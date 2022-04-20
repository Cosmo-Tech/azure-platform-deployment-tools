export AAD_JWT_TOKEN=`http --form POST \
      https://login.microsoftonline.com/${AZURE_TENANT_ID}/oauth2/token \
      grant_type=client_credentials \
      client_id=${AZURE_CLIENT_ID} \
      client_secret="${AZURE_CLIENT_SECRET}" \
      resource=https://api.partner.microsoft.com \
    | jq -r '.access_token'`
