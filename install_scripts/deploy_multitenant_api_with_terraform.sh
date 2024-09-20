#!/bin/bash

set -e

# TERRAFORM INSTALLER - Automated Terraform Installation
# CHECK DEPENDANCIES AND SET NET RETRIEVAL TOOL
if ! unzip -h 2&> /dev/null; then
  echo "aborting - unzip not installed and required"
  exit 1
fi

if curl -h 2&> /dev/null; then
  nettool="curl"
elif wget -h 2&> /dev/null; then
  nettool="wget"
else
  echo "aborting - wget or curl not installed and required"
  exit 1
fi

if jq --help 2&> /dev/null; then
  nettool="${nettool}jq"
fi

usage() {
  [[ "$1" ]] && echo -e "Download and Install Terraform - Latest Version unless '-i' specified\n"
  echo -e "usage: ${scriptname} [-i VERSION] [-a] [-c] [-h] [-v]"
  echo -e "     -i VERSION\t: specify version to install in format '0.11.8' (OPTIONAL)"
  echo -e "     -a\t\t: automatically use sudo to install to /usr/local/bin (or \$TF_INSTALL_DIR)"
  echo -e "     -c\t\t: leave binary in working directory (for CI/DevOps use)"
  echo -e "     -h\t\t: help"
  echo -e "     -v\t\t: display ${scriptname} version"
}

getLatest() {
  # USE NET RETRIEVAL TOOL TO GET LATEST VERSION
  case "${nettool}" in
    # jq installed - parse version from hashicorp website
    wgetjq)
      LATEST_ARR=($(wget -q -O- https://releases.hashicorp.com/index.json 2>/dev/null | jq -r '.terraform.versions[].version' | sort -t. -k 1,1nr -k 2,2nr -k 3,3nr))
      ;;
    curljq)
      LATEST_ARR=($(curl -s https://releases.hashicorp.com/index.json 2>/dev/null | jq -r '.terraform.versions[].version' | sort -t. -k 1,1nr -k 2,2nr -k 3,3nr))
      ;;
    # parse version from github API
    wget)
      LATEST_ARR=($(wget -q -O- https://api.github.com/repos/hashicorp/terraform/releases 2> /dev/null | awk '/tag_name/ {print $2}' | cut -d '"' -f 2 | cut -d 'v' -f 2))
      ;;
    curl)
      LATEST_ARR=($(curl -s https://api.github.com/repos/hashicorp/terraform/releases 2> /dev/null | awk '/tag_name/ {print $2}' | cut -d '"' -f 2 | cut -d 'v' -f 2))
      ;;
  esac

# make sure latest version isn't beta or rc
for ver in "${LATEST_ARR[@]}"; do
  if [[ ! $ver =~ beta ]] && [[ ! $ver =~ rc ]] && [[ ! $ver =~ alpha ]]; then
    LATEST="$ver"
    break
  fi
done
echo -n "$LATEST"
}

while getopts ":i:ach" arg; do
  case "${arg}" in
    a)  sudoInstall=true;;
    c)  cwdInstall=true;;
    i)  VERSION=${OPTARG};;
    h)  usage x; exit;;
    \?) echo -e "Error - Invalid option: $OPTARG"; usage; exit;;
    :)  echo "Error - $OPTARG requires an argument"; usage; exit 1;;
  esac
done
shift $((OPTIND-1))

# POPULATE VARIABLES NEEDED TO CREATE DOWNLOAD URL AND FILENAME
if [[ -z "$VERSION" ]]; then
  VERSION=$(getLatest)
fi
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "linux" ]]; then
  PROC=$(lscpu 2> /dev/null | awk '/Architecture/ {if($2 == "x86_64") {print "amd64"; exit} else if($2 ~ /arm/) {print "arm"; exit} else if($2 ~ /aarch64/) {print "arm"; exit} else {print "386"; exit}}')
  if [[ -z $PROC ]]; then
    PROC=$(cat /proc/cpuinfo | awk '/model\ name/ {if($0 ~ /ARM/) {print "arm"; exit}}')
  fi
  if [[ -z $PROC ]]; then
    PROC=$(cat /proc/cpuinfo | awk '/flags/ {if($0 ~ /lm/) {print "amd64"; exit} else {print "386"; exit}}')
  fi
