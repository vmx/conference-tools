#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script creates emails for all speakers that contains different
# dinformation depending on whether they pre-recorded a talk or not.
#
# As all options are mandatory, please use the specific order, I didn't want
# to complicate the script unnecessarily.
#
# You need to have the following utilities installed:
# jq, curl, python3
#
# This script creates a directory called `out` which contains all the files
# that are created when running this script. 

cd $(dirname $0)
. ../config

seafile_api_v20="${SEAFILE_URL}/api2"

mkdir -p out
cd out || exit 2

# The pretalx part
echo "Getting data from pretalx…"

# We only care about the confirmed talks
python3 ../../utils/pretalx-get-all.py "${PRETALX_API_TOKEN}" "${PRETALX_API_URL}/submissions/?state=confirmed" > confirmed.json

# Exclude certain types of submissions. This is a FOSSGIS 2021 specific step.
# It de-duplicates the data, so that it is one entry per speaker, as we want
# to send the email about the upload link to all speakers of a talk
jq "[.results[] | ${TALKS_EXCLUDE_FILTER} | not) | { code: .code, speaker: .speakers[].code, title: .title, submission_type: .submission_type[]}]" < confirmed.json > talks.json

# Get all the speakers
python3 ../../utils/pretalx-get-all.py "${PRETALX_API_TOKEN}" "${PRETALX_API_URL}/speakers/" > speakers.json

# Transform the file to one where the speaker code (identifier) is the key and the value their name and email address
jq '.results[] | {(.code): {name, email}}' < speakers.json|jq -s 'add' > speakers_name_email.json


# The Seafile part
echo "Getting data from Seafile…"

curl --silent -X GET --header "Authorization: Token ${SEAFILE_API_TOKEN}" "${seafile_api_v20}/repos/${SEAFILE_REPO_ID}/dir/?p=/${SEAFILE_PROCESS_DIR}/${SEAFILE_PROCESS_COMPLETE_DIR}&t=d"|jq --raw-output '.[].name' > prerecorded_talks.txt


# Final output part
python3 ../combine_talks_speakers_prerecorded_talks.py > combined.json

# Create emails per Talk
python3 ../../utils/data_to_email_submission.py "${MAIL_TEMPLATE_FINAL}" combined.json

echo "Emails can found at \`out/emails\`."
