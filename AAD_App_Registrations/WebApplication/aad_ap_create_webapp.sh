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


echo Creating App Registration...
app=$(az ad app create --display-name "Cosmo Tech Web Application For ${STAGE} - ${CUSTOMER}${PROJECT}")
export appId=$(echo $app | jq -r '.appId')
export appObjectId=$(echo $app | jq -r '.objectId')
echo App Registration created: $appId \($appObjectId\)
echo Creating associated Service Principal
az ad sp create --id $appId
echo
echo Adding Authentication SPA Platform with authorized redirect URI
# it is not possible to update directly replyUrlsWithType with az ad app update and set SPA reply url another way than REST API (10/2021)
az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/applications/${appObjectId}" --headers "Content-Type=application/json" --body "{\"spa\":{\"redirectUris\":[\"${WEBAPP_URL}/scenario\"]}}"
echo Adding and granting API Delegated Permission for Microsoft Graph User.Read scope
az ad app permission add --id $appId --api 00000002-0000-0000-c000-000000000000 --api-permissions 311a71cc-e848-46a1-bdf8-97ff7156d8e6=Scope
az ad app permission grant --id $appId --api 00000002-0000-0000-c000-000000000000 --consent-type AllPrincipals --scope User.Read
echo Adding and granting API Delegated Permission for Cosmo Tech API Platform - platform scope
az ad app permission add --id $appId --api $PLATFORM_APP_ID --api-permissions 6332363e-bcba-4c4a-a605-c25f23117400=Scope
az ad app permission grant --id $appId --api $PLATFORM_APP_ID --consent-type AllPrincipals --scope platform
