#!/bin/dash

if [ $# -eq 0 ]; then
    echo "usage: $0 <filenames>"
    exit 1
elif [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found"
    exit 1
fi

for file in "$@"; do
    if [ ! -e "$file" ]; then
        echo "$0: error: can not open '$file'"
        exit 1
    elif [ ! -f "$file" ]; then
        echo "$0: error: '$file' is not a regular file"
        exit 1
    fi
done


