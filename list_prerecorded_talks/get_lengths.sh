#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script gets the video lengths of all mkv files in the current directory.

if ! command -v ffprobe > /dev/null
then
    echo "'ffprobe' not found." && exit 1
fi

if ! command -v cut > /dev/null
then
    echo "'cut' not found." && exit 2
fi

for file in *.mkv
do
    length=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${file}"|cut -d '.' -f 1)
    echo "${length} ${file}"
done
