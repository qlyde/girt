#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
fi

# check if there is anything to commit
if [ ! -s .girt/index ]; then
    echo "nothing to commit"
    exit 0
fi

# create tree
head=$(cat .girt/HEAD)
parent_commit=$(cat ".girt/$head")
tree=$(cat .girt/index)
if [ -n "$parent_commit" ]; then
    # add unchanged files to tree from parent commit, if parent exists
    parent_tree=$(cat ".girt/objects/commits/$parent_commit" | grep '^tree:' | cut -d':' -f2)
    while IFS= read -r line; do
        file=$(echo "$line" | cut -d'/' -f1)
        if ! echo "$tree" | grep -q "^$file/"; then
            tree="$tree\n$line"
        fi
    done < ".girt/objects/trees/$parent_tree"
fi

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
