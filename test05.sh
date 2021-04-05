#!/bin/dash
# girt-rm test
# tests 8,9,10 assume girt-show works

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

TEST_DIR=".test05"

[ -e $TEST_DIR ] && rm -rf $TEST_DIR
PATH=..:$PATH
mkdir $TEST_DIR && cd $TEST_DIR
trap 'cd .. && rm -rf "$TEST_DIR"' INT TERM EXIT

# test 1: failure: no .girt directory
out=$(girt-rm 2>&1)
out_status=$?
out_exp="girt repository directory .girt not found"
test_failure 1 "$out" "$out_status" "$out_exp"
echo "test 1 passed"

girt-init > /dev/null 2>&1

# test 2: failure: file not in repo
out=$(girt-rm file 2>&1)
out_status=$?
out_exp="'file' is not in the girt repository"
test_failure 2 "$out" "$out_status" "$out_exp"
echo "test 2 passed"

# test 3: failure: staged changes without --cached
echo hello > a
girt-add a > /dev/null 2>&1
girt-commit -m 'This is commit 0' > /dev/null 2>&1

echo hello world > a
girt-add a > /dev/null 2>&1

out=$(girt-rm a 2>&1)
out_status=$?
out_exp="'a' has staged changes in the index"
test_failure 3 "$out" "$out_status" "$out_exp"
echo "test 3 passed"

# test 4: failure: unstaged changes without --cached
echo hello > b
girt-add b > /dev/null 2>&1
girt-commit -m 'This is commit 1' > /dev/null 2>&1

echo hello world > b

out=$(girt-rm b 2>&1)
out_status=$?
out_exp="'b' in the repository is different to the working file"
test_failure 4 "$out" "$out_status" "$out_exp"
echo "test 4 passed"

# test 5: failure: working file and staged file both different to repo (with and without --cached)
echo hello > c
girt-add c > /dev/null 2>&1
girt-commit -m 'This is commit 2' > /dev/null 2>&1

echo hello world > c
girt-add c > /dev/null 2>&1

echo hello world! > c

out=$(girt-rm c 2>&1)
out_status=$?
out_exp="'c' in index is different to both to the working file and the repository"
test_failure 5 "$out" "$out_status" "$out_exp"

out=$(girt-rm --cached c 2>&1)
out_status=$?
out_exp="'c' in index is different to both to the working file and the repository"
test_failure 5 "$out" "$out_status" "$out_exp"

echo "test 5 passed"

# test 6: success
echo hello > d
girt-add d > /dev/null 2>&1
girt-commit -m 'This is commit 3' > /dev/null 2>&1

out=$(girt-rm d 2>&1)
test -z "$out" || failed "test 6 failed: got unexpected output '$out'"
test ! -e d || failed "test 6 failed: file 'd' was not deleted"
echo "test 6 passed"

# test 7: success: --cached
echo hello > e
girt-add e > /dev/null 2>&1
girt-commit -m 'This is commit 4' > /dev/null 2>&1

out=$(girt-rm --cached e 2>&1)
test -z "$out" || failed "test 7 failed: got unexpected output '$out'"
test -e e || failed "test 7 failed: file 'e' was deleted with --cached flag"
echo "test 7 passed"

# test 8: success: staged changes with --cached
echo hello > f
girt-add f > /dev/null 2>&1
girt-commit -m 'This is commit 5' > /dev/null 2>&1

echo hello world > f
girt-add f > /dev/null 2>&1

out=$(girt-rm --cached f 2>&1)
test -z "$out" || failed "test 8 failed: got unexpected output '$out'"
test -e f || failed "test 8 failed: file 'f' was deleted with --cached flag"
test "$(cat f)" = "hello world" || failed "test 8 failed: file 'f' has incorrect contents"

out=$(girt-show :f 2>&1)
out_status=$?
out_exp="'f' not found in index"
test_failure 8 "$out" "$out_status" "$out_exp"

echo "test 8 passed"

# test 9: success: unstaged changes with --cached
echo hello > g
girt-add g > /dev/null 2>&1
girt-commit -m 'This is commit 6' > /dev/null 2>&1

echo hello world > g

out=$(girt-rm --cached g 2>&1)
test -z "$out" || failed "test 9 failed: got unexpected output '$out'"
test -e g || failed "test 9 failed: file 'g' was deleted with --cached flag"
test "$(cat g)" = "hello world" || failed "test 9 failed: file 'g' has incorrect contents"

out=$(girt-show :g 2>&1)
out_status=$?
out_exp="'g' not found in index"
test_failure 9 "$out" "$out_status" "$out_exp"

echo "test 9 passed"

# test 10: success: working file and staged file both different to repo (with --force)
echo hello > h
girt-add h > /dev/null 2>&1
girt-commit -m 'This is commit 7' > /dev/null 2>&1

echo hello world > h
girt-add h > /dev/null 2>&1

echo hello world! > h

out=$(girt-rm --force h 2>&1)
test -z "$out" || failed "test 10 failed: got unexpected output '$out'"
test ! -e h || failed "test 10 failed: file 'h' was not deleted with --force flag"

out=$(girt-show :h 2>&1)
out_status=$?
out_exp="'h' not found in index"
test_failure 10 "$out" "$out_status" "$out_exp"

out=$(girt-show 7:h 2>&1) # check file still in repo
out_exp="hello"
test "$out" = "$out_exp" || failed "test 10 failed: incorrect output: expected '$out_exp', got '$out'"

echo "test 10 passed"

passed
