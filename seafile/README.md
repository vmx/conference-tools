Seafile based workflow for pre-recorded talks
=============================================

These tools were created in order to run a conference with pre-recorded talks during COVID times.
For file managment [Seafile] is used.

 - [email_upload_links]: Create emails with upload links to [Seafile]
 - [copy_uploads]: Copy files on [Seafile] for reviewers and add an additional file with additional information
 - [cut_to_schedule]: Copy the processed files on [Seafile] into a directory structure based on a [pretalx] schedule
 - [download_files]: Download files from a password protected directory from [Seafile]
 - [list_prerecorded_talks]: Get a schedule of the pre-recorded and live talks
 - [email_speaker_final]: Create emails with status of pre-recorded files
 - [utils]: Utilities and scripts for reuse, e.g. for sending mails

For running the scripts you need to configure your API keys and other setting in configuration file `config`.
You can do this by copying the sample and edit the file for your needs:

```
cp config.sample config
vi config
```

All code is licensed under the [MIT License](../LICENSE).

[pretalx]: https://pretalx.com/
[Seafile]: https://seafile.com/

[email_upload_links]: ./email_upload_links
[copy_uploads]: ./copy_uploads
[cut_to_schedule]: ./cut_to_schedule
[download_files]: ./download_files
[list_prerecorded_talks]: ./list_prerecorded_talks
[email_speaker_final]: ./email_speaker_final
[utils]: ./utils
