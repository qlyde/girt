#!/bin/dash

if [ $# -eq 0 ]; then
    echo "usage: $0 <filenames>" 1>&2
    exit 1
elif [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
fi

# check files exist and are regular before staging them
for file in "$@"; do
    if [ ! -e "$file" ]; then
        echo "$0: error: can not open '$file'" 1>&2
        exit 1
    elif [ ! -f "$file" ]; then
        echo "$0: error: '$file' is not a regular file" 1>&2
        exit 1
    fi
done

# create index file if user removed it
[ -e .girt/index ] || touch .girt/index

# append "mode filename hash" to index
for file in "$@"; do
    # remove file from index if it exists
    sed -i "/^$file /d" .girt/index # ASSUME $file has no breaking characters

    permissions=$(stat -c'%A' -- "$file" | cut -c2) # reference only cares about user's read permissions
    hash=$(cat -A -- "$file" | sha1sum | cut -d' ' -f1)
    echo "$file $permissions $hash" >> .girt/index
done
