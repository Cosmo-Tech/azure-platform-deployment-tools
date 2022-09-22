#!/usr/bin/env bash
# Copyright (c) Cosmo Tech.
# Licensed under the MIT license.
echo create_private_dns_zone.sh start
./az_login_customer_sp.sh

echo Creating private DNS zone ${ZONE_NAME}...
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
