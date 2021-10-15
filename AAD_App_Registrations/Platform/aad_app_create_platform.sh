echo usage: ./aad_app_create_platform.sh CUSTOMER IDENTIFIER_URI [STAGE=Dev] [PROJECT] [PLATFORM_URL=IDENTIFIER_URI]
export CUSTOMER=$1
if [[ -z "$CUSTOMER" ]]; then
  echo Please provide customer name as first parameter
  exit 1
fi

export IDENTIFIER_URI=$2
if [[ -z "$IDENTIFIER_URI" ]]; then
  echo Please provide the base path identifier uri for oauth2 scope. Example: https://dev.api.cosmotech.com
  exit 1
fi

export STAGE=$3
if [[ -z "$STAGE" ]]; then
  export STAGE=Dev
  echo No stage defined, using Dev
fi

export PROJECT=$4
if [[ -z "$PROJECT" ]]; then
  echo No project name defined
else
  export PROJECT=" - $PROJECT"
fi

export PLATFORM_URL=$5
if [[ -z "$PLATFORM_URL" ]]; then
  export PLATFORM_URL=$IDENTIFIER_URI
  echo No specific API platform URL set, using identifier uri $IDENTIFIER_URI
fi

echo Creating App Registration...
app=$(az ad app create --display-name "Cosmo Tech $STAGE Platform For ${CUSTOMER}${PROJECT}" --app-roles @platform_app_roles_manifest.json --available-to-other-tenants --reply-urls $PLATFORM_URL/swagger-ui/oauth2-redirect.html --oauth2-allow-implicit-flow true)
export appId=$(echo $app | jq -r '.appId')
echo App Registration created: $appId
echo Creating associated Service Principal
az ad sp create --id $appId
echo Adding tags to hide app and Integrated App
az ad sp update --id $appId --add tags "HideApp"
az ad sp update --id $appId --add tags "WindowsAzureActiveDirectoryIntegratedApp"
echo
echo Creating application scope base identifier
az ad app update --id $appId --set identifierUris="[ \"$IDENTIFIER_URI\" ]"
echo Disabling default scope
export default_authz=$(az ad app show --id $appId  | jq '.oauth2Permissions[0].isEnabled = false'  | jq -r '.oauth2Permissions')
az ad app update --id $appId --set oauth2Permissions="$default_authz"
echo Adding Cosmo Tech platform scope
az ad app update --id $appId --set oauth2Permissions=@platform_oauth2Permissions_manifest.json
echo
echo Adding and granting API Delegated Permission for Microsoft Graph User.Read scope
az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
az ad app permission grant --id $appId --api 00000003-0000-0000-c000-000000000000 --consent-type AllPrincipals --scope User.Read
echo Adding and granting API Application Permission on itself as Platform.Admin role
az ad app permission add --id $appId --api $appId --api-permissions bb49d61f-8b6a-4a19-b5bd-06a29d6b8e60=Role
az ad app permission grant --id $appId --api $appId --consent-type AllPrincipals
echo Waiting 2mn for admin consent....
sleep 120s
echo Granting admin consent...
az ad app permission admin-consent --id $appId
echo Admin consent done
echo Remove permission from list
az ad app permission delete --id $appId --api $appId
echo Done
