#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script creates info files for reviewing the talks, to make sure they
# are the right ones (the upload was correct), cut properly and meet the
# expected quality.

cd $(dirname $0)
. ../config

if [ "${#}" -lt 1 ]; then
    echo "Usage: $(basename "${0}") <info-template-file>"
    echo ""
    echo "Example: $(basename "${0}") info.template"
    exit 1
fi

info_template=${1}

mkdir -p out
cd out || exit 2

echo "Getting data from pretalx…"

# We only care about the confirmed talks
python3 ../../utils/pretalx-get-all.py "${PRETALX_API_TOKEN}" "${PRETALX_API_URL}/submissions/?state=confirmed" > confirmed.json
jq '.results' < confirmed.json > confirmed_results.json

# Get all the speakers
python3 ../../utils/pretalx-get-all.py "${PRETALX_API_TOKEN}" "${PRETALX_API_URL}/speakers/" > speakers.json

# Transform the file to one where the speaker code (identifier) is the key and the value their name and email address
jq '.results[] | {(.code): {name, email}}' < speakers.json|jq -s 'add' > speakers_name_email.json

python3 ../add_email_to_speaker.py > talks_with_email.json

# Extract Pretalx ID, speakers and title of the talk. Concat all speakers,
# their name as well as their email address.
jq '[.[] | { code, duration, speakers:  [.speakers[] | [.name, "<" + .email + ">"] | join(" ")] | join (", "), title}]' < talks_with_email.json > talks.json

# And create the information for the reviewers
python3 ../data_to_md.py "../${info_template}" talks.json || exit 3

echo "Info files were created succesfully."
