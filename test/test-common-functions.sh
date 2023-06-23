#!/usr/bin/env sh
# shellcheck disable=SC3043 # allow 'local' usage

# shellcheck disable=SC2164 # chance of `cd` failing is neglible
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/common-functions.sh"

test_is_number() {
  assertFalse 'missing argument' is_number
  assertFalse 'empty argument' is_number

  local ii=0
  for ii in $(seq 0 10); do
    assertTrue "$ii" "is_number $ii"
  done

  local c=''
  for c in \` \~ \! @ \# \$ % ^ \& \* \( \) - _ + = \{ \[ \] \} \
           \\ \| : \; \' \" \< ',' \> . \? / \
           a b c d e f g h i j k l m n o p q r s t u v w x y z \
           A B C D E F G H I J K L M N O P Q R S T U V W X Y Z
  do
    assertFalse "non-letter: $c" "is_number '$c'"
  done
}

test_is_valid_identifier() {
  assertFalse 'missing argument' is_valid_identifier
  assertFalse 'empty argument' is_valid_identifier

  assertTrue 'small letters' 'is_valid_identifier abcdefghijklmnopqrtuvwxyz'
  assertTrue 'large letters' 'is_valid_identifier ABCDEFGHIJKLMNOPQRTUVWXYZ'
  assertTrue 'trailing numbers' 'is_valid_identifier a0123456789'
  assertTrue 'underscore' 'is_valid_identifier _'

  local ii=0
  for ii in $(seq 0 10); do
    assertFalse "leading $ii" "is_valid_identifier $ii"
  done

  local c=''
  for c in \` \~ \! @ \# \$ % ^ \& \* \( \) - + = \{ \[ \] \} \
           \\ \| : \; \' \" \< ',' \> . \? /
  do
    assertFalse "special character: $c" "is_valid_identifier '$c'"
  done
}

test_replace_all() {
  assertFalse 'missing variable name' replace_all
  assertFalse 'missing key string' 'replace_all var'
  assertFalse 'missing replacement' 'replace_all var x'

  assertFalse 'empty variable name' "replace_all '' x y"
  assertFalse 'invalid variable name' "replace_all '?' x y"

  assertFalse 'empty key string' "replace_all var '' y"

  local string

  string='a.b.c.d'
  replace_all string . -
  assertEquals 'replace embedded characters' 'a-b-c-d' "$string"

  string='--abcd'
  replace_all string - +
  assertEquals 'replace leading characters' '++abcd' "$string"

  string='abcd!!'
  replace_all string '!' '?'
  assertEquals 'replace trailing characters' 'abcd??' "$string"

  string='"Where are you going?"'
  replace_all string '"' ''
  assertEquals 'remove characters' 'Where are you going?' "$string"

  string='little red dog with red ball'
  replace_all string 'red' 'blue'
  assertEquals 'replace substring' 'little blue dog with blue ball' "$string"

  unset string2
  replace_all string2 'x' 'y'
  assertEquals 'non-existent variable' '' "${string2-foobar}"
  unset string2
}

test_escape_var() {
  assertFalse 'missing variable name' escape_var
  assertFalse 'empty variable name' "escape_var ''"
  assertFalse 'invalid variable name' "escape_var '?'"

  local var=''

  var='abcdefghijklmnopqrtuvwxyz'
  escape_var var
  assertEquals 'small letters' 'abcdefghijklmnopqrtuvwxyz' "$var"

  var='ABCDEFGHIJKLMNOPQRTUVWXYZ'
  escape_var var
  assertEquals 'large letters' 'ABCDEFGHIJKLMNOPQRTUVWXYZ' "$var"

  var='0123456789'
  escape_var var
  assertEquals 'numbers' '0123456789' "$var"

  var='^-+,./:=@_'
  escape_var var
  assertEquals 'non-special characters' '^-+,./:=@_' "$var"

  var=''
  escape_var var
  assertEquals 'empty string' "''" "$var"

  local c=''
  for c in \` \~ \! \# \$ % \& \* \( \) \{ \[ \] \} \\ \| \; \" \< \> \?; do
    var=$c
    escape_var var
    assertEquals "special character: $c" "'$c'" "$var"
  done

  var="'"
  escape_var var
  assertEquals "single quote" "''\\'''" "$var"

  unset var2
  escape_var var2
  assertEquals 'non-existent variable' "''" "${var2:-}"
  unset var2
}

test_escape() {
  assertEquals 'small letters' abcdefghijklmnopqrtuvwxyz \
                               "$(escape 'abcdefghijklmnopqrtuvwxyz')"
  assertEquals 'large letters' ABCDEFGHIJKLMNOPQRTUVWXYZ \
                               "$(escape 'ABCDEFGHIJKLMNOPQRTUVWXYZ')"
  assertEquals 'numbers' 0123456789 "$(escape 0123456789)"
  assertEquals 'non-special characters' '^-+,./:=@_' "$(escape '^-+,./:=@_')"

  assertEquals 'empty string' "''" "$(escape '')"

  local c=''
  for c in \` \~ \! \# \$ % \& \* \( \) \{ \[ \] \} \\ \| \; \" \< \> \?; do
    assertEquals "special character: $c" "'$c'" "$(escape "$c")"
  done

  assertEquals "single quote" "''\\'''" "$(escape "'")"

  assertEquals "multiple args" "'How'\\''re' you 'today?'" \
                               "$(escape "How're" you 'today?')"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
