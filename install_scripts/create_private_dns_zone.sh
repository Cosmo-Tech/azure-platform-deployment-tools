#!/usr/bin/env bash
# Copyright (c) Cosmo Tech.
# Licensed under the MIT license.
echo create_private_dns_zone.sh start
echo SP_APPID: the service principal application / client id
echo SP_SECRET: the service principal secret
echo SP_TENANT: the service principal tenant
echo ZONE_NAME: the private DNS zone name to create
echo RESOURCE_GROUP: the resource group where to create the private DNS zone
echo ZONE_LINK_NAME: the private DNS zone to vnet link name
echo VNET_ID: the virtual network resource id to connect the private DNS zone to
echo
./az_login_as_sp.sh

echo Creating private DNS zone ${ZONE_NAME} in ${RESOURCE_GROUP}...
az network private-dns zone create \
  --resource-group ${RESOURCE_GROUP} \
  --name  ${ZONE_NAME}

echo Creating private DNS link ${ZONE_LINK_NAME} for ${ZONE_NAME} to ${VNET_ID}...
az network private-dns link vnet create \
  --resource-group ${RESOURCE_GROUP} \
  --zone-name ${ZONE_NAME} \
  --name ${ZONE_LINK_NAME} \
  --virtual-network ${VNET_ID} \
  --registration-enabled false 

echo create_private_dns_zone.sh end
