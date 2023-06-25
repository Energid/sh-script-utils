#!/usr/bin/env sh
# shellcheck disable=SC3043 # allow 'local' usage

# shellcheck disable=SC2164 # chance of `cd` failing is neglible
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"
include ../lib/struct-functions.sh

test_struct_def() (
  assertFalse 'missing struct name' 'eval "$(struct_def)"'
  assertFalse 'missing field name' 'eval "$(struct_def abc)"'

  assertFalse 'empty struct name' 'eval "$(struct_def \"\" x)"'
  assertFalse 'invalid struct name' 'eval "$(struct_def \? x)"'

  assertFalse 'empty field name' 'eval "$(struct_def abc \"\")"'
  assertFalse 'invalid field name' 'eval "$(struct_def abc \?)"'

  eval "$(struct_def abc w x=1 y='x & y' z='foo=bar')"
  assertEquals 'struct member list' 'w x y z' "${struct_abc:-}"
  assertEquals "struct member 'w'" '' "${struct_abc_w:-}"
  assertEquals "struct member 'x'" '1' "${struct_abc_x:-}"
  assertEquals "struct member 'y'" 'x & y' "${struct_abc_y:-}"
  assertEquals "struct member 'z'" 'foo=bar' "${struct_abc_z:-}"

  assertFalse 'struct already exists' 'eval "$(struct_def abc x y z)"'

  case "$(struct_def -l abc2 w x y z)" in *"local "* ) ;; *)
    fail 'option -l not honored'
  ;; esac

  case "$(struct_def -x abc2 w x y z)" in *"export "* ) ;; *)
    fail 'option -x not honored'
  ;; esac
)

test_struct_get() {
  assertFalse 'missing struct name' struct_get
  assertFalse 'missing field name' 'struct_get abc'

  assertFalse 'empty struct name' "struct_get '' w"
  assertFalse 'invalid struct name' "struct_get '?' w"

  assertFalse 'empty field name' "struct_get abc ''"
  assertFalse 'invalid field name' "struct_get abc '?'"

  assertFalse 'extra argument' "struct_get abc x y"

  assertFalse 'non-existent struct' "struct_get abc w"

  eval "$(struct_def -l abc w x=1 y='x & y' z='foo=bar')"

  assertFalse 'non-existent field name' "struct_get abc d"

  assertEquals "get 'w' value" '' "$(struct_get abc w)"
  assertEquals "get 'x' value" '1' "$(struct_get abc x)"
  assertEquals "get 'y' value" 'x & y' "$(struct_get abc y)"
  assertEquals "get 'z' value" 'foo=bar' "$(struct_get abc z)"
}

test_struct_set() {
  assertFalse 'missing struct name' struct_set
  assertFalse 'missing field name' 'struct_set abc'
  assertFalse 'missing value' 'struct_set abc x'

  assertFalse 'empty struct name' "struct_set '' x 1"
  assertFalse 'invalid struct name' "struct_set '?' x 1"

  assertFalse 'empty field name' "struct_set abc '' 1"
  assertFalse 'invalid field name' "struct_set abc '?' 1"

  assertFalse 'extra argument' "struct_set abc x 1 a"

  assertFalse 'non-existent struct' "struct_set abc x 1"

  eval "$(struct_def -l abc x y z)"

  assertFalse 'non-existent field name' "struct_set abc d 1"

  local test_value
  for test_value in 2 'a & b' 'near=far' ''; do
    struct_set abc x "$test_value"
    assertEquals "set 'x' to '$test_value'" \
      "$test_value" "$(struct_get abc x)"
  done
}

test_struct_exists() {
  assertFalse 'missing struct name' struct_exists
  assertFalse 'empty struct name' "struct_exists ''"
  assertFalse 'invalid struct name' "struct_exists '?'"

  assertFalse 'extra argument' "struct_exists abc x"

  assertFalse 'struct undefined' 'struct_exists abc'

  eval "$(struct_def -l abc x y z)"

  assertTrue 'struct defined' 'struct_exists abc'
}

test_struct_has() {
  assertFalse 'missing struct name' struct_has
  assertFalse 'missing field name' 'struct_has abc'

  assertFalse 'empty struct name' "struct_has '' x"
  assertFalse 'invalid struct name' "struct_has '?' x"

  assertFalse 'empty field name' "struct_has abc ''"
  assertFalse 'invalid field name' "struct_has abc '?'"

  assertFalse 'extra argument' "struct_has abc x 1"

  assertFalse 'struct undefined' 'struct_has abc x'

  eval "$(struct_def -l abc x y z)"

  assertFalse 'field not found' 'struct_has abc w'
  assertTrue 'field found' 'struct_has abc x'
}

