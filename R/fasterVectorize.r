#' Convert a raster to a vector (points, lines, or polygons)
#'
#' This function is a potentially faster version of the function \code{\link[raster]{rasterToPolygons}} in the \pkg{raster} package. It can convert a raster to points or polygons (conversion to lines is not yet supported, although it is possible using the \code{r.to.vect} function in GRASS).
#' @param rast Either a raster or the full path and name of a raster object. The raster values must be 1 or 0 (or \code{NA}). The fragmentation index applies to the state of the entity represented by the 1's.
#' @param vectType Character, Indicates type of output: \code{point}, \code{line} (not supported yet), or \code{area}.
#' @param agg Logical, if \code{TRUE} (default) then union all points/lines/polygons with the same value into the same "multipart" polygon. This may or may not be desirable. For example, if the raster is vectorized into a polygons object each cell will become a separate polygon. Using this option will merge cells with the same value (even if they are not spatially adjacent one another).
#' @param smooth Logical, if \code{TRUE} then "round" cell corners by connecting the midpoints of corner cells (which leaves out the corner-most triangle of that cell). This option only applies if \code{vectType} is \code{area}. Default is \code{FALSE}.
#' @param calcDensity Logical, if \code{TRUE} then calculate density in the moving window. This will create a raster named \code{density} in the GRASS environment if \code{backToR} is \code{FALSE} or return a raster named \code{density} if \code{backToR} is \code{TRUE}. Default is \code{FALSE}.
#' @param calcConnect Logical, if \code{TRUE} then calculate a connectivity raster (conditional probability a cell with a value of 1 has a value that is also 1) in the moving window. This will create a raster named \code{connect} in the GRASS environment if \code{backToR} is \code{FALSE} or return a raster named \code{connect} if \code{backToR} is \code{TRUE}. Default is \code{FALSE}.
#' @param grassLoc Either \code{NULL} or a 3-element character vector. If the latter, the first element is the base path to the installation of GRASS, the second the version number, and the third the install type for GRASS.  For example, \code{c('C:/OSGeo4W64/', 'grass-7.4.1', 'osgeo4W')}. See \code{\link[link2GI]{linkGRASS7}} for further help. If \code{NULL} (default) the an installation of GRASS is searched for; this may take several minutes.
#' @param initGrass Logical, if \code{TRUE} (default) then a new GRASS session is initialized. If \code{FALSE} then it is assumed a GRASS session has been initialized using the raster in \code{rast}. The latter is useful if you are chaining \pkg{fasterRaster} functions together and the first function initializes the session.
#' @param backToR Logical, if \code{TRUE} (default) then the product of the calculations will be returned to R. If \code{FALSE}, then the product is left in the GRASS session and named \code{rastToVect}. The latter case is useful (and faster) when chaining several \pkg{fasterRaster} functions together.
#' @param ... Arguments to pass to \code{\link[rgrass7]{execGRASS}} when used for converting a raster to a vector (i.e., function \code{r.to.vect} in GRASS).
#' @return If \code{backToR} if \code{TRUE}, then a SpatialPointsDataFrame, SpatialLinesDataFrame, or a SpatialPolygonsDataFrame with the same coordinate reference system as \code{rast}. The field named \code{value} will have the raster values. Otherwise, vector object named \code{vectToRast} a  will be written into the GRASS session.
#' @details See (r.to.vect)[https://grass.osgeo.org/grass74/manuals/r.to.vect.html] for more details.  Note that if you get an error saying "", then you should add the EPSG code to the beginning of the raster and vector coordinate reference system string (their "proj4string"). For example, \code{proj4string(x) <- CRS('+init=epsg:32738')}. EPSG codes for various projections, datums, and locales can be found at (Spatial Reference)[http://spatialreference.org/].
#' @seealso \code{\link[raster]{rasterToPolygons}}, \code{\link[fasterRaster]{fasterRasterize}} 
#' @examples
#' \dontrun{
#' library(rgeos)
#' data(madForest)
#' # GRASS location -- change if needed, depending on version number
#' # and location!
#' grassLoc <- c('C:/OSGeo4W64/', 'grass-7.4.1', 'osgeo4W')
#' 
#' ### project raster
#' # could also use projectRaster() which
#' # may be faster in this example
#' elev <- fasterProjectRaster(elev, forest2000, grassLoc=grassLoc)
#' # elev <- projectRaster(elev, forest2000)
#' plot(elev, main='Elevation')
#' plot(mad0, add=TRUE)
#'
#' ### create mask for raster calculations
#' # could also use rasterize() or mask() which may
#' be faster in this example
#' madMask <- fasterRasterize(mad0, elev, grassLoc=grassLoc)
#' elev <- madMask * elev
#' # alternative #1
#' # madMask <- rasterize(mad0, elev)
#' # madMask <- 1 + 0 * madMask
#' # elev <- madMask * elev
#' #
#' # alternative #2
#' # elev <- mask(elev, mad0)
#' plot(elev, main='Elevation (m)')
#' plot(mad0, add=TRUE)
#'
#' ### topography
#' # could also use terrain() which may be faster
#' in this example
#' topo <- fasterTerrain(elev, slope = TRUE, aspect=TRUE, grassLoc=grassLoc)
#' # slp <- terrain(elev, opt='slope', unit='degrees')
#' # asp <- terrain(elev, opt='aspect', unit='degrees')
#' # topo <- stack(slp, asp)
#' # names(topo) <- c('slope', 'aspect')
#' plot(topo)
#'
#' ### distance to coast
#' # could also use distance() function which may be
#' # faster in this example
#' distToCoast <- fasterRastDistance(elev, fillNAs=FALSE, grassLoc=grassLoc)
#' # ocean <- calc(elev, function(x) ifelse(is.na(x), 1, NA))
#' # distToCoast <- raster::distance(ocean)
#' # distToCoast <- madMask * distToCoast
#' plot(distToCoast, main='Distance to Coast (m)')
#'
#' ### distance to nearest river (in the study region)
#' # could also use distance() function
#' # which may be faster in this example
#' distToRiver <- fasterRastToVectDistance(
#' 	elev, madRivers, grassLoc=grassLoc)
#' # naRast <- NA * elev
#' # distToRiver <- distance(naRast, madRivers)
#' # distToRiver <- madMask * distToRiver
#' plot(distToRiver, main='Distance to River (m)'
#' plot(madRivers, col='blue', add=TRUE)
#'
#' ### convert rivers (lines) to raster
#' # could use rasterize() which may be faster in this example
#' riverRast <- fasterRasterize(madRivers, elev)
#' # riverRast <- rasterize(madRivers, elev)
#' # riverRast <- riverRast > 0
#' par(mfrow=c(1, 2))
#' plot(mad0, main='Rivers as Vector')
#' plot(madRivers, col='blue', lwd=2, add=TRUE)
#' plot(riverRast, main='Rivers as Raster', col='blue')
#' plot(mad0, add=TRUE)
#' 
#' ### forest fragmentation
#' # forest = 1, all other is NA so convert NA to 0
#' forest2000 <- raster::calc(forest2000, function(x) ifelse(is.na(x), 0, x))
#' forest2014 <- raster::calc(forest2014, function(x) ifelse(is.na(x), 0, x))
#'
#' # make mask to force ocean to NA
#' # could use fasterRasterize() or rasterize()
#' # rasterize is faster in this example because rasters are small
#' maskRast <- fasterRasterize(mad, forest2000, grassLoc=grassLoc)
#' # maskRast <- raster::rasterize(mad, forest2000)
#' # maskRast <- 1 + 0 * maskRast
#' forest2000 <- maskRast * forest2000
#' forest2014 <- maskRast * forest2014
#' names(forest2000) <- 'forest2000'
#' names(forest2014) <- 'forest2014'
#'
#' fragRasts <- fragmentation(forest2000)
#' change <- sum(forest2000, forest2014)
#' par(mfrow=c(2, 2))
#' plot(change, col=c('gray90', 'red', 'green'), main='Forest Cover')
#' legend('topright', legend=c('Forest', 'Loss'), fill=c('green', 'red'))
#' plot(fragRasts[['density']], main='Density in 2000')
#' plot(fragRasts[['connect']], main='Connectivity in 2000')
#' cols <- c('gray90', 'forestgreen', 'lightgreen', 'orange', 'yellow', 'red')
#' plot(fragRasts[['class']], main='Fragmentation Class', col=cols)
#' legend('topright', fill=cols,
#' 	legend=c('no forest', 'interior', 'patch',
#'		'transitional', 'perforated', 'edge'))
#'
#' ### raster to polygons
#' # convert fragmentation class to polygons
#' # could also use rasterToPolygons() which is
#' probably faster in this example
#' fragPoly <- fasterVectorize(fragRasts[['class']],
#' 	vectType='area', grassLoc=grassLoc)
#' # fragPoly <- rasterToPolygons(fragRasts[['class']], dissolve=TRUE)
#' plot(fragPoly, main='Fragmentation Class Polygon')
#' legend('topright', fill=cols,
#' 	legend=c('no forest', 'interior', 'patch',
#'		'transitional', 'perforated', 'edge'))
#'
#' }
#' @export

