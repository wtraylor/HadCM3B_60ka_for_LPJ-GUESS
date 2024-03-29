<!--
SPDX-FileCopyrightText: 2021 Wolfgang Traylor <wolfgang.traylor@senckenberg.de>

SPDX-License-Identifier: CC-BY-4.0
-->

# Prepare HadCM3B 60ka Paleoclimate Data as Input for LPJ-GUESS

[![REUSE-compliant](reuse-compliant.svg)][REUSE]
[![DOI](https://zenodo.org/badge/228434046.svg)](https://zenodo.org/badge/latestdoi/228434046)

## Authors

- Wolfgang Traylor (wolfgang.traylor@senckenberg.de) <https://orcid.org/0000-0002-4813-1072>, Senckenberg Biodiversity and Climate Research Centre ([SBiK-F][])

[SBiK-F]: <https://www.senckenberg.de/en/institutes/sbik-f/>

## Naming Conventions of Original Files

- `tas`: temp (degC)
- `pr`: precip (mm/day)
- `downSol_Seaice_mm_s3_srf`: Incoming SW (Wm-2)
- `rd3_mm_srf`: Rainy days (number/month)
- `wchill`: Windchill (degC)
- `tempmonmin_abs`: Minimum month temperature (degC)

## Changes Made to the Original

- Change attributes & convert units:
    - Convert temperature from °C to Kelvin: standard name `air_temperature` and unit `K`.
    - Downwelling radiation: Set unit to `W m-2` and standard name to `surface_downwelling_shortwave_flux`. Though there’s no unit given in the original NetCDF file, we assume that it is in W/m².
    - Rainy days: Set standard name to `number_of_days_with_lwe_thickness_of_precipitation_amount_above_threshold`. The unit is irrelevant.
    - Precipitation: Set standard name to `precipitation_amount` and unit to `kg m-2`, which is equivalent to the original unit `mm/day`.
- Adjust the time:
    - In the original, there is no time unit. Each datum is one month.
    - NetCDF commands and LPJ-GUESS struggle with large negative year numbers.
    - We define the time unit first as "months since 1-1-15" and then convert the time values to "days since 1-1-15" because LPJ-GUESS cannot handle the "months since" format.
    - Year 1 is the first year of the HadCM3B simulation, that is the calendar year 60,000 BP. So the output files will show dates in the time dimension from year 1 to 60,000. Since the HadCM3B simulation goes to year 1950 AD (= 0 BP), the year 60,000 in the processed data corresponds to 1950 AD.
- Crop to the region specified in `options.make` (optional).
- Create attribute `missing_value`, which is deprecated, but recognized by LPJ-GUESS. It has the same value as `_FillValue`. Compare the [NCO reference](http://nco.sourceforge.net/nco.html#Missing-Values).
- Concatenate timeline within the time range defined in `options.make`.
- Reorder dimensions from `time,lon,lat` to `lon,lat,time`. This way LPJ-GUESS can access the values for each grid cell along the time axis faster.

### Square Subregions
To concatenate the whole Northern hemisphere over 60,000 years would yield insanely large NetCDF output files, and consecutively very large LPJ-GUESS output files. To keep the files in a manageable size, the output is split into “square subregions.” Each square NetCDF file contains the full timeline (as defined in `options.make`) and can be used as input for a transient simulation run in LPJ-GUESS.

With many separate LPJ-GUESS simulations comes the additional advantage of flexibility in scheduling the jobs. A simulation of *one square* will allow an estimate of the time and resource consumption necessary for *one grid cell,* from which you can derive the requirements for the simulating the *whole dataset.* And the simulation jobs for each square can the be scheduled as the resources permit.

The `gridlist.txt` for each subregion contains only grid cells that have a valid value in the first month of the `gridlist_reference` file specified in `options.make`. Ocean grid cells are thus not included in `gridlist.txt`. Square subregions that don’t contain any valid grid cells are excluded from the beginning.

One easy way to see how many valid grid cells are in a square subregion is by counting the lines in `gridlist.txt`: `wc -l gridlist.txt`. To get an overview of the amount of *all* grid cells you can use this command: `find output/ -name 'gridlist.txt' | xargs wc -l`.

You can define the size of each square in degrees or disable the splitting in `options.make`.

To preview how your region would be split into square subregions call `make output/square_regions.png`. The created map has modern coastlines, though.

## Repository Structure

- `MD5.txt`: MD5 checksums for files in `external_files/`.
- `Makefile`: Contains all top-level execution logic. Call it with the `make` command.
- `create_gridlist.sh`: Helper script to create the `gridlist.txt` file. Don’t call this directly, `make` does that.
- `create_square.make`: Helper Makefile called by `Makefile` automatically.
- `environment.yml`: Anaconda environment file.
- `external_files/`: Original input files. See section [“Include Original Files”](#include-original-files).
- `extract_square_coords.sh`: Helper script to set environment variables for square coordinates.
- `extract_years_from_filename.py`: Helper script to parse the year information out of the original filenames.
- `filter_nc_files.sh`: Helper script to check if original NetCDF file falls in desired time frame, based on filename.
- `get_square_regions.py`: Helper script to define square subregions.
- `months_to_days.py`: Helper script to convert time unit from “months since” to “days since”. Don’t call this directly.
- `options.make`: User-defined options in `Makefile` syntax.
- `output/`: Will be created automatically and contains the final output files. Each square subregion has its own subfolder, which is named by the coordinates of the edges of the square like: `<east>_<west>_<south>_<north>`, in degrees (0°–360° E and 0°–90° N). Each square subregion folder will contain the output files `temperature.nc`, `precipitation.nc`, `wet_days.nc`, `insolation.nc`, and `gridlist.txt`.
- `plot_squares.R`: Script for creating a map of the square subregions in `output/square_regions.png`.
- `tmp/`: Subfolder for intermediate files.

## Usage

### Prerequisites
- `make` (Usually installed on all UNIX systems.)
- NCO (<https://nco.sourceforge.net/>)
- Python 3 with [XArray](https://pypi.org/project/xarray/), [SciPy](https://pypi.org/project/scipy/), and [netCDF4](https://pypi.org/project/netCDF4/)
- The recommended way to reproduce this project is to use [Anaconda](https://anaconda.org) or [Miniconda](https://docs.conda.io/en/latest/miniconda.html):
    - Install Anaconda or Miniconda locally or system-wide.
    - In this repository run `conda env create environment.yml`. This should install all necessary dependencies.
    - Switch into the environment: `conda activate HadCM3B_60ka_for_LPJ-GUESS`
    - Now run `make` as described below.

### Include Original Files
The original NetCDF files are too big to be included in the Git repository itself.
They need to be downloaded manually.
You can download them from the Senckenberg internal network or request access from the authors.

The downloaded files are expected in a subdirectory `external_files` under the root of this repository.
Only the files within the time frame specified in `options.make` are processed.

**Important:** Do not change the original filenames!

All external files with their corresponding MD5 checksums are listed in `MD5.txt`.
You can open the `MD5.txt` file with a text editor to see which files you need and what directory structure is expected.

1. Open a **terminal** in the root of the repository, where the `MD5.txt` file lies.
1. **Copy or mount or symlink** the big files in the `external_files` subdirectory directly.
   - `external_files` should not exist yet.
   - Simplest option: Create the directory `external_files` and copy–paste the already downloaded files into it.
   - Alternative 1) Mount via SSH: `mkdir external_files ; sshfs -o compression=yes <USER>@172.30.45.56:/data/gitlab/bimodal/<REPOSITORY_NAME> external_files`
   - Alternative 2) Copy from remote (see `man rsync` for more options): `mkdir external_files ; rsync --progress --copy-links --recursive <USER>@172.30.45.56:/data/gitlab/bimodal/<REPOSITORY_NAME>/* external_files/`
   - Alternative 3) Symlink from local storage: `ln --symbolic /path/to/local/storage external_files`
1. Run `md5sum --check MD5.txt` and **check** the output in the terminal. Are all files there and checked correctly?
1. If some files failed the test, download them again. If that fails, contact the authors.

### Limited Diskspace
The intermediary files in `tmp/` and the output files in `output/` might take up a lot of diskspace. If you have limited space on your local hard drive, you can mount or symlink the `output/` and the `tmp/` from another drive here, overriding the automatically created folders. Do this before calling `make`.

### Options
Manipulate the file `options.make` with a text editor according to your needs.
Instructions are in that file.

### Run Make
Open a terminal in the root directory of this repository, where the `Makefile` lies.

- Execute `make` to run the script. If you have a multi-core machine, you can gain speed by running parallel jobs with the `-j/--jobs` flag, e.g.: `make --jobs=5`. Check the output of `lscpu` to see how many CPU cores your machine has.
- Execute `make clean` to remove files from the `tmp` and `output` folders. You will be asked for confirmation to delete the final output files. Of course, you can also just delete the folders manually.

## License

This project follows the [REUSE][] standard:

- Every file has its copyright/license information either in a comment at the top or in a separate text file with the extension `.license`.
- All license texts can be found in the directory `LICENSES/`.
- Project information and licenses for Git submodules can be found in the text file `.reuse/dep5`.

[REUSE]: https://reuse.software
