# /usr/bin/env python3

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes pretalx schedule an creates a text file which contains a
# list of recorded talks. The input is a pretalx schedule.json and a file
# that contains a list of recorded talks. That file contains one pretalx talk
# ID per line.

import argparse
import time
import json
import os

parser = argparse.ArgumentParser(description="Print text file of schedule.")
parser.add_argument("schedule", help="A schedule.json from pretalx.")
parser.add_argument(
    "talks_length", help="A file with the lengths of the recorded talks."
)

args = parser.parse_args()

schedule_path = args.schedule
talks_length_path = args.talks_length

with open(schedule_path) as schedule_file:
    schedule = json.load(schedule_file)
with open(talks_length_path) as talks_length_file:
    talks_length_list = talks_length_file.read().strip().split("\n")
    talks_length = {}
    for talk in talks_length_list:
        (seconds, filename) = talk.split(" ")
        pretalx_id = filename.split("_")[4]

        # special case lightning talks
        if pretalx_id == "lightning":
            pretalx_id = filename

        length = time.gmtime(int(seconds))
        length_formatted = time.strftime("%M:%S", length)
        talks_length[pretalx_id] = length_formatted

doc_title = f'FOSSGIS 2022 Schedule (Version {schedule["schedule"]["version"]})'
print(doc_title)
print("="*len(doc_title))

# First day is the OSM sunday
days = schedule["schedule"]["conference"]["days"]
for day in days:
    print("\n")
    print(day["date"])
    print("----------")
    for room_name, room in day["rooms"].items():
        # We only care about the four main stages
        if room_name in ["Bühne 1", "Bühne 2", "Bühne 3", "Demosession"]:
            print(f"\n\n### {room_name}\n")

            is_lt_block = False
            intend = ""


            for talk in room:
                pretalx_id = talk["url"].split("/")[-2]

                # Special case lightning talks
                if talk["type"] == "Lightning Talk":
                    if not is_lt_block:
                        # first LT
                        print(" - Lightning Talks:")
                    is_lt_block = True
                    intend = "    "
                else:
                    is_lt_block = False
                    intend = ""

                if pretalx_id in talks_length:
                    maybe_recorded = f"`{talks_length[pretalx_id]}`"
                else:
                    maybe_recorded = "**live**"
                if talk["url"]:
                    print(
                        f'{intend} - {talk["start"]}: {maybe_recorded} [{talk["title"]}]({talk["url"]})'
                    )
                else:
                    print(
                        f'{intend} - {talk["start"]}: {maybe_recorded} {talk["title"]}'
                    )
