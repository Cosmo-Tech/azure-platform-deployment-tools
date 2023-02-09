#!/bin/bash

set -eo errexit
export HELM_EXPERIMENTAL_OCI=1

#
# Production version for deploying the Helm Charts from the remote ghcr.io OCI registry
#

help() {
  echo
  echo "This script takes at least 5 parameters."
  echo
  echo "The following optional environment variables can be set to alter this script behavior:"
  echo "- ARGO_MINIO_ACCESS_KEY | string | AccessKey for MinIO. Generated when not set"
  echo "- ARGO_MINIO_SECRET_KEY | string | SecretKey for MinIO. Generated when not set"
  echo "- ARGO_REQUEUE_TIME | string | Workflow requeue time, 1s by default"
  echo "- ARGO_MINIO_REQUESTS_MEMORY | units of bytes (default is 4Gi) | Memory requests for the Argo MinIO server"
  echo "- ARGO_MINIO_PERSISTENCE_SIZE | units of bytes (default is 500Gi) | Persistence size for the Argo MinIO server"
  echo "- NGINX_INGRESS_CONTROLLER_ENABLED | boolean (default is false) | indicating whether an NGINX Ingress Controller should be deployed and an Ingress resource created too"
  echo "- NGINX_INGRESS_CONTROLLER_REPLICA_COUNT | int (default is 1) | number of pods for the NGINX Ingress Controller"
  echo "- NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP | IP Address String | optional public IP Address to use as LoadBalancer IP. You can create one with this Azure CLI command: az network public-ip create --resource-group <my-rg>> --name <a-name> --sku Standard --allocation-method static --query publicIp.ipAddress -o tsv "
  echo "- NGINX_INGRESS_CONTROLLER_HELM_ADDITIONAL_OPTIONS | Additional Helm options for the NGINX Ingress Controller | Additional options to pass to Helm when creating the Ingress Controller, e.g.: --set controller.service.annotations.\"service.beta.kubernetes.io/azure-load-balancer-resource-group\"=my-azure-resource-group"
  echo "- CERT_MANAGER_ENABLED  | boolean (default is false). Deprecated - use TLS_CERTIFICATE_TYPE instead | indicating whether cert-manager should be deployed. It is in charge of requesting and managing renewal of Let's Encrypt certificates"
  echo "- CERT_MANAGER_INSTALL_WAIT_TIMEOUT | string (default is 3m) | how much time to wait for the cert-manager Helm Chart to be successfully deployed"
  echo "- CERT_MANAGER_USE_ACME_PROD | boolean (default is false) | whether to use the Let's Encrypt Production server. Note that this is subject to rate limiting"
  echo "- CERT_MANAGER_COSMOTECH_API_DNS_NAME | FQDN String. Deprecated - use COSMOTECH_API_DNS_NAME instead | DNS name, used for Let's Encrypt certificate requests, e.g.: dev.api.cosmotech.com"
  echo "- COSMOTECH_API_DNS_NAME | FQDN String | DNS name, used for configuring the Ingress resource, e.g.: dev.api.cosmotech.com"
  echo "- CERT_MANAGER_ACME_CONTACT_EMAIL | Email String. Deprecated - use TLS_CERTIFICATE_LET_S_ENCRYPT_CONTACT_EMAIL instead | contact email, used for Let's Encrypt certificate requests"
  echo "- TLS_CERTIFICATE_TYPE | one of 'none', 'custom', 'let_s_encrypt' | strategy for TLS certificates"
  echo "- TLS_CERTIFICATE_LET_S_ENCRYPT_CONTACT_EMAIL | Email String | contact email, used for Let's Encrypt certificate requests"
  echo "- TLS_CERTIFICATE_CUSTOM_CERTIFICATE_PATH | File path | path to a file containing the custom TLS certificate to use for HTTPS"
  echo "- TLS_CERTIFICATE_CUSTOM_KEY_PATH | File path | path to a file containing the key for the custom TLS certificate to use for HTTPS"
  echo "- DEPLOY_PROMETHEUS_STACK | boolean (default is false) | deploy prometheus stack to monitor platform usage"
  echo "--- PROM_STORAGE_CLASS_NAME | storage class name for the prometheus PVC (default is standard)"
  echo "--- PROM_STORAGE_RESOURCE_REQUEST | size requested for prometheusPVC (default is 10Gi)"
  echo "--- PROM_CPU_MEM_LIMITS | memory size limit for prometheus (default is 2Gi)"
  echo "--- PROM_CPU_MEM_REQUESTS | memory size requested for prometheus (default is 2Gi)"
  echo "--- PROM_REPLICAS_NUMBER | number of prometheus replicas (default is 1)"
  echo "--- PROM_ADMIN_PASSWORD | admin password for grafana (generated if not specified)"
  echo "- REDIS_ADMIN_PASSWORD | admin password for redis (generated if not specified)"
  echo "- REDIS_DISK_SIZE | redis disk size requirement (default: 64Gi)"
  echo "- REDIS_MASTER_NAME_PVC | redis master persistent volume claim name (default: cosmotech-database-master-pvc)"
  echo "- REDIS_DISK_RESOURCE | redis volume handle resource id (ex: /subscriptions/<my-subscription>/resourceGroups/<my-resource-group>/providers/Microsoft.Compute/disks/<my-disk-name>)"
  echo
  echo "Usage: ./$(basename "$0") CHART_PACKAGE_VERSION NAMESPACE ARGO_POSTGRESQL_PASSWORD API_VERSION [any additional options to pass as is to the cosmotech-api Helm Chart]"
  echo
  echo "Examples:"
  echo
  echo "- ./$(basename "$0") latest phoenix \"a-super-secret-password-for-postgresql\" latest \\"
  echo "    --values /path/to/my/cosmotech-api-values.yaml \\"
  echo "    --set image.pullPolicy=Always"
  echo
  echo "- ./$(basename "$0") 1.0.1 phoenix \"change-me\" v1 --values /path/to/my/cosmotech-api-values.yaml"
}

