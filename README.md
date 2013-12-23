# xwatch

Logs when X windows become active (in CSV format). A log entry is created when focus moves to another window or the active window's title changes.

The following items are logged:

- Timestamp
- Window title
- `cmdline` for the process

Example entry:

    "2013-12-23 13:35:19","GitHub - Chromium","/usr/lib/chromium/chromium"

## Usage

    usage: xwatch.sh [options]
    logs when X windows become active (in CSV format)

        -f <filename>    use filename as the log file (default: ~/.xwatch)
                         the '-' character denotes standard output
        -t <format>      the timestamp format (default: %Y-%m-%d %H:%M:%S)
        -h, --help       show this help message


## Notes

1. Requires `xprop` and the following X window properties:

    - `_NET_ACTIVE_WINDOW` (root window)
    - `_NET_WM_PID`
    - `_NET_WM_NAME`

2. Unicode characters are not properly logged if the current charset is not UTF-8.

## License

This software is released under the MIT license (see LICENSE).

---

Author: Tim Cooper <<tim.cooper@layeh.com>>
