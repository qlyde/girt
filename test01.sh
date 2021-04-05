#!/bin/dash
# girt-add test

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

test_failure() {
    testno=$1
    out=$2
    out_status=$3
    out_exp=$4
    test $out_status -eq 1 || failed "test $testno failed: exit status 1 expected, got $out_status"
    echo "$out" | grep -Fq "$out_exp" || failed "test $testno failed: incorrect output: expected '$out_exp', got '$out'"
}

TEST_DIR=".test01"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

# test 1: failure: no .girt directory
out=$(girt-add 2>&1)
out_status=$?
out_exp="girt repository directory .girt not found"
test_failure 1 "$out" "$out_status" "$out_exp"
echo "test 1 passed"

girt-init > /dev/null 2>&1

# test 2: failure: non-existent file
out=$(girt-add non_existent_file 2>&1)
out_status=$?
out_exp="can not open 'non_existent_file'"
test_failure 2 "$out" "$out_status" "$out_exp"
echo "test 2 passed"

# test 3: failure: non-regular file
mkdir some_directory
out=$(girt-add some_directory 2>&1)
out_status=$?
out_exp="'some_directory' is not a regular file"
test_failure 3 "$out" "$out_status" "$out_exp"
echo "test 3 passed"

# test 4: success
touch a
out=$(girt-add a 2>&1)
test -z "$out" || failed "test 4 failed: got unexpected output '$out'"
echo "test 4 passed"

# test 5: success: adding a removed file
rm a
out=$(girt-add a 2>&1)
test -z "$out" || failed "test 5 failed: got unexpected output '$out'"
echo "test 5 passed"

passed
