#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Christopher Lorenz <dev@lorenz.lu>
# SPDX-License-Identifier: MIT

# This script to generate b2sum for all directories in schedule.
# You need to download or sync schedule directory
#
# You need to have the following utilities installed:
# b2sum


if [ "${#}" -lt 1 ]; then
    echo "Usage: $(basename "${0}") <schedule-dir>"
    echo ""
    exit 1
fi

if ! [ -d "$1" ]
then
    echo "Directory '$1' does not exists."
    exit 2
fi

# Find all directories with video files
for dir in $(find "$1" -type f -name "*.mkv" -o -name "*.mp4" -exec dirname "{}" \; |sort -u)
do
    echo "Processing b2sum ${dir} … "
    b2sum ${dir}/*.* > "${dir}/B2SUMS"
done
