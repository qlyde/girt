#!/bin/dash
# girt-status test

failed() { echo "$@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

# delete girt repo and all files
reset_girt() { rm -rf .girt * && girt-init > /dev/null 2>&1; }

TEST_DIR=".test06"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

# test 1: failure: no .girt directory
out=$(girt-status 2>&1)
out_status=$?
out_exp="girt repository directory .girt not found"
test $out_status -eq 1 || failed "$0: test 1 failed: exit status 1 expected, got $out_status"
echo "$out" | grep -Fq "$out_exp" || failed "$0: test 1 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 1 passed"

girt-init > /dev/null 2>&1

# test 2: success: untracked 1
touch untracked_1

out=$(girt-status 2>&1)
out_exp="untracked_1 - untracked"
test "$out" = "$out_exp" || failed "$0: test 2 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 2 passed"
reset_girt

# test 3: success: untracked 2
touch untracked_2
girt-add untracked_2 > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
girt-rm --cached untracked_2 > /dev/null 2>&1

out=$(girt-status 2>&1)
out_exp="untracked_2 - untracked"
test "$out" = "$out_exp" || failed "$0: test 3 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 3 passed"
reset_girt

# test 4: success: untracked 3
touch untracked_3
girt-add untracked_3 > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
girt-rm --cached untracked_3 > /dev/null 2>&1
echo hello > untracked_3

out=$(girt-status 2>&1)
out_exp="untracked_3 - untracked"
test "$out" = "$out_exp" || failed "$0: test 4 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 4 passed"
reset_girt

# test 5: success: same as repo
touch same_as_repo
girt-add same_as_repo > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1

out=$(girt-status 2>&1)
out_exp="same_as_repo - same as repo"
test "$out" = "$out_exp" || failed "$0: test 5 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 5 passed"
reset_girt

# test 6: success: file changed, changes staged for commit
touch changes_staged
girt-add changes_staged > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
echo hello > changes_staged
girt-add changes_staged > /dev/null 2>&1

out=$(girt-status 2>&1)
out_exp="changes_staged - file changed, changes staged for commit"
test "$out" = "$out_exp" || failed "$0: test 6 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 6 passed"
reset_girt

# test 7: success: file changed, changes not staged for commit
touch changes_not_staged
girt-add changes_not_staged > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
echo hello > changes_not_staged

out=$(girt-status 2>&1)
out_exp="changes_not_staged - file changed, changes not staged for commit"
test "$out" = "$out_exp" || failed "$0: test 7 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 7 passed"
reset_girt

# test 8: success: file changed, different changes staged for commit 1
echo hello > diff_changes_staged_1
girt-add diff_changes_staged_1 > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
echo world > diff_changes_staged_1
girt-add diff_changes_staged_1 > /dev/null 2>&1
echo hello > diff_changes_staged_1 # working same as repo

out=$(girt-status 2>&1)
out_exp="diff_changes_staged_1 - file changed, different changes staged for commit"
test "$out" = "$out_exp" || failed "$0: test 8 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 8 passed"
reset_girt

# test 9: success: file changed, different changes staged for commit 2
echo hello > diff_changes_staged_2
girt-add diff_changes_staged_2 > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
echo world > diff_changes_staged_2
girt-add diff_changes_staged_2 > /dev/null 2>&1
echo hello world > diff_changes_staged_2 # working diff to repo

out=$(girt-status 2>&1)
out_exp="diff_changes_staged_2 - file changed, different changes staged for commit"
test "$out" = "$out_exp" || failed "$0: test 9 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 9 passed"
reset_girt

# test 10: success: added to index
touch added_to_index
girt-add added_to_index > /dev/null 2>&1

out=$(girt-status 2>&1)
out_exp="added_to_index - added to index"
test "$out" = "$out_exp" || failed "$0: test 10 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 10 passed"
reset_girt

# test 11: success: added to index, file changed
touch added_to_index_file_changed
girt-add added_to_index_file_changed > /dev/null 2>&1
echo hello > added_to_index_file_changed

out=$(girt-status 2>&1)
out_exp="added_to_index_file_changed - added to index, file changed"
test "$out" = "$out_exp" || failed "$0: test 11 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 11 passed"
reset_girt

# test 12: success: added to index, file deleted
touch added_to_index_file_deleted
girt-add added_to_index_file_deleted > /dev/null 2>&1
rm added_to_index_file_deleted

out=$(girt-status 2>&1)
out_exp="added_to_index_file_deleted - added to index, file deleted"
test "$out" = "$out_exp" || failed "$0: test 12 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 12 passed"
reset_girt

# test 13: success: file deleted
touch file_deleted
girt-add file_deleted > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
rm file_deleted

out=$(girt-status 2>&1)
out_exp="file_deleted - file deleted"
test "$out" = "$out_exp" || failed "$0: test 13 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 13 passed"
reset_girt

# test 14: success: file deleted, different changes staged for commit
touch file_deleted_diff_changes_staged
girt-add file_deleted_diff_changes_staged > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
echo hello > file_deleted_diff_changes_staged
girt-add file_deleted_diff_changes_staged > /dev/null 2>&1
rm file_deleted_diff_changes_staged

out=$(girt-status 2>&1)
out_exp="file_deleted_diff_changes_staged - file deleted, different changes staged for commit"
test "$out" = "$out_exp" || failed "$0: test 14 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 14 passed"
reset_girt

# test 15: success: deleted
touch deleted
girt-add deleted > /dev/null 2>&1
girt-commit -m 0 > /dev/null 2>&1
girt-rm deleted > /dev/null 2>&1

out=$(girt-status 2>&1)
out_exp="deleted - deleted"
test "$out" = "$out_exp" || failed "$0: test 15 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 15 passed"

passed
