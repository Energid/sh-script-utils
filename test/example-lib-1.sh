# shellcheck shell=sh

include example-lib-2.sh

# shellcheck disable=SC2034 # variable used by test-include-function.sh
EXAMPLE_LIB_1_SOURCE=${INCLUDE_SOURCE:-}
