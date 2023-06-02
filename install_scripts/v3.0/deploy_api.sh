mkdir -p /tmp/deploy-$$
pushd /tmp/deploy-$$
export PATH="$(pwd):$PATH"
echo "Downloading kubectl"
az aks install-cli \
    --install-location ./kubectl \
    --kubelogin-install-location ./kubelogin 2>&1 || exit 1
echo "Getting AKS cluster credentials"
az aks get-credentials \
    --subscription $SUBSCRIPTION \
    --resource-group $RESOURCE_GROUP --name $AKS_NAME 2>&1 || exit 1
echo "Downloading Helm"
curl -SsL -o helm.tar.gz $HELM_DOWNLOAD_URL
echo "Uncompressing Helm"
gunzip -c helm.tar.gz | tar xf - --strip-components=1
echo "Downloading envsubst"
curl -SsL https://github.com/a8m/envsubst/releases/download/v1.2.0/envsubst-$(uname -s)-$(uname -m) -o envsubst
chmod +x envsubst
# az extension add --name aks-preview
echo "Generating password for Argo"
ARGO_PASS="$(openssl rand -base64 32)"
echo "Retrieving public IP address if needed: $PUBLIC_IP_NEW_OR_EXISTING_OR_NONE"
# Retrieve the public IP Address
if [[ "$PUBLIC_IP_NEW_OR_EXISTING_OR_NONE" == "none" ]]; then
    echo "Client requested no public IP at all => unsetting NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP and COSMOTECH_API_DNS_NAME envvars, if any"
    unset NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP || true
    unset COSMOTECH_API_DNS_NAME || true
elif [[ "$PUBLIC_IP_NEW_OR_EXISTING_OR_NONE" == "new" ]]; then
    echo "Using new public IP address => unsetting NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP so as to use the auto-created public IP address of the AKS node resource group."
    echo "In this case, if you need to configure an access via a fully-qualified domain name, you will need to manually find this public IP address and register your DNS records accordingly."
    unset NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP || true
elif [[ "$PUBLIC_IP_NEW_OR_EXISTING_OR_NONE" == "existing" ]]; then
    echo "Using existing public IP address: $NGINX_INGRESS_CONTROLLER_LOADBALANCER_IP"
    echo "Setting NGINX_INGRESS_CONTROLLER_HELM_ADDITIONAL_OPTIONS with the public IP resource group: $PUBLIC_IP_RESOURCE_GROUP"
    export NGINX_INGRESS_CONTROLLER_HELM_ADDITIONAL_OPTIONS="--set controller.service.annotations.\"service\.beta\.kubernetes\.io/azure-load-balancer-resource-group\"=$PUBLIC_IP_RESOURCE_GROUP"
fi
echo "Computing the API Version"
if [[ "$COSMOTECH_API_PACKAGE_VERSION" == "latest" ]]; then
    export COSMOTECH_API_VERSION=latest
else
    export firstPart=$(echo "$COSMOTECH_API_PACKAGE_VERSION" | cut -d '.' -f1)
    if [[ $firstPart == "v*" ]]; then
        export COSMOTECH_API_VERSION="$firstPart"
    else
        export COSMOTECH_API_VERSION="v$firstPart"
    fi
fi
if [[ "$TLS_CERTIFICATE_TYPE" == "custom" ]]; then
    echo "Fetching the custom TLS Certificate"
    echo "$TLS_CERTIFICATE_CUSTOM_CERTIFICATE" > certificate.crt
    export TLS_CERTIFICATE_CUSTOM_CERTIFICATE_PATH=$(realpath ./certificate.crt)
    echo "Fetching the custom TLS Certificate Key"
    echo "$TLS_CERTIFICATE_CUSTOM_KEY" > certificate_key.key
    export TLS_CERTIFICATE_CUSTOM_KEY_PATH=$(realpath ./certificate_key.key)
