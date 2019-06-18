#!/bin/bash
# Get the directory names for all the square subregions.
# The directories are identified by the south-east corner of the square.
#
# Author: Wolfgang Traylor (wolfgang.traylor@senckenberg.de)

./get_square_regions.py | while read square; do
  east=$(echo "$square" | cut --field=1 --delimiter=' ')
  west=$(echo "$square" | cut --field=2 --delimiter=' ')
  south=$(echo "$square" | cut --field=3 --delimiter=' ')
  north=$(echo "$square" | cut --field=4 --delimiter=' ')
  echo "${east}_${west}_${south}_${north}"
done
