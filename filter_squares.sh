#!/bin/bash
#
# Filter square subregions from stdin to stdout.
# Each line is a subregion in the format "<east> <west> <south> <north>" in
# degrees.
# If the subregion contains at least one grid cell with a non-missing value in
# the NetCDF file provided as environment variable `gridlist_reference` (with
# variable `gridlist_var`), the line is passed to stdout, otherwise it’s
# dropped.
#
# Author: Wolfgang Traylor <wolfgang.traylor@senckenberg.de>

square_is_valid(){
  (>&2 echo "Checking if square subregion is valid: $square")
  local east=$(echo "$square" | cut --field=1 --delimiter=' ')
  local west=$(echo "$square" | cut --field=2 --delimiter=' ')
  local south=$(echo "$square" | cut --field=3 --delimiter=' ')
  local north=$(echo "$square" | cut --field=4 --delimiter=' ')
  # -H: Don’t print metadata.
  # -C: Don’t print coordinates.
  ncks --variable="$gridlist_var" \
    -H \
    -C \
    --string='%f\n'\
    --dimension=lon,$east,$west \
    --dimension=lat,$south,$north \
    "$gridlist_reference" | \
    grep -v '_' | \
    grep -v -P '^\s*$' | \
    grep --perl-regexp --silent '\d'
  # If grep found any number in the output, we consider this square valid.
}

if [ ! -f "$gridlist_reference" ]; then
  (>&2 echo "$0: Could not find gridlist reference file: '$gridlist_reference'")
  exit 1
fi

if [ -z "$gridlist_var" ]; then
  (>&2 echo "$0: Environment variable 'gridlist_var' undefined.")
  exit 1
fi

while read square; do
  if square_is_valid; then
    echo "$square"
  fi
done

exit 0
