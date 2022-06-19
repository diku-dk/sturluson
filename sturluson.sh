#!/bin/sh

irc_out=$HOME/sturluson_irc_out

name=sturluson
password=$(cat sturluson_password)
channel="#proglangdesign"

# Input to the IRC client loop.
in=$(mktemp)
touch $in

# Output text file read by the slide.
touch $irc_out

# Program file.
file=$HOME/sturluson.fut

# Wrapper for invoking GNU timeout on non-GNU systems.
timeout_bin=$(which timeout)
timeout() {
    if which /usr/local/bin/gtimeout > /dev/null; then
        /usr/local/bin/gtimeout "$@"
    else
        $timeout_bin "$@"
    fi
}

startup() {
    (echo ":m nickserv identify $password" > $in
     sleep 20
     echo ":j $channel" > $in) &
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
    cut -d ':' -f 2- \
        | cut -d ' ' -f 3-
}

handle_line() {
    IFS='' read -r line
    if echo "$line" | egrep -q '<[^>]+> '$name'[:,] '; then
        code=$(echo "$line" | sed 's/.*'$name'[:,] //')
        run_futhark "$code"
    fi
}

run_futhark() {
    if echo "$@" | egrep -q '^(entry|module|type|import|let)'; then
        code="$@"
    else
        code=$(printf 'entry main =\n%s' "$*")
    fi

    echo "$code" > $file
    futhark run -w "$file" </dev/null 2>&1
}

process_text() {
    grep --line-buffered -E "^$channel" \
        | per_line shorten_line \
        | per_line handle_line >> $in
}

# Log onto IRC and keep the client running.
startup
tail -f "$in" \
    | while true; do ircloop; done \
    | while true; do tee /dev/tty; done \
    | while true; do process_text; done

