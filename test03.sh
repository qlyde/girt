#!/bin/dash
# girt-log test
# test 5 assumes girt-branch and girt-checkout work

failed() { echo "$@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

TEST_DIR=".test03"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

# test 1: failure: no .girt directory
out=$(girt-log 2>&1)
out_status=$?
out_exp="girt repository directory .girt not found"
test $out_status -eq 1 || failed "$0: test 1 failed: exit status 1 expected, got $out_status"
echo "$out" | grep -Fq "$out_exp" || failed "$0: test 1 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 1 passed"

girt-init > /dev/null 2>&1

# test 2: success: no commits
out=$(girt-log 2>&1)
test -z "$out" || failed "$0: test 2 failed: got unexpected output '$out'"
echo "test 2 passed"

# test 3: success: one commit
touch a
girt-add a > /dev/null 2>&1
girt-commit -m 'This is commit 0' > /dev/null 2>&1
out=$(girt-log 2>&1)
out_exp="0 This is commit 0"
test "$out" = "$out_exp" || failed "$0: test 3 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 3 passed"

# test 4: success: two commits
touch b
girt-add b > /dev/null 2>&1
girt-commit -m 'This is commit 1' > /dev/null 2>&1
out=$(girt-log 2>&1)
out_exp="1 This is commit 1
0 This is commit 0"
test "$out" = "$out_exp" || failed "$0: test 4 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 4 passed"

# test 5: success: two branches
girt-branch b1 > /dev/null 2>&1
touch c
girt-add c > /dev/null 2>&1
girt-commit -m 'This is commit 2' > /dev/null 2>&1

out=$(girt-log 2>&1)
out_exp="2 This is commit 2
1 This is commit 1
0 This is commit 0"
test "$out" = "$out_exp" || failed "$0: test 5 failed: incorrect output: expected '$out_exp', got '$out'"

girt-checkout b1 > /dev/null 2>&1 # commit 2 doesn't exist in branch b1
out=$(girt-log 2>&1)
out_exp="1 This is commit 1
0 This is commit 0"
test "$out" = "$out_exp" || failed "$0: test 5 failed: incorrect output: expected '$out_exp', got '$out'"

echo "test 5 passed"

passed
