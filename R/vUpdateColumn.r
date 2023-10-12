#' Change values in a column
#'
#' @description This function changes the values in a column of an attribute table of a **GRASS** vector to be the same value.
#' 
#' @param x A `GVector` or the [sources()] name of a **GRASS** vector.
#' 
#' @param column Character: Name of the column.
#' 
#' @param value Numeric, integer, or character: The value to be assigned to all cells in the column.
#' 
#' @returns `TRUE` (invisibly), and changes column values.
#' 
#' @aliases .vUpdateColumn
#' @rdname vUpdateColumn
#' @noRd
.vUpdateColumn <- function(x, column, value) {

	if (inherits(x, "GVector")) {
		.restore(x)
		src <- sources(x)
	} else {
		src <- x
	}

	if (!(column %in% .vNames(x))) stop("Column does not exist in this vector.")

	args <- list(
		cmd = "v.db.update",
		map = x,
		column = column,
		value = value,
		flags = "quiet"
	)

	do.call(rgrass::execGRASS, args = args)

	invisible(TRUE)

}
