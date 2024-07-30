#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# Copy files from source to target. It takes a list of files, where every line
# consists source and target file separated by a null byte.
#
# You need to have the following utilities installed:
# curl, jo, jq

# You can get your auth token via
# curl -X POST --data "username=<your-username>&password=<your-password>" '<you-server>/api2/auth-token/'

if [ "${#}" -lt 4 ]; then
    echo "Usage: $(basename "${0}") <base-url> <auth-token> <repo-id> <file-with-files-to-copy"
    echo ""
    echo "Example: $(basename "${0}") https://example.org fe91e764226cc534811f0ba32c62a6ac41ad0d7b 280b593a-f868-0594-d97a-23d88822a35f files_to_copy.txt"
    exit 1
fi

base_url=${1}
token=${2}
repo_id=${3}
files_to_copy_file=${4}

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
  printf "$format\\n" "$@"
}

# Creates the directory if it doesn't exist yet
create_dir() {
    dir=${1}

    details_code=$(curl --silent -X GET --header "Authorization: Token ${token}" "${api_v21}/repos/${repo_id}/dir/detail/?path=${dir}" --output /dev/null --write-out '%{http_code}')
    if [ "${details_code}" = "404" ]
    then
        echo "Creating directory ${dir}…" >&2
        mkdir_ret=$(curl --silent -X POST --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/dir/?p=${dir}" --data 'operation=mkdir')
        if [ "${mkdir_ret}" != '"success"' ]
        then
            echo "Error: cannot create directory '${dir}'."
            exit 1
        fi
    fi
}

# Takes a path and creates all those directories in case they don't exist yet
create_parent_dirs () {
    dirpath=${1}

    # Make the filepath loopable
    dirs=$(echo "${dirpath}"|tr '/' '\n')
    buildup=''
    for dir in ${dirs}
    do
        buildup="${buildup}/${dir}"
        create_dir "${buildup}"
    done
}


files_to_copy=$(cat "${files_to_copy_file}")

for to_copy in ${files_to_copy}
do
    while IFS=$(printf "\t") read -r source target
    do
        source_urlencoded=$(urlencode_grouped_case "${source}")
        source_file=$(basename "${source}")
        source_file_urlencoded=$(urlencode_grouped_case "${source_file}")
        target_dir=$(dirname "${target}")
        target_file=$(basename "${target}")

        # Create parent directories if they don't exist yet
        create_parent_dirs "${target_dir}"

        # Copy the file
        copy_ret=$(curl --silent -X POST --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/file/?p=${source_urlencoded}" --data "operation=copy&dst_repo=${repo_id}&dst_dir=${target_dir}")
        if [ "${copy_ret}" != "$(jo repo_id="${repo_id}" parent_dir="${target_dir}/" obj_name="${source_file}")" ]
        then
            echo "Error: copying '${source}' to '${target_dir}/' didn't work as expected."
            exit 2
        fi

        # Give the copied file the correct name
        rename_ret=$(curl --silent -X POST --header "Authorization: Token ${token}" "${api_v20}/repos/${repo_id}/file/?p=${target_dir}/${source_file_urlencoded}" --data "operation=rename&newname=${target_file}")
        if [ "${rename_ret}" != '"success"' ]
        then
            echo "Error: cannot rename file '${target_dir}/${source_file}' to '${target_dir}/${target_file}'."
            exit 3
        fi
    done <<EOF
${to_copy}
EOF
done

echo "Successfully copied all files from '${files_to_copy_file}'." >&2
