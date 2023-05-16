# Configure platform for single-tenant

When created with the [Platform Prerequisites Terraform](https://github.com/Cosmo-Tech/cosmotech-terraform/tree/main/azure/create-platform-prerequisites),
the app registrations authentications are configured by default as single-tenant.</br>
Until Cosmo Tech Platform version 2.3.5, API is deployed by default as multi-tenant.
This doc shows how to configure the Cosmo Tech API as single-tenant.

## Prerequisites

- Cosmo Tech platform version > 2.2 and <= 2.3.5 deployed


## Configure API for single-tenant

### 1 Get the current API config file

```bash
az login -t <tenant id>
az account set --subscription <subscription id>
az aks get-credentials --resource-group <managed resource group> --name <aks name>
helm -n phoenix get values cosmotech-api-v2 | tail -n +2 > <aks name>-values.yaml
```

### 2 Change config file to set authentication to single-tenant

- Open config file `<aks name>-values.yaml`
- Replace platform identity provider in `config > csm> platform` and fill in `tenant id` and `platform app id`

```bash
      identityProvider:
        authorizationUrl: https://login.microsoftonline.com/<tenant id>/oauth2/v2.0/authorize
        code: azure
        containerScopes:
          '[api://<platform app id>/.default]': Platform scope
        defaultScopes:
          '[api://<platform app id>/platform]': Platform scope
        tokenUrl: https://login.microsoftonline.com/<tenant id>/oauth2/v2.0/token
```

### 3 Update API config with new config

```bash
export HELM_EXPERIMENTAL_OCI=1
helm pull oci://ghcr.io/cosmo-tech/cosmotech-api-chart --version 2.3.5
helm -n phoenix upgrade cosmotech-api-v2 cosmotech-api-chart-2.3.5.tgz --values <aks name>-values.yaml
```