else
  PROC="amd64"
fi
[[ $PROC =~ arm ]] && PROC="arm"  # terraform downloads use "arm" not full arm type

# CREATE FILENAME AND URL FROM GATHERED PARAMETERS
FILENAME="terraform_${VERSION}_${OS}_${PROC}.zip"
LINK="https://releases.hashicorp.com/terraform/${VERSION}/${FILENAME}"
SHALINK="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_SHA256SUMS"

# TEST CALCULATED LINKS
case "${nettool}" in
  wget*)
    LINKVALID=$(wget --spider -S "$LINK" 2>&1 | grep "HTTP/" | awk '{print $2}')
    SHALINKVALID=$(wget --spider -S "$SHALINK" 2>&1 | grep "HTTP/" | awk '{print $2}')
    ;;
  curl*)
    LINKVALID=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "$LINK")
    SHALINKVALID=$(curl -o /dev/null --silent --head --write-out '%{http_code}\n' "$SHALINK")
    ;;
esac

# VERIFY LINK VALIDITY
if [[ "$LINKVALID" != 200 ]]; then
  echo -e "Cannot Install - Download URL Invalid"
  echo -e "\nParameters:"
  echo -e "\tVER:\t$VERSION"
  echo -e "\tOS:\t$OS"
  echo -e "\tPROC:\t$PROC"
  echo -e "\tURL:\t$LINK"
  exit 1
fi

# VERIFY SHA LINK VALIDITY
if [[ "$SHALINKVALID" != 200 ]]; then
  echo -e "Cannot Install - URL for Checksum File Invalid"
  echo -e "\tURL:\t$SHALINK"
  exit 1
fi

# DETERMINE DESTINATION
if [[ "$cwdInstall" ]]; then
  BINDIR=$(pwd)
elif [[ -n "$TF_INSTALL_DIR" ]]; then
  BINDIR="$TF_INSTALL_DIR"
  CMDPREFIX="${sudoInstall:+sudo }"
  STREAMLINED=true
elif [[ -w "/usr/local/bin" ]]; then
  BINDIR="/usr/local/bin"
  CMDPREFIX=""
  STREAMLINED=true
elif [[ "$sudoInstall" ]]; then
  BINDIR="/usr/local/bin"
  CMDPREFIX="sudo "
  STREAMLINED=true
else
  echo -e "Terraform Installer\n"
  echo "Specify install directory (a,b or c):"
  echo -en "\t(a) '~/bin'    (b) '/usr/local/bin' as root    (c) abort : "
  read -r -n 1 SELECTION
  echo
  if [ "${SELECTION}" == "a" ] || [ "${SELECTION}" == "A" ]; then
    BINDIR="${HOME}/bin"
    CMDPREFIX=""
  elif [ "${SELECTION}" == "b" ] || [ "${SELECTION}" == "B" ]; then
    BINDIR="/usr/local/bin"
    CMDPREFIX="sudo "
  else
    exit 0
  fi
fi

# CREATE TMPDIR FOR EXTRACTION
if [[ ! "$cwdInstall" ]]; then
  TMPDIR=${TMPDIR:-/tmp}
  UTILTMPDIR="terraform_${VERSION}"

  cd "$TMPDIR" || exit 1
  mkdir -p "$UTILTMPDIR"
  cd "$UTILTMPDIR" || exit 1
fi

# DOWNLOAD ZIP AND CHECKSUM FILES
case "${nettool}" in
  wget*)
    wget -q "$LINK" -O "$FILENAME"
    wget -q "$SHALINK" -O SHAFILE
    ;;
  curl*)
    curl -s -o "$FILENAME" "$LINK"
    curl -s -o SHAFILE "$SHALINK"
    ;;
esac

# VERIFY ZIP CHECKSUM
if shasum -h 2&> /dev/null; then
  expected_sha=$(cat SHAFILE | grep "$FILENAME" | awk '{print $1}')
  download_sha=$(shasum -a 256 "$FILENAME" | cut -d' ' -f1)
  if [ $expected_sha != $download_sha ]; then
    echo "Download Checksum Incorrect"
    echo "Expected: $expected_sha"
    echo "Actual: $download_sha"
    exit 1
  fi
fi

# EXTRACT ZIP
unzip -qq "$FILENAME" || exit 1

