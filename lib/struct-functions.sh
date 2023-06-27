# shellcheck shell=sh

# --------------------------------------------------------------------------------
# WARNING: This file must be loaded using `include` (from 'include-function.sh').
# --------------------------------------------------------------------------------

include common-functions.sh

#
# Usage: eval "$(struct_def [-l|-x] STRUCT_NAME FIELD_NAME[=VALUE]...)"
#
# Create structure named STRUCT_NAME with fields named FIELD_NAMEs
# and with optional default VALUEs.
#
# STRUCT_NAME and each FIELD_NAME must be a legal shell variable name.
#
# With the `-l` option, the structure is created at function-local scope,
# rather than global scope. With the `-x` option, the structure is
# exported for use in subshells.
#
# Structures provide a convenient way to pass multiple arguments to shell
# functions and/or receive multiple results from functions. They are
# essentially a POSIX-compliant (except for `local` usage) implementation
# of `bash`'s associative arrays, albeit with added data safety. Once
# a structure is defined, the set of its field names cannot be changed.
# Attempting to read or write a non-existent structure field will cause
# an error.
#
# If not given a default VALUE, a structure's field will be empty (i.e. set
# to an empty string).
#
# The functions `struct_get` and `struct_set` can used to be read and write
# a single structure field, respectively. The function 'struct_print'
# can be used to print the names and values of all fields in a structure.
#
# Example:
#   # create structure named 'vector1' with fields 'x', 'y', 'z'
#   eval "$(struct_def vector1 x=1 y=2 z=3)"
#
#   # create another structure named 'vector2'; assign fields after creation
#   eval "$(struct_def vector2 x y z)"
#   struct_set vector2 x 2
#   struct_set vector2 y 4
#   struct_set vector2 z 6
#
#   eval "$(struct_def vector3 x y z)"
#
#   # perform element-wise addition on 'vector1' and 'vector2' and
#   # store result in 'vector3'
#   add() {
#     struct_set $3 x $(($(struct_get $1 x) + $(struct_get $2 x)))
#     struct_set $3 y $(($(struct_get $1 y) + $(struct_get $2 y)))
#     struct_set $3 z $(($(struct_get $1 z) + $(struct_get $2 z)))
#   }
#   add vector1 vector2 vector3
#
#   # prints the following lines:
#   #   x='3'
#   #   y='6'
#   #   z='9'
#   struct_print vector3
#
# Implementation Notes:
#   The reason the output of `struct_def` must be passed to `eval`, rather
#   than `struct_def` being called directly, is to ensure the `-l` option
#   works properly.
#
struct_def() {
  if [ ! "${_struct_def_recursed:-}" ]; then
    _struct_def_recursed=1
    struct_def "$@"
    eval unset _struct_def_recursed \
               _struct_def_scope _struct_def_name _struct_def_field \
               _struct_def_field_name _struct_def_field_value \
               _struct_def_field_list \; return $?
  fi

  _struct_def_scope=''
  # shellcheck disable=SC2249 # default case not needed
  case ${1:-} in
    -l) _struct_def_scope='local';  shift ;;
    -x) _struct_def_scope='export'; shift ;;
  esac

  if [ $# -eq 0 ]; then
    echo "echo 'missing struct name' >&2"
    echo "false"; return
  fi

  if ! is_valid_identifier "$1"; then
    echo "echo \"'$1' is not a valid struct name\" >&2"
    echo "false"; return
  fi
  _struct_def_name=$1; shift

  if [ $# -eq 0 ]; then
    echo "echo 'missing field name(s)' >&2"
    echo "false"; return
  fi

  _struct_def_field_list=''

  for _struct_def_field in "$@"; do
    _struct_def_field_name=${_struct_def_field%%=*}
    if ! is_valid_identifier "$_struct_def_field_name"; then
      echo "echo \"'$_struct_def_field_name' is not a valid field name\" >&2"
      echo "false"; return
    else
      _struct_def_field_list="${_struct_def_field_list:+$_struct_def_field_list }$_struct_def_field_name"
    fi
  done

  if eval "[ \"\${struct_$_struct_def_name:-}\" ]"; then
    echo "echo \"the struct '$_struct_def_name' already exists\" >&2"
    echo "false"; return
  fi

  # store field names in 'struct_$name' variable;
  # this variable is also used to test for the structure's existence
  echo "${_struct_def_scope:+$_struct_def_scope }struct_${_struct_def_name}='$_struct_def_field_list'"

  # create 'struct_${name}_${field}' variable for each field
  for _struct_def_field in "$@"; do
    _struct_def_field_name=${_struct_def_field%%=*}
    case $_struct_def_field in
      *=*) _struct_def_field_value=${_struct_def_field#*=} ;;
      *)   _struct_def_field_value=''          ;;
    esac

    escape_var _struct_def_field_value
    echo "${_struct_def_scope:+$_struct_def_scope }struct_${_struct_def_name}_${_struct_def_field_name}=$_struct_def_field_value"
  done
}

