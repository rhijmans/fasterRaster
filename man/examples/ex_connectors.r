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

# Setup
library(sf)

# Rivers vector and locations of Dypsis plants
madRivers <- fastData("madRivers")
madDypsis <- fastData("madDypsis")

# Start GRASS session for examples only:
faster(x = madRivers, grassDir = grassDir,
workDir = tempdir(), location = "examples") # line only needed for examples

# Convert sf's to GVectors:
rivers <- fast(madRivers)
dypsis <- fast(madDypsis)

### Connections from each point to nearest river
consFromDypsis <- connectors(dypsis, rivers)

plot(st_geometry(madDypsis))
plot(st_geometry(madRivers), col = "blue", add = TRUE)
plot(consFromDypsis, add = TRUE)

### Connections from each river to nearest point
consFromRivers <- connectors(rivers, dypsis)

plot(st_geometry(madDypsis))
plot(st_geometry(madRivers), col = "blue", add = TRUE)
plot(consFromRivers, add = TRUE)

# IMPORTANT #3: Revert back to original GRASS session if needed.
fastRestore(opts.)
removeSession("examples")

}
