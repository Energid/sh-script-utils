# shellcheck shell=sh
# shellcheck disable=SC3043 # allow 'local' usage

# --------------------------------------------------------------------------------
# WARNING: This file must be loaded using `include` (from 'include-function.sh').
# --------------------------------------------------------------------------------

include common-functions.sh

#
# Usage: error [-u] MESSAGE...
#
# Concatenates given MESSAGEs and prints the result to standard error.
# Also prints `1` to standard output for use with `return` or `exit`.
#
# If the script variable SCRIPT_NAME is defined, then the error
# message will be prefixed with its value. Else, the message will
# be prefixed with the name of the currently executing script (if any).
#
# With the `-u` option, an additional error message will be printed to
# guide the user to pass the `-h` option to currently executing script
# for more information. Also `2` will be printed to standard output
# instead of `1`.
#
# Example:
#   check_file_path() {
#     if [ ! -f "$1" ]; then
#       return "$(error "'$1' is not a file")"
#     fi
#     return 0
#   }
#
#   # will print "<script-name>: '/non/existent/path' is not a file" to STDERR
#   # and cause script to exit with status code `1`
#   check_file_path /non/existent/path || exit $?
#
error() {
  local user_error=0
  if [ "${1:-}" = '-u' ]; then
    user_error=1; shift
  fi

  if [ ! "${1:-}" ]; then
    echo "missing error message" >&2
    return 2
  fi
  local msg="$*"

  local source="${SCRIPT_NAME:-}"
  if [ ! "$source" ] && file -- "${ZSH_ARGZERO:-$0}" | grep -q 'text'; then
    source=${ZSH_ARGZERO:-$0}
    source=${source##*/}
  fi

  echo "${source:-error}: $msg" >&2

  local exit_code=1
  if [ "$user_error" -eq 1 ]; then
    if [ "$source" ]; then
      echo "Try '$source -h' for more information." >&2
    fi

    exit_code=2
  fi

  echo "$exit_code"
}
