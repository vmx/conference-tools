#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script uploads the given file into a sub-directory named after the
# basename of the input file (without extension).

if [ "${#}" -lt 3 ]; then
    echo "Usage: $(basename "${0}") <upload-api-link> <seafile-directory> <local-file>"
    echo ""
    echo "Example: $(basename "${0}") https://example.org/upload-api/2e2424a0-6802-48cd-b134-4d6fd6e48a52 dir_on_seafile local_file"
    exit 1
fi

upload_api_link=${1}
seafile_dir=${2}
local_file=${3}

pretalx_id=$(basename "${local_file}" | cut -f 1 -d '.')
echo "Uploading '${local_file}' to Seafile at '/${seafile_dir}/${pretalx_id}/'…"
upload_file_code=$(curl --silent --form file=@"${local_file}" --form parent_dir="/${seafile_dir}/" --form relative_path="${pretalx_id}/" "${upload_api_link}" --output /dev/null --write-out '%{http_code}')
if [ "${upload_file_code}" != "200" ]
then
    echo "Error: cannot upload information file '${local_file}'."
    exit 2
fi
