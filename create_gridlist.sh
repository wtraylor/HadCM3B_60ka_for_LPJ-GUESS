#!/bin/bash
# Create an index gridlist for LPJ-GUESS from a NetCDF file.
# Note that the cf_gridlist in LPJ-GUESS just takes indices, not actual
# longitude and latitude.
#
# Author: Wolfgang Traylor (wolfgang.traylor@senckenberg.de)
#
# Usage:
#   create_gridlist.sh <in.nc> <variable> <gridlist.txt>

set -o errexit

# Arguments:
#  $1: NetCDF input file.
#  $2: NetCDF variable.
#  $3: Gridlist output file.

# Does the lon/lat grid cell contain a missing value in the first month?
# We assume that the NetCDF file is set up correctly to have the _FillValue
# set. Then `ncks` will print "_" for a missing value.
# Args:
#   1) longitude index
#   2) latitude index
cell_is_invalid() {
  local lon_index="$1"
  local lat_index="$2"
  ncks --variable="$netcdf_var" \
    --traditional \
    --dimension time,0 \
    --dimension lon,$lon_index \
    --dimension lat,$lat_index \
    "$in_file" |\
    grep --silent $netcdf_var'.*=_'
  local is_invalid=$?
  return "$is_invalid"
}

# Get number of grid cells in given dimension (longitude/latitude).
# Args: 1) variable (lat or lon)
get_dim_count() {
  local var="$1"
  # The regular expression matches the number in e.g. "lat = 30 ;".
  local regex='(?<='$var' = )\d*(?= ;$$)'
  ncks --variable="$var" "$in_file" |\
    grep --after-context=1 'dimensions:'  |\
    grep --perl-regexp --only-matching "$regex"
}

if [ ! "$#" -eq 3 ]; then
  echo 'Argument count not equal 3.' >&2
  echo 'create_gridlist.sh <in.nc> <variable> <gridlist.txt>'
  exit 1
fi

readonly in_file="$1"
readonly netcdf_var="$2"
readonly out_file="$3"

if [ ! -f "$in_file" ]; then
  echo "First argument is not a readable file: '$in_file'"
  exit 1
fi

readonly lat_count=$(get_dim_count 'lat')
readonly lon_count=$(get_dim_count 'lon')

# Delete output file to have a clean slate to append to.
rm --force "$out_file"

# Simply combine all longitudes with all latitudes.
for lat in $(seq 0 $(($lat_count - 1))); do
  for lon in $(seq 0 $(($lon_count - 1))); do
    if ! cell_is_invalid "$lon" "$lat"; then
      echo -e "$lon\t$lat" >> "$out_file"
    fi
  done
done
