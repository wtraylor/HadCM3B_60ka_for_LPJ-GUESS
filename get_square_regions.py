#!/usr/bin/env python3
#
# Calculate longitude and latitude of small square subregions that make up
# the user-defined region given by environment variables LON1, LON2, LAT1,
# LAT2. Whether a square is valid is determined by whether it has at least
# one valid grid cell in the `gridlist_reference` NetCDF file at timestep
# 1.
#
# Author: Wolfgang Traylor (wolfgang.traylor@senckenberg.de)

import os
import sys
import subprocess


def inc_lat(x):
    """ Increment latitude x by one square edge length. """
    return min(x + square_size, lat_bounds[1])


def inc_lon(x):
    """ Increment longitude x by one square edge length. """
    return min(x + square_size, lon_bounds[1])


def square_is_valid(s):
    """ Return true if square has at least one valid grid cell. """
    assert(os.environ['gridlist_var'])
    assert(os.environ['gridlist_reference'])
    ncks = subprocess.Popen(['ncks',
                             '--variable=%s' % os.environ['gridlist_var'],
                             '-H',  # no metadata
                             '-C',  # no coordinates
                             r'--string="%f\n"',  # prints '_' if missing
                             '--dimension=time,0',  # First timestep.
                             '--dimension=lon,%.2f,%.2f' % (s[0], s[1]),
                             '--dimension=lat,%.2f,%.2f' % (s[2], s[3]),
                             os.environ['gridlist_reference']],
                            stdout=subprocess.PIPE)
    # If only one grid cell value is found that’s not missing (i.e. '_'),
    # we consider this square valid.
    grep = subprocess.Popen(['grep', '--invert-match', '--silent', '_'],
                            stdin=ncks.stdout,
                            stdout=subprocess.PIPE).stdout
    for line in grep.readlines():
        print(str(line).strip(), file=sys.stderr)
        if not str(line).strip():
            return True  # Found a number!
    return False  # No valid number found


# Edge length of one square.
square_size = float(os.environ['SQUARE_SIZE'])

lon_bounds = [float(os.environ['LON1']), float(os.environ['LON2'])]
lat_bounds = [float(os.environ['LAT1']), float(os.environ['LAT2'])]
# If the area extends over the 360° longitude, we just reverse the longitudes
# so that the second longitude is always bigger than the first.
if lon_bounds[0] > lon_bounds[1]:
    lon_bounds[1] += 360
assert lon_bounds[0] >= 0.0 and lon_bounds[0] <= 360.0
assert lon_bounds[1] >= 0.0 and lon_bounds[1] <= 2*360.0
assert lon_bounds[0] < lon_bounds[1]
assert lat_bounds[0] >= 0.0 and lat_bounds[0] <= 90.0
assert lat_bounds[1] >= 0.0 and lat_bounds[1] <= 90.0
assert lat_bounds[0] < lat_bounds[1]

# We assume here that longitude is still in the original 0/360° format.

# Each square it defined by its bounds in a list: [lon1, lon2, lat1, lat2]
square = [lon_bounds[0], inc_lon(lon_bounds[0]),
          lat_bounds[0], inc_lat(lat_bounds[0])]

# List of all squares.
squares = list()

# Construct all possible squares.
while square[2] <= lat_bounds[1] - .001:  # latitude loop from S to N
    while square[0] <= lon_bounds[1] - .001:  # longitude loop from E to W
        square_normalized = [square[0] % 360, square[1] % 360,
                             square[2], square[3]]
        squares += [square_normalized[:]]
        # Move to next square along the longitude axis. Leave latitude within
        # this loop untouched.
        square = [square[1], inc_lon(square[1]),
                  square[2], square[3]]
    # Move to next square along the latitude axis and reset longitude to the
    # beginning.
    square = [lon_bounds[0], inc_lon(lon_bounds[0]),
              square[3], inc_lat(square[3])]

# Print out only those squares that have at least one valid grid cell.
# Print all squares to STDOUT.
for s in squares:
    if square_is_valid(s):
        print("VALID: " + str(s), file=sys.stderr)
        sys.stdout.write("%.2f %.2f %.2f %.2f\n" % tuple(s))
    else:
        print("not valid: " + str(s), file=sys.stderr)
