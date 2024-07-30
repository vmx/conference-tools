Tools for reuse and more
========================

`seafile_get_token.sh`
----------------------

Usage:

    ./seafile_get_token.sh

This script will give a token of Seafile by given login credentials. It will append the token to `../config`.

`email_to_pretalx.sh`
---------------------

Usage:

    ./email_to_pretalx.sh <subject> <emails-dir> <cookie-data>

Example:

    ./email_to_pretalx.sh "Upload Links" email_upload_links/out/emails 'pretalx_csrftoken=zY8j6zcV6O…'

Send all mails from given directory. Filenames are the codes of submission. Sending e-mail to individual speakers is currently not supported.
The parameter `cookie-data` which are needed can be determined by login to pretalx: 
`${PRETALX_URL}/orga/event/${PRETALX_EVENT}/mails/compose` 

In the developer console of your browser you can get the `cookie-data` using "Copy as cURL" of the last request of any page. If you keep login you can send automated mails.

Mails are send are move to subfolder send, so you can rerun the script after an error.
