#' Get/create inrastName argument
#'
#' Retrieves or generates \code{inRastName}, which are names for each input raster.
#'
#' @param inRastName Either \code{NULL}, or a character vector, one per layer in \code{rast}.
#' @param rast A \code{SpatRaster} object with one or more layers.
#'
#' @return A character vector.
#'
#' @keywords internal
.getInRastName <- function(inRastName, rast) {

	if (missing(inRastName)) inRastName <- NULL

	# not needed
	if (is.null(rast)) {
		inRastName <- NULL
	# needed
	} else {

		# number of rasters
		if (inherits(rast, 'character')) {
			n <- length(rast)
		} else {
			rast <- terra::rast(rast)
			n <- terra::nlyr(rast)
			rastNames <- names(rast)
		}

		if (is.null(inRastName)) {

			# if rast is a character
			if (inherits(rast, 'character')) {
				
				# see if this is a raster file
				if (file.exists(rast)) {
					inRastName <- tryCatch(names(terra::rast(rast)), error=function(cond) FALSE)
					if (is.logical(inRastName)) inRastName <- basename(rast)
				} else {
					inRastName <- rast
				}
				
			# if rast is a raster
			} else {
				if (any(is.null(rastNames)) || any(is.na(rastNames)) || any(rastNames == '')) {
					inRastName <- if (n > 1L) {
						paste0('inputRast', 1L:n)
					} else {
						'inputRast'
					}
				} else {
					inRastName <- rastNames
				}
			}
		
		}
		
		if (length(inRastName) != n) stop('The number of names in "inRastName" is not the same as the number of layers in this raster.')
		
	}

	inRastName

}

#' Get/create inVectName
#'
#' Define inVectName
#'
#' @param inVectName Any of: NULL (use default: "inputVect") or a character.
#' @param vect A character, SpatVector, or sf object.
#'
#' @return TRUE invisibly
#'
#' @keywords internal
.getInVectName <- function(inVectName, vect) {

	if (missing(inVectName) || is.null(inVectName)) {
		if (inherits(vect, 'character')) {
			inVectName <- vect
		} else {
			inVectName <- 'inputVect'
		}
	}
	inVectName
}
