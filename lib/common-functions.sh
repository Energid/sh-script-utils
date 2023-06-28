# shellcheck shell=sh

#
# Usage: is_number STRING
#
# Returns `0` if STRING is a valid integer; else returns `1`.
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
# Returns `0` if STRING is a valid name for a shell variable;
# else returns `1`.
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
# REPL may be an empty string. If VAR does not exist, it will
# be initialized with an empty string.
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

# If VAR does not exist, it will be initialized with an empty string before
# the function processes it.
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
  _escape_index=1

  for _escape_arg in "$@"; do
    if [ "$_escape_index" -gt 1 ]; then
      printf ' '
    fi

    # shellcheck disable=SC2249 # default case not needed
    case $_escape_arg in ''|*[!0-9A-Za-z_]*)
      # shellcheck disable=SC2249 # default case not needed
      case $_escape_arg in ''|*[!-0-9A-Za-z^+,./:=@_]*)
        # shellcheck disable=SC2249 # default case not needed
        case $_escape_arg in *\'*)
          replace_all _escape_arg "'" "'\\''"
        ;; esac

        printf '%s' "'$_escape_arg'"
        _escape_index=$((_escape_index + 1))

        continue
      ;; esac
    ;; esac

    printf '%s' "$_escape_arg"
    _escape_index=$((_escape_index + 1))
  done

  unset _escape_index _escape_arg
}
