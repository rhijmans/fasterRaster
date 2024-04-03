#' Create a raster with random values drawn from a uniform distribution
#'
#' @description `runifRast()` creates a raster with values drawn from a uniform (flat) distribution.
#'
#' @param x A `GRaster`. The output will have the same extent and dimensions as this raster.
#'
#' @param n A numeric integer: Number of rasters to generate. 
#'
#' @param low,high Numeric: Minimum and maximum values from which to select.
#'
#' @param seed Numeric integer vector or `NULL`: Random seed. If `NULL`, then a different seed will be generated by **GRASS**. Defining this is useful if you want to recreate rasters.  If provided, there should be one seed value per raster.
#'
#' @returns A `GRaster`.
#'
#' @example man/examples/ex_randRast.r
#' 
#' @seealso [rnormRast()], [rSpatDepRast()], [fractalRast()], and **GRASS** module `r.random.surface`
#'
#' @aliases runifRast
#' @rdname runifRast
#' @exportMethod runifRast
methods::setMethod(
    f = "runifRast",
    signature = c(x = "GRaster"),
    function(
		x,
        n = 1,
        low = 0,
        high = 1,
        seed = NULL
	) {

    if (!is.null(seed)) if (length(seed) != n) stop("You must provide one value of ", sQuote("seed"), " per raster, or set it to NULL.")

    .locationRestore(x)
    .region(x)

    srcs <- .makeSourceName("runif", "raster", n)

    for (i in seq_len(n)) {

		# # have to add/subtract a fractional number to avoid producing a rounded (CELL) raster
		# num <- 1 / sqrt(pi * exp(1))

		# ex <- paste0(srcs[i], " = float(rand(", low, " + ", num, ", ", high, " + ", num, ") - ", num, ")")
		ex <- paste0(srcs[i], " = float(rand(", low, " + 0.1, ", high, " + 0.1) - 0.1)")
        args <- list(
            cmd = "r.mapcalc",
            expression = ex,
            flags = c(.quiet(), "overwrite"),
            intern = TRUE
        )

        if (!is.null(seed)) {
			args$seed <- seed[i]
		} else {
			args$flags <- c(args$flags, "s")
		}
        do.call(rgrass::execGRASS, args = args)

    } # next raster
    .makeGRaster(srcs, rep("runif", n))

    } # EOF
)
