# Configure platform with Okta authentication

Default authentication and access management service of the Cosmo Tech Platform is Azure Active Directory. However it is also possible to use Okta as a Customer Identity and Access Management. The complete feature and configuration of Okta for Cosmo Tech Platform are detailed in [Cosmo Tech Platform documentation](https://portal.cosmotech.com/docs//documentation/platform_help/2.2/Content/Platform%20Help/Okta/Okta.htm). The purpose of this document is to provide a concise guide to set up the feature. 


## Prerequisites

- Cosmo Tech Platform version > 2.3.14
- Have an Okta ogranization in order to managed you users

## Configure your Okta organization

### 1 Create users and user groups

In Okta admin portal:
* Create users
* Create user groups:
  * Admin group (e.g. `AdminAccessGroup`)
  * User group (e.g. `UserAccessGroup`)
  * Viewer group (optional) (e.g. `ViewerAccessGroup`)
* Assign groups to users

### 2 Create Authorization server

Create a new authorization server (in `Security`>`API`) with the following properties:
* Name: (e.g. `default`)
* Audience (e.g. `api://default`)
* Issuer URI: `https://{yourOktaDomain}/oauth2/default` (e.g. `https://cosmotech-dev.oktapreview.com/oauth2/default`)
* Scope:
  Add the scopes you will require for an application to reach Cosmo Tech Platform API, among the available scopes list:
  * Read accesses
    * csm.scenario.read: (entry in property: csm.platform.identityProvider.containerScopes) (Mandatory for web app use)
    *	csm.connector.read
    *	csm.organization.read
    *	csm.dataset.read
    *	csm.solution.read
    *	csm.workspace.read
    *	csm.scenariorun.read
    * csm.twingraph.read
  *	Write accesses
    *	csm.connector.write
    *	csm.organization.write
    *	csm.dataset.write
    *	csm.solution.write
    *	csm.workspace.write
    *	csm.scenario.write
    *	csm.scenariorun.write
    * csm.twingraph.write
* Claims
  * Add a Claim
    * Name: `groups`
    * Value type: `Groups`
    * Filter: Matches regex `.*`
    * Include in: Any scope
* Access policy and rules
  * Create access policy as described in the [Platform documentation](https://portal.cosmotech.com/docs//documentation/platform_help/2.2/Content/Platform%20Help/Okta/AccessPoliciesRules.htm)

### 3 Create Applications
* Cosmo Tech - Platform API
  * Application type: Web
  * Grant type: Client credentials + Authorization Code
  * Require user consent
  * Sign-in URI: `<platform-URL>/authorization-code/callback` (e.g. `https://delivery.api.cosmotech.com/v2/authorization-code/callback`)
  * Sign-out URI: `<platform-URL>` (e.g. `https://delivery.api.cosmotech.com/v2`)
> Save Client ID and Client Secret for next step (API values).
Cosmo Tech - Swagger
  * Application type: Single Page App
  * Grant type: Authorization Code
  * Require user consent
  * Sign-in URI: `<platform-URL>/swagger-ui/oauth2-redirect.html` (e.g. `https://delivery.api.cosmotech.com/v2/swagger-ui/oauth2-redirect.html`)
  * Sign-out URI: `http://localhost:8080/swagger-ui`
> Save Client ID for log in to Swagger UI.

## Configure Identity provider in API values
### 1 Retrieve API values  
Retrieve the Platform API values into a local file `values.yaml`.  
```bash
# Connect to Platform AKS context
helm -n phoenix get values cosmotech-api-<api-version> | tail -n +2 > values.yaml

# e.g. for a Platform using API v2
helm -n phoenix get values cosmotech-api-v2 | tail -n +2 > values.yaml
```

### 2 Edit IdentityProvider configuration in API values
In the `values.yaml` file, replace the existing `IdentityProvider` configuration by:
```yaml
csm:
  platform:
    identityProvider:
      code: okta
      # Use to overwrite openAPI configuration
      authorizationUrl: "https://{yourOktaDomain}/oauth2/default/v1/authorize"
      tokenUrl: "https://{yourOktaDomain}/oauth2/default/v1/token"
      defaultScopes:
        openid: "OpenId Scope"
      containerScopes:
        csm.scenario.read: "Read access to scenarios"
      adminGroup: "<my_custom_admin_group>"
      userGroup: "<my_custom_user_group>"
      viewerGroup: "<my_custom_viewer_group>"
    # Use to define Okta Configuration
    okta:
      issuer: "https://{yourOktaDomain}/oauth2/default"
      clientId: "<OKTA_API_CLIENT_ID>"
      clientSecret: "<OKTA_API_CLIENT_SECRET>"
      audience: "<OKTA_AUTHORIZATION_SERVER_AUDIENCE>"
```
Example based on previous example values:
```yaml
identityProvider:
        code: okta
        # Use to overwrite openAPI configuration
        authorizationUrl: "https://cosmotech-dev.oktapreview.com/oauth2/default/v1/authorize"
        tokenUrl: "https://cosmotech-dev.oktapreview.com/oauth2/default/v1/token"
        defaultScopes:
          openid: "OpenId Scope"
        containerScopes:
          csm.scenario.read: "Read access to scenarios"
        adminGroup: "AdminAccessGroup"
        userGroup: "UserAccessGroup"
        viewerGroup: "ViewerAccessGroup"
      # Use to define Okta Configuration
      okta:
        issuer: "https://cosmotech-dev.oktapreview.com/oauth2/default"
        clientId: "xxxxxxxxxxxxx"
        clientSecret: "yyyyyyyyyyyyy"
        audience: "api://default"
```

### 3 Update API values
Re-deploy the API on the Platform by upgrading the API values.  
```bash
# Download the API image corresponding to your API chart version
export HELM_EXPERIMENTAL_OCI=1
helm pull oci://ghcr.io/cosmo-tech/cosmotech-api-chart --version <chart-version>
# example with chart version 2.3.14 (should be the same as image:tag:.. value in values.yaml)
helm pull oci://ghcr.io/cosmo-tech/cosmotech-api-chart --version 2.3.14

# Connect to AKS context and upgrade API
helm -n phoenix upgrade cosmotech-api-<api-version> cosmotech-api-chart-<chart-version>.tgz --values values.yaml
# example with API v2 and chart version 2.3.14
helm -n phoenix upgrade cosmotech-api-v2 cosmotech-api-chart-2.3.14.tgz --values values.yaml
```
> API redeployment can take a few minutes.

## Test Okta configuration
In order to test the integration of your Okta organization with the Cosmo Tech Platform: 
* Open `<Platform-URL>`
* Authenticate by clicking on `Authorize`
  * Enter the `client_id` of your Swagger Okta Application
  * Leave `client_secret` empty
  * Select the scope `openid`
* Run API queries

