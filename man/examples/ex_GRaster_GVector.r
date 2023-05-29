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
library(sf)
library(terra)

# example data
madElev <- fastData('madElev')
madCoast0 <- fastData('madCoast0')
madRivers <- fastData('madRivers')
madDypsis <- fastData('madDypsis')

# start GRASS session for examples only
wd <- forwardSlash(tempdir()) # only for examples

faster(crs = madElev, grassDir = grassDir,
workDir = wd, location = 'examples') # line only needed for examples

### GRaster properties
######################

# convert SpatRasters to GRasters
elev <- fast(madElev)

dim(elev) # rows, columns, depths, layers
nrow(elev) # rows
ncol(elev) # columns
ndepth(elev) # depths
nlyr(elev) # layers

res(elev) # resolution

ncell(elev) # cells
ncell3d(elev) # cells (3D rasters only)

topology(elev) # number of dimensions
is.2d(elev) # is it 2D?
is.3d(elev) # is it 3D?

minmax(elev) # min/max values

# information on the GRASS session in which the GRaster is located
location(elev) # location
mapset(elev) # mapset

# "gnames" of the object (its name in GRASS)
gnames(elev)

# coordinate reference system
crs(elev)
st_crs(elev)

# extent (bounding box)
ext(elev)
st_bbox(elev)

# data type
datatype(elev)

# names
names(elev)

### GVector properties
######################

# convert sf vectors to GVectors
coast <- fast(madCoast4)
rivers <- fast(madRivers)
dypsis <- fast(madDypsis)

# extent
ext(rivers)
st_bbox(rivers) # extent

# coordinate reference system
crs(rivers)
st_crs(rivers)

# column names and data types
names(coast)
datatype(coast)

# session information
location(rivers) # GRASS location
mapset(rivers) # GRASS mapset

# points, lines, or polygons?
geomtype(dypsis)
geomtype(rivers)
geomtype(coast)

is.points(dypsis)
is.points(coast)

is.lines(rivers)
is.lines(dypsis)

is.polygons(coast)
is.polygons(dypsis)

# dimensions
nrow(rivers) # how many spatial features
ncol(rivers) # hay many columns in the data frame

# 2- or 3D
topology(rivers) # dimensionality
is.2d(elev) # is it 2D?
is.3d(elev) # is it 3D?

### operations on GVectors
##########################

# convert to data frame
as.data.frame(rivers)

# IMPORTANT #3: Revert back to original GRASS session if needed.
fastRestore(opts.)
removeSession('examples')

}