if [[ "${1:-}" == "--help" ||  "${1:-}" == "-h" ]]; then
  help
  exit 0
fi
if [[ $# -lt 4 ]]; then
  help
  exit 1
fi

export HELM_EXPERIMENTAL_OCI=1

export CHART_PACKAGE_VERSION="$1"
export NAMESPACE="$2"
export API_VERSION="$4"
export REQUEUE_TIME="${ARGO_REQUEUE_TIME:-1s}"

echo CHART_PACKAGE_VERSION: "$CHART_PACKAGE_VERSION"
echo NAMEPSACE: "$NAMESPACE"
echo API_VERSION: "$API_VERSION"

export ARGO_VERSION="0.16.6"
export ARGO_RELEASE_NAME=argocsmv2
export ARGO_RELEASE_NAMESPACE="${NAMESPACE}"
export MINIO_VERSION="12.1.3"
export MINIO_RELEASE_NAME=miniocsmv2
export POSTGRES_RELEASE_NAME=postgrescsmv2
export POSTGRESQL_VERSION="11.6.12"
export ARGO_POSTGRESQL_USER=argo
export ARGO_POSTGRESQL_PASSWORD="$3"
export INGRESS_NGINX_VERSION="4.2.5"
export CERT_MANAGER_VERSION="1.9.1"
export VERSION_REDIS="17.3.14"
export VERSION_REDIS_COSMOTECH="1.0.0"
export VERSION_REDIS_INSIGHT="0.1.0"
export PROMETHEUS_STACK_VERSION="45.0.0"

export ARGO_DATABASE=argo_workflows
export ARGO_BUCKET_NAME=argo-workflows

WORKING_DIR=$(mktemp -d -t cosmotech-api-helm-XXXXXXXXXX)
echo "[info] Working directory: ${WORKING_DIR}"
pushd "${WORKING_DIR}"

echo -- "[info] Working directory: ${WORKING_DIR}"

# common exports
export COSMOTECH_API_RELEASE_NAME="cosmotech-api-${API_VERSION}"
export REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_ADMIN_PASSWORD:-$(kubectl get secret --namespace "${NAMESPACE}" cosmotechredis -o jsonpath="{.data.redis-password}" | base64 -d || "")}
if [[ -z $REDIS_PASSWORD ]] ; then
  REDIS_PASSWORD=$(date +%s | sha256sum | base64 | head -c 32)
fi

# HELM_CHARTS_BASE_PATH=$(realpath "$(dirname "$0")")

# Create namespace if it does not exist
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

if [[ "${COSMOTECH_API_DNS_NAME:-}" == "" ]]; then
  export COSMOTECH_API_DNS_NAME="${CERT_MANAGER_COSMOTECH_API_DNS_NAME:-}"
fi

# kube-prometheus-stack
# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
# https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
if [[ "${DEPLOY_PROMETHEUS_STACK:-false}" == "true" ]]; then
  echo -- Monitoring stack
  export MONITORING_NAMESPACE="${NAMESPACE}-monitoring"
  kubectl create namespace "${MONITORING_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  MONITORING_NAMESPACE_VAR=${MONITORING_NAMESPACE} \
  PROM_STORAGE_CLASS_NAME_VAR=${PROM_STORAGE_CLASS_NAME:-"default"} \
  PROM_STORAGE_RESOURCE_REQUEST_VAR=${PROM_STORAGE_RESOURCE_REQUEST:-"32Gi"} \
  PROM_CPU_MEM_LIMITS_VAR=${PROM_CPU_MEM_LIMITS:-"2Gi"} \
  PROM_CPU_MEM_REQUESTS_VAR=${PROM_CPU_MEM_REQUESTS:-"2Gi"} \
  PROM_REPLICAS_NUMBER_VAR=${PROM_REPLICAS_NUMBER:-"1"} \
  PROM_ADMIN_PASSWORD_VAR=${PROM_ADMIN_PASSWORD:-$(date +%s | sha256sum | base64 | head -c 32)} \
  REDIS_ADMIN_PASSWORD_VAR=${REDIS_ADMIN_PASSWORD} \
  REDIS_HOST_VAR=cosmotechredis-master.${NAMESPACE}.svc.cluster.local \
  REDIS_PORT_VAR=${REDIS_PORT} \
  # Cannot use kube-prometheus-stack.yaml here directly since ARM only download deploy_via_helm.sh
  # envsubst < "${HELM_CHARTS_BASE_PATH}"/kube-prometheus-stack-template.yaml > kube-prometheus-stack.yaml

cat <<EOF > kube-prometheus-stack.yaml
namespace: $MONITORING_NAMESPACE_VAR
name: cosmotech-api-latest
labels:
  networking/traffic-allowed: "yes"
defaultRules:
  create: true
alertmanager:
  enabled: true
  alertmanagerSpec:
    logLevel: info
    tolerations:
      - key: "vendor"
        operator: "Equal"
        value: "cosmotech"
        effect: "NoSchedule"
    nodeSelector:
      "cosmotech.com/tier": "monitoring"
    podMetadata:
      labels:
        networking/traffic-allowed: "yes"
    resources:
      limits:
        cpu: 1
        memory: 1Gi
      requests:
        cpu: 1
        memory: 400Mi
grafana:
  enabled: true
  grafana.ini:
    server:
      domain: "${COSMOTECH_API_DNS_NAME}"
      root_url: "%(protocol)s://%(domain)s/monitoring"
      serve_from_sub_path: true
  ingress:
    enabled: true
    path: "/monitoring"
    annotations:
      kubernetes.io/ingress.class: nginx
    hosts:
      - "${COSMOTECH_API_DNS_NAME}"
    tls:
      - secretName: ${TLS_SECRET_NAME}
        hosts: [${COSMOTECH_API_DNS_NAME}]
  plugins:
    - redis-datasource
  adminPassword: $PROM_ADMIN_PASSWORD_VAR
  defaultDashboardsEnabled: true
  additionalDataSources:
    - name: cosmotech-redis
      orgId: 1
      type: redis-datasource
      access: proxy
      url: redis://$REDIS_HOST_VAR:$REDIS_PORT_VAR
      basicAuth: false
      withCredentials: false
      isDefault: false
      version: 1
      editable: false
      secureJsonData:
        password: $REDIS_ADMIN_PASSWORD_VAR
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      redis:
        gnetId: 12776
        revision: 2
        datasource: cosmotech-redis
      argo:
        gnetId: 14136
        revision: 1
        datasource: Prometheus
      nginx:
        gnetId: 9614
        revision: 1
        datasource: Prometheus
      minio:
        gnetId: 15305
        revision: 1
        datasource: Prometheus
      postgresql:
        gnetId: 9628
        revision: 7
        datasource: Prometheus
      certmanager:
        gnetId: 11001
        revision: 1
        datasource: Prometheus
      csm_licensing:
        url: "https://raw.githubusercontent.com/Cosmo-Tech/azure-platform-deployment-tools/main/grafana/cosmotech_licensing/v4/cosmotech_licensing.json"
      csm_customer_success:
        url: "https://raw.githubusercontent.com/Cosmo-Tech/azure-platform-deployment-tools/main/grafana/customer_success/v1/customer_success.json"
      csm_api:
        url: "https://raw.githubusercontent.com/Cosmo-Tech/azure-platform-deployment-tools/main/grafana/cosmotech_api/v1/cosmotech_api.json"
  tolerations:
    - key: "vendor"
      operator: "Equal"
      value: "cosmotech"
      effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "monitoring"
kubeApiServer:
  enabled: true
kubelet:
  enabled: true
kubeControllerManager:
  enabled: true
coreDns:
  enabled: true
kubeEtcd:
  enabled: true
kubeScheduler:
  enabled: true
kubeStateMetrics:
  enabled: true
kube-state-metrics:
  tolerations:
      - key: "vendor"
        operator: "Equal"
        value: "cosmotech"
        effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "monitoring"
  podMetadata:
    labels:
      networking/traffic-allowed: "yes"
  resources:
    limits:
      cpu: 1
      memory: 1Gi
    requests:
      cpu: 1
      memory: 400Mi
nodeExporter:
  enabled: true
prometheusOperator:
  tolerations:
    - key: "vendor"
      operator: "Equal"
      value: "cosmotech"
      effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "monitoring"
  admissionWebhooks:
    patch:
      labels:
        networking/traffic-allowed: "yes"
      nodeSelector:
        "cosmotech.com/tier": "monitoring"
      tolerations:
        - key: "vendor"
          operator: "Equal"
          value: "cosmotech"
          effect: "NoSchedule"
prometheus:
  enabled: true
  crname: prometheus
  serviceAccount:
    create: true
    name: prometheus-service-account
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    logLevel: info
    replicas: $PROM_REPLICAS_NUMBER_VAR
    tolerations:
      - key: "vendor"
        operator: "Equal"
        value: "cosmotech"
        effect: "NoSchedule"
    nodeSelector:
      "cosmotech.com/tier": "monitoring"
    podMetadata:
      annotations:
        cluster-autoscaler.kubernetes.io/safe-to-evict: "true"
      labels:
        app: prometheus
    resources:
      limits:
        cpu: 1
        memory: $PROM_CPU_MEM_LIMITS_VAR
      requests:
        cpu: 1
        memory: $PROM_CPU_MEM_REQUESTS_VAR
    retention: 365d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: $PROM_STORAGE_CLASS_NAME_VAR
          accessModes:
          - ReadWriteOnce
          resources:
            requests:
              storage: $PROM_STORAGE_RESOURCE_REQUEST_VAR
  additionalServiceMonitors:
    - name: cosmotech-latest
      additionalLabels:
        serviceMonitorSelector: prometheus
      endpoints:
        - interval: 30s
          targetPort: 8081
          path: /actuator/prometheus
      namespaceSelector:
        matchNames:
        - phoenix
      selector:
        matchLabels:
          app.kubernetes.io/instance: cosmotech-api-latest
    - name: cosmotech-v1
      additionalLabels:
        serviceMonitorSelector: prometheus
      endpoints:
        - interval: 30s
          targetPort: 8081
          path: /actuator/prometheus
      namespaceSelector:
        matchNames:
        - phoenix
      selector:
        matchLabels:
          app.kubernetes.io/instance: cosmotech-api-v1
EOF

  helm upgrade --install prometheus-operator prometheus-community/kube-prometheus-stack \
               --namespace "${MONITORING_NAMESPACE}" \
               --version ${PROMETHEUS_STACK_VERSION} \
               --values "kube-prometheus-stack.yaml"
fi

echo -- Certificate config
# NGINX Ingress Controller & Certificate
if [[ "${CERT_MANAGER_USE_ACME_PROD:-false}" == "true" ]]; then
  export CERT_MANAGER_ACME="prod"
  export CERT_MANAGER_ACME_SERVER="https://acme-v02.api.letsencrypt.org/directory"
else
  export CERT_MANAGER_ACME="staging"
  export CERT_MANAGER_ACME_SERVER="https://acme-staging-v02.api.letsencrypt.org/directory"
fi
if [[ "${TLS_CERTIFICATE_TYPE:-let_s_encrypt}" != "let_s_encrypt" ]]; then
  export CERT_MANAGER_ENABLED="false"
  if [[ "${TLS_CERTIFICATE_TYPE:-}" == "custom" ]]; then
    export TLS_SECRET_NAME="custom-tls-secret"
    kubectl -n "${NAMESPACE}" create secret tls "${TLS_SECRET_NAME}" \
      --cert "${TLS_CERTIFICATE_CUSTOM_CERTIFICATE_PATH}" \
      --key "${TLS_CERTIFICATE_CUSTOM_KEY_PATH}" \
      --dry-run=client \
      -o yaml | kubectl -n "${NAMESPACE}" apply -f -
  fi
else
  export CERT_MANAGER_ENABLED="true"
  export TLS_SECRET_NAME="letsencrypt-${CERT_MANAGER_ACME}"
fi

if [[ "${NGINX_INGRESS_CONTROLLER_ENABLED:-false}" == "true" ]]; then
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
  helm repo update

  export NGINX_INGRESS_CONTROLLER_REPLICA_COUNT="${NGINX_INGRESS_CONTROLLER_REPLICA_COUNT:-1}"
  export NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP="${NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP:-}"

cat <<EOF > values-ingress-nginx.yaml
controller:
  metrics:
    enabled: true
    serviceMonitor:
      enabled: true
      namespace: $MONITORING_NAMESPACE
  labels:
    networking/traffic-allowed: "yes"
  podLabels:
    networking/traffic-allowed: "yes"
  replicaCount: "${NGINX_INGRESS_CONTROLLER_REPLICA_COUNT}"
  nodeSelector:
    "cosmotech.com/tier": "services"
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  service:
    labels:
      networking/traffic-allowed: "yes"
    loadBalancerIP: "${NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP}"
  extraArgs:
    default-ssl-certificate: "${NAMESPACE}/${TLS_SECRET_NAME}"
  resources:
    requests:
      cpu: 100m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 512Mi
  admissionWebhooks:
    labels:
      networking/traffic-allowed: "yes"
    patch:
      labels:
        networking/traffic-allowed: "yes"
      nodeSelector:
        "cosmotech.com/tier": "services"
      tolerations:
      - key: "vendor"
        operator: "Equal"
        value: "cosmotech"
        effect: "NoSchedule"

defaultBackend:
  podLabels:
    networking/traffic-allowed: "yes"
  nodeSelector:
    "cosmotech.com/tier": "services"
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  resources:
    requests:
      cpu: 100m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 512Mi

EOF

  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace "${NAMESPACE}" \
    --version ${INGRESS_NGINX_VERSION} \
    --values values-ingress-nginx.yaml \
    ${NGINX_INGRESS_CONTROLLER_HELM_ADDITIONAL_OPTIONS:-}
fi

echo -- Cert Manager
# cert-manager
if [[ "${TLS_CERTIFICATE_LET_S_ENCRYPT_CONTACT_EMAIL:-}" == "" ]]; then
  export TLS_CERTIFICATE_LET_S_ENCRYPT_CONTACT_EMAIL="${CERT_MANAGER_ACME_CONTACT_EMAIL:-}"
fi
if [[ "${TLS_CERTIFICATE_TYPE:-}" == "" ]]; then
  if [[ "${CERT_MANAGER_ENABLED:-}" == "true" ]]; then
    export TLS_CERTIFICATE_TYPE="let_s_encrypt"
  else
    export TLS_CERTIFICATE_TYPE="none"
  fi
fi
if [[ "${CERT_MANAGER_ENABLED:-false}" == "true" ]]; then
  helm repo add jetstack https://charts.jetstack.io
  helm repo update

cat <<EOF > values-cert-manager.yaml
installCRDs: true
prometheus:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: $MONITORING_NAMESPACE
    interval: 300s
    scrapeTimeout: 30s
tolerations:
- key: "vendor"
  operator: "Equal"
  value: "cosmotech"
  effect: "NoSchedule"
nodeSelector:
  "cosmotech.com/tier": "services"
podLabels:
  "networking/traffic-allowed": "yes"
resources:
  requests:
    cpu: 10m
    memory: 128Mi
  limits:
    cpu: 1000m
    memory: 256Mi
webhook:
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "services"
  podLabels:
    "networking/traffic-allowed": "yes"
  resources:
    requests:
      cpu: 10m
      memory: 64Mi
    limits:
      cpu: 1000m
      memory: 64Mi
cainjector:
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "services"
  podLabels:
    "networking/traffic-allowed": "yes"
  resources:
    requests:
      cpu: 10m
      memory: 128Mi
    limits:
      cpu: 1000m
      memory: 256Mi
startupapicheck:
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "services"
  podLabels:
    "networking/traffic-allowed": "yes"
  resources:
    requests:
      cpu: 10m
      memory: 64Mi
    limits:
      cpu: 1000m
      memory: 64Mi

EOF


  kubectl label namespace "${NAMESPACE}" cert-manager.io/disable-validation=true --overwrite=true
  helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace "${NAMESPACE}" \
    --version v${CERT_MANAGER_VERSION} \
    --wait \
    --timeout "${CERT_MANAGER_INSTALL_WAIT_TIMEOUT:-3m}" \
    --set installCRDs=true \
    --values values-cert-manager.yaml


  if [[ "${COSMOTECH_API_DNS_NAME:-}" != "" && "${TLS_CERTIFICATE_LET_S_ENCRYPT_CONTACT_EMAIL:-}" != "" ]]; then
    # Wait few seconds until the CertManager WebHook pod is ready.
    # Otherwise, we might run into the following issue :
    # Error from server: error when creating "STDIN": conversion webhook for cert-manager.io/v1,
    # Kind=Certificate failed: Post "https://cert-manager-webhook.${NAMESPACE}.svc:443/convert?timeout=30s"
    sleep 25
    echo -- Cluster Issuer and Certificate
cat <<EOF | kubectl --namespace "${NAMESPACE}" apply --validate=false -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-${CERT_MANAGER_ACME}
spec:
  acme:
    server: "${CERT_MANAGER_ACME_SERVER}"
    email: "${TLS_CERTIFICATE_LET_S_ENCRYPT_CONTACT_EMAIL}"
    privateKeySecretRef:
      name: letsencrypt-${CERT_MANAGER_ACME}-private-key
    solvers:
      - http01:
          ingress:
            class: nginx
            podTemplate:
              metadata:
                labels:
                  networking/traffic-allowed: "yes"
              spec:
                tolerations:
                - key: "vendor"
                  operator: "Equal"
                  value: "cosmotech"
                  effect: "NoSchedule"
                nodeSelector:
                  "cosmotech.com/tier": "services"
                resources:
                  requests:
                    cpu: 10m
                    memory: 64Mi
                  limits:
                    cpu: 1000m
                    memory: 64Mi

---

apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ${TLS_SECRET_NAME}
spec:
  secretName: ${TLS_SECRET_NAME}
  dnsNames:
    - ${COSMOTECH_API_DNS_NAME}
  acme:
    config:
      - http01:
          ingressClass: nginx
        domains:
          - ${COSMOTECH_API_DNS_NAME}
  issuerRef:
    name: letsencrypt-${CERT_MANAGER_ACME}
    kind: ClusterIssuer
EOF
  fi
fi

echo -- Redis

EXISTING_REDIS_PV_NAME=$(kubectl get persistentvolumes -n "${NAMESPACE}" -l "cosmotech.com/service=redis" --field-selector='metadata.name=cosmotech-database-master-pv' -o name)
REDIS_PV_NAME=cosmotech-database-master-pv
REDIS_PVC_NAME="${REDIS_MASTER_NAME_PVC:-"cosmotech-database-master-pvc"}"

if [[ "${REDIS_DISK_SIZE}" != *"Gi" ]]; then
  export REDIS_DISK_SIZE=${REDIS_DISK_SIZE}Gi
fi

if [[ "${EXISTING_REDIS_PV_NAME:-}" == "" && "${REDIS_DISK_RESOURCE:-}" != "" ]]; then

cat <<EOF > redis-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: "${REDIS_PV_NAME}"
  labels:
    "cosmotech.com/service": "redis"
spec:
  storageClassName: ""
  claimRef:
    name: "${REDIS_PVC_NAME}"
    namespace: "${NAMESPACE}"
  capacity:
    storage: ${REDIS_DISK_SIZE:-"64Gi"}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: disk.csi.azure.com
    volumeHandle: ${REDIS_DISK_RESOURCE}
    volumeAttributes:
      fsType: ext4
EOF

echo "Deploying DB Persistent Volume cosmotech-database-master-pv"
kubectl apply -n "${NAMESPACE}" -f redis-pv.yaml

fi

# Redis Cluster
helm repo add bitnami https://charts.bitnami.com/bitnami
help repo update

cat <<EOF > redis-master-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: "${REDIS_PVC_NAME}"
  namespace: ${NAMESPACE}
spec:
  storageClassName: ""
  volumeName: "${REDIS_PV_NAME}"
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: "${REDIS_DISK_SIZE:-"64Gi"}"

EOF
kubectl apply -n "${NAMESPACE}" -f redis-master-pvc.yaml


cat <<EOF > values-redis.yaml
auth:
  password: ${REDIS_PASSWORD}
image:
  registry: ghcr.io
  repository: cosmo-tech/cosmotech-redis
  tag: ${VERSION_REDIS_COSMOTECH}
volumePermissions:
  enabled: true
master:
  persistence:
    existingClaim: ${REDIS_MASTER_NAME_PVC:-"cosmotech-database-master-pvc"}
  podLabels:
    "networking/traffic-allowed": "yes"
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  nodeSelector:
    cosmotech.com/tier: "db"
  resources:
    requests:
      cpu: 500m
      memory: 4Gi
    limits:
      cpu: 1000m
      memory: 4Gi
replica:
  replicaCount: 1
  podLabels:
    "networking/traffic-allowed": "yes"
  persistence:
    storageClass: "managed-csi"
    size: "${REDIS_DISK_SIZE:-"64Gi"}"
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "db"
  resources:
    requests:
      cpu: 500m
      memory: 4Gi
    limits:
      cpu: 1000m
      memory: 4Gi

EOF


helm upgrade --install cosmotechredis bitnami/redis \
    --namespace "${NAMESPACE}" \
    --version "${VERSION_REDIS}" \
    --values https://raw.githubusercontent.com/Cosmo-Tech/cosmotech-redis/main/values/v1/values-cosmotech-cluster.yaml \
    --values values-redis.yaml \
    --wait \
    --timeout 10m0s

echo -- Redis Insight
# Redis Insight
REDIS_INSIGHT_HELM_CHART="${WORKING_DIR}/redisinsight-chart.tgz"
wget https://docs.redis.com/latest/pkgs/redisinsight-chart-${VERSION_REDIS_INSIGHT}.tgz  -O "${REDIS_INSIGHT_HELM_CHART}"

cat <<EOF > values-redis-insight.yaml
service:
  type: NodePort
  port: 80
tolerations:
- key: "vendor"
  operator: "Equal"
  value: "cosmotech"
  effect: "NoSchedule"
nodeSelector:
  "cosmotech.com/tier": "services"
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 1000m
    memory: 128Mi

EOF


helm upgrade --install \
   --namespace "${NAMESPACE}" redisinsight "${REDIS_INSIGHT_HELM_CHART}" \
   --set service.type=NodePort \
   --wait \
   --values values-redis-insight.yaml \
   --timeout 10m0s

echo -- Minio
# Minio
cat <<EOF > values-minio.yaml
fullnameOverride: ${MINIO_RELEASE_NAME}
defaultBuckets: "${ARGO_BUCKET_NAME}"
persistence:
  enabled: true
  size: "${ARGO_MINIO_PERSISTENCE_SIZE:-16Gi}"
resources:
  requests:
    memory: "${ARGO_MINIO_REQUESTS_MEMORY:-2Gi}"
    cpu: "100m"
  limits:
    memory: "${ARGO_MINIO_REQUESTS_MEMORY:-2Gi}"
    cpu: "1"
service:
  type: ClusterIP
podLabels:
  networking/traffic-allowed: "yes"
tolerations:
- key: "vendor"
  operator: "Equal"
  value: "cosmotech"
  effect: "NoSchedule"
nodeSelector:
  "cosmotech.com/tier": "services"
auth:
  rootUser: "${ARGO_MINIO_ACCESS_KEY:-}"
  rootPassword: "${ARGO_MINIO_SECRET_KEY:-}"
metrics:
  # Metrics can not be disabled yet: https://github.com/minio/minio/issues/7493
  serviceMonitor:
    enabled: true
    namespace: $MONITORING_NAMESPACE
    interval: 30s
    scrapeTimeout: 10s
EOF

helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install ${MINIO_RELEASE_NAME} bitnami/minio --namespace "${NAMESPACE}" --version ${MINIO_VERSION} --values values-minio.yaml

echo -- Postgres
# Postgres
cat <<EOF > values-postgresql.yaml
auth:
  username: "${ARGO_POSTGRESQL_USER}"
  password: "${ARGO_POSTGRESQL_PASSWORD}"
  database: ${ARGO_DATABASE}
primary:
  podLabels:
    "networking/traffic-allowed": "yes"
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "db"
readReplicas:
  nodeSelector:
    "cosmotech.com/tier": "db"
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
resources:
  requests:
    memory: "64Mi"
    cpu: "250m"
  limits:
    memory: "256Mi"
    cpu: "1"
metrics:
  enabled: true
  serviceMonitor:
    enabled: true
    namespace: $MONITORING_NAMESPACE
    interval: 30s
    scrapeTimeout: 10s
EOF

helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install -n "${NAMESPACE}" ${POSTGRES_RELEASE_NAME} bitnami/postgresql --version ${POSTGRESQL_VERSION} --values values-postgresql.yaml

export ARGO_POSTGRESQL_SECRET_NAME=argo-postgres-config
cat <<EOF > postgres-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    app: postgres
  name: ${ARGO_POSTGRESQL_SECRET_NAME}
stringData:
  password: ${ARGO_POSTGRESQL_PASSWORD}
  username: ${ARGO_POSTGRESQL_USER}
type: Opaque

EOF
kubectl apply -n "${NAMESPACE}" -f postgres-secret.yaml

echo -- Argo
# Argo
export ARGO_SERVICE_ACCOUNT=workflowcsmv2
cat <<EOF > values-argo.yaml
images:
  pullPolicy: IfNotPresent
workflow:
  serviceAccount:
    create: true
    name: ${ARGO_SERVICE_ACCOUNT}
  rbac:
    create: true
executor:
  env:
  - name: RESOURCE_STATE_CHECK_INTERVAL
    value: 1s
  - name: WAIT_CONTAINER_STATUS_CHECK_INTERVAL
    value: 1s
useDefaultArtifactRepo: true
artifactRepository:
  archiveLogs: true
  s3:
    bucket: ${ARGO_BUCKET_NAME}
    endpoint: ${MINIO_RELEASE_NAME}.${NAMESPACE}.svc.cluster.local:9000
    insecure: true
    accessKeySecret:
      name: ${MINIO_RELEASE_NAME}
      key: root-user
    secretKeySecret:
      name: ${MINIO_RELEASE_NAME}
      key: root-password
server:
  extraArgs:
  - --auth-mode=server
  secure: false
  podLabels:
    networking/traffic-allowed: "yes"
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "services"
  resources:
    requests:
      memory: "64Mi"
      cpu: "100m"
    limits:
      memory: "128Mi"
      cpu: "1"
controller:
  extraEnv:
  - name: DEFAULT_REQUEUE_TIME
    value: "${REQUEUE_TIME}"
  podLabels:
    networking/traffic-allowed: "yes"
  serviceMonitor:
    enabled: true
    namespace: $MONITORING_NAMESPACE
  tolerations:
  - key: "vendor"
    operator: "Equal"
    value: "cosmotech"
    effect: "NoSchedule"
  nodeSelector:
    "cosmotech.com/tier": "services"
  resources:
    requests:
      memory: "64Mi"
      cpu: "100m"
    limits:
      memory: "128Mi"
      cpu: "1"
  containerRuntimeExecutor: k8sapi
  metricsConfig:
    enabled: true
  workflowDefaults:
    spec:
      # make sure workflows do not run forever. Default limit set is 7 days (604800 seconds)
      activeDeadlineSeconds: 604800
      ttlStrategy:
        # keep workflows that succeeded for 1d (86400 seconds).
        # We can still view them since they are archived.
        secondsAfterSuccess: 86400
        # keep workflows that have completed (either successfully or not) for 3d (259200 seconds).
        # We can still view them since they are archived.
        secondsAfterCompletion: 259200
      podGC:
        # Delete pods when workflows are successful.
        # We can still access their logs and artifacts since they are archived.
        # One of "OnPodCompletion", "OnPodSuccess", "OnWorkflowCompletion", "OnWorkflowSuccess"
        strategy: OnWorkflowSuccess
      volumeClaimGC:
        # Delete PVCs when workflows are done. However, due to Kubernetes PVC Protection,
        # such PVCs will just be marked as Terminating, until no pod is using them.
        # Pod deletion (either via the Pod GC strategy or the TTL strategy) will allow to free up
        # attached PVCs.
        # One of "OnWorkflowCompletion", "OnWorkflowSuccess"
        strategy: OnWorkflowCompletion
  persistence:
    archive: true
    postgresql:
      host: "${POSTGRES_RELEASE_NAME}-postgresql"
      database: ${ARGO_DATABASE}
      tableName: workflows
      userNameSecret:
        name: "${ARGO_POSTGRESQL_SECRET_NAME}"
        key: username
      passwordSecret:
        name: "${ARGO_POSTGRESQL_SECRET_NAME}"
        key: password
mainContainer:
  imagePullPolicy: IfNotPresent

EOF

helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install -n "${NAMESPACE}" ${ARGO_RELEASE_NAME} argo/argo-workflows --version ${ARGO_VERSION} --values values-argo.yaml

popd

echo -- Cosmo Tech Api
# cosmotech-api
helm pull oci://ghcr.io/cosmo-tech/cosmotech-api-chart --version "${CHART_PACKAGE_VERSION}"

if [[ "${COSMOTECH_API_DNS_NAME:-}" != "" && "${CERT_MANAGER_ACME:-}" != "" ]]; then
  export COSMOTECH_API_INGRESS_ENABLED=true
else
  export COSMOTECH_API_INGRESS_ENABLED=false
fi
cat <<EOF > values-cosmotech-api-deploy.yaml
replicaCount: 2
api:
  version: "$API_VERSION"

image:
  repository: ghcr.io/cosmo-tech/cosmotech-api
  tag: "$CHART_PACKAGE_VERSION"

config:
  api:
    serviceMonitor:
      enabled: true
      namespace: $MONITORING_NAMESPACE
  csm:
    platform:
      namespace: ${NAMESPACE}
      argo:
        base-uri: "http://${ARGO_RELEASE_NAME}-argo-workflows-server.${NAMESPACE}.svc.cluster.local:2746"
        workflows:
          namespace: ${NAMESPACE}
          service-account-name: ${ARGO_SERVICE_ACCOUNT}
      twincache:
        host: "cosmotechredis-master.${NAMESPACE}.svc.cluster.local"
        port: ${REDIS_PORT}
        username: "default"
        password: "${REDIS_PASSWORD}"

ingress:
  enabled: ${COSMOTECH_API_INGRESS_ENABLED}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "30"
    nginx.org/client-max-body-size: "0"
  hosts:
    - host: "${COSMOTECH_API_DNS_NAME}"
  tls:
    - secretName: ${TLS_SECRET_NAME}
      hosts: [${COSMOTECH_API_DNS_NAME}]

resources:
  # Recommended in production environments
  limits:
    #   cpu: 100m
    memory: 2048Mi
  requests:
    #   cpu: 100m
    memory: 1024Mi

tolerations:
- key: "vendor"
  operator: "Equal"
  value: "cosmotech"
  effect: "NoSchedule"

nodeSelector:
  "cosmotech.com/tier": "services"

EOF

if [[ "${CERT_MANAGER_ENABLED:-false}" == "true" ]]; then
  export CERT_MANAGER_INGRESS_ANNOTATION_SET="--set ingress.annotations.cert-manager\.io/cluster-issuer=letsencrypt-${CERT_MANAGER_ACME}"
else
  export CERT_MANAGER_INGRESS_ANNOTATION_SET=""
fi

helm upgrade --install "${COSMOTECH_API_RELEASE_NAME}" "cosmotech-api-chart-${CHART_PACKAGE_VERSION}.tgz" \
    --namespace "${NAMESPACE}" \
    --version "${CHART_PACKAGE_VERSION}" \
    --values values-cosmotech-api-deploy.yaml \
    ${CERT_MANAGER_INGRESS_ANNOTATION_SET} \
    "${@:5}"

