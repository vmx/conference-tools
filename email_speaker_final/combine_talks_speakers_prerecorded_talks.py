# /usr/bin/env python3

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

import json

TALKS = "talks.json"
SPEAKERS = "speakers_name_email.json"
PRERECORDED_TALKS = "prerecorded_talks.txt"

with open(TALKS) as talks_file:
    talks = json.load(talks_file)

with open(SPEAKERS) as speakers_file:
    speakers = json.load(speakers_file)

with open(PRERECORDED_TALKS) as prerecorded_talks_file:
    prerecorded_talks = prerecorded_talks_file.read().strip().split('\n')

for talk in talks:
    # Add the speaker
    speaker = speakers[talk["speaker"]]
    talk["name"] = speaker["name"]
    talk["email"] = speaker["email"]
    # Delete the speaker code, which was only needed to get the name and email
    # address
    del talk["speaker"]

    # Add whether talk was prerecorded
    if talk["code"] in prerecorded_talks:
        talk["is_prerecorded"] = True
    else:
        talk["is_prerecorded"] = False

print(json.dumps(talks))
