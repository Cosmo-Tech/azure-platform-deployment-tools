# Configure external application on Cosmo Tech Platform API

In order to access Cosmo Tech Platform API from an external application or script, the authentication shoud be configured according to the following documentation.  
  
The proposed method is based on Postman, but it is possible to use another library or service. The method consists in:
* Register your Application in your Authentication service
* Generate a token for your Application
* Run API queries to the Cosmo Tech Platform API
  
The Cosmo Tech platform supports two authentication services: Okta and Azure Active Directory.

## Case 1: Okta authentication
### Prerequisites

* Okta authentication has been configured on the platform according to the how-to guide: [Configure platform with Okta authentication](https://github.com/Cosmo-Tech/azure-platform-deployment-tools/tree/main/How-to%20guides/Configure%20platform%20with%20Okta%20authentication.md)
* Install [Postman Desktop](https://www.postman.com/downloads/)

### Register an Application in your Okta organization

In your Okta organization, create a new Application with the following settings:
* Name (e.g. `Cosmo Tech - External Application`)
* Application type: Web
* Client authentication: Client secret
* Grant type: Client credentials
> Save Client ID and Client Secret for next step (API values).

### Generate token in Postman
In Postman desktop:
* Create a new Collection
* In `Authorization` tab:
    * Select `Type`: `OAuth 2.0`
    * In `Configure New Token`:
        * `Token Name` should explicitly mention the scope of the token (e.g. `Okta twingraph read`)
        * `Grant Type`: `Client Credentials`
        * `Access Token URL`: `https://{yourOktaDomain}/oauth2/default/v1/token` (e.g. `https://cosmotech-dev.oktapreview.com/oauth2/default/v1/token`)
        * `Client ID`: Okta Client ID of your Application (created in the previous step)
        * `Client secret`: Okta Client secret of your Application (created in the previous step)
        * `Scope`: Scope corresponding to the query to be run by the application. This scope should be declared in the Okta Authorization Server. Several scopes can be set (e.g. `csm.organization.read csm.twingraph.write`)
        * `Client Authentication`: `Send client credentials in body`
        * Click on `Get New Access Token`

### Import your Cosmo Tech Platform API tree to Postman
In your Postman Workspace, click on `Import` and enter `https://{platformURL}/openapi` (e.g. `https://delivery.api.comsotech.com/v2/openapi`).  
This will create a new collection in your workspace, gathered all queries available. 

> Cosmo Tech Platform API security, based on Access Control List still applies on external application accessing the API through based on a scope. The external applications are identified in the API security by their **Okta Application Client ID**.  
>  
> For example: 
>```yaml
>security:
>  default: "none"
>  accessControlList:
>    - id: "<Okta-application-cliend-id>"
>      role: editor
>```
  
## Case 2: Azure Active Directory
### Prerequisites

* Azure Active Directory is configured as the Identity provider in your Cosmo Tech Platform (default configuration at the platform deployment).
* Install [Postman Desktop](https://www.postman.com/downloads/)

### Register an App registration in Azure Active Directory
In the same tenant as the Platform, create a new App Registration for your external application, with the following configuration:
* `Supported account types`: `Single tenant`
* Certificates & secrets: Create a secret
* API permissions:
    * Add a permission:
        * Select an API : your Cosmo Tech Platform App registation
        * Type of permissions: `Application permissions`
        * Select permission: `Organization.User` (in order to provide restricted permissions where API resources security can apply, otherwise `Platform.Admin`)
    * Grant admin consent for your tenant
> Save Client ID and Client Secret for next step (API values).

### Generate token 
In Postman desktop:
* Create a new Collection
* In `Authorization` tab:
    * Select `Type`: `OAuth 2.0`
    * In `Configure New Token`:
        * `Token Name` should explicitly mention the application name (e.g. `AAD application token`)
        * `Grant Type`: `Client Credentials`
        * `Access Token URL`: `https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token` (e.g. `https://login.microsoftonline.com/e413b834-8be8-4822-a370-be619545cb49/oauth2/v2.0/token`)
        * `Client ID`: AAD Client ID of your Application (created in the previous step)
        * `Client secret`: AAD Client secret of your Application (created in the previous step)
        * `Scope`: `api://<platform-app-registration-client-id>/.default` (e.g. `api://3baf6f7a-97b7-4041-b132-d431afcce2c1/.default`)
        * `Client Authentication`: `Send client credentials in body`
        * Click on `Get New Access Token`

### Import your Cosmo Tech Platform API tree to Postman
In your Postman Workspace, click on `Import` and enter `https://{platformURL}/openapi` (e.g. `https://delivery.api.comsotech.com/v2/openapi`).  
This will create a new collection in your workspace, gathered all queries available. 

> Cosmo Tech Platform API security, based on Access Control List still applies on external application accessing the API. The external applications are identified in the API security by the **Object ID of their Enterprise Application** (Beware, it differs from the client id of the app registration).  



