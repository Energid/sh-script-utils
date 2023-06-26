# shellcheck shell=sh
# shellcheck disable=SC3043 # allow 'local' usage

#
# Usage: register_exit_handler COMMAND_LINE
#
# Add COMMAND_LINE to the list of commands to be run when
# `trigger_exit_handlers` is next called.
#
register_exit_handler() {
  local handler="${1:?missing command}"

  local extra_args=''; [ $# -eq 1 ] || : "${extra_args:?extra argument(s)}"

  __EXIT_HANDLERS="${__EXIT_HANDLERS:+${__EXIT_HANDLERS}; }${handler}"
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
  if [ $# -gt 0 ]; then
    echo "echo \"extra argument(s)\" 2>&1"
    echo "false"
  fi

  if [ "${__EXIT_HANDLERS_ENABLED:-0}" -eq 0 ]; then
    echo "trap trigger_exit_handlers EXIT"
    echo "trap 'exit \$?' INT HUP QUIT TERM"
    echo "__EXIT_HANDLERS_ENABLED=1"
  fi
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
  local extra_args=''; [ $# -eq 0 ] || : "${extra_args:?extra argument(s)}"

  if [ "${__EXIT_HANDLERS:-}" ]; then
    local was_set_e_on=0
    case $- in *e*) was_set_e_on=1 ;; esac
    set +e

    eval "$__EXIT_HANDLERS"
    unset __EXIT_HANDLERS

    if [ "$was_set_e_on" -eq 1 ]; then
      set -e
    fi
  fi

  if [ "${__EXIT_HANDLERS_ENABLED:-0}" -ne 0 ]; then
    trap - INT HUP QUIT TERM EXIT
    unset __EXIT_HANDLERS_ENABLED
  fi
}
