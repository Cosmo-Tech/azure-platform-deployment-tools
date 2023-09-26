# How to deploy Cosmo Tech platform 2.3.5

## Prerequisites

### Azure subscription & resource group

* Provide Azure subscription ID to Cosmo Tech for being added to Marketplace Private offer availability list.
* Activate Microsoft.Web as resource provider of your subscription
* Make sure your subscription quotas for CPUs are high enough. Recommended values for the default sizing of the Cosmo Tech platform:
    * Standard FSv2 Family vCPUs -> 250
    * Standard Av2 Family vCPUs -> 20 
    * Standard DADSv5 Family vCPUs -> 20
    * Standard EADSv5 Family vCPUs -> 20

### Technical prerequisites to deploy with Terraform

A [Terraform script](https://github.com/Cosmo-Tech/cosmotech-terraform/tree/main/azure/create-platform-prerequisites) is available for deploying the following technical prerequisites:
* Azure resource group
* Azure Virtual Network for AKS
* Azure Public IP
* Azure DNS record
* App registrations:
    * Platform app registration
    * Network ADT app registration
    * Swagger app registration
    * Restish app registration
    * Web app app registration
* Role assignments:
    * Network ADT app registration Contributor on Public IP
    * Network ADT app registration Network Contributor on Virtual Network

> **NOTE**
> <br> Please provide to Cosmo Tech: Tenant ID, App registrations client ID & names

## Platform deployment

### Platform deployment from Azure Marketplace

> **IMPORTANT**
> <br>The Cosmo Tech platform is an Azure Managed Application, meaning that Cosmo Tech, as the publisher of the managed application is Contributor of all the resources of the managed application.

Cosmo Tech Simulation Digital Twin Platform available on Azure Marketplace: select [Custom Plan v2](https://portal.azure.com/#create/cosmotech1600259358818.cosmotechsdtplatformuniversal_plan_v2).

Follow the [deployment documentation](https://portal.cosmotech.com/docs//documentation/platform_help/2.2/Content/How_To_Build_My_App/Marketplace/Deployment/How-to-deploy-CosmoTech-platform.htm) to configure your platform.

Here are some recommendations or details about platform deployment configuration:

**Basics**
* `Resource group`: created previously in the prerequisites step.
* `Managed resource group name`: this resource group will be created automatically at the managed application deployment to host all managed application resources. Cosmo Tech, as the publisher of the managed application will be Contributor of this resource group.

**Cosmo Tech Platform**
* `Application name`: give a name to the platform to be deployed
* `Platform Version`: version of the API to be deployed on the platform. Latest current version is 2.3.5.
* `Platform App Registration Tenant ID`: Azure Active Directory tenant ID
* `Platform App Registration ID`: Client ID of the Platform app registration
* `Platform App Registration Secret`: Secret of the Platform app registration
* `Platform App Registration Application ID URI`: Application ID URI defined in the Platform app registration > Expose an API
* `Enable Platform Monitoring`: Select Enable Monitoring
* *Static Web App*: Keep empty, the web app will deployed and configured during Solution deployment. 

**Storage**
* Keep all default settings.

**Compute**
* If no specific sizing needs, keep all default settings.

**Scaling**
* If no specific sizing needs, keep all default settings.

**Networking**
* *Kubernetes*: Keep default config.
* *Configure virtual networks*: Select Virtual Network and Subnet created in the prerequisites step.

**External Access**
* `Public IP address Resource`: Select Public IP created previously in prerequisites step.
* `Fully qualified domain name`: Enter the FQDN defined previously in the prerequisites step (e.g. `dev.api.cosmotech.com`).
* `TLS Certificate`: `Let's Encrypt` is recommended. For Custom certificate, please enter the certificate and key, as detailed in the [documentation](https://portal.cosmotech.com/docs//documentation/platform_help/2.2/Content/How_To_Build_My_App/Marketplace/Deployment/ExternalAccess_tab.htm).

**Security**
* `Authorized IP ranges`: In case you want to set an IP white list to access AKS cluster, enter the authorized IP ranges (please add Cosmo Tech IP to the list `185.55.98.20`). If empty: no IP restriction for accessing AKS cluster.
* `Service principal type`: Select existing.
* `Service principal`: Select previously created NetworkADT app registration. Enter Network ADT app registration secret.

**Tags**
* Define tags if needed.

### Deployment verification
Once the platform is deployed, a simple check can be performed by a **Customer user** in order to validate the deployment:
* Connect to the API URL: `https://<platform_fqdn>/v2`
* Click on **Authorize**:
    * Enter Swagger client id
    * Let secret empty
    * Select the scope
* The operation should succeed. The platform is ready for the next step: Users management in order to be able to run API queries.
## Post Deployment Operations

### Change platform authentication method to single
When created with the [Platform Prerequisites Terraform](https://github.com/Cosmo-Tech/cosmotech-terraform/tree/main/azure/create-platform-prerequisites),
the app registrations authentications are configured by default as single-tenant.</br>
Until Cosmo Tech Platform version 2.3.5, API is deployed by default as multi-tenant.
The [Configure platform as single-tenant]("./How-to guides/Configure platform as single-tenant.md") doc shows how to configure the Cosmo Tech API as single-tenant.

## Users management

### Objectives

* Split users in 3 groups: Contributors users, Business users, Business readers
* Enable Cosmo Tech engineers to access the platform API and to manage resources outside of managed application (e.g. data integration, web app, etc).

### Users management steps
* Invite Cosmo Tech engineers as Guest in your tenant OR create accounts for external users in your tenant
* Create user groups in your tenant and add relevant users:
    * Group for Contributors users: should include Cosmo Tech Engineers and application admins
    * Group for Business users
* Assign the following roles on the Platform Enterprise Application (in Azure portal > Enterprise applications > search for Platform app registration name > Users and groups > Add user/group):
    * Contributors users: Platform.Admin
    * Business users: Organization.User
* Assign Azure Digital Twins Data Owner role on Azure Digital Twins resource to:
    * Network ADT app registration
    * Contributors users

## Optional: Configure Cosmo Tech platform to authorize access from Cosmo Tech tenant

By default the Cosmo Tech platform is deployed so that the API is only accessible from users of the customer tenant. However it is possible to configure the platform to be accessible also from the Cosmo Tech tenant. To do it so, a few actions have to be performed:
* By Customer:
    * Set the app registrations Platform, Network/ADT and Swagger to support multiple organizations accounts. In Azure Portal > open App registration > Authentication > Supported account types : multitenant.
* By Cosmo Tech:
    * Add the Platform Enterprise Application to Cosmo Tech tenant (`az ad sp create --id <platform_app_reg_client_id>`). This will create a new Enteprise Application in Cosmo Tech tenant, named after the Platform app registration.
    * Add Cosmo Tech engineers as Platform.Users of the Enterprise Application in Cosmo Tech tenant. 
    * Add Cosmo Tech tenant ID (`e413b834-8be8-4822-a370-be619545cb49`) to API access [authorized tenant](https://portal.cosmotech.com/docs//documentation/platform_help/2.2/Content/Platform%20Help/DevOps%20Guide/D_Cosmo%20Tech%20API%20Service/Allowed%20tenants%20list.htm).
    * Update the API values by replacing `/[TENANT_ID]/` by `/common/` in:
        * `csm.platform.identityProvider:authorizationUrl`
        * `csm.platform.identityProvider:tokenUrl`

## Power BI

Define Power BI embedded authentication mode and related licensing plan.
### SSO (Single Sign On) mode
* Licensing option 1 (better for large amount of users and if you already have a Premium Capacity available)
    * Power BI workspace with a Premium Capacity
    * User managing the reports and workspace has a Power BI Pro Licence
* Licensing option 2 (better for low number of users and no Premium capacity available)
    * All users have a Power BI Pro license
    No need for a Premium Capacity
### Service Principal mode
* Licensing:
    * User managing the reports and workspace has a Power BI Pro Licence
    * All other users do not need any Power BI account or license
    * Premium capacity is needed for Production applications
* Power BI admin rights are required to `Enable Power BI embed content and service principals to use Power BI APIs` (for specific Power BI security group) in Power BI Admin Portal

# How to upgrade Cosmo Tech platform from 2.2.0 to 2.3.5

## Prerequisites
* Platform virtual network and subnet should have a range size of at least /26.
* User performing the upgrade should be:
    * Network contributor on the Virtual Network
    * Contributor on AKS
* For default platform sizing, subscription CPU quotas should be at least:
    * Standard FSv2 Family vCPUs -> 250
    * Standard Av2 Family vCPUs -> 20 
    * Standard DADSv5 Family vCPUs -> 20
    * Standard EADSv5 Family vCPUs -> 20

## Upgrade steps

### Retrieve API values (optional)
This step is optional, but useful to save API values in case of issue during the upgrade.
> Connect to AKS Cluster Context
```
helm -n phoenix get values cosmotech-api-v2 | tail -n +2 > values.yaml
```
### Migrate AKS from 1.23.x to 1.25.5
Migrate AKS successively from 1.23.x to 1.24.9 to 1.25.5.
```
az login
az account set --subscription <subscription_id>
az aks upgrade --resource-group <myResourceGroup> --name <myAKSCluster> --kubernetes-version 1.24.9
az aks upgrade --resource-group <myResourceGroup> --name <myAKSCluster> --kubernetes-version 1.25.5
```
### Run API upgrade script
An API upgrade script to update API v2 to version 2.3.5 is available in the folder `deployment_scripts/v2.3/`. This script upgrades the Cosmo Tech Platform API and dependancies.
> Connect to AKS Cluster Context
```
./upgrade.sh 2.3.5
```
