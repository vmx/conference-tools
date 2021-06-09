Scripts to copy files based on a pretalx ID based structure into a schedule based one. You need [Seafile] and [pretalx].

Usage:

    ./cut_to_schedule.sh <pretalx-api-url> <pretalx-api-token> <seafile-base-url> <seafile-auth-token> <seafile-repo-id> <seafile-source-directory> <seafile-target-directory>

Example:

    ./cut_to_schedule.sh https://pretalx.com/api/events/your-event cc78456d498548331ea9b744f262fa68d23d27e8 https://example.org fe91e764226cc534811f0ba32c62a6ac41ad0d7b 280b593a-f868-0594-d97a-23d88822a35f some-dir some-other-dir

[Seafile]: https://seafile.com/
[pretalx]: https://pretalx.com/
