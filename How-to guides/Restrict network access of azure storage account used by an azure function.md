# Restrict network access of azure storage account used by an azure function

This method allows to disable the access from all network for a azure storage account used by a azure function in a Consumption plan. The method is based on the IP addresses restriction and not on VNET and private endpoints which requires premium plan (see <https://learn.microsoft.com/en-us/azure/azure-functions/functions-networking-options?tabs=azure-cli#private-endpoints> for details)

## Get the list of possible azure function outbound IPs

- Go to the Azure Resource Explorer resources.azure.com
- Select subscriptions > {your subscription} > providers > Microsoft.Web > sites (or direclty with <https://resources.azure.com/subscriptions/{subscription}/providers/Microsoft.Web/sites> )
- Select the Azure Storage account used by the azure function.
- Get the list of IP from `outboundIpAddresses`

## Set the networking configuration

- Go to the Azure Portal and open the Storage account
- Select `Networking`
- In `Firewall and virtual networks`, `Public network access` choose `Enabled from selected virtual networks and IP addresses`
- Add the IP addresses got in step 1 in the Firewall section `Add IP ranges to allow access from the internet or your on-premises networks`
