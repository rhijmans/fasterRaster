#' @name fasterOptions
#'
#' @title Set \code{GRASS} options for all fasterRaster functions
#' 
#' @description You can specify default settings for most \pkg{fasterRaster} functions using the \code{options} function:
#' \itemize{
#' 	\item The \code{grassDir} argument: Most \pkg{fasterRaster} functions use an argument named "\code{grassDir}" for specifying where \code{GRASS} is installed. However, defining this argument every time can be cumbersome if you are using a lot of \code{fasterRaster} functions. Instead, you can define \code{grassDir} just once using \code{\link{options}}, and subsequent calls to \pkg{fasterRaster} functions will automatically use the directory defined there. To set the \code{grassDir} argument for all \pkg{fasterRaster} functions at once, simply do this: \cr
#' 
#' \code{grassDir <- 'C:/Program Files/GRASS GIS 8.2' # example path for Windows} \cr
#' \code{grassDir <- "/Applications/GRASS-8.2.app/Contents/Resources" # example path for a Mac} \cr
#' \code{grassDir <- '/usr/local/grass' # Linux... maybe} \cr
#'
#' \code{options(grassDir = grassDir)} \cr
#'
#' To remove the \code{GRASS} path, simply set the option to \code{NULL}: \cr
#'
#' \code{options(grassDir = NULL)} \cr
#'
#' \item Default class of spatial vector outputs: Some \code{fasterRaster} functions output spatial vectors. By default, these will be \code{SpatVectors} (from the \pkg{terra} package), but if you want them to be \code{sf} objects (from the pkg{sf} package), you can cause all such functions to return these objects using: \cr
#' 
#' \code{options(grassVectOut = 'sf')} \cr
#'
#' To revert the setting, simply set the option to \code{NULL} or any other value: \cr
#'
#' \code{options(grassVectOut = NULL)} \cr
#'
#' }
#'
#' @keywords options
#'
NULL