fi
export PATH="$(pwd):$PATH"
export ESCAPED_APP_SCOPE=${APP_SCOPE//\./\\\.}
echo "Running the deployment script"
# TODO config.csm.platform.azure.credentials.{tenantId,clientId,clientSecret} are deprecated but still supported in the Helm Chart.
#  Make sure to replace them by config.csm.platform.azure.credentials.core.{tenantId,clientId,clientSecret} once the Helm Chart no longer
#  supports such keys.
curl -o- -sSL https://raw.githubusercontent.com/Cosmo-Tech/azure-platform-deployment-tools/main/deployment_scripts/v3.0/deploy_via_helm.sh | bash -s -- \
    $COSMOTECH_API_PACKAGE_VERSION \
    $NAMESPACE \
    $ARGO_PASS \
    $COSMOTECH_API_VERSION \
    --wait \
    --set config.csm.platform.azure.credentials.tenantId="$APP_TENANT_ID" \
    --set config.csm.platform.azure.credentials.clientId="$APP_CLIENT_ID" \
    --set config.csm.platform.azure.credentials.clientSecret="$APP_CLIENT_SECRET" \
    --set config.csm.platform.azure.credentials.customer.tenantId="$TENANT" \
    --set config.csm.platform.azure.credentials.customer.clientId="$CUSTOMER_SERVICE_PRINCIPAL_APPID" \
    --set config.csm.platform.azure.credentials.customer.clientSecret="$CUSTOMER_SERVICE_PRINCIPAL_SECRET" \
    --set config.csm.platform.azure.appIdUri="$APP_SCOPE" \
    --set config.csm.platform.identityProvider.code="azure" \
    --set config.csm.platform.identityProvider.authorizationUrl="https://login.microsoftonline.com/$TENANT/oauth2/v2.0/authorize" \
    --set config.csm.platform.identityProvider.tokenUrl="https://login.microsoftonline.com/$TENANT/oauth2/v2.0/token" \
    --set config.csm.platform.identityProvider.defaultScopes."\[${ESCAPED_APP_SCOPE}/platform\]"="Platform scope" \
    --set config.csm.platform.identityProvider.containerScopes."\[${ESCAPED_APP_SCOPE}/\.default\]"="Platform scope" \
    --set "config.csm.platform.authorization.allowed-tenants={$TENANT}" \
    --set config.csm.platform.azure.dataWarehouseCluster.baseUri=$KUSTO_URI \
    --set config.csm.platform.azure.dataWarehouseCluster.options.ingestionUri=$KUSTO_INGEST_URI \
    --set config.csm.platform.azure.eventBus.baseUri=$EVENTHUB_AMQPS \
    --set config.csm.platform.azure.eventBus.authentication.strategy="$EVENTHUB_AUTHENTICATION_STRATEGY" \
    --set config.csm.platform.azure.eventBus.authentication.sharedAccessPolicy.namespace.name="$EVENTHUB_NAMESPACE_SHARED_ACCESS_POLICY_NAME" \
    --set config.csm.platform.azure.eventBus.authentication.sharedAccessPolicy.namespace.key="$EVENTHUB_NAMESPACE_SHARED_ACCESS_POLICY_KEY" \
    --set config.csm.platform.azure.storage.account-name=$STORAGE_ACCOUNT_NAME \
    --set config.csm.platform.azure.storage.account-key="$STORAGE_KEY" \
    --set csm.platform.azure.containerRegistries.solutions=$ACR_LOGIN_SERVER \
    --set argo.imageCredentials.registry=$ACR_LOGIN_SERVER \
    --set argo.imageCredentials.username=$ACR_LOGIN_USERNAME \
    --set argo.imageCredentials.password=$ACR_LOGIN_PASSWORD \
    --set argo.storage.class.parameters.skuName="$KUBERNETES_AZURE_FILE_STORAGE_CLASS_SKU" \
    --set argo.storage.class.parameters.tags="$KUBERNETES_AZURE_FILE_STORAGE_TAGS" \
    2>&1 || exit 1
popd
echo "Done installing cosmotech-api and all its dependencies in the managed app Kubernetes cluster! Enjoy ;)"
#PROD-7753
echo "Updating the AKS Cluster with the authorized IP ranges: $AKS_AUTHORIZED_IP_RANGES..."
# This feature is purposely non-blocking for now, as there is a permission issue when users pick an existing VNet from a separate resource group:
# Error message: ERROR: (LinkedAuthorizationFailed) The client 'XXX' with object id 'XXX' has permission to perform action
# 'Microsoft.ContainerService/managedClusters/write' on scope
# '/subscriptions/XXX/resourceGroups/<managed_rg>/providers/Microsoft.ContainerService/managedClusters/<aks_name>';
# however, it does not have permission to perform action 'Microsoft.Network/virtualNetworks/subnets/join/action' on the linked scope(s)
# '/subscriptions/XXX/resourceGroups/<existing_rg>/providers/Microsoft.Network/virtualNetworks/<existing_vnet>/subnets/<existing_vnet_subnet>'
# or the linked scope(s) are invalid
az aks update \
    --subscription $SUBSCRIPTION \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --api-server-authorized-ip-ranges "$AKS_AUTHORIZED_IP_RANGES" 2>&1 || echo "*** NOTICE***\n Could not update the AKS cluster with the authorized IP ranges: $AKS_AUTHORIZED_IP_RANGES . Please perform such operation manually, either from the Azure Portal, or by issuing the following command:  az aks update --subscription $SUBSCRIPTION --resource-group $RESOURCE_GROUP --name $AKS_NAME --api-server-authorized-ip-ranges \"$AKS_AUTHORIZED_IP_RANGES\""
echo "... Done updating the AKS Cluster with the authorized IP ranges!"
