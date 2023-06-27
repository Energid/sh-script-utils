# shellcheck shell=sh

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
  _error_user_error=0
  if [ "${1:-}" = '-u' ]; then
    _error_user_error=1; shift
  fi

  if [ ! "${1:-}" ]; then
    unset _error_user_error

    echo "missing error message" >&2
    return 2
  fi

  _error_source="${SCRIPT_NAME:-}"
  if [ ! "$_error_source" ] && file -- "${ZSH_ARGZERO:-$0}" | grep -q 'text'; then
    _error_source=${ZSH_ARGZERO:-$0}
    _error_source=${_error_source##*/}
  fi

  echo "${_error_source:-error}: $*" >&2

  _error_exit_code=1
  if [ "$_error_user_error" -eq 1 ]; then
    if [ "$_error_source" ]; then
      echo "Try '$_error_source -h' for more information." >&2
    fi

    _error_exit_code=2
  fi

  echo "$_error_exit_code"
 
  unset _error_user_error _error_source _error_exit_code
}
