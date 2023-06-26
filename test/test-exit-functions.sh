#!/usr/bin/env sh
# shellcheck disable=SC3043 # allow 'local' usage

# shellcheck disable=SC2164 # chance of `cd` failing is neglible
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

  local script_dir
  script_dir=$(cd -- "$(dirname "${ZSH_ARGZERO:-$0}")"; pwd)

  assertEquals 'auto triggering (EXIT)' \
    'foo' \
    "$(. "$script_dir/../lib/exit-functions.sh"
       eval "$(enable_exit_handlers)"
       register_exit_handler 'echo foo')"

  local output_file="${SHUNIT_TMPDIR}/output"
  cp /dev/null "$output_file"

  (
    . "$script_dir/../lib/exit-functions.sh"
    eval "$(enable_exit_handlers)"
    register_exit_handler "echo foo >>'$output_file'"
    while true; do sleep 1; done
    echo 'bar' >>"$output_file"
  )&
  local child_pid=$!
  sleep 1
  kill "$child_pid"
  wait "$child_pid"

  assertEquals 'auto triggering (TERM)' 'foo' "$(cat "$output_file")"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
