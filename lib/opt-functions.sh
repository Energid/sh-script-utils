# shellcheck shell=sh

# --------------------------------------------------------------------------------
# WARNING: This file must be loaded using `include` (from 'include-function.sh').
# --------------------------------------------------------------------------------

include common-functions.sh

#
# Usage: build_opt_specs [-l LONG_NAME] [-m MEDIUM_NAME] SHORT_NAME OPT_DEF...
#
# Generate short-option specification from OPT_DEFs in $SHORT_NAME
# for use with `getopts` or `get_short_opts`. With -l, also generate
# long-option specification in $LONG_NAME for use with `get_long_opts`.
# With -m, also generate medium-option specification in $MEDIUM_NAME for
# use with `get_medium_opts`. The variables SHORT_NAME, MEDIUM_NAME
# (with -m), and LONG_NAME (with -l) will be created as global shell
# variables if they do not already exist.
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
# `getopts` to use silent error reporting.
#
# If an OPT_DEF defines a long-option but -l was not used, then an error
# will be returned. Likewise, providing a medium-option-defining OPT_DEF
# without -m will also cause an error to be returned.
#
# Warning:
#   If SHORT_NAME, MEDIUM_NAME, or LONG_NAME exists, it must be either a global
#   shell variable or a local variable with dynamic scoping. Attempting to pass
#   a local SHORT_NAME, MEDIUM_NAME, or LONG_NAME with static scoping will
#   cause a global variable to be created/updated instead. Of all the POSIX-
#   compliant shells that support local variables, only ksh93 and its
#   descendants are known to use static scoping.
#
build_opt_specs() {
  if [ ! "${_bos_recursed:-}" ]; then
    _bos_recursed=1
    build_opt_specs "$@"
    eval unset _bos_recursed \
               _bos_long_spec_name _bos_medium_spec_name _bos_short_spec_name \
               _bos_arg \
               _bos_long_opt_spec _bos_medium_opt_spec _bos_short_opt_spec \
               _bos_optdef _bos_found_bad_opt \
               _bos_found_long_opt _bos_found_medium_opt _bos_found_short_opt \
               _bos_long_opt _bos_medium_opt _bos_short_opt \
               _bos_optarg_sigil \
               _bos_long_opt_spec _bos_medium_opt_spec _bos_short_opt_spec \
         \; return $?
  fi

  _bos_long_spec_name=''
  _bos_medium_spec_name=''
  while true; do
    case ${1:-} in
      -l) _bos_long_spec_name="${2:?option '-l' requires an argument}"; shift 2 ;;
      -m) _bos_medium_spec_name="${2:?option '-m' requires an argument}"; shift 2 ;;
      *)  break ;;
    esac
  done

  _bos_short_spec_name="${1:?missing short option spec name}"; shift

  for _bos_arg in "$_bos_short_spec_name" \
             "$_bos_medium_spec_name" \
             "$_bos_long_spec_name"
  do
    if [ "$_bos_arg" ] && ! is_valid_identifier "$_bos_arg"; then
      echo "'$_bos_arg' is not a valid identifier" >&2
      return 2
    fi
  done

  _bos_short_opt_spec=":"
  _bos_medium_opt_spec=""
  _bos_long_opt_spec=""

  while [ $# -gt 0 ]; do
    _bos_optdef="$1"; shift

    _bos_found_short_opt=0
    _bos_found_medium_opt=0
    _bos_found_long_opt=0
    _bos_found_bad_opt=0
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

    _bos_short_opt=''
    _bos_medium_opt=''
    if [ "$_bos_found_short_opt" -eq 1 ]; then
      _bos_short_opt=${_bos_optdef%\(*}
      _bos_short_opt=${_bos_short_opt%:}
    elif [ "$_bos_found_medium_opt" -eq 1 ]; then
      _bos_medium_opt=${_bos_optdef%\(*}
      _bos_medium_opt=${_bos_medium_opt%:}
    fi

    _bos_long_opt=''
    if [ "$_bos_found_long_opt" -eq 1 ]; then
      _bos_long_opt=${_bos_optdef#*\(}
      _bos_long_opt=${_bos_long_opt%\)*}
    fi

    _bos_optarg_sigil=''
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
# Usage: eval "$(get_long_opts OPT_SPEC OPT_INDEX SHORT_OPT ARG...)"
#
# Parse next long option from ARGs using both OPT_SPEC and OPT_INDEX
# and store result in $SHORT_OPT.
#
# This function expects that `get_short_opts` be called after it with
# a short-option specification from `build_opt_specs`, that OPT_INDEX be
# the value of $OPTIND from the caller's context, that $SHORT_OPT be the
# variable in which `get_short_opts` will place its output, and that ARGs
# be the same positional arguments that will be passed to `get_short_opts`.
# Also OPT_SPEC must be a long-option specification from `build_opt_specs`.
#
# If SHORT_OPT does not exist, then it will be created as a global shell
# variable.
#
# If the next option processed by `get_short_opts` would be a long option in OPT_SPEC
# with any required argument present, then this function will set $SHORT_OPT
# to the name of the option and OPTARG to any argument for the option.
# Else, if the next processed option would be a recognized long option with a
# missing required argument, then $SHORT_OPT will be set to ':' and OPTARG
# to the option name. Else, if the next processed option would be an unrecognized
# long option, then $SHORT_OPT will be set to '?' and OPTARG to the option name.
# Else (if the next processed option would be a non-option or an option not in
# OPT_SPEC), then this function will return failure.
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
#     build_opt_specs -l long_opts short_opts 'l(level):' 'c(category):' 'h(help)'
#
#     eval "$(reset_opt_index)"
#     opt='' bad_opt='' no_optarg=0
#     while eval "$(get_long_opts "$long_opts" "$OPTIND" opt "$@")" \
#           || eval "$(get_short_opts "$short_opts" opt "$@")"
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
#   `get_long_opts`, `get_medium_opts`, and `get_short_opts`.
#
# Implementation Notes:
#   The reason this function must be called before `get_short_opts`, rather
#   than it calling `get_short_opts` itself, is to avoid a `dash` limitation
#   in which `getopts` misbehaves when called through a wrapper function.
#
#   The reason this function must be called before `get_short_opts`, rather
#   than before `getopts`, is to ensure changes to `OPTIND` are properly
#   coordinated between this functin and `getopts`.
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
  if [ ! "${_glo_recursed:-}" ]; then
    _glo_recursed=1
    echo '{'
    get_long_opts "$@"
    eval unset _glo_recursed \
               _glo_opt_spec _glo_opt_index _glo_opt_subindex _glo_opt_name \
               _glo_current_arg _glo_matched_opt _glo_opt_arg \
         \; echo \\\} \; return $?
  fi

  if [ ! "${1:-}" ]; then
    echo "echo 'missing long-option specification' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  _glo_opt_spec="$1"; shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing OPTIND value' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  _glo_opt_index="$1"
  _glo_opt_subindex=''
  case $_glo_opt_index in *:*)
    # NOTE: For `yash`, OPTIND has the format 'ARG_INDEX[:CHAR_INDEX]'
    _glo_opt_index="${1%%:*}"
    _glo_opt_subindex="${1#*:}"
  ;; esac
  shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing getopts output variable name' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  _glo_opt_name="$1"; shift

  if ! is_number "$_glo_opt_index" \
    || { [ -n "$_glo_opt_subindex" ] && ! is_number "$_glo_opt_subindex"; }
  then
    # shellcheck disable=SC2312 # chance of `escape` failing is negligible
    echo "echo" \
         "\"$(escape "${_glo_opt_index}${_glo_opt_subindex:+":$_glo_opt_subindex"}")" \
         "is not a valid number\" >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi

  if ! is_valid_identifier "$_glo_opt_name"; then
    # shellcheck disable=SC2312 # chance of `escape` failing is negligible
    echo "echo \"$(escape "$_glo_opt_name") is not a valid identifier\" >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi

  if [ "${ZSH_VERSION:-}" ]; then
    if [ "$_glo_opt_index" -eq 0 ]; then
      # `zsh` treats an OPTIND of `0` the same as one of `1`, except the
      # former commands `getopts` to reset its internal state
      _glo_opt_index=1
    else
      # apply any `zsh` OPTIND correction from `get_short_opts`
      _glo_opt_index=$((_glo_opt_index + ${__ZSH_GETOPTS_OPTIND_OFFSET:-0}))
    fi
  fi

  if [ "$_glo_opt_index" -gt $# ]; then
    echo "false"; return
  fi

  eval "_glo_current_arg=\"\$$_glo_opt_index\""
  if [ -n "$_glo_opt_subindex" ] \
    && [ "$_glo_opt_subindex" -ge "${#_glo_current_arg}" ]
  then
    # NOTE: `yash` sometimes increments the CHAR_INDEX component of OPTIND
    #       out of bounds, rather than incrementing the ARG_INDEX component,
    #       after parsing a short option with `getopts`.
    _glo_opt_index=$((_glo_opt_index + 1))
    eval "_glo_current_arg=\"\$$_glo_opt_index\""
  fi

  # shellcheck disable=SC2154 # _glo_current_arg set by `eval` above
  case $_glo_current_arg in --?*) ;; *)
    # not a long option
    echo "false"; return
  ;; esac

  _glo_current_arg=${_glo_current_arg#--*}

  _glo_matched_opt=${_glo_current_arg%%=*}

  case " $_glo_opt_spec " in
    *" $_glo_matched_opt "*)
      if [ "${_glo_current_arg%%=*}" != "$_glo_current_arg" ]; then
        # long option with unexpected argument
        echo "OPTARG=$_glo_matched_opt"
        _glo_matched_opt='?'
      fi

      echo "OPTIND=$((_glo_opt_index + 1))"
      ;;
    *" $_glo_matched_opt: "*)
      if [ "${_glo_current_arg%%=*}" != "$_glo_current_arg" ]; then
        # long option with '='-delimited argument
        _glo_opt_arg="${_glo_current_arg#*=}"
        escape_var _glo_opt_arg
        echo "OPTARG=$_glo_opt_arg"

        echo "OPTIND=$((_glo_opt_index + 1))"
      elif [ "$((_glo_opt_index + 1))" -le $# ]; then
        # long option with IFS-delimited argument
        eval "_glo_opt_arg=\"\$$((_glo_opt_index + 1))\""
        escape_var _glo_opt_arg
        echo "OPTARG=$_glo_opt_arg"

        echo "OPTIND=$((_glo_opt_index + 2))"
      else
        # long option with missing argument
        echo "OPTARG=$_glo_matched_opt"
        _glo_matched_opt=':'
        echo "OPTIND=$((_glo_opt_index + 1))"
      fi
      ;;
    *)
      # unrecognized long option
      echo "OPTARG=$_glo_matched_opt"
      _glo_matched_opt='?'
      echo "OPTIND=$((_glo_opt_index + 1))"
      ;;
  esac

  echo "$_glo_opt_name='$_glo_matched_opt'"

  if [ "${ZSH_VERSION:-}" ]; then
    # clear `zsh` OPTIND correction
    echo '__ZSH_GETOPTS_OPTIND_OFFSET=0'
  fi
}

