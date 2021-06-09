# /usr/bin/env python3

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

import json

TALKS = "talks.json"
SPEAKERS = "speakers_name_email.json"
UPLOAD_LINKS = "upload_links.json"

with open(TALKS) as talks_file:
    talks = json.load(talks_file)

with open(SPEAKERS) as speakers_file:
    speakers = json.load(speakers_file)

with open(UPLOAD_LINKS) as upload_links_file:
    upload_links = json.load(upload_links_file)

for talk in talks:
    # Add the speaker
    speaker = speakers[talk["speaker"]]
    talk["name"] = speaker["name"]
    talk["email"] = speaker["email"]
    # Delete the speaker code, which was only needed to get the name and email
    # address
    del talk["speaker"]

    # Add upload link
    talk["upload_link"] = upload_links[talk["code"]]

print(json.dumps(talks))
