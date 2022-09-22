echo Creating private DNS zone ${ZONE_NAME}...
az network private-dns zone create --resource-group ${RESOURCE_GROUP} \
   --name  $ZONE_NAME

echo Creating private DNS link ${ZONE_LINK_NAME}...
az network private-dns link vnet create --resource-group ${RESOURCE_GROUP} \
   --zone-name  $ZONE_NAME\
   --name ${ZONE_LINK_NAME} \
   --virtual-network $VNetName \
   --registration-enabled false 

