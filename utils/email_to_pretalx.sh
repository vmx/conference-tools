#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes a directory where each file contains an email body, the
# flename is the email address. Those email are then posted to pretalx into
# the outgoing email queue.

emails_dir=$(readlink -f ${1})

cd $(dirname $0)
. ../config

if [ "${#}" -lt 3 ]; then
    echo "Usage: $(basename "${0}") <emails-dir> <cookie-data> <csrf-token>"
    echo ""
    echo "Example: $(basename "${0}") email_upload_links/out/emails 'pretalx_csrftoken=zY8j6zcV6O…' 'EshSi…'"
    exit 1
fi

# emails_dir=${1} # need to resolve before load config
cookie_data=${2}
csrf_token=${3}
pretalx_url=${PRETALX_URL}/orga/event/${PRETALX_EVENT}/mails/compose

for file in "${emails_dir}"/*
do
    email_address=$(basename "${file}")
    email_body=$(cat "${file}")
    case "$email_address" in
        *@*)
            #  currently not working!
            echo Mail: ${email_address} - skip, not working
            # curl "${pretalx_url}" -H "Referer: ${pretalx_url}" -H "Cookie: ${cookie_data}"  --data-raw "csrfmiddlewaretoken=${csrf_token}" --data-urlencode "additional_recipients=${email_address}" --data-urlencode "reply_to=${MAIL_REPLAY_TO}" --data-urlencode "subject=${MAIL_UPLOAD_LINKS_SUBJECT}" --data-urlencode "text=${email_body}"
            ;;
        *)
            echo Submission: ${email_address}
            curl "${pretalx_url}" -H "Referer: ${pretalx_url}" -H "Cookie: ${cookie_data}"  --data-raw "csrfmiddlewaretoken=${csrf_token}" --data-urlencode "submissions=${email_address}" --data-urlencode "reply_to=${MAIL_REPLAY_TO}" --data-urlencode "subject_2=${MAIL_UPLOAD_LINKS_SUBJECT}" --data-urlencode "text_2=${email_body}"
            ;;
    esac
done
