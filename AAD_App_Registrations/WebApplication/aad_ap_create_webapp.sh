echo usage: ./aad_ap_create_webapp.sh CUSTOMER PLATFORM_APP_ID WEBAPP_URL [STAGE=Dev] [PROJECT] [DEVAUTHENT=True]
export CUSTOMER=$1
if [[ -z "$CUSTOMER" ]]; then
  echo Please provide customer name as first parameter
  exit 1
fi

export PLATFORM_APP_ID=$2
if [[ -z "$PLATFORM_APP_ID" ]]; then
  echo Please provide Cosmo Tech API Core Platform Application Id
  exit 1
fi

export WEBAPP_URL=$3
if [[ -z "$WEBAPP_URL" ]]; then
  echo Please provide the Web Application base URL. Example: https://myapp.app.cosmotech.com
fi

export STAGE=$4
if [[ -z "$STAGE" ]]; then
  export STAGE=Dev
  echo No stage defined, using Dev
fi

export PROJECT=$5
if [[ -z "$PROJECT" ]]; then
  echo No project name defined
else
  export PROJECT=" - $PROJECT"
fi

export DEVAUTHENT=$6
if [[ -z "$DEVAUTHENT" ]]; then
  export DEVAUTHENT=true
  echo Dev authentication authorized
fi

if [[ "$DEVAUTHENT" == "true" ]]; then
  export authentUri="[\"${WEBAPP_URL}/scenario\", \"http://localhost:3000/scenario\"]"
else
  export authentUri="[\"${WEBAPP_URL}/scenario\"]"
fi



echo Creating App Registration...
app=$(az ad app create --display-name "Cosmo Tech Web Application For ${STAGE} - ${CUSTOMER}${PROJECT}")
export appId=$(echo $app | jq -r '.appId')
export appObjectId=$(echo $app | jq -r '.objectId')
echo App Registration created: $appId \($appObjectId\)
echo Creating associated Service Principal
az ad sp create --id $appId
echo Adding tags to Hide App and Integrated App
az ad sp update --id $appId --add tags "HideApp"
az ad sp update --id $appId --add tags "WindowsAzureActiveDirectoryIntegratedApp"
echo
echo Adding Authentication SPA Platform with authorized redirect URI
# it is not possible to update directly replyUrlsWithType with az ad app update and set SPA reply url another way than REST API (10/2021)

az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/applications/${appObjectId}" --headers "Content-Type=application/json" --body "{\"spa\":{\"redirectUris\":${authentUri}}}"
echo Adding and granting API Delegated Permission for Microsoft Graph User.Read scope
az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
az ad app permission grant --id $appId --api 00000003-0000-0000-c000-000000000000 --consent-type AllPrincipals --scope User.Read
echo Getting Platform Enterprise Application OAuth2 informations
export platformEA=$(az ad sp show --id ${PLATFORM_APP_ID})
export scopeId=$(echo $platformEA | jq -r '.oauth2Permissions[0].id')
echo Adding and granting API Delegated Permission for Cosmo Tech API Platform - platform scope
az ad app permission add --id $appId --api $PLATFORM_APP_ID --api-permissions ${scopeId}=Scope
echo API scope if is ${scopeId}
az ad app permission grant --id $appId --api $PLATFORM_APP_ID --consent-type AllPrincipals --scope platform
