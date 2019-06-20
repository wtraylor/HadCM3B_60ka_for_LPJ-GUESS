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
    - We define the time unit first as "months since 1-1-15" and then convert the time values to "days since 1-1-15" because LPJ-GUESS cannot handle the "months since" format.
    - Year 1 is the first year of the HadCM3B simulation, that is the calendar year 60,000 BP. So the output files will show dates in the time dimension from year 1 to 60,000.
- Crop to the region specified in `options.make` (optional).
- Create attribute `missing_value`, which is deprecated, but recognized by LPJ-GUESS. It has the same value as `_FillValue`. Compare the [NCO reference](http://nco.sourceforge.net/nco.html#Missing-Values).
- Concatenate full timeline.
- Reorder dimensions from `time,lon,lat` to `lon,lat,time`. This way LPJ-GUESS can access the values for each grid cell along the time axis faster.

### Square Subregions
To concatenate the whole Northern hemisphere over 60,000 years would yield insanely large NetCDF output files, and consecutively very large LPJ-GUESS output files. To keep the files in a manageable size, the output is split into “square subregions.” Each square NetCDF file contains the full timeline and can be used as input for a transient simulation run in LPJ-GUESS.

With many separate LPJ-GUESS simulations comes the additional advantage of flexibility in scheduling the jobs. A simulation of _one square_ will allow an estimate of the time and resource consumption necessary for _one grid cell,_ from which you can derive the requirements for the simulating the _whole dataset._ And the simulation jobs for each square can the be scheduled as the resources permit.

The `gridlist.txt` for each subregion contains only grid cells that have a valid value in the first month of the `gridlist_reference` file specified in `options.make`. Ocean grid cells are thus not included in `gridlist.txt`. Square subregions that don’t contain any valid grid cells are excluded from the beginning.

One easy way to see how many valid grid cells are in a square subregion is by counting the lines in `gridlist.txt`: `wc -l gridlist.txt`. To get an overview of the amount of _all_ grid cells you can use this command: `find output/ -name 'gridlist.txt' | xargs wc -l`.

You can define the size of each square in degrees or disable the splitting in `options.make`.

To preview how your region would be split into square subregions call `make output/square_regions.png`. The created map has modern coastlines, though.

Repository Structure
--------------------

- `MD5.txt`: MD5 checksums for files in `external_files/`.
- `Makefile`: Contains all top-level execution logic. Call it with the `make` command.
- `create_gridlist.sh`: Helper script to create the `gridlist.txt` file. Don’t call this directly, `make` does that.
- `create_square.make`: Helper Makefile called by `Makefile` automatically.
- `environment.yml`: Anaconda environment file.
- `external_files/`: Original input files. See section “Include Original Files”.
- `extract_square_coords.sh`: Helper script to set environment variables for square coordinates.
- `get_square_dirs.sh`: Helper script to compose output of `get_square_regions.py` to directory names in `output/`.
- `get_square_regions.py`: Helper script to define square subregions.
- `months_to_days.py`: Helper script to convert time unit from “months since” to “days since”. Don’t call this directly.
- `options.make`: User-defined options in `Makefile` syntax.
- `output/`: Will be created automatically and contains the final output files. Each square subregion has its own subfolder, which is named by the coordinates of the edges of the square like: `<east>_<west>_<south>_<north>`, in degrees (0°–360° E and 0°–90° N). Each square subregion folder will contain the output files `temperature.nc`, `precipitation.nc`, `wet_days.nc`, `insolation.nc`, and `gridlist.txt`.
- `plot_squares.R`: Script for creating a map of the square subregions in `output/square_regions.png`.
- `tmp/`: Subfolder for intermediate files.

Usage
-----

### Prerequisites
- `make` (Usually installed on all UNIX systems.)
- NCO (<https://nco.sourceforge.net/>)
- Python 3 with [XArray](https://pypi.org/project/xarray/), [SciPy](https://pypi.org/project/scipy/), and [netCDF4](https://pypi.org/project/netCDF4/)
- The recommended way to reproduce this project is to use [Anaconda](https://anaconda.org) or [Miniconda](https://docs.conda.io/en/latest/miniconda.html):
    + Install Anaconda or Miniconda locally or system-wide.
    + In this repository run `conda env create environment.yml`. This should install all necessary dependencies.
    + Switch into the environment: `conda activate HadCM3B_60ka_for_LPJ-GUESS`
    + Now run `make` as described below.

### Include Original Files
The downloaded files are expected in a subdirectory `external_files` under the root of this repository.
For each of the original NetCDF files one output file is created.
So if you don’t want to include the whole time series, you put only those files into `external_files` that you are interested in having prepared for LPJ-GUESS.

### Limited Diskspace
The intermediary files in `tmp/` and the output files in `output/` might take up a lot of diskspace. If you have limited space on your local hard drive, you can mount or symlink the `output/` and the `tmp/` from another drive here, overriding the automatically created folders. Do this before calling `make`.

### Options
Manipulate the file `options.make` with a text editor according to your needs.
Instructions are in that file.

### Run Make
Open a terminal in the root directory of this repository, where the `Makefile` lies.

- Execute `make` to run the script. If you have a multi-core machine, you can gain speed by running parallel jobs with the `-j/--jobs` flag, e.g.: `make --jobs=5`. Check the output of `lscpu` to see how many CPU cores your machine has.
- Execute `make clean` to remove files from the `tmp` and `output` folders. You will be asked for confirmation to delete the final output files. Of course, you can also just delete the folders manually.

License
-------

To be decided.
