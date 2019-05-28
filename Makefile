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

output/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc : external_files/regrid_downSol_Seaice_mm_s3_srf_%kyr.nc
	@mkdir --parents --verbose $(shell dirname $@)
	ncatted --overwrite --attribute 'standard_name,downSol_Seaice_mm_s3_srf,o,c,surface_downwelling_shortwave_flux' --attribute 'units,downSol_Seaice_mm_s3_srf,o,c,W m-2' $< $@

output/bias_regrid_pr_%kyr.nc : external_files/bias_regrid_pr_%kyr.nc
	@mkdir --parents --verbose $(shell dirname $@)
	ncatted --overwrite --attribute 'standard_name,pr,o,c,precipitation_amount' --attribute 'units,pr,o,c,kg m-2' $< $@

output/bias_regrid_tas_%kyr.nc : external_files/bias_regrid_tas_%kyr.nc
	@mkdir --parents --verbose $(shell dirname $@)
	@echo $@

output/regrid_rd3_mm_srf_%kyr.nc : external_files/regrid_rd3_mm_srf_%kyr.nc
	@mkdir --parents --verbose $(shell dirname $@)
	@echo $@
