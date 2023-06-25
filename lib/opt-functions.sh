# shellcheck shell=sh
# shellcheck disable=SC3043 # allow 'local' usage

# --------------------------------------------------------------------------------
# WARNING: This file must be loaded using `include` (from 'include-function.sh').
# --------------------------------------------------------------------------------

include common-functions.sh

#
# Usage: build_opt_specs [-l LONG_NAME] [-m MEDIUM_NAME] SHORT_NAME OPT_DEF...
#
# Generate short-option specification from OPT_DEFs in $SHORT_NAME
# for use with `getopts`. With -l, also generate long-option
# specification in $LONG_NAME for use with `get_long_opts`. With -m,
# also generate medium-option specification in $MEDIUM_NAME for use
# with `get_medium_opts`. The variables SHORT_NAME, MEDIUM_NAME (with -m),
# and LONG_NAME (with -l) will be initialized if they do not already exist.
#
# Each OPT_DEF defines a recognized short/medium option and/or long
# option. It must be in the form 'SHORT', 'MEDIUM', '(LONG)', 'SHORT(LONG)',
# or 'MEDIUM(LONG)', where 'SHORT' is a letter or number defining a short
# option, 'MEDIUM' is two or more letters/numbers defining a medium option,
# and 'LONG' is an alphanumeric string (may also include hyphens) defining a
# long option. It may also have a colon suffix to indicate the option(s)
# is/are expected to have an argument. For example, an OPT_DEF of 'c(category):'
# would define '-c' and '--category' options, both expecting an argument.
#
# Besides containing the short options extracted from the OPT_DEFs, the
# $SHORT_NAME variable will also be prefixed with a colon (:) to configure
# `getopts` to use silent error reporting. With -l, $SHORT_NAME will also
# contain '-:' to ensure `getopts` accepts GNU-style long options.
#
# If an OPT_DEF defines a long-option but -l was not used, then an error
# will be returned. Likewise, providing a medium-option-defining OPT_DEF
# without -m will also cause an error to be returned.
#
# Implementation Notes:
#   The reason all local variables in this function are prefixed with
#   `_bos_` is to reduce the likelihood of one of the variables
#   having the same name as SHORT_NAME, MEDIUM_NAME, or LONG_NAME and thus
#   preventing $SHORT_NAME, $MEDIUM_NAME, or $LONG_NAME from being updated
#   on function completion.
#
build_opt_specs() {
  local _bos_long_spec_name=''
  local _bos_medium_spec_name=''
  while true; do
    case ${1:-} in
      -l) _bos_long_spec_name="${2:?option '-l' requires an argument}"; shift 2 ;;
      -m) _bos_medium_spec_name="${2:?option '-m' requires an argument}"; shift 2 ;;
      *)  break ;;
    esac
  done

  local _bos_short_spec_name="${1:?missing short option spec name}"; shift

  local _bos_arg
  for _bos_arg in "$_bos_short_spec_name" \
             "$_bos_medium_spec_name" \
             "$_bos_long_spec_name"
  do
    if [ "$_bos_arg" ] && ! is_valid_identifier "$_bos_arg"; then
      echo "'$_bos_arg' is not a valid identifier" >&2
      return 2
    fi
  done

  local _bos_short_opt_spec=":"
  local _bos_medium_opt_spec=""
  local _bos_long_opt_spec=""

  while [ $# -gt 0 ]; do
    local _bos_optdef="$1"
    shift

    local _bos_found_short_opt=0
    local _bos_found_medium_opt=0
    local _bos_found_long_opt=0
    local _bos_found_bad_opt=0
    case ${_bos_optdef%:} in
      # short option
      [0-9A-Za-z])
        _bos_found_short_opt=1; _bos_found_medium_opt=0; _bos_found_long_opt=0; ;;

      # long option
      \(\) | \(*[!-0-9A-Za-z]*\))
        _bos_found_bad_opt=1 ;;
      \(?*\))
        _bos_found_short_opt=0; _bos_found_medium_opt=0; _bos_found_long_opt=1; ;;

      # short option and long option
      [0-9A-Za-z]\(\) | [0-9A-Za-z]\(*[!-0-9A-Za-z]*\))
        _bos_found_bad_opt=1 ;;
      [0-9A-Za-z]\(?*\))
        _bos_found_short_opt=1; _bos_found_medium_opt=0; _bos_found_long_opt=1; ;;

      # medium option and long option
      [0-9A-Za-z][0-9A-Za-z]*[!0-9A-Za-z]*\(*\))
        _bos_found_bad_opt=1 ;;
      [0-9A-Za-z][0-9A-Za-z]*\(\) | [0-9A-Za-z][0-9A-Za-z]*\(*[!-0-9A-Za-z]*\))
        _bos_found_bad_opt=1 ;;
      [0-9A-Za-z][0-9A-Za-z]*\(?*\))
        _bos_found_short_opt=0; _bos_found_medium_opt=1; _bos_found_long_opt=1; ;;

      # medium option
      [0-9A-Za-z][0-9A-Za-z]*[!0-9A-Za-z]*)
        _bos_found_bad_opt=1 ;;
      [0-9A-Za-z][0-9A-Za-z]*)
        _bos_found_short_opt=0; _bos_found_medium_opt=1; _bos_found_long_opt=0; ;;

      # end of option definitions
      --) break ;;

      *) _bos_found_bad_opt=1 ;;
    esac

    if [ "$_bos_found_bad_opt" -eq 1 ]; then
      echo "invalid option definition '$_bos_optdef'" >&2
      return 2
    fi

    local _bos_short_opt=''
    local _bos_medium_opt=''
    if [ "$_bos_found_short_opt" -eq 1 ]; then
      _bos_short_opt=${_bos_optdef%\(*}
      _bos_short_opt=${_bos_short_opt%:}
    elif [ "$_bos_found_medium_opt" -eq 1 ]; then
      _bos_medium_opt=${_bos_optdef%\(*}
      _bos_medium_opt=${_bos_medium_opt%:}
    fi

    local _bos_long_opt=''
    if [ "$_bos_found_long_opt" -eq 1 ]; then
      _bos_long_opt=${_bos_optdef#*\(}
      _bos_long_opt=${_bos_long_opt%\)*}
    fi

    local _bos_optarg_sigil=''
    if [ "${_bos_optdef%:}" != "$_bos_optdef" ]; then
      _bos_optarg_sigil=':'
    fi

    if [ "$_bos_short_opt" ]; then
      _bos_short_opt_spec="${_bos_short_opt_spec}${_bos_short_opt}${_bos_optarg_sigil}"
    elif [ "$_bos_medium_opt" ]; then
      _bos_medium_opt_spec="${_bos_medium_opt_spec:+${_bos_medium_opt_spec} }${_bos_medium_opt}${_bos_optarg_sigil}"
    fi

    if [ "$_bos_long_opt" ]; then
      _bos_long_opt_spec="${_bos_long_opt_spec:+${_bos_long_opt_spec} }${_bos_long_opt}${_bos_optarg_sigil}"
    fi
  done

  if [ "$_bos_long_opt_spec" ]; then
    _bos_short_opt_spec="${_bos_short_opt_spec}-:"
  fi

  if [ "$_bos_long_opt_spec" ]; then
    if [ ! "$_bos_long_spec_name" ]; then
      echo "need to use '-l' option when defining long option(s)" >&2
      return 2
    fi

    eval "$_bos_long_spec_name='$_bos_long_opt_spec'"
  fi

  if [ "$_bos_medium_opt_spec" ]; then
    if [ ! "$_bos_medium_spec_name" ]; then
      echo "need to use '-m' option when defining medium option(s)" >&2
      return 2
    fi

    eval "$_bos_medium_spec_name='$_bos_medium_opt_spec'"
  fi

  eval "$_bos_short_spec_name='$_bos_short_opt_spec'"
}

#
# Usage: eval "$(get_medium_opts OPT_SPEC OPT_INDEX SHORT_OPT ARG...)"
#
# Parse next medium option from ARGs using both OPT_SPEC and OPT_INDEX
# and store result in $SHORT_OPT.
#
# This function expects that `getopts` be called after it with a short-option
# specification from `build_opt_specs`, that OPT_INDEX be the value of $OPTIND
# from the caller's context, $SHORT_OPT be the variable in which `getopts` will
# place its output, and that ARGs be the same positional arguments that will be
# passed to `getopts`. Also OPT_SPEC must be a medium-option specification
# from `build_opt_specs`.
#
# If the next argument processed by `getopts` would be a medium option in OPT_SPEC
# with any required argument present, then this function will set $SHORT_OPT
# to the name of the option, set OPTARG to any argument for the option, and
# increment OPTIND appropriately. Else, if the next processed argument would
# be a recognized medium option with a missing required argument, then $SHORT_OPT
# will be set to ':', OPTARG will be set to the option name, and OPTIND will be
# incremented. Else (if the next processed argument would be a non-option or
# an option not in OPT_SPEC), then this function will return failure.
#
# This function recognizes any IFS character as a valid delimiter between a medium
# option and its argument.
#
# Example:
#   parse_args() {
#     input_dir=''
#     output_dir=''
#     help=0
#
#     local short_opts medium_opts long_opts
#     build_opt_specs -l long_opts -m medium_opts short_opts \
#                     'id(input-dir):' 'od(output-dir):' 'h(help)'
#
#     local OPTIND=1 OPTARG='' opt='' bad_opt='' no_optarg=0
#     while eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt "$@")" \
#           || { getopts "$short_opts" opt "$@" \
#                && eval "$(get_long_opts "$long_opts" "$OPTIND" opt "$@")"; }
#     do
#       case $opt in
#         id|input-dir)  input_dir=$OPTARG  ;;
#         od|output-dir) output_dir=$OPTARG ;;
#         h|help)        help=1             ;;
#
#         :) bad_opt=$OPTARG ; no_optarg=1; break ;;
#         *) bad_opt=$OPTARG ; break ;;
#       esac
#     done; shift $((OPTIND - 1))
#
#     # check bad_opt/no_optarg and handle remaining (non-option) arguments here...
#   }
#
#   # sets '$input_dir' to 'foo' and '$output_dir' to 'bar'
#   parse_args --input-dir=foo -od bar
#
#   # sets '$input_dir' to 'one' and '$output_dir' to 'two'
#   parse_args -id ERROR --output-dir two
#
#   # sets '$help' to '1'
#   parse_args -h
#
# Note:
#   See `opt_parser_def` for a convenient code generator for
#   `get_long_opts`, `get_medium_opts`, and `getopts`.
#
# Implementation Notes:
#   The reason the output of this function must be passed to `eval`, rather than
#   the function called directly, is to avoid a `dash` limitation where `getopts`
#   ignores any change to `OPTIND` that was a side effect of a function call.
#
#   The reason we need to pass the caller's `$OPTIND` value in as a parameter,
#   rather than accessing it via dynamic scoping, is to work around idiosyncratic
#   behavior of 'zsh' where the value of the OPTIND shell variable is reset to
#   to `1` whenever a new function is entered.
#
get_medium_opts() {
  if [ ! "${1:-}" ]; then
    echo "echo 'missing medium-option specification' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  local medium_opt_spec="$1"; shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing OPTIND value' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  # NOTE: For `yash`, OPTIND has the format 'ARG_INDEX[:CHAR_INDEX]'
  local opt_index="${1%%:*}"; shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing getopts output variable name' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  local opt_name="$1"; shift

  if ! is_number "$opt_index"; then
    echo "echo \"$(escape "$opt_index") is not a valid number\" >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi

  if ! is_valid_identifier "$opt_name"; then
    echo "echo \"$(escape "$opt_name") is not a valid identifier\" >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi

  if [ "$opt_index" -gt $# ]; then
    echo "false"; return
  fi

  eval "local current_arg=\"\$$opt_index\""

  # shellcheck disable=SC2154 # current_arg set by `eval` above
  case $current_arg in -*) ;; *)
    # not an option
    echo "false"; return
  ;; esac

  local matched_opt="${current_arg#-}"

  case " $medium_opt_spec " in
    *" $matched_opt "*)
      # medium option with no argument
      echo "OPTIND=$((opt_index + 1))"
      ;;
    *" $matched_opt: "*)
      if [ "$((opt_index + 1))" -le $# ]; then
        # medium option with provided argument
        eval "local opt_arg=\"\$$((opt_index + 1))\""
        escape_var opt_arg
        echo "OPTARG=$opt_arg"

        echo "OPTIND=$((opt_index + 2))"
      else
        # medium option with missing argument
        echo "OPTARG=$matched_opt"
        echo "OPTIND=$((opt_index + 1))"
        matched_opt=':'
      fi
      ;;
    *)
      # unrecognized option
      echo "false"; return
      ;;
  esac

  echo "$opt_name='$matched_opt'"
}

