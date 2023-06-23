# shellcheck shell=sh
# shellcheck disable=SC3043 # allow 'local' usage

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
  local msg="$*"

  echo ''

  if [ "${DRY_RUN:-0}" -eq 0 ]; then
    echo "=================================================="
    echo "$msg" | tr '[:lower:]' '[:upper:]'
    echo "=================================================="
  else
    echo "# $msg"
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
  local eval=0
  local dry_run_only=0
  while true; do
    case ${1:-} in
      -e) eval=1; shift         ;;
      -n) dry_run_only=1; shift ;;
       *) break                 ;;
    esac
  done

  if [ "${DRY_RUN:-0}" -eq 0 ]; then
    if [ "$dry_run_only" -eq 0 ]; then
      if [ "$eval" -eq 1 ]; then
        eval "$*"
      else
        "$@"
      fi
    fi
  elif [ $# -gt 0 ]; then
    if [ "$eval" -eq 1 ]; then
      echo "$*"
    else
      escape "$@"
      printf '\n'
    fi
  fi
}