fasterVectorize <- function(
	rast,
	vectType,
	agg = TRUE,
	smooth = FALSE,
	grassLoc = NULL,
	initGrass = TRUE,
	backToR = TRUE,
	...
) {

	if (!(vectType %in% c('point', 'line', 'area'))) stop('Argument "vectType" in function fasterVectorize() must be either "point", "line", or "area".')

	flags <- c('quiet', 'overwrite')
	if (smooth & vectType == 'area') flags <- c(flags, 's')
	
	# load spatial object and raster
	if (class(rast) == 'character') rast <- raster::raster(rast)

	# get CRS
	p4s <- sp::proj4string(rast)
	
	# initialize GRASS
	if (initGrass) link2GI::linkGRASS7(rast, default_GRASS7=grassLoc, gisdbase=raster::tmpDir(), location='temp')
	
	exportRastToGrass(rast, vname='rast')

	# vectorize
	rgrass7::execGRASS('r.to.vect', input='rast', output='rastToVect', type=vectType, flags=flags, ...)
	
	# get raster back to R
	if (backToR) {
	
		out <- rgrass7::readVECT('rastToVect')
		
		# join output with same values
		if (agg) {
			out <- raster::aggregate(out, by='value')
		}
		
		sp::proj4string(out) <- p4s
		out
		
	}

}
