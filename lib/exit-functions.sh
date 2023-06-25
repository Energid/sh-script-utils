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

  ExitHandlers="${ExitHandlers:+${ExitHandlers}; }${handler}"
}

#
# Usage: eval "$(enable_exit_handlers)"
#
# Set traps to call `trigger_exit_handlers` when the current function
# (zsh-only) or shell exits, normally or abnormally.
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
  if [ "${ExitHandlersEnabled:-0}" -eq 0 ]; then
    echo "trap trigger_exit_handlers INT HUP QUIT TERM EXIT"
    echo "ExitHandlersEnabled=1"
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
  if [ "${ExitHandlers:-}" ]; then
    local was_set_e_on=0
    case $- in *e*) was_set_e_on=1 ;; esac
    set +e

    eval "$ExitHandlers"
    unset ExitHandlers

    if [ "$was_set_e_on" -eq 1 ]; then
      set -e
    fi
  fi

  if [ "${ExitHandlersEnabled:-0}" -ne 0 ]; then
    trap - INT HUP QUIT TERM EXIT
    unset ExitHandlersEnabled
  fi
}