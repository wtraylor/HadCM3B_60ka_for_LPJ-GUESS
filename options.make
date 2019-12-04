# USER OPTIONS
#
# This file is in Makefile syntax.

# The time frame for output files.
# A value of 1 means the oldest year of the dataset, i.e. 60,000 years BP.
# A value of 60000 is the last year of the dataset. If left undefined, the
# whole dataset will be used.
FIRST_YEAR = 59500  # 500 years BP
LAST_YEAR  = 60000  # present-day

# Constant CO₂ value in ppm:
CO2_CONSTANT = 340

# Define NetCDF file that shall be used to create gridlist.txt as well as
# to define the square subregions. This should be the time with the lowest
# sea level in your time series so that you get the maximum land area for
# your simulation.
gridlist_reference = external_files/bias_regrid_tas_0_2.5kyr.nc
# NetCDF variable in $(gridlist_reference).
gridlist_var = tas

# Edge length of one square with full time line, in degrees.
# A value of 4 will yield squares of size 4°x4°, which will (likely) create
# squares with 8x8 = 16 grid cells each. (But note that this depends on how
# the grid cells lie in the region defined by LON1/LON2/LAT1/LAT2. It can
# also be 8x9 or 9x9 grid cells.)
# If you don’t want your output be split into squares, use a square size of
# 360° or higher.
SQUARE_SIZE = 20
