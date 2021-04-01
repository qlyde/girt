#!/bin/dash

if [ $# -ne 0 ]; then
    echo "usage: $0" 1>&2
    exit 1
elif [ -e .girt ]; then
    echo "$0: error: .girt already exists" 1>&2
    exit 1
fi

mkdir .girt &&
echo "Initialized empty girt repository in .girt"

# store current branch
echo "refs/heads/master" > .girt/HEAD

# store staged changes
touch .girt/index

# store objects: blobs (files), trees (snapshot of files), commits
mkdir .girt/objects
mkdir .girt/objects/blobs
mkdir .girt/objects/trees
mkdir .girt/objects/commits

# store branches as pointers to commits
mkdir .girt/refs
mkdir .girt/refs/heads
touch .girt/refs/heads/master # default branch
