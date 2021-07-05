#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2021 W. Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

#
# Calculate longitude and latitude of small square subregions that make up
# the user-defined region given by environment variables LON1, LON2, LAT1,
# LAT2.
#
# Author: Wolfgang Traylor (wolfgang.traylor@senckenberg.de)

import os
import sys


def inc_lat(x):
    """ Increment latitude x by one square edge length. """
    return min(x + square_size, lat_bounds[1])


def inc_lon(x):
    """ Increment longitude x by one square edge length. """
    return min(x + square_size, lon_bounds[1])


def norm_lon(x):
    """ Normalize longitude x into range [0,360]. """
    if x == 360:
        return 360
    else:
        return x % 360


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

while square[2] <= lat_bounds[1] - .001:  # latitude loop from S to N
    while square[0] <= lon_bounds[1] - .001:  # longitude loop from E to W
        square_normalized = [norm_lon(square[0]), norm_lon(square[1]),
                             square[2], square[3]]
        squares += [square_normalized[:]]
        sys.stdout.write("%.2f %.2f %.2f %.2f\n" % tuple(squares[-1]))
        # Move to next square along the longitude axis. Leave latitude within
        # this loop untouched.
        square = [square[1], inc_lon(square[1]),
                  square[2], square[3]]
    # Move to next square along the latitude axis and reset longitude to the
    # beginning.
    square = [lon_bounds[0], inc_lon(lon_bounds[0]),
              square[3], inc_lat(square[3])]
