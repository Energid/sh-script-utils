# shellcheck shell=sh

# --------------------------------------------------------------------------------
# WARNING: This file must be loaded using `include` (from 'include-function.sh').
# --------------------------------------------------------------------------------

include common-functions.sh
include exit-functions.sh

#
# Usage: get_temp_file NAME
#
# Create temporary file and assign its path to the shell variable NAME.
#
# If NAME does not exist, it will be created as a global shell variable.
#
# The temporary file will be automatically deleted when `trigger_exit_handlers`
# (from exit-functions.sh) is called.
#
# Warning:
#   If NAME exists, it must be either a global shell variable or a local
#   variable with dynamic scoping. Attempting to pass a local NAME with
#   static scoping will cause a global NAME to be created/updated instead.
#   Of all the POSIX-compliant shells that support local variables,
#   only ksh93 and its descendants are known to use static scoping.
#
get_temp_file() {
  : "${1:?missing output variable name}"

  [ $# -eq 1 ] || : "${_get_temp_file_extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid identifier" >&2
    return 2
  fi

  _get_temp_file_path=$(mktemp) || eval "unset _get_temp_file_path; return $?"
  escape_var _get_temp_file_path

  register_exit_handler "rm -f $_get_temp_file_path"

  eval "$1=\$_get_temp_file_path"
  unset _get_temp_file_path
}

#
# Usage: get_temp_dir NAME
#
# Create temporary directory and assign its path to the shell variable NAME.
#
# If NAME does not exist, it will be created as a global shell variable.
#
# The temporary directory will be automatically deleted when
# `trigger_exit_handlers` (from exit-functions.sh) is called.
#
# Warning:
#   If NAME exists, it must be either a global shell variable or a local
#   variable with dynamic scoping. Attempting to pass a local NAME with
#   static scoping will cause a global NAME to be created/updated instead.
#   Of all the POSIX-compliant shells that support local variables,
#   only ksh93 and its descendants are known to use static scoping.
#
get_temp_dir() {
  : "${1:?missing output variable name}"

  [ $# -eq 1 ] || : "${_get_temp_dir_extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid identifier" >&2
    return 2
  fi

  _get_temp_dir_path=$(mktemp -d) || eval "unset _get_temp_dir_path; return $?"
  escape_var _get_temp_dir_path

  register_exit_handler "rm -rf $_get_temp_dir_path"

  eval "$1=\$_get_temp_dir_path"
  unset _get_temp_dir_path
}
