#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes a seafile directory that contains uploads of talks and
# synchronizes into another directory. Only files that don't already exist
# are copied. Empty directories are not copied. Some addtional file that is
# used to cut/review the upload is added to the directory if it was newly
# created.

cd $(dirname $0)
. ../config

seafile_api_v20="${SEAFILE_URL}/api2"

cd out || (echo "'./out' directory must exist, create it with the 'create_info_files.sh' script." && exit 2)

echo "Pushing files to Seafile…"

# Copy only the sub-directories that contain new files into the new directory
created_dirs=$(../sync_files.sh "${SEAFILE_URL}" "${SEAFILE_API_TOKEN}" "${SEAFILE_REPO_ID}" "${SEAFILE_UPLOAD_DIR}" "${SEAFILE_PROCESS_DIR}")

# Get the upload-api-link
upload_api_link=$(curl --silent -X GET --header "Authorization: Token ${SEAFILE_API_TOKEN}" "${seafile_api_v20}/repos/${SEAFILE_REPO_ID}/upload-link/?p=/${SEAFILE_PROCESS_DIR}/"|jq --raw-output '.')

# Upload the file with additional information for the reviewers. Upload only
# to the newly created ones.
for created_dir in ${created_dirs}
do
    echo "Uploading ./md/${created_dir}.md…"
    ../upload_file.sh "${upload_api_link}" "${SEAFILE_PROCESS_DIR}" "./md/${created_dir}.md"
done

if [ "${created_dirs}" != "" ]
then
    echo "Info files were successfully uploaded."
fi
