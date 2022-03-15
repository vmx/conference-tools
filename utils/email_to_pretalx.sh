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
    echo "Usage: $(basename "${0}") <emails-dir> <subject> <cookie-data> "
    echo ""
    echo "Example: $(basename "${0}") email_upload_links/out/emails \${MAIL_UPLOAD_LINKS_SUBJECT} 'pretalx_csrftoken=zY8j6zcV6O…'"
    exit 1
fi

# emails_dir=${1} # need to resolve before load config
subject=${2}
cookie_data=${3}
pretalx_url=${PRETALX_URL}/orga/event/${PRETALX_EVENT}/mails/compose

mkdir -p "${emails_dir}/send"

for file in "${emails_dir}"/*
do
    email_address=$(basename "${file}")
    if [ "${email_address}" = "send" ]; then 
        # skip folder "send"
        continue
    fi
    email_body=$(cat "${file}")
    case "$email_address" in
        *@*)
            #  currently not working!
            echo Mail: ${email_address} - skip, not working
            # curl "${pretalx_url}" -H "Referer: ${pretalx_url}" -H "Cookie: ${cookie_data}"  --data-raw "csrfmiddlewaretoken=${csrf_token}" --data-urlencode "additional_recipients=${email_address}" --data-urlencode "reply_to=${MAIL_REPLAY_TO}" --data-urlencode "subject=${subject}" --data-urlencode "text=${email_body}"
            ;;
        *)
            echo -n "Send Mail for Submission: ${email_address}… "
            # get csrftoken
            csrf_token=$(curl --silent -X GET "${pretalx_url}" -H "Referer: ${pretalx_url}" -H "Cookie: ${cookie_data}" | grep csrf | cut -d'"' -f6)
            echo -n "csrf_token: ${csrf_token} … "

            # send data
            http_result=$(curl --silent "${pretalx_url}" -H "Referer: ${pretalx_url}" -H "Cookie: ${cookie_data}"  --data-raw "csrfmiddlewaretoken=${csrf_token}" --data-urlencode "submissions=${email_address}" --data-urlencode "reply_to=${MAIL_REPLAY_TO}" --data-urlencode "subject_2=${subject}" --data-urlencode "text_2=${email_body}" --output /dev/null --write-out '%{http_code} %{url_effective}')
            if [ "${http_result}" = "302 ${pretalx_url}" ]; then
                mv "${file}" "${emails_dir}/send/"
                echo "success"
            else
                exit 3
            fi
            ;;
    esac
done
