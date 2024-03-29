#!/usr/bin/env sh
# shellcheck disable=SC2016 # do not warn about `$()` in single quotes

# shellcheck disable=SC2164,SC2312 # chance of `cd` failing is negligible
# shellcheck disable=SC1091 # do not follow source
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

  _test_bos_short_opts=''
  _test_bos_medium_opts=''
  _test_bos_long_opts=''
  _test_bos_c=''
  _test_bos_cmn_ill_chars='
    ` ~ ! @ # $ % ^ & _ + = { } | : ; '\'' " < , > . /
  '

  for _test_bos_c in $_test_bos_cmn_ill_chars \* \? \[ \] \( \) -; do
    assertFalse "invalid short option: $_test_bos_c" \
      "build_opt_specs _test_bos_short_opts '$_test_bos_c'"
  done

  for _test_bos_c in $_test_bos_cmn_ill_chars \* \? \[ \] \) -; do
    assertFalse "invalid medium option: x$_test_bos_c:" \
      "build_opt_specs -m _test_bos_medium_opts _test_bos_short_opts x\\$_test_bos_c:"
  done

  assertFalse "empty long option" \
    "build_opt_specs -l _test_bos_long_opts _test_bos_short_opts '()'"

  for _test_bos_c in $_test_bos_cmn_ill_chars \* \? \[ \] \(; do
    assertFalse "invalid long option: ($_test_bos_c)" \
      "build_opt_specs -l _test_bos_long_opts _test_bos_short_opts \\(\\$_test_bos_c)\\"
  done

  assertFalse "short option and empty long option" \
    "build_opt_specs -l _test_bos_long_opts _test_bos_short_opts 'x()'"

  for _test_bos_c in $_test_bos_cmn_ill_chars \* \? \[ \] \) -; do
    assertFalse "invalid short option and long option: $_test_bos_c(x)" \
      "build_opt_specs _test_bos_short_opts \\$_test_bos_c'(x)'"
  done

  for _test_bos_c in $_test_bos_cmn_ill_chars \* \? \[ \] \(; do
    assertFalse "short option and invalid long option: x($_test_bos_c)" \
      "build_opt_specs -l _test_bos_long_opts _test_bos_short_opts 'x('\\$_test_bos_c')'"
  done

  assertFalse "medium option and empty long option" \
    "build_opt_specs -m _test_bos_medium_opts _test_bos_medium_opts 'xy()'"

  for _test_bos_c in $_test_bos_cmn_ill_chars \* \? \[ \] \) -; do
    assertFalse "invalid medium option and long option: x$_test_bos_c(a)" \
      "build_opt_specs -m _test_bos_medium_opts _test_bos_short_opts x\\$_test_bos_c'(a)'"
  done

  for _test_bos_c in $_test_bos_cmn_ill_chars \* \? \[ \] \(; do
    assertFalse "medium option and invalid long option: xy($_test_bos_c)" \
      "build_opt_specs -m _test_bos_medium_opts _test_bos_short_opts xy\\(\\$_test_bos_c\\)"
  done

  assertFalse 'missing -m option' "build_opt_specs _test_bos_short_opts 'xy'"
  assertFalse 'missing -l option' "build_opt_specs _test_bos_short_opts '(abc)'"

  build_opt_specs _test_bos_short_opts \
    a b: c d: e f: g h: i j: k l: m n: o p: q r: s t: u v: w x: y z: \
    0: 1 2: 3 4: 5 6: 7 8: 9
  assertEquals 'only short opts' \
    ':ab:cd:ef:gh:ij:kl:mn:op:qr:st:uv:wx:yz:0:12:34:56:78:9' \
    "$_test_bos_short_opts"

  build_opt_specs -m _test_bos_medium_opts _test_bos_short_opts \
    ab: cd ef: gh ij: kl mn: op qr: st uv: wx yz: \
    012: 345 6789:
  assertEquals 'no short opts (medium opts)' \
    ':' "$_test_bos_short_opts"
  assertEquals 'only medium opts' \
    'ab: cd ef: gh ij: kl mn: op qr: st uv: wx yz: 012: 345 6789:' \
    "$_test_bos_medium_opts"

  build_opt_specs -l _test_bos_long_opts _test_bos_short_opts \
    '(ab-cd)' '(ef-gh):' '(ij-kl)' '(mn-op):' '(qr-st)' '(uv-wx):' '(yz)' \
    '(-012):' '(345-678)' '(9):'
  assertEquals 'no short opts (long opts)' \
    ':' "$_test_bos_short_opts"
  assertEquals 'only long opts' \
    'ab-cd ef-gh: ij-kl mn-op: qr-st uv-wx: yz -012: 345-678 9:' \
    "$_test_bos_long_opts"

  build_opt_specs -l _test_bos_long_opts \
                  -m _test_bos_medium_opts \
                  _test_bos_short_opts \
                  a 0: ab 12: '(abc-def)' '(123-456):' 'b(12-34)' \
                  '1(ab-cd):' 'cd(34-56)' '34(cd-ef):'
  assertEquals 'short opts (mixed in)' \
    ':a0:b1:' "$_test_bos_short_opts"
  assertEquals 'medium opts (mixed in)' \
    'ab 12: cd 34:' "$_test_bos_medium_opts"
  assertEquals 'long opts (mixed in)' \
    'abc-def 123-456: 12-34 ab-cd: 34-56 cd-ef:' "$_test_bos_long_opts"

  unset _test_bos_short_opts _test_bos_medium_opts _test_bos_long_opts \
        _test_bos_c _test_bos_cmn_ill_chars
}

test_get_long_opts() {
  assertFalse 'missing option specification' 'eval "$(get_long_opts)"'
  assertFalse 'missing OPTIND value' 'eval "$(get_long_opts "ab")"'
  assertFalse 'missing output variable name' 'eval "$(get_long_opts "ab" 1)"'

  assertFalse 'empty option specification' \
    'eval "$(get_long_opts "" 1 _test_glo_opt)"'

  assertFalse 'empty OPTIND value' \
    'eval "$(get_long_opts "ab" "" _test_glo_opt)"'
  assertFalse 'invalid OPTIND value' \
    'eval "$(get_long_opts "ab" "?" _test_glo_opt)"'

  assertFalse 'empty output variable name' 'eval "$(get_long_opts "ab" 1 "")"'
  assertFalse 'invalid output variable name' 'eval "$(get_long_opts "ab" 1 "?")"'

  _test_glo_opt_spec='ab-cd ef-gh:'
  _test_glo_opt=''

  assertFalse 'no arguments' \
    "eval \"\$(get_long_opts '$_test_glo_opt_spec' '$OPTIND' _test_glo_opt)\""

  eval "$(reset_opt_index)"
  _test_glo_old_optind=$OPTIND
  set -- x
  _test_glo_case='non-opt'
  ! eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" "$_test_glo_old_optind" "$OPTIND"

  eval "$(reset_opt_index)"
  _test_glo_old_optind=$OPTIND
  set -- -x
  _test_glo_case='short opt'
  ! eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" "$_test_glo_old_optind" "$OPTIND"

  eval "$(reset_opt_index)"
  _test_glo_old_optind=$OPTIND
  set -- -xy
  _test_glo_case='medium opt'
  ! eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" "$_test_glo_old_optind" "$OPTIND"

  eval "$(reset_opt_index)"
  OPTARG=''
  set -- --xy
  _test_glo_case='unrecognized long opt'
  eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 2 "$OPTIND"
  assertEquals "$_test_glo_case: opt" '?' "$_test_glo_opt"
  assertEquals "$_test_glo_case: OPTARG" 'xy' "$OPTARG"

  eval "$(reset_opt_index)"
  set -- --ef-gh
  _test_glo_case='missing long optarg'
  eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 2 "$OPTIND"
  assertEquals "$_test_glo_case: opt" ':' "$_test_glo_opt"
  assertEquals "$_test_glo_case: OPTARG" 'ef-gh' "${OPTARG:-}"

  eval "$(reset_opt_index)"
  set -- --ef-gh foo --ab-cd
  _test_glo_case='[long optarg] -> long opt -> end'
  eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 3 "$OPTIND"
  assertEquals "$_test_glo_case: opt" 'ef-gh' "$_test_glo_opt"
  assertEquals "$_test_glo_case: OPTARG" 'foo' "${OPTARG:-}"
  _test_glo_case='long optarg -> [long opt] -> end'
  eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 4 "$OPTIND"
  assertEquals "$_test_glo_case: opt" 'ab-cd' "$_test_glo_opt"
  _test_glo_case='long optarg -> long opt -> [end]'
  ! eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 4 "$OPTIND"

  eval "$(reset_opt_index)"
  set -- --ab-cd --ef-gh bar -x
  _test_glo_case='[long opt] -> long optarg -> short opt'
  eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 2 "$OPTIND"
  assertEquals "$_test_glo_case: opt" 'ab-cd' "$_test_glo_opt"
  _test_glo_case='long opt -> [long optarg] -> short opt'
  eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 4 "$OPTIND"
  assertEquals "$_test_glo_case: opt" 'ef-gh' "$_test_glo_opt"
  assertEquals "$_test_glo_case: OPTARG" 'bar' "${OPTARG:-}"
  _test_glo_case='long opt -> long optarg -> [short opt]'
  ! eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 4 "$OPTIND"

  eval "$(reset_opt_index)"
  set -- --ef-gh='yes & no' -x --ab-cd
  _test_glo_case='[long optarg] -> short opt -> long opt -> end'
  eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 2 "$OPTIND"
  assertEquals "$_test_glo_case: opt" 'ef-gh' "$_test_glo_opt"
  assertEquals "$_test_glo_case: OPTARG" 'yes & no' "${OPTARG:-}"
  _test_glo_case='long optarg -> [short opt] -> long opt -> end'
  ! eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 2 "$OPTIND"
  OPTIND=3 # skip to next long option
  _test_glo_case='long optarg -> short opt -> [long opt] -> end'
  eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 4 "$OPTIND"
  assertEquals "$_test_glo_case: opt" 'ab-cd' "$_test_glo_opt"
  _test_glo_case='long optarg -> short opt -> long opt -> [end]'
  ! eval "$(get_long_opts "$_test_glo_opt_spec" "$OPTIND" _test_glo_opt "$@")" \
    || fail "$_test_glo_case: parse"
  assertEquals "$_test_glo_case: OPTIND" 4 "$OPTIND"

  unset _test_glo_opt_spec _test_glo_opt _test_glo_old_optind _test_glo_case
}

test_get_medium_opts() {
  assertFalse 'missing option specification' 'eval "$(get_medium_opts)"'
  assertFalse 'missing OPTIND value' 'eval "$(get_medium_opts "ab")"'
  assertFalse 'missing output variable name' 'eval "$(get_medium_opts "ab" 1)"'

  assertFalse 'empty option specification' \
    'eval "$(get_medium_opts "" 1 _test_gmo_opt)"'

  assertFalse 'empty OPTIND value' \
    'eval "$(get_medium_opts "ab" "" _test_gmo_opt)"'
  assertFalse 'invalid OPTIND value' \
    'eval "$(get_medium_opts "ab" "?" _test_gmo_opt)"'

  assertFalse 'empty output variable name' \
    'eval "$(get_medium_opts "ab" 1 "")"'
  assertFalse 'invalid output variable name' \
    'eval "$(get_medium_opts "ab" 1 "?")"'

  _test_gmo_opt_spec='ab cd:'
  _test_gmo_opt=''

  assertFalse 'no arguments' \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt)\""

  eval "$(reset_opt_index)"
  _test_gmo_old_optind=$OPTIND
  set -- x
  _test_gmo_case='non-opt'
  assertFalse "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" "$_test_gmo_old_optind" "$OPTIND"

  eval "$(reset_opt_index)"
  _test_gmo_old_optind=$OPTIND
  set -- -x
  _test_gmo_case='short opt'
  assertFalse "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" "$_test_gmo_old_optind" "$OPTIND"

  eval "$(reset_opt_index)"
  _test_gmo_old_optind=$OPTIND
  set -- --xy
  _test_gmo_case='long opt'
  assertFalse "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" "$_test_gmo_old_optind" "$OPTIND"

  eval "$(reset_opt_index)"
  _test_gmo_old_optind=$OPTIND
  set -- -xy
  _test_gmo_case='unrecognized medium opt'
  assertFalse "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" "$_test_gmo_old_optind" "$OPTIND"

  eval "$(reset_opt_index)"
  set -- -cd
  _test_gmo_case='missing medium optarg'
  assertTrue "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" 2 "$OPTIND"
  assertEquals "$_test_gmo_case: opt" ':' "$_test_gmo_opt"
  assertEquals "$_test_gmo_case: OPTARG" 'cd' "$OPTARG"

  eval "$(reset_opt_index)"
  set -- -cd foo -ab
  _test_gmo_case='[medium optarg] -> medium opt -> end'
  assertTrue "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" 3 "$OPTIND"
  assertEquals "$_test_gmo_case: opt" 'cd' "$_test_gmo_opt"
  assertEquals "$_test_gmo_case: OPTARG" 'foo' "$OPTARG"
  _test_gmo_case='medium optarg -> [medium opt] -> end'
  assertTrue "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" 4 "$OPTIND"
  assertEquals "$_test_gmo_case: opt" 'ab' "$_test_gmo_opt"
  _test_gmo_case='medium optarg -> medium opt -> [end]'
  assertFalse "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" 4 "$OPTIND"

  eval "$(reset_opt_index)"
  set -- -ab -cd bar -x
  _test_gmo_case='[medium opt] -> medium optarg -> short opt'
  assertTrue "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" 2 "$OPTIND"
  assertEquals "$_test_gmo_case: opt" 'ab' "$_test_gmo_opt"
  _test_gmo_case='medium opt -> [medium optarg] -> short opt'
  assertTrue "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" 4 "$OPTIND"
  assertEquals "$_test_gmo_case: opt" 'cd' "$_test_gmo_opt"
  assertEquals "$_test_gmo_case: OPTARG" 'bar' "$OPTARG"
  _test_gmo_case='medium opt -> medium optarg -> [short opt]'
  assertFalse "$_test_gmo_case: parse" \
    "eval \"\$(get_medium_opts '$_test_gmo_opt_spec' '$OPTIND' _test_gmo_opt $*)\""
  eval "$(get_medium_opts "$_test_gmo_opt_spec" "$OPTIND" _test_gmo_opt "$@")"
  assertEquals "$_test_gmo_case: OPTIND" 4 "$OPTIND"

  unset _test_gmo_opt_spec _test_gmo_opt _test_gmo_old_optind _test_gmo_case
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

  build_opt_specs \
    -l _test_opd_long_opts \
    -m _test_opd_medium_opts \
    _test_opd_short_opts \
    'a' 'b:' 'am' 'bm:' '(a-long)' '(b-long):'

  _test_opd_make_parser() {
    _test_opd_opt_parser=$(opt_parser_def \
      -l "$_test_opd_long_opts" \
      -m "$_test_opd_medium_opts" \
      "$_test_opd_short_opts" \
      _test_opd_opt \
      "$@"
    )
  }

  eval "$(reset_opt_index)"
  set -- 0
  _test_opd_make_parser "$@"
  _test_opd_case='start -> non-opt'
  ! eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"

  eval "$(reset_opt_index)"
  set -- -x
  _test_opd_make_parser "$@"
  _test_opd_case='start -> invalid short opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" '?' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" 'x' "${OPTARG:-}"

  eval "$(reset_opt_index)"
  set -- --ax-long
  _test_opd_make_parser "$@"
  _test_opd_case='start -> invalid long opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" '?' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" 'ax-long' "${OPTARG:-}"

  eval "$(reset_opt_index)"
  set -- -a
  _test_opd_make_parser "$@"
  _test_opd_case='start -> short opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -am
  _test_opd_make_parser "$@"
  _test_opd_case='start -> medium opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- --a-long
  _test_opd_make_parser "$@"
  _test_opd_case='start -> long opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -a 0
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> short opt] -> non-opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"
  _test_opd_case='start -> [short opt -> non-opt]'
  ! eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"

  eval "$(reset_opt_index)"
  set -- -a -b1
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> short opt] -> short opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"
  _test_opd_case='start -> [short opt -> short opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '1' "${OPTARG:-}"

  # NOTE: `posh` cannot parse combined short options with its `getopts`
  if ! command ps -p $$ 2>/dev/null | grep -q 'posh'; then
    eval "$(reset_opt_index)"
    set -- -ab1
    _test_opd_make_parser "$@"
    _test_opd_case='[start -> short opt] -> joined short opt'
    eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
    assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"
    _test_opd_case='start -> [short opt -> joined short opt]'
    eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
    assertEquals "$_test_opd_case: opt" 'b' "${_test_opd_opt:-}"
    assertEquals "$_test_opd_case: OPTARG" '1' "${OPTARG:-}"
  fi

  eval "$(reset_opt_index)"
  set -- -a -am
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> short opt] -> medium opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"
  _test_opd_case='start -> [short opt -> medium opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -a --a-long
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> short opt] -> long opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"
  _test_opd_case='start -> [short opt -> long opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -b 1 0
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> short optarg] -> non-opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '1' "${OPTARG:-}"
  _test_opd_case='start -> [short optarg -> non-opt]'
  ! eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"

  eval "$(reset_opt_index)"
  set -- -b 1 -a
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> short optarg] -> short opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '1' "${OPTARG:-}"
  _test_opd_case='start -> [short optarg -> short opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -b 1 -am
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> short optarg] -> medium opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '1' "${OPTARG:-}"
  _test_opd_case='start -> [short optarg -> medium opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -b 1 --a-long
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> short optarg] -> long opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '1' "${OPTARG:-}"
  _test_opd_case='start -> [short optarg -> long opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -am 0
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> medium opt] -> non-opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"
  _test_opd_case='start -> [medium opt -> non-opt]'
  ! eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"

  eval "$(reset_opt_index)"
  set -- -am -a
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> medium opt] -> short opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"
  _test_opd_case='start -> [medium opt -> short opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -am -bm 2
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> medium opt] -> medium opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"
  _test_opd_case='start -> [medium opt -> medium opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'bm' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '2' "${OPTARG:-}"

  eval "$(reset_opt_index)"
  set -- -am --a-long
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> medium opt] -> long opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"
  _test_opd_case='start -> [medium opt -> long opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -bm 2 0
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> medium optarg] -> non-opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'bm' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '2' "${OPTARG:-}"
  _test_opd_case='start -> [medium optarg -> non-opt]'
  ! eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"

  eval "$(reset_opt_index)"
  set -- -bm 2 -a
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> medium optarg] -> short opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'bm' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '2' "${OPTARG:-}"
  _test_opd_case='start -> [medium optarg -> short opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -bm 2 -am
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> medium optarg] -> medium opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'bm' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '2' "${OPTARG:-}"
  _test_opd_case='start -> [medium optarg -> medium opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- -bm 2 --a-long
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> medium optarg] -> long opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'bm' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '2' "${OPTARG:-}"
  _test_opd_case='start -> [medium optarg -> long opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- --a-long 0
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> long opt] -> non-opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"
  _test_opd_case='start -> [long opt -> non-opt]'
  ! eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"

  eval "$(reset_opt_index)"
  set -- --a-long -a
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> long opt] -> short opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"
  _test_opd_case='start -> [long opt -> short opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- --a-long -am
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> long opt] -> medium opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"
  _test_opd_case='start -> [long opt -> medium opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- --a-long --b-long 3
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> long opt] -> long opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"
  _test_opd_case='start -> [long opt -> long opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b-long' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '3' "${OPTARG:-}"

  eval "$(reset_opt_index)"
  set -- --b-long 3 0
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> long optarg] -> non-opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b-long' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '3' "${OPTARG:-}"
  _test_opd_case='start -> [long optarg -> non-opt]'
  ! eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"

  eval "$(reset_opt_index)"
  set -- --b-long 3 -a
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> long optarg] -> short opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b-long' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '3' "${OPTARG:-}"
  _test_opd_case='start -> [long optarg -> short opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- --b-long 3 -am
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> long optarg] -> medium opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b-long' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '3' "${OPTARG:-}"
  _test_opd_case='start -> [long optarg -> medium opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'am' "${_test_opd_opt:-}"

  eval "$(reset_opt_index)"
  set -- --b-long 3 --a-long
  _test_opd_make_parser "$@"
  _test_opd_case='[start -> long optarg] -> long opt'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'b-long' "${_test_opd_opt:-}"
  assertEquals "$_test_opd_case: OPTARG" '3' "${OPTARG:-}"
  _test_opd_case='start -> [long optarg -> long opt]'
  eval "$_test_opd_opt_parser" || fail "$_test_opd_case: parse"
  assertEquals "$_test_opd_case: opt" 'a-long' "${_test_opd_opt:-}"

  unset _test_opd_long_opts _test_opd_medium_opts _test_opd_short_opts \
        _test_opd_opt_parser _test_opd_make_parser _test_opd_opt _test_opd_case
}

if [ "${ZSH_VERSION:-}" ]; then
  setopt shwordsplit

  # shellcheck disable=SC2034 # variable used by `shunit2`
  SHUNIT_PARENT=$0
fi

. shunit2
