#!/bin/bash
#
# Sort the HadCM3B output files in the argument list chronologically, using
# the filename pattern.
#
# Author: Wolfgang Traylor <wolfgang.traylor@senckenberg.de>

# The problem is that the years in the HadCM3B output files don’t have leading
# zeros. So when we sort by their original name, the order is broken.
# The simple solution is to *add leading zeros*, sort, and then restore the original names.

function add_zeros(){
  sed 's;_0_2.5kyr.nc;_00_2.5kyr.nc;' |\
    sed 's;_2.5_5kyr.nc;_02.5_5kyr.nc;' |\
    sed 's;_5_7.5kyr.nc;_05_7.5kyr.nc;' |\
    sed 's;_7.5_10kyr.nc;_07.5_10kyr.nc;'
}

function restore_original(){
  sed 's;_00_2.5kyr.nc;_0_2.5kyr.nc;' |\
    sed 's;_02.5_5kyr.nc;_2.5_5kyr.nc;' |\
    sed 's;_05_7.5kyr.nc;_5_7.5kyr.nc;' |\
    sed 's;_07.5_10kyr.nc;_7.5_10kyr.nc;'
}

if [[ "$#" -eq 0 ]]; then
  echo >&2 "$0: ERROR - No input files received."
  exit 1
fi

for f in $*; do
  if [[ ! -f "$f" ]]; then
    echo >&2 "$0: ERROR - Input file does not exist: '$f'"
    exit 1
  fi
done

printf "%s\n" $* | sed 's; ;\n;g' | add_zeros | sort --reverse | restore_original
