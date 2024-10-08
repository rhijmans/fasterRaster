#' Open the help page for a GRASS module
#'
#' @description This function opens the manual page for a **GRASS** module (function) in your browser.
#'
#' @param x Character: Any of:
#' * The name of a **GRASS** module (e.g., `"r.mapcalc"`).
#' * `"type"`: Display a page wherein modules are classified by types.
#' * `"topics"`: Display an index of topics.
#'
#' @param online If `FALSE` (default), show the manual page that is included with your installation of **GRASS**.  If `FALSE`, show the manual page online (requires an Internet connection).
#'
#' @returns Nothing (opens a web page).
#'
#' @example man/examples/ex_grassHelp.r
#'
#' @aliases grassHelp
#' @rdname grassHelp
#' @export
grassHelp <- function(x, online = FALSE) {

	x <- tolower(x)
	if (length(x) != 1L) stop("Only one help page can be opened at a time.")
	
	args <- list(
		cmd = "g.manual",
		flags = .quiet()
	)
	
	if (x == "type") {
		args$flags <- c(args$flags, "i")
	} else if (x == "index") {
		args$flags <- c(args$flags, "t")
	}

	do.call(rgrass::execGRASS, args = args)

}
