# shellcheck shell=sh

# --------------------------------------------------------------------------------
# WARNING: This file must be loaded using `include` (from 'include-function.sh').
# --------------------------------------------------------------------------------

include common-functions.sh

#
# Usage: print_banner MESSAGE...
#
# Capitalize and concatenate MESSAGEs and print the result with leading
# newline and wrapped by leading and following borders.
#
# If the shell variable DRY_RUN is defined with a non-zero value, then
# `print_banner` will instead concatenate MESSAGEs and print them on a
# single line as a shell comment.
#
print_banner() {
  if [ ! "${1:-}" ]; then
    echo "missing message" >&2
    return 2
  fi

  echo ''

  if [ "${DRY_RUN:-0}" -eq 0 ]; then
    echo "=================================================="
    echo "$*" | tr '[:lower:]' '[:upper:]'
    echo "=================================================="
  else
    echo "# $*"
  fi
}

#
# Usage: run [-n] COMMAND [ARG]...
#   or:  run [-n] -e ARG...
#
# In first form, execute given COMMAND with given ARGs. If the shell
# variable DRY_RUN is defined a with non-zero value, then print COMMAND
# and ARGs in `eval`-ready format instead.
#
# In second form, concatenate given ARGs and pass the result to `eval`.
# If the shell variable DRY_RUN is defined with a non-zero value,
# then print the concatenated ARGs insead.
#
# In either form, if the '-n' option is used, then the given command(s)
# will never be executed but will still be printed when DRY_RUN is non-zero.
#
run() {
  _run_eval=0
  _run_dry_only=0
  while true; do
    case ${1:-} in
      -e) _run_eval=1; shift     ;;
      -n) _run_dry_only=1; shift ;;
       *) break                  ;;
    esac
  done

  : "${1:?missing missing argument(s)}"

  if [ "${DRY_RUN:-0}" -eq 0 ]; then
    if [ "$_run_dry_only" -eq 0 ]; then
      if [ "$_run_eval" -eq 1 ]; then
        eval "$*"
      else
        "$@"
      fi
    fi
  elif [ $# -gt 0 ]; then
    if [ "$_run_eval" -eq 1 ]; then
      echo "$*"
    else
      escape "$@"
      printf '\n'
    fi
  fi

  eval "unset _run_eval _run_dry_only; return $?"
}
