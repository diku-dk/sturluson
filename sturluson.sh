#!/bin/sh

irc_out=$HOME/sturluson_irc_out

name=sturluson
password=$(cat sturluson_password)
channels="#futhark #proglangdesign"

# Input to the IRC client loop.
in=$(mktemp)
touch $in

# Output text file read by the slide.
touch $irc_out

# Program file.
file=$HOME/sturluson.fut

startup() {
    (sleep 10
     echo ":m nickserv identify $password" >> $in
     for c in $channels; do echo ":j $c" >> $in; done) &
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
        echo -e "$line" | $function
    done
}

shorten_line() {
    # Keep only the most important parts.
    cut -d ':' -f 2- | cut -d ' ' -f 3-
}

eval_futhark() {
    echo "$(timeout 4 futhark eval "$*" 2>&1 | head -c 300)"
}

handle_line() {
    IFS='' read -r line
    if echo "$line" | egrep -q '<[^>]+> '$name'[:,] '; then
        code=$(echo "$line" | sed 's/.*'$name'[:,] //')
        eval_futhark "$code"
        if [ $? = 124 ]; then
            echo "Took too long."
        fi
    fi
}

process_text() {
    grep --line-buffered -E "^#" \
        | per_line shorten_line \
        | per_line handle_line >> "$in"
}

# Log onto IRC and keep the client running.
startup
tail -n 0 -f "$in" \
    | while true; do ircloop; done \
    | while true; do tee /dev/tty; done \
    | while true; do process_text; done

