#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ $# -ne 0 ]; then
    echo "usage: $0" 1>&2
    exit 1
fi

head=$(cat .girt/HEAD)
curr_commit=$(cat ".girt/$head")
while [ -n "$curr_commit" ]; do
    parent=$(cat ".girt/objects/commits/$curr_commit" | grep '^parent:' | sed 's/^parent://')
    message=$(cat ".girt/objects/commits/$curr_commit" | grep '^message:' | sed 's/^message://')
    printf "%s %s\n" "$curr_commit" "$message"
    curr_commit="$parent"
done