# COPY TO DESTINATION
if [[ ! "$cwdInstall" ]]; then
  mkdir -p "${BINDIR}" || exit 1
  ${CMDPREFIX} mv terraform "$BINDIR" || exit 1
  # CLEANUP AND EXIT
  cd "${TMPDIR}" || exit 1
  rm -rf "${UTILTMPDIR}"
  [[ ! "$STREAMLINED" ]] && echo
  echo "Terraform Version ${VERSION} installed to ${BINDIR}"
else
  rm -f "$FILENAME" SHAFILE
  echo "Terraform Version ${VERSION} downloaded"
fi
# TERRAFORM INSTALLED

################## REPOSITORIES ##################

# ./platform-infra-core
# ./platform-infra-tenant
# ./platform-k8s-core
# ./platform-k8s-tenant

################## REPOSITORIES ##################

################## GLOBAL VARIABLES GLOBAL ##################
core="platform-infra-core"
tenant="platform-infra-tenant"
core_k8s="platform-k8s-core"
tenant_k8s="platform-k8s-tenant"
file_infra_core="terraform.infra.core.tfvars"
file_k8s_core="terraform.k8s.core.tfvars"
file_infra_tenant="terraform.infra.tenant.tfvars"
file_k8s_tenant="terraform.k8s.tenant.tfvars"
number=$RANDOM
################## GLOBAL VARIABLES ##################

################## DEPLOY CORE ##################
git clone -b marketplace-rc https://github.com/Cosmo-Tech/terraform-azure-cosmotech-common.git $core

echo """
terraform {
  backend "azurerm" {}
}
""" > $core/providers.azure.tf

echo "running terraform init: $core"
terraform -chdir=$core init \
    -backend-config "resource_group_name=$TF_VAR_tf_resource_group_name" \
    -backend-config "storage_account_name=$TF_VAR_tf_storage_account_name" \
    -backend-config "container_name=$TF_VAR_tf_container_name" \
    -backend-config "key=${TF_VAR_kubernetes_cluster_name}-infra-core-$number" \
    -backend-config "access_key=$TF_VAR_tf_access_key"

echo installing tfvars in $core
echo """
client_id                = \"$TF_VAR_client_id\"
network_sp_client_id     = \"$TF_VAR_network_sp_client_id\"
client_secret            = \"$TF_VAR_client_secret\"
network_sp_client_secret = \"$TF_VAR_network_sp_client_secret\"
subscription_id          = \"$TF_VAR_subscription_id\"
tenant_id                = \"$TF_VAR_tenant_id\"
location                 = \"$TF_VAR_location\"
owner_list               = [\"$TF_VAR_owner_list\"]

# project
project_customer_name = \"cosmotech\"
project_name          = \"$TF_VAR_project_name\"

# publicip
network_publicip_name = \"$TF_VAR_publicip_name\"

# network
network_dns_zone_name           = \"api.cosmo-platform.com\"
network_api_dns_name            = \"$TF_VAR_network_api_dns_name\"
network_dns_record              = \"$TF_VAR_network_dns_record\"
network_dns_record_create       = false
network_publicip_resource_group = \"$TF_VAR_network_publicip_resource_group\"
network_resource_group          = \"$TF_VAR_network_resource_group\"

# kubernetes
kubernetes_version        = \"$TF_VAR_kubernetes_version\"
kubernetes_resource_group = \"$TF_VAR_kubernetes_resource_group\"
kubernetes_cluster_name   = \"$TF_VAR_kubernetes_cluster_name\"

is_bare_metal = false
""" > $PWD/$file_infra_core

az storage blob upload \
    --account-name $TF_VAR_tf_storage_account_name \
    --container-name $TF_VAR_tf_container_name \
    --name $file_infra_core \
    --file $PWD/$file_infra_core \
    --auth-mode key \
    --account-key $TF_VAR_tf_access_key

terraform -chdir=$core plan -out tfplan_core -var-file $PWD/$file_infra_core
terraform -chdir=$core apply tfplan_core

################## DEPLOY CORE ##################

################## EXPORT CORE OUTPUT ##################

terraform -chdir=$core output > $PWD/out_core.txt
sed -i 's/ = /=/' $PWD/out_core.txt
sed -i 's/out_/export TF_VAR_/' $PWD/out_core.txt

