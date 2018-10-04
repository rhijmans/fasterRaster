#' Calculate fragmentation indices for a raster
#'
#' This function uses multiple CPU cores to speed calculation of a set of fragmentation indices as per Riitters, K., J. Wickham, R. O'Neill, B. Jones, and E. Smith. 2000. Global-scale patterns of forest fragmentation. Conservation Ecology 4:3. URL: https://www.jstor.org/stable/26271763. (Also note the erratum to the paper on their classification scheme at https://www.ecologyandsociety.org/vol4/iss2/art3/errata/january26.2001.html.) Note that unlike many functions in the \pkg{fasterRaster] package this function does \emph{not} use GRASS but rather multiple cores. It is a wrapper for \code{\link[fasterRaster]{fasterFocal}}.
#' @param rast Raster with binary values (1 or 0 or \code{NA}).
#' @param size Integer, number of cells wide and high of the window used to calculate fragmentation. This must be an odd integer (default is 3).
#' @param pad Logical, if \code{TRUE} then add virtual rows and columns around the raster so that there are no edge effects. The virtual rows and columns are set to equal \code{padValue}. Default is \code{FALSE}.
#' @param padValue Value to which to set the values of the virtual cells used to pad the raster if \code{pad} is \code{TRUE}.
#' @param calcDensity Logical, if \code{TRUE} (default) then calculate density raster.
#' @param calcConnect Logical, if \code{TRUE} (default) then calculate connectivity raster.
#' @param calcClass Logical, if \code{TRUE} (default) then calculate classification raster. Note that to calculate the classification raster the density and connectivity rasters must also be calculated (\code{calcDensity} and \code{calcConnect} should both be \code{TRUE}). If they are not then the will be forced to \code{TRUE} with a warning.
#' @param na.rm Logical, if \code{FALSE} (default) then \code{NA} cells count as part of the area potentially occupied in a window (i.e., the count in the denominator when calculating density and they are counted as potential links in the connectance calculations if a neighboring cell has a value of 1). If \code{FALSE} then areas that border \code{NA} cells could still be classified as "interior" or otherwise have less apparent fragmentation if the occupied cells are fully surrounded by other occupied cells (except for the \code{NA} cells).
#' @param undet Character. When classifying this defines what is done with "undetermined" cases (when density is >= 0.6 and density == connectivity). Possible values include (partial matching of strings is used):
#' \itemize{
#' 	\item \code{undetermined}: Undetermined cases will be assigned a value of 5 (which is not assigned to any other case; default).
#' 	\item \code{perforated}: Undetermined cases will be assigned a value of 3 ("perforated").
#' 	\item \code{edge}: Undetermined cases will be assigned a value of 4 ("edge").
#' 	\item \code{random}: Undetermined cases will be assigned a value of 3 or 4 at random ("perforated" or "edge").
#' }
#' @param cores Integer >0, number of CPU cores to use to calculate the focal function (default is number of cores available on the system).
#' @param forceMulti Logical, if \code{TRUE} (default) then the function will attempt to use the total number of cores in \code{cores}. (Note that this many not necessarily be faster since each core costs some overhead.)  If \code{FALSE}, then the function will use up to \code{cores} if needed (which also may not be faster... it always depends on the problem being computed).
#' @return A raster stack with three rasters: a fragmentation classification (named \code{class}), the density of "1" pixels in the window (named \code{density}--called "pf" in Riitter et al. 2000), and a connectivity raster (conditional probability a cell with a value of 1 has a value that is also 1; named \code{connect}--called "pff" in Riitter et al. 2000).
#' The density and connectivity rasters have values in the range [0, 1], but the classification raster has coded values (from the erratum to Ritter et al. (2000):
#' \itemize{
#' 	\item \code{0}: No forest (or whatever is being evaluated) in window
#'	\item \code{1}: interior (\code{pf} == 1)
#'	\item \code{2}: patch (\code{pf} < 0.4)
#'	\item \code{3}: transitional (0.4 <= \code{pf} < 0.6)
#'	\item \code{4}: perforated (\code{pf} >= 0.6 & \code{pf - pff} > 0)
#'	\item \code{5}: edge (\code{pf} >= 0.6 & \code{pf - pff} < 0)
#'	\item \code{6}: undetermined (\code{pf} >= 0.6 & \code{pf == pff})
#' }
#' @seealso \code{\link[fasterRaster]{fragmentation}}
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
#' # ocean <- calc(elev, function(rast) ifelse(is.na(rast), 1, NA))
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
#' forest2000 <- raster::calc(forest2000, function(rast) ifelse(is.na(rast), 0, rast))
#' forest2014 <- raster::calc(forest2014, function(rast) ifelse(is.na(rast), 0, rast))
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
#' @seealso \code{\link[fasterRaster]{fragmentation}}
#' @export

fasterFragmentation <- function(
	rast,
	size = 3,
	pad = FALSE,
	padValue = NA,
	calcDensity = TRUE,
	calcConnect = TRUE,
	calcClass = TRUE,
	na.rm = FALSE,
	undet = 'undetermined',
	cores = raster::detectCores(),
	forceMulti = TRUE,
	...
) {

	if (size %% 2 == 0 | size < 3) stop('Argument "size" to function fragmentation() must be an odd integer >= 3.')
	if (calcClass & (!calcDensity | !calcConnect)) {
		warning('Forcing "calcDensity" and "calcConnect" in function "fragmentation()" to be TRUE since "calcClass" is TRUE.')
	}

	### single core
	if (cores == 1) {
		
		out <- fasterRaster::fragmentation(rast=rast, size=size, calcDensity=calcDensity, calcConnect=calcConnect, calcClass=calcClass, na.rm=na.rm, ...)

	### multi-core
	} else {
		
		if (calcDensity | calcClass) {
		
			fragDensity <- fasterRaster::fasterFocal(rast=rast, w=size, fun=fasterRaster:::.fragDensity, na.rm=na.rm, cores=cores, forceMulti=forceMulti, filename='', pad=pad, padValue=padValue, NAonly=FALSE)
		
			names(fragDensity) <- 'density'
			
		}
		
		if (calcConnect | calcClass) {
		
			fragConnect <- fasterRaster::fasterFocal(rast=rast, w=size, fun=fasterRaster:::.fragConnect, na.rm=na.rm, cores=cores, forceMulti=forceMulti, filename='', pad=pad, padValue=padValue, NAonly=FALSE)
			
			names(fragConnect) <- 'connect'
			
		}
			
		if (calcClass) {
		
			fragClass <- fasterRaster::fasterRaster(rast=stack(fragDens, fragConnect), fun=fasterRaster:::.fragClassify, XXXXXXXXXXXX, undet=undet)
			names(fragClass) <- 'class'
		
		}

		out <- if (calcDensity & !calcConnect & !calcClass) {
			fragDensity
		} else if (!calcDensity & calConnect & !calcClass) {
			fragConnect
		} else if (calcDensity & calConnect & !calcClass) {
			raster::stack(fragDensity, fragConnect)
		} else if (calcClass) {
			raster::stack(fragClass, fragDensity, fragConnect)
		}
		
	} # multi-core
		
	out
	
}
