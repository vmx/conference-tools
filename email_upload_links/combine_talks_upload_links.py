# /usr/bin/env python3

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

import json

TALKS = "talks.json"
UPLOAD_LINKS = "upload_links.json"

with open(TALKS) as talks_file:
    talks = json.load(talks_file)

with open(UPLOAD_LINKS) as upload_links_file:
    upload_links = json.load(upload_links_file)

for talk in talks:
    del talk["speaker"]

    # Add upload link
    talk["upload_link"] = upload_links[talk["code"]]

print(json.dumps(talks))
