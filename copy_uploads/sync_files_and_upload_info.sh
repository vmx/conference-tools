#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes a seafile directory that contains uploads of talks and
# synchronizes into another directory. Only files that don't already exist
# are copied. Empty directories are not copied. Some addtional file that is
# used to cut/review the upload is added to the directory if it was newly
# created.

# You can get your auth token via
# curl -X POST --data "username=<your-username>&password=<your-password>" '<you-server>/api2/auth-token/'

if [ "${#}" -lt 5 ]; then
    echo "Usage: $(basename "${0}") <seafile-base-url> <seafile-auth-token> <seafile-repo-id> <seafile-source-directory> <seafile-target-directory>"
    echo ""
    echo "Example: $(basename "${0}") https://example.org fe91e764226cc534811f0ba32c62a6ac41ad0d7b 280b593a-f868-0594-d97a-23d88822a35f uploaded-talks processing-talks"
    exit 1
fi

seafile_base_url=${1}
seafile_auth_token=${2}
seafile_repo_id=${3}
seafile_source_dir=${4}
seafile_target_dir=${5}

seafile_api_v20="${seafile_base_url}/api2"

cd out || (echo "'./out' directory must exist, create it with the 'create_info_files.sh' script." && exit 2)

echo "Pushing files to Seafile…"

# Copy only the sub-directories that contain new files into the new directory
created_dirs=$(../sync_files.sh "${seafile_base_url}" "${seafile_auth_token}" "${seafile_repo_id}" "${seafile_source_dir}" "${seafile_target_dir}")

# Get the upload-api-link
upload_api_link=$(curl --silent -X GET --header "Authorization: Token ${seafile_auth_token}" "${seafile_api_v20}/repos/${seafile_repo_id}/upload-link/?p=/${seafile_target_dir}/"|jq --raw-output '.')

# Upload the file with additional information for the reviewers. Upload only
# to the newly created ones.
for created_dir in ${created_dirs}
do
    echo "Uploading ./md/${created_dir}.md…"
    ../upload_file.sh "${upload_api_link}" "${seafile_target_dir}" "./md/${created_dir}.md"
done

if [ "${created_dirs}" != "" ]
then
    echo "Info files were successfully uploaded."
fi
