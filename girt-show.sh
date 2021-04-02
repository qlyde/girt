#!/bin/dash

usage() { echo "usage: $0 <commit>:<filename>" 1>&2; exit 1; }

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ $# -ne 1 ]; then
    usage
fi

# parse argument
if echo "$1" | grep -q ':'; then
    commit=$(echo "$1" | cut -d':' -f1)
    filename=$(echo "$1" | cut -d':' -f2-)
    if [ -z "$filename" ]; then
        echo "$0: error: invalid filename '$filename'" 1>&2
        exit 1
    fi
else
    usage
fi

# check if commit exists if given
if [ -n "$commit" -a ! -e ".girt/objects/commits/$commit" ]; then
    echo "$0: error: unknown commit '$commit'" 1>&2
    exit 1
fi

if [ -n "$commit" ]; then
    # loop over files in the given commit
    tree=$(cat ".girt/objects/commits/$commit" | grep '^tree:' | sed 's/^tree://')
    while IFS= read -r line; do
        file=$(echo "$line" | cut -f1)
        if [ "$file" = "$filename" ]; then
            blob=$(echo "$line" | cut -f3)
        fi
    done < ".girt/objects/trees/$tree"

    # check if file exists in the given commit
    if [ -z "$blob" ]; then
        echo "$0: error: '$filename' not found in commit $commit" 1>&2
        exit 1
    fi
else
    # loop over files in the index
    while IFS= read -r line; do
        file=$(echo "$line" | cut -f1)
        if [ "$file" = "$filename" ]; then
            blob=$(echo "$line" | cut -f3)
        fi
    done < ".girt/index"

    # check if file exists in the index
    if [ -z "$blob" ]; then
        echo "$0: error: '$filename' not found in index" 1>&2
        exit 1
    fi
fi

# print blob contents
cat ".girt/objects/blobs/$blob" | zcat
