###########################################################################
# Author: Wolfgang Traylor, Senckenberg BiK-F (wolfgang.traylor@senckenberg.de)
# Convert paleoclimate data from 60ka HadCM3B run as input for LPJ-GUESS.
###########################################################################

SHELL=bash

# Make shall delete any target whose build sequence completes with a non-zero
# return status:
.DELETE_ON_ERROR:

# Import user-defined variables.
include options.make

# ORIGINAL FILES
insol_files = $(shell ls external_files/regrid_downSol_Seaice_mm_s3_srf_*kyr.nc 2>/dev/null)
precip_files = $(shell ls external_files/bias_regrid_pr_*kyr.nc 2>/dev/null)
temp_files = $(shell ls external_files/bias_regrid_tas_*kyr.nc 2>/dev/null)
wetdays_files = $(shell ls external_files/regrid_rd3_mm_srf_*kyr.nc 2>/dev/null)

co2_files = $(patsubst external_files/bias_regrid_tas%,output/co2%,${temp_files})

all_originals = ${insol_files} ${precip_files} ${temp_files} ${wetdays_files}
all_output = $(patsubst external_files/%,output/%,${all_originals}) $(co2_files)

# Take the first output file to create the gridlist. It could be any file,
# relly.
gridlist_reference = $(shell echo $(all_output) | cut -d' ' -f1)

.PHONY:default
default : $(all_output)
	@echo 'Done.'

.PHONY: clean
clean :
	@echo 'Deleting temporary files in output folder...'
	@rm --verbose --force output/*.tmp
	@echo 'Regular output files:'
	@ls output/*.nc 2>/dev/null && \
	read -p 'Delete the files? [y|n]' -rs -n1 && \
	test "$$REPLY" == 'y' && rm --verbose --force output/*.nc || \
	exit 0
	@echo 'Done.'

# Gridlist:
# Simply combine all longitudes with all latitudes, irrespective of the land mask.
# Not ethat the cf_gridlist in LPJ-GUESS just takes indices, not actual longitude and latitude
# THe regular expression matches the number in e.g. "lat = 30 ;".
LAT_REGEX := '(?<=lat = )\d*(?= ;$$)'
LON_REGEX := '(?<=lon = )\d*(?= ;$$)'
output/gridlist.txt : $(gridlist_reference)
	@echo 'Creating gridlist file.'
	@rm --force $@
	lat_count=$$(ncks --variable=lat $< | grep --after-context=1 'dimensions:'  | grep --perl-regexp --only-matching $(LAT_REGEX)) && \
	lon_count=$$(ncks --variable=lon $< | grep --after-context=1 'dimensions:'  | grep --perl-regexp --only-matching $(LON_REGEX)) && \
	for lon in $$(seq 0 $$(($$lat_count - 1))); do \
		for lat in $$(seq 0 $$(($$lon_count - 1))); do \
			echo -e "$$lon\t$$lat" >> $@ ; \
		done ; \
	done

# Solar Radiation:
output/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc : external_files/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc options.make
	@mkdir --parents --verbose $(shell dirname $@)
	ncks --overwrite --dimension lon,$(LON1),$(LON2) --dimension lat,$(LAT1),$(LAT2) $< $@
	ncatted --overwrite \
		--attribute 'units,time,o,c,months since 1-1-15' \
		--attribute 'standard_name,downSol_Seaice_mm_s3_srf,o,c,surface_downwelling_shortwave_flux' \
		--attribute 'units,downSol_Seaice_mm_s3_srf,o,c,W m-2' $@

# Precipitation:
output/bias_regrid_pr_%kyr.nc : external_files/bias_regrid_pr_%kyr.nc options.make
	@mkdir --parents --verbose $(shell dirname $@)
	ncks --overwrite --dimension lon,$(LON1),$(LON2) --dimension lat,$(LAT1),$(LAT2) $< $@
	ncatted --overwrite \
		--attribute 'units,time,o,c,months since 1-1-15' \
		--attribute 'standard_name,pr,o,c,precipitation_amount' \
		--attribute 'units,pr,o,c,kg m-2' $@

# Temperature: convert °C to Kelvin
output/bias_regrid_tas_%kyr.nc : external_files/bias_regrid_tas_%kyr.nc options.make
	@mkdir --parents --verbose $(shell dirname $@)
	ncks --overwrite --dimension lon,$(LON1),$(LON2) --dimension lat,$(LAT1),$(LAT2) $< $@
	ncap2 --overwrite --script 'tas += 273.2' $@ $@
	ncatted --overwrite \
		--attribute 'units,time,o,c,months since 1-1-15' \
		--attribute 'standard_name,tas,o,c,air_temperature' \
		--attribute 'units,tas,o,c,K' $@

# Rainy/Wet Days:
output/regrid_rd3_mm_srf_%kyr.nc : external_files/regrid_rd3_mm_srf_%kyr.nc options.make
	@mkdir --parents --verbose $(shell dirname $@)
	ncks --overwrite --dimension lon,$(LON1),$(LON2) --dimension lat,$(LAT1),$(LAT2) $< $@
	ncatted --overwrite \
		--attribute 'units,time,o,c,months since 1-1-15' \
		--attribute 'standard_name,rd3_mm_srf,o,c,number_of_days_with_lwe_thickness_of_precipitation_amount_above_threshold' $@

# Create a CO₂ file with constant values for each temperature file (but that
# could be any other variable, too).
output/co2_%kyr.nc : output/bias_regrid_tas_%kyr.nc
	@echo "Creating CO₂ file with constant value $(CO2_CONSTANT) ppm: "
	@echo $@
	@rm --force $@
	@for year in $$(seq 2400); do \
		echo -e "$$year\t$(CO2_CONSTANT)" >> $@ ; \
	done
