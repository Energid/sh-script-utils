# shellcheck shell=sh
# shellcheck disable=SC3043 # allow 'local' usage

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
  local scope=''
  case ${1:-} in
    -l) scope='local';  shift ;;
    -x) scope='export'; shift ;;
  esac

  if [ $# -eq 0 ]; then
    echo "echo 'missing struct name' >&2"
    echo "false"; return
  fi

  local name="$1"; shift
  if ! is_valid_identifier "$name"; then
    echo "echo \"'$name' is not a valid struct name\" >&2"
    echo "false"; return
  fi

  if [ $# -eq 0 ]; then
    echo "echo 'missing field name(s)' >&2"
    echo "false"; return
  fi

  local field=''
  local field_name=''
  local field_value=''
  local field_list=''

  for field in "$@"; do
    field_name=${field%%=*}
    if ! is_valid_identifier "$field_name"; then
      echo "echo \"'$field_name' is not a valid field name\" >&2"
      echo "false"; return
    else
      field_list="${field_list:+$field_list }$field_name"
    fi
  done

  if eval "[ \"\${struct_$name:-}\" ]"; then
    echo "echo \"the struct '$name' already exists\" >&2"
    echo "false"; return
  fi

  # store field names in 'struct_$name' variable;
  # this variable is also used to test for the structure's existence
  echo "${scope:+$scope }struct_$name='$field_list'"

  # create 'struct_$name_$field' variable for each field
  for field in "$@"; do
    field_name=${field%%=*}
    case $field in
      *=*) field_value=${field#*=} ;;
      *)   field_value=''          ;;
    esac

    escape_var field_value
    echo "${scope:+$scope }struct_${name}_${field_name}=$field_value"
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
  local name="${1:?missing struct name}"
  local field="${2:?missing field name}"

  local extra_args=''; [ $# -eq 2 ] || : "${extra_args:?extra argument(s)}"

  local arg; for arg in "$@"; do
    if ! is_valid_identifier "$arg"; then
      echo "'$arg' is not a valid identifier" >&2
      return 2
    fi
  done

  local error_msg="no struct exists with name \\'$name\\' and field \\'$field\\'"

  # read 'struct_$name_$field' variable
  eval "echo \"\${struct_${name}_$field?$error_msg}\""
}

#
# Usage: struct_get STRUCT_NAME FIELD_NAME VALUE
#
# Assign VALUE to field with FIELD_NAME in structure with STRUCT_NAME.
#
# Report error and exit (non-interactive) shell if there is no such structure or field.
#
struct_set() {
  local name="${1:?missing struct name}"
  local field="${2:?missing field name}"
  local value="${3?missing field value}"

  local extra_args=''; [ $# -eq 3 ] || : "${extra_args:?extra argument(s)}"

  local arg; for arg in "$name" "$field"; do
    if ! is_valid_identifier "$arg"; then
      echo "'$arg' is not a valid identifier" >&2
      return 2
    fi
  done

  # assert 'struct_$name_$field' exists
  local error_msg="no struct exists with name \\'$name\\' and field \\'$field\\'"
  eval ": \"\${struct_${name}_$field?$error_msg}\"" || return $?

  # set 'struct_$name_$field' variable
  eval "struct_${name}_$field=\$value"
}

#
# Usage: struct_exists STRUCT_NAME
#
# Return success is a structure exists with STRUCT_NAME; else return failure.
#
struct_exists() {
  local name="${1:?missing struct name}"

  local extra_args=''; [ $# -eq 1 ] || : "${extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$name"; then
    echo "'$name' is not a valid identifier" >&2
    return 2
  fi

  eval "test \"\${struct_$name:-}\""
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
  local name="${1:?missing struct name}"
  local field="${2:?missing field name}"

  local extra_args=''; [ $# -eq 2 ] || : "${extra_args:?extra argument(s)}"

  local arg; for arg in "$name" "$field"; do
    if ! is_valid_identifier "$arg"; then
      echo "'$arg' is not a valid identifier" >&2
      return 2
    fi
  done

  local error_msg="no struct exists with name \\'$name\\'"

  eval "local field_list=\"\${struct_$name?$error_msg}\""

  case " $field_list " in
    *" $field "*) true ;;
    *)           false ;;
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
  local name="${1:?missing struct name}"
  local field="${2:?missing field name}"
  local op="${3:?missing test operator}"
  local value="${4?missing test value}"

  local extra_args=''; [ $# -eq 4 ] || : "${extra_args:?extra argument(s)}"

  local arg; for arg in "$name" "$field"; do
    if ! is_valid_identifier "$arg"; then
      echo "'$arg' is not a valid identifier" >&2
      return 2
    fi
  done

  local error_msg="no struct exists with name \\'$name\\' and field \\'$field\\'"

  eval "local actual_value=\"\${struct_${name}_$field?$error_msg}\""

  # shellcheck disable=SC2154 # actual_value set by `eval` above
  test "$actual_value" "$op" "$value"
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
# Implementation Notes:
#   The reason all local variables in this function are prefixed with
#   `_struct_unpack_` is to reduce the likelihood of one of the local
#   variables having the same name as an output variable and thus
#   the output variable from being created/updated on function completion.
#
struct_unpack() {
  local _struct_unpack_name="${1:?missing struct name}"; shift

  if [ $# -eq 0 ]; then
    echo "missing field name(s)" >&2
    return 2
  fi

  if ! is_valid_identifier "$_struct_unpack_name"; then
    echo "'$_struct_unpack_name' is not a valid struct name" >&2
    return 2
  fi

  local _struct_unpack_field=''
  local _struct_unpack_field_name=''
  local _struct_unpack_field_dest=''

  for _struct_unpack_field in "$@"; do
    _struct_unpack_field_name=${_struct_unpack_field%%:*}
    if ! is_valid_identifier "$_struct_unpack_field_name"; then
      echo "'$_struct_unpack_field_name' is not a valid field name" >&2
      return 2
    fi

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

  eval "local _struct_unpack_field_list=\"\${struct_$_struct_unpack_name:-}\""
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
  local name="${1:?missing struct name}"

  local extra_args=''; [ $# -eq 1 ] || : "${extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$name"; then
    echo "'$name' is not a valid identifier" >&2
    return 2
  fi

  eval "local field_list=\"\${struct_$name:-}\""
  if [ ! "$field_list" ]; then
    echo "there is no struct named '$name'" >&2
    return 2
  fi

  # print each 'struct_$name_$field' variable
  local field=''
  local value=''
  for field in $field_list; do
    eval "value=\"\${struct_${name}_$field}\""

    escape_var value
    echo "$field=$value"
  done
}

#
# Usage: struct_undef STRUCT_NAME
#
# Delete structure with STRUCT_NAME.
#
# Do nothing if there is no such structure.
#
struct_undef() {
  local name="${1:?missing struct name}"

  local extra_args=''; [ $# -eq 1 ] || : "${extra_args:?extra argument(s)}"

  if ! is_valid_identifier "$name"; then
    echo "'$name' is not a valid identifier" >&2
    return 2
  fi

  eval "local field_list=\"\${struct_$name:-}\""
  if [ ! "$field_list" ]; then
    return 0
  fi

  local field; for field in $field_list; do
    eval "unset struct_${name}_$field"
  done

  eval "unset struct_$name"
}
