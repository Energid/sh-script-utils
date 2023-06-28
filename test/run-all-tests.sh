#!/usr/bin/env sh

#
# Usage: ./run-all-tests.sh [-f FILE]... [SHELL]...
#
# Run all test FILEs with given SHELLs.
# 
# If FILEs are omitted, then all 'test-*.sh' files in the same folder
# as this script will be executed. If SHELLs are omitted, then each
# of the shells supported by the unit tests in the same folder as
# this script will be used (if the shell is installed).
#
# The tests have have been run successfully with the following shells:
#   - busybox 1.30.1
#   - dash 0.5.11
#   - bash 5.1.4
#   - zsh 5.8
#   - ksh 93u+
#   - mksh 59c
#   - yash 2.50
#
# The 'get_long_opts' tests are known to fail with 'posh' (v0.14.1) due
# to its lack of support for the '-' character in the `getopts` option string.
#

if ! hash shunit2 2>/dev/null; then
  echo "ERROR: Need to install 'shunit2' and/or add it to PATH." >&2
  exit 1
fi

# Versions of `shunit2` prior to 2.1.8 did not report "FAIL" when
# one or more assertions failed within a unit test.
ShunitAssertBug=$(
  # shellcheck disable=SC2312 # shunit2 existence already verified by `hash`
  SHUNIT_VERSION=$(grep '^SHUNIT_VERSION=' "$(command -v shunit2)" \
                   | cut -d= -f2 | tr -d '"'\''"')

  IFS='.'
  # shellcheck disable=SC2086 # intentional word-splitting
  set ${SHUNIT_VERSION}

  test "${1:-0}" -gt 2 \
     || { test "${1:-0}" -eq 2 \
          && { test "${2:-0}" -gt 1 \
               || { test "${2:-0}" -eq 1 \
                    && test "${3:-0}" -ge 8; }; }; }
  echo $?
)

TestFiles=''
TestShells=''
while [ $# -gt 0 ]; do
  case $1 in
    -f) TestFiles="${TestFiles:+${TestFiles} }${2:?option '-f' requires an argument}"
        shift 2
        ;;
     *) TestShells="${TestShells:+${TestShells} }$1"
        shift 1
        ;;
  esac
done

if [ ! "$TestFiles" ]; then
  TestFiles=$(echo "$(dirname "$0")"/test-*.sh)
fi

if [ ! "$TestShells" ]; then
  for shell in busybox dash bash zsh ksh mksh yash; do
    if hash "$shell" 2>/dev/null; then
      TestShells="${TestShells:+${TestShells} }$shell"
    fi
  done
fi

for test in $TestFiles; do
  for shell in $TestShells; do
    echo ''
    echo '--------------------------------'
    echo "${test#*/} ($shell)"
    echo '--------------------------------'

    if [ "$shell" = busybox ]; then
      shell='busybox sh'
    fi

    if [ "$ShunitAssertBug" -eq 1 ]; then
      { $shell "$test" \
        | awk '/FAIL|ASSERT/ { f=1 } { print } END { if (f) {  exit 1 } }'; } \
      || exit $?
    else
      $shell "$test" || exit $?
    fi
  done
done
