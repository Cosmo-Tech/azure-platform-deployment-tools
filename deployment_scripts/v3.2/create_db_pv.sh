#!/bin/bash

set -eo errexit

#
# Create a db Persistent Volume
#

help() {
  echo
  echo "This script takes at least 2 parameters."
  echo
  echo "The following optional environment variables can be set to alter this script behavior:"
  echo "- NAMESPACE | string | name of the targeted namespace. Generated when not set"
  echo "- REDIS_DISK_RESOURCE | string | ex: /subscriptions/<my-subscription>/resourceGroups/<my-resource-group>/providers/Microsoft.Compute/disks/<my-disk-name>"
  echo "- REDIS_DISK_SIZE | string | requested disk size (default: 64Gi)"
  echo "- REDIS_MASTER_NAME_PVC | redis master persistent volume claim name (default: cosmotech-database-master-pvc)"
  echo
  echo "Usage: ./$(basename "$0") NAMESPACE REDIS_DISK_RESOURCE REDIS_DISK_SIZE"
}

if [[ "${1:-}" == "--help" ||  "${1:-}" == "-h" ]]; then
  help
  exit 0
fi
if [[ $# -lt 2 ]]; then
  help
  exit 1
fi

export NAMESPACE="$1"
export REDIS_DISK_RESOURCE_VAR="$2"
export REDIS_DISK_SIZE_VAR="$3"

REDIS_PV_NAME=cosmotech-database-master-pv
REDIS_PVC_NAME="${REDIS_MASTER_NAME_PVC:-"cosmotech-database-master-pvc"}"

WORKING_DIR=$(mktemp -d -t create_db_pv-XXXXXXXXXX)
echo "[info] Working directory: ${WORKING_DIR}"
pushd "${WORKING_DIR}"

echo -- "[info] Working directory: ${WORKING_DIR}"

curl -sSL https://raw.githubusercontent.com/Cosmo-Tech/azure-platform-deployment-tools/main/deployment_scripts/v2.1/redis_pv-template.yaml -o redis_pv-template.yaml

REDIS_DISK_RESOURCE=${REDIS_DISK_RESOURCE_VAR} \
REDIS_DISK_SIZE=${REDIS_DISK_SIZE_VAR:-"64Gi"} \
envsubst < "${WORKING_DIR}"/redis_pv-template.yaml > redis_pv.yaml

echo "Deploying DB Persistent Volume"
kubectl apply -n "${NAMESPACE}" -f redis_pv.yaml

rm -rf "${WORKING_DIR}"
