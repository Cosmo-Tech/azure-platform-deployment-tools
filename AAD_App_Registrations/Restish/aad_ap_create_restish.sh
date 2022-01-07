echo usage: ./aad_ap_create_restish.sh CUSTOMER PLATFORM_APP_ID [STAGE=Dev] [PROJECT]
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


echo Creating App Registration...
app=$(az ad app create --display-name "Cosmo Tech Restish For ${STAGE} - ${CUSTOMER}${PROJECT}" --available-to-other-tenants --reply-urls "http://localhost:8484" --oauth2-allow-implicit-flow true)
export appId=$(echo $app | jq -r '.appId')
echo App Registration created: $appId
echo Creating associated Service Principal
az ad sp create --id $appId
echo Adding tags to Hide App and Integrated App
az ad sp update --id $appId --add tags "HideApp"
az ad sp update --id $appId --add tags "WindowsAzureActiveDirectoryIntegratedApp"
echo
echo Adding and granting API Delegated Permission for Microsoft Graph User.Read scope
az ad app permission add --id $appId --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
az ad app permission grant --id $appId --api 00000003-0000-0000-c000-000000000000 --consent-type AllPrincipals --scope User.Read
echo Adding and granting API Delegated Permission for Cosmo Tech API Platform - platform scope
az ad app permission add --id $appId --api $PLATFORM_APP_ID --api-permissions 6332363e-bcba-4c4a-a605-c25f23117400=Scope
az ad app permission grant --id $appId --api $PLATFORM_APP_ID --consent-type AllPrincipals --scope platform
