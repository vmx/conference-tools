Scripts to copy files with some meta information. You need [Seafile] and [pretalx].

It is a two step process. First, creating the meta information and second copying the file and that information.

Usage:
    ./create_info_files.sh <pretalx-api-url> <pretalx-api-token> <info-template-file>
    ./sync_files_and_upload_info.sh <seafile-base-url> <seafile-auth-token> <seafile-repo-id> <seafile-source-directory
> <seafile-target-directory>

Example:

    ./create_info_files.sh https://pretalx.com/api/events/your-event cc78456d498548331ea9b744f262fa68d23d27e8 info.template
    ./sync_files_and_upload_info.sh https://example.org fe91e764226cc534811f0ba32c62a6ac41ad0d7b 280b593a-f868-0594-d97a-23d88822a35f uploaded-talks processing-talks

[Seafile]: https://seafile.com/
[pretalx]: https://pretalx.com/