test_struct_test() {
  assertFalse 'missing struct name' struct_test
  assertFalse 'missing field name' 'struct_test abc'
  assertFalse 'missing test operator' 'struct_test abc x'
  assertFalse 'missing test value' 'struct_test abc x -eq'

  assertFalse 'empty struct name' "struct_test '' x -eq 1"
  assertFalse 'invalid struct name' "struct_test '?' x -eq 1"

  assertFalse 'empty field name' "struct_test abc '' -eq 1"
  assertFalse 'invalid field name' "struct_test abc '?' -eq 1"

  assertFalse 'empty test operator' "struct_test abc x '' 1"

  assertFalse 'extra argument' "struct_test abc x -eq 1 y"

  assertFalse 'struct undefined' 'struct_test abc x -eq 1'

  eval "$(struct_def -l abc x=1 y z='abc')"

  assertFalse 'field not found' 'struct_test abc w -eq 1'

  assertTrue 'x > 0' 'struct_test abc x -gt 0'
  assertTrue 'x >= 0' 'struct_test abc x -ge 0'
  assertTrue 'x == 1' 'struct_test abc x -eq 1'
  assertTrue 'x <= 2' 'struct_test abc x -le 2'
  assertTrue 'x < 2' 'struct_test abc x -lt 2'
  assertTrue 'x != 2' 'struct_test abc x -ne 2'

  assertFalse 'x < 0' 'struct_test abc x -lt 0'
  assertFalse 'x <= 0' 'struct_test abc x -le 0'
  assertFalse 'x != 1' 'struct_test abc x -ne 1'
  assertFalse 'x >= 2' 'struct_test abc x -ge 2'
  assertFalse 'x > 2' 'struct_test abc x -gt 2'
  assertFalse 'x == 2' 'struct_test abc x -eq 2'

  assertTrue 'z == "abc"' 'struct_test abc z = "abc"'
  assertTrue 'z != "def"' 'struct_test abc z != "def"'

  assertFalse 'z != "abc"' 'struct_test abc z != "abc"'
  assertFalse 'z == "def"' 'struct_test abc z = "def"'
}

test_struct_print() {
  assertFalse 'missing struct name' struct_print
  assertFalse 'empty struct name' "struct_print ''"
  assertFalse 'invalid struct name' "struct_print '?'"

  assertFalse 'extra argument' "struct_print abc"

  assertFalse 'struct undefined' "struct_print abc'"

  eval "$(struct_def -l abc w x=1 y='x & y' z='foo=bar')"

  assertEquals 'print-out' \
    "$(printf '%s\n%s\n%s\n%s\n' "w=''" 'x=1' "y='x & y'" "z=foo=bar")" \
    "$(struct_print abc)"
}

test_struct_unpack() {
  assertFalse 'missing struct name' struct_unpack
  assertFalse 'missing field name' 'struct_unpack abc'

  assertFalse 'empty struct name' "struct_unpack '' x"
  assertFalse 'invalid struct name' "struct_unpack '?' x"

  assertFalse 'empty field name' "struct_unpack abc ''"
  assertFalse 'invalid field name' "struct_unpack abc' '?'"

  assertFalse 'empty output variable name' "struct_unpack abc x:"
  assertFalse 'invalid output variable name' "struct_unpack abc' 'x:?'"

  assertFalse 'non-existent struct' "struct_unpack abc x"

  eval "$(struct_def -l abc w=1 x='a & b' y='' z='?')"

  assertFalse 'non-existent field' "struct_unpack abc v"

  local y=7 b=8
  struct_unpack abc w:a x y z:b
  assertEquals 'create output variable (same name)' 1 "${a:-}"
  assertEquals 'create output variable (alternate name)' 'a & b' "${x:-}"
  assertEquals 'update output variable (same name)' '' "$y"
  assertEquals 'update output variable (alternate name)' '?' "$b"
}

test_struct_undef() {
  assertFalse 'missing struct name' struct_undef
  assertFalse 'empty struct name' "struct_undef ''"
  assertFalse 'invalid struct name' "struct_undef '?'"

  assertFalse 'extra argument' "struct_undef abc x"

  assertTrue 'struct already undefined' 'struct_undef abc'

  eval "$(struct_def -l abc w x=1 y='x & y' z='foo=bar')"

  assertTrue 'undefining struct' 'struct_undef abc'
  struct_undef abc

  assertEquals 'struct member list' '' "${struct_abc:-}"
  assertEquals "struct member 'w'" '' "${struct_abc_w:-}"
  assertEquals "struct member 'x'" '' "${struct_abc_x:-}"
  assertEquals "struct member 'y'" '' "${struct_abc_y:-}"
  assertEquals "struct member 'z'" '' "${struct_abc_z:-}"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
