#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script returns all files that should be copied from the source
# directory into a target directory. It outputs to stdout the list of files
# that should be coppied. Each line consists of the source directory and the
# target directory separated by a tab character.
#
# You need to have the following utilities installed:
# curl, jq

# You can get your auth token via
# curl -X POST --data "username=<your-username>&password=<your-password>" '<you-server>/api2/auth-token/'

if [ "${#}" -lt 5 ]; then
    echo "Usage: $(basename "${0}") <base-url> <auth-token> <repo-id> <source-directory> <target-directory>"
    echo ""
    echo "Example: $(basename "${0}") https://example.org fe91e764226cc534811f0ba32c62a6ac41ad0d7b 280b593a-f868-0594-d97a-23d88822a35f source_dir target_dir"
    exit 1
fi

base_url=${1}
token=${2}
repo_id=${3}
source_dir=${4}
target_dir=${5}

api_v20="${base_url}/api2"

# In this script we always only want to split at newlines in for loops
# https://github.com/koalaman/shellcheck/wiki/SC2039#c-style-escapes
IFS="$(printf '%b_' '\n')"; IFS="${IFS%_}"


# Find out which files to copy
list_dirs_ret=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/dir/?p=/${source_dir}&t=d"|jq --raw-output '.[].name')
for dir_name in ${list_dirs_ret}
do
    # Print progress indicator to stderr, so that you can still pipe the
    # expected output into a file.
    echo "Processing ${dir_name}…" >&2
    latest_modified_mkv_file=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/dir/?p=/${source_dir}/${dir_name}&t=f"|jq --raw-output '[.[] | select(.name | endswith(".mkv"))] | sort_by(-.mtime) | first | .name | strings')
    if [ "${latest_modified_mkv_file}" != "" ]
    then
        # Get the target file path
        target_file=$(python3 ../get_filepath.py "${dir_name}" schedule.json)

        # Copy file only if it wasn't copied yet
        file_code=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/file/detail/?p=/${target_dir}/${target_file}" --output /dev/null --write-out '%{http_code}')
        if [ "${file_code}" = "404" ]
        then
            # Print progress indicator to stderr, so that you can still pipe the
            # expected output into a file.
            echo "'/${source_dir}/${dir_name}/${latest_modified_mkv_file}' will be copied to '/${target_dir}/${target_file}'…" >&2

            # Output source and target file
            printf '%s\t%s\n' "/${source_dir}/${dir_name}/${latest_modified_mkv_file}" "/${target_dir}/${target_file}"
        fi
    fi
done

echo "List files to copy: done." >&2
