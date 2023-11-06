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
grassDir <- "/Applications/GRASS-8.3.app/Contents/Resources" # Mac
grassDir <- "C:/Program Files/GRASS GIS 8.3" # Windows
grassDir <- "/usr/local/grass" # Linux

# setup
library(sf)

# sample data raster
madRivers <- fastData("madRivers")

# start GRASS session for examples only
faster(x = madRivers, grassDir = grassDir,
workDir = tempdir(), location = "examples") # line only needed for examples

# example data
madCoast4 <- fastData("madCoast4")
madRivers <- fastData("madRivers")
madDypsis <- fastData("madDypsis")

# convert SpatVectors to GVectors
coast <- fast(madCoast4)
rivers <- fast(madRivers)
dypsis <- fast(madDypsis)

# GVector properties
ext(rivers) # extent
crs(rivers) # coordinate reference system

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

# number of dimensions
topology(rivers)
is.2d(rivers) # 2-dimensional?
is.3d(rivers) # 3-dimensional?

# head/tail
head(rivers)
tail(rivers)

# just the data table
as.data.frame(rivers)
as.data.table(rivers)

# vector or table with just selected columns
names(rivers)
rivers$NAME
rivers[[c("NAM", "NAME_0")]]
rivers[[c(3, 5)]]

# selected geometries/rows of the vector
nrow(rivers)
selected <- rivers[2:6]
nrow(selected)

# plot
plot(rivers)
plot(selected, col = "red", add = TRUE)

# vector math
hull <- convHull(dypsis)

plus <- coast + hull
plot(plus)

minus <- coast - hull
plot(minus)

# IMPORTANT #3: Revert back to original GRASS session if needed.
restoreSession(opts.)
removeSession("examples")

}
