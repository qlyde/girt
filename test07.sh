#!/bin/dash
# girt-branch test
# test 7 assumes girt-checkout works

failed() { echo "$@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

test_failure() {
    testno=$1
    out=$2
    out_status=$3
    out_exp=$4
    test $out_status -eq 1 || failed "$0: test $testno failed: exit status 1 expected, got $out_status"
    echo "$out" | grep -Fq "$out_exp" || failed "$0: test $testno failed: incorrect output: expected '$out_exp', got '$out'"
}

TEST_DIR=".test07"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

# test 1: failure: no .girt directory
out=$(girt-branch 2>&1)
out_status=$?
out_exp="girt repository directory .girt not found"
test_failure 1 "$out" "$out_status" "$out_exp"
echo "test 1 passed"

girt-init > /dev/null 2>&1

# test 2: failure: no commit
out=$(girt-branch 2>&1)
out_status=$?
out_exp="this command can not be run until after the first commit"
test_failure 2 "$out" "$out_status" "$out_exp"
echo "test 2 passed"

touch a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1

# test 3: success: create and list branches
girt-branch a > /dev/null 2>&1
girt-branch abc > /dev/null 2>&1
girt-branch b > /dev/null 2>&1
girt-branch bcd > /dev/null 2>&1
out=$(girt-branch 2>&1)
out_exp="a
abc
b
bcd
master"
test "$out" = "$out_exp" || failed "$0: test 3 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 3 passed"

# test 4: failure: branch already exists
out=$(girt-branch a 2>&1)
out_status=$?
out_exp="branch 'a' already exists"
test_failure 4 "$out" "$out_status" "$out_exp"
echo "test 4 passed"

# test 5: failure: trying to delete master
out=$(girt-branch -d master 2>&1)
out_status=$?
out_exp="can not delete branch 'master'"
test_failure 5 "$out" "$out_status" "$out_exp"
echo "test 5 passed"

# test 6: failure: trying to delete non-existent branch
out=$(girt-branch -d non_existent_branch 2>&1)
out_status=$?
out_exp="branch 'non_existent_branch' doesn't exist"
test_failure 6 "$out" "$out_status" "$out_exp"
echo "test 6 passed"

# test 7: failure: trying to delete a branch with unmerged changes
girt-checkout a > /dev/null 2>&1
touch file
girt-add file > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-checkout master > /dev/null 2>&1
out=$(girt-branch -d a 2>&1)
out_status=$?
out_exp="branch 'a' has unmerged changes"
test_failure 7 "$out" "$out_status" "$out_exp"
echo "test 7 passed"

# test 8: success: deleting a branch
out=$(girt-branch -d b 2>&1)
out_exp="Deleted branch 'b'"
test "$out" = "$out_exp" || failed "$0: test 8 failed: incorrect output: expected '$out_exp', got '$out'"

out=$(girt-checkout b 2>&1)
out_status=$?
out_exp="unknown branch 'b'"
test_failure 8 "$out" "$out_status" "$out_exp"

echo "test 8 passed"

passed
