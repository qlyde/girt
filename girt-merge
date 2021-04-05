#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ ! -e .girt/objects/commits/0 ]; then
    echo "$0: error: this command can not be run until after the first commit" 1>&2
    exit 1
elif [ $# -ne 3 -o "$(echo "$1" | cut -c1)" = "-" -o "$2" != "-m" -o "$(echo "$3" | cut -c1)" = "-" ]; then
    echo "usage: $0 <branch|commit> -m message" 1>&2
    exit 1
elif [ -z "$3" ]; then
    echo "$0: error: empty commit message" 1>&2
    exit 1
fi

# check if branch or commit is given (commits are numerical)
if echo "$1" | grep -q '[^0-9]'; then
    branch="$1"
else
    commit="$1"
fi

# check if branch/commit exists
if [ -n "$branch" -a ! -e ".girt/refs/heads/$branch" ]; then
    echo "$0: error: unknown branch '$branch'" 1>&2
    exit 1
elif [ -n "$commit" -a ! -e ".girt/objects/commits/$commit" ]; then
    echo "$0: error: unknown commit '$commit'" 1>&2
    exit 1
fi

# check if already up to date
head=$(cat .girt/HEAD)
curr_commit=$(cat ".girt/$head")
if [ -n "$branch" ]; then
    if [ "$curr_commit" = "$(cat ".girt/refs/heads/$branch")" ]; then
        echo "Already up to date"
        exit 0
    fi
else
    if [ "$curr_commit" = "$commit" ]; then
        echo "Already up to date"
        exit 0
    fi
fi
