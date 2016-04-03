# qbt_client CHANGELOG

## v1.0.0

Update client to work with qBitTorrent 3.3.4 WebUI changes

- Login method has changed from digest authentication to cookie based token
  - NOTE: minimum password length is now 6 chars
- `/json/` url paths have changed to `/query/`
- `/command/pauseall` has changed to `/command/pauseAll` (all paths are case sensitive)
- `/command/resumeall` has changed to `/command/resumeAll`
- `/command/getTorrentDlLimit` changed to `/command/getTorrentsDlLimit`
  - `hash` option changed to `hashes` option
- `/command/setTorrentDlLimit` changed to `/command/setTorrentsDlLimit`
  - `hash` option changed to `hashes` option
- `/command/getTorrentUpLimit` changed to `/command/getTorrentsUpLimit`
  - `hash` option changed to `hashes` option
- `/command/setTorrentUpLimit` changed to `/command/setTorrentsUpLimit`
  - `hash` option changed to `hashes` option
- Turn on network debug output when `DEBUG` env var is set


## v0.1.0

Initial release
