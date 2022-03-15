#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# Synchronizes all files of the source directory into the target directory.
# Files are only copied if they don't exist on the target yet. Empty
# directories are not copied.
# The target directory is created if it doesn't exist yet.
# The script outputs newly created directories. That information can be used
# by other scripts, to e.g. place additional files in the newly created
# directories.
#
# You need to have the following utilities installed:
# curl, jo, jq

# You can get your auth token via
# curl -X POST --data "username=<your-username>&password=<your-password>" '<you-server>/api2/auth-token/'

cd $(dirname $0)
. ../config

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
api_v21="${base_url}/api/v2.1"

# In this script we always only want to split at newlines in for loops
# https://github.com/koalaman/shellcheck/wiki/SC2039#c-style-escapes
IFS="$(printf '%b_' '\n')"; IFS="${IFS%_}"

# https://unix.stackexchange.com/questions/60653/urlencode-function/60698#60698
urlencode_grouped_case () {
  string=$1; format=; set --
  while
    literal=${string%%[!-._~0-9A-Za-z]*}
    case "$literal" in
      ?*)
        format=$format%s
        set -- "$@" "$literal"
        string=${string#$literal};;
    esac
    case "$string" in
      "") false;;
    esac
  do
    tail=${string#?}
    head=${string%$tail}
    format=$format%%%02x
    set -- "$@" "'$head"
    string=$tail
  done
  # shellcheck disable=SC2059 # The ${format} is the formatting pattern
  printf "${format}\\n" "$@"
}


# Check if target directory exists, if not, create it
details_code=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v21}/repos/${repo_id}/dir/detail/?path=/${target_dir}" --output /dev/null --write-out '%{http_code}')
if [ "${details_code}" = "404" ]
then
    mkdir_ret=$(curl --silent -X POST --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/dir/?p=/${target_dir}" --data 'operation=mkdir')
    if [ "${mkdir_ret}" != '"success"' ]
    then
        echo "Error: cannot create directory '${target_dir}'."
        exit 2
    fi
fi

# Get all directories with more than 1 file in it
list_dirs_ret=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/dir/?p=/${source_dir}&t=d"|jq --raw-output '.[].name')
for dir_name in ${list_dirs_ret}
do
    # Print progress indicator to stderr, so that you can still pipe the
    # expected output into a file.
    echo "Processing ${dir_name}…" >&2
    files=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/dir/?p=/${source_dir}/${dir_name}&t=f"|jq --raw-output '.[].name')

    # Copy file only if it wasn't copied yet
    for file in ${files}
    do
        file_urlencoded=$(urlencode_grouped_case "${file}")
        file_code=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/file/detail/?p=/${target_dir}/${dir_name}/${file_urlencoded}" --output /dev/null --write-out '%{http_code}')

        # The following code is FOSSGIS 2021 specific. When a file was cut
        # it is moved to a directory called `fertig` or in a root directory
        # called `vortraege_konferenz`. We don't want to copy any files that
        # were already cut successfully.
        fertig_dir_code=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v21}/repos/${repo_id}/dir/detail/?path=/${target_dir}/${SEAFILE_PROCESS_COMPLETE_DIR}/${dir_name}" --output /dev/null --write-out '%{http_code}')
        konferenz_dir_code=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v21}/repos/${repo_id}/dir/detail/?path=/vortraege_konferenz/${dir_name}" --output /dev/null --write-out '%{http_code}')

        if [ "${file_code}" = "404" ] && [ "${fertig_dir_code}" = "404" ] && [ "${konferenz_dir_code}" = "404" ]
        then
            # Print progress indicator to stderr, so that you can still pipe the
            # expected output into a file.
            echo "${dir_name}/${file} will be copied…" >&2

            # All parent directories must exist before copying files
            dir_name_code=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v21}/repos/${repo_id}/dir/detail/?path=/${target_dir}/${dir_name}" --output /dev/null --write-out '%{http_code}')
            if [ "${dir_name_code}" = "404" ]
            then
                dir_name_mkdir_ret=$(curl --silent -X POST --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/dir/?p=/${target_dir}/${dir_name}" --data 'operation=mkdir')
                if [ "${dir_name_mkdir_ret}" != '"success"' ]
                then
                    echo "Error: cannot create directory '${target_dir}/${dir_name}'."
                    exit 3
                fi
                echo "${dir_name}"
            fi

            copy_ret=$(curl --silent -X POST --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/file/?p=/${source_dir}/${dir_name}/${file_urlencoded}" --data "operation=copy&dst_repo=${repo_id}&dst_dir=/${target_dir}/${dir_name}")
            if [ "${copy_ret}" != "$(jo repo_id="${repo_id}" parent_dir="/${target_dir}/${dir_name}/" obj_name="${file}")" ]
            then
                echo "Error: copying '${source_dir}/${dir_name}/${file}' to '${target_dir}/${dir_name}/${file}' didn't work as expected."
                exit 4
            fi
        fi
    done
done

echo "Successfully synchronized from '${source_dir}' to '${target_dir}'." >&2
