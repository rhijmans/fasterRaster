#' Set or get options shared across "fasterRaster" functions
#'
#' @description These functions allows you to either 1) view or 2) define options shared by **fasterRaster** functions. 
#'
#' @param ... Either a character (the name of an option), or **fasterRaster** option that can be defined using an `option = value` pattern. These include:
#'
#' * `cores` (integer/numeric): Number of processor cores to use on a task. The default is 1. Only some **GRASS** modules allow this option.
#'
#' * `memory` (integer/numeric): The amount of memory to allocate to a task, in MB. The default is 300 MB. Only some **GRASS** modules allow this option.
#'
#' * `useDataTable` (logical): If `FALSE` (default), use `data.frame`s when going back and forth between data tables of `GVector`s and **R**. This can be slow for very large data tables. If `TRUE`, use `data.table`s from the **data.table** package. This can be much faster, but it might require you to know how to use `data.table`s if you want to manipulate them in **R**. You can always convert them to `data.frame`s using [base::as.data.frame()].
#' 
#' * `rasterPrecision` (character): The [precision][tutorial_raster_data_types] of values when applying mathematical operations to a `GRaster`. By default, this is `"double"`, which allows for precision to about the 16th decimal place. However, it can be set to `"float"`, which allows for precision to about the 7th decimal place. `float` rasters are smaller in memory and on disk. The default is `"double"`.`
#'
#' * `verbose` (logical): If `TRUE`, show **GRASS** messages and otherwise hidden slots in classes. This is mainly used for debugging, so most users will want to keep this at its default, `FALSE`.
#'
#' * `grassDir` (character): The folder in which **GRASS** is installed on your computer. Typically, this option is set when you run [faster()], but you can define it before you run that function. All subsequent calls of `faster()` do not need `grassDir` set because it will be obtained from the options. By default, `grassDir` is `NULL`, which causes the function to search for your installation of **GRASS** (and which usually fails). Depending on your operating system, your install directory will look something like this:
#'     * Windows: `"C:/Program Files/GRASS GIS 8.3"`
#'     * Mac OS: `"/Applications/GRASS-8.3.app/Contents/Resources"`
#'     * Linux: `"/usr/local/grass"`
#'
#' *  `addonDir` (character): Folder in which **GRASS** addons are stored. If `NULL` and `grassDir` is not `NULL`, this will be taken to be `file.path(grassDir, "addons")`.
#'
#'  * `workDir` (character): The folder in which **GRASS** rasters, vectors, and other objects are created and manipulated. Typically, this is set when you first call [faster()]. All subsequent calls to `faster()` will not do not need `workDir` defined because it will be obtained from the options. By default, this is set to the temporary directory on your operating system (from [tempdir()]).
#'
#' @param restore If `TRUE`, the all options will be reset to their default values. The default is `FALSE`.
#'
#' @param default Supplies the default value of the option(s).
#'
#' @return If just one option is specified, `getFastOptions()` returns a vector with a single value. If more than one option is specified, `gastFasterOptions()` returns a named list with values. The `setFasterOptions()` function changes the values of these settings and returns the pre-existing values as a list (invisibly--i.e., so you can revert to them if you want).
#'
#' @example man/examples/ex_options.r
#'
#' @export

