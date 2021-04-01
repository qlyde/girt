#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ $# -eq 0 ]; then
    echo "usage: $0 <filenames>" 1>&2
    exit 1
fi

head=$(cat .girt/HEAD)
parent_commit=$(cat ".girt/$head")

# check files exist and are regular before staging them
for file in "$@"; do
    # if file doesn't exist but exists in latest commit tree then continue
    flag=
    if [ ! -e "$file" -a -n "$parent_commit" ]; then
        parent_tree=$(cat ".girt/objects/commits/$parent_commit" | grep '^tree:' | sed 's/^tree://')
        while IFS= read -r line; do
            parent_tree_file=$(echo "$line" | cut -d'/' -f1)
            if [ "$file" = "$parent_tree_file" ]; then
                flag=true
            fi
        done < ".girt/objects/trees/$parent_tree"
        if [ -n "$flag" ]; then continue; fi
    fi

    if [ ! -e "$file" ]; then
        echo "$0: error: can not open '$file'" 1>&2
        exit 1
    elif [ ! -f "$file" ]; then
        echo "$0: error: '$file' is not a regular file" 1>&2
        exit 1
    fi
done

for file in "$@"; do
    if [ ! -e "$file" -a -n "$parent_commit" ]; then
        parent_tree=$(cat ".girt/objects/commits/$parent_commit" | grep '^tree:' | sed 's/^tree://')
        while IFS= read -r line; do
            parent_tree_file=$(echo "$line" | cut -d'/' -f1)
            if [ "$file" = "$parent_tree_file" ]; then
                # file doesn't exist but exists in latest commit tree so add to rmindex
                sed -i "/^$file$/d" .girt/rmindex
                echo "$file" >> .girt/rmindex
            fi
        done < ".girt/objects/trees/$parent_tree"
    else
        mode=$(stat -c'%a' -- "$file")
        hash=$(sha1sum -- "$file" | cut -d' ' -f1)

        sed -i "/^$file\//d" .girt/index # remove file from index if it exists
        echo "$file/$mode/$hash" >> .girt/index # append to index
        gzip -c -- "$file" > ".girt/objects/blobs/$hash" # create blob
    fi
done
