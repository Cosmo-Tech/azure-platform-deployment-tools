#!/bin/bash
# Copyright (c) Cosmo Tech.
# Licensed under the MIT license.

set -eo errexit

#
# Script that create the k8s structure required by CosmoTech API V2.1 (from v2)
# Should create:
# - 1 disk for cosmotech database
#

help() {
  echo
  echo "This script takes at least 2 parameters."
  echo
  echo
  echo "Usage: ./$(basename "$0") <resource_group> <disk_location>"
  echo
  echo "Example:"
  echo
  echo "- ./$(basename "$0") phoenixdev eastus2 "
  echo "- ./$(basename "$0") phoenixdev eastus2 Premium_LRS"
  echo "- ./$(basename "$0") phoenixdev eastus2 Premium_LRS P6"
  echo "- ./$(basename "$0") phoenixdev eastus2 Premium_LRS P10 128Gi"
  echo
}

if [[ "${1:-}" == "--help" ||  "${1:-}" == "-h" ]]; then
  help
  exit 0
fi
if [[ $# -lt 2 ]]; then
  help
  exit 1
fi

export RESOURCE_GROUP=$1
export DISK_LOCATION=$2
export DISK_SKU=${3:-"Premium_LRS"}
export DISK_TIER=${4:-"P6"}
export DISK_SIZE=${5:-"64Gi"}

echo "Creating 'cosmotech-database-disk' disk..."

az disk create --name "cosmotech-database-disk" \
                      -g "$RESOURCE_GROUP" \
                      --size-gb "$DISK_SIZE" \
                      --location "$DISK_LOCATION" \
                      --sku "$DISK_SKU" \
                      --tier "$DISK_TIER"

echo "... 'cosmotech-database-disk' disk created"
echo "You may need to add kubernetes identity as disk contributor"


