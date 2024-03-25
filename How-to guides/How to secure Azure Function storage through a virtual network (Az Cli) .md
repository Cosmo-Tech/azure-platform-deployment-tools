# How to Secure Azure Function Storage through a Virtual Network

This guide provides step-by-step instructions on configuring network access policies for an Azure Storage account to restrict access to a specific Azure Function App.

## For an Existing Azure Function App and Storage

**Az Cli variables**

```bash
# Set your variables
subscriptionId="YOUR_SUBSCRIPTION_ID"
resourceGroupName="YOUR_RESOURCE_GROUP_NAME"
virtualNetworkName="YOUR_VIRTUAL_NETWORK_NAME"
location="YOUR_LOCATION"
subnetName="YOUR_SUBNET_NAME"
storageAccountName="YOUR_STORAGE_ACCOUNT_NAME"
privateEndPointName="YOUR_PRIVATE_ENDPOINT_NAME"
functionAppName="YOUR_FUNCTION_APP_NAME"
vpnIpAddress="YOUR_VPN_IP_ADDRESS"
```


### 1. Create an Azure Virtual Network


```bash
# Create Virtual Network
az network vnet create \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --name $virtualNetworkName \
  --location $location \
  --address-prefixes "10.0.0.0/16"

# Add default Subnet
az network vnet subnet create \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --vnet-name $virtualNetworkName \
  --name default \
  --address-prefixes "10.0.0.0/24"

# Add storage Subnet
az network vnet subnet create \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --vnet-name $virtualNetworkName \
  --name $subnetName \
  --address-prefixes "10.0.1.0/24"

# Update storage Subnet with Service Endpoints
az network vnet subnet update \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --vnet-name $virtualNetworkName \
  --name $subnetName \
  --service-endpoints Microsoft.Storage
```

### 2. Configure Azure Storage Account Network Policies

#### 2.1 Using a Private Endpoint


```bash
# Disable Public Network Access
az storage account update \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --name $storageAccountName \
  --bypass AzureServices \
  --default-action Deny \
  --publish-internet-endpoints false \
  --publish-microsoft-endpoints true \
  --public-network-access Disabled \
  --routing-choice MicrosoftRouting

# Create Private Endpoint
az network private-endpoint create \
  --resource-group $resourceGroupName \
  --connection-name $privateEndPointName \
  --name $privateEndPointName \
  --private-connection-resource-id $(az storage account show --resource-group $resourceGroupName --name $storageAccountName --query id --output tsv) \
  --vnet-name $virtualNetworkName \
  --group-id blob \
  --subnet $subnetName
```

#### 2.2 Using Network Firewall Filter Rules


```bash
# Enable Public Network Access from Selected Networks
az storage account update \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --name $storageAccountName \
  --bypass AzureServices \
  --default-action Deny \
  --publish-internet-endpoints false \
  --publish-microsoft-endpoints true \
  --public-network-access Enabled \
  --routing-choice MicrosoftRouting

# Add Existing Virtual Network
az storage account network-rule add \
  --resource-group $resourceGroupName \
  --account-name $storageAccountName \
  --vnet-name $virtualNetworkName \
  --subnet $subnetName

# Add VPN IP Address to Firewall Rules (if needed)
az storage account network-rule add \
  --resource-group $resourceGroupName \
  --account-name $storageAccountName \
  --ip-address $vpnIpAddress
```

### 3. Configure Azure Function App Network

```bash
# Add Virtual Network Integration
az functionapp vnet-integration add \
  --resource-group $resourceGroupName \
  --name $functionAppName \
  --vnet $virtualNetworkName \
  --subnet default
```