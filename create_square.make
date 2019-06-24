SHELL=bash

# Make shall delete any target whose build sequence completes with a non-zero
# return status:
.DELETE_ON_ERROR:

# Output directory for this square subregion.
OUT_DIR = output/$(ID)_$(LON1)_$(LON2)_$(LAT1)_$(LAT2)

# Directory for intermediary files.
TMP_DIR = tmp/$(ID)_$(LON1)_$(LON2)_$(LAT1)_$(LAT2)

OUTPUT_FILES = $(OUT_DIR)/insolation.nc \
			   $(OUT_DIR)/precipitation.nc \
			   $(OUT_DIR)/temperature.nc \
			   $(OUT_DIR)/wet_days.nc

insol_output   = $(patsubst external_files/%,$(TMP_DIR)/%,${insol_files})
precip_output  = $(patsubst external_files/%,$(TMP_DIR)/%,${precip_files})
temp_output    = $(patsubst external_files/%,$(TMP_DIR)/%,${temp_files})
wetdays_output = $(patsubst external_files/%,$(TMP_DIR)/%,${wetdays_files})

this_gridlist_reference = $(TMP_DIR)/gridlist_reference.nc

.PHONY: default
default : $(OUTPUT_FILES)
	@echo 'Square subregion done: $(OUT_DIR)'

# Generic function for cropping (hyperslabbing) the file by the coordinates
# given in options.make.
# - If coordinates cover the whole dataset, cropping is skipped.
# - For months_to_days.py we need to create a temporary file because Python
#   XArray cannot write into the file it has currently opened.
crop_and_convert_time = \
	@rm --force $@ ;\
	if [ "$(LON1)" == "0.0" ] && [ "$(LON2)" == "360.0" ] && [ "$(LAT1)" == "0.0" ] && [ "$(LAT2)" == "90.0" ]; then \
		echo '$@: Converting time axis...' ;\
		./months_to_days.py $< $@ ;\
	else \
		echo '$@: Cropping...' ;\
		ncks --overwrite --dimension lon,$(LON1),$(LON2) --dimension lat,$(LAT1),$(LAT2) $< $@ ;\
		echo '$@: Converting time axis...' ;\
		readonly TMP_FILE=$@$$$$.tmp; ./months_to_days.py $@ "$$TMP_FILE"; mv $$TMP_FILE $@ ;\
	fi

# Solar Radiation:
$(TMP_DIR)/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc : external_files/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc options.make
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
$(TMP_DIR)/bias_regrid_pr_%kyr.nc : external_files/bias_regrid_pr_%kyr.nc options.make
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
$(TMP_DIR)/bias_regrid_tas_%kyr.nc : external_files/bias_regrid_tas_%kyr.nc options.make
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
$(TMP_DIR)/regrid_rd3_mm_srf_%kyr.nc : external_files/regrid_rd3_mm_srf_%kyr.nc options.make
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

# Concatenate files along time dimension
# We need to feed the files in chronological order into `ncrcat`, which
# means the files need to be sorted in reversed alphabetical order,
# starting with "60" all the way to "0".

concatenate_along_time = @echo $^ | sed 's/ /\n/g' | sort --reverse | \
						 xargs ncrcat --overwrite --output $@

reorder_dimensions = @echo 'Reordering dimensions: $@' ;\
	ncpdq --overwrite --reorder 'lon,lat,time' $@ $@

$(OUT_DIR)/insolation.nc : $(insol_output)
	@mkdir --parents --verbose $(shell dirname $@)
	@echo -e 'Concatenating along time axis: $@'
	$(concatenate_along_time)
	$(reorder_dimensions)

$(OUT_DIR)/precipitation.nc : $(precip_output)
	@mkdir --parents --verbose $(shell dirname $@)
	@echo -e 'Concatenating along time axis: $@'
	$(concatenate_along_time)
	$(reorder_dimensions)

$(OUT_DIR)/temperature.nc : $(temp_output)
	@mkdir --parents --verbose $(shell dirname $@)
	@echo -e 'Concatenating along time axis: $@'
	$(concatenate_along_time)
	$(reorder_dimensions)

$(OUT_DIR)/wet_days.nc : $(wetdays_output)
	@mkdir --parents --verbose $(shell dirname $@)
	@echo -e 'Concatenating along time axis: $@'
	$(concatenate_along_time)
	$(reorder_dimensions)

# Crop the original gridlist reference to the this square subregion and
# only take the first month of the file.
$(this_gridlist_reference) : $(gridlist_reference)
	@mkdir --parents --verbose $(shell dirname $@)
	@echo '$@: Cropping...'
	@ncks --overwrite \
		--dimension lon,$(LON1),$(LON2) \
		--dimension lat,$(LAT1),$(LAT2) \
		--dimension time,0 \
		$< $@

$(OUT_DIR)/gridlist.txt : $(this_gridlist_reference)
	@mkdir --parents --verbose $(shell dirname $@)
	@echo 'Creating gridlist file: $@'
	@./create_gridlist.sh $< $(gridlist_var) $@
