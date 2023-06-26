#!/usr/bin/env sh
# shellcheck disable=SC3043 # allow 'local' usage

# shellcheck disable=SC2164 # chance of `cd` failing is neglible
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"
include ../lib/temp-functions.sh

test_get_temp_file() {
  assertFalse "missing variable name" get_temp_file
  assertFalse "empty variable name" "get_temp_file ''"
  assertFalse "invalid variable name" "get_temp_file '?'"

  assertFalse 'extra argument' "get_temp_file temp_file_path x"

  local temp_file_status
  local temp_file_path
  get_temp_file temp_file_path; temp_file_status=$?
  assertEquals 'file generated' 0 "$temp_file_status"

  assertNotNull 'file name published' "${temp_file_path:-}"
  assertTrue 'file exists' "[ -r '${temp_file_path:-}' ]"

  trigger_exit_handlers

  assertFalse 'file cleaned on exit' "[ -r '${temp_file_path:-}' ]"
}

test_get_temp_dir() {
  assertFalse "missing variable name" get_temp_dir
  assertFalse "empty variable name" "get_temp_dir ''"
  assertFalse "invalid variable name" "get_temp_dir '?'"

  assertFalse 'extra argument' "get_temp_dir temp_dir_path x"

  local temp_dir_status
  local temp_dir_path
  get_temp_dir temp_dir_path; temp_dir_status=$?
  assertEquals 'dir generated' 0 "$temp_dir_status"

  assertNotNull 'dir name published' "${temp_dir_path:-}"
  assertTrue 'dir exists' "[ -d '${temp_dir_path:-}' ]"

  trigger_exit_handlers

  assertFalse 'dir cleaned on exit' "[ -d '${temp_dir_path:-}' ]"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
