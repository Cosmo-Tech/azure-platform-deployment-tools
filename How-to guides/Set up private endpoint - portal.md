# Set up private endpoint for on an existing storage account and attach it to the platform virtual network

This how-to guide helps to configure a private endpoint on a existing storage account in order to the disable public network access.

## Create a private DNS zone

Skip this step if the desired DNS zone already exists

- In the Azure Portal, search for `private DNS zone`
- Select Create private dns zone
  - Resource group
  - Name : `privatelink.blob.core.windows.net`
  - Select the resource group location

## Disable the private endpoint network policies for the subnet

- Go to the Azure Portal and open virtual network
- In `subnets`, select the subnet you want to attach the storage
- In `NETWORK POLICY FOR PRIVATE ENDPOINTS`, remove the policies

## Create the private endpoint

- Go to the Azure Portal and open the Storage Account
- Select `Networking` > `Private endpoint connections` > + `Private endpoint`
- in the `Create a private endpoint` page
  - Basics
    - Subscription / Resource group
    - Name : "storage-privateendpoint"
    - Network Interface Name : "private-endpoint-nic{number}"
  - Resource
    - Target sub-resource : `blob`
  - Virtual Network
    - Virtual Network : select the platform vnet
    - Subnet : select the subnet
    - Private IP configuration : Dynamically allocate IP address
  - DNS
    - Integrate with private DNS zone : Yes
    - select subscription / resource group / private DNS zone (private DNS zone = `privatelink.blob.core.windows.net`)

## Disable Public network access

- In the Storage Account page
- Select `Networking` > `Firewalls and virtual networks`
  - Disable `Public network access`
