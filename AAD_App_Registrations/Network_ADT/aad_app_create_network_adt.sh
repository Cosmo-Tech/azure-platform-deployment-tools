export STAGE=$1
if [[ -z "$STAGE" ]]; then
  export STAGE=Dev
  echo No stage defined, using Dev
fi

export PROJECT=$2
if [[ -z "$PROJECT" ]]; then
  echo No project name defined
else
  export PROJECT=" - $PROJECT"
fi

echo Creating App Registration...
app=$(az ad app create --display-name "Cosmo Tech Network and ADT registration - ${STAGE}${PROJECT}")
export appId=$(echo $app | jq -r '.appId')
echo App Registration created: $appId
echo Creating associated Service Principal
az ad sp create --id $appId
echo Done
