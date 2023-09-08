#' Apply a function to a set of rasters
#'
#' @description `app()` applies a function to a set of "stacked" rasters. `appFuns()` provides a table of **GRASS** functions and their equivalents from the **terra** and **sf** packages. `appCheck()` tests whether a formula supplied to `app()` has any "forbidden" function calls.
#' 
#' `app()` function operates in a manner slightly different from [terra::app()]. The function to be applied *must* be written as a character string. For example, if the raster had layer names "`x1`" and "`x2`", then the function might be like `"= max(sqrt(x1), log(x2))"`. Rasters **cannot** have the same names as functions used in the formula. In this example, the rasters could not be named "max", "sqrt", or "log".
#' 
#' The `app()` function will automatically check for raster names that appear also to be functions that appear in the formula, but the `appCheck()` function can be applied to the raster stack plus the formula to do this outside of `app()`. You can obtain a list of functions using `appFuns()`. Note that these are sometimes different from how they are applied in **R**.
#'
#' TIPS:
#' * In **GRASS**, `null()` is the same as `NA` in **R**.
#' * If you want to calculate values using while removing `NA` (or `null`) values, see the functions that begin with `n` (like `nmean`).
#' * Be mindful of the data type that a function returns. In **GRASS**, these are `CELL` (integer), `FCELL` (floating point values--precise to about the 7th decimal place), and `DCELL` (double-floating point values--precise to about the 15th decimal place). In cases where you want to ensure a raster to be treated like a float or double data type raster, wrap the raster in the `float()` or `double()` functions to ensure it is treated as such. This is especially useful if the raster might be assumed to be the `CELL` type because it only contains integer values. You can get the data type of a raster using [datatype()]. You can change the data type of a `GRaster` using [as.int()], [as.float()], and [as.doub()]. Note that [categorical][tutorial_raster_data_types] are really `CELL` rasters with an associated "levels" table. You can also change a `CELL` raster to a `FCELL` raster by adding then subtracting a decimal value, as in `x - 0.1 + 0.1`.
#' * The `rand()` function returns `CELL` (integer) values by default. If you want non-integer values, use the tricks mentioned above to ensure non-integer values. For example, the [runifRast()] function's expression is (essentially) `= float(rand(0 + 0.1, 1 + 0.1) - 0.1)`
#'
#' @param x A `GRaster` with one or more named layers.
#'
#' @param fun Character: The function to apply. This must be written as a character string that follows these rules:
#' 
#' * It must begin with an equals sign ("`=`"").
#' * It must use typical arithmetic operators like `+`, `-`, `*`, `/` and/or functions that can be seen using `appFuns(TRUE)`.
#' * It has no functions that have the same names as the [names()] of any of the raster layers. Note that `x` and `y` are forbidden names :(
#' The help page for `r.mapcalc` on the **GRASS** website provides more details.
#' 
#' @param ensure Character: This ensures that rasters are treated as a certain type before they are operated on. This is useful when using rasters that have all integer values, which **GRASS** can assume represent integers, even if they are not supposed to. In this case, the output of operations on this raster might be an integer if otherwise not corrected. Partial matching is used, and options include:
#' * `"integer"`: Force all rasters to integers by truncating their values. The output may still be of type `float` if the operation creates non-integer values.
#' * `"float"`: Force rasters to be considered floating-point values.
#' * `"double"`: Force rasters to be considered double-floating point values.
#' * `"auto"` (default): Ensure that rasters are represented by their native [datatype()] (i.e., "CELL" rasters as integers, "FCELL" rasters as floating-point, and "DCELL" as double-floating point).
#'
#' @param seed Numeric integer vector or `NULL` (default): A number for the random seed. Used only for `app()` function `rand()`, that generates a random number. If `NULL`, a seed will be generated. Defining the seed is useful for replicating a raster made with `rand()`. This must be an integer!
#' 
#' @param show Logical (function `appFuns()`):
#' * `FALSE` (default): Return a `data.frame` or `data.table` with definitions of functions.
#' * `TRUE`: Open a searchable, sortable **shiny** table in a browser.
#' 
#' @param msgOnGood Logical (function `appCheck()`): If `TRUE` (default), display a message if no overt problems with the raster names and formula are detected.
#' 
#' @param failOnBad Logical (function `appCheck()`): If `TRUE` (default), fail if overt problems with raster names and the formula are detected.
#'
#' @returns A `GRaster`.
#'
#' @seealso [terra::app()], and modules `r.mapcalc` and `r.mapcalc.simple` in **GRASS**.
#'
#' @example man/examples/ex_app.r
#'
#' @aliases app
#' @rdname app
#' @exportMethod app
methods::setMethod(
    f = "app",
    signature = c(x = "GRaster"),
    function(x, fun, ensure = "auto", seed = NULL) {

    fun <- trimws(fun)

    if (substr(fun, 1L, 1L) != "=") stop("Argument ", sQuote("fun"), " should begin with an equals sign.")
    if (substr(fun, 1L, 2L) == "==") stop("Argument ", sQuote("fun"), " cannot begin with a double equals sign.")
    if (substr(fun, 1L, 2L) != "= ") fun <- paste0("= ", substr(fun, 2L, nchar(fun)))

    appCheck(x, fun, msgOnGood = FALSE, failOnBad = TRUE)

    .restore(x)
    region(x)

    # replace raster names with sources
    # replacing from longest to shortest to avoid issues with nestedness
    xn <- names(x)
    nchars <- nchar(xn)
    xn <- xn[order(nchars, decreasing = TRUE)]

    ensure <- pmatchSafe(ensure, c("integer", "float", "double", "auto"))
    if (ensure == "integer") ensure = "int"

    for (name in xn) {

        i <- which(name == names(x))
        src <- sources(x)[i]

        # ensure data type  
        dt <- datatype(x, "GRASS")[i]
        if (ensure == "auto") {
            src <- if (dt == "CELL") {
                paste0("int(", src, ")")
            } else if (dt == "FCELL") {
                paste0("float(", src, ")")
            } else if (dt == "DCELL") {
                paste0("double(", src, ")")
            }
        } else {
            if (dt != "FCELL") {
                src <- paste0(ensure, "(", src, ")")
            }
        }

        fun <- gsub(fun, pattern = name, replacement = src)
    }

    src <- .makeSourceName("app", "raster")
    fun <- paste(src, fun)

    args <- list(
        cmd = "r.mapcalc",
        expression = fun,
        flags = c("quiet", "overwrite"),
        intern = TRUE
    )
    if (is.null(seed)) {
		args$flags <- c(args$flags, "s")
	} else {
		args$seed <- seed
	}
    do.call(rgrass::execGRASS, args = args)
    .makeGRaster(src, "app")

    } # EOF
)

