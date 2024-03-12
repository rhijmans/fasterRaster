#' @title Classes for fasterRaster locations, rasters, and vectors
#'
#' @aliases GVector
#' @rdname GLocation
#' @exportClass GVector
GVector <- methods::setClass(
	"GVector",
	contains = "GSpatial",
	slots = list(
		projection = "character",
		nGeometries = "integer",
		nSubgeometries = "integer",
		geometry = "character",
		table = "data.table"
	),
	prototype = prototype(
		projection = NA_character_,
		geometry = NA_character_,
		nGeometries = NA_integer_,
		nSubgeometries = NA_integer_,
		table = data.table::data.table(NULL)
	)
)


methods::setValidity("GVector",
	function(object) {

		info <- .vectInfo(object)

		if (!info$catsValid) {
			"Invalid vector topology. See the *Details* section in `fast()` on how to correct topology."
		} else if (!all(object@geometry %in% c(NA_character_, "points", "lines", "polygons"))) {
			paste0("@geometry can only be NA, ", sQuote("points"), ", ", sQuote("lines"), ", or ", sQuote("polygons"), ".")
		# } else if (length(unique(.vCats(object)) != object@nGeometries)) {
			# "The number of @nGeometries is not the same as the number of unique ", sQuote("cat"), " values in the vector attribute table in GRASS."
		# } else if (object@nGeometries > object@nSubgeometries) {
			# "The number of sub-geometries in @nSubgeometries must be <= the number of geometries in @nGeometries."
		} else if (object@nGeometries == 0L) {
			"GVector has no geometries."
		} else if (nrow(object@table) > 0L && nrow(object@table) != object@nGeometries) {
			"The data.table in @table must be a NULL table (data.table(NULL)), or\n  it must have the same number of rows as @nGeometries.\n  See the *Details* section in `fast()` on how to correct topology."
		} else {
			TRUE
		}
	} # EOF
)

#' Create a GVector
#'
#' @description Create a `GVector` from a vector existing in the current **GRASS** session.
#'
#' @param src Character: The name of the vector in **GRASS**.
#'
#' @param table A `data.table`, `data.frame`, or character. This can be `data.table(NULL)` or `data.frame(NULL)` if there is no table associated with the vector. If a character, this is interpreted as the name of the table in **GRASS**.
#'
#' @param build Logical: If `TRUE` (default), build topology using **GRASS** module `v.build`.
#'
#' @param extensive Logical: If `TRUE`, do extensive topological checks using `v.build`. The default is `FALSE`.
#'
#' @returns A `GVector`.
#'
#' @seealso [.makeGRaster()]
#'
#' @example man/examples/ex_GRaster_GVector.r
#'
#' @noRd
.makeGVector <- function(src, table = NULL, build = TRUE, extensive = FALSE) {

	if (inherits(table, "GVector")) table <- src@table
	if (is.null(table)) table <- data.table::data.table(NULL)
	if (!inherits(table, "data.table")) table <- data.table::as.data.table(table)

	cats <- .vCats(src, db = FALSE)
	# if (is.null(cats)) cats <- .vCats(src, db = FALSE)
	# dt <- data.table::data.table(frid = cats)
	# .vAttachDatabase(src, table = dt, replace = TRUE)
	
	# srcIn <- src
	# src <- .makeSourceName("v_category", "vector")
	# rgrass::execGRASS(
	# 	cmd = "v.category",
	# 	input = srcIn,
	# 	output = src,
	# 	option = "del",
	# 	flags = c(.quiet(), "overwrite", "t")
	# 	# flags = c(.quiet(), "overwrite")
	# )

	nGeoms <- length(unique(cats))
	nSubgeoms <- length(cats)

	info <- .vectInfo(src)

	# build topology
	if (build) {

		args <- list(
			cmd = "v.build",
			map = src,
			option = "build",
			flags = c(.quiet(), "overwrite"),
			echoCmd = FALSE
		)
		if (extensive) args$flags <- c(args$flags, "e")
		do.call(rgrass::execGRASS, args = args)

	}
	
	methods::new(
		"GVector",
		location = .location(),
		mapset = "PERMANENT",
		workDir = faster("workDir"),
		crs = crs(),
  		projection = info[["projection"]][1L],
		topology = info[["topology"]][1L],
		sources = src,
		geometry = info[["geometry"]][1L],
		nGeometries = nGeoms,
		nSubgeometries = nSubgeoms,
		extent = c(info[["west"]][1L], info[["east"]][1L], info[["south"]][1L], info[["north"]][1L]),
		zextent = c(info[["zbottom"]], info[["ztop"]]),
		table = table
	)

}
