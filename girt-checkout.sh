#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ $# -ne 1 ]; then
    echo "usage: $0 <commit>:<filename>" 1>&2
    exit 1
fi
