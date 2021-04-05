#!/bin/dash
# girt-checkout test: failures only

failed() { echo "$0: $@" && exit 1; }
passed() { echo "all tests passed" && exit 0; }

# delete girt repo and all files
# and commit a file
reset_girt() {
    rm -rf .girt *
    girt-init > /dev/null 2>&1
    touch a
    girt-add a > /dev/null 2>&1
    girt-commit -m m > /dev/null 2>&1
}

test_failure() {
    testno=$1
    out=$2
    out_status=$3
    out_exp=$4
    test $out_status -eq 1 || failed "test $testno failed: exit status 1 expected, got $out_status"
    echo "$out" | grep -Fq "$out_exp" || failed "test $testno failed: incorrect output: expected '$out_exp', got '$out'"
}

TEST_DIR=".test08"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

# test 1: failure: no .girt directory
out=$(girt-checkout 2>&1)
out_status=$?
out_exp="girt repository directory .girt not found"
test_failure 1 "$out" "$out_status" "$out_exp"
echo "test 1 passed"

girt-init > /dev/null 2>&1

# test 2: failure: no commit
out=$(girt-checkout 2>&1)
out_status=$?
out_exp="this command can not be run until after the first commit"
test_failure 2 "$out" "$out_status" "$out_exp"
echo "test 2 passed"

touch a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1

# test 3: failure: unknown branch
out=$(girt-checkout unknown_branch 2>&1)
out_status=$?
out_exp="unknown branch 'unknown_branch'"
test_failure 3 "$out" "$out_status" "$out_exp"
echo "test 3 passed"

# test 4: success: checking out to current branch
out=$(girt-checkout master 2>&1)
out_exp="Already on 'master'"
test "$out" = "$out_exp" || failed "test 4 failed: incorrect output: expected '$out_exp', got '$out'"
echo "test 4 passed"

# test 5: failure: overwriting changes: unstaged (file not in repo)
girt-branch b1 > /dev/null 2>&1
touch b
girt-add b > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-checkout b1 > /dev/null 2>&1
touch b

out=$(girt-checkout master 2>&1)
out_status=$?
out_exp="Your changes to the following files would be overwritten by checkout:"
test_failure 5 "$out" "$out_status" "$out_exp"
echo "$out" | grep -Fqx "b" || failed "test 5 failed: incorrect output: wrong files listed"
echo "test 5 passed"
reset_girt

# test 6: failure: overwriting changes: unstaged 2 (file in repo)
girt-branch b1 > /dev/null 2>&1
echo hello > a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-checkout b1 > /dev/null 2>&1
echo hello > a

out=$(girt-checkout master 2>&1)
out_status=$?
out_exp="Your changes to the following files would be overwritten by checkout:"
test_failure 6 "$out" "$out_status" "$out_exp"
echo "$out" | grep -Fqx "a" || failed "test 6 failed: incorrect output: wrong files listed"
echo "test 6 passed"
reset_girt

# test 7: failure: overwriting changes: staged changes different to branch file (file in repo)
girt-branch b1 > /dev/null 2>&1
echo hello > a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-checkout b1 > /dev/null 2>&1
echo hello world > a
girt-add a > /dev/null 2>&1

out=$(girt-checkout master 2>&1)
out_status=$?
out_exp="Your changes to the following files would be overwritten by checkout:"
test_failure 7 "$out" "$out_status" "$out_exp"
echo "$out" | grep -Fqx "a" || failed "test 7 failed: incorrect output: wrong files listed"
echo "test 7 passed"
reset_girt

# test 8: failure: overwriting changes: staged changes different to both branch file and working file
girt-branch b1 > /dev/null 2>&1
echo hello > a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-checkout b1 > /dev/null 2>&1
echo hello world > a
girt-add a > /dev/null 2>&1
echo hello world! > a

out=$(girt-checkout master 2>&1)
out_status=$?
out_exp="Your changes to the following files would be overwritten by checkout:"
test_failure 8 "$out" "$out_status" "$out_exp"
echo "$out" | grep -Fqx "a" || failed "test 8 failed: incorrect output: wrong files listed"
echo "test 8 passed"
reset_girt

# test 9: failure: overwriting changes: staged changes different to branch file (file not in repo)
girt-branch b1 > /dev/null 2>&1
touch b
girt-add b > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-checkout b1 > /dev/null 2>&1
echo hello > b
girt-add b > /dev/null 2>&1

out=$(girt-checkout master 2>&1)
out_status=$?
out_exp="Your changes to the following files would be overwritten by checkout:"
test_failure 9 "$out" "$out_status" "$out_exp"
echo "$out" | grep -Fqx "b" || failed "test 9 failed: incorrect output: wrong files listed"
echo "test 9 passed"
reset_girt

passed
