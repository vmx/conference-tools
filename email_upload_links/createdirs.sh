#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# Creates a directory with the given name (sub-directories are not supported)
# in the root of the repo returns its name together with the upload link as
# JSON, where the directory name is the key and the upload link is the value.

# You can get your auth token via
# curl -X POST --data "username=<your-username>&password=<your-password>" '<you-server>/api2/auth-token/'

if [ "${#}" -lt 4 ]; then
    echo "Usage: $(basename "${0}") <base-url> <auth-token> <repo-id> <directory-name>"
    echo ""
    echo "Example: $(basename "${0}") https://example.org fe91e764226cc534811f0ba32c62a6ac41ad0d7b 280b593a-f868-0594-d97a-23d88822a35f directory_to_create"
    exit 1
fi

base_url=${1}
token=${2}
repo_id=${3}
dir_name=${4}

api_v20="${base_url}/api2"
api_v21="${base_url}/api/v2.1"

mkdir_ret=$(curl --silent -X POST --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/dir/?p=/${dir_name}" --data 'operation=mkdir')
if [ "${mkdir_ret}" != '"success"' ]; then
    echo "Error: cannot create directory '${dir_name}'."
    exit 2
fi

# Output the directory name to stderr (so that you can still pipe the expected
# output into a fil) as progress indicator
echo "Creating ${dir_name} on Seafile…" >&2
upload_link_ret=$(curl --silent -X POST --header "Authorization: Token ${token}" "${api_v21}/upload-links/" --data "path=/${dir_name}/&repo_id=${repo_id}"|jq --compact-output '{(.obj_name): .link}')
echo "${upload_link_ret}"