source $PWD/out_core.txt

################## EXPORT CORE OUTPUT ##################


################## DEPLOY CORE K8S ##################
git clone -b azure https://github.com/Cosmo-Tech/terraform-kubernetes-cosmotech-common.git $core_k8s

echo """
terraform {
  backend "azurerm" {}
}
""" > $core_k8s/providers.azure.tf

echo "running terraform init: $core_k8s"
terraform -chdir=$core_k8s init \
    -backend-config "resource_group_name=$TF_VAR_tf_resource_group_name" \
    -backend-config "storage_account_name=$TF_VAR_tf_storage_account_name" \
    -backend-config "container_name=$TF_VAR_tf_container_name" \
    -backend-config "key=${TF_VAR_kubernetes_cluster_name}-k8s-core-$number" \
    -backend-config "access_key=$TF_VAR_tf_access_key"

echo "installing tfvars in $core_k8s"
echo """
client_id     = \"$TF_VAR_client_id\"
client_secret = \"$TF_VAR_client_secret\"

# argocd
argocd_deploy                  = true
argocd_helm_chart              = \"argo-cd\"
argocd_helm_chart_version      = \"7.5.0\"
argocd_helm_release_name       = \"argocd\"
argocd_helm_repo_url           = \"https://argoproj.github.io/argo-helm\"
argocd_replicas                = 3
argocd_create_ingress          = false
argocd_namespace               = \"argocd\"
argocd_project                 = \"phoenix\"
argocd_setup_job_image_version = \"v2.0.5\"
argocd_repositories = [
  {
    url      = \"https://github.com/Cosmo-Tech/cosmotech-api.git\"
    private  = false
    username = \"\"
    token    = \"\"
  }
]

# vault
vault_deploy             = true
vault_helm_chart         = \"vault\"
vault_helm_chart_version = \"0.28.1\"
vault_helm_release_name  = \"vault\"
vault_helm_repo_url      = \"https://helm.releases.hashicorp.com\"
vault_namespace          = \"vault\"
vault_replicas           = 3
vault_secret_name        = \"vault-token-secret\"
vault_ingress_enabled    = true

# VSOPS
vault_secrets_operator_deploy             = false
vault_secrets_operator_helm_chart         = \"vault-secrets-operator\"
vault_secrets_operator_helm_chart_version = \"0.8.1\"
vault_secrets_operator_helm_release_name  = \"vault-secrets-operator\"
vault_secrets_operator_helm_repo_url      = \"https://helm.releases.hashicorp.com\"
vault_secrets_operator_namespace          = \"vault-secrets-operator\"
vault_secrets_operator_vault_address      = \"http://vault.vault.svc.cluster.local:8200\"
vault_secrets_operator_replicas           = 1

# prometheus
prometheus_stack_deploy   = true
prom_redis_host_namespace = \"$TF_VAR_kubernetes_tenant_namespace\"

# network
keycloak_ingress_hostname = \"$TF_VAR_network_api_dns_name\"
publicip_address          = \"$TF_VAR_loadbalancer_ip\"
api_dns_name              = \"$TF_VAR_network_api_dns_name\"

certificate_cert_content  = \"$TF_VAR_tls_certificate_custom_certificate\"
certificate_key_content   = \"$TF_VAR_tls_certificate_custom_key\"
tls_certificate_type      = \"$TF_VAR_tls_certificate_type\"

nginx_deploy    = true
cert_deploy     = true
loki_deploy     = true
keycloak_deploy = false
is_bare_metal   = false

""" > $PWD/$file_k8s_core

az storage blob upload \
    --account-name $TF_VAR_tf_storage_account_name \
    --container-name $TF_VAR_tf_container_name \
    --name $file_k8s_core \
    --file $PWD/$file_k8s_core \
    --auth-mode key \
    --account-key $TF_VAR_tf_access_key

terraform -chdir=$core_k8s plan -out tfplan_core_k8s -var-file $PWD/$file_k8s_core
terraform -chdir=$core_k8s apply tfplan_core_k8s

################## DEPLOY CORE K8S ##################




################## DEPLOY TENANT INFRA ##################
git clone -b marketplace-rc https://github.com/Cosmo-Tech/terraform-azure-cosmotech-tenant.git $tenant

