#!/usr/bin/env bash
echo "Login with Azure using Service Principal credentials: ${CUSTOMER_SERVICE_PRINCIPAL_APPID}";
az login --service-principal -u "${CUSTOMER_SERVICE_PRINCIPAL_APPID}" -p "${CUSTOMER_SERVICE_PRINCIPAL_SECRET}" --tenant "${TENANT}" 2>&1 || exit 1;