#
# Usage: eval "$(get_long_opts OPT_SPEC OPT_INDEX SHORT_OPT ARG...)"
#
# Adjust `getopts` output to accommodate long options in OPT_SPEC.
#
# This function requires that `getopts` be called before it with a short-option
# specification from `build_opt_specs`, that OPT_INDEX be the value of $OPTIND
# from the caller's context, that $SHORT_OPT be the variable in which `getopts`
# has placed its output, and that ARGs be the same positional arguments that
# were passed to `getopts`. Also OPT_SPEC must be a long-option specification
# from `build_opt_specs`.
#
# If the last option processed by `getopts` was a long option in OPT_SPEC
# with any required argument present, then this function will set $SHORT_OPT
# to the name of the option and OPTARG to any argument for the option.
# Else, if the last processed option was a recognized long option with a
# missing required argument, then $SHORT_OPT will be set to ':' and OPTARG
# to the option name. Else, if the last processed option was an unrecognized
# long option, then $SHORT_OPT will be set to '?' and OPTARG to the option name.
# Else (if the last processed option was a short option), then this function
# will do nothing.
#
# This function recognizes the equals sign and any IFS character as a valid
# delimiter between a long option and its argument. For example, the options
# `--level DEBUG` and `--level=DEBUG` are equivalent.
#
# Example:
#   parse_args() {
#     level=''
#     category=''
#     help=0
#
#     local short_opts long_opts
#     build_opt_specs -l long_opts short_opts 'l(level):' 'c(category):' 'h(help)'
#
#     local OPTIND=1 OPTARG='' opt='' bad_opt='' no_optarg=0
#     while getopts "$short_opts" opt "$@" \
#           && eval "$(get_long_opts "$long_opts" "$OPTIND" opt "$@")"
#     do
#       case $opt in
#         l|level)    level=$OPTARG    ;;
#         c|category) category=$OPTARG ;;
#         h|help)     help=1           ;;
#
#         :) bad_opt=$OPTARG ; no_optarg=1; break ;;
#         *) bad_opt=$OPTARG ; break ;;
#       esac
#     done; shift $((OPTIND - 1))
#
#     # check bad_opt/no_optarg and handle remaining (non-option) arguments here...
#   }
#
#   # sets '$level' to 'INFO' and '$category' to 'general'
#   parse_args --level=INFO -c general
#
#   # sets '$level' to 'ERROR' and '$category' to 'special'
#   parse_args -l ERROR --category special
#
#   # sets '$help' to '1'
#   parse_args -h
#
# Note:
#   See `opt_parser_def` for a convenient code generator for
#   `get_long_opts`, `get_medium_opts`, and `getopts`.
#
# Implementation Notes:
#   The reason this function must be called after `getopts`, rather than it calling
#   `getopts` itself, is to avoid a `dash` limitation in which `getopts` misbehaves
#   when called through a wrapper function.
#
#   The reason the output of this function must be passed to `eval`, rather than
#   the function called directly, is to avoid a `dash` limitation where `getopts`
#   ignores any change to `OPTIND` that was a side effect of a function call.
#
#   The reason we need to pass the caller's `$OPTIND` value in as a parameter,
#   rather than accessing it via dynamic scoping, is to work around idiosyncratic
#   behavior of 'zsh' where the value of the OPTIND shell variable is reset to
#   to `1` whenever a new function is entered.
#
get_long_opts() {
  if [ ! "${1:-}" ]; then
    echo "echo 'missing long-option specification' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  local long_opt_spec="$1"; shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing OPTIND value' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  # NOTE: For `yash`, OPTIND has the format 'ARG_INDEX[:CHAR_INDEX]'
  local opt_index="${1%%:*}"; shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing getopts output variable name' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  local opt_name="$1"; shift

  if ! is_number "$opt_index"; then
    echo "echo \"$(escape "$opt_index") is not a valid number\" >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi

  if ! is_valid_identifier "$opt_name"; then
    echo "echo \"$(escape "$opt_name") is not a valid identifier\" >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi

  eval "local matched_opt=\"\$$opt_name\""

  if [ "$matched_opt" = '-' ]; then
    matched_opt=${OPTARG%%=*}

    case " $long_opt_spec " in
      *" $matched_opt "*)
        if [ "${OPTARG%%=*}" != "$OPTARG" ]; then
          # long option with unexpected argument
          matched_opt='?'
        fi
        ;;
      *" $matched_opt: "*)
        if [ "${OPTARG%%=*}" != "$OPTARG" ]; then
          # long option with '='-delimited argument
          local opt_arg="${OPTARG#*=}"
          escape_var opt_arg
          echo "OPTARG=$opt_arg"
        elif [ "$opt_index" -le $# ]; then
          # long option with IFS-delimited argument
          eval "local opt_arg=\"\$$opt_index\""
          escape_var opt_arg
          echo "OPTARG=$opt_arg"

          echo "OPTIND=$((opt_index + 1))"
        else
          # long option with missing argument
          matched_opt=':'
        fi
        ;;
      *)
        # unrecognized long option
        matched_opt='?'
        ;;
    esac
  fi

  echo "$opt_name='$matched_opt'"
}

