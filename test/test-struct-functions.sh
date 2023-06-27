#!/usr/bin/env sh
# shellcheck disable=SC2016 # do not warn about `$()` in single quotes

# shellcheck disable=SC2164,SC2312 # chance of `cd` failing is neglible
# shellcheck disable=SC1091 # do not follow source
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"
include ../lib/struct-functions.sh

test_struct_def() (
  assertFalse 'missing struct name' 'eval "$(struct_def)"'
  assertFalse 'missing field name' \
    'eval "$(struct_def _test_struct_def_abc)"'

  assertFalse 'empty struct name' 'eval "$(struct_def \"\" x)"'
  assertFalse 'invalid struct name' 'eval "$(struct_def \? x)"'

  assertFalse 'empty field name' \
    'eval "$(struct_def _test_struct_def_abc \"\")"'
  assertFalse 'invalid field name' \
    'eval "$(struct_def _test_struct_def_abc \?)"'

  eval "$(struct_def _test_struct_def_abc w x=1 y='x & y' z='foo=bar')"
  assertEquals 'struct member list' \
    'w x y z' "${struct__test_struct_def_abc:-}"
  assertEquals "struct member 'w'" \
    '' "${struct__test_struct_def_abc_w:-}"
  assertEquals "struct member 'x'" \
    '1' "${struct__test_struct_def_abc_x:-}"
  assertEquals "struct member 'y'" \
    'x & y' "${struct__test_struct_def_abc_y:-}"
  assertEquals "struct member 'z'" \
    'foo=bar' "${struct__test_struct_def_abc_z:-}"

  assertFalse 'struct already exists' \
    'eval "$(struct_def _test_struct_def_abc x y z)"'

  struct_undef _test_struct_def_abc

  case "$(struct_def -l abc2 w x y z)" in *"local "* ) ;; *)
    fail 'option -l not honored'
  ;; esac

  case "$(struct_def -x abc2 w x y z)" in *"export "* ) ;; *)
    fail 'option -x not honored'
  ;; esac
)

test_struct_get() {
  assertFalse 'missing struct name' struct_get
  assertFalse 'missing field name' 'struct_get _test_struct_get_abc'

  assertFalse 'empty struct name' "struct_get '' w"
  assertFalse 'invalid struct name' "struct_get '?' w"

  assertFalse 'empty field name' "struct_get _test_struct_get_abc ''"
  assertFalse 'invalid field name' "struct_get _test_struct_get_abc '?'"

  assertFalse 'extra argument' "struct_get _test_struct_get_abc x y"

  assertFalse 'non-existent struct' "struct_get _test_struct_get_abc w"

  eval "$(struct_def _test_struct_get_abc w x=1 y='x & y' z='foo=bar')"

  assertFalse 'non-existent field name' "struct_get _test_struct_get_abc d"

  assertEquals "get 'w' value" '' "$(struct_get _test_struct_get_abc w)"
  assertEquals "get 'x' value" '1' "$(struct_get _test_struct_get_abc x)"
  assertEquals "get 'y' value" 'x & y' "$(struct_get _test_struct_get_abc y)"
  assertEquals "get 'z' value" 'foo=bar' "$(struct_get _test_struct_get_abc z)"

  struct_undef _test_struct_get_abc
}

test_struct_set() {
  assertFalse 'missing struct name' struct_set
  assertFalse 'missing field name' 'struct_set _test_struct_set_abc'
  assertFalse 'missing value' 'struct_set _test_struct_set_abc x'

  assertFalse 'empty struct name' "struct_set '' x 1"
  assertFalse 'invalid struct name' "struct_set '?' x 1"

  assertFalse 'empty field name' "struct_set _test_struct_set_abc '' 1"
  assertFalse 'invalid field name' "struct_set _test_struct_set_abc '?' 1"

  assertFalse 'extra argument' "struct_set _test_struct_set_abc x 1 a"

  assertFalse 'non-existent struct' "struct_set _test_struct_set_abc x 1"

  eval "$(struct_def _test_struct_set_abc x y z)"

  assertFalse 'non-existent field name' "struct_set _test_struct_set_abc d 1"

  for _test_struct_set_value in 2 'a & b' 'near=far' ''; do
    struct_set _test_struct_set_abc x "$_test_struct_set_value"
    assertEquals "set 'x' to '$_test_struct_set_value'" \
      "$_test_struct_set_value" "$(struct_get _test_struct_set_abc x)"
  done

  struct_undef _test_struct_set_abc
  unset _test_struct_set_value
}

