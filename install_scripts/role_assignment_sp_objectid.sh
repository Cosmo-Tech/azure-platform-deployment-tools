#!/usr/bin/env bash
# Copyright (c) Cosmo Tech.
# Licensed under the MIT license.
echo role_assignment_objectid.sh start
echo SP_ID: the service principal id to assign role to
echo ROLE_ID: the Azure role UID to assign
echo RESOURCE_SCOPE: the resource scope to assign role to
echo

echo Assigning ${ROLE_ID} to ${SP_ID} on ${RESOURCE_SCOPE}
az role assignment create \
  --assignee-object-id "${SP_ID}" \
  --role "${ROLE_ID}" \
  --scope "${RESOURCE_SCOPE}" \
  --assignee-principal-type "ServicePrincipal" \
  2>&1 || exit 1

echo role_assignment_objectid.sh end
