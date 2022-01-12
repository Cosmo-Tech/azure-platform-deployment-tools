echo usage: ./generate_cross_tenant_link.sh PLATFORM_APP_ID PLATFORM_URL [IDENTIFIER_URI=PLATFORM_URL] [CLIENT_APP_ID=PLATFORM_APP_ID]
export PLATFORM_APP_ID=$1
if [[ -z "$PLATFORM_APP_ID" ]]; then
  echo Please provide the Platform App Registration Client Id
  exit 1
fi

export PLATFORM_URL=$2
if [[ -z "$PLATFORM_URL" ]]; then
  echo Please provide the Platform URL
  exit 1
fi

export IDENTIFIER_URI=$3
if [[ -z "$IDENTIFIER_URI" ]]; then
  export IDENTIFIER_URI=$PLATFORM_URL
  echo No Identifier URI defined for API scope, using PLATFORM_URL uri $PLATFORM_URL
fi

export CLIENT_APP_ID=$4
if [[ -z "$CLIENT_APP_ID" ]]; then
  export CLIENT_APP_ID=$PLATFORM_APP_ID
  echo No client app id defined, using PLATFORM_APP_ID $PLATFORM_APP_ID
fi

export ENCODED_PLATFORM_URL=${PLATFORM_URL//':'/'%3A'}
export ENCODED_PLATFORM_URL=${ENCODED_PLATFORM_URL//'/'/'%2F'}
export ENCODED_IDENTIFIER_URI=${IDENTIFIER_URI//':'/'%3A'}
export ENCODED_IDENTIFIER_URI=${ENCODED_IDENTIFIER_URI//'/'/'%2F'}

echo Generated cross tenant link to create an enterprise application linked to $PLATFORM_APP_ID App Registration:
echo "https://login.microsoftonline.com/common/oauth2/authorize?client_id=${CLIENT_APP_ID}&response_type=code&redirect_uri=${ENCODED_PLATFORM_URL}%2Fswagger-ui%2Foauth2-redirect.html&response_mode=query&scope=${ENCODED_IDENTIFIER_URI}%2Fplatform&state=12345&resource=${PLATFORM_APP_ID}"
