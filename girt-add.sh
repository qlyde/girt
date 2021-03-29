#!/bin/dash

if [ $# -eq 0 ]; then
    echo "usage: girt-add <filenames>" 1>&2
    exit 1
elif [ ! -d .girt ]; then
    echo "girt-add: error: girt repository directory .girt not found" 1>&2
    exit 1
fi

for file in "$@"; do
    if [ ! -e "$file" ]; then
        echo "girt-add: error: can not open '$file'" 1>&2
        exit 1
    elif [ ! -f "$file" ]; then
        echo "girt-add: error: '$file' is not a regular file" 1>&2
        exit 1
    fi
done


