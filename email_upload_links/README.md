Scripts to send upload links to every speaker. You need [Seafile] and [pretalx].

Usage:

    ./upload_talks_to_seafile.sh

All needed settings should be set in `../config` 

- Download submissions and speakers from pretalx
- Create directories in Seafile including links for every talk
- Create mails using templates for every submission (Default: `mail_templates/send_upload_links.template`) in `out/emails`.

You can send mails by using `../utils/email_to_pretalx.sh ./out/emails ....`

[Seafile]: https://seafile.com/
[pretalx]: https://pretalx.com/
