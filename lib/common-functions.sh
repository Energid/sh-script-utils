# shellcheck shell=sh
# shellcheck disable=SC3043 # allow 'local' usage

#
# Usage: is_number STRING
#
# Returns `0` if STRING is a valid integer; else returns `1`.
#
is_number() {
  local value="${1:?missing value}"

  local extra_args=''; [ $# -eq 1 ] || : "${extra_args:?extra argument(s)}"

  case $value in
    *[!0-9]*) false ;;
    *)         true ;;
  esac
}

#
# Usage: is_valid_identifier STRING
#
# Returns `0` if STRING is a valid name for a shell variable;
# else returns `1`.
#
is_valid_identifier() {
  local id="${1:?missing identifier}"

  local extra_args=''; [ $# -eq 1 ] || : "${extra_args:?extra argument(s)}"

  case $id in
    [0-9]*|*[!A-Za-z0-9_]*) false ;;
    *) true ;;
  esac
}

#
# Usage: replace_all VAR KEY REPL
#
# Replace all instances of KEY in $VAR with REPL.
#
# REPL may be an empty string. If VAR does not exist, it will
# be initialized with an empty string.
#
# Implementation Notes:
#   The reason all local variables in this function are prefixed with
#   `_replace_all_` is to reduce the likelihood of one of the variables
#   having the same name as VAR and thus preventing $VAR from being
#   updated on function completion.
#
replace_all() {
  : "${1:?missing variable name}"
  : "${2:?missing key string}"
  : "${3?missing replacement string}"

  local extra_args=''; [ $# -eq 3 ] || : "${extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid variable name" >&2
    return 2
  fi

  local _replace_all_result=''
  eval "local _replace_all_right=\"\${$1:-}\""

  while [ "$_replace_all_right" ]; do
    _replace_all_left="${_replace_all_right%%$2*}"

    if [ "$_replace_all_left" = "$_replace_all_right" ]; then
      _replace_all_result="${_replace_all_result}${_replace_all_right}"
      break
    fi

    _replace_all_result="${_replace_all_result}${_replace_all_left}$3"
    _replace_all_right="${_replace_all_right#*$2}"
  done

  eval "$1=\"\${_replace_all_result}\""
}

#
# Usage: escape_var VAR
#
# Modify $VAR such that it is quoted and/or escaped for safe usage with `eval`.
#
# This function provides a faster alternative to `escape`.

# If VAR does not exist, it will be initialized with an empty string before
# the function processes it.
#
# Implementation Notes:
#   The reason all local variables in this function are prefixed with
#   `_escape_var_` is to reduce the likelihood of one of the variables
#   having the same name as VAR and thus preventing $VAR from being
#   updated on function completion.
#
escape_var() {
  : "${1:?missing variable name}"

  local extra_args=''; [ $# -eq 1 ] || : "${extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid variable name" >&2
    return 2
  fi

  eval "local _escape_var_result=\"\${$1:-}\""

  # shellcheck disable=SC2154 # _escape_var_result used in `eval` statement
  case $_escape_var_result in ''|*[[:punct:][:space:]]*)
    case $_escape_var_result in ''|*[!-[:alnum:]^+,./:=@_]*)
      case $_escape_var_result in *\'*)
        replace_all _escape_var_result "'" "'\\''"
      ;; esac

      eval "$1=\"'\${_escape_var_result}'\""
    ;; esac
  ;; esac
}

#
# Usage: escape ARG...
#
# Prints each ARG quoted and/or escaped for safe usage with `eval`.
#
escape() {
  local arg
  local idx=1

  for arg in "$@"; do
    if [ "$idx" -gt 1 ]; then
      printf ' '
    fi

    case $arg in ''|*[[:punct:][:space:]]*)
      case $arg in ''|*[!-[:alnum:]^+,./:=@_]*)
        case $arg in *\'*)
          replace_all arg "'" "'\\''"
        ;; esac

        printf '%s' "'$arg'"
        idx=$((idx + 1))

        continue
      ;; esac
    ;; esac

    printf '%s' "$arg"
    idx=$((idx + 1))
  done
}
