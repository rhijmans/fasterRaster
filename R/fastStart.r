#' Initialize a 'GRASS' session
#'
#' This function initializes a **GRASS** session in a particulatr folder. You need to run this function before you use most functions in **fasterRaster** (just once). You can also use the function to switch your **GRASS** session to a different folder, even if one is already started.
#'
#' @param crs Any object from which a coordinate reference system (CRS) can be acquired. Ergo, any of:
#' * A `SpatRaster`, `SpatVector`, `SpatExtent`, `stars` or `sf` object
#' * A CRS (coordinate reference system) string
#'
#' @param grassDir Character or `NULL` (default): Folder in which **GRASS** is installed on your computer. This will look different depending on the operating system and verison of **GRASS** you have installed. Here are some examples:
#' * Windows: `'C:/Program Files/GRASS GIS 8.3'`
#' * Mac OS: `"/Applications/GRASS-8.3.app/Contents/Resources"`
#' * Linux: `'/usr/local/grass'`
#' If `NULL`, then the function will use [getFastOption()] to attempt to get it. If it fails, `grassDir` will stay as `NULL` and likely reseult in an error.
#'
#' @param workDir `NULL` or character: The name of the folder in which **GRASS** will store rasters and vectors. If this is `NULL` (default), then the [tempdir()] on the user's system will be used. If users wish to create persistent **GRASS** sesssions that can be used in a different instance of **R** (i.e., if **R** is stopped then restarted), then this needs to be specified.
#'
#' @param overwrite Logical: If `FALSE` (default), and a **GRASS** session in the stated (or default) location and mapset has already been started, then the function will fail. If `TRUE`, then any existing **GRASS** session will be overwritten. *NOTE*: This will **not** remove any **R** objects associated with rasters or vectors in the session, but they will no longer work because the objects they point to will be overwritten.
#
#' @param warn Logical: If `TRUE` (default) and `overwrite` is `TRUE`, then display a warning.
#'
#' @param ... Options to send to [setFastOptions()]. These should be in `option = value` format.
#'
#' @return An [rgrass::gmeta()] object (a list) if successful (invisibly). If not successful, the function will usually either fail or return `FALSE` with a warning.
#'
#' @seealso Guide to getting [started](tutorial_starting) with **fasterRaster**.
#'
#' @example man/examples/examples_fastStart.r
#'
#' @export

fastStart <- function(
	crs,
	grassDir= NULL,
	workDir = NULL,
	overwrite = FALSE,
	warn = TRUE,
	...
) {

	# for debugging
	if (FALSE) {

		grassDir <- 'C:/Program Files/GRASS GIS 8.2' # Windows
		dots <- list()
		workDir <- NULL
		crs <- madRivers
	
	}

	### function globals
	dots <- list(...)
	if (is.null(workDir)) workDir <- rightSlash(tempdir())
	dir.create(workDir, showWarnings=FALSE, recursive=TRUE)

	### CRS
	if (inherits(crs, c('SpatRaster', 'SpatVector', 'SpatExtent'))) {
		crs <- terra::crs(crs)
	} else if (inherits(crs, 'sf')) {
		crs <- sf::st_crs(crs)
	} else if (inherits(crs, 'stars')) {
		crs <- stars::st_crs(crs)
	} # else, we assume crs is a string
	
	if (inherits(crs, 'crs')) crs <- unclass(crs)$wkt

	### do we need a new GRASS session or to swicth the location/working directory?

	if (is.null(grassDir)) grassDir <- getFastOptions('grassDir')
	if (is.na(grassDir)) grassDir <- NULL

	mapset <- if (!('mapset' %in% names(dots))) {
		getFastOptions('mapset')
	} else {
		dots$mapset
	}

	location <- if (!('location' %in% names(dots))) {
		getFastOptions('location')
	} else {
		dots$location
	}

	if (overwrite) {
	
		if (warn) warning(paste0('The GRASS session with these properties has been overwritten:\n  * location: ', location, '\n  * mapset: ', mapset, '\n  * workDir: ', workDir, '.\n  All previously existing files have been removed.'), immediate.=TRUE)
		
		rgrass::unset.GIS_LOCK()
		rgrass::remove_GISRC()
		rgrass::unlink_.gislock()

		files <- list.files(file.path(workDir, location), include.dirs = TRUE, full.names = TRUE, recursive = TRUE)
		files <- rev(files)
		unlink(files, recursive = TRUE)
		unlink(file.path(workDir, location), recursive = TRUE)
	
	}
		
	# are we trying to restart same folder, etc. but with a different CRS?
	crsFile <- file.path(workDir, location, mapset, '.crs.rds')
	if (!overwrite & length(crsFile) > 0L && file.exists(crsFile)) {
		existingCrs <- readRDS(crsFile)
		if (existingCrs != crs) {

			stop('The active GRASS session has a different coordinate reference system.\n  Either use the same CRS or a different location (see ?locations).')

		}
	}
		
	### start new GRASS session
	emptyRast <- terra::rast(matrix(1), type='xy', crs=crs)

	### start the GRASS session
	suppressWarnings(
		session <- rgrass::initGRASS(
			gisBase = grassDir,
			home = workDir,
			SG = emptyRast,
			location = location,
			mapset = mapset,
			override = TRUE, # must be TRUE to restart, even in different location/mapset
			remove_GISRC = TRUE, # ???
			ignore.stderr = TRUE
		)
	)
		
	### set options
	setFastOptions(grassDir = grassDir, workDir = workDir)
	if (length(dots) > 0L) setFastOptions(...)
	
	saveRDS(crs, file=crsFile)
			
	invisible(session)

}