#
# Usage: struct_get STRUCT_NAME FIELD_NAME
#
# Print value of field with FIELD_NAME in structure with STRUCT_NAME.
#
# Report error and exit (non-interactive) shell if there is no such structure or field.
#
# Note:
#   This function can be expensive when used repeatedly to read a large number of
#   structure fields, since a subshell is typically required to access its output.
#   See `struct_unpack` for a more efficient alternative.
#
struct_get() {
  : "${1:?missing struct name}"
  : "${2:?missing field name}"

  [ $# -eq 2 ] || : "${_struct_get_extra_args:?extra argument(s)}"

  for _struct_get_arg in "$@"; do
    if ! is_valid_identifier "$_struct_get_arg"; then
      unset _struct_get_arg
      echo "'$_struct_get_arg' is not a valid identifier" >&2
      return 2
    fi
  done
  unset _struct_get_arg

  # read 'struct_${name}_${field}' variable
  eval "echo \"\${struct_${1}_$2?no struct exists with name '$1' and field '$2'}\""
}

#
# Usage: struct_get STRUCT_NAME FIELD_NAME VALUE
#
# Assign VALUE to field with FIELD_NAME in structure with STRUCT_NAME.
#
# Report error and exit (non-interactive) shell if there is no such structure or field.
#
# Note:
#   See `struct_pack` for a more convenient alternative for assigning multiple 
#   structure fields at once.
#
struct_set() {
  : "${1:?missing struct name}"
  : "${2:?missing field name}"
  : "${3?missing field value}"

  [ $# -eq 3 ] || : "${_struct_set_extra_args:?extra argument(s)}"

  for _struct_set_arg in "$1" "$2"; do
    if ! is_valid_identifier "$_struct_set_arg"; then
      unset _struct_set_arg
      echo "'$_struct_set_arg' is not a valid identifier" >&2
      return 2
    fi
  done
  unset _struct_set_arg

  # assert 'struct_${name}_${field}' exists
  eval ": \"\${struct_${1}_$2?no struct exists with name '$1' and field '$2'}\"" \
    || return $?

  # set 'struct_${name}_${field}' variable
  eval "struct_${1}_$2=\$3"
}

#
# Usage: struct_exists STRUCT_NAME
#
# Return success is a structure exists with STRUCT_NAME; else return failure.
#
struct_exists() {
  : "${1:?missing struct name}"

  [ $# -eq 1 ] || : "${_struct_exists_extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid identifier" >&2
    return 2
  fi

  eval "test \"\${struct_$1:-}\""
}

#
# Usage: struct_has STRUCT_NAME FIELD_NAME
#
# Return success if a structure exists with STRUCT_NAME and a field
# with FIELD_NAME. If the structure exists but does not have the
# specified field, return failure. Else (if the structure does not
# exist) report an error and exit (non-interactive) shell.
#
struct_has() {
  : "${1:?missing struct name}"
  : "${2:?missing field name}"

  [ $# -eq 2 ] || : "${_struct_has_extra_args:?extra argument(s)}"

  for _struct_has_arg in "$1" "$2"; do
    if ! is_valid_identifier "$_struct_has_arg"; then
      unset _struct_has_arg
      echo "'$_struct_has_arg' is not a valid identifier" >&2
      return 2
    fi
  done
  unset _struct_has_arg

  eval "_struct_has_field_list=\"\${struct_$1?no struct exists with name '$1'}\""

  # shellcheck disable=SC2154 # _struct_has_field_list set by `eval` above
  case " $_struct_has_field_list " in
    *" $2 "*) unset _struct_has_field_list; true  ;;
    *)        unset _struct_has_field_list; false ;;
  esac
}

#
# Usage: struct_test STRUCT_NAME FIELD_NAME OP VALUE
#
# Return success if both of the following conditions are met:
#   - A structure exists with STRUCT_NAME and a field with FIELD_NAME.
#   - The command `test "$(struct_get STRUCT_NAME FIELD_NAME)" OP VALUE`
#     would return success.
#
# Return failure if the given structure and field exist but the
# `test` command would would return failure.
#
# If either the structure or the field do not exist, report error
# and exit (non-interactive) shell.
#
struct_test() {
  : "${1:?missing struct name}"
  : "${2:?missing field name}"
  : "${3:?missing test operator}"
  : "${4?missing test value}"

  [ $# -eq 4 ] || : "${_struct_test_extra_args:?extra argument(s)}"

  for _struct_test_arg in "$1" "$2"; do
    if ! is_valid_identifier "$_struct_test_arg"; then
      unset _struct_test_arg
      echo "'$_struct_test_arg' is not a valid identifier" >&2
      return 2
    fi
  done
  unset _struct_test_arg

  eval test "\"\${struct_${1}_$2?no struct exists with name '$1' and field '$2'}\"" \
            "\"\$3\"" "\"\$4\""
}

#
# Usage: struct_pack STRUCT_NAME FIELD_NAME=VALUE...
#
# Assign VALUEs to fields with FIELD_NAMEs in structure with STRUCT_NAME.
#
# Report error and exit (non-interactive) shell if no structure with STRUCT_NAME
# exists or if any FIELD_NAME does not correspond to a field name in the structure.
#
# Example:
#   eval "$(struct_def vec x y z)"
#
#   # will print 'x=1, y=2, z=3'
#   struct_pack vec x=1 y=2 z=3
#   echo "x=$(struct_get vec x), y=$(struct_get vec y), z=$(struct_get z)"
#
struct_pack() {
  if [ ! "${_struct_pack_recursed:-}" ]; then
    _struct_pack_recursed=1
    struct_pack "$@"
    eval unset _struct_pack_recursed \
               _struct_pack_name _struct_pack_field \
               _struct_pack_field_name _struct_pack_field_value \
               _struct_pack_field_list \; return $?
  fi

  _struct_pack_name="${1:?missing struct name}"; shift

  if [ $# -eq 0 ]; then
    echo "missing field name(s)" >&2
    return 2
  fi

  if ! is_valid_identifier "$_struct_pack_name"; then
    echo "'$_struct_pack_name' is not a valid struct name" >&2
    return 2
  fi

  for _struct_pack_field in "$@"; do
    _struct_pack_field_name=${_struct_pack_field%%=*}
    if ! is_valid_identifier "$_struct_pack_field_name"; then
      echo "'$_struct_pack_field_name' is not a valid field name" >&2
      return 2
    fi

    case $_struct_pack_field in *=*) ;; *)
      echo "missing value for '$_struct_pack_field_name' field" >&2
      return 2
    ;; esac
  done

  eval "_struct_pack_field_list=\"\${struct_${_struct_pack_name}:-}\""
  if [ ! "$_struct_pack_field_list" ]; then
    echo "there is no struct named '$_struct_pack_name'" >&2
    return 2
  fi

  for _struct_pack_field in "$@"; do
    _struct_pack_field_name=${_struct_pack_field%%=*}
    case " $_struct_pack_field_list " in *" $_struct_pack_field_name "*) ;; *)
      echo "no '$_struct_pack_field_name' field exists in struct '$_struct_pack_name'" >&2
      return 2
    ;; esac
  done

  for _struct_pack_field in "$@"; do
    _struct_pack_field_name=${_struct_pack_field%%=*}
    _struct_pack_field_value=${_struct_pack_field#*=}

    eval "struct_${_struct_pack_name}_${_struct_pack_field_name}=\"\$_struct_pack_field_value\""
  done
}

#
# Usage: struct_unpack STRUCT_NAME FIELD_NAME[:VAR_NAME]...
#
# Extract values of fields with FIELD_NAMEs from structure with STRUCT_NAME.
#
# For each given FIELD_NAME, the value of the matching structure field will
# be written to the shell variable FIELD_NAME, creating it if it does not exist.
# If a VAR_NAME is provided, the field value will be written to the shell
# variable VAR_NAME instead.
#
# Report error and exit (non-interactive) shell if no structure with STRUCT_NAME
# exists or if any FIELD_NAME does not correspond to a field name in the structure.
#
# Example:
#   eval "$(struct_def vector1 x=1 y=2 z=3)"
#
#   # will print 'x=1, y=2, z=3'
#   struct_unpack vector1 x y z
#   echo "x=$x, y=$y, z=$y"
#
#   struct_set vector1 x 2
#   struct_set vector1 y 4
#   struct_set vector1 z 6
#
#   # will print 'a=2, b=4, c=6'
#   struct_unpack vector1 x:a y:b z:c
#   echo "a=$a, b=$b, c=$c"
#
struct_unpack() {
  if [ ! "${_struct_unpack_recursed:-}" ]; then
    _struct_unpack_recursed=1
    struct_unpack "$@"
    eval unset _struct_unpack_recursed \
               _struct_unpack_name _struct_unpack_field \
               _struct_unpack_field_name _struct_unpack_field_dest \
               _struct_unpack_field_list \; return $?
  fi

  _struct_unpack_name="${1:?missing struct name}"; shift

  if [ $# -eq 0 ]; then
    echo "missing field name(s)" >&2
    return 2
  fi

  if ! is_valid_identifier "$_struct_unpack_name"; then
    echo "'$_struct_unpack_name' is not a valid struct name" >&2
    return 2
  fi

  for _struct_unpack_field in "$@"; do
    _struct_unpack_field_name=${_struct_unpack_field%%:*}
    if ! is_valid_identifier "$_struct_unpack_field_name"; then
      echo "'$_struct_unpack_field_name' is not a valid field name" >&2
      return 2
    fi

    # shellcheck disable=SC2249 # default case not needed
    case $_struct_unpack_field in *:*)
      _struct_unpack_field_dest=${_struct_unpack_field#*:}
      if [ ! "$_struct_unpack_field_dest" ] \
         || ! is_valid_identifier "$_struct_unpack_field_dest"
      then
        echo "'$_struct_unpack_field_dest' is not a valid identifier" >&2
        return 2
      fi
    ;; esac
  done

  eval "_struct_unpack_field_list=\"\${struct_$_struct_unpack_name:-}\""
  if [ ! "$_struct_unpack_field_list" ]; then
    echo "there is no struct named '$_struct_unpack_name'" >&2
    return 2
  fi

  for _struct_unpack_field in "$@"; do
    _struct_unpack_field_name=${_struct_unpack_field%%:*}
    case " $_struct_unpack_field_list " in *" $_struct_unpack_field_name "*) ;; *)
      echo "no '$_struct_unpack_field_name' field exists in struct '$_struct_unpack_name'" >&2
      return 2
    ;; esac
  done

  for _struct_unpack_field in "$@"; do
    _struct_unpack_field_name=${_struct_unpack_field%%:*}
    case $_struct_unpack_field in
      *:*) _struct_unpack_field_dest=${_struct_unpack_field#*:} ;;
        *) _struct_unpack_field_dest=$_struct_unpack_field_name ;;
    esac

    eval "$_struct_unpack_field_dest=\${struct_${_struct_unpack_name}_${_struct_unpack_field_name}}"
  done
}