#
# Usage: eval "$(get_medium_opts OPT_SPEC OPT_INDEX SHORT_OPT ARG...)"
#
# Parse next medium option from ARGs using both OPT_SPEC and OPT_INDEX
# and store result in $SHORT_OPT.
#
# This function expects that `get_short_opts` be called after it with
# a short-option specification from `build_opt_specs`, that OPT_INDEX
# be the value of $OPTIND from the caller's context, $SHORT_OPT be the
# variable in which `get_short_opts` will place its output, and that ARGs
# be the same positional arguments that will be passed to `get_short_opts`.
# Also OPT_SPEC must be a medium-option specification from `build_opt_specs`.
#
# If SHORT_OPT does not exist, then it will be created as a global shell
# variable.
#
# If the next argument processed by `get_short_opts` would be a medium option
# in OPT_SPEC with any required argument present, then this function will
# set $SHORT_OPT to the name of the option, set OPTARG to any argument for
# the option, and increment OPTIND appropriately. Else, if the next processed
# argument would be a recognized medium option with a missing required argument,
# then $SHORT_OPT will be set to ':', OPTARG will be set to the option name,
# and OPTIND will be incremented. Else (if the next processed argument would
# be a non-option or an option not in OPT_SPEC), then this function will
# return failure.
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
#     build_opt_specs -l long_opts -m medium_opts short_opts \
#                     'id(input-dir):' 'od(output-dir):' 'h(help)'
#
#     eval "$(reset_opt_index)"
#     opt='' bad_opt='' no_optarg=0
#     while eval "$(get_long_opts "$long_opts" "$OPTIND" opt "$@")" \
#           || eval "$(get_medium_opts "$medium_opts" "$OPTIND" opt "$@")" \
#           || eval "$(get_short_opts "$short_opts" opt "$@")"
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
#   `get_long_opts`, `get_medium_opts`, and `get_short_opts`.
#
# Implementation Notes:
#   The reason this function must be called before `get_short_opts`, rather
#   than it calling `get_short_opts` itself, is to avoid a `dash` limitation
#   in which `getopts` misbehaves when called through a wrapper function.
#
#   The reason this function must be called before `get_short_opts`, rather
#   than before `getopts`, is to ensure changes to `OPTIND` are properly
#   coordinated between this functin and `getopts`.
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
get_medium_opts() {
  if [ ! "${_gmo_recursed:-}" ]; then
    _gmo_recursed=1
    echo '{'
    get_medium_opts "$@"
    eval unset _gmo_recursed \
               _gmo_opt_spec _gmo_opt_index _gmo_opt_subindex _gmo_opt_name \
               _gmo_current_arg _gmo_matched_opt _gmo_opt_arg \
         \; echo \\\} \; return $?
  fi

  if [ ! "${1:-}" ]; then
    echo "echo 'missing medium-option specification' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  _gmo_opt_spec="$1"; shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing OPTIND value' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  _gmo_opt_index="$1"
  _gmo_opt_subindex=''
  case $_gmo_opt_index in *:*)
    # NOTE: For `yash`, OPTIND has the format 'ARG_INDEX[:CHAR_INDEX]'
    _gmo_opt_index="${1%%:*}"
    _gmo_opt_subindex="${1#*:}"
  ;; esac
  shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing getopts output variable name' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  _gmo_opt_name="$1"; shift

  if ! is_number "$_gmo_opt_index" \
    || { [ -n "$_gmo_opt_subindex" ] && ! is_number "$_gmo_opt_subindex"; }
  then
    # shellcheck disable=SC2312 # chance of `escape` failing is negligible
    echo "echo" \
         "\"$(escape "${_gmo_opt_index}${_gmo_opt_subindex:+":$_gmo_opt_subindex"}")" \
         "is not a valid number\" >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi

  if ! is_valid_identifier "$_gmo_opt_name"; then
    # shellcheck disable=SC2312 # chance of `escape` failing is negligible
    echo "echo \"$(escape "$_gmo_opt_name") is not a valid identifier\" >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi

  if [ "${ZSH_VERSION:-}" ]; then
    if [ "$_gmo_opt_index" -eq 0 ]; then
      # `zsh` treats an OPTIND of `0` the same as one of `1`, except the
      # former commands `getopts` to reset its internal state
      _gmo_opt_index=1
    else
      # apply any `zsh` OPTIND correction from `get_short_opts`
      _gmo_opt_index=$((_gmo_opt_index + ${__ZSH_GETOPTS_OPTIND_OFFSET:-0}))
    fi
  fi

  if [ "$_gmo_opt_index" -gt $# ]; then
    echo "false"; return
  fi

  eval "_gmo_current_arg=\"\$$_gmo_opt_index\""
  if [ -n "$_gmo_opt_subindex" ] \
    && [ "$_gmo_opt_subindex" -ge "${#_gmo_current_arg}" ]
  then
    # NOTE: `yash` sometimes increments the CHAR_INDEX component of OPTIND
    #       out of bounds, rather than incrementing the ARG_INDEX component,
    #       after parsing a short option with `getopts`.
    _gmo_opt_index=$((_gmo_opt_index + 1))
    eval "_gmo_current_arg=\"\$$_gmo_opt_index\""
  fi

  # shellcheck disable=SC2154 # _gmo_current_arg set by `eval` above
  case $_gmo_current_arg in -*) ;; *)
    # not an option
    echo "false"; return
  ;; esac

  _gmo_matched_opt="${_gmo_current_arg#-}"

  case " $_gmo_opt_spec " in
    *" $_gmo_matched_opt "*)
      # medium option with no argument
      echo "OPTIND=$((_gmo_opt_index + 1))"
      ;;
    *" $_gmo_matched_opt: "*)
      if [ "$((_gmo_opt_index + 1))" -le $# ]; then
        # medium option with provided argument
        eval "_gmo_opt_arg=\"\$$((_gmo_opt_index + 1))\""
        escape_var _gmo_opt_arg
        # shellcheck disable=SC2154 # _gmo_opt_arg set by `eval` above
        echo "OPTARG=$_gmo_opt_arg"

        echo "OPTIND=$((_gmo_opt_index + 2))"
      else
        # medium option with missing argument
        echo "OPTARG=$_gmo_matched_opt"
        echo "OPTIND=$((_gmo_opt_index + 1))"
        _gmo_matched_opt=':'
      fi
      ;;
    *)
      echo "false"; return
      ;;
  esac

  echo "$_gmo_opt_name='$_gmo_matched_opt'"

  if [ "${ZSH_VERSION:-}" ]; then
    # clear `zsh` OPTIND correction
    echo '__ZSH_GETOPTS_OPTIND_OFFSET=0'
  fi
}

