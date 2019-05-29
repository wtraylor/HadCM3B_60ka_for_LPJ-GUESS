Prepare HadCM3B 60ka Paleoclimate Data as Input for LPJ-GUESS
=============================================================

THIS REPOSITORY IS FOR INTERNAL USE ONLY.

Authors
-------

Wolfgang Traylor (wolfgang.traylor@senckenberg.de), Senckenberg Biodiversity and Climate Research Centre Frankfurt, Germany

Naming Conventions of Original Files
------------------------------------

- `tas`: temp (degC)
- `pr`: precip (mm/day)
- `downSol_Seaice_mm_s3_srf`: Incoming SW (Wm-2)
- `rd3_mm_srf`: Rainy days (number/month)
- `wchill`: Windchill (degC)
- `tempmonmin_abs`: Minimum month temperature (degC)

Changes Made to the Original
----------------------------

- Change attributes & convert units:
	- Convert temperature from °C to Kelvin: standard name `air_temperature` and unit `K`.
	- Downwelling radiation: Set unit to `W m-2` and standard name to `surface_downwelling_shortwave_flux`. Though there’s no unit given in the original NetCDF file, we assume that it is in W/m².
	- Rainy days: Set standard name to `number_of_days_with_lwe_thickness_of_precipitation_amount_above_threshold`. The unit is irrelevant.
	- Precipitation: Set standard name to `precipitation_amount` and unit to `kg m-2`, which is equivalent to the original unit `mm/day`.
- Adjust the time:
	- In the original, there is no time unit. Each datum is one month.
	- NetCDF commands and LPJ-GUESS struggle with large negative year numbers.
	- For now we define that each file individually starts counting the time from year "1".
	- For that we define the time unit first as "months since 1-1-15" and then convert the time values to "days since 1-1-15" because LPJ-GUESS cannot handle the "months since" format.
- Crop to region.

Usage
-----

### Prerequisites
- `make` (Usually installed on all UNIX systems.)
- NCO (<https://nco.sourceforge.net/>)

### Include Original Files
The downloaded files are expected in a subdirectory `external_files` under the root of this repository.

### Options
Manipulate the file `options.txt` with a text editor according to your needs.
Instructions are in that file.

### Run Make
Open a terminal in the root directory of this repository, where the `Makefile` lies.
- Execute `make` to run the script.
- Execute `make clean` to remove files from the `output` folder. You can also just delete the `output` folder manually.

To Do
-----

- Write a Python script to overwrite time dimension with "days since".
- Re-order dimensions for LPJ-GUESS with `ncpdq --re-order 'lon,lat,time' in.nc out.nc`.
- Create gridlist.txt file.
- Get CO₂ timeline.
- Decide for a time unit that is transient over the whole dataset (60k years).
- Create a `environment.yml` file plus instructions for how to use it with Anaconda.
- Decide for a license.
- Explain `external_files/` + checksums.
- Prepare a LPJ-GUESS instructions file as a template.
