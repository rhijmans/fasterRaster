#' Solar radiance and irradiance
#'
#' The `sun()` function calculates beam (direct), diffuse and ground reflected solar irradiation for a given day and set of topographic and atmospheric conditions. The function relies on the **GRASS** module `r.sun`, which contains a detailed explanation.
#'
#' @param elevation A `GRaster` with values representing elevation (typically in meters).
#'
#' @param coeff_bh A `GRaster`: A raster with values of the real-sky beam radiation coefficient. Valid values are between 0 and 1.
#'
#' @param coeff_dh A `GRaster`: A raster with values of the real-sky diffuse radiation coefficient. Valid values are between 0 and 1.
#'
#' @param slope A `GRaster`: This is a raster representing topographic slope in radians. It can be generated using [terrain()].
#'
#' @param aspect A `GRaster`: This is a raster representing topographic aspect in degrees. It can be generated using [terrain()]. If generated with that function, "east orientation" *must* be used (i.e., argument `northIs0` must be `FALSE`).
#'
#' @param hh A "stack" of `GRaster`s: This represents height of the horizon in radians in particular directions. Horizon height can be calculated using [horizonHeight()]. The directions *must* be in "east orientation" (i.e., argument `northIs0` in `horzionHeight()` must be `FALSE`). The directions must correspond with the sequence given by `horizon_step` (see next argument). For example, if `horizon_step` is 90, then `hh` must contain rasters representing horizon height at 0 (east), 90 (north), 180 (west), and 270 (south) aspects.
#'#' 
#' @param horizon_step Numeric >0: Difference between angular steps in which horizon height is measured. One horizon height raster will be made per value from 0 to 360 - `horizon_step` degrees.
#'
#' @param albedo A `GRaster` or a numeric value: This is either a raster with values of ground albedo or a numeric value (in which case albedo is assumed to be the same everywhere). Albedo is unit-less, and the default value is 0.2.
#'
#' @param linke A `GRaster` or a numeric value: This is either a raster with values of the Linke atmospheric turbidity coefficient or a numeric value (in which case the same value is assumed for all locations). The Linke coefficient is unit-less. The default value is 3, but see also the **GRASS** manual page for module `r.sun`.
#'
#' @param day Positive integer between 1 to 365, inclusive: Day of year for which to calculate ir/radiation. Default is 1 (January 1st).
#'
#' @param step Positive integer between 0 and 24, inclusive. Time step in hours for all-day radiation sums. Decimal values are OK.
#'
#' @param declination Numeric or `NULL` (default). Declination value. If `NULL`, this is calculated automatically.
#'
#' @param solar_constant Positive numeric: The solar constant (solar energy hitting the top of the atmosphere). Default is 1367. Units are W / m^2.
#'
#' @param distance_step Positive numeric between 0.5 and 1.5, inclusive: Sampling distance coefficient. Default is 1.
#'
#' @param npartitions Positive numeric. Number of chunks in which to read input files. Default is 1.
#'
#' @param beam_rad Logical: If `TRUE` (default), generate a raster with beam irradiation with units of Wh / m^2 / day ("mode 2" of the `r.sun` **GRASS** module).
#'
#' @param diff_rad Logical: If `TRUE` (default), generate a raster representing irradiation in Wh / m^2 /day
#'
#' @param refl_rad Logical: If `TRUE` (default), generate a raster with ground-reflected irradiation with units of Wh / m^2 / day ("mode 2" of the `r.sun` **GRASS** module).
#'
#' @param glob_rad Logical:. If `TRUE` (default), generate a raster with total irradiance/irradiation with units of Wh / m^2 / day ("mode 2" of the `r.sun` **GRASS** module).
#'
#' @param insol_time Logical: If `TRUE` (default), generate a raster with total insolation time in hours ("mode 2" of the `r.sun` **GRASS** module).
#'
#' @returns A raster or raster stack stack with the same extent, resolution, and coordinate reference system as `elevation`. Assuming all possible rasters are generated they represent:
#' * `beam_rad`: Beam radiation (Watt-hours/m2/day)
#' * `diff_rad`: Diffuse radiation (Watt-hours/m2/day)
#' * `refl_rad`: Reflected radiation (Watt-hours/m2/day)
#' * `glob_rad`: Global radiation (Watt-hours/m2/day)
#' * `insol_time`: Insolation duration (hours)
#' 
#' @seealso Module `r.sun` in **GRASS**
#'
#' @example man/examples/ex_sun.r
#'
#' @export
sun <- function(
		elevation,
		coeff_bh,
		coeff_dh,

		slope,
		aspect,

		hh,
		horizon_step = 90,
		
		albedo = 0.2,
		linke = 3,

		day = 1,
		step = 0.5,
		declination = NULL,
		solar_constant = 1367,
		
		distance_step = 1,
		npartitions = 1,

		beam_rad = TRUE,
		diff_rad = TRUE,
		refl_rad = TRUE,
		glob_rad = TRUE,
		insol_time = TRUE
		
	) {

	if (!beam_rad & !diff_rad & !refl_rad & !glob_rad & !insol_time) stop('No output requested.')

	compareGeom(elevation, coeff_bh, coeff_dh, slope, aspect, hh)
	
	.restore(elevation)
	region(elevation)

	hhGn <- .gnames(hh)[1L]
	directions <- seq(0, 359.9999999, by=horizon_step)
	hhGn <- gsub(hhGn, pattern=paste0('_', sprintf('%03.0f', directions[1L])), replacement='')
		
	args <- list(
		cmd = 'r.sun',
		flags = c('quiet', 'overwrite'),
		day = day,
		step = step,
		nprocs = getFastOptions('cores'),
		distance_step = distance_step,
		npartitions = npartitions,
		elevation = .gnames(elevation),
		coeff_bh = .gnames(coeff_bh),
		coeff_dh = .gnames(coeff_dh),
		slope = .gnames(slope),
		aspect = .gnames(aspect),
		horizon_basename = hhGn,
		horizon_step = horizon_step
	)

	if (!is.null(declination)) args <- c(args, declination = declination)

	# albedo
	if (inherits(albedo, 'GRaster')) { # raster
		compareGeom(elevation, albedo)
		args <- c(args, albedo=.gnames(albedo))
	} else {
		args <- c(args, albedo_value=albedo)
	}
	
	# linke
	if (inherits(linke, 'GRaster')) { # raster
		compareGeom(elevation, linke)
		args <- c(args, linke=.gnames(linke))
	} else {
		args <- c(args, linke_value=linke)
	}

	# output names
	if (beam_rad) args <- c(args, beam_rad = .makeGName('beam_rad', 'rast'))
	if (diff_rad) args <- c(args, diff_rad = .makeGName('diff_rad', 'rast'))
	if (refl_rad) args <- c(args, refl_rad = .makeGName('refl_rad', 'rast'))
	if (glob_rad) args <- c(args, glob_rad = .makeGName('glob_rad', 'rast'))
	if (insol_time) args <- c(args, insol_time = .makeGName('insol_time', 'rast'))

	# execute!
	do.call(rgrass::execGRASS, args=args)

	out <- elevation
	
	if (beam_rad) {
		this <- .makeGRaster(args$beam_rad, 'beam_rad')
		out <- c(out, this)
	}
	
	if (diff_rad) {
		this <- .makeGRaster(args$diff_rad, 'diff_rad')
		out <- c(out, this)
	}
	
	if (refl_rad) {
		this <- .makeGRaster(args$refl_rad, 'refl_rad')
		out <- c(out, this)
	}
	
	if (glob_rad) {
		this <- .makeGRaster(args$glob_rad, 'glob_rad')
		out <- c(out, this)
	}
	
	if (insol_time) {
		this <- .makeGRaster(args$insol_time, 'insol_time')
		out <- c(out, this)
	}
	
	n <- nlyr(out)
	out <- out[[2L:n]]
	out

} # EOF
