Script to download files from a password protected directory from [Seafile] for video team.

Usage:

    ./download_files.sh <download-url> <absolute-path> <password> <output-dir>

Example:

    ./download_files.sh https://example.org/d/d590ba6f7cda44840835 '/some/sub-dir' your-password ./local-dir


Using this script you need to create b2sum files to check correct download. You need to download or sync the schedule directory.

Usage:

    ./create_b2sums.sh <schedule-dir>

Example:
    ./create_b2sums.sh /media/seafile/myconf/schedule/09/
