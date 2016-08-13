# LOGGING

We only log to the console by default.
See `config/application.rb` for details.

## Development

Default level is WARN, you can set RAILS_LOG_LEVEL. Use `tee` if you want to
have the logs in a file.

## Production e.i. on the Server

RAILS_LOG_LEVEL is WARN. To change it temporarily (until the next deploy): edit
`/etc/systemd/system/cider-ci_user-interface.service`, and restart the service.
Use `journalctl` to read the logs.
