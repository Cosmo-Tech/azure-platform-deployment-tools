http --json POST https://marketplaceapi.microsoft.com/api/usageEvent api-version=="2018-08-31" \
      Authorization:"Bearer ${AAD_JWT_TOKEN}" \
      x-ms-requestid:"${APPLICATION_NAME}-metering-`date +%s`" \
      x-ms-correlationid:"${CORRELATION_ID}" <<< '
{
  "resourceUri": "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME}/providers/Microsoft.Solutions/applications/${APPLICATION_NAME}",
  "quantity": ${QUANTITY},
  "dimension": "${DIMENSION_ID}",
  "effectiveStartTime": "`date -uIs`",
  "planId": "${PLAN_ID}"
}
'
