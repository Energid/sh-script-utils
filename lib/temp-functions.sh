# shellcheck shell=sh
# shellcheck disable=SC3043 # allow 'local' usage

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
# The temporary file will be automatically deleted when the shell exits.
#
# Implementation Notes:
#   The reason all local variables in this function are prefixed with
#   `_get_file_file_` is to reduce the likelihood of one of the variables
#   having the same name as NAME and thus preventing $NAME from being
#   updated on function completion.
#
get_temp_file() {
  local _get_temp_file_varname="${1:?missing output variable name}"

  if ! is_valid_identifier "$_get_temp_file_varname"; then
    echo "'$_get_temp_file_varname' is not a valid identifier" >&2
    return 2
  fi

  local _get_temp_file_path
  _get_temp_file_path=$(mktemp) || return $?
  escape_var _get_temp_file_path

  register_exit_handler "rm -f $_get_temp_file_path"

  eval "$_get_temp_file_varname=$_get_temp_file_path"
}

#
# Usage: get_temp_dir NAME
#
# Create temporary directory and assign its path to the shell variable NAME.
#
# The temporary directory will be automatically deleted when the shell exits.
#
# Implementation Notes:
#   The reason all local variables in this function are prefixed with
#   `_get_temp_dir_` is to reduce the likelihood of one of the variables
#   having the same name as NAME and thus preventing $NAME from being
#   updated on function completion.
#
get_temp_dir() {
  local _get_temp_dir_varname="${1:?missing output variable name}"

  if ! is_valid_identifier "$_get_temp_dir_varname"; then
    echo "'$_get_temp_dir_varname' is not a valid identifier" >&2
    return 2
  fi

  local _get_temp_dir_path
  _get_temp_dir_path=$(mktemp -d) || return $?
  escape_var _get_temp_dir_path

  register_exit_handler "rm -rf $_get_temp_dir_path"

  eval "$_get_temp_dir_varname=$_get_temp_dir_path"
}
