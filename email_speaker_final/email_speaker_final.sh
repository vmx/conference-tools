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
# that are created when running this script. The final output is called
# `email_data.csv`

# You can get your auth token via
# curl -X POST --data "username=<your-username>&password=<your-password>" '<you-server>/api2/auth-token/'

if [ "${#}" -lt 7 ]; then
    echo "Usage: $(basename "${0}") <pretalx-api-url> <pretalx-api-token> <seafile-base-url> <seafile-auth-token> <seafile-repo-id> <seafile-directory> <email-template-file>"
    echo ""
    echo "Example: $(basename "${0}") https://pretalx.com/api/events/your-event cc78456d498548331ea9b744f262fa68d23d27e8 https://example.org fe91e764226cc534811f0ba32c62a6ac41ad0d7b 280b593a-f868-0594-d97a-23d88822a35f some-dir email.template"
    exit 1
fi

pretalx_api_url=${1}
pretalx_api_token=${2}
seafile_base_url=${3}
seafile_api_token=${4}
seafile_repo_id=${5}
seafile_dir=${6}
email_template=${7}

seafile_api_v20="${seafile_base_url}/api2"

mkdir -p out
cd out || exit 2

# The pretalx part
echo "Getting data from pretalx…"

# We only care about the confirmed talks
python3 ../pretalx-get-all.py "${pretalx_api_token}" "${pretalx_api_url}/submissions/?state=confirmed" > confirmed.json

# Exclude certain types of submissions. This is a FOSSGIS 2021 specific step.
# It de-duplicates the data, so that it is one entry per speaker, as we want
# to send the email about the upload link to all speakers of a talk
jq '[.results[] | select((.submission_type[] | contains("Workshop")) or (.submission_type[] == "Anwendertreffen / BoF") | not) | { code: .code, speaker: .speakers[].code, title: .title, submission_type: .submission_type[]}]' < confirmed.json > talks.json

# Get all the speakers
python3 ../pretalx-get-all.py "${pretalx_api_token}" "${pretalx_api_url}/speakers/" > speakers.json

# Transform the file to one where the speaker code (identifier) is the key and the value their name and email address
jq '.results[] | {(.code): {name, email}}' < speakers.json|jq -s 'add' > speakers_name_email.json


# The Seafile part
echo "Getting data from Seafile…"

curl --silent -X GET --header "Authorization: Token ${seafile_api_token}" "${seafile_api_v20}/repos/${seafile_repo_id}/dir/?p=/${seafile_dir}&t=d"|jq --raw-output '.[].name' > prerecorded_talks.txt


# Final output part

# Transform output into a list where one item is one speaker with all their
# talks
python3 ../combine_talks_speakers_prerecorded_talks.py|jq '[. | group_by(.email)[] | {email: .[0].email, name: .[0].name, talks: [.[] | {title, is_prerecorded}]}]' > combined.json

# Check if *all* their talks were either pre-recorded :
jq '[.[] | {email, name, all_talks_prerecorded: [.talks[].is_prerecorded] | all}]' < combined.json > combined_prerecorded.json

# Create individual emails
python3 ../data_to_email.py "../${email_template}" combined_prerecorded.json

echo "Emails can found at \`out/emails\`."
