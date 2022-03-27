#!/bin/bash

source functions.sh

path_to_logfile=$1

if [[ -z $path_to_logfile ]]; then
    echo "logging output to stdout"
fi

dashes="------------------------------"

header() {
    log "$dashes"
    log "$(date)"
    log "$dashes"
}

# provides output similar to the rotate_key function in functions.sh to test logging without rotating
mock_rotate() {
    echo "deleted key for profile $1 successfully"
    echo "successfully replaced key and secret pair for profile $1"
    echo "and set new secret for key"
}

pipe_log() {
    while read data;
    do
        if [[ -n "$path_to_logfile"]]; then
            echo "$data" >> "$path_to_logfile"
        else
            echo "$data"
        fi
    done;
}

log() {
    if [[ -n "$path_to_logfile" ]]; then
        echo "$@" >> "$path_to_logfile"
    else
        echo "$@"
    fi
}

# list of all AWS profiles by name
PROFILES="default profile1 profile2"

header
for profile in $PROFILES; do
    rotate_key $profile | pipe_log
    log "$dashes"
done