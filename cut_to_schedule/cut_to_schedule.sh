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

cd $(dirname $0)
. ../config

mkdir -p out
cd out || exit 2

# The pretalx part
echo "Getting data from pretalx…"

## Get the current schedule version
schedule_url=$(curl --silent "${PRETALX_API_URL}/" --header "Authorization: Token ${PRETALX_API_TOKEN}"|jq --raw-output '.urls.schedule')
schedule_version=$(curl --silent -X GET "${schedule_url}export/schedule.json"|jq --raw-output '.schedule.version'|tr --delete '.')

# We only care about the confirmed talks
python3 ../../utils/pretalx-get-all.py "${PRETALX_API_TOKEN}" "${PRETALX_API_URL}/submissions/?state=confirmed" > confirmed.json

# Create a file that creates the scheduling information. Exclude lightning talks.
jq ".results[] | ${TALKS_EXCLUDE_FILTER} | not) | {(.code): {title, room: first(.slot.room[]), start: .slot.start}}" < confirmed.json|jq --slurp 'add' > schedule.json

# The Seafile part

# Only copy files we haven't copied yet, create a list of those files.
../get_files_to_copy.sh "${SEAFILE_URL}" "${SEAFILE_API_TOKEN}" "${SEAFILE_REPO_ID}" "${SEAFILE_PROCESS_DIR}/${SEAFILE_PROCESS_COMPLETE_DIR}" "${SEAFILE_SCHEDULE_DIR}/${schedule_version}" > files_to_copy.txt

## Copy the files from that list
../copy_files.sh "${SEAFILE_URL}" "${SEAFILE_API_TOKEN}" "${SEAFILE_REPO_ID}" files_to_copy.txt

echo "Files were sucessfully synchronized."
