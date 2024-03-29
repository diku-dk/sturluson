#!/bin/sh

name=sturluson
password=$(cat sturluson_password)
channels="#futhark #proglangdesign"

per_line() {
    function=$1
    while IFS='' read -r line; do
        echo "$line" | $function
    done
}

shorten() {
    tr '\n' ' ' | head -c 300
}

eval_futhark() {
    timeout 4 futhark eval "$*" 2>&1 | head -c 300 | sed -E 's/\s+$//'
}

eval_line() {
    code=$1
    response=$(eval_futhark "$code")
    if [ "$response" ]; then
        echo "$response" | ./print.py
    else
        echo "I don't have time for that."
    fi
}

on_output() {
    channel=$1
    awk '{print ":m", CHANNEL, $0}' CHANNEL=${channel}
}

handle_line() {
    IFS='' read -r line
    channel=$(echo "$line" | cut -d':' -f1 | cut -d' ' -f1)
    payload=$(echo "$line" | cut -d: -f2-)
    from=$(echo "$payload" | cut -d' ' -f4)
    msg=$(echo "$payload" | cut -d' ' -f5-)
    if echo "$msg" | egrep -q $name'[:,] '; then
        code=$(echo "$msg" | cut -d' ' -f2-)
        eval_line "$code" | on_output "$channel"
    fi
}

process_text() {
    grep --line-buffered -E "^#.*<[^>]+> *${name}[:,]" \
        | per_line handle_line >> "$in"
}

startup() {
    in=$1
    (sleep 8
     echo ":m nickserv identify $password" >> "$in"
     sleep 2
     for c in $channels; do echo ":j $c" >> "$in"; done) &
}

ircloop() {
    while true; do
        sic -h irc.libera.chat -n "$name"
        sleep 2
        startup
    done
}

if [ $# -gt 0 ]; then
    eval_line "$@" | on_output '#channel'
else
    # Input to the IRC client loop.
    in=$(mktemp)
    touch $in

    # Log onto IRC and keep the client running.
    startup "$in"
    tail -n 0 -f "$in" \
        | while true; do ircloop; done \
        | while true; do tee /dev/tty; done \
        | while true; do process_text; done

fi
