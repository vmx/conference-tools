# /usr/bin/env python3

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes a template and some data and creates individual files.
# The files are created in a directory called `md`, each file is named
# with the pretalx ID.

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

os.makedirs("md", exist_ok=True)
process_completed = "/"+os.environ['SEAFILE_PROCESS_DIR']+"/"+os.environ['SEAFILE_PROCESS_COMPLETE_DIR']

for entry in data:
    entry['process_completed'] = process_completed
    text = template.format(**entry)
    with open(f"md/{entry['code']}.md", "w") as md_file:
        md_file.write(text)
