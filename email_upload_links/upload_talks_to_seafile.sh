#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# Creates directories on Seafile to upload talks which were submitted to
# pretalx. The output is a CSV file containing the pretalx code of the talk,
# its title, the submission type, the submitters name, their email address and
# the upload link.
#
# Please note that this script it tailered for the FOSSGIS 2021, it filters
# out certain submission types. Though this should be the only specific thing
# so it should be re-usable for other conferences that use pretalx and Seafile.
#
# As all options are mandatory, please use the specific order, I didn't want
# to complicate the script unnecessarily.
#
# You need to have the following utilities installed:
# jq, python3, xargs
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

mkdir -p out
cd out || exit 2

# The pretalx part
echo "Getting data from pretalx…"

# We only care about the confirmed talks
python3 ../pretalx-get-all.py "${pretalx_api_token}" "${pretalx_api_url}/submissions/?state=confirmed" > confirmed.json

# Create a list of talk IDs. This file is used as the source to create the
# direcotries on Seafile
jq -r '.results[] | select((.submission_type[] | contains("Workshop")) or (.submission_type[] == "Anwendertreffen / BoF") | not) | .code' < confirmed.json > dirs.txt

# Exclude certain types of submissions. This should be the only FOSSGIS 2021
# specific step.
# It de-duplicates the data, so that it is one entry per speaker, as we want
# to send the email about the upload link to all speakers of a talk
jq '[.results[] | select((.submission_type[] | contains("Workshop")) or (.submission_type[] == "Anwendertreffen / BoF") | not) | { code: .code, speaker: .speakers[].code, title: .title, submission_type: .submission_type[]}]' < confirmed.json > talks.json

# Get all the speakers
python3 ../pretalx-get-all.py "${pretalx_api_token}" "${pretalx_api_url}/speakers/" > speakers.json

# Transform the file to one where the speaker code (identifier) is the key and the value their name and email address
jq '.results[] | {(.code): {name, email}}' < speakers.json|jq -s 'add' > speakers_name_email.json


# The Seafile part
echo "Creating directories on seafile…"

# Create the directories on Seafile and return the upload links to them
xargs -n1 -I{} ../createdirs.sh "${seafile_base_url}" "${seafile_api_token}" "${seafile_repo_id}" "${seafile_dir}"/{} < dirs.txt > upload_links.ndjson

jq -s 'add' < upload_links.ndjson > upload_links.json


# Final output part

# Transform output into a list where one item is one speaker with all their
# talks
python3 ../combine_talks_speakers_upload_links.py|jq '[. | group_by(.email)[] | {email: .[0].email, name: .[0].name, talks: [.[] | {title, upload_link}]}]' > combined.json

# Create individual emails
python3 ../data_to_email.py "../${email_template}" combined.json

echo "Emails can found at \`out/emails\`."
