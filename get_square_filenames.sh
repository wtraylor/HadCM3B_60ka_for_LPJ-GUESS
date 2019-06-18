#!/bin/bash
# Given an input filename (a NetCDF file), this script returns one new
# filename for each square subregion.
# The new file is identified by the south-east corner of the square.
#
# Author: Wolfgang Traylor (wolfgang.traylor@senckenberg.de)
#
# Usage:
#   ./get_square_filenames.sh <file1> <file2> ...

for f in "$@"; do
  base=$(basename "$f")
  stub=${base%.nc}  # without file ending
  ./get_square_regions.py | while read square; do
    east=$(echo "$square" | cut --field=1 --delimiter=' ')
    south=$(echo "$square" | cut --field=3 --delimiter=' ')
    echo "${stub}_${east}_${south}.nc"
  done
done