echo """
terraform {
  backend "azurerm" {}
}
""" > $tenant/providers.azure.tf

echo "running terraform init: $tenant"
terraform -chdir=$tenant init \
    -backend-config "resource_group_name=$TF_VAR_tf_resource_group_name" \
    -backend-config "storage_account_name=$TF_VAR_tf_storage_account_name" \
    -backend-config "container_name=$TF_VAR_tf_container_name" \
    -backend-config "key=${TF_VAR_kubernetes_cluster_name}-infra-tenant-$number" \
    -backend-config "access_key=$TF_VAR_tf_access_key"

echo "installing tfvars in $tenant"
echo """
# azure
client_id                            = \"$TF_VAR_client_id\"
client_secret                        = \"$TF_VAR_client_secret\"
owner_list                           = [\"$TF_VAR_owner_list\"]
location                             = \"$TF_VAR_location\"
network_tenant_address_prefix        = \"10.31.0.0/21\"
network_tenant_subnet_address_prefix = \"10.31.0.0/21\"
tenant_resource_group                = \"$TF_VAR_kubernetes_tenant_namespace\"
backup_create                        = false

# network
api_dns_name              = \"$TF_VAR_network_api_dns_name\"

# kubernetes
kubernetes_tenant_namespace = \"$TF_VAR_kubernetes_tenant_namespace\"
cluster_name                = \"$TF_VAR_kubernetes_cluster_name\"

# adx
kusto_deploy = false

# eventhub
create_eventhub = false

# rabbitmq
create_rabbitmq = true

# storage
storage_public_network_access_enabled = true

# cosmotech api
cosmotech_api_version               = \"$TF_VAR_cosmotech_api_version\"
cosmotech_api_chart_package_version = \"$TF_VAR_cosmotech_api_chart_package_version\"
cosmotech_api_version_path          = \"$TF_VAR_cosmotech_api_version_path\"

# project
project_stage     = \"Dev\"
storage_class_sku = \"Standard_LRS\"
project_name      = \"$TF_VAR_kubernetes_cluster_name\"

# redis
redis_disk_size_gb = 64
redis_disk_sku     = \"Premium_LRS\"
redis_disk_tier    = \"P6\"

# vault
vault_create_entries = false
vault_address        = \"http://vault.vault.svc.cluster.local\"
vault_namespace      = \"vault\"
vault_sops_namespace = \"vault-secrets-operator\"

# platform config
services_secrets_create = true
create_platform_config  = false
platform_name           = \"$TF_VAR_kubernetes_tenant_namespace\"
allowed_namespace       = \"$TF_VAR_kubernetes_tenant_namespace\"
organization_name       = \"$TF_VAR_kubernetes_tenant_namespace\"
identifier_uri          = \"api://$TF_VAR_tenant_client_id\"
engine_secret           = \"$TF_VAR_kubernetes_tenant_namespace\"

""" > $PWD/$file_infra_tenant

az storage blob upload \
    --account-name $TF_VAR_tf_storage_account_name \
    --container-name $TF_VAR_tf_container_name \
    --name $file_infra_tenant \
    --file $PWD/$file_infra_tenant \
    --auth-mode key \
    --account-key $TF_VAR_tf_access_key

terraform -chdir=$tenant plan -out tfplan_tenant -var-file $PWD/$file_infra_tenant
terraform -chdir=$tenant apply tfplan_tenant

################## DEPLOY TENANT INFRA ##################

################## EXPORT TENANT INFRA OUTPUT ##################

terraform -chdir=$tenant output > $PWD/out_tenant.txt
sed -i 's/ = /=/' $PWD/out_tenant.txt
sed -i 's/<sensitive>/""/' $PWD/out_tenant.txt
sed -i 's/out_/export TF_VAR_/' $PWD/out_tenant.txt

source $PWD/out_tenant.txt
################## EXPORT TENANT INFRA OUTPUT ##################

# out_core.txt
# out_tenant.txtterraform-azure-cosmotech-common


################# DEPLOY TENANT K8S ##################
git clone -b azure https://github.com/Cosmo-Tech/terraform-kubernetes-cosmotech-tenant.git $tenant_k8s

echo """
terraform {
  backend "azurerm" {}
}
""" > $tenant_k8s/providers.azure.tf

