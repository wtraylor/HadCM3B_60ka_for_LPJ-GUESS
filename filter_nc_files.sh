#!/bin/bash
# Filter HadCM3B NetCDF files (received as arguments) by whether they fall
# within the time frame given by FIRST_YEAR and LAST_YEAR.
#
# Author: Wolfgang Traylor (wolfgang.traylor@senckenberg.de)
#
# Usage:
#   filter_nc_files.sh [file]...

set -o errexit
set -o nounset

# Check whether given NetCDF file covers at least part of the desired time
# frame.
function is_in_timeframe() {
  local YEARS=($(./extract_years_from_filename.py "$1"))
  if [ "${YEARS[0]}" -le "$LAST_YEAR" ] && \
    [ "${YEARS[1]}" -ge "$FIRST_YEAR" ]
  then
    return 0  # true
  fi
  return 1  # false
}

while [ $# -ge 1 ]; do
  FILE="$1"
  if [ ! -f "$FILE" ]; then
    (>&2 echo "$0: Not a valid file: '$FILE'")
    exit 1
  fi
  if is_in_timeframe "$FILE"; then
    echo "$1"
  fi
  shift 1
done
