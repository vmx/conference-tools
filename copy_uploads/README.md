Scripts to copy files with some meta information for review and processing. You need [Seafile] and [pretalx].

It is a two step process. First, creating the meta information and second copying the file and that information.

Usage:
    ./create_info_files.sh <info-template-file>
    ./sync_files_and_upload_info.sh

Example:

    ./create_info_files.sh info.template
    ./sync_files_and_upload_info.sh

`sync_files_and_upload_info.sh` can be run multiple time for copy newly uploaded files, e.g. using `crontab`.

[Seafile]: https://seafile.com/
[pretalx]: https://pretalx.com/