echo "running terraform init: $tenant_k8s"
terraform -chdir=$tenant_k8s init \
    -backend-config "resource_group_name=$TF_VAR_tf_resource_group_name" \
    -backend-config "storage_account_name=$TF_VAR_tf_storage_account_name" \
    -backend-config "container_name=$TF_VAR_tf_container_name" \
    -backend-config "key=${TF_VAR_kubernetes_cluster_name}-k8s-tenant-$number" \
    -backend-config "access_key=$TF_VAR_tf_access_key"

echo "installing tfvars in $tenant_k8s"
echo """
client_id     = \"$TF_VAR_client_id\"
client_secret = \"$TF_VAR_client_secret\"

kubernetes_tenant_namespace = \"$TF_VAR_kubernetes_tenant_namespace\"
tenant_resource_group       = \"$TF_VAR_tenant_resource_group\"
cluster_name                = \"$TF_VAR_kubernetes_cluster_name\"

# api
deploy_api                          = true
cosmotech_api_version               = \"$TF_VAR_cosmotech_api_version\"
cosmotech_api_chart_package_version = \"$TF_VAR_cosmotech_api_chart_package_version\"
cosmotech_api_version_path          = \"$TF_VAR_cosmotech_api_version_path\"
identity_token_url                  = \"https://login.microsoftonline.com/$TF_VAR_tenant_id/oauth2/v2.0/token\"
identity_authorization_url          = \"https://login.microsoftonline.com/$TF_VAR_tenant_id/oauth2/v2.0/authorize\"

# network
api_dns_name              = \"$TF_VAR_network_api_dns_name\"

argo_deploy       = true
cert_deploy       = true
postgresql_deploy = true
redis_deploy      = true
rabbitmq_deploy   = true
minio_deploy      = true
tls_deploy        = false

# terraform mode
postgresql_secrets_config_create = false
create_rabbitmq_secret           = false

# vault
create_platform_config  = false
vault_engine_secret     = false
allowed_namespace       = \"$TF_VAR_kubernetes_tenant_namespace\"

tenant_sp_client_id     = \"$TF_VAR_tenant_client_id\"
tenant_sp_client_secret = \"$TF_VAR_tenant_client_secret\"

""" > $PWD/$file_k8s_tenant

az storage blob upload \
    --account-name $TF_VAR_tf_storage_account_name \
    --container-name $TF_VAR_tf_container_name \
    --name $file_k8s_tenant \
    --file $PWD/$file_k8s_tenant \
    --auth-mode key \
    --account-key $TF_VAR_tf_access_key

terraform -chdir=$tenant_k8s plan -out tfplan_tenant_k8s -var-file $PWD/$file_k8s_tenant
terraform -chdir=$tenant_k8s apply tfplan_tenant_k8s

################## DEPLOY TENANT K8S ##################


# GENERATE AND UPLOAD terraform.tfvars TO AZURE BLOB

echo "Generating terraform.tfvars..."

output_file="terraform.all.tfvars"

rm -f "$PWD/$output_file"

# Iterate all environment variables and generate the tfvars file
while IFS='=' read -r name value ; do
    # Check if the variable starts with TF_VAR_
    if [[ $name == TF_VAR_* ]] ; then
        # Extract the variable name without the TF_VAR_ prefix
        var_name=${name}
        # Write the variable to the tfvars file
        echo "export $var_name=\"$value\"" >> "$PWD/$output_file"
    fi
done < <(env)

echo "File $PWD/$output_file generated successfully."

# Upload the file to Azure Blob Storage
echo "Uploading $PWD/$output_file to Azure Blob Storage..."

az storage blob upload \
    --account-name $TF_VAR_tf_storage_account_name \
    --container-name $TF_VAR_tf_container_name \
    --name $output_file \
    --file $PWD/$output_file \
    --auth-mode key \
    --account-key $TF_VAR_tf_access_key

echo "File $PWD/$output_file uploaded to Azure Blob Storage successfully."

# End of script
echo "Deployment and configuration completed."

# terraform.marketplace.tfvars
# terraform.infra.core.tfvars
# terraform.k8s.core.tfvars
# terraform.infra.tenant.tfvars
# terraform.k8s.tenant.tfvars