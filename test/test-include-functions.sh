#!/usr/bin/env sh
# shellcheck disable=SC3043 # allow 'local' usage

# shellcheck disable=SC2164 # chance of `cd` failing is neglible
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"

test_include() {
  assertFalse 'missing argument' include
  assertFalse 'empty argument' "include ''"

  local script_dir
  script_dir=$(cd -- "$(dirname "$0")"; pwd)

  include "$script_dir/example-lib-1.sh"
  assertEquals 'EXAMPLE_LIB_1_SOURCE (absolute path)' \
    "$script_dir/example-lib-1.sh" \
    "${EXAMPLE_LIB_1_SOURCE:-}"
  assertEquals 'EXAMPLE_LIB_2_SOURCE (absolute path)' \
    "$script_dir/example-lib-2.sh" \
    "${EXAMPLE_LIB_2_SOURCE:-}"
  assertEquals 'empty INCLUDE_SOURCE (absolute path)' \
    '' \
    "${INCLUDE_SOURCE:-}"

  cd /
  unset EXAMPLE_LIB_1_SOURCE EXAMPLE_LIB_2_SOURCE
  include example-lib-1.sh
  assertEquals 'EXAMPLE_LIB_1_SOURCE (relative path)' \
    "$script_dir/example-lib-1.sh" \
    "${EXAMPLE_LIB_1_SOURCE:-}"
  assertEquals 'EXAMPLE_LIB_2_SOURCE (relative path)' \
    "$script_dir/example-lib-2.sh" \
    "${EXAMPLE_LIB_2_SOURCE:-}"
  assertEquals 'empty INCLUDE_SOURCE (relative path)' \
    '' \
    "${INCLUDE_SOURCE:-}"
  cd "$OLDPWD"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
