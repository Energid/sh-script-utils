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
# The temporary file will be automatically deleted when `trigger_exit_handlers`
# (from exit-functions.sh) is called.
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
# The temporary directory will be automatically deleted when
# `trigger_exit_handlers` (from exit-functions.sh) is called.
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