#
# Usage: opt_parser_def [-l LONG_OPT_SPEC] [-m MEDIUM_OPT_SPEC]
#                       SHORT_OPT_SPEC SHORT_OPT ARGS...
#
# Generate evaluable code to call `getopts` with given short-option specification
# SHORT_OPT_SPEC, output variable SHORT_OPT, and positional ARGs.
#
# With -l, also generate code to call `get_long_opts` with given long-option
# specification LONG_OPT_SPEC, output variable SHORT_OPT, and positional ARGs.
#
# With -m, also generate code to call `get_medium_opts` with given medium-option
# specification MEDIUM_OPT_SPEC, output variable SHORT_OPT, and positional ARGs.
#
# The output of this function should be passed to `eval` for execution.
#
# Example:
#   parse_args() {
#     input_dir=''
#     output_dir=''
#     help=0
#
#     local short_opts medium_opts long_opts
#     build_opt_specs -l long_opts -m medium_opts short_opts \
#                     'id(input-dir):' 'od(output-dir):' 'h(help)'
#
#     local opt_parser
#     opt_parser="$(opt_parser_def -l "$long_opts" -m "$medium_opts" \
#                                  "$short_opts" opt "$@")"
#
#     local OPTIND=1 OPTARG='' opt='' bad_opt='' no_optarg=0
#     while eval "opt_parser"; do
#       case $opt in
#         id|input-dir)  input_dir=$OPTARG  ;;
#         od|output-dir) output_dir=$OPTARG ;;
#         h|help)        help=1             ;;
#
#         :) bad_opt=$OPTARG ; no_optarg=1; break ;;
#         *) bad_opt=$OPTARG ; break ;;
#       esac
#     done; shift $((OPTIND - 1))
#
#     # check bad_opt/no_optarg and handle remaining (non-option) arguments here...
#   }
#
#   # sets '$input_dir' to 'foo' and '$output_dir' to 'bar'
#   parse_args --input-dir=foo -od bar
#
#   # sets '$input_dir' to 'one' and '$output_dir' to 'two'
#   parse_args -id ERROR --output-dir two
#
#   # sets '$help' to '1'
#   parse_args -h
#
opt_parser_def() {
  local long_opt_spec=''
  local medium_opt_spec=''
  while true; do
    case ${1:-} in
      -l) if [ ! "${2:-}" ]; then
            echo "echo \"option '-l' requires an argument\" >&2"
            echo "return 2 2>/dev/null || exit 2"
            return
          else
            local long_opt_spec="$2"; shift 2
          fi
          ;;

      -m) if [ ! "${2:-}" ]; then
            echo "echo \"option '-m' requires an argument\" >&2"
            echo "return 2 2>/dev/null || exit 2"
            return
          else
            local medium_opt_spec="$2"; shift 2
          fi
          ;;

       *) break
          ;;
    esac
  done

  if [ ! "${1:-}" ]; then
    echo "echo 'missing short option specification' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  local short_opt_spec="$1"; shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing getopts output variable name' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  local opt_name="$1"; shift

  local escaped_opt_name="$opt_name"
  escape_var escaped_opt_name

  local escaped_args
  escaped_args=$(escape "$@")

  if [ "$medium_opt_spec" ]; then
    local escaped_medium_opt_spec="$medium_opt_spec"
    escape_var escaped_medium_opt_spec

    printf "eval \"\$(get_medium_opts %s %s %s %s)\" || " \
      "$escaped_medium_opt_spec" \
      "\"\$OPTIND\"" \
      "$escaped_opt_name" \
      "$escaped_args"
  fi

  if [ "$long_opt_spec" ]; then
    printf "%s" "{ "
  fi

  local escaped_short_opt_spec="$short_opt_spec"
  escape_var escaped_short_opt_spec

  printf "getopts %s %s %s" \
      "$escaped_short_opt_spec" \
      "$escaped_opt_name" \
      "$escaped_args"

  if [ "$long_opt_spec" ]; then
    local escaped_long_opt_spec="$long_opt_spec"
    escape_var escaped_long_opt_spec

    printf " && eval \"\$(get_long_opts %s %s %s %s)\"; }" \
        "$escaped_long_opt_spec" \
        "\"\$OPTIND\"" \
        "$escaped_opt_name" \
        "$escaped_args"
  fi
}
