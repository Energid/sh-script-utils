#!/usr/bin/env sh

# shellcheck disable=SC2164,SC2312 # chance of `cd` failing is negligible
# shellcheck disable=SC1091 # do not follow source
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"
include ../lib/temp-functions.sh

test_get_temp_file() {
  assertFalse "missing variable name" get_temp_file
  assertFalse "empty variable name" "get_temp_file ''"
  assertFalse "invalid variable name" "get_temp_file '?'"

  assertFalse 'extra argument' "get_temp_file _test_get_temp_file_file x"

  get_temp_file _test_get_temp_file_file; _test_get_temp_file_status=$?
  assertEquals 'file generated' 0 "$_test_get_temp_file_status"

  assertNotNull 'file name published' "${_test_get_temp_file_file:-}"
  assertTrue 'file exists' "[ -r '${_test_get_temp_file_file:-}' ]"

  trigger_exit_handlers

  assertFalse 'file cleaned on exit' "[ -r '${_test_get_temp_file_file:-}' ]"

  unset _test_get_temp_file_status _test_get_temp_file_file
}

test_get_temp_dir() {
  assertFalse "missing variable name" get_temp_dir
  assertFalse "empty variable name" "get_temp_dir ''"
  assertFalse "invalid variable name" "get_temp_dir '?'"

  assertFalse 'extra argument' "get_temp_dir _test_get_temp_dir_dir x"

  get_temp_dir _test_get_temp_dir_dir; _test_get_temp_dir_status=$?
  assertEquals 'dir generated' 0 "$_test_get_temp_dir_status"

  assertNotNull 'dir name published' "${_test_get_temp_dir_dir:-}"
  assertTrue 'dir exists' "[ -d '${_test_get_temp_dir_dir:-}' ]"

  trigger_exit_handlers

  assertFalse 'dir cleaned on exit' "[ -d '${_test_get_temp_dir_dir:-}' ]"

  unset _test_get_temp_dir_status _test_get_temp_dir_dir
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
