#!/bin/dash

usage() { echo "usage: $0 [--force] [--cached] <filenames>" 1>&2; exit 1; }

if [ ! -d .girt ]; then
    echo "$0: error: girt repository directory .girt not found" 1>&2
    exit 1
fi

# | directory | index | repos |
# |     x     |       |       | 'file' is not in the girt repository
# |     x     |       |   x   | 'file' is not in the girt repository
# |     x     |       |   y   | 'file' is not in the girt repository
# |           |       |   x   | 'file' is not in the girt repository'
# |     x     |   x   |   y   | 'file' has staged changes in the index, (--cached works)
# |     x     |   x   |       | 'file' has staged changes in the index, (--cached works)
# |     x     |   y   |   y   | 'file' in the repository is different to the working file, (--cached works)
# |     x     |   y   |   x   | 'file' in index is different to both to the working file and the repository
# |     x     |   y   |   z   | 'file' in index is different to both to the working file and the repository
# |     x     |   y   |       | 'file' in index is different to both to the working file and the repository
# |     x     |   x   |   x   |
# |           |   x   |       |
# |           |   x   |   x   |
# |           |   x   |   y   |

# parse arguments
# assumes options come before filenames
while true; do
    arg="$1"
    case "$arg" in
        --force)
            flag_force=true
            shift
            ;;
        --cached)
            flag_cached=true
            shift
            ;;
        -*) usage;;
        *) break;;
    esac
done

# check each file doesn't incur errors
for file in "$@"; do
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
    head=$(cat .girt/HEAD)
    parent_commit=$(cat ".girt/$head")
    if [ -n "$parent_commit" ]; then
        parent_tree=$(cat ".girt/objects/commits/$parent_commit" | grep '^tree:' | sed 's/^tree://')
        repo_blob=$(cat .girt/objects/trees/$parent_tree | sed -n "/^$escaped_file$(printf '\t')/p" | cut -f3)
    fi

    # note index_blob cannot be null here
    if [ -z "$index_blob" ]; then
        # 'file' is not in the girt repository
        echo "$0: error: '$file' is not in the girt repository" 1>&2
        exit 1
    elif [ "$working_blob" = "$index_blob" -a "$index_blob" != "$repo_blob" ]; then
        # 'file' has staged changes in the index, (--cached works)
        if [ -n "$flag_force" -o -n "$flag_cached" ]; then continue; fi
        echo "$0: error: '$file' has staged changes in the index" 1>&2
        exit 1
    elif [ -n "$working_blob" -a "$working_blob" != "$index_blob" -a "$index_blob" = "$repo_blob" ]; then
        # 'file' in the repository is different to the working file, (--cached works)
        if [ -n "$flag_force" -o -n "$flag_cached" ]; then continue; fi
        echo "$0: error: '$file' in the repository is different to the working file" 1>&2
        exit 1
    elif [ -n "$working_blob" -a "$working_blob" != "$index_blob" -a "$index_blob" != "$repo_blob" ]; then
        # 'file' in index is different to both to the working file and the repository
        if [ -n "$flag_force" ]; then continue; fi
        echo "$0: error: '$file' in index is different to both to the working file and the repository" 1>&2
        exit 1
    fi
done

# girt-rm each file
for file in "$@"; do
    # remove file
    if [ -f "$file" -a -z "$flag_cached" ]; then
        rm "$file"
    fi

    # remove file from index
    escaped_file=$(echo "$file" | sed 's:[]\[^$.*/]:\\&:g')
    sed -i "/^$escaped_file$(printf '\t')/d" .girt/index
done
