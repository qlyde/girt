#!/bin/dash

usage() { echo "$0 [-d] <branch>" 1>&2; exit 1; }

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ ! -e .girt/objects/commits/0 ]; then
    echo "$0: error: this command can not be run until after the first commit" 1>&2
    exit 1
elif [ $# -gt 2 ]; then
    usage
fi

# parse arguments
if [ $# -eq 0 ]; then
    # list branches
    ls -1 .girt/refs/heads | sort
elif [ $# -eq 1 ]; then
    [ "$(echo "$1" | cut -c1)" = "-" ] && usage # argument invalid

    # check if branch already exists
    branch="$1"
    if [ -e ".girt/refs/heads/$branch" ]; then
        echo "$0: error: branch '$branch' already exists" 1>&2
        exit 1
    fi

    # create branch, branch points to current commit
    head=$(cat .girt/HEAD)
    curr_commit=$(cat ".girt/$head")
    echo "$curr_commit" > ".girt/refs/heads/$branch"
else # $# = 2
    [ "$1" != "-d" ] && usage # option invalid
    [ "$(echo "$2" | cut -c1)" = "-" ] && usage # option argument invalid

    # check if branch can be deleted
    branch="$2"
    curr_branch=$(basename $(cat .girt/HEAD))
    if [ "$branch" = "master" -o "$branch" = "$curr_branch" ]; then # can't delete master or current branch
        echo "$0: error: can not delete branch '$branch'" 1>&2
        exit 1
    elif [ ! -e ".girt/refs/heads/$branch" ]; then
        echo "$0: error: branch '$branch' doesn't exist" 1>&2
        exit 1
    fi

    # check if branch has unmerged changes
    # ie. changes in target branch are not merged into the current branch
    # eg. current branch 3 -> 2 -> 1 -> 0
    # eg. target branch 4 -> 3 -> 2 -> 1 -> 0 (unmerged) vs 2 -> 1 -> 0 (merged)
    curr_commit=$(cat ".girt/refs/heads/$curr_branch")
    target_commit=$(cat ".girt/refs/heads/$branch")

    # check if target_commit appears in current branch commit chain
    merged=
    while [ -n "$curr_commit" ]; do
        [ "$curr_commit" = "$target_commit" ] && merged=true
        curr_commit=$(cat ".girt/objects/commits/$curr_commit" | grep '^parent:' | sed 's/^parent://')
    done
    if [ -z "$merged" ]; then
        echo "$0: error: branch '$branch' has unmerged changes" 1>&2
        exit 1
    fi

    # delete branch
    rm ".girt/refs/heads/$branch"
    echo "Deleted branch '$branch'"
fi
