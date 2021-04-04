#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
elif [ ! -e .girt/objects/commits/0 ]; then
    echo "$0: error: this command can not be run until after the first commit" 1>&2
    exit 1
elif [ $# -ne 1 -o "$(echo "$1" | cut -c1)" = "-" ]; then
    echo "usage: $0 <branch>" 1>&2
    exit 1
elif [ ! -e ".girt/refs/heads/$1" ]; then
    echo "$0: error: unknown branch '$1'" 1>&2
    exit 1
fi

branch="$1"
branch_commit=$(cat ".girt/refs/heads/$branch") # guaranteed to not be null as 1 commit is needed to branch
branch_tree=$(cat ".girt/objects/commits/$branch_commit" | grep '^tree:' | sed 's/^tree://')

head=$(cat .girt/HEAD)
curr_commit=$(cat ".girt/$head") # guaranteed to not be null as 1 commit is needed to branch
curr_tree=$(cat ".girt/objects/commits/$curr_commit" | grep '^tree:' | sed 's/^tree://')

# check if checkout will overwrite changes
error=
for file in *; do # if file was removed, it does not count as 'losing work'
    [ -f "$file" ] || continue

    escaped_file=$(echo "$file" | sed 's:[]\[^$.*/]:\\&:g')

    index_blob=$(cat .girt/index | sed -n "/^$escaped_file$(printf '\t')/p" | cut -f3) # can be null if untracked
    branch_blob=$(cat ".girt/objects/trees/$branch_tree" | sed -n "/^$escaped_file$(printf '\t')/p" | cut -f3) # can be null

    if [ "$index_blob" != "$branch_blob" ]; then
        # file in current branch is different to target branch so it requires modification/removal
        # check that working file is the same as the index file (ie. changes are staged)
        working_blob=$(sha1sum -- "$file" | cut -d' ' -f1)
        if [ "$working_blob" != "$index_blob" ]; then
            error=true
            error_files=$(printf "%s\n%s" "$error_files" "$file")
            # will be sorted since index is sorted
        fi
    fi
done

if [ -n "$error" ]; then
    printf "$0: error: Your changes to the following files would be overwritten by checkout:%s\n" "$error_files" 1>&2
    exit 1
fi

# change index and working directory
while IFS= read -r line; do
    file=$(echo "$line" | cut -f1)
    escaped_file=$(echo "$file" | sed 's:[]\[^$.*/]:\\&:g')

    index_blob=$(echo "$line" | cut -f3)
    branch_blob=$(cat ".girt/objects/trees/$branch_tree" | sed -n "/^$escaped_file$(printf '\t')/p" | cut -f3)
    repo_blob=$(cat .girt/objects/trees/$curr_tree | sed -n "/^$escaped_file$(printf '\t')/p" | cut -f3)

    if [ "$index_blob" = "$repo_blob" -a "$index_blob" != "$branch_blob" -a -n "$branch_blob" ]; then
        # only modify file if change is commited, ie. index_blob = repo_blob, otherwise keep untracked/staged changes
        # working_blob is guaranteed to be same as index_blob otherwise an error would have been raised
        # since index_blob is committed, change index entry to be branch entry
        escaped_line=$(echo "$line" | sed 's:[]\[^$.*/]:\\&:g')
        sed -i "/^$escaped_line$/s/$index_blob/$branch_blob/" .girt/index # no need to escape blobs, they are hexadecimal
        cat ".girt/objects/blobs/$branch_blob" | zcat > "$file"
    elif [ -z "$branch_blob" ]; then
        if [ "$index_blob" != "$repo_blob" ]; then
            # if index_blob is not committed and branch_blob is null, keep in new index
            continue
        else
            # if index_blob is in repo and branch_blob is null, delete index entry
            escaped_line=$(echo "$line" | sed 's:[]\[^$.*/]:\\&:g')
            sed -i "s/^$escaped_line$//" .girt/index
            [ -f "$file" ] && rm -- "$file" # delete file
        fi
    fi
done < .girt/index

# copy any new files in the branch tree
while IFS= read -r line; do
    file=$(echo "$line" | cut -f1)
    blob=$(echo "$line" | cut -f3)
    if ! cat .girt/index | cut -f1 | grep -Fqx -- "$file"; then
        # file in branch index not present in current index so add it
        printf "%s\n" "$line" >> .girt/index
        cat ".girt/objects/blobs/$blob" | zcat > "$file"
    fi
done < ".girt/objects/trees/$branch_tree"

# sort index and delete blank lines
sed -i '/^$/d' .girt/index
sort -o .girt/index .girt/index

# change HEAD pointer
echo "refs/heads/$branch" > .girt/HEAD
echo "Switched to branch '$branch'"
