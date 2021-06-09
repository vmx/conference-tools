#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes a directory that contains directories named after pretalx
# IDs and copies the most recent `.mkv` file into another directory, named
# after a certain scheme suitable for people that need to play those files at
# the conference.
#
# You need to have the following utilities installed:
# curl, jq

# You can get your auth token via
# curl -X POST --data "username=<your-username>&password=<your-password>" '<you-server>/api2/auth-token/'

if [ "${#}" -lt 7 ]; then
    echo "Usage: $(basename "${0}") <pretalx-api-url> <pretalx-api-token> <seafile-base-url> <seafile-auth-token> <seafile-repo-id> <seafile-source-directory> <seafile-target-directory>"
    echo ""
    echo "Example: $(basename "${0}") https://pretalx.com/api/events/your-event cc78456d498548331ea9b744f262fa68d23d27e8 https://example.org fe91e764226cc534811f0ba32c62a6ac41ad0d7b 280b593a-f868-0594-d97a-23d88822a35f some-dir some-other-dir"
    exit 1
fi

pretalx_api_url=${1}
pretalx_api_token=${2}
seafile_base_url=${3}
seafile_api_token=${4}
seafile_repo_id=${5}
seafile_source_dir=${6}
seafile_target_dir=${7}

mkdir -p out
cd out || exit 2

# The pretalx part
echo "Getting data from pretalx…"

## Get the current schedule version
schedule_url=$(curl --silent "${pretalx_api_url}/" --header "Authorization: Token ${pretalx_api_token}"|jq --raw-output '.urls.schedule')
schedule_version=$(curl --silent -X GET "${schedule_url}export/schedule.json"|jq --raw-output '.schedule.version'|tr --delete '.')

# We only care about the confirmed talks
python3 ../pretalx-get-all.py "${pretalx_api_token}" "${pretalx_api_url}/submissions/?state=confirmed" > confirmed.json

# Create a file that creates the scheduling information. Exclude lightning talks.
jq '.results[] | select((.submission_type[] | contains("Lightning Talk")) | not) | {(.code): {title, room: first(.slot.room[]), start: .slot.start}}' < confirmed.json|jq --slurp 'add' > schedule.json

# The Seafile part

# Only copy files we haven't copied yet, create a list of those files.
../get_files_to_copy.sh "${seafile_base_url}" "${seafile_api_token}" "${seafile_repo_id}" "${seafile_source_dir}" "${seafile_target_dir}/${schedule_version}" > files_to_copy.txt

## Copy the files from that list
../copy_files.sh "${seafile_base_url}" "${seafile_api_token}" "${seafile_repo_id}" files_to_copy.txt

echo "Files were sucessfully synchronized."
