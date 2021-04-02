#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ $# -ne 0 ]; then
    echo "usage: $0" 1>&2
    exit 1
fi

for commit in .girt/objects/commits/*; do
    [ -f "$commit" ] || continue
    message=$(cat -- "$commit" | grep '^message:' | sed 's/^message://')
    printf "%s %s\n" "$(basename -- "$commit")" "$message"
done | sort -nr
