#!/usr/bin/env python3
#
# Convert time axis of given NetCDF file from "months since" to "days
# since", starting to count from 60,000 years BP (the beginning of the
# HadCM3B simulation).
# Arguments:
#   1) Input NetCDF file.
#   2) Output NetCDF file.
#
# Author: Wolfgang Traylor, SBiK-F (wolfgang.traylor@senckenberg.de)
# License: See LICENSE file in repository.

import os
import re
import sys

import numpy
import xarray as xr

if len(sys.argv) != 3:
    sys.exit('Please provide exactly two argument:\n'
             f'{sys.argv[0]} <in.nc> <out.nc>')

in_file = sys.argv[1]
out_file = sys.argv[2]

if not os.path.isfile(in_file):
    sys.exit(f'File does not exist: {in_file}')
if os.path.isfile(out_file):
    sys.exit(f'Output file already exists: {out_file}')

# Find the starting year for this particular file. Since the NetCDF files
# don’t contain that information in their metadata, we need to derive it
# from the filename.
# The counting starts with `start_year==0` at the first HadCM3B simulation
# year, which is 60,000 years BP.
# For example the filename "regrid_downSol_Seaice_mm_s3_srf_2.5_5kyr.nc" will
# yield the start year 55000 (60ka - 5ka).
try:
    start_year_str = re.search(r'(?<=_)\d+\.?5?(?=kyr\.nc)', in_file).group(0)
    start_year = (60 - float(start_year_str)) * 1000
except (AttributeError, ValueError):
    sys.exit('Failed to extract year information from file name:\n'
             '"%s"\n' % in_file +
             'Did you change the original filename?')
start_day = start_year * 365

# Prepare a vector of values for the time axis in "days since".
# It has 30,000 entries for the 2,400 years of transient monthly data in the
# NetCDF file.

month_lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

total_month_count = 30000
days_axis = numpy.zeros(total_month_count, dtype='i')  # reserve memory
days_axis[0] = start_day + 15
for i in range(len(days_axis)-1):
    current_month = i % 12
    days_axis[i+1] = start_day + days_axis[i] + month_lengths[current_month]
# Now days_axis contains the Julian day for the +/- middle of each month:
# [15, 43, 74, 104, ...]

# Write the new time axis into the NetCDF file.
# Note that the "unit" attribute must be changed externally.
ds = xr.open_dataset(in_file, decode_times=False).load()
ds["time"].values = days_axis
ds.to_netcdf(out_file, mode='w', engine='netcdf4')
ds.close()

# Exit with success code.
sys.exit(0)
