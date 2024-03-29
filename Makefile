# SPDX-FileCopyrightText: 2021 W. Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

###########################################################################
# Author: Wolfgang Traylor, Senckenberg BiK-F (wolfgang.traylor@senckenberg.de)
# Convert paleoclimate data from 60ka HadCM3B run as input for LPJ-GUESS.
###########################################################################

SHELL=bash

# Make shall delete any target whose build sequence completes with a non-zero
# return status:
.DELETE_ON_ERROR:

# When running very many parallel jobs, Python will fail to import numpy.
# This is because too many threads run in parallel. The easy solution is to
# set the OPENBLAS_NUM_THREADS variable.
# Further explanations: https://stackoverflow.com/a/51257384
export OPENBLAS_NUM_THREADS=1

# Import user-defined variables.
include options.make

# If the user didn’t define a region, the area of the whole dataset is
# taken.
LON1 ?= 0.0
LON2 ?= 360.0
LAT1 ?= 0.0
LAT2 ?= 90.0
export LON1 LON2 LAT1 LAT2

# If the user didn’t define a square size, we set the default.
SQUARE_SIZE ?= 4
export SQUARE_SIZE

# If the user didn’t define the time slice, we just use the whole dataset.
FIRST_YEAR ?= 0
LAST_YEAR  ?= 60000
FIRST_DAY := $(shell echo $$(( $(FIRST_YEAR) * 365 )) )
LAST_DAY  := $(shell echo $$(( $(LAST_YEAR) * 365 )) )
export FIRST_DAY LAST_DAY

# ORIGINAL FILES
# Filtered by time.
insol_files   := $(shell ls --quote-name external_files/regrid_downSol_Seaice_mm_s3_srf_*kyr.nc 2>/dev/null \
	| xargs ./filter_nc_files.sh)
precip_files  := $(shell ls --quote-name external_files/bias_regrid_pr_*kyr.nc 2>/dev/null \
	| xargs ./filter_nc_files.sh)
temp_files    := $(shell ls --quote-name external_files/bias_regrid_tas_*kyr.nc 2>/dev/null \
	| xargs ./filter_nc_files.sh)
wetdays_files := $(shell ls --quote-name external_files/regrid_rd3_mm_srf_*kyr.nc 2>/dev/null \
	| xargs ./filter_nc_files.sh)
export insol_files precip_files temp_files wetdays_files

# Take the first temperature output file to create the gridlist. It could
# be any file. Only define it if user hasn’t done it in options.make.
gridlist_reference ?= $(shell echo $(temp_files) | cut -d' ' -f1)
gridlist_var ?= tas  # NetCDF variable in $(gridlist_reference).
export gridlist_reference gridlist_var

# All the directory names for the square subregions (not the full path).
# The pattern is: "<id>_<east>_<west>_<south>_<north>"
# We save the filtered list of squares in `output/squares.txt`. There is
# a rule to make that target, but we need the `square_dirs` variable
# BEFORE any rule are executed. So please run first `make
# output/squares.txt` and afterwards `make`.
square_dirs = $(shell cat output/squares.txt 2>/dev/null | tr ' ' '_')

# Paths of all the output files in each square subregion.
all_gridlist_output := $(patsubst %,output/%/gridlist.txt,$(square_dirs))
all_insol_output    := $(patsubst %,output/%/insolation.nc,$(square_dirs))
all_precip_output   := $(patsubst %,output/%/precipitation.nc,$(square_dirs))
all_temp_output     := $(patsubst %,output/%/temperature.nc,$(square_dirs))
all_wetdays_output  := $(patsubst %,output/%/wet_days.nc,$(square_dirs))

all_output_files := $(all_gridlist_output) \
	$(all_insol_output) \
	$(all_precip_output) \
	$(all_temp_output) \
	$(all_wetdays_output) \
	output/co2.txt \
	output/square_regions.png

# Variable `square_dirs` needs to be set the rules in this Makefile. But
# for that to happen we need "output/squares.txt" already created. So by
# default, we first create "output/squares.txt" and afterwards call this
# Makefile again, building all output targets.
.PHONY:default
default : output/squares.txt
	@$(MAKE) --no-print-directory all

# The list of squares needs to be created first. Afterwards call this
# Makefile again.
output/squares.txt : options.make
	@mkdir --parents --verbose $(shell dirname $@)
	@./get_square_regions.py  | \
		./filter_squares.sh | \
		nl --number-width=4 --number-format='rz' --number-separator=' ' \
		> $@

# Build all output targets. This needs "output/squares.txt" already created
# before reading the Makefile!
.PHONY:all
all : $(all_output_files)
	@echo 'Deleting temporary files in "output/" folder...'
	@find 'output/' -name '*.tmp' -delete -print | sed 's;^;removed ;g'
	@echo 'Everything done.'

.PHONY: clean
clean :
	@echo 'Deleting temporary folder "tmp/"...'
	@rm --verbose --force --recursive tmp/
	@echo
	@echo 'Deleting temporary files in "output/" folder...'
	@find 'output/' -name '*.tmp' -delete -print | sed 's;^;removed ;g'
	@echo
	@echo 'Final output files:'
	@ls output/*  2>/dev/null ; \
	read -p 'Delete the final output files? [y|n]' -rs -n1 && \
	test "$$REPLY" == 'y' && rm --verbose --force --recursive 'output/' || \
	exit 0
	@echo
	@echo 'Done.'

# Create a CO₂ file covering the whole time span from 0 to 60,000 years.
output/co2.txt :
	@echo "Creating CO₂ file with constant value $(CO2_CONSTANT) ppm: $@"
	@rm --force $@
	@for year in $$(seq 60000); do \
		echo -e "$$year\t$(CO2_CONSTANT)" >> $@ ; \
	done

# Call the “secondary” Makefile with the coordinates (LON1, LON2, LAT1,
# LAT2) of the square subregion that is to be built. The coordinates are
# extracted from the path name of the target ($@).
#
# All calls to `create_square.make` are completely independent of each
# other and can thus be parallelized. Even when the same square subregion
# is being handled at the same time, the files are distinct because each
# call is only for one variable (temperature, insolation, etc.). Within
# each call to `create_square.make` there are many tasks that can be
# parallelized. By using $(MAKE) the --jobs flag from the user call will be
# passed on to the subordinate `create_square.make`.
#
# We use $(MAKE) and the '+' sign to call the other Makefile to avoid
# issues with parallel # jobs.
# https://www.gnu.org/software/make/manual/html_node/MAKE-Variable.html
#
create_square_output = @+mkdir --parents --verbose $(shell dirname $@) && \
					   $(MAKE) --no-print-directory \
					   --makefile=create_square.make \
					   $@ \
					   $(shell ./extract_square_coords.sh $@)

$(all_gridlist_output) : $(gridlist_reference) options.make
	$(create_square_output) \
		gridlist_reference=$(gridlist_reference) \
		gridlist_var=$(gridlist_var)

$(all_insol_output) : $(insol_files) options.make
	$(create_square_output)

$(all_precip_output) : $(precip_files) options.make
	$(create_square_output)

$(all_temp_output) : $(temp_files) options.make
	$(create_square_output)

$(all_wetdays_output) : $(wetdays_files) options.make
	$(create_square_output)

output/square_regions.png : options.make output/squares.txt
	@echo "Plotting map of square subregions: $@"
	@./plot_squares.R  $@ < output/squares.txt
