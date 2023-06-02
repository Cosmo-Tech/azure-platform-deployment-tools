#!/bin/bash

#
# Production version for upgrading Helm Charts previously installed
#

help() {
  echo
  echo "This script takes at least 4 parameters."
  echo
  echo "You can retrieve the Helm values for your existing Platform with the following command:"
  echo "helm -n <NAMESPACE> get values cosmotech-api-<API_VERSION> | tail -n +2 | tee my_platform_cosmotech_api.values.yaml"
  echo
  echo "Usage: ./$(basename "$0") CHART_PACKAGE_VERSION [/absolute/path/to/cosmotech_api_values.yaml=current] [NAMESPACE=phoenix] [API_VERSION=MajorVersionOrLatestOf(CHART_PACKAGE_VERSION)] [INSTALL_SCRIPT_BRANCH=main] [any additional options to pass as is to the cosmotech-api Helm Chart] [API_URL=api/url/]"
  echo
  echo "Examples:"
  echo
  echo "- ./$(basename "$0") latest \\"
  echo "    /absolute/path/to/my/platform/cosmotech-api-values.yaml \\"
  echo "    phoenix \\"
  echo "    latest \\"
  echo "    main \\"
  echo "    --set image.pullPolicy=Always"
  echo
  echo "- ./$(basename "$0") 0.0.10-rc"
}

if [[ "${1:-}" == "--help" ||  "${1:-}" == "-h" ]]; then
  help
  exit 0
