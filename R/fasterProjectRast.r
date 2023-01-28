#' Project and resample a raster
#'
#' Project and resample raster.
#'
#' @inheritParams .sharedArgs_rast_multiple
#' @inheritParams .sharedArgs_inRastName_multiple
#' @inheritParams .sharedArgs_replace
#' @inheritParams .sharedArgs_grassDir
#' @inheritParams .sharedArgs_grassToR
#' @inheritParams .sharedArgs_outGrassName
#' @inheritParams .sharedArgs_dots_forInitGrass_andGrassModule
#'
#' @param template Either \code{NULL} (default) or a \code{SpatRaster} to serve as a template for projecting. If there is an existing \code{GRASS} session (started by another \pkg{fasterRaster} function or through the \code{\link{initGrass}} function), then this argument can be \code{NULL}, and the raster in \code{rast} will be projected to the coordinate reference system used by the current \code{GRASS} session.  However, if a \code{GRASS} session has not yet been started, or a different projection is desired, then this argument must be non-\code{NULL}.
#' @param method Character, method for resampling cells:
#' \itemize{
#' 		\item \code{nearest}: Nearest neighbor (uses value from 1 cell).
#' 		\item \code{bilinear}: Bilinear interpolation (default; uses values from 4 cells).
#' 		\item \code{bilinear_f}: Bilinear interpolation with fallback.
#' 		\item \code{bicubic}: Bicubic interpolation (uses values from 16 cells).
#' 		\item \code{bicubic_f}: Bicubic interpolation with fallback.
#' 		\item \code{lanczos}: Lanczos interpolation (uses values from 25 cells).
#' 		\item \code{lanczos_f}: Lanczos interpolation with fallback.
#' }
#'
#' @return If \code{grassToR} if \code{TRUE}, then a raster or raster stack with the same extent, resolution, and coordinate reference system as \code{rast}. Regardless, a raster with the name given by \code{outGrassName} is written into the \code{GRASS} session.
#'
#' @details Note that it is not uncommon to get the warning "Projection of dataset does not appear to match the current mapset" (followed by more information). If the coordinate reference systems match, then the cause is likely due to extra information being stored in one of the spatial object's coordinate reference system slot (e.g., an EPSG code in addition to the other proj4string information), in which case it can probably be safely ignored.
#'
#' @seealso \code{\link[terra]{project}} in \pkg{terra}; \href{https://grass.osgeo.org/grass82/manuals/r.proj.html}{\code{r.proj}} in \code{GRASS}
#'
#' @example man/examples/ex_fasterProject.r
#'
#' @export

fasterProjectRast <- function(
	rast,
	inRastName,
	template = NULL,
	method = 'bilinear',
	outGrassName = 'projectedRast',

	replace = fasterGetOptions('replace', FALSE),
	grassToR = fasterGetOptions('grassToR', TRUE),
	autoRegion = fasterGetOptions('autoRegion', TRUE),
	grassDir = fasterGetOptions('grassDir', NULL),
	...
) {

	### begin common
	flags <- .getFlags(replace=replace)
	inRastName <- .getInRastName(inRastName, rast)
	if (is.null(inVectName)) inVectName <- 'vect'
	
	# region settings
	success <- .rememberRegion()
	on.exit(.returnToRegion(inits), add=TRUE)
	on.exit(.revertRegion(), add=TRUE)
	on.exit(regionResize(), add=TRUE)
	
	if (is.null(inits)) inits <- list()
	### end common

	if (is.null(outGrassName)) outGrassName <- inRastName

	# template
	inits <- c(inits, list(rast=template[[1L]], vect=NULL, inRastName='TEMPTEMP_templateRast', inVectName=NULL, replace=replace, grassDir=grassDir))
	toRast <- do.call('initGrass', inits)

	fromRastLoc <- paste0('fromRast', round(1E9 * runif(1)))

	# focal raster
	inits$rast <- rast
	inits$location <- fromRastLoc
	inits$inRastName <- inRastName
	inits$tempDir <- attr(toRast, 'tempDir')
	fromGrass <- do.call('initGrass', inits)

	# switch back to default location
	reset <- initGrass(location=attr(toRast, 'session')$LOCATION_NAME, mapset=attr(toRast, 'session')$MAPSET)

	# rgrass::execGRASS('r.proj', location='fromRast', mapset='PERMANENT', input=inRastName[i], output=outGrassName[i], method=method, resolution=resol, flags=flags)
	for (i in 1L:nlyr(rast)) {
		rgrass::execGRASS('r.proj', location=fromRastLoc, mapset='PERMANENT', input=inRastName[i], output=outGrassName[i], method=method, flags=flags)
	}

	# cleanup
	reset <- initGrass(location=fromRast, mapset='PERMANENT')
	fasterRm(x='*')
	reset <- initGrass(location='default', mapset='PERMANENT')

	# return
	if (grassToR) {
	
		for (i in 1L:terra::nlyr(rast)) {
		
			thisOut <- fasterWriteRaster(outGrassName[i], paste0(tempfile(), '.tif'), overwrite=TRUE)
			out <- if (exists('out', inherits=FALSE)) {
				c(out, thisOut)
			} else {
				thisOut
			}
			
		}
	
		names(out) <- outGrassName
		out
		
	}
	
}
