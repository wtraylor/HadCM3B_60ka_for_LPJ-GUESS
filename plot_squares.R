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

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1)
  stop("Please provide exactly one argument.")
png_file <- args[1]

LON1 <- Sys.getenv("LON1")
if (LON1 == "") stop("Environment variable LON1 not set.")
LON2 <- Sys.getenv("LON2")
if (LON2 == "") stop("Environment variable LON2 not set.")
LAT1 <- Sys.getenv("LAT1")
if (LAT1 == "") stop("Environment variable LAT1 not set.")
LAT2 <- Sys.getenv("LAT2")
if (LAT2 == "") stop("Environment variable LAT2 not set.")
SQUARE_SIZE <- Sys.getenv("SQUARE_SIZE")
if (SQUARE_SIZE == "") stop("Environment variable SQUARE_SIZE not set.")
gridlist_reference <- Sys.getenv("gridlist_reference")
if (gridlist_reference == "")
  stop("Environment variable gridlist_reference not set.")

lon_bounds <- as.numeric(c(LON1, LON2))
lat_bounds <- as.numeric(c(LAT1, LAT2))

# Read the table of squares from STDIN.
squares.db <- read.csv(file = "stdin", header = FALSE, sep = " ")
names(squares.db) <- c("id", "east", "west", "south", "north")

# Fix those squares that cross 0° longitude.
squares.db$west <- mapply(
  function(e, w) ifelse(w < e, w + 360, w),
  squares.db$east,
  squares.db$west
)

world_map <- ggplot2::map_data("world", wrap = c(0, 360))

png(
  filename = png_file,
  width = 4096,
  height = 1350,
  res = 200,
  pointsize = 3
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
    fill = "white",
    alpha = 0.3
    ) +
  geom_text(
    data = squares.db,
    aes(label = id, x = (east + west) / 2, y = (south + north) / 2),
    color = "red",
    hjust = 0.5,
    vjust = 0.5,
    size = 1.3
    ) +
  coord_fixed(ylim = c(0,90)) +
  scale_x_continuous(breaks = seq(0, 360, 20)) +
  scale_y_continuous(breaks = seq(0, 90, 20)) +
  labs(
    x = "Longitude",
    y = "Latitude",
    title = "Preview of Square Subregions",
    caption = paste0(
      "Square size: ", SQUARE_SIZE, "°\n",
      "East–West: ", lon_bounds[1], "°E to ", lon_bounds[2], "°E\n",
      "South–North: ", lat_bounds[1], "°N to ", lat_bounds[2], "°N\n",
      "Reference file for palaeo landmass: '", gridlist_reference, "'\n",
      "The coastlines on this map are modern."
    )
  )

print(regions.map)
dev.off()
