#!/bin/sh

name=sturluson
password=$(cat sturluson_password)
channels="#futhark #proglangdesign"

# Input to the IRC client loop.
in=$(mktemp)
touch $in

startup() {
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


per_line() {
    function=$1
    while IFS='' read -r line; do
        echo "$line" | $function
    done
}

shorten() {
    tr '\n' ' ' | sed -E 's/\s+/ /g' | head -c 300
}

eval_futhark() {
    # This weird construction is to eliminate whitespace.
    echo $(timeout 4 futhark eval "$*" 2>&1 | shorten)
}

handle_line() {
    IFS='' read -r line
    channel=$(echo "$line" | cut -d' ' -f1)
    payload=$(echo "$line" | cut -d: -f2-)
    from=$(echo "$payload" | cut -d' ' -f4)
    msg=$(echo "$payload" | cut -d' ' -f5-)
    if echo "$msg" | egrep -q $name'[:,] '; then
        code=$(echo "$msg" | cut -d' ' -f2-)
        response=$(eval_futhark "$code")
        if [ "$response" ]; then
            echo ":m $channel $response"
        else
            echo ":m $channel I don't have time for that."
        fi
    fi
}

process_text() {
    grep --line-buffered -E "^#.*<[^>]+> *${name}[:,]" \
        | per_line handle_line >> "$in"
}

# Log onto IRC and keep the client running.
startup
tail -n 0 -f "$in" \
    | while true; do ircloop; done \
    | while true; do tee /dev/tty; done \
    | while true; do process_text; done

