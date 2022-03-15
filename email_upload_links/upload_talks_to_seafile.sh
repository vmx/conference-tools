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

cd $(dirname $0)
. ../config

mkdir -p out
cd out || exit 2

# The pretalx part
echo "Getting data from pretalx…"

# We only care about the confirmed talks
python3 ../../utils/pretalx-get-all.py "${PRETALX_API_TOKEN}" "${PRETALX_API_URL}/submissions/?state=confirmed" > confirmed.json

# Create a list of talk IDs. This file is used as the source to create the
# direcotries on Seafile
jq -r ".results[] | ${TALKS_EXCLUDE_FILTER} | not) | .code" < confirmed.json > dirs.txt

# Exclude certain types of submissions. This should be the only FOSSGIS 2021
# specific step.
# It de-duplicates the data, so that it is one entry per speaker, as we want
# to send the email about the upload link to all speakers of a talk
jq "[.results[] | ${TALKS_EXCLUDE_FILTER} | not) | { code: .code, speaker: .speakers[].code, title: .title, submission_type: .submission_type[]}]" < confirmed.json > talks.json

# Get all the speakers
python3 ../../utils/pretalx-get-all.py "${PRETALX_API_TOKEN}" "${PRETALX_API_URL}/speakers/" > speakers.json

# Transform the file to one where the speaker code (identifier) is the key and the value their name and email address
jq '.results[] | {(.code): {name, email}}' < speakers.json|jq -s 'add' > speakers_name_email.json


# The Seafile part
echo "Creating directories on seafile…"
../createdirs.sh "${SEAFILE_URL}" "${SEAFILE_API_TOKEN}" "${SEAFILE_REPO_ID}" "${SEAFILE_UPLOAD_DIR}" nolink # create root directory for upload
# Create the directories on Seafile and return the upload links to them
xargs -n1 -I{} ../createdirs.sh "${SEAFILE_URL}" "${SEAFILE_API_TOKEN}" "${SEAFILE_REPO_ID}" "${SEAFILE_UPLOAD_DIR}"/{} < dirs.txt > upload_links.ndjson

jq -s 'add' < upload_links.ndjson > upload_links.json


# Final output part

# combine talks with upload links
# per speaker (currently mailing not working)
# python3 ../combine_talks_speakers_upload_links.py|jq '[. | group_by(.email)[] | {email: .[0].email, name: .[0].name, talks: [.[] | {title, upload_link}]}]' > combined.json
# combine per submission
python3 ../combine_talks_upload_links.py | jq 'unique' > combined.json

# Create individual emails
# python3 ../../utils/data_to_email.py "${MAIL_TEMPLATE_UPLOAD_LINKS}" combined.json
# Create email per submission
python3 ../../utils/data_to_email_submission.py "${MAIL_TEMPLATE_UPLOAD_LINKS}" combined.json

echo "Emails can found at \`out/emails\`."
