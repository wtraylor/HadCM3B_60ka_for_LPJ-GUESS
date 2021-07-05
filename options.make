# SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: CC0-1.0

# USER OPTIONS
#
# This file is in Makefile syntax.

# Boundary box for the region that is cut out: Remove the hash comment
# signs to activate cropping.
# Use 0.5 degrees steps, because that’s how the dataset is gridded:
#   longitude: 359.25, 359.75, 0.25, 0.75, 1.25, ...
#   latitude: 0.0, 0.5, 1.0, ...
# Note that negative numbers will not work, you need to specify your longitude
# in the range of 0° to 360°. (Latitude is not negative anyway because the
# dataset only covers the Northern hemisphere.)
# IT IS VERY IMPORTANT TO HAVE A DECIMAL POINT IN THE NUMBER!
# Also don’t use quote marks.
#
# These example values cover the British Isles:
LON1 = 352.5
LON2 = 3.0
LAT1 = 49.5
LAT2 = 58.5

# The time frame for output files.
# A value of 1 means the oldest year of the dataset, i.e. 60,000 years BP.
# A value of 60000 is the last year of the dataset. If left undefined, the
# whole dataset will be used.
FIRST_YEAR = 57000  # 3ka BP
LAST_YEAR  = 60000  # present-day

# Constant CO₂ value in ppm:
CO2_CONSTANT = 340

# Define NetCDF file that shall be used to create gridlist.txt as well as
# to define the square subregions. This should be the time with the lowest
# sea level in your time series so that you get the maximum land area for
# your simulation.
# gridlist_reference = external_files/bias_regrid_tas_20_22.5kyr.nc
# NetCDF variable in $(gridlist_reference).
gridlist_var = tas

# Edge length of one square with full time line, in degrees.
# A value of 4 will yield squares of size 4°x4°, which will (likely) create
# squares with 8x8 = 16 grid cells each. (But note that this depends on how
# the grid cells lie in the region defined by LON1/LON2/LAT1/LAT2. It can
# also be 8x9 or 9x9 grid cells.)
# If you don’t want your output be split into squares, use a square size of
# 360° or higher.
SQUARE_SIZE = 4
