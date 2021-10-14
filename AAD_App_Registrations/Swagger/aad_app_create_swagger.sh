echo usage: ./aad_app_create_swagger.sh CUSTOMER PLATFORM_URL [STAGE=Dev] [PROJECT]
export CUSTOMER=$1
if [[ -z "$CUSTOMER" ]]; then
  echo Please provide customer name as first parameter
  exit 1
fi

export PLATFORM_URL=$2
if [[ -z "$PLATFORM_URL" ]]; then
  echo Please provide the Cosmo Tech API Platform URL
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
app=$(az ad app create --display-name "Cosmo Tech Swagger For ${STAGE} - ${CUSTOMER}${PROJECT}" --available-to-other-tenants --reply-urls $PLATFORM_URL/swagger-ui/oauth2-redirect.html --oauth2-allow-implicit-flow true)
export appId=$(echo $app | jq -r '.appId')
echo App Registration created: $appId
echo Creating associated Service Principal
az ad sp create --id $appId
echo
echo Adding and granting API Delegated Permission for Microsoft Graph User.Read scope
az ad app permission add --id $appId --api 00000002-0000-0000-c000-000000000000 --api-permissions 311a71cc-e848-46a1-bdf8-97ff7156d8e6=Scope
az ad app permission grant --id $appId --api 00000002-0000-0000-c000-000000000000 --consent-type AllPrincipals --scope User.Read
