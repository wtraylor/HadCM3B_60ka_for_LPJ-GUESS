#!/usr/bin/env python3

# SPDX-FileCopyrightText: 2021 W. Traylor <wolfgang.traylor@senckenberg.de>
#
# SPDX-License-Identifier: MIT

# Find the starting year for this particular file. Since the NetCDF files
# don’t contain that information in their metadata, we need to derive it
# from the filename.
# The counting starts with `start_year==0` at the first HadCM3B simulation
# year, which is 60,000 years BP.
# For example the filename "regrid_downSol_Seaice_mm_s3_srf_2.5_5kyr.nc" will
# yield the first year 55000 (60ka - 5ka) and the last year 57500 (60ka -
# 2.5ka).

import re
import sys


def extract_years(filename):
    """ Extract the first & last simulation year from the filename. """
    try:
        rgx = r'(?<=_)(\d+\.?5?)_(\d+\.?5?)(?=kyr\.nc)'
        matches = re.search(rgx, filename).groups()
        # Note that the positions of first and last year (chronologically)
        # are switched in the filename.
        last_year, first_year = [(60 - float(i)) * 1000 for i in matches]
    except (AttributeError, ValueError):
        sys.exit('Failed to extract year information from filename:\n'
                 '"%s"\n' % filename +
                 'Did you change the original filename?')
    return int(first_year), int(last_year)


def main():
    if len(sys.argv) != 2:
        sys.exit('Please provide exactly one filename as argument.')
    filename = sys.argv[1]
    first_year, last_year = extract_years(filename)
    print(first_year, last_year)
    sys.exit(0)


if __name__ == "__main__":
    main()