#
# Usage: eval "$(get_short_opts OPT_SPEC SHORT_OPT ARG..)"
#
# Parse next short option from ARGs using OPT_SPEC and store result in $SHORT_OPT.
#
# This function wraps the `getopts` shell builtin and makes it compatible
# with the `get_long_opts` and `get_medium_opts` functions. See `getopts`
# documentation for how OPT_SPEC, SHORT_OPT, and ARGs are processed.
#
# Implementation Notes:
#   The reason the output of this function must be passed to `eval`, rather than
#   the function called directly, is to avoid a `dash` limitation where `getopts`
#   ignores any change to `OPTIND` that was a side effect of a function call.
#
#   The raison d'etre of this function is to work around the following unusual
#   behavior in the `zsh` implementation of the `getopts` builtin:
#     - $OPTIND must be set to `0`, rather than the `1` specified by POSIX,
#       to reset the internal state of `getopts`.
#     - $OPTIND is incremented before processing a non-argumented option
#       and after processing an argumented option, whereas other shells
#       (except `yash`) increment $OPTIND after processing any option.
#     - $OPTIND cannot be reliably adjusted after `getopts` has started
#       parsing a sequence of non-argumented options, whereas other shells
#       are more forgiving of arbitrary $OPTIND adjustments.
#
get_short_opts() {
  echo "{"

  if [ "${ZSH_VERSION:-}" ] && is_valid_identifier "${2:-\?}"; then
    _gso_zsh_opt="$2"

         # clear any OPTIND correction
    echo '__ZSH_GETOPTS_OPTIND_OFFSET=0'
         # save current OPTIND so we can know if `getopts` increments it
    echo '__ZSH_GETOPTS_PREV_OPTIND=$OPTIND'
  fi

  # call `getopts` with given parameters
  printf 'getopts %s' "$(escape "$@")"

  if [ -z "${_gso_zsh_opt:-}" ]; then
    echo ''
  else
    echo ' && \'
          # if `getopts` did not increment $OPTIND
          # (or $OPTIND was incremented from `0` to `1`)...
    echo 'if [ "$OPTIND" -eq "$__ZSH_GETOPTS_PREV_OPTIND" ] \'
    echo '     || [ "$__ZSH_GETOPTS_PREV_OPTIND" -eq 0 ]'
          # then it must have parsed a non-argumented option
    echo 'then'
            # add the newly parsed option to the list of short options already
            # parsed for the argument with index $OPTIND
    echo "  case \${$_gso_zsh_opt} in"
    echo '    \?|:)'
    echo '       __ZSH_GETOPTS_PARSED_OPTS="${__ZSH_GETOPTS_PARSED_OPTS:-}${OPTARG}"'
    echo '      ;;'
    echo '    *)'
    echo "      __ZSH_GETOPTS_PARSED_OPTS=\"\${__ZSH_GETOPTS_PARSED_OPTS:-}\${$_gso_zsh_opt}\""
    echo '      ;;'
    echo '  esac'
            # if the argument with index $OPTIND contains nothing but one or
            # more non-argumented short options and `getopts` has parsed all
            # those options...
    echo '  if eval test "-${__ZSH_GETOPTS_PARSED_OPTS:-}" = "\${$OPTIND}"; then'
              # clear parsed option tracking
    echo "    __ZSH_GETOPTS_PARSED_OPTS=''"
              # set OPTIND correction so `get_long_opts` or `get_medium_opts`
              # can process the next argument
    echo '    __ZSH_GETOPTS_OPTIND_OFFSET=1'
    echo '  fi'
          # else `getopts` must have parsed an argumented option
    echo 'else'
            # clear parsed option tracking
    echo "  __ZSH_GETOPTS_PARSED_OPTS=''"
    echo 'fi'
  fi

  echo "}"

  unset _gso_zsh_opt
}