#' @aliases appFuns
#' @rdname app
#' @exportMethod appFuns
methods::setMethod(
    f = "appFuns",
    signature = c(show = "logical"),
    function(show = FALSE) {
    
	appFunsTable <- NULL
    utils::data("appFunsTable", envir = environment(), package = "fasterRaster")

    if (show & interactive()) {

        showableCols <- c("Type", "GRASS_Function", "R_Function", "Definition", "Returns")

        shiny::shinyApp(
            ui = shiny::fluidPage(DT::DTOutput("tbl")),
            server = function(input, output) {
                output$tbl <- DT::renderDT(
                    appFunsTable[ , showableCols],
                    caption = shiny::HTML("Functions that can be used in the fasterRaster app() function and the equivalent functions in R. Note that in GRASS, 'null()' is the same as 'NA'."),
                    options = list(
                        pageLength = nrow(appFunsTable),
                        width = "100%",
                        scrollX = TRUE
                    )
                    # options = list(lengthChange = FALSE)
                )
            }
        )
        
    } else if (show & !interactive()) {
        warning("You must be running R interactively to view the table using appFuns().")
    }

    if (getFastOptions("useDataTable")) appFunsTable <- data.table::data.table(appFunsTable)
    invisible(appFunsTable)

    } # EOF
)

#' @aliases appCheck
#' @rdname app
#' @exportMethod appCheck
methods::setMethod(
    f = "appCheck",
    signature = c(x = "GRaster", fun = "character"),
    function(x, fun, msgOnGood = TRUE, failOnBad = TRUE) {

    # any forbidden names in rasters?
    ns <- names(x)
    funs <- appFuns(FALSE)
    
    if (inherits(funs, "data.table")) {
        funs <- funs[["GRASS_Function"]]
    } else {
        funs$GRASS_Function
    }
    
    bads <- funs[funs %in% ns]

    if (length(bads) == 0L) {
        if (msgOnGood) {
            cat("Raster name(s) are likely acceptable.\n")
            utils::flush.console()
        }
    } else {

        realBads <- character()
        for (bad in bads) {
            if (grepl(fun, pattern = bad)) realBads <- c(realBads, bad)
        }

        if (length(realBads) > 0L) {
            
            msg <- "At least one raster has a forbidden name that seems to appear in the string."
            if (failOnBad) {
                stop(msg, "\n", realBads)
            } else {
                warning(msg)
                return(realBads)
            }
        } else if (msgOnGood) {
            msg <- "Rasters have one or more forbidden names, but they do not seem to appear in the string."
            warning(msg)
        }
    }

    invisible(bads)

    } # EOF
)

