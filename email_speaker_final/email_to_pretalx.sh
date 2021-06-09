#!/bin/sh
#set -o xtrace

# SPDX-FileCopyrightText: Volker Mische <volker.mische@gmail.com>
# SPDX-License-Identifier: MIT

# This script takes a directory where each file contains an email body, the
# flename is the email address. Those email are then posted to pretalx into
# the outgoing email queue.

if [ "${#}" -lt 6 ]; then
    echo "Usage: $(basename "${0}") <emails-dir> <reply-to> <email-subject> <pretalx-url> <cookie-data> <csrf-token>"
    echo ""
    echo "Example: $(basename "${0}") ./out/emails 'reply@example.org' Information for speakers' https://pretalx.com/orga/event/your-event/mails/compose 'pretalx_csrftoken=zY8j6zcV6O…' 'EshSi…'"
    exit 1
fi

emails_dir=${1}
reply_to=${2}
subject=${3}
pretalx_url=${4}
cookie_data=${5}
csrf_token=${6}


for file in "${emails_dir}"/*
do
    email_address=$(basename "${file}")
    echo ${email_address}
    email_body=$(cat "${file}")
    #email_body="some body"
    #echo "${email_body}"
    #data_raw="csrfmiddlewaretoken=${csrf_token}&additional_recipients=${email_address}&reply_to=${reply_to}&cc=&bcc=&subject=${subject}&text=${email_body}"
    #data_urlencode="csrfmiddlewaretoken=${csrf_token}&additional_recipients=${email_address}&reply_to=${reply_to}&cc=&bcc=&subject=${subject}&text=${email_body}"
    #echo "${data_url_encode}"
    #echo curl "${pretalx_url}" -H "Cookie: ${cookie_data}"  --data-urlencode "${data_urlencode}"
    curl "${pretalx_url}" -H "Referer: ${pretalx_url}" -H "Cookie: ${cookie_data}"  --data-raw "csrfmiddlewaretoken=${csrf_token}" --data-urlencode "additional_recipients=${email_address}" --data-urlencode "reply_to=${reply_to}" --data-urlencode "subject=${subject}" --data-urlencode "text=${email_body}"
done
