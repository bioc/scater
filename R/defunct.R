#' Defunct functions
#'
#' Functions that have passed on to the function afterlife.
#' Their successors are also listed.
#'
#' @param object,x,... Ignored arguments.
#'
#' @details
#' \code{calculateQCMetrics} is succeeded by \code{\link{perCellQCMetrics}} and \code{\link{perFeatureQCMetrics}}.
#'
#' \code{normalize} is succeeded by \code{\link{logNormCounts}}.
#'
#' \code{centreSizeFactors} has no replacement - the \pkg{SingleCellExperiment} is removing support for multiple size factors, so this function is now trivial.
#' 
#' \code{runDiffusionMap} and \code{calculateDiffusionMap} have no replacement.
#' \pkg{destiny} is no longer on Bioconductor. You can calculate a diffusion map
#' yourself, and add it to a \code{reducedDim} field, if you so wish.
#'
#' @return All functions error out with a defunct message pointing towards its descendent (if available).
#'
#' @author Aaron Lun
#'
#' @examples
#' try(calculateQCMetrics())
#' @name defunct
NULL

#' @export
#' @rdname defunct
calculateQCMetrics <- function(...) {
    .Defunct("perCellQCMetrics")
}

#' @export
#' @importFrom BiocGenerics normalize
#' @rdname defunct
setMethod("normalize", "SingleCellExperiment", function(object, ...) {
    .Defunct("'normalize,SingleCellExperiment-method' is defunct.\nUse 'logNormCounts' instead")
})

#' @export
#' @rdname defunct
centreSizeFactors <- function(...) {
    .Defunct()
}

#' @export
#' @rdname defunct
setGeneric("calculateDiffusionMap", function(x, ...) {
    standardGeneric("calculateDiffusionMap")
})

#' @export
#' @rdname defunct
setMethod("calculateDiffusionMap", "ANY", function(x, ...) {
    .Defunct()
})

#' @export
#' @rdname defunct
#' @importFrom SingleCellExperiment reducedDim<-
runDiffusionMap <- function(...) {
    .Defunct()
}

#' @export
#' @rdname defunct
multiplot <- function(...) {
    .Defunct("scater::multiplot is defunct.\nUse 'gridExtra::grid.arrange' instead")
}