test_struct_exists() {
  assertFalse 'missing struct name' struct_exists
  assertFalse 'empty struct name' "struct_exists ''"
  assertFalse 'invalid struct name' "struct_exists '?'"

  assertFalse 'extra argument' "struct_exists _test_struct_exists_abc x"

  assertFalse 'struct undefined' 'struct_exists _test_struct_exists_abc'

  eval "$(struct_def _test_struct_exists_abc x y z)"

  assertTrue 'struct defined' 'struct_exists _test_struct_exists_abc'

  struct_undef _test_struct_exists_abc
}

test_struct_has() {
  assertFalse 'missing struct name' struct_has
  assertFalse 'missing field name' 'struct_has _test_struct_has_abc'

  assertFalse 'empty struct name' "struct_has '' x"
  assertFalse 'invalid struct name' "struct_has '?' x"

  assertFalse 'empty field name' "struct_has _test_struct_has_abc ''"
  assertFalse 'invalid field name' "struct_has _test_struct_has_abc '?'"

  assertFalse 'extra argument' "struct_has _test_struct_has_abc x 1"

  assertFalse 'struct undefined' 'struct_has _test_struct_has_abc x'

  eval "$(struct_def _test_struct_has_abc x y z)"

  assertFalse 'field not found' 'struct_has _test_struct_has_abc w'
  assertTrue 'field found' 'struct_has _test_struct_has_abc x'

  struct_undef _test_struct_has_abc
}

test_struct_test() {
  assertFalse 'missing struct name' struct_test
  assertFalse 'missing field name' 'struct_test _test_struct_test_abc'
  assertFalse 'missing test operator' 'struct_test _test_struct_test_abc x'
  assertFalse 'missing test value' 'struct_test _test_struct_test_abc x -eq'

  assertFalse 'empty struct name' "struct_test '' x -eq 1"
  assertFalse 'invalid struct name' "struct_test '?' x -eq 1"

  assertFalse 'empty field name' "struct_test _test_struct_test_abc '' -eq 1"
  assertFalse 'invalid field name' "struct_test _test_struct_test_abc '?' -eq 1"

  assertFalse 'empty test operator' "struct_test _test_struct_test_abc x '' 1"

  assertFalse 'extra argument' "struct_test _test_struct_test_abc x -eq 1 y"

  assertFalse 'struct undefined' 'struct_test _test_struct_test_abc x -eq 1'

  eval "$(struct_def _test_struct_test_abc x=1 y z='abc')"

  assertFalse 'field not found' 'struct_test _test_struct_test_abc w -eq 1'

  assertTrue 'x > 0' 'struct_test _test_struct_test_abc x -gt 0'
  assertTrue 'x >= 0' 'struct_test _test_struct_test_abc x -ge 0'
  assertTrue 'x == 1' 'struct_test _test_struct_test_abc x -eq 1'
  assertTrue 'x <= 2' 'struct_test _test_struct_test_abc x -le 2'
  assertTrue 'x < 2' 'struct_test _test_struct_test_abc x -lt 2'
  assertTrue 'x != 2' 'struct_test _test_struct_test_abc x -ne 2'

  assertFalse 'x < 0' 'struct_test _test_struct_test_abc x -lt 0'
  assertFalse 'x <= 0' 'struct_test _test_struct_test_abc x -le 0'
  assertFalse 'x != 1' 'struct_test _test_struct_test_abc x -ne 1'
  assertFalse 'x >= 2' 'struct_test _test_struct_test_abc x -ge 2'
  assertFalse 'x > 2' 'struct_test _test_struct_test_abc x -gt 2'
  assertFalse 'x == 2' 'struct_test _test_struct_test_abc x -eq 2'

  assertTrue 'z == "abc"' 'struct_test _test_struct_test_abc z = "abc"'
  assertTrue 'z != "def"' 'struct_test _test_struct_test_abc z != "def"'

  assertFalse 'z != "abc"' 'struct_test _test_struct_test_abc z != "abc"'
  assertFalse 'z == "def"' 'struct_test _test_struct_test_abc z = "def"'

  struct_undef _test_struct_test_abc
}

