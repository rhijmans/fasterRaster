#' Combine rasters that do not perfectly overlap
#'
#' This function combines rasters with (potentially) different extents but the same registration, resolution, and coordinate reference system. The new output rasters will have the extent of the overall set of rasters. Preference is given by the order in which rasters are input. That is, if a given cell has a value in the first and the second raster, then the value in the first raster is used. However, if the cell is \code{NA} in the first raster, then the value in the second raster has will be used, unless the second raster also had \code{NA}, and so on.\cr
#' Note that unlike most \pkg{fasterRaster} functions, this function changes the extent of the entire \code{GRASS} session (i.e., in \code{GRASS} parlance, the "\href{https://grass.osgeo.org/grass82/manuals/grass_database.html}{location}"). This can affect any existing rasters and downstream analyses that use the extent to crop newly imported rasters or vectors.
#'
#' @inheritParams .sharedArgs_replace
#' @inheritParams .sharedArgs_grassToR
#' @inheritParams .sharedArgs_outGrassName
#'
#' @param ... Two or more \code{SpatRasters} (required); areguments to send to the \code{GRASS} module \href{https://grass.osgeo.org/grass82/manuals/r.patch.html}{\code{r.patch}} (optional); and arguments to send to \code{\link{initGrass}} (optional).
#' @param cores Number of cores to use.
#' @param memory Memory to use, in MB. The defualt is 300 MB.
#' @param inRastName The names of the input rasters in \code{GRASS}. The default value is the names of the raster(s) (i.e., \code{names(raster)}).
#'
#' @return A \code{SpatRaster}.
#'
#' @seealso \code{\link[terra]{mosaic}} in package \pkg{terra}; \href{https://grass.osgeo.org/grass82/manuals/r.patch.html}{\code{r.patch}} in \code{GRASS}
#'
#' @example man/examples/ex_fasterMosaic.r
#'
#' @export

fasterMosaic <- function(
	...,
	inRastName,
	cores = 1,
	memory = 300,
	outGrassName = 'mosaicRast',

	replace = fasterGetOptions('replace', FALSE),
	grassToR = fasterGetOptions('grassToR', TRUE),
	autoRegion = fasterGetOptions('autoRegion', TRUE),
	grassDir = fasterGetOptions('grassDir', NULL)
) {

	### begin common
	flags <- .getFlags(replace=replace)
	# inRastName <- .getInRastName(inRastName, rast)
	# if (is.null(inVectName)) inVectName <- 'vect'
	
		# inRastNames
		if (is.null(inRastName)) inRastName <- sapply(rasts, names)
		if (length(inRastName) != length(rasts)) stop('The number of rasters and names in "inRastName" are different.')

	# region settings
	success <- .rememberRegion()
	# on.exit(.restoreRegion(), add=TRUE)
	on.exit(regionResize(), add=TRUE)
	
	if (is.null(inits)) inits <- list()
	### end common
	
	# create extent
	ells <- list(...)
	rastersOrNot <- lapply(ells, inherits, what='SpatRaster')
	rasts <- ells[rastersOrNot]
	
	if (length(rasts) < 2L) stop('Function requires >1 raster as input.')
	
	proj <- terra::crs(rasts[[1L]])

	# get overall extent... NB, supposedly we could use terra::merge, but doesn't seem to work for SpatExtents
	extent <- terra::ext(rasts[[1L]])
	extent <- extent@ptr$vector
	for (i in 2L:length(rasts)) {
	
		thisExtent <- terra::ext(rasts[[i]])
		corners <- thisExtent@ptr$vector

		if (corners[1L] < extent[1L]) extent[1L] <- corners[1L]
		if (corners[2L] > extent[2L]) extent[2L] <- corners[2L]
		
		if (corners[3L] < extent[3L]) extent[3L] <- corners[3L]
		if (corners[4L] > extent[4L]) extent[4L] <- corners[4L]
		
	}
	
	
	# make region
	w <- as.character(extent[1L])
	e <- as.character(extent[2L])
	s <- as.character(extent[3L])
	n <- as.character(extent[4L])
	
	resol <- terra::res(rasts[[1L]])
	ewres <- as.character(resol[1L])
	nsres <- as.character(resol[2L])

	# initialize GRASS and expand region
	inits <- c(inits, list(rast=rasts[[1L]], vect=NULL, inRastName=inRastName[1L], inVectName=NULL, replace=replace, grassDir=grassDir))
	input <- do.call('initGrass', inits)
	rgrass::execGRASS('g.region', n=n, s=s, e=e, w=w, ewres=ewres, nsres=nsres, flags=c(flags, 'o'))

	# export remaining rasters
	for (i in 2L:length(rasts)) {
		fasterRast(rast = rasts[i], inRastName = inRastName[i], replace=replace)
	}

	# execute
	rgrass::execGRASS('r.patch', input=inRastName, output=outGrassName, nprocs=cores, memory=memory, flags=flags)

	# resize region to encompass all objects
	success <- regionResize()

	# return
	if (grassToR) {

		out <- fasterWriteRaster(outGrassName, paste0(tempfile(), '.tif'), overwrite=TRUE)
		out

	}
	
}
