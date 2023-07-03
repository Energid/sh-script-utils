# shellcheck shell=sh

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
# directory path stored in the shell variable INCLUDE_ROOT.
# Altneratively, If 'include-function.sh' is sourced interactively,
# then INCLUDE_ROOT will be left unset.
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
  : "${1:?missing file path argument}"

  [ $# -eq 1 ] || : "${_include_extra_args:?extra argument(s)}"

  case "$1" in
    /*) INCLUDE_SOURCE=$1
        ;;

     *) if [ "${INCLUDE_SOURCE:-}" ]; then
          INCLUDE_SOURCE="$(dirname "$INCLUDE_SOURCE")/$1"
        elif [ "${INCLUDE_ROOT:-}" ]; then
          INCLUDE_SOURCE="${INCLUDE_ROOT%/*}/$1"
        else
          INCLUDE_SOURCE="$PWD/$1"
        fi
        ;;
  esac

  __INCLUDE_STACK="${__INCLUDE_STACK:-}:$INCLUDE_SOURCE"

  # only include file if it has not been already
  case ":${__INCLUDED_FILES:-}:" in *:$INCLUDE_SOURCE:*) ;; *)
    __INCLUDED_FILES="${__INCLUDED_FILES:+$__INCLUDED_FILES:}$INCLUDE_SOURCE"

    # shellcheck disable=SC1090
    . "$INCLUDE_SOURCE"
  ;; esac

  __INCLUDE_STACK=${__INCLUDE_STACK%:*}
  if [ "$__INCLUDE_STACK" ]; then
    INCLUDE_SOURCE=${__INCLUDE_STACK##*:}
  else
    unset __INCLUDE_STACK
    unset INCLUDE_SOURCE
  fi
}

# initialize INCLUDE_ROOT variable (if possible)
# shellcheck disable=SC2249 # default case not needed
case "$(file -- "${ZSH_ARGZERO:-$0}")" in
  *text*)
    INCLUDE_ROOT=${ZSH_ARGZERO:-$0}
    # shellcheck disable=SC2164 # chance of `cd` failing is negligible
    INCLUDE_ROOT="$(cd -- "$(dirname "$INCLUDE_ROOT")"; pwd)/${INCLUDE_ROOT##*/}"
    ;;
esac
