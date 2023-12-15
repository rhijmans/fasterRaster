if (grassStarted()) {

# Setup
library(sf)
library(terra)

# Example data: elevation raster and points vector
madElev <- fastData("madElev") # raster
madCover <- fastData("madCover") # categorical raster
madDypsis <- fastData("madDypsis") # points vector
madRivers <- fastData("madRivers") # lines vector
madCoast4 <- fastData("madCoast4") # polygons vector

# Convert to fasterRaster formats:
elev <- fast(madElev) # raster
cover <- fast(madCover, method = "near", warn = FALSE) # categorical raster
dypsis <- fast(madDypsis) # points vector
rivers <- fast(madRivers) # lines vector
coast <- fast(madCoast4) # polygons vector

# Get values of elevation at points where Dypsis species are located:
extract(elev, dypsis, xy = TRUE)

# Extract from categorical raster at points:
extract(cover, dypsis)
extract(cover, dypsis, cats = TRUE)

# Extract and summarize values on a raster across polygons:
extract(elev, coast, fun = c("sum", "mean", "countNonNA"), overlap = FALSE)

# Extract and summarize values on a raster across lines:
extract(elev, rivers, fun = c("sum", "mean", "countNonNA"), overlap = FALSE)

# Extract from a polygons vector at a points vector:
table <- extract(coast, dypsis, xy = TRUE)
head(table) # first 3 are outside polygons vector, next 3 are inside

}