#
# Usage: struct_print STRUCT_NAME
#
# Prints name and values of each field in structure with STRUCT_NAME.
#
# Report error if there is no such structure.
#
struct_print() {
  : "${1:?missing struct name}"

  [ $# -eq 1 ] || : "${_struct_print_extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid identifier" >&2
    return 2
  fi

  eval "_struct_print_field_list=\"\${struct_$1:-}\""
  if [ ! "$_struct_print_field_list" ]; then
    unset _struct_print_field_list
    echo "there is no struct named '$1'" >&2
    return 2
  fi

  # print each 'struct_$name_$field' variable
  for _struct_print_field in $_struct_print_field_list; do
    eval "_struct_print_value=\"\${struct_${1}_${_struct_print_field}}\""

    escape_var _struct_print_value
    # shellcheck disable=SC2154 # _struct_has_field_list set by `escape_var`
    echo "$_struct_print_field=$_struct_print_value"
  done

  unset _struct_print_field_list _struct_print_field _struct_print_value
}

#
# Usage: struct_undef STRUCT_NAME
#
# Delete structure with STRUCT_NAME.
#
# Do nothing if there is no such structure.
#
struct_undef() {
  : "${1:?missing struct name}"

  [ $# -eq 1 ] || : "${_struct_undef_extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$1"; then
    echo "'$1' is not a valid identifier" >&2
    return 2
  fi

  eval "_struct_undef_field_list=\"\${struct_$1:-}\""
  if [ ! "$_struct_undef_field_list" ]; then
    unset _struct_undef_field_list
    return 0
  fi

  for _struct_undef_field in $_struct_undef_field_list; do
    eval "unset struct_${1}_${_struct_undef_field}"
  done

  eval "unset struct_$1"

  unset _struct_undef_field_list _struct_undef_field
}
