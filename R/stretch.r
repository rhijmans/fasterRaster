#' Rescale values in a raster
#' 
#' @description `stretch()` rescales the values in a `GRaster`. All values can be rescaled, or just values in a user-defined range. This range can be given by specifying either the lower and upper bounds of the range using `smin` and `smax`, and/or by the quantiles (across all cells of the raster) using `minq` and `maxq`.
#' 
#' @param x A `GRaster`.
#' @param minv,maxv Numeric: Minumum and maximum values to which to rescale values.
#' @param minq,maxq Numeric: Specifies range of values to rescale, given by their quantiles. The default is to stretch all values (the 0th and 100th quantiles). One or both are  ignored if `smin` and/or `smax` are provided.
#' @param smin,smax Numeric: Specifies range of values to rescale.
#' 
#' @returns A `GRaster`.
#' 
#' @seealso [terra::stretch()] and module `r.rescale` in **GRASS** (not used on this function)
#' 
#' @example man/example/ex_stretch.r
#' 
#' @aliases stretch
#' @rdname stretch
#' @exportMethod stretch
methods::setMethod(
    f = 'stretch',
    signature = c(x = 'GRaster'),
    definition = function(
        x,
        minv = 0, maxv = 255,
        minq = 0, maxq = 1,
        smin = NA, smax = NA
    ) {

    if (is.na(minv)) stop('Invalid lower bound to which to stretch.')
    if (is.na(maxv)) stop('Invalid upper bound to which to stretch.')

    if (is.na(minq) & is.na(smin)) stop('Invalid lower bound of range to stretch.')
    if (!is.na(minq) && minq < 0) stop('Invalid lower bound of range to stretch.')

    if (is.na(maxq) & is.na(smax)) stop('Invalid upper bound of range to stretch.')
    if (!is.na(maxq) && maxq > 1) stop('Invalid upper bound of range to stretch.')

    .restore(x)
    region(x)

    for (i in 1L:nlyr(x)) {

        ### lower "from" bound
        if (!is.na(smin)) {
            lowerFrom <- smin
        } else {
            
            if (minq == 0) {
                lowerFrom <- minmax(x)[1L, i]
            } else {

                # get lower quantile
                args <- list(
                    cmd = 'r.univar',
                    flags = c('quiet', 'r', 'e'),
                    map = gnames(x)[i],
                    Sys_show.output.on.console = FALSE,
                    echoCmd = FALSE,
                    intern = TRUE,
                    percentile = minq * 100
                )

                info <- do.call(rgrass::execGRASS, args)
                pattern <- 'percentile: '
                lowerFrom <- info[grepl(info, pattern=pattern)]
                lowerFrom <- strsplit(lowerFrom, split=':')[[1L]][2L]
                lowerFrom <- as.numeric(lowerFrom)

            } # if calculating quantile
        } # if calculating lower quantile

        ### upper "from" bound
        if (!is.na(smax)) {
            upperFrom <- smax
        } else {
            
            if (maxq == 1) {
                upperFrom <- minmax(x)[2L, i]
            } else {

                # get lower quantile
                args <- list(
                    cmd = 'r.univar',
                    flags = c('quiet', 'r', 'e'),
                    map = gnames(x)[i],
                    Sys_show.output.on.console = FALSE,
                    echoCmd = FALSE,
                    intern = TRUE,
                    percentile = maxq * 100
                )

                info <- do.call(rgrass::execGRASS, args)
                pattern <- 'percentile: '
                upperFrom <- info[grepl(info, pattern=pattern)]
                upperFrom <- strsplit(upperFrom, split=':')[[1L]][2L]
                upperFrom <- as.numeric(upperFrom)

            } # if calculating quantile
        } # if calculating upper quantile

        ### truncate values at min/max
        if (minmax(x[[i]])[1L, i] < lowerFrom | minmax(x[[i]])[2L, i] > upperFrom) {

            gnTrunc <- .makeGname('truncated', 'rast')
            ex <- paste0(gnTrunc, ' = if(', gnames(x)[i], ' < ', lowerFrom, ', ', lowerFrom, ', if(', gnames(x)[i], ' > ', upperFrom, ', ', upperFrom, ', ', gnames(x)[i], '))')

            args <- list(
                cmd = 'r.mapcalc',
                expression = ex,
                flags = c('quiet', 'overwrite'),
                intern = TRUE
            )

            do.call(rgrass::execGRASS, args=args)

        } else {
            gnTrunc <- gnames(x)[i]
        }

        gn <- .makeGname(names(x)[i], 'rast')
        scale <- (maxv - minv) / (upperFrom - lowerFrom)
        ex <- paste0(gn, ' = ', minv, ' + (', scale, ' * (', gnTrunc, ' - ', lowerFrom, '))')
        
        args <- list(
            cmd = 'r.mapcalc',
            expression = ex,
            flags = c('quiet', 'overwrite'),
            intern = TRUE
        )

        do.call(rgrass::execGRASS, args=args)

        this <- makeGRaster(gn, names(x)[i])
        if (i == 1L) {
            out <- this
        } else {
            out <- c(out, this)
        }

    } # next layer
    out

    } # EOF
)
