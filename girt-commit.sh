#!/bin/dash

usage() { echo "usage: $0 [-a] -m commit-message" 1>&2; exit 1; }

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
fi

while [ $# -gt 0 ]; do
    arg=$1
    case "$arg" in
        -a)
            flag_a=true
            shift
            ;;
        -m)
            flag_m=true
            message="$2"
            [ -z "$message" ] && usage # option argument not given
            [ "$(echo "$message" | cut -c1)" = "-" ] && usage # option argument invalid
            shift 2
            ;;
        *) usage;;
    esac
done
[ -z "$flag_m" ] && usage # -m is compulsory

# check if there is anything to commit
head=$(cat .girt/HEAD)
parent_commit=$(cat ".girt/$head")
if [ -n "$parent_commit" ]; then
    parent_tree=$(cat ".girt/objects/commits/$parent_commit" | grep '^tree:' | sed 's/^tree://')
    if diff .girt/index ".girt/objects/trees/$parent_tree" > /dev/null 2>&1; then
        echo "nothing to commit"
        exit 0
    fi
fi

# create tree
tree=$(cat .girt/index)
tree_hash=$(sha1sum .girt/index | cut -d' ' -f1)
cp .girt/index ".girt/objects/trees/$tree_hash"

# create commit
commit="tree:$tree_hash\nparent:$parent_commit\nmessage:$message"
commit_num=0
while [ -e ".girt/objects/commits/$commit_num" ]; do commit_num=$((commit_num+1)); done
echo "$commit" > ".girt/objects/commits/$commit_num"
echo "Committed as commit $commit_num"

# update branch pointer
echo "$commit_num" > ".girt/$head"
