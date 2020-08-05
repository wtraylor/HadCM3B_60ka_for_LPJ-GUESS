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
    - Year 1 is the first year of the HadCM3B simulation, that is the calendar year 60,000 BP. So the output files will show dates in the time dimension from year 1 to 60,000. Since the HadCM3B simulation goes to year 1950 AD (= 0 BP), the year 60,000 in the processed data corresponds to 1950 AD.
- Crop to the region specified in `options.make` (optional).
- Create attribute `missing_value`, which is deprecated, but recognized by LPJ-GUESS. It has the same value as `_FillValue`. Compare the [NCO reference](http://nco.sourceforge.net/nco.html#Missing-Values).
- Concatenate timeline within the time range defined in `options.make`.
- Reorder dimensions from `time,lon,lat` to `lon,lat,time`. This way LPJ-GUESS can access the values for each grid cell along the time axis faster.

### Square Subregions
To concatenate the whole Northern hemisphere over 60,000 years would yield insanely large NetCDF output files, and consecutively very large LPJ-GUESS output files. To keep the files in a manageable size, the output is split into “square subregions.” Each square NetCDF file contains the full timeline (as defined in `options.make`) and can be used as input for a transient simulation run in LPJ-GUESS.

With many separate LPJ-GUESS simulations comes the additional advantage of flexibility in scheduling the jobs. A simulation of _one square_ will allow an estimate of the time and resource consumption necessary for _one grid cell,_ from which you can derive the requirements for the simulating the _whole dataset._ And the simulation jobs for each square can the be scheduled as the resources permit.

The `gridlist.txt` for each subregion contains only grid cells that have a valid value in the first month of the `gridlist_reference` file specified in `options.make`. Ocean grid cells are thus not included in `gridlist.txt`. Square subregions that don’t contain any valid grid cells are excluded from the beginning.

One easy way to see how many valid grid cells are in a square subregion is by counting the lines in `gridlist.txt`: `wc -l gridlist.txt`. To get an overview of the amount of _all_ grid cells you can use this command: `find output/ -name 'gridlist.txt' | xargs wc -l`.

You can define the size of each square in degrees or disable the splitting in `options.make`.

To preview how your region would be split into square subregions call `popper preview` and open `output/square_regions.png`. The created map has modern coastlines, though.

Repository Structure
--------------------

- `.popper.yml`: The Popper workflow file. See [Usage](#executing-workflows).
- `docker/Dockerfile`: Description of the Docker image built and used by Popper.
- `MD5.txt`: MD5 checksums for files in `external_files/`.
- `Makefile`: Contains all top-level execution logic. Call it with the `make` command.
- `create_gridlist.sh`: Helper script to create the `gridlist.txt` file. Don’t call this directly, `make` does that.
- `create_square.make`: Helper Makefile called by `Makefile` automatically.
- `external_files/`: Original input files. See section [Include External Files](#include-external-files).
- `extract_square_coords.sh`: Helper script to set environment variables for square coordinates.
- `extract_years_from_filename.py`: Helper script to parse the year information out of the original filenames.
- `filter_nc_files.sh`: Helper script to check if original NetCDF file falls in desired time frame, based on filename.
- `get_square_regions.py`: Helper script to define square subregions.
- `months_to_days.py`: Helper script to convert time unit from “months since” to “days since”. Don’t call this directly.
- `options.make`: User-defined options in `Makefile` syntax.
- `output/`: Will be created automatically and contains the final output files. Each square subregion has its own subfolder, which is named by the coordinates of the edges of the square like: `<east>_<west>_<south>_<north>`, in degrees (0°–360° E and 0°–90° N). Each square subregion folder will contain the output files `temperature.nc`, `precipitation.nc`, `wet_days.nc`, `insolation.nc`, and `gridlist.txt`.
- `plot_squares.R`: Script for creating a map of the square subregions in `output/square_regions.png`.
- `tmp/`: Subfolder for intermediate files.

Usage
-----

### Prerequisites
- [Popper](https://github.com/getpopper/popper) (≥2.5.0)
- [Docker](https://docs.docker.com/get-docker/) (≥19.03)

### Include External Files
The downloaded files are expected in a subdirectory `external_files` under the root of this repository.
Only the files within the time frame specified in `options.make` are processed.

**Do not change the original filenames!**

### Options
Manipulate the file `options.make` with a text editor according to your needs.
Instructions are in that file.

### Executing Workflows
This project follows the [**Popper** convention](https://getpopper.io) (Jimenez et al. 2017).
Use the [Popper](https://github.com/getpopper/popper/) command line tool to execute the YAML workflow file (`.popper.yml`):

```bash
popper run
```

You should tune parallelization to your machine by setting the number of parallel jobs.
Do that by opening `.popper.yml` in a text editor and change the number for the `--jobs` argument.
The number of threads should be 1.5 times the number of your cores or less.

License
-------

To be decided.

References
----------

- Jimenez, I., M. Sevilla, N. Watkins, C. Maltzahn, J. Lofstead, K. Mohror, A. Arpaci-Dusseau, and R. Arpaci-Dusseau. 2017. “The Popper Convention: Making Reproducible Systems Evaluation Practical.” In *2017 Ieee International Parallel and Distributed Processing Symposium Workshops (Ipdpsw)*, 1561–70. <https://doi.org/10.1109/IPDPSW.2017.157>.

