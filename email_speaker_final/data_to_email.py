# /usr/bin/env python3

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes a template and some data and creates individual emails.
# The emails are created in a directory called "emails", each file is named
# with the email address of the speaker as it is one email per speaker.
# The file itself only contains the email body and not the subject.

import argparse
import json
import os

parser = argparse.ArgumentParser(
    description="Generate emails out of a some data and a template."
)
parser.add_argument("template", help="The template file to use.")
parser.add_argument("data", help="The JSON file to use as input data.")

args = parser.parse_args()

template_path = args.template
data_path = args.data


with open(template_path) as template_file:
    template = template_file.read()
with open(data_path) as data_file:
    data = json.load(data_file)

os.makedirs("emails", exist_ok=True)

for entry in data:
    # The text is slightly different depending on whether all talks were
    # pre-recorded or not
    if entry['all_talks_prerecorded']:
        entry["prerecorded_specific_text"] = """Thanks for uploading pre-recordings of all your talks."""
    else:
        entry["prerecorded_specific_text"] = """You haven't uploaded any pre-recordings."""

    email_body = template.format(**entry)
    with open(f"emails/{entry['email']}", 'w') as email_file:
        email_file.write(email_body)
