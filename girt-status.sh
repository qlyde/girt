#!/bin/dash

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
fi

# | directory | index | repos |
# |     x     |       |       | untracked
# |     x     |       |   x   | untracked
# |     x     |       |   y   | untracked
# |     x     |   x   |   x   | same as repo
# |     x     |   x   |   y   | file changed, changes staged for commit
# |     x     |   y   |   y   | file changed, changes not staged for commit
# |     x     |   y   |   x   | file changed, different changes staged for commit
# |     x     |   y   |   z   | file changed, different changes staged for commit
# |     x     |   x   |       | added to index
# |     x     |   y   |       | added to index, file changed
# |           |   x   |       | added to index, file deleted
# |           |   x   |   x   | file deleted
# |           |   x   |   y   | file deleted, different changes staged for commit
# |           |       |   x   | deleted

TMP=$(mktemp /tmp/girt_status_out.XXXXXXXXXX)
trap 'rm -f "$TMP"' INT TERM EXIT

process_file() {
    local file="$1"
    working_blob=
    index_blob=
    repo_blob=

    # get working blob
    if [ -f "$file" ]; then
        working_blob=$(sha1sum -- "$file" | cut -d' ' -f1)
    fi

    # get index blob
    escaped_file=$(echo "$file" | sed 's:[]\[^$.*/]:\\&:g')
    index_blob=$(cat .girt/index | sed -n "/^$escaped_file$(printf '\t')/p" | cut -f3)

    # get repo blob
    local head=$(cat .girt/HEAD)
    local parent_commit=$(cat ".girt/$head")
    if [ -n "$parent_commit" ]; then
        local parent_tree=$(cat ".girt/objects/commits/$parent_commit" | grep '^tree:' | sed 's/^tree://')
        repo_blob=$(cat .girt/objects/trees/$parent_tree | sed -n "/^$escaped_file$(printf '\t')/p" | cut -f3)
    fi

    # find status of file
    # 2 blobs are null
    if [ -n "$working_blob" -a -z "$index_blob" ]; then
        printf "%s - untracked\n" "$file"
    elif [ -z "$working_blob" -a -z "$index_blob" ]; then
        printf "%s - deleted\n" "$file"
    elif [ -z "$working_blob" -a -z "$repo_blob" ]; then
        printf "%s - added to index, file deleted\n" "$file"
    # 1 blob is null
    elif [ "$working_blob" = "$index_blob" -a -z "$repo_blob" ]; then
        printf "%s - added to index\n" "$file"
    elif [ "$working_blob" != "$index_blob" -a -z "$repo_blob" ]; then
        printf "%s - added to index, file changed\n" "$file"
    elif [ -z "$working_blob" -a "$index_blob" = "$repo_blob" ]; then
        printf "%s - file deleted\n" "$file"
    elif [ -z "$working_blob" -a "$index_blob" != "$repo_blob" ]; then
        printf "%s - file deleted, different changes staged for commit\n" "$file"
    # 0 blobs are null
    elif [ "$working_blob" = "$index_blob" -a "$index_blob" = "$repo_blob" ]; then
        printf "%s - same as repo\n" "$file"
    elif [ "$working_blob" = "$index_blob" -a "$index_blob" != "$repo_blob" ]; then
        printf "%s - file changed, changes staged for commit\n" "$file"
    elif [ "$working_blob" != "$index_blob" -a "$index_blob" = "$repo_blob" ]; then
        printf "%s - file changed, changes not staged for commit\n" "$file"
    elif [ "$working_blob" != "$index_blob" -a "$index_blob" != "$repo_blob" ]; then
        printf "%s - file changed, different changes staged for commit\n" "$file"
    fi
}

# process files in working directory
for file in *; do
    [ -f "$file" ] || continue # in case glob doesn't match
    process_file "$file"
done >> "$TMP"

# process files in index
while IFS= read -r line; do
    file=$(echo "$line" | cut -f1)
    if ! grep -Fq -- "$file -" "$TMP"; then # hasn't already been processed
        process_file "$file"
    fi
done < .girt/index >> "$TMP"

# process files in repo
head=$(cat .girt/HEAD)
parent_commit=$(cat ".girt/$head")
if [ -n "$parent_commit" ]; then
    parent_tree=$(cat ".girt/objects/commits/$parent_commit" | grep '^tree:' | sed 's/^tree://')
    while IFS= read -r line; do
        file=$(echo "$line" | cut -f1)
        if ! grep -Fq -- "$file -" "$TMP"; then # hasn't already been processed
            process_file "$file"
        fi
    done < ".girt/objects/trees/$parent_tree" >> "$TMP"
fi

# print status
cat "$TMP" | sort
