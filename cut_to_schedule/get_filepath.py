# /usr/bin/env python3

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes a pretalx ID and a data file that contains all the
# information that is needed to create the full path for the file, so that
# it can be easily be used by the team that is streaming the talk.
#
# The filepath is:
# <room>/day<day-of-the-conference>/day<day-of-the-conference>_<day-of-the-week>_<date>_<time>_<pretalx-id>_<title>

import argparse
import json
import re

from datetime import datetime

# We also output the day relative to the conference start
CONFERENCE_START = datetime.fromisoformat("2021-06-07T00:00+02:00")


parser = argparse.ArgumentParser(
    description="Generate a filename based on the schedule."
)
parser.add_argument("pretalx_id", help="The pretalx ID of the talk.")
parser.add_argument(
    "schedule", help="The JSON file containing the schedule information."
)

args = parser.parse_args()

pretalx_id = args.pretalx_id
schedule_path = args.schedule


def sanitize_string(in_string):
    # Replace non-alphanumeric characters we want to keep
    translate_dict = {
        "ä": "ae",
        "ö": "oe",
        "ü": "ue",
        "Ä": "Ae",
        "Ü": "Ue",
        "Ö": "Oe",
        "ß": "ss",
        " ": "_",
    }
    translate_table = in_string.maketrans(translate_dict)
    translated = in_string.translate(translate_table)
    # Remove all non-alphanumeric/dash/underscore characters
    return re.sub(r"[^a-zA-Z0-9_\-]+", "", translated)


def sanitize_date(in_date):
    parsed = datetime.fromisoformat(in_date)
    # formatted = f'{date.year}{date.month}{date.day}'
    date = parsed.strftime("%Y%m%d")
    time = parsed.strftime("%H%M")
    day_of_the_week = parsed.strftime("%a").lower()
    day_of_the_conference = (parsed - CONFERENCE_START).days + 1
    formatted = f"{day_of_the_week}_{date}_{time}"
    return (f"day{day_of_the_conference}", formatted)


with open(schedule_path) as schedule_file:
    schedule = json.load(schedule_file)

schedule_info = schedule[pretalx_id]
room = sanitize_string(schedule_info["room"]).lower()
title = sanitize_string(schedule_info["title"])
(day, date) = sanitize_date(schedule_info["start"])
filepath = f"{room}/{day}/{day}_{date}_{pretalx_id}_{title}.mkv"
print(filepath)
