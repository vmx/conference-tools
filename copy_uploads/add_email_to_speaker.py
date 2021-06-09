# /usr/bin/env python3

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# Add the email address to the speakers.

import json

TALKS = "confirmed_results.json"
SPEAKERS = "speakers_name_email.json"

with open(TALKS) as talks_file:
    talks = json.load(talks_file)

with open(SPEAKERS) as speakers_file:
    speakers = json.load(speakers_file)

for talk in talks:
    # Add the email address to the speakers
    for speaker in talk["speakers"]:
        speaker["email"] = speakers[speaker["code"]]["email"]

print(json.dumps(talks))
