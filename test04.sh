#!/bin/dash
# girt-show test

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

TEST_DIR=".test04"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

# test 1: failure: no .girt directory
out=$(girt-show 2>&1)
out_status=$?
out_exp="girt repository directory .girt not found"
test_failure 1 "$out" "$out_status" "$out_exp"
echo "test 1 passed"

girt-init > /dev/null 2>&1

# test 2: failure: unknown commit
out=$(girt-show 0:file 2>&1)
out_status=$?
out_exp="unknown commit '0'"
test_failure 2 "$out" "$out_status" "$out_exp"
echo "test 2 passed"

echo hello > a
girt-add a > /dev/null 2>&1
girt-commit -m 'This is commit 0' > /dev/null 2>&1

# test 3: failure: unknown file in commit
out=$(girt-show 0:file 2>&1)
out_status=$?
out_exp="'file' not found in commit 0"
test_failure 3 "$out" "$out_status" "$out_exp"
echo "test 3 passed"

# test 4: failure: unknown file in index
out=$(girt-show :file 2>&1)
out_status=$?
out_exp="'file' not found in index"
test_failure 4 "$out" "$out_status" "$out_exp"
echo "test 4 passed"

# test 5: success: commit
out=$(girt-show 0:a 2>&1)
out_exp="hello"
test "$out" = "$out_exp" || failed "test 5 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 5 passed"

# test 6: success: index
out=$(girt-show :a 2>&1)
out_exp="hello"
test "$out" = "$out_exp" || failed "test 6 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 6 passed"

# test 7: success: index different from commit
echo hello world > a
girt-add a > /dev/null 2>&1

out=$(girt-show :a 2>&1)
out_exp="hello world"
test "$out" = "$out_exp" || failed "test 7 failed: incorrect output: expected '$out_exp', got '$out'"

out=$(girt-show 0:a 2>&1)
out_exp="hello"
test "$out" = "$out_exp" || failed "test 7 failed: incorrect output: expected '$out_exp', got '$out'"

echo "test 7 passed"

# test 8: success: two commits
girt-commit -m 'This is commit 1' > /dev/null 2>&1

out=$(girt-show 0:a 2>&1)
out_exp="hello"
test "$out" = "$out_exp" || failed "test 8 failed: incorrect output: expected '$out_exp', got '$out'"

out=$(girt-show 1:a 2>&1)
out_exp="hello world"
test "$out" = "$out_exp" || failed "test 8 failed: incorrect output: expected '$out_exp', got '$out'"

echo "test 8 passed"

passed
