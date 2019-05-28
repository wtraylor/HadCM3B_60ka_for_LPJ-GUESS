###########################################################################
# Author: Wolfgang Traylor, Senckenberg BiK-F (wolfgang.traylor@senckenberg.de)
# Convert paleoclimate data from 60ka HadCM3B run as input for LPJ-GUESS.
###########################################################################

# Make shall delete any target whose build sequence completes with a non-zero
# return status:
.DELETE_ON_ERROR:

# Import user-defined variables.
include options.txt

# ORIGINAL FILES
insol_files = $(shell ls external_files/regrid_downSol_Seaice_mm_s3_srf_*kyr.nc 2>/dev/null)
precip_files = $(shell ls external_files/bias_regrid_pr_*kyr.nc 2>/dev/null)
temp_files = $(shell ls external_files/bias_regrid_tas_*kyr.nc 2>/dev/null)
wetdays_files = $(shell ls external_files/regrid_rd3_mm_srf_*kyr.nc 2>/dev/null)

all_originals = ${insol_files} ${precip_files} ${temp_files} ${wetdays_files}
all_output = $(patsubst external_files/%,output/%,${all_originals})

.PHONY:default
default : $(all_output)
	@echo "Original Files:"
	@echo ${all_originals}

# Solar Radiation:
output/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc : external_files/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc options.txt
	@mkdir --parents --verbose $(shell dirname $@)
	ncks --dimension lon,$(LON1),$(LON2) --dimension lat,$(LAT1),$(LAT2) $< $@
	ncatted --overwrite --attribute 'standard_name,downSol_Seaice_mm_s3_srf,o,c,surface_downwelling_shortwave_flux' --attribute 'units,downSol_Seaice_mm_s3_srf,o,c,W m-2' $@

# Precipitation:
output/bias_regrid_pr_%kyr.nc : external_files/bias_regrid_pr_%kyr.nc
	@mkdir --parents --verbose $(shell dirname $@)
	ncatted --overwrite --attribute 'standard_name,pr,o,c,precipitation_amount' --attribute 'units,pr,o,c,kg m-2' $< $@

# Temperature: convert °C to Kelvin
output/bias_regrid_tas_%kyr.nc : external_files/bias_regrid_tas_%kyr.nc
	@mkdir --parents --verbose $(shell dirname $@)
	ncap2 --script 'tas += 273.2' $< $@
	ncatted --overwrite --attribute 'standard_name,tas,o,c,air_temperature' --attribute 'units,tas,o,c,K' $@

# Rainy/Wet Days:
output/regrid_rd3_mm_srf_%kyr.nc : external_files/regrid_rd3_mm_srf_%kyr.nc
	@mkdir --parents --verbose $(shell dirname $@)
	ncatted --overwrite --attribute 'standard_name,rd3_mm_srf,o,c,number_of_days_with_lwe_thickness_of_precipitation_amount_above_threshold' $< $@