#
# Usage: eval "$(reset_opt_index)"
#
# Reset internal state of `get_long_opts`, `get_medium_opts`, and
# `get_short_opts` to prepare functions to parse new set of arguments.
#
# Implementation Notes:
#   The reason the output of this function must be passed to `eval`, rather than
#   the function called directly, is to avoid a `dash` limitation where `getopts`
#   ignores any change to `OPTIND` that was a side effect of a function call.
#
reset_opt_index() {
  echo '{'
  if [ -z "${ZSH_VERSION:-}" ]; then
    echo 'OPTIND=1'
  else
    echo 'OPTIND=0'
    echo '__ZSH_GETOPTS_OPTIND_OFFSET=0'
    echo "__ZSH_GETOPTS_PARSED_OPTS=''"
  fi
  echo '}'
}

#
# Usage: opt_parser_def [-l LONG_OPT_SPEC] [-m MEDIUM_OPT_SPEC]
#                       SHORT_OPT_SPEC SHORT_OPT ARGS...
#
# Generate evaluable code to call `get_short_opts` with given short-option
# specification SHORT_OPT_SPEC, output variable SHORT_OPT, and positional ARGs.
#
# With -l, also generate code to call `get_long_opts` with given long-option
# specification LONG_OPT_SPEC, output variable SHORT_OPT, and positional ARGs.
#
# With -m, also generate code to call `get_medium_opts` with given medium-option
# specification MEDIUM_OPT_SPEC, output variable SHORT_OPT, and positional ARGs.
#
# If SHORT_OPT does not exist, then it will be created as a global shell
# variable.
#
# The output of this function should be passed to `eval` for execution.
#
# Example:
#   parse_args() {
#     input_dir=''
#     output_dir=''
#     help=0
#
#     build_opt_specs -l long_opts -m medium_opts short_opts \
#                     'id(input-dir):' 'od(output-dir):' 'h(help)'
#
#     opt_parser="$(opt_parser_def -l "$long_opts" -m "$medium_opts" \
#                                  "$short_opts" opt "$@")"
#
#     eval "$(reset_opt_index)"
#     opt='' bad_opt='' no_optarg=0
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
  if [ ! "${_opd_recursed:-}" ]; then
    _opd_recursed=1
    printf '{ '
    opt_parser_def "$@"
    eval unset _opd_recursed \
               _opd_long_opt_spec _opd_medium_opt_spec _opd_short_opt_spec \
               _opd_escaped_opt_name _opd_escaped_args \
               _opd_escaped_short_opt_spec \
               _opd_escaped_medium_opt_spec \
               _opd_escaped_long_opt_spec \
         \; printf \"\; \}\" \; return $?
  fi

  _opd_long_opt_spec=''
  _opd_medium_opt_spec=''
  while true; do
    case ${1:-} in
      -l) if [ ! "${2:-}" ]; then
            echo "echo \"option '-l' requires an argument\" >&2"
            echo "return 2 2>/dev/null || exit 2"
            return
          else
            _opd_long_opt_spec="$2"; shift 2
          fi
          ;;

      -m) if [ ! "${2:-}" ]; then
            echo "echo \"option '-m' requires an argument\" >&2"
            echo "return 2 2>/dev/null || exit 2"
            return
          else
            _opd_medium_opt_spec="$2"; shift 2
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
  _opd_short_opt_spec="$1"; shift

  if [ ! "${1:-}" ]; then
    echo "echo 'missing getopts output variable name' >&2"
    echo "return 2 2>/dev/null || exit 2"
    return
  fi
  _opd_escaped_opt_name="$1"; shift
  escape_var _opd_escaped_opt_name

  _opd_escaped_args=$(escape "$@")

  if [ "$_opd_long_opt_spec" ]; then
    _opd_escaped_long_opt_spec="$_opd_long_opt_spec"
    escape_var _opd_escaped_long_opt_spec

    printf "eval \"\$(get_long_opts %s %s %s %s)\" || " \
        "$_opd_escaped_long_opt_spec" \
        "\"\$OPTIND\"" \
        "$_opd_escaped_opt_name" \
        "$_opd_escaped_args"
  fi

  if [ "$_opd_medium_opt_spec" ]; then
    _opd_escaped_medium_opt_spec="$_opd_medium_opt_spec"
    escape_var _opd_escaped_medium_opt_spec

    printf "eval \"\$(get_medium_opts %s %s %s %s)\" || " \
      "$_opd_escaped_medium_opt_spec" \
      "\"\$OPTIND\"" \
      "$_opd_escaped_opt_name" \
      "$_opd_escaped_args"
  fi

  _opd_escaped_short_opt_spec="$_opd_short_opt_spec"
  escape_var _opd_escaped_short_opt_spec

  printf "eval \"\$(get_short_opts %s %s %s)\"" \
    "$_opd_escaped_short_opt_spec" \
    "$_opd_escaped_opt_name" \
    "$_opd_escaped_args"
}
