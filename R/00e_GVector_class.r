#' @title Classes for fasterRaster locations, rasters, and vectors
#'
#' @name GMetaTable-class
#' @aliases GMetaTable
#' @rdname GSession-class
#' @exportClass GMetaTable
GMetaTable <- setClass("GMetaTable")

#' @name GEmptyMetaTable-class
#' @aliases GEmptyMetaTable
#' @rdname GSession-class
#' @exportClass GEmptyMetaTable
GEmptyMetaTable <- setClass("GEmptyMetaTable", contains = "GMetaTable")

#' @name GFullMetaTable-class
#' @aliases GFullMetaTable
#' @rdname GSession-class
#' @exportClass GFullMetaTable
GFullMetaTable <- setClass(
	"GFullMetaTable",
	contains = "GMetaTable",
	slots = list(
		dbLayer = "character",
		fields = "character",
		classes = "character"
	)
)

#' @noRd
setValidity("GFullMetaTable",
	function(object) {
		if (length(object@fields) != length(object@classes)) {
			"Number of @fields must be the same as the number of @classes"
		} else if (is.na(object@dbLayer)) {
			"@dbLayer cannot be NA."
		} else {
			TRUE
		}
	} # EOF
)

#' @name GVector-class
#' @aliases GVector
#' @rdname GSession-class
#' @exportClass GVector
GVector <- methods::setClass(
	"GVector",
	contains = "GSpatial",
	slots = list(
		projection = "character",
		nGeometries = "integer",
		geometry = "character",
		nFields = "integer",
		db = "GMetaTable"
	),
	prototype = prototype(
		projection = NA_character_,
		geometry = NA_character_,
		nGeometries = NA_integer_,
		nFields = NA_integer_,
		db = GEmptyMetaTable()
	)
)


setValidity("GVector",
	function(object) {
		if (!all(object@geometry %in% c(NA_character_, "points", "lines", "polygons"))) {
			paste0("@geometry can only be NA, ", sQuote("points"), ", ", sQuote("lines"), ", or ", sQuote("polygons"), ".")
		# } else if (!inherits(object@db, "GEmptyMetaTable") && object@nFields != length(object@db@fields)) {
			# "@fields does not have @nFields values."
		# } else if (!inherits(object@db, "GEmptyMetaTable") && object@nFields != length(object@db@classes)) {
			# "@classes does not have @nFields values."
		} else {
			TRUE
		}
	} # EOF
)

#' Create a GVector
#'
#' @description Create a `GVector` from a vector existing in the current **GRASS** session.
#'
#' @param gn Character: The name of the vector in **GRASS**.
#'
#' @returns A `GVector`.
#'
#' @seealso [.makeGRaster()]
#'
#' @example man/examples/ex_GRaster_GVector.r
#'
#' @noRd
.makeGVector <- function(gn) {

	info <- .vectInfo(gn)
	
	db <- if (is.na(info[["fields"]][1L])) {
		GEmptyMetaTable()
	} else {
		GFullMetaTable(
			dbLayer = info[["dbLayer"]],
			fields = info[["fields"]],
			classes = info[["classes"]]
		)
	}
	
	new(
		"GVector",
		location = getFastOptions("location"),
		mapset = getFastOptions("mapset"),
		crs = crs(),
  		projection = info[["projection"]][1L],
		topology = info[["topology"]][1L],
		sources = gn,
		geometry = info[["geometry"]][1L],
		nGeometries = info[["nGeometries"]],
		extent = c(info[["west"]][1L], info[["east"]][1L], info[["south"]][1L], info[["north"]][1L]),
		zextent = c(info[["zbottom"]], info[["ztop"]]),
		nFields = info[["nFields"]],
		db = db
	)
	
}
