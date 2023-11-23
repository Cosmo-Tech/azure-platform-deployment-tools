# Set up private endpoint for on an existing storage account and attach it to the platform virtual network

This how-to guide helps to configure a private endpoint on a existing storage account in order to the disable public network access.

## Set up the variables

```bash
subscription=""
resource_group="" 
vnet_name="" # the platform vnet name
subnet_name=""
subnet_prefix='' # if new subnet needed
storage_account_name=""
```

## Prepare the subnet or create a new one

```bash
# Disable the private endpoint network policies for the subnet
```bash
az network vnet subnet update \
  --name $subnet_name \
  --resource-group $resource_group \
  --vnet-name $vnet_name \
  --disable-private-endpoint-network-policies true
```

```bash
# Or create new subnet 
az network vnet subnet create \
  --name $subnet_name \
  --resource-group $resource_group \
  --vnet-name $vnet_name \
  --address-prefixes $subnet_prefix \
  --disable-private-endpoint-network-policies true
```


## Configure private endpoint

```bash
# get the AKS VNET ID
vnet_id=$(az network vnet list --resource-group $resource_group --query "[?name=='$vnet_name'].id" -o tsv)

# get the subnet ID
subnet_id=$(az network vnet subnet show --resource-group $resource_group --vnet-name $vnet_name  --name $subnet_name --query 'id' --output tsv)


# Block public access
az storage account update \
    --name $storage_account_name \
    --resource-group $resource_group \
    --public-network-access Disabled

private_connection_resource_id=$(az storage account show --name $storage_account_name --resource-group $resource_group --query "id" --output tsv)

 # Create private endpoint
 az network private-endpoint create \
    --resource-group $resource_group \
    --name "storage-privateendpoint" \
    --vnet-name $vnet_name \
    --subnet $subnet_id \
    --private-connection-resource-id $private_connection_resource_id \
    --group-ids "blob" \
    --connection-name "privatestorageconnection"

# Configure private DNS
az network private-dns zone create \
    --resource-group $resource_group \
    --name "privatelink.blob.core.windows.net"

# Link vnet to the Private DNS Zone
az network private-dns link vnet create \
    --resource-group $resource_group \
    --virtual-network $vnet_id \
    --name "PrivateDnsLink1" \
    --zone-name "privatelink.blob.core.windows.net" \
    --registration-enabled false
```