fi
if [[ $# -lt 1 ]]; then
  help
  exit 1
fi

export HELM_EXPERIMENTAL_OCI=1

export CHART_PACKAGE_VERSION="$1"
export COSMOTECH_API_RELEASE_VALUES_FILE="$2"
export NAMESPACE="$3"
export API_VERSION="$4"
export GIT_BRANCH_NAME="$5"
export API_URL="$6"

if [[ -z "${NAMESPACE}" ]]; then
  export NAMESPACE="phoenix"
fi

if [[ -z "${API_VERSION}" ]]; then
  if [[ "${CHART_PACKAGE_VERSION}" == "latest" ]]; then
    export API_VERSION="latest"
  else
    export tagFirstPart=$(echo "${CHART_PACKAGE_VERSION}" | cut -d '.' -f1)
    if [[ $tagFirstPart == "v*" ]]; then
      export API_VERSION=${tagFirstPart}
    else
      export API_VERSION=v${tagFirstPart}
    fi
  fi
fi

if [[ -z "${GIT_BRANCH_NAME}" ]]; then
  export GIT_BRANCH_NAME="main"
fi

echo Migrate data from CosmosDB to Redis...

WORKING_DIR=$(mktemp -d -t cosmotech-api-migration-XXXXXXXXXX)
pushd "${WORKING_DIR}"

export COSMOSDB_DATABASE_NAME=phoenix-core
export NAMESPACE="phoenix"
export REDIS_INSTANCE="cosmotechredis"

cat <<EOF > cosmosdb_migration_pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: migration-pod
spec:
  containers:
  - name: migration-pod
    image: ghcr.io/cosmo-tech/platform-migrate-redis:1.0.0
    env:
    - name: COSMOSDB_DATABASE_NAME
      value: ${COSMOSDB_DATABASE_NAME}
    - name: COSMOSDB_URL
      value: $(kubectl -n ${NAMESPACE} get secret cosmotech-api-v2 -o yaml | yq -r '.data["application-helm.yml"]' | base64 -d | yq '.csm.platform.azure.cosmos.uri')
    - name: COSMOSDB_KEY
      value: $(kubectl -n ${NAMESPACE} get secret cosmotech-api-v2 -o yaml | yq -r '.data["application-helm.yml"]' | base64 -d | yq '.csm.platform.azure.cosmos.key')
    - name: REDIS_SERVER
      value: "${REDIS_INSTANCE}-master"
    - name: REDIS_PASSWORD
      value: $(kubectl -n ${NAMESPACE} get secret ${REDIS_INSTANCE} -o jsonpath="{.data.redis-password}" | base64 --decode)
  nodeSelector:
    "cosmotech.com/tier": "db"
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  restartPolicy: Never
  initContainers:
  - name: download-dependencies
    image: alpine:latest
    command: ["sh", "-c", "wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64", "-o", "/usr/bin/yq", "&&", "chmod", "+x", "/usr/bin/yq"]
EOF

kubectl apply -n ${NAMESPACE} -f cosmosdb_migration_pod.yaml

rm -rf "${WORKING_DIR}"

echo End of the migration step



if [[ -z "${COSMOTECH_API_RELEASE_VALUES_FILE}" ]]; then
  echo Getting cosmotech-api-${API_VERSION} helm values...
  TMPDIR=$(mktemp -d) 
  export COSMOTECH_API_RELEASE_VALUES_FILE="${TMPDIR}/platform_cosmotech_api.values.yaml"
  helm -n ${NAMESPACE} get values cosmotech-api-${API_VERSION} | tail -n +2 | tee ${COSMOTECH_API_RELEASE_VALUES_FILE} >/dev/null
fi

echo Upgrade parameters:
echo CHART_PACKAGE_VERSION=${CHART_PACKAGE_VERSION}
echo COSMOTECH_API_RELEASE_VALUES_FILE=${COSMOTECH_API_RELEASE_VALUES_FILE}
echo NAMESPACE=${NAMESPACE}
echo API_VERSION=${API_VERSION}
echo GIT_BRANCH_NAME=${GIT_BRANCH_NAME}

echo "Setting environment variables useful for this upgrade..."

# Retrieve the Argo MinIO access and secret key credentials
# shellcheck disable=SC2155
export ARGO_MINIO_ACCESS_KEY=$(kubectl -n "${NAMESPACE}" get secret miniocsmv2 -o=jsonpath='{.data.root-user}' | base64 -d)
if [[ -z ${ARGO_MINIO_ACCESS_KEY} ]]; then
  # migrate existing user
  export MINIO_MIGRATE=true
fi
# shellcheck disable=SC2155
export ARGO_MINIO_SECRET_KEY=$(kubectl -n "${NAMESPACE}" get secret miniocsmv2 -o=jsonpath='{.data.root-password}' | base64 -d)

if [[ $MINIO_MIGRATE ]]; then
  echo Deleting minio installation for migration
  helm -n ${NAMESPACE} uninstall miniocsmv2
fi

echo Deleting minio secret for migration
kubectl -n ${NAMESPACE} delete secret miniocsmv2

# Retrieve the current Argo PostgreSQL secret
# shellcheck disable=SC2155
export ARGO_POSTGRESQL_PASSWORD=$(kubectl -n "${NAMESPACE}" get secret argo-postgres-config -o json | jq -r '.data["password"]' | base64 -d)

# Retrieve the current redis password from secret
if [[ -z ${REDIS_ADMIN_PASSWORD} ]]; then
  export REDIS_ADMIN_PASSWORD=$(kubectl get secret --namespace ${NAMESPACE} cosmotechredis -o jsonpath="{.data.redis-password}" | base64 --decode)
fi
# Retrive redis disk information
if [[ -z ${REDIS_DISK_RESOURCE} ]]; then
  export REDIS_DISK_RESOURCE=$(kubectl get pv -n ${NAMESPACE} cosmotech-database-master-pv -o jsonpath="{.spec.csl.volumeHandler}")
fi
if [[ -z ${REDIS_DISK_SIZE} ]]; then
  export REDIS_DISK_SIZE=$(kubectl get pv -n ${NAMESPACE} cosmotech-database-master-pv -o jsonpath="{.spec.capacity.storage}")
fi

# Get the current Ingress Controller Load Balancer IP
# shellcheck disable=SC2155
export NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP=$(kubectl -n "${NAMESPACE}" get service ingress-nginx-controller -o json | jq -r '.spec.loadBalancerIP')
if [[ -n "$NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP" ]]; then
  export NGINX_INGRESS_CONTROLLER_ENABLED=true
else
  export NGINX_INGRESS_CONTROLLER_ENABLED=false
fi

NGINX_INGRESS_CONTROLLER_ALB_RG=$(kubectl -n "${NAMESPACE}" get service ingress-nginx-controller -o json | jq -r '.metadata.annotations["service.beta.kubernetes.io/azure-load-balancer-resource-group"]')
if [[ -n "$NGINX_INGRESS_CONTROLLER_ALB_RG" ]] && [[ "$NGINX_INGRESS_CONTROLLER_ALB_RG" != "null" ]]; then
  export NGINX_INGRESS_CONTROLLER_HELM_ADDITIONAL_OPTIONS="--set controller.service.annotations.\"service\.beta\.kubernetes\.io/azure-load-balancer-resource-group\"=$NGINX_INGRESS_CONTROLLER_ALB_RG"
else
  unset NGINX_INGRESS_CONTROLLER_HELM_ADDITIONAL_OPTIONS
fi

# Get the current cert-manager configuration, if deployed
helm -n "${NAMESPACE}" get notes cert-manager > /dev/null 2>&1
if helm -n "${NAMESPACE}" get notes cert-manager > /dev/null 2>&1; then
  export CERT_MANAGER_ENABLED=true
else
  unset CERT_MANAGER_ENABLED
fi

# Export the TLS Configuration
# shellcheck disable=SC2155
export TLS_SECRET_NAME=$(kubectl -n "${NAMESPACE}" get ingress cosmotech-api-${API_VERSION} -o json | jq -r '.spec.tls[0].secretName')

if [[ "${TLS_SECRET_NAME}" = letsencrypt-* ]]; then
  export TLS_CERTIFICATE_TYPE=let_s_encrypt
  # shellcheck disable=SC2155
  export TLS_CERTIFICATE_LET_S_ENCRYPT_CONTACT_EMAIL=$(kubectl -n "${NAMESPACE}" get clusterissuer letsencrypt-prod -o=jsonpath='{.spec.acme.email}')
  if [[ "${TLS_SECRET_NAME}" == "letsencrypt-prod" ]]; then
    export CERT_MANAGER_USE_ACME_PROD=true
  else
    export CERT_MANAGER_USE_ACME_PROD=false
  fi
else
  if kubectl -n "${NAMESPACE}" get secret custom-tls-secret > /dev/null 2>&1; then
    export TLS_CERTIFICATE_TYPE=custom
    kubectl -n phoenix get secret custom-tls-secret -o=json | jq -r '.data["tls.crt"]' | base64 -d > /tmp/tls.crt
    export TLS_CERTIFICATE_CUSTOM_CERTIFICATE_PATH="/tmp/tls.crt"
    kubectl -n phoenix get secret custom-tls-secret -o=json | jq -r '.data["tls.key"]' | base64 -d > /tmp/tls.key
    export TLS_CERTIFICATE_CUSTOM_KEY_PATH="/tmp/tls.key"
  else
    export TLS_CERTIFICATE_TYPE=none
  fi
fi

# shellcheck disable=SC2155
export COSMOTECH_API_DNS_NAME=$(kubectl -n "${NAMESPACE}" get ingress cosmotech-api-${API_VERSION} -o json | jq -r '.spec.tls[0].hosts[0]')

export PROM_ADMIN_PASSWORD=$(kubectl -n "${NAMESPACE}-monitoring" get secret "prometheus-operator-grafana" -o=jsonpath='{.data.admin-password}' | base64 -d)
export DEPLOY_PROMETHEUS_STACK=true

kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.63.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml
kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.63.0/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml
kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.63.0/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml
kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.63.0/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml
kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.63.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.63.0/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.63.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml
kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.63.0/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml

# Now run the deployment script with the right environment variables set
echo "Now running the deployment script (from \"${GIT_BRANCH_NAME}\" Git Branch) with the right environment variables..."
curl -o- -sSL https://raw.githubusercontent.com/Cosmo-Tech/azure-platform-deployment-tools/main/deployment_scripts/v2.4/deploy_via_helm.sh | bash -s -- \
  "${CHART_PACKAGE_VERSION}" \
  "${NAMESPACE}" \
  "${ARGO_POSTGRESQL_PASSWORD}" \
  "${API_VERSION}" \
  --values "${COSMOTECH_API_RELEASE_VALUES_FILE}" \
  --set image.tag="${CHART_PACKAGE_VERSION}" \
  "${@:6}"
