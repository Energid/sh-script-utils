#!/usr/bin/env sh

#
# These tests have have been run successfully with the following shells:
#   - bash 5.1.4
#   - dash 0.5.11
#   - zsh 5.8
#   - mksh 59c
#
# They are known to fail with 'ksh' due to its lack of support
# for the 'local' keyword.
#

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

    "$shell" "$test" || exit $?
  done
done
