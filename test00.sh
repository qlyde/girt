#!/bin/dash
# girt-init test

failed() { echo "$@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

[ -d .girt ] && rm -rf .girt

# test success
out=$(girt-init)
out_exp="Initialized empty girt repository in .girt"
test "$out" = "$out_exp" || failed "$0: failed: incorrect output: expected '$out_exp', got '$out'"
test -d .girt || failed "$0: failed: .girt directory doesn't exist"

# test failure
out=$(girt-init 2>&1)
out_status=$?
out_exp=".girt already exists"
test $out_status -eq 1 || failed "$0: failed: exit status 1 expected, got $out_status"
echo "$out" | grep -Fq "$out_exp" || failed "$0: failed: incorrect output: expected '$out_exp', got '$out'"

rm -rf .girt

passed
