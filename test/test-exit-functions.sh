#!/usr/bin/env sh

# shellcheck disable=SC2164,SC2312 # chance of `cd` failing is negligible
# shellcheck disable=SC1091 # do not follow source
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/exit-functions.sh"

test_exit_handlers() {
  assertFalse 'missing argument' register_exit_handler
  assertFalse 'empty argument' "register_exit_handler ''"

  assertFalse 'extra argument (register)' "register_exit_handler ls x"
  assertFalse 'extra argument (enable)' "eval \"\$(enable_exit_handlers x\)\""
  assertFalse 'extra argument (trigger)' "trigger_exit_handlers x"

  register_exit_handler "echo yes"
  register_exit_handler "false"
  register_exit_handler "echo no"

  set -e

  assertEquals 'manual triggering' \
               "$(printf 'yes\nno\n')" "$(trigger_exit_handlers)"
  case $- in *e*) ;; *)
    fail 'set -e not reset'
  ;; esac

  trigger_exit_handlers >/dev/null
  assertEquals 'manual triggering (2nd call)' \
               '' "$(trigger_exit_handlers)"

  set +e

  _test_exit_handlers_script_dir=$(cd -- "$(dirname "${ZSH_ARGZERO:-$0}")"; pwd)

  assertEquals 'auto triggering (EXIT)' \
    'foo' \
    "$(. "$_test_exit_handlers_script_dir/../lib/exit-functions.sh"
       eval "$(enable_exit_handlers)"
       register_exit_handler 'echo foo')"

  # shellcheck disable=SC2154 # SHUNIT_TMPDIR defined by shunit2
  _test_exit_handlers_output_file="${SHUNIT_TMPDIR}/output"
  cp /dev/null "$_test_exit_handlers_output_file"

  (
    . "$_test_exit_handlers_script_dir/../lib/exit-functions.sh"
    eval "$(enable_exit_handlers)"
    register_exit_handler "echo foo >>'$_test_exit_handlers_output_file'"
    while true; do sleep 1; done
    echo 'bar' >>"$_test_exit_handlers_output_file"
  )&
  _test_exit_handlers_child_pid=$!
  sleep 1
  kill "$_test_exit_handlers_child_pid"
  wait "$_test_exit_handlers_child_pid" 2>/dev/null

  assertEquals 'auto triggering (TERM)' \
    'foo' "$(cat "$_test_exit_handlers_output_file")"

  unset _test_exit_handlers_script_dir \
        _test_exit_handlers_output_file \
        _test_exit_handlers_child_pid
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
