#!/bin/dash
# girt-checkout test: successes only

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

TEST_DIR=".test09"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

girt-init > /dev/null 2>&1
reset_girt

# test 1: success: file in one branch, not in the other
girt-branch b1 > /dev/null 2>&1
touch b
girt-add b > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1

out=$(girt-checkout b1 2>&1)
out_exp="Switched to branch 'b1'"
test "$out" = "$out_exp" || failed "test 1 failed: incorrect output: expected '$out_exp', got '$out'"
test ! -e b || failed "test 1 failed: file 'b' should not be in branch b1"

out=$(girt-checkout master 2>&1)
out_exp="Switched to branch 'master'"
test "$out" = "$out_exp" || failed "test 1 failed: incorrect output: expected '$out_exp', got '$out'"
test -e b || failed "test 1 failed: file 'b' should be in branch master"

echo "test 1 passed"
reset_girt

# test 2: success: different file contents
echo hello > a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-branch b1 > /dev/null 2>&1
echo world > a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1

girt-checkout b1 > /dev/null 2>&1
test "$(cat a)" = "hello" || failed "test 2 failed: file 'a' has incorrect contents in branch b1"

girt-checkout master > /dev/null 2>&1
test "$(cat a)" = "world" || failed "test 2 failed: file 'a' has incorrect contents in branch master"

echo "test 2 passed"
reset_girt

# test 3: success: keeping untracked files across branches
echo hello > untracked
girt-branch b1 > /dev/null 2>&1

girt-checkout b1 > /dev/null 2>&1
test -e untracked || failed "test 3 failed: file 'untracked' should be in branch b1"
test "$(cat untracked)" = "hello" || failed "test 3 failed: file 'untracked' has incorrect contents in branch b1"

echo world > untracked

girt-checkout master > /dev/null 2>&1
test -e untracked || failed "test 3 failed: file 'untracked' should be in branch master"
test "$(cat untracked)" = "world" || failed "test 3 failed: file 'untracked' has incorrect contents in branch master"

echo "test 3 passed"
reset_girt

# test 4: success: removing a file, changing branches, file reappearing after commit
girt-branch b1 > /dev/null 2>&1
girt-checkout b1 > /dev/null 2>&1
rm a

girt-checkout master > /dev/null 2>&1
test ! -e a || failed "test 4 failed: file 'a' should not be in branch master"

girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1

girt-checkout b1 > /dev/null 2>&1
test -e a || failed "test 4 failed: file 'a' should be in branch b1"

echo "test 4 passed"
reset_girt

# test 5: success: checking out with staged changes, committing, checking out and changes disappear
echo hello > a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-branch b1 > /dev/null 2>&1
echo changes > a
girt-add a > /dev/null 2>&1

girt-checkout b1 > /dev/null 2>&1
test "$(cat a)" = "changes" || failed "test 5 failed: file 'a' has incorrect contents in branch b1"

girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1

girt-checkout master > /dev/null 2>&1
test "$(cat a)" = "hello" || failed "test 5 failed: file 'a' has incorrect contents in branch master"

echo "test 5 passed"
reset_girt

# weird case
# test 6: success: index file different to working file and repo file, but same as branch file
girt-branch b1 > /dev/null 2>&1
echo hello > a
girt-add a > /dev/null 2>&1
girt-commit -m m > /dev/null 2>&1
girt-checkout b1 > /dev/null 2>&1
echo hello > a
girt-add a > /dev/null 2>&1
echo world > a

girt-checkout master > /dev/null 2>&1
test "$(cat a)" = "world" || failed "test 6 failed: file 'a' has incorrect contents in branch master"
test "$(girt-show :a)" = "hello" || failed "test 6 failed: file 'a' has incorrect contents in index"

girt-commit -a -m m > /dev/null 2>&1

girt-checkout b1 > /dev/null 2>&1
test "$(cat a)" = "" || failed "test 6 failed: file 'a' has incorrect contents in branch b1"

echo "test 6 passed"
reset_girt

# test 7: success: index file different to working file and repo file, but repo file same as branch file
girt-branch b1 > /dev/null 2>&1
echo hello > a
girt-add a > /dev/null 2>&1
echo world > a

girt-checkout b1 > /dev/null 2>&1
test "$(cat a)" = "world" || failed "test 7 failed: file 'a' has incorrect contents in branch b1"
test "$(girt-show :a)" = "hello" || failed "test 7 failed: file 'a' has incorrect contents in index"

girt-commit -m m > /dev/null 2>&1

out=$(girt-checkout master 2>&1)
out_status=$?
out_exp="Your changes to the following files would be overwritten by checkout:"
test $out_status -eq 1 || failed "test 7 failed: exit status 1 expected, got $out_status"
echo "$out" | grep -Fq "$out_exp" || failed "test 7 failed: incorrect output: expected '$out_exp', got '$out'"
echo "$out" | grep -Fqx "a" || failed "test 7 failed: incorrect output: wrong files listed"

echo "test 7 passed"
reset_girt

passed
