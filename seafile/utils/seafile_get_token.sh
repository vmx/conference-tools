#!/bin/sh

# SPDX-FileCopyrightText: Christopher Lorenz <dev@lorenz.lu>
# SPDX-License-Identifier: MIT

# Guided script for get and append Seafile token to config
cd $(dirname $0)
. ../config

echo "Login to ${SEAFILE_URL}\n"

read -p "Username: " seafile_username
stty -echo
read -p "Password:  " seafile_password
stty echo

echo "\n\nRequest token from ${SEAFILE_URL}…"
token=$(curl -X POST --data "username=${seafile_username}&password=${seafile_password}" "${SEAFILE_URL}/api2/auth-token/" | jq -r '.token')
if [ $? -eq 0 ]
then
  echo "Token is: ${token}"
  echo "Adding token to config …"
  echo "export SEAFILE_API_TOKEN=${token}" >> ../config
else
  echo "Error get token"
  exit 1
fi
