#!/usr/bin/env bash
# Copyright (c) Cosmo Tech.
# Licensed under the MIT license.
echo az_login_as_sp.sh start
echo Mandatory env vars:
echo SP_APPID: the service principal application / client id
echo SP_SECRET: the service principal secret
echo SP_TENANT: the service principal tenant
echo
echo "Login with Azure using Service Principal credentials: ${SP_APPID}..."
az login --service-principal -u "${SP_APPID}" -p "${SP_SECRET}" --tenant "${SP_TENANT}" 2>&1 || exit 1
echo az_login_as_sp.sh end
