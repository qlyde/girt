#!/bin/dash
# girt-commit test

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

TEST_DIR=".test02"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

# test 1: failure: no .girt directory
out=$(girt-commit 2>&1)
out_status=$?
out_exp="girt repository directory .girt not found"
test_failure 1 "$out" "$out_status" "$out_exp"
echo "test 1 passed"

girt-init > /dev/null 2>&1

# test 2: failure: no -m flag
out=$(girt-commit -a 2>&1)
out_status=$?
out_exp="usage: " # prog name can vary as prog uses $0
test_failure 2 "$out" "$out_status" "$out_exp"
echo "test 2 passed"

# test 3: success: nothing to commit (empty index)
out=$(girt-commit -m m 2>&1)
out_exp="nothing to commit"
test "$out" = "$out_exp" || failed "$0: test 3 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 3 passed"

# test 4: success: create commit 0
touch a
girt-add a > /dev/null 2>&1
out=$(girt-commit -m m 2>&1)
out_exp="Committed as commit 0"
test "$out" = "$out_exp" || failed "$0: test 4 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 4 passed"

# test 5: success: nothing to commit (non-empty index)
girt-add a > /dev/null 2>&1
out=$(girt-commit -m m 2>&1)
out_exp="nothing to commit"
test "$out" = "$out_exp" || failed "$0: test 5 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 5 passed"

# test 6: success: -a flag
echo new > a
out=$(girt-commit -a -m m 2>&1)
out_exp="Committed as commit 1" # incorrect implementation would result in "nothing to commit" as this change was not staged
test "$out" = "$out_exp" || failed "$0: test 6 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 6 passed"

passed
