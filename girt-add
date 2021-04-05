#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ $# -eq 0 ]; then
    echo "usage: $0 <filenames>" 1>&2
    exit 1
fi

# check files exist and are regular before staging them
for file in "$@"; do
    if [ ! -e "$file" ]; then
        if cat .girt/index | cut -f1 | grep -Fqx -- "$file"; then continue; fi
        echo "$0: error: can not open '$file'" 1>&2
        exit 1
    elif [ ! -f "$file" ]; then
        echo "$0: error: '$file' is not a regular file" 1>&2
        exit 1
    fi
done

# girt-add each file
# file is guaranteed to be a regular file, or not exist in cwd but exist in index
for file in "$@"; do
    escaped_file=$(echo "$file" | sed 's:[]\[^$.*/]:\\&:g')
    sed -i "/^$escaped_file$(printf '\t')/d" .girt/index # remove file from index if it exists

    if [ -e "$file" ]; then
        mode=$(stat -c'%a' -- "$file")
        hash=$(sha1sum -- "$file" | cut -d' ' -f1)

        printf "%s\t%s\t%s\n" "$file" "$mode" "$hash" >> .girt/index # append to index
        sort -o .girt/index .girt/index

        gzip -c -- "$file" > ".girt/objects/blobs/$hash" # create blob
    fi
done
