export AAD_JWT_TOKEN=`http --form POST \
      https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/token \
      grant_type=client_credentials \
      client_id=${AZURE_CLIENT_ID} \
      client_secret="${AZURE_CLIENT_SECRET}" \
      resource=20e940b3-4c77-4b0b-9a53-9e16a1b010a7 \
    | jq -r '.access_token'`
