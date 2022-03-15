#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Christopher Lorenz <osm@lorenz.lu>
# SPDX-License-Identifier: MIT

# This script creates the program.md

cd $(dirname $0)
. ../config

if [ "${#}" -lt 1 ]; then
    echo "Usage: $(basename "${0}") <schedule-dir>"

    exit 1
fi

if ! [ -d "$1" ]
then
    echo "Directory '$1' does not exists."
    exit 2
fi

mkdir -p out
cd out

# loading current schedule

curl ${PRETALX_URL}/${PRETALX_EVENT}/schedule.json > schedule.json

# getting lengths of all talks
echo "Calculate lengths of talks…"
../get_lengths.sh "$1" > talk_lengths.txt

# build program
echo "Building plan of program…"
python3 ../list_recorded_talks.py schedule.json talk_lengths.txt > program.md
cp program.md "$1"

echo "Created program: program.md"
cat program.md
