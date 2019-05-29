#!/bin/bash
# Author: Wolfgang Traylor
# Combine each line of file 1 with each line of file 2.

set -o errexit

readonly LON_FILE="$1"
readonly LAT_FILE="$2"

while read lon; do
  while read lat; do
    echo -e "$lon\t$lat"
  done < "$LAT_FILE"
done < "$LON_FILE"

exit 0
