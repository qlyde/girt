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
