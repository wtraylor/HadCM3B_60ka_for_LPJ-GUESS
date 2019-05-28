# ORIGINAL FILES
insol_files = $(shell ls external_files/regrid_downSol_Seaice_mm_s3_srf_*kyr.nc 2>/dev/null)
precip_files = $(shell ls external_files/bias_regrid_pr_*kyr.nc 2>/dev/null)
temp_files = $(shell ls external_files/bias_regrid_tas_*kyr.nc 2>/dev/null)
wetdays_files = $(shell ls external_files/regrid_rd3_mm_srf_*kyr.nc 2>/dev/null)

all_originals = ${insol_files} ${precip_files} ${temp_files} ${wetdays_files}

.PHONY:default
default :
	@echo "Original Files:"
	@echo ${all_originals}
