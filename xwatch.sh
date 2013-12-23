#!/bin/bash
#
# xwatch.sh - logs which X windows are active in CSV format
#
# Author: Tim Cooper <tim.cooper@layeh.com>
# License: MIT (see LICENSE)
#

logfile=$HOME"/.xwatch"
timeformat="%Y-%m-%d %H:%M:%S"
active_id=""
active_pid="-1"
active_proc=""
active_title=""
force=0

progname=$(basename $0)

# Parse arguments
function usage {
    echo "usage: $progname [options]"
    echo "logs when X windows become active (in CSV format)"
    echo
    echo "    -f <filename>    use filename as the log file (default: ~/.xwatch)"
    echo "                     the '-' character denotes standard output"
    echo "    -t <format>      the timestamp format (default: %Y-%m-%d %H:%M:%S)"
    echo "    -h, --help       show this help message"
}

while [ $# -ne 0 ]
do
    if [ "$1" = "-f" -a $# -gt 1 ]
    then
        shift
        logfile="$1"
        if [ "$logfile" = "-" ]
        then
            logfile="/dev/stdout"
        fi
    elif [ "$1" = "-t" -a $# -gt 1 ]
    then
        shift
        timeformat="$1"
    elif [ "$1" = "-h" -o "$1" = "--help" ]
    then
        usage
        exit 0
    else
        echo $(basename $0)": unknown or incomplete argument $1"
        exit 1
    fi
    shift
done

# Create FIFO
function cleanup {
    rm -f "$root_file" 2> /dev/null
    exit 0
}

root_file=$(mktemp -u)
mkfifo "$root_file"

trap cleanup SIGINT

# Start listening on the root window
xprop -notype -root -spy 0c _NET_ACTIVE_WINDOW > "$root_file" 2> /dev/null &

function escapequote {
    sed 's/"/\\"/'
}

cat "$root_file" | (while read line
do
    grep '^_NET_ACTIVE_WINDOW' > /dev/null 2> /dev/null <<< "$line"
    if [ $? = "0" ]
    then
        window_id=$(grep -Po '\d+$' 2> /dev/null <<< "$line")
        # Another window became active
        if [ "$active_id" = "$window_id" ]
        then
            continue
        fi
        if [ -n "$active_proc" ]
        then
            kill $active_proc 2> /dev/null
            wait $active_proc 2> /dev/null
        fi
        xprop -notype -id $window_id -spy _NET_WM_PID _NET_WM_NAME > "$root_file" 2> /dev/null &
        active_proc=$!
        active_id=$window_id
        force=1
    else
        grep '^_NET_WM_PID' > /dev/null 2> /dev/null <<< "$line"
        if [ $? = "0" ]
        then
            # Active window's PID
            active_pid=$(grep -Po '\d+$' 2> /dev/null <<< "$line")
            if [ $? != "0" ]
            then
                active_pid="-1"
            fi
        else
            # Active window's title changed
            title=$(sed 's/^_NET_WM_NAME = "//;s/"$//' <<< "$line")
            if [ "$force" = "1" -o "$title" != "$active_title" ]
            then
                timestamp=$(date +"$timeformat" | escapequote)
                cleantitle=$(escapequote <<< "$title")
                if [ $active_pid != "-1" ]
                then
                    cmdline=$(cat /proc/$active_pid/cmdline 2> /dev/null | escapequote)
                else
                    cmdline=""
                fi
                printf "\"%s\",\"%s\",\"%s\"\n" "$timestamp" "$cleantitle" "$cmdline" >> "$logfile" 2> /dev/null
                active_title="$title"
                force=0
            fi
        fi
    fi
done)
