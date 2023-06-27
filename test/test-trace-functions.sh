#!/usr/bin/env sh

# shellcheck disable=SC2164,SC2312 # chance of `cd` failing is neglible
# shellcheck disable=SC1091 # do not follow source
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"
include ../lib/trace-functions.sh

test_print_banner() {
  assertFalse 'missing arguments' print_banner
  assertFalse 'empty arguments' "print_banner ''"

  case "$(print_banner hello world)" in *"HELLO WORLD"*) ;; *)
    failure 'normal run'
  ;; esac

  assertEquals 'dry run' \
    "$(printf '\n%s\n' '# hello world')" \
    "$(DRY_RUN=1 print_banner hello world)"
}

test_run() {
  assertFalse 'missing arguments' 'run'
  assertFalse 'empty argument' "run ''"

  assertEquals 'normal run output' \
    "yes no" \
    "$(run echo yes no)"
  assertTrue 'normal run success' 'run true'
  assertFalse 'normal run failure' 'run false'

  assertEquals 'eval run output' \
    'Hello World!' \
    "$(run -e 'if true; then echo "Hello World!"; fi')"
  assertTrue 'eval run success' 'run -e "false || true"'
  assertFalse 'eval run failure' 'run -e "true && false"'

  assertEquals 'normal dry run output' \
    "echo That will cost you '\$100.'" \
    "$(DRY_RUN=1 run echo That will cost you \$100.)"

  assertEquals 'eval dry run output' \
    'if true; then echo "Hello World!"; fi' \
    "$(DRY_RUN=1 run -e 'if true; then echo "Hello World!"; fi')"

  assertEquals "normal output with '-n'" \
    '' \
    "$(run -n echo That will cost you \$100.)"
  assertEquals "normal dry run output with '-n'" \
    "echo That will cost you '\$100.'" \
    "$(DRY_RUN=1 run -n echo That will cost you \$100.)"

  assertEquals "eval output with '-n'" \
    '' \
    "$(run -n -e 'if true; then echo "Hello World!"; fi')"
  assertEquals "eval dry run output with '-n'" \
    'if true; then echo "Hello World!"; fi' \
    "$(DRY_RUN=1 run -n -e 'if true; then echo "Hello World!"; fi')"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
