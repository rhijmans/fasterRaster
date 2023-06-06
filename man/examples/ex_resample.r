\dontrun{
# NB This example is in a "dontrun{}" block because it requires users to have
# GRASS GIS Version 8+ installed on their system.

# IMPORTANT #1: If you already have a GRASS session started, you will need to
# run the line below and the last line in this example to work with it again.
# If you have not started a GRASS session, you can skip this step and go to
# step #2.
opts. <- getFastOptions()

# IMPORTANT #2: Select the appropriate line below and change as necessary to
# where GRASS is installed on your system.
grassDir <- "/Applications/GRASS-8.2.app/Contents/Resources" # Mac
grassDir <- 'C:/Program Files/GRASS GIS 8.2' # Windows
grassDir <- '/usr/local/grass' # Linux

# setup
library(terra)

# elevation raster, climate raster, rivers vector
madElev <- fastData('madElev')

# start GRASS session for examples only
faster(crs = madElev, grassDir = grassDir,
workDir = tempdir(), location = 'examples') # line only needed for examples

elev <- fast(madElev)

### resample raster to 120 x 120 m
elev120 <- resample(elev, c(120, 120), method='bilinear')
elev
elev120

### resample using a coarser raster as a template
# fasterRaster
coarser <- aggregate(elev, 4)

frResampFb <- resample(elev, coarser, method = 'lanczos')
frResamp <- resample(elev, coarser, method = 'lanczos', fallback = FALSE)

frResampFb
frResamp

# terra
coarserTerra <- aggregate(madElev, 4)
terra <- resample(madElev, coarserTerra, method = 'lanczos')

# compare fasterRaster with terra
frFb <- rast(frResampFb)
fr <- rast(frResamp)

frFb <- extend(frFb, terra)
fr <- extend(fr, terra)

frFb - terra
fr - terra

plot(terra, col = 'red', main = 'No fallback')
plot(fr, add = TRUE)

plot(terra, col = 'red', main = 'Fallback')
plot(frFb, add = TRUE)

# IMPORTANT #3: Revert back to original GRASS session if needed.
fastRestore(opts.)
fastRemove('exampleFrom')
fastRemove('exampleTo')

}
