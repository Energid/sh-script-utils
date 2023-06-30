# shellcheck shell=sh

#
# Usage: is_number STRING
#
# Returna success if STRING is a valid integer; else return failure.
#
is_number() {
  : "${1:?missing value}"

  [ $# -eq 1 ] || : "${_is_number_extra_args:?extra argument(s)}"

  case $1 in
    *[!0-9]*) false ;;
    *)         true ;;
  esac
}

#
# Usage: is_valid_identifier STRING
#
# Return success if STRING is a valid name for a shell variable;
# else return failure.
#
is_valid_identifier() {
  : "${1:?missing identifier}"

  [ $# -eq 1 ] || : "${_is_valid_id_extra_args:?extra argument(s)}"

  case $1 in
    [0-9]*|*[!A-Za-z0-9_]*) false ;;
    *) true ;;
  esac
}

#
# Usage: replace_all VAR KEY REPL
#
# Replace all instances of KEY in $VAR with REPL.
#
# REPL may be an empty string. If VAR does not exist, it will be created
# as a null global shell variable.
#
# Warning:
#   If VAR exists, it must be either a global shell variable or a local
#   variable with dynamic scoping. Attempting to pass a local VAR with
#   static scoping will cause a global VAR to be created/updated instead.
#   Of all the POSIX-compliant shells that support local variables,
#   only ksh93 and its descendants are known to use static scoping.
#
replace_all() {
  : "${1:?missing variable name}"
  : "${2:?missing key string}"
  : "${3?missing replacement string}"

  [ $# -eq 3 ] || : "${_replace_all_extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid variable name" >&2
    return 2
  fi

  eval "_replace_all_right=\"\${$1:-}\""

  while [ "$_replace_all_right" ]; do
    _replace_all_left=${_replace_all_right%%"$2"*}

    if [ "$_replace_all_left" = "$_replace_all_right" ]; then
      _replace_all_result="${_replace_all_result}${_replace_all_right}"
      break
    fi

    _replace_all_result="${_replace_all_result}${_replace_all_left}$3"
    _replace_all_right=${_replace_all_right#*"$2"}
  done

  eval "$1=\"\${_replace_all_result}\""
  unset _replace_all_left _replace_all_right _replace_all_result
}

#
# Usage: escape_var VAR
#
# Modify $VAR such that it is quoted and/or escaped for safe usage with `eval`.
#
# This function provides a faster alternative to `escape`.
#
# If VAR does not exist, it will be created as a null global shell variable
# before the function processes it.
#
# Warning:
#   If VAR exists, it must be either a global shell variable or a local
#   variable with dynamic scoping. Attempting to pass a local VAR with
#   static scoping will cause a global VAR to be created/updated instead.
#   Of all the POSIX-compliant shells that support local variables,
#   only ksh93 and its descendants are known to use static scoping.
#
escape_var() {
  : "${1:?missing variable name}"

  [ $# -eq 1 ] || : "${_escape_var_extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid variable name" >&2
    return 2
  fi

  eval "_escape_var_result=\"\${$1:-}\""

  # shellcheck disable=SC2154 # _escape_var_result used in `eval` statement
  # shellcheck disable=SC2249 # default case not needed
  case $_escape_var_result in ''|*[!0-9A-Za-z_]*)
    # shellcheck disable=SC2249 # default case not needed
    case $_escape_var_result in ''|*[!-0-9A-Za-z^+,./:=@_]*)
      # shellcheck disable=SC2249 # default case not needed
      case $_escape_var_result in *\'*)
        replace_all _escape_var_result "'" "'\\''"
      ;; esac

      eval "$1=\"'\${_escape_var_result}'\""
    ;; esac
  ;; esac

  unset _escape_var_result
}

#
# Usage: escape ARG...
#
# Prints each ARG quoted and/or escaped for safe usage with `eval`.
#
escape() {
  _escape_output=''

  for _escape_arg in "$@"; do
    # shellcheck disable=SC2249 # default case not needed
    case $_escape_arg in ''|*[!0-9A-Za-z_]*)
      # shellcheck disable=SC2249 # default case not needed
      case $_escape_arg in ''|*[!-0-9A-Za-z^+,./:=@_]*)
        # shellcheck disable=SC2249 # default case not needed
        case $_escape_arg in *\'*)
          replace_all _escape_arg "'" "'\\''"
        ;; esac

        _escape_arg="'$_escape_arg'"
      ;; esac
    ;; esac

    _escape_output="${_escape_output:+$_escape_output }$_escape_arg"
  done

  printf '%s' "$_escape_output"

  unset _escape_output _escape_arg
}
