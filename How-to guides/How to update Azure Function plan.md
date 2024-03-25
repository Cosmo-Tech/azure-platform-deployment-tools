# How to update Azure Function plan

This guide provides step-by-step instructions on how to update an Azure Function App to a different plan.

## Update the Azure Function App Plan to a Different Tier

The sku property of the function app defines the plan and capacity of the function app.

**Az Cli command**

```bash
# Set your variables
resourceGroupName="YOUR_RESOURCE_GROUP_NAME"
functionPlanName="YOUR_PLAN_NAME"

# Update the function app plan
az functionapp plan update  \
	--resource-group $resourceGroupName \
	--name $functionPlanName \
	--plan $functionPlanName \
	--max-burst 1 --sku EP1
```


## Update Azure Function App with a Different Plan

**Az Cli command**

```bash
# Set your variables
resourceGroupName="YOUR_RESOURCE_GROUP_NAME"
functionAppName="YOUR_FUNCTION_APP_NAME"
functionPlanName="YOUR_PLAN_NAME"

# Update the function app
az functionapp update \
	--resource-group $resourceGroupName \
	--name $functionAppName \
	--plan $functionPlanName
```