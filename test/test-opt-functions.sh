#!/usr/bin/env sh
# shellcheck disable=SC3043 # allow 'local' usage

# shellcheck disable=SC2164 # chance of `cd` failing is neglible
. "$(cd -- "$(dirname "$0")"; pwd)/../lib/include-function.sh"
include ../lib/opt-functions.sh

test_build_opt_specs() {
  assertFalse 'missing short-opt spec name' build_opt_specs
  assertFalse 'empty short-opt spec name' "build_opt_specs ''"
  assertFalse 'invalid short-opt spec name' "build_opt_specs '?'"

  assertFalse 'missing medium-opt spec name' 'build_opt_specs -m'
  assertFalse 'empty medium-opt spec name' "build_opt_specs -m ''"
  assertFalse 'invalid medium-opt spec name' "build_opt_specs -m '!'"

  assertFalse 'missing long-opt spec name' 'build_opt_specs -l'
  assertFalse 'empty long-opt spec name' "build_opt_specs -l ''"
  assertFalse 'invalid long-opt spec name' "build_opt_specs -l '.'"

  local short_opts='' medium_opts='' long_opts='' c=''
  local common_illegal_chars='
    ` ~ ! @ # $ % ^ & _ + = { } | : ; '\'' " < , > . /
  '

  for c in $common_illegal_chars \* \? \[ \] \( \) -; do
    assertFalse "invalid short option: $c" \
      "build_opt_specs short_opts '$c'"
  done

  for c in $common_illegal_chars \* \? \[ \] \) -; do
    assertFalse "invalid medium option: x$c:" \
      "build_opt_specs -m medium_opts short_opts 'x$c:'"
  done

  assertFalse "empty long option" \
    "build_opt_specs -l long_opts short_opts '()'"

  for c in $common_illegal_chars \* \? \[ \] \(; do
    assertFalse "invalid long option: ($c)" \
      "build_opt_specs -l long_opts short_opts '($c)'"
  done

  assertFalse "short option and empty long option" \
    "build_opt_specs -l long_opts short_opts 'x()'"

  for c in $common_illegal_chars \* \? \[ \] \) -; do
    assertFalse "invalid short option and long option: $c(x)" \
      "build_opt_specs short_opts '$c(x)'"
  done

  for c in $common_illegal_chars \* \? \[ \] \(; do
    assertFalse "short option and invalid long option: x($c)" \
      "build_opt_specs -l long_opts short_opts 'x($c)'"
  done

  assertFalse "medium option and empty long option" \
    "build_opt_specs -m medium_opts medium_opts 'xy()'"

  for c in $common_illegal_chars \* \? \[ \] \) -; do
    assertFalse "invalid medium option and long option: x$c(a)" \
      "build_opt_specs -m medium_opts short_opts 'x$c(a)'"
  done

  for c in $common_illegal_chars \* \? \[ \] \(; do
    assertFalse "medium option and invalid long option: xy($c)" \
      "build_opt_specs -m medium_opts short_opts 'xy($c)'"
  done

  assertFalse 'missing -m option' "build_opt_specs short_opts 'xy'"
  assertFalse 'missing -l option' "build_opt_specs short_opts '(abc)'"

  build_opt_specs short_opts \
    a b: c d: e f: g h: i j: k l: m n: o p: q r: s t: u v: w x: y z: \
    0: 1 2: 3 4: 5 6: 7 8: 9
  assertEquals 'only short opts' \
    ':ab:cd:ef:gh:ij:kl:mn:op:qr:st:uv:wx:yz:0:12:34:56:78:9' \
    "$short_opts"

  build_opt_specs -m medium_opts short_opts \
    ab: cd ef: gh ij: kl mn: op qr: st uv: wx yz: \
    012: 345 6789:
  assertEquals 'no short opts (medium opts)' \
    ':' "$short_opts"
  assertEquals 'only medium opts' \
    'ab: cd ef: gh ij: kl mn: op qr: st uv: wx yz: 012: 345 6789:' \
    "$medium_opts"

  build_opt_specs -l long_opts short_opts \
    '(ab-cd)' '(ef-gh):' '(ij-kl)' '(mn-op):' '(qr-st)' '(uv-wx):' '(yz)' \
    '(-012):' '(345-678)' '(9):'
  assertEquals 'no short opts (long opts)' \
    ':-:' "$short_opts"
  assertEquals 'only long opts' \
    'ab-cd ef-gh: ij-kl mn-op: qr-st uv-wx: yz -012: 345-678 9:' \
    "$long_opts"

  build_opt_specs -l long_opts -m medium_opts short_opts \
    a 0: ab 12: '(abc-def)' '(123-456):' 'b(12-34)' '1(ab-cd):' 'cd(34-56)' '34(cd-ef):'
  assertEquals 'short opts (mixed in)' \
    ':a0:b1:-:' "$short_opts"
  assertEquals 'medium opts (mixed in)' \
    'ab 12: cd 34:' "$medium_opts"
  assertEquals 'long opts (mixed in)' \
    'abc-def 123-456: 12-34 ab-cd: 34-56 cd-ef:' "$long_opts"
}

test_get_medium_opts() {
  assertFalse 'missing option specification' 'eval "$(get_medium_opts)"'
  assertFalse 'missing OPTIND value' 'eval "$(get_medium_opts "ab")"'
  assertFalse 'missing output variable name' 'eval "$(get_medium_opts "ab" 1)"'


  assertFalse 'empty option specification' 'eval "$(get_medium_opts "" 1 opt)"'

  assertFalse 'empty OPTIND value' 'eval "$(get_medium_opts "ab" "" opt)"'
  assertFalse 'invalid OPTIND value' 'eval "$(get_medium_opts "ab" "?" opt)"'

  assertFalse 'empty output variable name' 'eval "$(get_medium_opts "ab" 1 "")"'
  assertFalse 'invalid output variable name' 'eval "$(get_medium_opts "ab" 1 "?")"'

  local medium_opts='ab cd:'
  local opt=''

  assertFalse 'no arguments' \
    "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt)\""

  (
    OPTIND=1
    assertFalse 'non-option argument' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt x)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt x)"
    assertEquals 1 "$OPTIND"
  )

  (
    OPTIND=1
    assertFalse 'short argument' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -x)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -x)"
    assertEquals 1 "$OPTIND"
  )

  (
    OPTIND=1
    assertFalse 'long argument' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt --xy)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt --xy)"
    assertEquals 1 "$OPTIND"
  )

  (
    OPTIND=1
    assertFalse 'unrecognized medium argument' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -xy)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -xy)"
    assertEquals 1 "$OPTIND"
  )

  (
    OPTIND=1
    assertTrue 'missing option argument' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -cd)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -cd)"
    assertEquals 2 "$OPTIND"
    assertEquals ':' "$opt"
    assertEquals 'cd' "$OPTARG"
  )

  (
    OPTIND=1
    assertTrue 'option with argument' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -cd foo -ab)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -cd foo -ab)"
    assertEquals 3 "$OPTIND"
    assertEquals 'cd' "$opt"
    assertEquals 'foo' "$OPTARG"
    assertTrue 'basic option' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -cd foo -ab)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -cd foo -ab)"
    assertEquals 4 "$OPTIND"
    assertEquals 'ab' "$opt"
    assertFalse 'end of arguments' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -cd foo -ab)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -cd foo -ab)"
    assertEquals 4 "$OPTIND"
  )

  (
    OPTIND=1
    assertTrue 'basic option' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -ab -cd bar -x)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -ab -cd bar -x)"
    assertEquals 2 "$OPTIND"
    assertEquals 'ab' "$opt"
    assertTrue 'option with argument' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -ab -cd bar -x)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -ab -cd bar -x)"
    assertEquals 4 "$OPTIND"
    assertEquals 'cd' "$opt"
    assertEquals 'bar' "$OPTARG"
    assertFalse 'end of options' \
      "eval \"\$(get_medium_opts '$medium_opts' '$OPTIND' opt -ab -cd bar -x)\""
    eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt -ab -cd bar -x)"
    assertEquals 4 "$OPTIND"
  )
}

test_get_long_opts() {
  assertFalse 'missing option specification' 'eval "$(get_long_opts)"'
  assertFalse 'missing OPTIND value' 'eval "$(get_long_opts "ab")"'
  assertFalse 'missing output variable name' 'eval "$(get_long_opts "ab" 1)"'

  assertFalse 'empty option specification' 'eval "$(get_long_opts "" 1 opt)"'

  assertFalse 'empty OPTIND value' 'eval "$(get_long_opts "ab" "" opt)"'
  assertFalse 'invalid OPTIND value' 'eval "$(get_long_opts "ab" "?" opt)"'

  assertFalse 'empty output variable name' 'eval "$(get_long_opts "ab" 1 "")"'
  assertFalse 'invalid output variable name' 'eval "$(get_long_opts "ab" 1 "?")"'

  local orig_OPTIND='' orig_OPTARG=''
  local long_opts='ab-cd ef-gh:'
  local opt=''

  assertTrue 'no arguments' "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt)\""

  (
    OPTIND=1
    getopts ':-:' opt x
    orig_OPTIND=$OPTIND
    assertTrue 'non-option argument' "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt x)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt x)"
    assertEquals "$orig_OPTIND" "$OPTIND"
  )

  (
    OPTIND=1
    getopts ':-:' opt -x
    orig_OPTIND=$OPTIND
    assertTrue 'short argument' "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt -x)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt -x)"
    assertEquals "$orig_OPTIND" "$OPTIND"
  )

  (
    OPTIND=1
    getopts ':-:' opt -xy
    orig_OPTIND=$OPTIND
    assertTrue 'medium argument' "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt -xy)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt -xy)"
    assertEquals "$orig_OPTIND" "$OPTIND"
  )

  (
    OPTIND=1
    getopts ':-:' opt --xy
    orig_OPTIND=$OPTIND
    orig_OPTARG=${OPTARG:-}
    assertTrue 'unrecognized long argument' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --xy)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --xy)"
    assertEquals "$orig_OPTIND" "$OPTIND"
    assertEquals '?' "$opt"
    assertEquals "$orig_OPTARG" "$OPTARG"
  )

  (
    OPTIND=1
    getopts ':-:' opt --ef-gh
    assertTrue 'missing option argument' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ef-gh)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ef-gh)"
    assertEquals 2 "$OPTIND"
    assertEquals ':' "$opt"
    assertEquals 'ef-gh' "$OPTARG"
  )

  (
    OPTIND=1
    getopts ':-:' opt --ef-gh foo --ab-cd
    assertTrue 'option with argument' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ef-gh foo --ab-cd)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ef-gh foo --ab-cd)"
    assertEquals 3 "$OPTIND"
    assertEquals 'ef-gh' "$opt"
    assertEquals 'foo' "$OPTARG"
    getopts ':-:' opt --ef-gh foo --ab-cd
    assertTrue 'basic option' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ef-gh foo --ab-cd)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ef-gh foo --ab-cd)"
    assertEquals 4 "$OPTIND"
    assertEquals 'ab-cd' "$opt"
    getopts ':-:' opt --ef-gh foo --ab-cd
    assertTrue 'end of arguments' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ef-gh foo --ab-cd)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ef-gh foo --ab-cd)"
    assertEquals 4 "$OPTIND"
  )

  (
    OPTIND=1
    getopts ':-:' opt --ab-cd --ef-gh bar -x
    assertTrue 'basic option' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ab-cd --ef-gh bar -x)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ab-cd --ef-gh bar -x)"
    assertEquals 2 "$OPTIND"
    assertEquals 'ab-cd' "$opt"
    getopts ':-:' opt --ab-cd --ef-gh bar -x
    assertTrue 'option with argument' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ab-cd --ef-gh bar -x)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ab-cd --ef-gh bar -x)"
    assertEquals 4 "$OPTIND"
    assertEquals 'ef-gh' "$opt"
    assertEquals 'bar' "$OPTARG"
    getopts ':-:' opt --ab-cd --ef-gh bar -x
    orig_OPTIND=$OPTIND
    assertTrue 'end of options' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ab-cd --ef-gh bar -x)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ab-cd --ef-gh bar -x)"
    assertEquals "$orig_OPTIND" "$OPTIND"
  )

  (
    OPTIND=1
    getopts ':x-:' opt --ef-gh='yes & no' -x --ab-cd
    assertTrue 'option with argument' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ef-gh='yes & no' -x --ab-cd)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ef-gh='yes & no' -x)"
    assertEquals 2 "$OPTIND"
    assertEquals 'ef-gh' "$opt"
    assertEquals 'yes & no' "$OPTARG"
    getopts ':x-:' opt --ef-gh='yes & no' -x --ab-cd
    orig_OPTIND=$OPTIND
    assertTrue 'short option' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ef-gh='yes & no' -x --ab-cd)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ef-gh='yes & no' -x)"
    assertEquals "$orig_OPTIND" "$OPTIND"
    assertEquals 'x' "$opt"
    getopts ':x-:' opt --ef-gh='yes & no' -x --ab-cd
    assertTrue 'basic option' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ef-gh='yes & no' -x --ab-cd)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ef-gh='yes & no' -x)"
    assertEquals 4 "$OPTIND"
    assertEquals 'ab-cd' "$opt"
    assertTrue 'end of arguments' \
      "eval \"\$(get_long_opts '$long_opts' '$OPTIND' opt --ef-gh='yes & no' -x --ab-cd)\""
    eval "$(get_long_opts "$long_opts" "$OPTIND" opt --ef-gh='yes & no' -x --ab-cd)"
    assertEquals 4 "$OPTIND"
  )
}

test_opt_parser_def() {
  assertFalse 'missing short-opt spec name' 'eval "$(opt_parser_def)"'
  assertFalse 'empty short-opt spec name' 'eval "$(opt_parser_def "")"'

  assertFalse 'missing getopts output variable name' 'eval "$(opt_parser_def opts)"'
  assertFalse 'empty getopts output variable name' 'eval "$(opt_parser_def opts "")"'

  assertFalse 'missing medium-opt spec name' 'eval "$(opt_parser_def -m)"'
  assertFalse 'empty medium-opt spec name' 'eval "$(opt_parser_def -m "")"'

  assertFalse 'missing long-opt spec name' 'eval "$(opt_parser_def -l)"'
  assertFalse 'empty long-opt spec name' 'eval "$(opt_parser_def -l "")"'

  assertEquals 'short options only' \
    "getopts ab:c opt -a -b x -c 1" \
    "$(opt_parser_def 'ab:c' opt -a -b x -c 1)"

  assertEquals 'medium options only' \
    "$(printf '%s || %s' \
              'eval "$(get_medium_opts '\''ab cd: ef'\'' "$OPTIND" opt -ab -cd x -ef 1)"' \
              'getopts : opt -ab -cd x -ef 1')" \
    "$(opt_parser_def -m 'ab cd: ef' ':' opt -ab -cd x -ef 1)"

  assertEquals 'long options only' \
    "$(printf '{ %s && %s; }' \
              'getopts :-: opt --abc --def x --ghi 1' \
              'eval "$(get_long_opts '\''abc def: ghi'\'' "$OPTIND" opt --abc --def x --ghi 1)"')" \
    "$(opt_parser_def -l 'abc def: ghi' ':-:' opt --abc --def x --ghi 1)"

  assertEquals 'all option types' \
    "$(printf '%s || { %s && %s; }' \
              'eval "$(get_medium_opts '\''gh: ij'\'' "$OPTIND" opt -lx -gh foo --def bar)"' \
              'getopts :kl:-: opt -lx -gh foo --def bar' \
              'eval "$(get_long_opts '\''abc def:'\'' "$OPTIND" opt -lx -gh foo --def bar)"')" \
    "$(opt_parser_def -l 'abc def:' -m 'gh: ij' ':kl:-:' opt -lx -gh foo --def bar)"
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
