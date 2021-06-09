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

print("FOSSGIS 2021 Schedule")
print("=====================")

# First day is the OSM sunday
days = schedule["schedule"]["conference"]["days"][1:]
for day in days:
    print("\n")
    print(day["date"])
    print("----------")
    for room_name, room in day["rooms"].items():
        # We only care about the four main stages
        if room_name in ["Bühne 1", "Bühne 2", "Bühne 3", "Bühne 4"]:
            print(f"\n\n### {room_name}\n")

            for talk in room:
                pretalx_id = talk["url"].split("/")[-2]

                # Special case lightning talks
                if pretalx_id in [
                    "MQWM83",
                    "QWFKTH",
                    "KXUK3W",
                    "ZLGACF",
                    "DF3TGM",
                    "97WELW",
                    "KVX7EA",
                    "ZVFZQQ",
                    "ZQKZQT",
                    "CQDB8M",
                    "DZCNKG",
                ]:
                    continue
                if pretalx_id in [
                    "WSUSUX",
                    "MTJ9R9",
                    "QVK8J8",
                    "DSUDXJ",
                    "MVPR79",
                    "DZCNKG",
                ]:
                    if pretalx_id == "WSUSUX":
                        talks_length[pretalx_id] = talks_length[
                            "day1_mon_20210607_1015_lightning_talks.mkv"
                        ]
                    elif pretalx_id == "MTJ9R9":
                        talks_length[pretalx_id] = talks_length[
                            "day1_mon_20210607_1700_lightning_talks.mkv"
                        ]
                    elif pretalx_id == "QVK8J8":
                        talks_length[pretalx_id] = talks_length[
                            "day2_tue_20210608_1000_lightning_talks.mkv"
                        ]
                    elif pretalx_id == "DSUDXJ":
                        talks_length[pretalx_id] = talks_length[
                            "day2_tue_20210608_1200_lightning_talks.mkv"
                        ]
                    elif pretalx_id == "MVPR79":
                        talks_length[pretalx_id] = talks_length[
                            "day3_wed_20210609_1200_lightning_talks.mkv"
                        ]
                    else:
                        pass

                    talk["title"] = "Lightning Talks"
                    talk["url"] = ""

                if pretalx_id in talks_length:
                    maybe_recorded = f"`{talks_length[pretalx_id]}`"
                else:
                    maybe_recorded = "live"
                if talk["url"]:
                    print(
                        f' - {talk["start"]}: {maybe_recorded} [{talk["title"]}]({talk["url"]})'
                    )
                else:
                    print(
                        f' - {talk["start"]}: {maybe_recorded} {talk["title"]}'
                    )
