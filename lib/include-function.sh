# shellcheck shell=sh
# shellcheck disable=SC3043 # allow 'local' usage

# prevent file from being sourced twice to ensure INCLUDE_ROOT is not redefined
if [ "${INCLUDE_ROOT:-}" ]; then
  echo "ERROR: 'include-functions.sh' has already been sourced." 2>&1
  # shellcheck disable=SC2317
  return 1 2>/dev/null || exit 1
fi

#
# Usage: include FILE
#
# Execute commands from FILE in the current shell.
#
# This function wraps the shell's dot operator (.) and causes FILE
# to be resolved relative to the current source file location, rather
# than located using the command PATH.
#
# More precisely, `include`, when called with a relative FILE argument,
# will resolve the path according the following rules:
#   - If the call site is within a file that was itself loaded by `include`,
#     then FILE will be resolved relative to the loaded file's location.
#   - Else, if the shell is executing a script file, then FILE will be
#     resolved relative to the script file's location.
#   - Else, FILE will be resolved relative to the current working directory.
#
# This function also detects when it has already loaded a given file and
# will prevent the file from being reloaded as an optimization.
#
# When a file is loaded by `include`, the file is able to access its
# own path via the shell variable INCLUDE_SOURCE outside of any function
# definitions in the file.
#
# The script file that sources 'include-function.sh' will have its full
# path stored in the shell variable INCLUDE_ROOT.
#
# NOTE: This file should always be sourced from outermost scope of the
#       the main script file (if any). Sourcing it from within a function
#       body or another script called by the main script may cause include
#       paths to be resolved incorrectly.
#
# WARNING: You should not use `include` within a file that was itself
#          loaded by the shell's dot operator (.). Else PATH may be
#          resolved incorrectly.
#
include() {
  local file_path="${1:?missing file path argument}"

  local extra_args=''; [ $# -eq 1 ] || : "${extra_args:?extra argument(s)}"

  case "$file_path" in /*) ;; *)
    local root_dir
    if [ "${INCLUDE_SOURCE:-}" ]; then
      root_dir=$(dirname "$INCLUDE_SOURCE")
    else
      root_dir=$INCLUDE_ROOT
    fi

    file_path="$root_dir/$file_path"
  ;; esac

  # return early if file has already been included
  # shellcheck disable=SC2249 # default case not needed
  case ":${__INCLUDED_FILES:-}:" in *:$file_path:*)
    return 0
  ;; esac

  local INCLUDE_SOURCE="$file_path"

  # shellcheck disable=SC1090
  . "$file_path"

  __INCLUDED_FILES="${__INCLUDED_FILES:+$__INCLUDED_FILES:}$file_path"
}

# initialize INCLUDE_ROOT variable
case "$(file -- "${ZSH_ARGZERO:-$0}")" in
  *text*)
    # shellcheck disable=SC2164 # chance of `cd` failing is neglible
    INCLUDE_ROOT=$(cd -- "$(dirname "${ZSH_ARGZERO:-$0}")"; pwd)
    ;;
  *)
    INCLUDE_ROOT=$PWD
    ;;
esac