setFastOptions <- function(
	...,
	restore = FALSE
) {

	opts <- list(...)
	if (length(opts) == 1L && inherits(opts[[1L]], "list")) opts <- opts[[1L]]

	namesOfOpts <- .namesOfOptions()
	if (!is.null(opts) && any(!(names(opts) %in% namesOfOpts))) stop("Invalid option(s): ", paste(names(opts[!(opts %in% namesOfOpts)]), collapse=", "))
	
	# retrieve in case we want to reset them
	out <- getFastOptions()

	### check for validity
	error <- paste0("Option ", sQuote("grassDir"), " must be ", dQuote("NULL"), " (which is likely to fail)\n  or a single character string. The default is ", dQuote(.grassDirDefault()), ".")
	if (any(names(opts) %in% "grassDir")) {
		if (!is.null(opts$grassDir)) {
   			if (!is.character(opts$grassDir) || length(opts$grassDir) != 1L) stop(error)
		}
	}

	error <- paste0("Option ", sQuote("addonDir"), " must be ", sQuote("NULL"), " or a single character string. The default is ", dQuote(.addonDirDefault()), ".")
	if (any(names(opts) %in% "addonDir")) {
		if (!is.null(opts$addonDir)) {
   			if (!is.character(opts$addonDir) || length(opts$addonDir) != 1L) stop(error)
		}
	}

	error <- paste0("Option ", sQuote("workDir"), " must be a single character string. The default is\n  ", dQuote(.workDirDefault()), ".")
	if (any(names(opts) %in% "workDir")) {
  		if (!is.character(opts$workDir) || length(opts$workDir) != 1L) stop(error)
	}

	error <- paste0("Option ", sQuote("location"), " must be a single character string. The default is ", dQuote(.locationDefault()), ".")
	if (any(names(opts) %in% "location")) {
  		if (!is.character(opts$location) || length(opts$location) != 1L) stop(error)
	}

	error <- paste0("Option ", sQuote("mapset"), " must be a single character string. The default is ", dQuote(.mapsetDefault()), ".")
	if (any(names(opts) %in% "mapset")) {
  		if (!is.character(opts$mapset) || length(opts$mapset) != 1L) stop(error)
	}

	if (any(names(opts) %in% "cores")) {
		if (!is.numeric(opts$cores) | (opts$cores <= 0 & opts$cores %% 1 != 0)) stop("Option ", sQuote("cores"), " must be an integer >= 1. The default is ", .coresDefault(), ".")
	}

	if (any(names(opts) %in% "verbose")) {
  		if (is.na(opts$verbose) || !is.logical(opts$verbose)) stop("Option ", sQuote("verbose"), " must be a logical. The default is ", .grassVerbose(), ".")
	}

	if (any(names(opts) %in% "memory")) {
		if (!is.numeric(opts$memory) || opts$memory <= 0) stop("Option ", sQuote("memory"), " must be a positive number. The default is ", .memoryDefault(), " (MB).")
	}

	# if (any(names(opts) %in% "autoRegion")) {
	# 	if (!is.logical(opts$autoRegion)) stop("Option ", sQuote("autoRegion"), " must be a logical. The default is ", .autoRegionDefault(), ".")
	# 	if (is.na(opts$autoRegion)) stop("Option ", sQuote("autoRegion"), " must be TRUE or FALSE (not NA). The default is ", .autoRegionDefault(), ".")
	# }

	if (any(names(opts) %in% "rasterPrecision")) {
	
		if (is.na(opts$rasterPrecision) || !is.character(opts$rasterPrecision)) stop("Option ", sQuote("rasterPrecision"), " must be ", sQuote("float"), ") or ", sQuote("double"), ".\n  The default is ", .rasterPrecisionDefault(), ".")

     	opts$rasterPrecision <- pmatchSafe(opts$rasterPrecision, c("FCELL", "float", "DCELL", "double"))
		opts$rasterPrecision <- if (opts$rasterPrecision == "FCELL") {
   			"float"
		} else if (opts$rasterPrecision == "DCELL") {
			"double"
		}
	}

	if (any(names(opts) %in% "useDataTable")) {

		if (is.na(opts$useDataTable) || !is.logical(opts$useDataTable)) stop("Option ", sQuote("useDataTable"), " must be a logical. The default is ", .useDataTableDefault(), ".")
	
	}

	### set the options
	if (length(opts) == 0L) {
		opts <- as.list(namesOfOpts)
		names(opts) <- namesOfOpts
	}
	
	for (opt in names(opts)) {
	
		# default
		if (restore | is.null(.fasterRaster$options[[opt]])) {
			val <- paste0(".", opt, "Default()")
			val <- eval(str2expression(val))
		} else {
			val <- opts[[opt]]
		}
		if (is.null(val)) {
			.fasterRaster$options[[opt]] <- list(val)
		} else {
			.fasterRaster$options[[opt]] <- val
		}
	}

	if (any(names(opt) %in% "verbose")) {
		rgrass::set.ignore.stderrOption(!getFastOptions("verbose"))
	}

	invisible(out)

}

#' @name getFastOptions
#' @title Report arguments shared across functions
#' @rdname setFastOptions
#' @export
getFastOptions <- function(..., default = FALSE) {

	namesOfOpts <- .namesOfOptions()
	opts <- unlist(list(...))
	if (!is.null(opts) && any(!(opts %in% namesOfOpts))) stop("Invalid option(s): ", paste(opts[!(opts %in% namesOfOpts)], collapse=", "))

	### return default values
	if (default) {

		if (length(opts) == 0L) opts <- namesOfOpts

		out <- list()
		for (opt in opts) {

			ex <- paste0(".", opt, "Default()")
			out[[length(out) + 1L]] <- eval(str2expression(ex))

		}
		names(out) <- opts

	### return options as they currently are
	} else {

		out <- list()
		# we have no options :(
		if (length(opts) == 0L) {
			out <- .fasterRaster$options
		# we have options, people!
		} else {
			out <- list()
			for (opt in opts) {
				out[[length(out) + 1L]] <- .fasterRaster$options[[opt]]
			}
			names(out) <- opts
		}

	}

	if (length(out) == 1L) out <- unlist(out)
	out

}
