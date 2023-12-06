# Set up Azure AD authentication with Kubernetes RBAC on AKS Cluster

Cosmo Tech Platform deploys an AKS cluster which has a default configuration for Authentication and Authorization: `Local accounts with Kubernetes RBAC`. This configuration can be considered as a security issue by some IT departments, as the access to the AKS cluster is not based on an AAD token but on Kubernetes local accounts providing non auditable access to AKS cluster.

> Warning: this Azure Active Directory integration can't be disabled once added, it is irreversible.

Feature documentation and migration steps are detailed in [Microsoft documentation portal](https://learn.microsoft.com/en-us/azure/aks/enable-authentication-microsoft-entra-id).

## Migration steps for an existing AKS cluster

An Admin AAD group should be added as Kubernetes Cluster Admin group.

With Azure CLI:
```bash
az aks update -g myResourceGroup -n myManagedCluster --enable-aad --aad-admin-group-object-ids <id> [--aad-tenant-id <id>]
```

In Azure portal:
* Open AKS Service
* Go to Settings > Cluster Configuration
* In **Authentication and Authorization**: 
    * Select `Azure AD authentication with Kubernetes RBAC`
    * Select your Admin group for Kubernetes Cluster
    * Do not check `Kubernetes local accounts`
* Click on `Save`

## Access an AAD integrated cluster

Make sure you are part of the Kubernetes Cluster Admin group specified in the previous step.

```bash
# Get user credentials
az aks get-credentials --resource-group myResourceGroup --name myManagedCluster
# Set kubelogin to use azcli
kubelogin convert-kubeconfig -l azurecli
```

Now you have access to the AKS cluster.
