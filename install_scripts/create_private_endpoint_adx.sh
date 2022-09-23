#!/usr/bin/env bash
# Copyright (c) Cosmo Tech.
# Licensed under the MIT license.
echo create_private_endpoint_adx.sh start
echo Mandatory env vars:
echo SP_APPID: the service principal application / client id
echo SP_SECRET: the service principal secret
echo SP_TENANT: the service principal tenant
echo PRIVATE_ENDPOINT_NAME: The private endpoint name to create
echo RESOURCE_GROUP: The resource group where to create the private endpoint 
echo SUBNET_ID: The sub net id linked to the private endpoint
echo RESOURCE_ID: The resource id linked to the private endpoint
echo GROUP_ID: The resource group to link
echo CONNECTION_NAME: The private endpoint connection name
echo DNS_GROUP_NAME: The DNS zone group name
echo ZONE_NAME_ADX: The DNS private zone name for ADX
echo ZONE_NAME_BLOB: The DNS private zone name for blob
echo ZONE_NAME_QUEUE: The DNS private zone name for queue
echo ZONE_NAME_TABLE: The DNS private zone name for table
echo
source ./az_login_as_sp.sh

echo Creating private endpoint ${PRIVATE_ENDPOINT_NAME} for ${RESOURCE_ID} in ${SUBNET_ID}...
az network private-endpoint create \
  --name ${PRIVATE_ENDPOINT_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --subnet ${SUBNET_ID} \
  --private-connection-resource-id ${RESOURCE_ID} \
  --group-id ${GROUP_ID} \
  --connection-name ${CONNECTION_NAME} \
  2>&1 || exit 1

echo Creating private DNS group ${DNS_GROUP_NAME} in ${ZONE_NAME} for ADX cluster...
az network private-endpoint dns-zone-group create \
  --resource-group ${RESOURCE_GROUP} \
  --endpoint-name ${PRIVATE_ENDPOINT_NAME} \
  --name ${DNS_GROUP_NAME} \
  --private-dns-zone ${ZONE_NAME_ADX} \
  --zone-name ${ZONE_NAME_ADX} \
  2>&1 || exit 1

echo Creating private DNS group ${DNS_GROUP_NAME} in ${ZONE_NAME} for ADX blob...
az network private-endpoint dns-zone-group create \
  --resource-group ${RESOURCE_GROUP} \
  --endpoint-name ${PRIVATE_ENDPOINT_NAME} \
  --name ${DNS_GROUP_NAME} \
  --private-dns-zone ${ZONE_NAME_BLOB} \
  --zone-name ${ZONE_NAME_BLOB} \
  2>&1 || exit 1

echo Creating private DNS group ${DNS_GROUP_NAME} in ${ZONE_NAME} for ADX queue...
az network private-endpoint dns-zone-group create \
  --resource-group ${RESOURCE_GROUP} \
  --endpoint-name ${PRIVATE_ENDPOINT_NAME} \
  --name ${DNS_GROUP_NAME} \
  --private-dns-zone ${ZONE_NAME_QUEUE} \
  --zone-name ${ZONE_NAME_QUEUE} \
  2>&1 || exit 1

echo Creating private DNS group ${DNS_GROUP_NAME} in ${ZONE_NAME} for ADX table...
az network private-endpoint dns-zone-group create \
  --resource-group ${RESOURCE_GROUP} \
  --endpoint-name ${PRIVATE_ENDPOINT_NAME} \
  --name ${DNS_GROUP_NAME} \
  --private-dns-zone ${ZONE_NAME_TABLE} \
  --zone-name ${ZONE_NAME_TABLE} \
  2>&1 || exit 1

echo create_private_endpoint_adx.sh end
