#!/bin/dash
# girt-init test

failed() { echo "$@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

TEST_DIR=".test00"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR

# test 1: success
out=$(girt-init 2>&1)
out_exp="Initialized empty girt repository in .girt"
test "$out" = "$out_exp" || failed "$0: test 1 failed: incorrect output: expected '$out_exp', got '$out'"
test -d .girt || failed "$0: test 1 failed: .girt directory not found"
echo "test 1 passed"

# test 2: failure
out=$(girt-init 2>&1)
out_status=$?
out_exp=".girt already exists"
test $out_status -eq 1 || failed "$0: test 2 failed: exit status 1 expected, got $out_status"
echo "$out" | grep -Fq "$out_exp" || failed "$0: test 2 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 2 passed"

cd .. && rm -rf $TEST_DIR
passed
