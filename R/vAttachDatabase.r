#' Add a database table to a GRASS attribute table
#'
#' @description `.vAttachDatabase()` adds a table to a **GRASS** vector. This table is meant to be "invisible" to most users--they should use interact with attribute tables using the `GVector` slot `@table`. Some functions require tables (e.g., [extract()] and [spatSample()]). **This function is mostly of use to developers.**
#'
#' @param x A `GVector` or the name of a vector in **GRASS**.
#' 
#' @param table Either `NULL` (default), or a `data.frame` or `data.table`, or a numeric or integer vector:
#' * If `NULL`, then a bare minimal table will be created with a column named `cat`, holding sequential integer values.
#' * If a `data.frame` or `data.table` and no column is named `cat`, one will be created with sequential integer values. If the table does have a column named `cat`, then it should have integer (not just numeric) values.
#' * If a `vector`, then these are coerced to type `integer` and used to define the `cat` column.
#'
#' There should be one row/value per geometry in `x`.
#'
#' @param replace Logical: If `TRUE`, replace the existing database connection.
#'
#' @param cats Either `NULL` (default), or an integer vector: This is provided as a means to save time by passing `cats` to this function if it has already been generated by a calling function.
#' 
#' @returns Invisibly returns the [sources()] name of a vector in **GRASS**.
#' 
#' @aliases .vAttachDatabase
#' @rdname vAttachDatabase
#' @keywords internal
.vAttachDatabase <- function(x, table = NULL, replace = TRUE, cats = NULL) {

	if (inherits(x, "GVector")) {
		.locationRestore(x)
		src <- sources(x)
	} else {
		src <- x
	}

	if (replace || !.vHasDatabase(src)) {

		# if no table
		if (is.null(table)) {
			if (is.null(cats)) cats <- .vCats(src, db = FALSE, integer = TRUE)
			table <- data.frame(cat = cats)
		}

		# if table is a vector
		if (inherits(table, c("numeric", "integer"))) {
			table <- as.integer(table)
			table <- data.frame(cat = table)
		}

		# if table does not have a "cat" column
		if (!any(names(table) %in% "cat")) {
		
			if (is.null(cats)) cats <- .vCats(src, db = FALSE, integer = TRUE)
			catsRenum <- omnibus::renumSeq(cats)
			table <- table[catsRenum, , drop = FALSE]
			cats <- data.frame(cat = cats)
			table <- cbind(cats, table)
		
		}

		# columns <- names(table)
		# classes <- sapply(table, "class")
		# for (i in seq_len(ncol(table))) {

		# 	if (classes[i] == "integer") {
		# 		columns[i] <- paste0(columns[i], " INTEGER")
		# 	} else if (classes[i] == "numeric") {
		# 		columns[i] <- paste0(columns[i], " DOUBLE PRECISION")
		# 	} else {
		# 		nc <- nchar(table[ , i])
		# 		nc <- max(nc)
		# 		columns[i] <- paste0(columns[i], " VARCHAR(", nc, ")")
		# 	}

		# }

		# save table to disk
		tf <- tempfile(fileext = ".csv")
		tft <- paste0(tf, "t")
		utils::write.csv(table, tf, row.names = FALSE)
		
		classes <- sapply(table, class)
		classes[!(classes %in% c("numeric", "integer", "character", "Date"))] <- '"String"'
		classes[classes == "numeric"] <- '"Real"'
		classes[classes == "integer"] <- '"Integer"'
		classes[classes == "character"] <- '"String"'
		classes[classes == "Date"] <- '"Date"'
		classes <- paste(classes, collapse = ",")
		
		write(classes, tft)

		# import table as database
		srcTable <- .makeSourceName("db_in_ogr_table", NULL)
		rgrass::execGRASS(
			cmd = "db.in.ogr",
			input = tf,
			output = srcTable,
			# key = "cat", # error
			flags = c(.quiet(), "overwrite")
		)

		# disconnect existing table
		if (.vHasDatabase(src)) {
		
			rgrass::execGRASS(
				cmd = "v.db.droptable",
				map = src,
				flags = c(.quiet(), "f")
			)
		
		}

		# connect database to vector
		args <- list(
			cmd = "v.db.connect",
			map = sources(x),
			table = srcTable,
			layer = "1",
			# key = "frid",
			key = "cat_", # adds an underscore, for some reason
			# flags = c(.quiet(), "overwrite", "o")
			flags = c(.quiet(), "overwrite")
		)

		if (grassInfo("versionNumber") <= 8.3) args$flags <- c(arges$flags, "o")

		do.call(rgrass::execGRASS, args = args)

		# args <- list(
		# 	cmd = "v.db.addtable",
		# 	map = src,
		# 	columns = columns,
		# 	flags = .quiet(),
		# 	intern = TRUE
		# )

		# info <- do.call(rgrass::execGRASS, args = args)

	}
	invisible(x)

}
