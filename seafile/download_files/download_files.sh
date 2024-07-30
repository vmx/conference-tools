#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script downloads files from Seafile from a password protected directory
# from the command line. It only downloads the files of the given directory,
# it's *not* recursing down directories.
#
# You need to have the following utilities installed:
# b2sum, curl, cut, jq
#
# The CSRF Token part is taken from (2021-06-05):
# https://stackoverflow.com/questions/21306515/how-to-curl-an-authenticated-django-app/24376188#24376188

if [ "${#}" -lt 4 ]; then
    echo "Usage: $(basename "${0}") <download-url> <absolute-path> <password> <output-dir>"
    echo ""
    echo "Example: $(basename "${0}") https://example.org/d/d590ba6f7cda44840835 '/some/sub-dir' your-password ./local-dir"
    exit 1
fi

url=${1}
path=${2}
password=${3}
out_dir=${4}

# Check if all utilities that are required for this script are installed
if ! command -v b2sum > /dev/null
then
    echo "'b2sum' not found." && exit 2
fi
if ! command -v curl > /dev/null
then
    echo "'curl' not found." && exit 3
fi
if ! command -v cut > /dev/null
then
    echo "'cur' not found." && exit 4
fi
if ! command -v jq > /dev/null
then
    echo "'jq' not found." && exit 5
fi

# https://unix.stackexchange.com/questions/60653/urlencode-function/60698#60698
urlencode () {
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

# Create the output directory if it doesn't exist yet
mkdir -p "${out_dir}"
rm -f "${out_dir}/B2SUMS" &> /dev/null

# The URL without the path
base_url=$(echo "${url}"|cut -d '/' -f 1-3)
# The link name is also the token for the login request
token=$(echo "${url}"|cut -d '/' -f 5)
# The file to store the cookies at
COOKIES=cookies.txt
# Curl with default parameters
curl="curl --cookie-jar ${COOKIES} --cookie ${COOKIES} --referer ${url}"


echo "Get CSRF Token…"
${curl} "${url}/" --silent > /dev/null
csrf_token=$(grep csrftoken $COOKIES | sed 's/^.*csrftoken\s*//')


echo "Login…"
${curl} "${url}/" --silent --data-raw "csrfmiddlewaretoken=${csrf_token}&token=${token}&password=${password}" --output /dev/null


echo "Get directory listing…"

file_paths=$(${curl} --silent "${base_url}/api/v2.1/share-links/${token}/dirents/?path=${path}"|jq --raw-output '.dirent_list[].file_path')
for file_path in ${file_paths}
do
    file_path_urlencoded=$(urlencode "${file_path}")
    echo "Downloading ${file_path}…"
    if [ -f "${out_dir}/$(basename "${file_path}")" ]; then
        echo "File $(basename "${file_path}") already exists, if checksum is invalid please remove!"
    else
        ${curl} "${url}/files/?p=${file_path_urlencoded}&dl=1" --location --output "${out_dir}/$(basename "${file_path}")"
    fi
done

echo "Checksum check…"
cd "${out_dir}" || exit 6
b2sum --check B2SUMS
b2sum_status=$?
if [ "${b2sum_status}" = 0 ]
then
     echo "Checksums match."
else
     echo "ERROR: Checksums do *not* match. REMOVE BROKEN FILE AND START DOWNLOAD AGAIN!"
     exit 7
fi

echo "Downloading files was successful."
