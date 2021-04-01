#!/bin/dash

if [ $# -ne 0 ]; then
    echo "usage: $0" 1>&2
    exit 1
elif [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
fi

for commit in .girt/objects/commits/*; do
    message=$(cat -- "$commit" | grep '^message:' | sed 's/^message://')
    echo "$(basename -- "$commit")" "$message"
done
