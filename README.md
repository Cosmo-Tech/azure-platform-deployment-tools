# How to deploy Cosmo Tech platform 2.3.5

## Prerequisites

### Azure subscription & resource group

* Provide Azure subscription ID to Cosmo Tech for being added to Marketplace Private offer availability list.
* Acticate Microsoft.Web as resource provider of your subscription
* Create a resource group to host the Managed Application and all project resources (IP, VNet, etc)

### Technical prerequisites to deploy with Terraform

A [Terraform script](https://github.com/Cosmo-Tech/cosmotech-terraform/tree/main/azure/create-platform-prerequisites) is available for deploying the following technical prerequisites:
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
> <br>The Cosmo Tech platform is an Azure Managed Application, meaning that Cosmo Tech, as the publisher of the managed application is Owner of all the resources of the managed application.

Cosmo Tech Simulation Digital Twin Platform available on Azure Marketplace: select [Custom Plan v2](https://portal.azure.com/#create/cosmotech1600259358818.cosmotechsdtplatformuniversal_plan_v2).

Follow the [deployment documentation](https://portal.cosmotech.com/docs//documentation/platform_help/2.2/Content/How_To_Build_My_App/Marketplace/Deployment/How-to-deploy-CosmoTech-platform.htm) to configure your platform.

Here are some recommendations or details about platform deployment configuration:

**Basics**
* `Resource group`: created previously in the prerequisites step.
* `Managed resource group name`: this resource group will be created automatically at the managed application deployment to host all managed application resources. Cosmo Tech, as the publisher of the managed application has access to this resource group.

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
* `TLS Certificate`: `Let's Encrypt` is recommended. For Custom certificate, please enter the certificate and key.

**Security**
* `Authorized IP ranges`: In case you want to set an IP white list to access AKS cluster, enter the authorized IP ranges (please add Cosmo Tech IP to the list `185.55.98.20`). If empty: no IP restriction for accessing AKS cluster.
* `Service principal type`: Select existing.
* `Service principal`: Select previously created NetworkADT app registration. Enter Network ADT app registration secret.

**Tags**
* Define tags if needed.

## Users management

### Objectives

* Split users in 3 groups: Contributors users, Business users, Business readers
* Enable Cosmo Tech engineers to access the platform API and to manage resources outside of managed application (e.g. data integration, web app, etc).

### Users management steps
* Invite Cosmo Tech engineers as Guest in your tenant OR create accounts for external users in your tenant
* Create user groups in your tenant and add relevant users:
    * Group for Contributors users: should include Cosmo Tech Engineers and application admins
    * Group for Business users
    * Group for Business readers
* Assign the following roles on the Platform Enterprise Application (in Azure portal > Enterprise applications > search for Platform app registration name > Users and groups > Add user/group):
    * Contributors users: Platform.Admin
    * Business users: Organization.User
    * Business readers: Organization.Reader
* Assign Azure Digital Twins Data Owner role on Azure Digital Twins resource to:
    * Network ADT app registration
    * Contributors users


## Cosmo Tech post deployment operations

> These steps are executed by Cosmo Tech engineers.

- Add Cosmo Tech tenant to API access authorized tenant
- Declare the Platform Enterprise Application in Cosmo Tech tenant using cross tenant activation link.

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