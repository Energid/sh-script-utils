#!/usr/bin/env sh

# shellcheck disable=SC2164,SC2312 # chance of `cd` failing is negligible
# shellcheck disable=SC1091 # do not follow source
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"
include ../lib/error-functions.sh

test_error() {
  assertFalse 'missing error message' error
  assertFalse 'empty error message' "error ''"

  assertEquals 'normal error (w/o SCRIPT_NAME)' \
    "$(printf '%s\n%s\n' \
       'test-error-functions.sh: something went wrong' \
       1)" \
    "$(error something went wrong 2>&1)"
  assertEquals 'normal error (w/ SCRIPT_NAME)' \
    "$(printf '%s\n%s\n' \
       'foobar: something went wrong' \
       1)" \
    "$(SCRIPT_NAME='foobar' error 'something went wrong' 2>&1)"

  assertEquals 'user error (w/o SCRIPT_NAME)' \
    "$(printf '%s\n%s\n%s\n' \
       'test-error-functions.sh: something went wrong' \
       "Try 'test-error-functions.sh -h' for more information." \
       2)" \
    "$(error -u 'something went wrong' 2>&1)"
  assertEquals 'user error (w/ SCRIPT_NAME)' \
    "$(printf '%s\n%s\n%s\n' \
       'foobar: something went wrong' \
       "Try 'foobar -h' for more information." \
       2)" \
    "$(SCRIPT_NAME='foobar' error -u something went wrong 2>&1)"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
