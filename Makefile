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
insol_files   = $(shell ls external_files/regrid_downSol_Seaice_mm_s3_srf_*kyr.nc 2>/dev/null)
precip_files  = $(shell ls external_files/bias_regrid_pr_*kyr.nc 2>/dev/null)
temp_files    = $(shell ls external_files/bias_regrid_tas_*kyr.nc 2>/dev/null)
wetdays_files = $(shell ls external_files/regrid_rd3_mm_srf_*kyr.nc 2>/dev/null)

co2_output     = $(patsubst external_files/bias_regrid_tas%.nc,output/co2%.txt,${temp_files})
insol_output   = $(patsubst external_files/%,output/%,${insol_files})
precip_output  = $(patsubst external_files/%,output/%,${insol_files})
temp_output    = $(patsubst external_files/%,output/%,${temp_files})
wetdays_output = $(patsubst external_files/%,output/%,${wetdays_files})

final_outputs = output/insolation.nc \
								output/precipitation.nc \
								output/temperature.nc \
								output/wet_days.nc

# Take the first temperature output file to create the gridlist. It could
# be any file.
gridlist_reference = $(shell echo $(patsubst external_files/%,output/%,${temp_files}) | cut -d' ' -f1)
gridlist_var = 'tas'  # NetCDF variable in $(gridlist_reference).

.PHONY:default
default : $(final_outputs)
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

output/gridlist.txt : $(gridlist_reference)
	@echo 'Creating gridlist file: $@'
	@rm --force $@
	./create_gridlist.sh "$<" $(gridlist_var) $@

# Generic function for cropping (hyperslabbing) the file by the coordinates
# given in options.make.
# - If not all coordinates are given, cropping is skipped.
# - For months_to_days.py we need to create a temporary file because Python
#   XArray cannot write into the file it has currently opened.
crop_and_convert_time = \
	@rm --force $@ ;\
	if [ -z "$(LON1)" ] || [ -z "$(LON2)" ] || [ -z "$(LAT1)" ] || [ -z "$(LAT2)" ]; then \
		echo '$@: Converting time axis...' ;\
		./months_to_days.py $< $@ ;\
	else \
		echo '$@: Cropping...' ;\
		ncks --overwrite --dimension lon,$(LON1),$(LON2) --dimension lat,$(LAT1),$(LAT2) $< $@ ;\
		echo '$@: Converting time axis...' ;\
		readonly TMP_FILE=$@$$$$.tmp; ./months_to_days.py $@ "$$TMP_FILE"; mv $$TMP_FILE $@ ;\
	fi

# Solar Radiation:
output/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc : external_files/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc options.make
	@mkdir --parents --verbose $(shell dirname $@)
	$(crop_and_convert_time)
	@echo '$@: Setting metadata...'
	@ncatted --overwrite \
		--attribute 'units,time,o,c,days since 1-1-1' \
		--attribute 'calendar,time,o,c,365_day' \
		--attribute 'standard_name,lon,o,c,longitude' \
		--attribute 'standard_name,lat,o,c,latitude' \
		--attribute 'missing_value,downSol_Seaice_mm_s3_srf,c,f,9.96921e+36' \
		--attribute 'standard_name,downSol_Seaice_mm_s3_srf,o,c,surface_downwelling_shortwave_flux' \
		--attribute 'units,downSol_Seaice_mm_s3_srf,o,c,W m-2' $@
	@echo '$@: Setting "time" as record dimension...'
	@ncks --overwrite --mk_rec_dmn time $@ $@

# Precipitation:
output/bias_regrid_pr_%kyr.nc : external_files/bias_regrid_pr_%kyr.nc options.make
	@mkdir --parents --verbose $(shell dirname $@)
	$(crop_and_convert_time)
	@echo '$@: Setting metadata...'
	@ncatted --overwrite \
		--attribute 'units,time,o,c,days since 1-1-1' \
		--attribute 'calendar,time,o,c,365_day' \
		--attribute 'standard_name,lon,o,c,longitude' \
		--attribute 'standard_name,lat,o,c,latitude' \
		--attribute 'standard_name,pr,o,c,precipitation_amount' \
		--attribute 'missing_value,pr,c,f,9.96921e+36' \
		--attribute 'units,pr,o,c,kg m-2' $@
	@echo '$@: Setting "time" as record dimension...'
	@ncks --overwrite --mk_rec_dmn time $@ $@

# Temperature: convert °C to Kelvin
output/bias_regrid_tas_%kyr.nc : external_files/bias_regrid_tas_%kyr.nc options.make
	@mkdir --parents --verbose $(shell dirname $@)
	$(crop_and_convert_time)
	@echo '$@: Converting °C to Kelvin...'
	@ncap2 --overwrite --script 'tas += 273.2' $@ $@
	@echo '$@: Setting metadata...'
	@ncatted --overwrite \
		--attribute 'units,time,o,c,days since 1-1-1' \
		--attribute 'calendar,time,o,c,365_day' \
		--attribute 'standard_name,lon,o,c,longitude' \
		--attribute 'standard_name,lat,o,c,latitude' \
		--attribute 'standard_name,tas,o,c,air_temperature' \
		--attribute 'missing_value,tas,c,f,9.96921e+36' \
		--attribute 'units,tas,o,c,K' $@
	@echo '$@: Setting "time" as record dimension...'
	@ncks --overwrite --mk_rec_dmn time $@ $@

# Rainy/Wet Days:
output/regrid_rd3_mm_srf_%kyr.nc : external_files/regrid_rd3_mm_srf_%kyr.nc options.make
	@mkdir --parents --verbose $(shell dirname $@)
	$(crop_and_convert_time)
	@echo '$@: Setting metadata...'
	@ncatted --overwrite \
		--attribute 'units,time,o,c,days since 1-1-1' \
		--attribute 'calendar,time,o,c,365_day' \
		--attribute 'standard_name,lon,o,c,longitude' \
		--attribute 'standard_name,lat,o,c,latitude' \
		--attribute 'missing_value,rd3_mm_srf,c,f,9.96921e+36' \
		--attribute 'standard_name,rd3_mm_srf,o,c,number_of_days_with_lwe_thickness_of_precipitation_amount_above_threshold' $@
	@echo '$@: Setting "time" as record dimension...'
	@ncks --overwrite --mk_rec_dmn time $@ $@

# Create a CO₂ file covering the whole time span from 0 to 60,000 years.
output/co2.txt :
	@echo "Creating CO₂ file with constant value $(CO2_CONSTANT) ppm: "
	@echo $@
	@rm --force $@
	@for year in $$(seq 60000); do \
		echo -e "$$year\t$(CO2_CONSTANT)" >> $@ ; \
	done

# Concatenate files along time dimension
# We need to feed the files in chronological order into `ncrcat`, which
# means the files need to be sorted in reversed alphabetical order,
# starting with "60" all the way to "0".

concatenate_along_time = @echo $^ | sed 's/ /\n/g' | sort --reverse | \
												 xargs ncrcat --overwrite --output $@

output/insolation.nc : $(insol_output)
	@echo -e 'Concatenating along time axis: $@'
	$(concatenate_along_time)

output/precipitation.nc : $(precip_output)
	@echo -e 'Concatenating along time axis: $@'
	$(concatenate_along_time)

output/temperature.nc : $(temp_output)
	@echo -e 'Concatenating along time axis: $@'
	$(concatenate_along_time)

output/wet_days.nc : $(wetdays_output)
	@echo -e 'Concatenating along time axis: $@'
	$(concatenate_along_time)
