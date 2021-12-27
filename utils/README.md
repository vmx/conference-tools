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

    ./email_to_pretalx.sh <emails-dir> <cookie-data> <csrf-token>

Example:

    ./email_to_pretalx.sh email_upload_links/out/emails 'pretalx_csrftoken=zY8j6zcV6O…' 'EshSi…'"

Send all mails from given directory. Filenames are the codes of submission. Sending e-mail to individual speakers is currently not supported.
The parameter `cookie-data` and `csrf-token` which are needed can be determined by login to pretalx: 
`${PRETALX_URL}/orga/event/${PRETALX_EVENT}/mails/compose` 

In the developer console of your browser you can get the `cookie-data` using "Copy as cURL" of the last request of any page. On Mail Editor you can search `csrfmiddlewaretoken` in the source code of the page to find the paramter `csrf-token`.
