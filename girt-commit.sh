#!/bin/dash

# usage() { echo "usage: $0 [-a] -m commit-message" 1>&2; exit 1; }

# while [ $# -gt 0 ]; do
#     arg=$1
#     case "$arg" in
#         -a)
#             shift
#             ;;
#         -m)
#             shift 2
#             ;;
#         *) usage;;
#     esac
# done

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
fi

# check if there is anything to commit
if [ ! -s .girt/index -a ! -s .girt/rmindex ]; then
    echo "nothing to commit"
    exit 0
fi

# create tree
head=$(cat .girt/HEAD)
parent_commit=$(cat ".girt/$head")
tree=$(cat .girt/index)
if [ -n "$parent_commit" ]; then
    # add unchanged files to tree from parent commit, if parent exists
    parent_tree=$(cat ".girt/objects/commits/$parent_commit" | grep '^tree:' | sed 's/^tree://')
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d'/' -f1)
        if ! echo "$tree" | grep -q "^$file/"; then
            tree="$tree\n$line"
        fi
    done < ".girt/objects/trees/$parent_tree"
fi

while IFS= read -r file; do
    tree=$(echo -n "$tree" | sed "/^$file\//d")
done < ".girt/rmindex"
tree_hash=$(echo "$tree" | sha1sum | cut -d' ' -f1)
echo "$tree" > ".girt/objects/trees/$tree_hash"

# create commit
commit="tree:$tree_hash\nparent:$parent_commit\nmessage:$message"

commit_num=0
while [ -e ".girt/objects/commits/$commit_num" ]; do commit_num=$((commit_num+1)); done
echo "$commit" > ".girt/objects/commits/$commit_num"
echo "Committed as commit $commit_num"

# update branch pointer
echo "$commit_num" > ".girt/$head"

# reset index
echo -n > .girt/index
echo -n > .girt/rmindex
