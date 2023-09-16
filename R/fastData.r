#' Get one of the example rasters or spatial vectors
#'
#' This function is a simple way to get example rasters or spatial vector datasets that come with **fasterRaster**.
#'
#' @param x The name of the raster or spatial vector to get. All of these represent a portion of the eastern coast of Madagascar.
#'
#' Spatial vectors (objects of class `sf` from the **sf** `package):
#' * `madCoast0: Outline of the region (polygon)
#' * `madCoast4`: Outlines of the Fokontanies (Communes) of the region (polygons)
#' * `madDypsis`: Records of plants of the genus *Dypsis* (points)
#' * `madRivers`: Major rivers (lines)
#'
#' Rasters (objects of class `SpatRaster` from the **terra** package):
#' * `madChelsa`: Bioclimatic variables
#' * `madCover`: Land cover (also see `madCoverCats)
#' * `madElev`: Elevation
#' * `madForest2000`: Forest cover in year 2000
#' * `madForest2014`: Forest cover in year 2014
#' * `madLand`: Surface reflectance in 2023
#'
#' Data frames
#' * `appFunsTable`: Table of functions usable by [app()].
#' * `madCoverCats`: Land cover values and categories.
#'
#' @return A `SpatRaster` or `sf` spatial vector.
#'
#' @seealso [madCoast0], [madCoast4], [madCover], [madCoverCats], [madDypsis], [madElev], [madForest2000], [madForest2014], [madRivers]
#'
#' @example man/examples/ex_fastData.r
#'
#' @export
fastData <- function(x) {

	vectors <- c("madCoast0", "madCoast4", "madDypsis", "madRivers")
	tables <- c("appFunsTable", "madCoverCats")
	rasters <- c("madChelsa", "madCover", "madElev", "madLand", "madForest2000", "madForest2014")

	if (!inherits(x, "character")) {
		stop("Please supply the name of an example raster or spatial vector in fasterRaster.")
	} else {
		if (x %in% c(vectors, tables)) {

			madCoast0 <- madCoast4 <- madDypsis <- madRivers <- NULL
			madCoverCats <- NULL
			out <- do.call(utils::data, list(x, envir = environment(), package = "fasterRaster"))
			out <- get(out)

		} else if (x %in% rasters) {
			rastFile <- system.file("extdata", paste0(x, ".tif"), package = "fasterRaster")
			out <- terra::rast(rastFile)

			if (x == "madCover") {
			    levs <- system.file("extdata", paste0("madCover.csv"), package = "fasterRaster")
				levs <- utils::read.csv(levs)
				levels(out) <- levs
				# set.cats(out, layer = 1L, value = levs, active = 1L)
			}

		} else {
			stop("Please supply the name of a data object available in fasterRaster.")
		}
	}

	out

}
