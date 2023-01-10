#!/bin/bash
# Copyright (c) Cosmo Tech.
# Licensed under the MIT license.

set -eo errexit

#
# Script that create the k8s structure required by CosmoTech API V2
# Should create:
# - 7 nodepool (system, basic, highcpu, highmemory, monitoring, services, db )
# - 1 disk for cosmotech database
#

help() {
  echo
  echo "This script takes at least 4 parameters."
  echo
  echo
  echo "Usage: ./$(basename "$0") <cluster-name> <resource_group> <creation-monitoring-nodepool> <disk_location>"
  echo
  echo "Example:"
  echo
  echo "- ./$(basename "$0") phoenixAKSdev phoenixdev true eastus2 "
  echo "- ./$(basename "$0") phoenixAKSdev phoenixdev true eastus2 Premium_LRS"
  echo "- ./$(basename "$0") phoenixAKSdev phoenixdev false eastus2 Premium_LRS"
  echo "- ./$(basename "$0") phoenixAKSdev phoenixdev false eastus2 Premium_LRS P6 128"
  echo
}

if [[ "${1:-}" == "--help" ||  "${1:-}" == "-h" ]]; then
  help
  exit 0
fi
if [[ $# -lt 4 ]]; then
  help
  exit 1
fi

export CLUSTER_NAME=$1
export RESOURCE_GROUP=$2
export CREATE_MONITORING_NODE_POOL=$3
export DISK_LOCATION=$4
export DISK_SKU=${5:-"Premium_LRS"}
export DISK_TIER=${6:-"P6"}
export DISK_SIZE=${7:-"64"}

echo "Creating 'system' nodepool..."

az aks nodepool add --cluster-name "$CLUSTER_NAME" \
                    -g "$RESOURCE_GROUP" \
                    --name "system" \
                    --node-count 4 \
                    --node-vm-size "Standard_D4d_v4" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 6 \
                    --min-count 3 \
                    --enable-cluster-autoscaler \
                    --mode "System" \
                    --os-type "Linux"

echo "... 'system' nodepool created"

echo "Creating 'basic' nodepool..."

az aks nodepool add --cluster-name "$CLUSTER_NAME" \
                    -g "$RESOURCE_GROUP" \
                    --name "basic" \
                    --node-count 2 \
                    --node-vm-size "Standard_B2s" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 5 \
                    --min-count 1 \
                    --enable-cluster-autoscaler \
                    --labels "cosmotech.com/tier=compute" "cosmotech.com/size=basic" \
                    --node-taints "vendor=cosmotech:NoSchedule" \
                    --mode "User" \
                    --os-type "Linux"

echo "... 'basic' nodepool created"

echo "Creating 'highcpu' nodepool..."

az aks nodepool add --cluster-name "$CLUSTER_NAME" \
                    -g "$RESOURCE_GROUP" \
                    --name "highcpu" \
                    --node-count 0 \
                    --node-vm-size "Standard_F72s_v2" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 3 \
                    --min-count 0 \
                    --enable-cluster-autoscaler \
                    --labels "cosmotech.com/tier=compute" "cosmotech.com/size=highcpu" \
                    --node-taints "vendor=cosmotech:NoSchedule" \
                    --mode "User" \
                    --os-type "Linux"

echo "... 'highcpu' nodepool created"

echo "Creating 'highmemory' nodepool..."

az aks nodepool add --cluster-name "$CLUSTER_NAME" \
                    -g "$RESOURCE_GROUP" \
                    --name "highmemory" \
                    --node-count 0 \
                    --node-vm-size "Standard_E2ads_v5" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 3 \
                    --min-count 0 \
                    --enable-cluster-autoscaler \
                    --labels "cosmotech.com/tier=compute" "cosmotech.com/size=highmemory" \
                    --node-taints "vendor=cosmotech:NoSchedule" \
                    --mode "User" \
                    --os-type "Linux"

echo "... 'highmemory' nodepool created"

echo "Creating 'services' nodepool..."

az aks nodepool add --cluster-name "$CLUSTER_NAME" \
                    -g "$RESOURCE_GROUP" \
                    --name "services" \
                    --node-count 2 \
                    --node-vm-size "Standard_A2m_v2" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 5 \
                    --min-count 2 \
                    --enable-cluster-autoscaler \
                    --labels "cosmotech.com/tier=services" \
                    --node-taints "vendor=cosmotech:NoSchedule" \
                    --mode "User" \
                    --os-type "Linux"

echo "... 'services' nodepool created"

echo "Creating 'db' nodepool..."

az aks nodepool add --cluster-name "$CLUSTER_NAME" \
                    -g "$RESOURCE_GROUP" \
                    --name "db" \
                    --node-count 2 \
                    --node-vm-size "Standard_D2ads_v5" \
                    --node-osdisk-size 128 \
                    --node-osdisk-type "Managed" \
                    --max-pods 110 \
                    --max-count 5 \
                    --min-count 2 \
                    --enable-cluster-autoscaler \
                    --labels "cosmotech.com/tier=db" \
                    --node-taints "vendor=cosmotech:NoSchedule" \
                    --mode "User" \
                    --os-type "Linux"

echo "... 'db' nodepool created"

if [[ "${CREATE_MONITORING_NODE_POOL:-true}" == "true" ]]; then

  echo "Creating 'monitoring' nodepool..."

  az aks nodepool add --cluster-name "$CLUSTER_NAME" \
                      -g "$RESOURCE_GROUP" \
                      --name "monitoring" \
                      --node-count 0 \
                      --node-vm-size "Standard_D2ads_v5" \
                      --node-osdisk-size 128 \
                      --node-osdisk-type "Managed" \
                      --max-pods 110 \
                      --max-count 10 \
                      --min-count 0 \
                      --enable-cluster-autoscaler \
                      --labels "cosmotech.com/tier=monitoring" \
                      --node-taints "vendor=cosmotech:NoSchedule" \
                      --mode "User" \
                      --os-type "Linux"

  echo "... 'monitoring' nodepool created"

fi


echo "Creating 'cosmotech-database-disk' disk..."

az disk create --name "cosmotech-database-disk" \
                      -g "$RESOURCE_GROUP" \
                      --size-gb "$DISK_SIZE" \
                      --location "$DISK_LOCATION" \
                      --sku "$DISK_SKU" \
                      --tier "$DISK_TIER"

echo "... 'cosmotech-database-disk' disk created"


