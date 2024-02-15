**How to Secure Azure Function Storage through a Virtual Network**

This guide provides step-by-step instructions on configuring network access policies for an Azure Storage account to restrict access to a specific Azure Function App.

### For an Existing Azure Function App and Storage

**Prerequisites**

- Ensure that the Azure Function App Service plan is an Elastic Premium Plan (EP1, EP2, EP3).
- Confirm that the following Active Directory roles are assigned:

  - Network Contributor on the ressource group
  - Contributor on the Azure Function App
  - Storage Account Contributor


### 1. Create an Azure Virtual Network

Create a Virtual Network (VNet) with two subnets, one for Azure Storage and one for the Azure Function App.

- Navigate to the Microsoft Azure portal, and in the top bar, search for `virtual networks`. Select the "Virtual networks" option.
- Click on `Create`.
- Fill in the required details:
  - Choose your subscription.
  - Select or create a resource group.
  - Enter a unique Virtual Network name.
  - For optimal performance, choose the same `Region/Location` for your resources.
- Navigate to the `IP addresses` tab, click `Add subnet`, and provide a relevant name such as `storagesubnet`. Keep all other settings as default and click `Add`.
- Review the configuration on the `Review + Create` tab, then click `Create`.

### 2. Configure Virtual Network service endpoint

[Configuring service endpoint provides secure and direct connectivity](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview) to Azure services over an optimized route over the Azure backbone network.

- Navigate to the created Virtual Network, then go to `Subnet` and choose the second subnet named `storagesubnet`.
- In the subnet settings, locate `Service Endpoints` and click on it.
- Under the `Services` section, select `Microsoft.Storage`.
- Save the changes to apply the service endpoint configuration.

### 3. Configure Azure Storage Account Network Policies

#### 3.1 Using a Private Endpoint

- Navigate to the Storage Account, then go to `Networking` and select `Firewalls and virtual networks`.
- Change Public network access to `Disabled`.
- Under Network Routing, set the Routing preference to `Microsoft network`.
- In the `Private endpoint connections` tab, click to add a Private Endpoint.
- Choose an Instance Name and Network Interface Name, then click Next.
- In the Resource section, select the target sub-resource as `blob` and click Next.
- Under Virtual Network, choose the second subnet named `storagesubnet` and click Next three times.
- Review the configuration and click Create to complete the setup.

#### 3.2 Using Network Firewall Filter Rules

- Navigate to the Storage Account, then go to `Networking` and select `Firewalls and virtual networks`.
- Change Public network access to `Enabled from selected virtual networks and IP addresses`.
- Under Network Routing, set the Routing preference to `Microsoft network`.
- In `Virtual networks`, click on 'Add existing virtual network'.
- Select the created virtual network.
- Choose the second subnet named `storagesubnet` and click Add.
- In the Firewall section, under Address range, add your organization's VPN IP address if needed to allow connections from your organization's users.

### 4. Configure Azure Function App Network

**Important:** Ensure that the Azure Function App Service plan is an Elastic Premium Plan (EP1, EP2, EP3).

- Navigate to the Azure Function App, then go to `Networking` and in `Outbound traffic configuration`.
- Choose `Virtual network integration configuration`.
- Click on `Add virtual network integration`.
- Select the created virtual network.
- Choose the default subnet, then click `Connect`.

```bash
# Set your variables
subscriptionId="your-subscription-id"
resourceGroupName="your-resource-group-name"
virtualNetworkName="your-virtual-network-name"
location="your-location"
subnetName="storagesubnet"

# Create Virtual Network
az network vnet create \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --name $virtualNetworkName \
  --location $location \
  --address-prefixes "10.0.0.0/16"  # Update with your desired address range

# Add Subnet
az network vnet subnet create \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --vnet-name $virtualNetworkName \
  --name $subnetName \
  --address-prefixes "10.0.1.0/24"  # Update with your desired subnet address range

# Review and create
az network vnet subnet update \
  --subscription $subscriptionId \
  --resource-group $resourceGroupName \
  --vnet-name $virtualNetworkName \
  --name $subnetName \
  --service-endpoints Microsoft.Storage
```