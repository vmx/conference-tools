Scripts to create a schedule for the pre-recorded and live talks. You need [Seafile] and [pretalx].

Get the schedule:

    curl https://pretalx.com/<your-conference>/schedule.json > schedule.json

For getting the lengths of the videos, download them all with the download script from [`../download_files`]. Then run the [`get_length.sh` script] in each of the directories and output then into a file. For example:

    cd your-talks-day1
    /path/to/get_lengths.sh > ../lengths/day1.txt

Then combine the lengths of all days into a single file:

    cat ../lengths/*.txt > ../talk_lengths.txt

Now you can create the final schedule:

    cd ..
    python3 /path/to/list_recorded_talks.py schedule.json talk_lengths.txt

Here's a sample [schedule from the FOSSGIS 2021].

[Seafile]: https://seafile.com/
[pretalx]: https://pretalx.com/
[`../download_files`]: ../download_files
