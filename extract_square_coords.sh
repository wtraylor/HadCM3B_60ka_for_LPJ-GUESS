#!/bin/bash
# Extract the coordinate bounds (LON1, LON2, LAT1, LAT2) for one square
# subregion from the path given as argument.
# We assume this pattern: "...output/<LON1>_<LON2>_<LAT1>_<LAT2>/..."
#
# extract_square_coords.sh <path>

readonly str=$(echo "$1" | grep -Po '(?<=output/)\d.*_.*_.*_.*\d(?=/)')

LON1=$(echo "$str" | cut --delimiter='_' --field=1)
LON2=$(echo "$str" | cut --delimiter='_' --field=2)
LAT1=$(echo "$str" | cut --delimiter='_' --field=3)
LAT2=$(echo "$str" | cut --delimiter='_' --field=4)

echo "LON1=$LON1 LON2=$LON2 LAT1=$LAT1 LAT2=$LAT2"
