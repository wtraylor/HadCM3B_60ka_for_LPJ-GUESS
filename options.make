# USER OPTIONS

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

# Constant CO₂ value in ppm:
CO2_CONSTANT = 340

# Define NetCDF file that shall be used to create gridlist.txt as well as
# to define the square subregions. This should be the time with the lowest
# sea level in your time series so that you get the maximum land area for
# your simulation.
gridlist_reference = external_files/bias_regrid_tas_20_22.5kyr.nc
gridlist_var = tas  # NetCDF variable in $(gridlist_reference).

# Edge length of one square with full time line.
SQUARE_SIZE = 4
