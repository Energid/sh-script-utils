#!/usr/bin/env sh

#
# These tests have have been run successfully with the following shells:
#   - bash 5.1.4
#   - dash 0.5.11
#   - zsh 5.8
#   - mksh 59c
#   - yash 2.50
#
# They are known to fail with 'ksh' due to its lack of support
# for the 'local' keyword.
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

if [ $# -gt 0 ]; then
  TestShells="$*"
else
  TestShells=''
  for shell in dash bash zsh mksh yash; do
    if hash "$shell" 2>/dev/null; then
      TestShells="${TestShells:+${TestShells} }$shell"
    fi
  done
fi

# shellcheck disable=SC2164 # chance of `cd` failing is neglible
cd "$(dirname "$0")"

for test in ./test-*.sh; do
  for shell in $TestShells; do
    echo ''
    echo '--------------------------------'
    echo "${test#*/} ($shell)"
    echo '--------------------------------'

    if [ "$ShunitAssertBug" -eq 1 ]; then
      { "$shell" "$test" \
        | awk '/FAIL|ASSERT/ { f=1 } { print } END { if (f) {  exit 1 } }'; } \
      || exit $?
    else
      "$shell" "$test" || exit $?
    fi
  done
done
