# shellcheck shell=sh

#
# Usage: register_exit_handler COMMAND_LINE
#
# Add COMMAND_LINE to the list of commands to be run when
# `trigger_exit_handlers` is next called.
#
register_exit_handler() {
  : "${1:?missing command}"

  [ $# -eq 1 ] || : "${_register_exit_handler_extra_args:?extra argument(s)}"

  __EXIT_HANDLERS="${__EXIT_HANDLERS:+${__EXIT_HANDLERS}; }$1"
}

#
# Usage: eval "$(enable_exit_handlers)"
#
# Set traps to call `trigger_exit_handlers` when the current function
# (zsh-only) or (sub)shell exits, normally or abnormally.
#
# Implementation Notes:
#   The reason the output of the function needs to be passed to `eval`,
#   rather than the function being called directly, is to support
#   the idiosyncratic of the 'EXIT' trap under `zsh`. For most shells,
#   the 'EXIT' trap will always run when the current shell instance exists.
#   For `zsh` however, the `EXIT` trap, when set within a function, will
#   run when that function returns.
#
enable_exit_handlers() {
  echo "{"

  if [ $# -gt 0 ]; then
    echo "echo \"extra argument(s)\" 2>&1"
    echo "false"
  fi

  if [ "${__EXIT_HANDLERS_ENABLED:-0}" -eq 0 ]; then
    echo "trap trigger_exit_handlers EXIT"
    echo "trap 'exit \$?' INT HUP QUIT TERM"
    echo "__EXIT_HANDLERS_ENABLED=1"
  fi

  echo "}"
}

#
# Usage: trigger_exit_handlers
#
# Run all commands passed to `register_exit_handler` and
# then clear this command list. If `enable_exit_handlers`
# was called prior to this function, all shell exit traps
# will be reset to their default behaviors.
#
trigger_exit_handlers() {
  [ $# -eq 0 ] || : "${_trigger_exit_handlers_extra_args:?extra argument(s)}"

  if [ "${__EXIT_HANDLERS:-}" ]; then
    case $- in
      *e*) _trigger_exit_handlers_had_errexit=1 ;;
        *) _trigger_exit_handlers_had_errexit=0 ;;
    esac
    set +e

    eval "$__EXIT_HANDLERS"
    unset __EXIT_HANDLERS

    [ "$_trigger_exit_handlers_had_errexit" -eq 0 ] || set -e
    unset _trigger_exit_handlers_had_errexit
  fi

  if [ "${__EXIT_HANDLERS_ENABLED:-0}" -ne 0 ]; then
    trap - INT HUP QUIT TERM EXIT
    unset __EXIT_HANDLERS_ENABLED
  fi
}
