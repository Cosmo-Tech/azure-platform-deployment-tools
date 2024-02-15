# How to secure Azure Function storage through a virtual network

This is the guide to configure network access policies on an Azure Storage and limit the access to an specific Azure Function App.

## For an existing Azure Function App and Storage

**Requirement**

- The Azure Function App Service plan Must be Elastic Premium Plan (EP1, EP2, EP3)
- 

### 1. Create a Azure Virtual Network

Create a Virtual Network(VNet) with two subnet one for the Azure Storage one for the Azure Function App.

- Go to Microsoft Azure portal search in the top bar `virtual networks` and select virtual networks
- Click on `Create`
- Select : your Subscription , Resource group and Virtual network name. For better performance choose the same `Region/Location` for your resources
- On `IP addresses` tab click `Add subnet` chose a relevant name like `storagesubnet` keep all other default setting the `Add`
- Click `Review + Create` and `Create`

### 2. Configure Virtual Network service endpoint

[Configuring service endpoint provides secure and direct connectivity](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview) to Azure services over an optimized route over the Azure backbone network.

- Go to the created Virtual Network >> `Subnet` >> choose the second subnet name `storagesubnet`
- In   the subnet Settings >> `Service Endpoints` >> Services >> `Select Microsoft.Storage` >> Save

### 3. Configure the Azure Storage Account Network policies


#### 3.1 Using a private endpoint

- Go to the Storage Account >> Networking >> `Firewalls and virtual networks`
- Change Public network access to `Disabled`
- In Network Routing >> Routing preference : choose Microsoft network
- In `Private endpoint connections` Tabs click to add a Private endpoint
- Choose an Instance Name and Network Interface Name then Next
- In Resource >> Target sub-resource select blob then Next
- In Virtual Network select the second subnet name `storagesubnet` then Next tree time and create.

#### 3.2 Using a Network firewall filter rules

- Go to the Storage Account >> Networking >> `Firewalls and virtual networks`
- Change Public network access to `Enabled from selected virtual networks and IP addresses`
- In Network Routing >> Routing preference : choose Microsoft network
- In `Virtual networks`  >> Add existing virtual network
- Select the created virtual network
- Select the second subnet name `storagesubnet` then click Add
- In Firewall >> Address range,  add your organization VPN ip address if needed to allow connection form your organization users

### 4. Configure the Azure Function App Network

Important : The Azure Function App Service plan Must be Elastic Premium Plan (EP1, EP2, EP3)

- Go to the Azure Function App >> Networking >> Outbound traffic configuration >> select Virtual network integration configuration
- Add virtual network integration
- Select the created virtual network
- Select the default subnet then click connect
