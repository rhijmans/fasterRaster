#' @name madForest2014
#'
#' @title Forest cover in year 2014 for a portion of Madagascar
#'
#' @description Raster of occurrence/non-occurrence of forest cover in a portion of Madagascar. Cells are 30-m in resolution. Values represent forest (1) or non-forest (\code{NA}).
#'
#' @docType data
#'
#' @format An object of class \code{'SpatRaster'}. Values are forest (1) or not forest (\code{NA}).
#'
#' @keywords Madagascar
#'
#' @references Vielledent, G., Grinand, C., Rakotomala, F.A., Ranaivosoa, R., Rakotoarijaona, J-R., Allnutt, T.F., and Achard, F.  2018.  Combining global tree cover loss data with historical national forest cover maps to look at six decades of deforestation and forest fragmentation in Madagascar.  \emph{Biological Conservation} 222:189-197. \doi{10.1016/j.biocon.2018.04.008}.
#'
#' @examples
#'
#' library(terra)
#' rastFile <- system.file('extdata', 'madForest2014.tif', package='enmSdmX')
#' madForest2014 <- rast(rastFile)
#' plot(madForest2014)
#'
NULL