test_struct_pack() {
  assertFalse 'missing struct name' struct_pack
  assertFalse 'missing field name' 'struct_pack _test_struct_pack_abc'

  assertFalse 'empty struct name' "struct_pack '' x"
  assertFalse 'invalid struct name' "struct_pack '?' x"

  assertFalse 'empty field name' "struct_pack _test_struct_pack_abc ''"
  assertFalse 'invalid field name' "struct_pack _test_struct_pack_abc' '?'"

  assertFalse 'missing field value' "struct_pack _test_struct_pack_abc x"

  assertFalse 'non-existent struct' "struct_pack _test_struct_pack_abc x=1"

  eval "$(struct_def _test_struct_pack_abc w=1 x='a & b' y='' z='?')"

  assertFalse 'non-existent field' "struct_pack _test_struct_pack_abc v=2"

  assertTrue 'pack values' \
    "struct_pack _test_struct_pack_abc w= x=1 y='foo & bar' z='a=b'"

  struct_pack _test_struct_pack_abc w= x=1 y='foo & bar' z='a=b'
  assertEquals 'w updated' '' "$(struct_get _test_struct_pack_abc w)"
  assertEquals 'x updated' '1' "$(struct_get _test_struct_pack_abc x)"
  assertEquals 'y updated' 'foo & bar' "$(struct_get _test_struct_pack_abc y)"
  assertEquals 'z updated' 'a=b' "$(struct_get _test_struct_pack_abc z)"

  struct_undef _test_struct_pack_abc
}

test_struct_unpack() {
  assertFalse 'missing struct name' struct_unpack
  assertFalse 'missing field name' 'struct_unpack _test_struct_unpack_abc'

  assertFalse 'empty struct name' "struct_unpack '' x"
  assertFalse 'invalid struct name' "struct_unpack '?' x"

  assertFalse 'empty field name' "struct_unpack _test_struct_unpack_abc ''"
  assertFalse 'invalid field name' "struct_unpack _test_struct_unpack_abc' '?'"

  assertFalse 'empty output variable name' \
    "struct_unpack _test_struct_unpack_abc x:"
  assertFalse 'invalid output variable name' \
    "struct_unpack _test_struct_unpack_abc' 'x:?'"

  assertFalse 'non-existent struct' "struct_unpack _test_struct_unpack_abc x"

  eval "$(struct_def _test_struct_unpack_abc w=1 x='a & b' y='' z='?')"

  assertFalse 'non-existent field' "struct_unpack _test_struct_unpack_abc v"

  y=7 b=8
  struct_unpack _test_struct_unpack_abc w:a x y z:b
  assertEquals 'create output variable (same name)' 1 "${a:-}"
  assertEquals 'create output variable (alternate name)' 'a & b' "${x:-}"
  assertEquals 'update output variable (same name)' '' "$y"
  assertEquals 'update output variable (alternate name)' '?' "$b"

  struct_undef _test_struct_unpack_abc
  unset a b w x y z
}

test_struct_print() {
  assertFalse 'missing struct name' struct_print
  assertFalse 'empty struct name' "struct_print ''"
  assertFalse 'invalid struct name' "struct_print '?'"

  assertFalse 'extra argument' "struct_print _test_struct_print_abc"

  assertFalse 'struct undefined' "struct_print _test_struct_print_abc'"

  eval "$(struct_def _test_struct_print_abc w x=1 y='x & y' z='foo=bar')"

  assertEquals 'print-out' \
    "$(printf '%s\n%s\n%s\n%s\n' "w=''" 'x=1' "y='x & y'" "z=foo=bar")" \
    "$(struct_print _test_struct_print_abc)"

  struct_undef _test_struct_print_abc
}

test_struct_undef() {
  assertFalse 'missing struct name' struct_undef
  assertFalse 'empty struct name' "struct_undef ''"
  assertFalse 'invalid struct name' "struct_undef '?'"

  assertFalse 'extra argument' "struct_undef _test_struct_undef_abc x"

  assertTrue 'struct already undefined' 'struct_undef _test_struct_undef_abc'

  eval "$(struct_def _test_struct_undef_abc w x=1 y='x & y' z='foo=bar')"

  assertTrue 'undefining struct' 'struct_undef _test_struct_undef_abc'
  struct_undef _test_struct_undef_abc

  assertEquals 'struct member list' '' "${struct__test_struct_undef_abc:-}"
  assertEquals "struct member 'w'" '' "${struct__test_struct_undef_abc_w:-}"
  assertEquals "struct member 'x'" '' "${struct__test_struct_undef_abc_x:-}"
  assertEquals "struct member 'y'" '' "${struct__test_struct_undef_abc_y:-}"
  assertEquals "struct member 'z'" '' "${struct__test_struct_undef_abc_z:-}"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
