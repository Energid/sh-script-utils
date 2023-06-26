#!/usr/bin/env sh

# shellcheck disable=SC2164,SC2312 # chance of `cd` failing is neglible
# shellcheck disable=SC1091 # do not follow source
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/common-functions.sh"

test_is_number() {
  assertFalse 'missing argument' is_number
  assertFalse 'empty argument' is_number

  assertFalse 'extra argument' 'is_number 1 1'

  for _test_is_number_ii in $(seq 0 10); do
    assertTrue "$_test_is_number_ii" "is_number $_test_is_number_ii"
  done

  _test_is_number_c=''
  for _test_is_number_c in \
    \` \~ \! @ \# \$ % ^ \& \* \( \) - _ + = \{ \[ \] \} \
    \\ \| : \; \' \" \< ',' \> . \? / \
    a b _test_is_number_c d e f g h i j k l m n o p q r s t u v w x y z \
    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
  do
    assertFalse "non-letter: $_test_is_number_c" \
      "is_number \\$_test_is_number_c"
  done

  unset _test_is_number_c _test_is_number_ii
}

test_is_valid_identifier() {
  assertFalse 'missing argument' is_valid_identifier
  assertFalse 'empty argument' is_valid_identifier

  assertFalse 'extra argument' 'is_valid_identifier x y'

  assertTrue 'small letters' 'is_valid_identifier abcdefghijklmnopqrtuvwxyz'
  assertTrue 'large letters' 'is_valid_identifier ABCDEFGHIJKLMNOPQRTUVWXYZ'
  assertTrue 'trailing numbers' 'is_valid_identifier a0123456789'
  assertTrue 'underscore' 'is_valid_identifier _'

  _test_is_valid_id_ii=0
  for _test_is_valid_id_ii in $(seq 0 10); do
    assertFalse "leading $_test_is_valid_id_ii" \
      "is_valid_identifier $_test_is_valid_id_ii"
  done

  for _test_is_valid_id_c in \
    \` \~ \! @ \# \$ % ^ \& \* \( \) - + = \{ \[ \] \} \
    \\ \| : \; \' \" \< ',' \> . \? /
  do
    assertFalse "special character: $_test_is_valid_id_c" \
      "is_valid_identifier \\$_test_is_valid_id_c"
  done

  unset _test_is_valid_id_c _test_is_valid_id_ii
}

test_replace_all() {
  assertFalse 'missing variable name' replace_all
  assertFalse 'missing key string' 'replace_all var'
  assertFalse 'missing replacement' 'replace_all var x'

  assertFalse 'empty variable name' "replace_all '' x y"
  assertFalse 'invalid variable name' "replace_all '?' x y"

  assertFalse 'empty key string' "replace_all var '' y"

  assertFalse 'extra argument' 'replace_all w x y z'

  _test_replace_all_string='a.b.c.d'
  replace_all _test_replace_all_string . -
  assertEquals 'replace embedded characters' \
    'a-b-c-d' "$_test_replace_all_string"

  _test_replace_all_string='--abcd'
  replace_all _test_replace_all_string - +
  assertEquals 'replace leading characters' \
    '++abcd' "$_test_replace_all_string"

  _test_replace_all_string='abcd!!'
  replace_all _test_replace_all_string '!' '?'
  assertEquals 'replace trailing characters' \
    'abcd??' "$_test_replace_all_string"

  _test_replace_all_string='"Where are you going?"'
  replace_all _test_replace_all_string '"' ''
  assertEquals 'remove characters' \
    'Where are you going?' "$_test_replace_all_string"

  _test_replace_all_string='little red dog with red ball'
  replace_all _test_replace_all_string 'red' 'blue'
  assertEquals 'replace substring' \
    'little blue dog with blue ball' "$_test_replace_all_string"

  replace_all _test_replace_all_string2 'x' 'y'
  assertEquals 'non-existent variable' \
    '' "${_test_replace_all_string2-foobar}"

  unset _test_replace_all_string _test_replace_all_string2
}

test_escape_var() {
  assertFalse 'missing variable name' escape_var
  assertFalse 'empty variable name' "escape_var ''"
  assertFalse 'invalid variable name' "escape_var '?'"

  assertFalse 'extra argument' "escape_var x y"

  _test_escape_var_var='abcdefghijklmnopqrtuvwxyz'
  escape_var _test_escape_var_var
  assertEquals 'small letters' \
    'abcdefghijklmnopqrtuvwxyz' "$_test_escape_var_var"

  _test_escape_var_var='ABCDEFGHIJKLMNOPQRTUVWXYZ'
  escape_var _test_escape_var_var
  assertEquals 'large letters' \
    'ABCDEFGHIJKLMNOPQRTUVWXYZ' "$_test_escape_var_var"

  _test_escape_var_var='0123456789'
  escape_var _test_escape_var_var
  assertEquals 'numbers' \
    '0123456789' "$_test_escape_var_var"

  _test_escape_var_var='^-+,./:=@_'
  escape_var _test_escape_var_var
  assertEquals 'non-special characters' \
    '^-+,./:=@_' "$_test_escape_var_var"

  _test_escape_var_var=''
  escape_var _test_escape_var_var
  assertEquals 'empty string' \
    "''" "$_test_escape_var_var"

  for _test_escape_var_c in \
    \` \~ \! \# \$ % \& \* \( \) \{ \[ \] \} \\ \| \; \" \< \> \?
  do
    _test_escape_var_var=$_test_escape_var_c
    escape_var _test_escape_var_var
    assertEquals "special character: $_test_escape_var_c" \
      "'$_test_escape_var_c'" "$_test_escape_var_var"
  done

  _test_escape_var_var="'"
  escape_var _test_escape_var_var
  assertEquals "single quote" "''\\'''" "$_test_escape_var_var"

  escape_var _test_escape_var_var2
  assertEquals 'non-existent variable' "''" "${_test_escape_var_var2:-}"

  unset _test_escape_var_var _test_escape_var_c _test_escape_var_var2
}

test_escape() {
  assertEquals 'small letters' abcdefghijklmnopqrtuvwxyz \
                               "$(escape 'abcdefghijklmnopqrtuvwxyz')"
  assertEquals 'large letters' ABCDEFGHIJKLMNOPQRTUVWXYZ \
                               "$(escape 'ABCDEFGHIJKLMNOPQRTUVWXYZ')"
  assertEquals 'numbers' 0123456789 "$(escape 0123456789)"
  assertEquals 'non-special characters' '^-+,./:=@_' "$(escape '^-+,./:=@_')"

  assertEquals 'empty string' "''" "$(escape '')"

  for _test_escape_c in \
    \` \~ \! \# \$ % \& \* \( \) \{ \[ \] \} \\ \| \; \" \< \> \?
  do
    assertEquals "special character: $_test_escape_c" \
      "'$_test_escape_c'" "$(escape "$_test_escape_c")"
  done

  assertEquals "single quote" "''\\'''" "$(escape "'")"

  assertEquals "multiple args" "'How'\\''re' you 'today?'" \
                               "$(escape "How're" you 'today?')"

  unset _test_escape_c
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
