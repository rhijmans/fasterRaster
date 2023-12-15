if (grassStarted()) {

# Setup
library(sf)
library(terra)

# Example data
madElev <- fastData("madElev")
madForest2000 <- fastData("madForest2000")
madCoast0 <- fastData("madCoast0")
madRivers <- fastData("madRivers")
madDypsis <- fastData("madDypsis")

### GRaster properties
######################

# convert SpatRasters to GRasters
elev <- fast(madElev)
forest <- fast(madForest2000)

# plot
plot(elev)

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

# "names" of the object
names(elev)

# coordinate reference system
crs(elev)

# extent (bounding box)
ext(elev)

# data type
datatype(elev)

# assigning
copy <- elev
copy[] <- pi # assign all cells to the value of pi
copy

# concatenating multiple GRasters
rasts <- c(elev, forest)
rasts

# adding a raster "in place"
add(rasts) <- ln(elev)
rasts

# subsetting
rasts[[1]]
rasts[["madForest2000"]]

# assigning
rasts[[4]] <- elev > 500

# number of layers
nlyr(rasts)

# names
names(rasts)
names(rasts) <- c("elev_meters", "forest", "ln_elev", "high_elevation")
rasts

### GVector properties
######################

# convert sf vectors to GVectors
coast <- fast(madCoast4)
rivers <- fast(madRivers)
dypsis <- fast(madDypsis)

# extent
ext(rivers)

W(rivers) # western extent
E(rivers) # eastern extent
S(rivers) # southern extent
N(rivers) # northern extent
top(rivers) # top extent
bottom(rivers) # bottom extent

# coordinate reference system
crs(rivers)

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

# Update values from GRASS
# (Reads values from GRASS... will not appear to do anything in this case)
update(elev)

### operations on GVectors
##########################

# convert to data frame
as.data.frame(rivers)

# subsetting
rivers[c(1:2, 5)] # select 3 rows/geometries
rivers[-5:-11] # remove rows/geometries 5 through 11
rivers[ , 1] # column 1
rivers[ , "NAM"] # select column
rivers[["NAM"]] # select column
rivers[1, 2] # row/geometry 1 and column 1
rivers[c(TRUE, FALSE)] # select every other geometry (T/F vector is recycled)
rivers[ , c(TRUE, FALSE)] # select every other column (T/F vector is recycled)

# Refresh values from GRASS
# (Reads values from GRASS... will not appear to do anything in this case
# since the rivers object is up-to-date):
rivers <- update(rivers)

# Concatenating multiple vectors
rivers2 <- c(rivers, rivers)
dim(rivers)
dim(rivers2)

}
