#' Save a GVector to disk
#'
#' @description This function saves a `GVector` to disk directly from a **GRASS** session.
#'
#' By default, files will be of OGC GeoPackage format (extension "`.gpkg`"), but this can be changed with the `format` argument. You can see a list of supported formats by simply using this function with no arguments, as in `writeVector()`, or by consulting the online help page for **GRASS** module `v.out.ogr`.
#'
#' @param x A `GVector`.
#' @param filename Character: Path and file name.
#' @param overwrite Logical: If `FALSE` (default), do not save over existing files.
#' @param format File format. Some common formats include:
#'	* `"GPKG"`: OGC GeoPackage (default).
#'	* `"CSV"`: Comma-separated value... saves the data table only, not the geometries.
#'	* `"ESRI_Shapefile"`: ESRI shapefile... \code{filename} should not end in an extension.
#'	* `"GeoJSON"`: GeoJSON
#'	* `"KML"`: Keyhole Markup Language (KML)
#'	* `"netCDF"`: NetCDF (argument `filename` should not end in an extension).
#'	* `"XLSX"`: MS Office Open XML spreadsheet
#' @param attachTable Logical: If `TRUE` (default), attach the attribute to table to the vector before saving it. If `FALSE`, the attribute table will not be attached.
#' @param ... Additional arguments to send to **GRASS** module `v.out.ogr`.
#'
#' @return Invisibly returns a `SpatVector`. Importantly, the function also writes one or more files to disk.
#'
#' @seealso [terra::writeVector()], [sf::st_write()]
#'
#' @example man/examples/ex_writeVector.r
#'
#' @aliases writeVector
#' @rdname writeVector
#' @exportMethod writeVector
setMethod(
	"writeVector",
	signature(x = "GVector", filename = "character"),
	function(
		x,
		filename,
		overwrite = FALSE,
		format = "GPKG",
		attachTable = TRUE,
		...
	) {

	### going to overwrite anything?
	if (!overwrite && file.exists(filename)) stop(paste0("File already exists and ", sQuote("overwrite"), " is FALSE:\n ", filename))

	# ### remove table
	# if (.vHasTable(x)) {

	# 	src <- .copyGVector(x)

	# 	rgrass::execGRASS(
	# 		cmd = "v.db.connect",
	# 		map = src,
	# 		layer = "1",
	# 		flags = c(.quiet(), "overwrite", "d")
	# 	)

	# }

	if (attachTable & nrow(x) > 0L) {

		src <- .copyGVector(x)
		table <- as.data.frame(x)
		.vAttachTable(src, table = table, replace = TRUE)

	} else {
		src <- sources(x)
	}

	### general arguments
	args <- list(
		cmd = "v.out.ogr",
		input = src,
		output = filename,
		flags = c(.quiet(), "s")
	)
	if (overwrite) args$flags <- c(args$flags, "overwrite")
	do.call(rgrass::execGRASS, args)
	
	out <- terra::vect(filename)

	if (nrow(x) > 0L && any(names(out) == "cat_")) out$cat_ <- NULL

	invisible(out)

	} # EOF
)

#' @aliases writeVector
#' @rdname writeVector
#' @export
#' @exportMethod writeVector
setMethod(
	"writeVector",
	signature(x = "missing", filename = "missing"),
	function(x, filename) {

		forms <- rgrass::execGRASS("v.out.ogr", flags="l", intern=TRUE)
		forms <- forms[forms != "Supported formats:"]
		forms <- trimws(forms)
		forms <- sort(forms)
		forms <- c("Supported vector file formats:", forms)
		cat(paste(forms, collapse="\n"))
		cat("\n")
		utils::flush.console()
		
	} # EOF
)
