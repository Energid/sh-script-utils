#!/usr/bin/env sh

# shellcheck disable=SC2164,SC2312 # chance of `cd` failing is negligible
# shellcheck disable=SC1091 # do not follow source
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"

test_include() {
  assertFalse 'missing argument' include
  assertFalse 'empty argument' "include ''"

  assertFalse 'extra argument' "include x y"

  # shellcheck disable=SC2154 # INCLUDE_ROOT set by include-function.sh
  assertFalse "source include-function.sh' twice" \
    ". '$INCLUDE_ROOT/../lib/include-function.sh'"

  _test_include_script_dir=$(cd -- "$(dirname "${ZSH_ARGZERO:-$0}")"; pwd)

  (
    include "$_test_include_script_dir/example-lib-1.sh"
    assertEquals 'EXAMPLE_LIB_1_SOURCE (absolute path)' \
      "$_test_include_script_dir/example-lib-1.sh" \
      "${EXAMPLE_LIB_1_SOURCE:-}"
    assertEquals 'EXAMPLE_LIB_2_SOURCE (absolute path)' \
      "$_test_include_script_dir/example-lib-2.sh" \
      "${EXAMPLE_LIB_2_SOURCE:-}"
    assertEquals 'empty INCLUDE_SOURCE (absolute path)' \
      '' \
      "${INCLUDE_SOURCE:-}"
  )

  (
    cd /
    include example-lib-1.sh
    assertEquals 'EXAMPLE_LIB_1_SOURCE (relative path)' \
      "$_test_include_script_dir/example-lib-1.sh" \
      "${EXAMPLE_LIB_1_SOURCE:-}"
    assertEquals 'EXAMPLE_LIB_2_SOURCE (relative path)' \
      "$_test_include_script_dir/example-lib-2.sh" \
      "${EXAMPLE_LIB_2_SOURCE:-}"
    assertEquals 'empty INCLUDE_SOURCE (relative path)' \
      '' \
      "${INCLUDE_SOURCE:-}"
  )

  (
    include example-lib-1.sh
    EXAMPLE_LIB_1_SOURCE='overwritten'
    include example-lib-1.sh
    assertEquals 'double inclusion prevented' \
      'overwritten' "${EXAMPLE_LIB_1_SOURCE}"
  )

  unset _test_include_script_dir
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
