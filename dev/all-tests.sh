#!/usr/bin/env bash
#############################################################
#
# File: dev/all-tests.sh
#
# Description: run all tests, exit after failed test
#
#### $$VERSION$$ v1.21-0-gc85af77
#############################################################

# magic to ensure that we're always inside the root of our application,
# no matter from which directory we'll run script
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null)
if [ "$GIT_DIR" != "" ] ; then
	cd "$GIT_DIR/.." || exit 1
else
	printf "Sorry, no git repository %s\n" "$(pwd)" && exit 1
fi

##########################
# create test environment
TESTENV="/tmp/bashbot.test$$"
mkdir "${TESTENV}"
cp -r ./* "${TESTENV}"
cd "test" || exit 1

# delete possible config
rm -f "${TESTENV}/botconfig.jssh" "${TESTENV}/botacl" 2>/dev/null

# mkdir needed dirs
mkdir "${TESTENV}/data-bot-bash"

# inject JSON.sh
mkdir "${TESTENV}/JSON.sh"
curl -sL "https://cdn.jsdelivr.net/gh/dominictarr/JSON.sh/JSON.sh" >"${TESTENV}/JSON.sh/JSON.sh"
chmod +x "${TESTENV}/JSON.sh/JSON.sh"

########################
#prepare and run tests
#set -e
fail=0
tests=0
passed=0
#all_tests=${__dirname:}
#printf PLAN ${#all_tests}
for test in $(find ./*-test.sh | sort -u) ;
do
  [ "${test}" = "dev/all-tests.sh" ] && continue
  [ ! -x "${test}" ] && continue
  tests=$((tests+1))
  printf "TEST: %s\n" "${test}"
  "${test}" "${TESTENV}"
  ret=$?
  set +e
  if [ "$ret" -eq 0 ] ; then
    printf "OK: ---- %s\n" "${test}"
    passed=$((passed+1))
  else
    printf "FAIL: %s\n" "${test} ${fail}"
    fail=$((fail+ret))
    break
  fi
done

###########################
# cleanup depending on test state
if [ "$fail" -eq 0 ]; then
  printf 'SUCCESS '
  exitcode=0
  rm -rf "${TESTENV}"
else
  printf 'FAILURE '
  exitcode=1
  rm -rf "${TESTENV}/test"
  find "${TESTENV}/"* ! -name '[a-z]-*' -delete
fi

#########################
# show test result and test logs
printf "%s\n\n" "${passed} / ${tests}"
[ -d "${TESTENV}" ] && printf "Logfiles from run are in %s\n" "${TESTENV}"

ls -ld /tmp/bashbot.test* 2>/dev/null && printf "Do not forget to delete bashbot test files in /tmp!!\n"

exit ${exitcode}
