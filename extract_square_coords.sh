#!/bin/bash

# SPDX-FileCopyrightText: 2021 W. Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

# Extract the coordinate bounds (LON1, LON2, LAT1, LAT2) for one square
# subregion from the path given as argument.
# We assume this pattern: "...output/<ID>_<LON1>_<LON2>_<LAT1>_<LAT2>/..."
#
# The output (stdout) is in the form of assignments for environment
# variables to be passed to `make`, e.g.:
#   "LON1=0.25 LON2=5.25 LAT1=54.0 LAT2=58.0"
#
# Author: Wolfgang Traylor (wolfgang.traylor@senckenberg.de)
#
# Usage:
#   extract_square_coords.sh <path>

readonly str=$(echo "$1" | grep -Po '(?<=output/)\d.*_.*_.*_.*\d(?=/)')

ID=$(echo "$str" | cut --delimiter='_' --field=1)
LON1=$(echo "$str" | cut --delimiter='_' --field=2)
LON2=$(echo "$str" | cut --delimiter='_' --field=3)
LAT1=$(echo "$str" | cut --delimiter='_' --field=4)
LAT2=$(echo "$str" | cut --delimiter='_' --field=5)

echo "ID=$ID LON1=$LON1 LON2=$LON2 LAT1=$LAT1 LAT2=$LAT2"
