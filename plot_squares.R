#!/usr/bin/env Rscript
#
# Plot the square subregions on a map.
# The plot is written as PNG to the file given as argument.
# The subregions are read line by line from STDIN in the format
# "EAST WEST SOUTH NORTH"
#
# Author: Wolfgang Traylor <wolfgang.traylor@senckenberg.de>
#
# Usage: ./get_square_regions.py | ./plot_squares.R <out.png>

library(ggplot2)
library(maps)

# Convert longitude from 0°/360° to -180°/+180° format.
convert_long_to_180 <- function(x){
  ifelse(x > 180, x - 360, x)
}


args = commandArgs(trailingOnly = TRUE)
if (length(args) != 1)
  stop("Please provide exactly one argument.")

lon_bounds = as.numeric(c(Sys.getenv("LON1"), Sys.getenv("LON2")))
lat_bounds = as.numeric(c(Sys.getenv("LAT1"), Sys.getenv("LAT2")))

squares.db <- read.csv(file = "stdin", header = FALSE, sep = " ")
names(squares.db) <- c("east", "west", "south", "north")

pacific_centered <- (lon_bounds[1] < 180 && lon_bounds[2] > 180)

if (!pacific_centered) {
  squares.db$east = convert_long_to_180(squares.db$east)
  squares.db$west = convert_long_to_180(squares.db$west)
  lon_bounds = convert_long_to_180(lon_bounds)
}

world_map <- ggplot2::map_data("world",
  wrap = ifelse(pacific_centered, lon_bounds, FALSE)
)

regions.map <- ggplot() +
  geom_polygon(
    data = world_map,
    aes(x = long, y = lat, group = group)
    ) +
  geom_rect(
    data = squares.db,
    aes(xmin = east, xmax = west, ymin = south, ymax = north),
    color = "red",
    fill = NA
    ) +
  coord_fixed(xlim = lon_bounds, ylim = lat_bounds) +
  labs(x = "Longitude",
    y = "Latitude",
    title = "Preview of Square Subregions",
    caption = paste0(
      "Square size: ", Sys.getenv("SQUARE_SIZE"), "°\n",
      "East–West: ", lon_bounds[1], "°E to ", lon_bounds[2], "°E\n",
      "South–North: ", lat_bounds[1], "°N to ", lat_bounds[2], "°N\n",
      "Coastlines are modern."
    )
  )

ggsave(args[1], regions.map)
