#' Perform MDS on cell-level data
#'
#' Perform multi-dimensional scaling (MDS) on cells, based on the data in a SingleCellExperiment object.
#'
#' @param x For \code{calculateMDS}, a numeric matrix of log-expression values
#' where rows are features and columns are cells.
#' Alternatively, a \linkS4class{SummarizedExperiment} or \linkS4class{SingleCellExperiment} containing such a matrix.
#'
#' For \code{runMDS}, a \linkS4class{SingleCellExperiment} object.
#' @param ncomponents Numeric scalar indicating the number of MDS?g dimensions
#' to obtain.
#' @inheritParams runPCA
#' @param ... For the \code{calculateMDS} generic, additional arguments to pass 
#' to specific methods. For the SummarizedExperiment and SingleCellExperiment 
#' methods, additional arguments to pass to the ANY method.
#'
#' For \code{runMDS}, additional arguments to pass to \code{calculateMDS}.
#' @param FUN A function that accepts a numeric matrix as its first argument,
#' where rows are samples and columns are features; and returns a distance 
#' structure such as that returned by \code{dist} or a full symmetric matrix 
#' containing the dissimilarities.
#' @param keep_dist Logical scalar indicating whether the \code{dist} object 
#' calculated by \code{FUN} should be stored as \sQuote{dist} attribute of the 
#' matrix returned/stored by \code{calculateMDS} or \code{runMDS}.
#'
#' @return
#' For \code{calculateMDS}, a matrix is returned containing the MDS coordinates
#' for each cell (row) and dimension (column).
#'
#' For \code{runMDS}, a modified \code{x} is returned that contains the MDS 
#' coordinates in \code{\link{reducedDim}(x, name)}.
#'
#' @inheritSection calculatePCA Feature selection
#' @inheritSection calculatePCA Using reduced dimensions
#' @inheritSection calculatePCA Using alternative Experiments
#'
#' @details
#' The function \code{\link{cmdscale}} is used internally to compute the MDS 
#' components with \code{eig = TRUE}.
#' The \code{eig} and \code{GOF} fields of the object returned by 
#' \code{\link{cmdscale}} are stored as attributes \dQuote{eig} and \dQuote{GOF}
#' of the MDS matrix calculated.
#'
#' @name runMDS
#' @seealso
#' \code{\link{cmdscale}}, to perform the underlying calculations.
#'
#' \code{\link{dist}} for the function used as default to calculate the 
#' \code{dist} object.
#'
#' \code{\link[scater]{plotMDS}}, to quickly visualize the results.
#'
#' @author Aaron Lun, based on code by Davis McCarthy
#'
#' @examples
#' example_sce <- mockSCE()
#' example_sce <- logNormCounts(example_sce)
#'
#' example_sce <- runMDS(example_sce)
#' reducedDimNames(example_sce)
#' head(reducedDim(example_sce))
NULL

#' @importFrom stats cmdscale dist
.calculate_mds <- function(x, FUN = dist, ncomponents = 2,
    ntop = 500, subset_row = NULL, scale = FALSE, transposed = FALSE,
    keep_dist = FALSE, ...)
{
    if (!is.logical(keep_dist) || length(keep_dist) != 1L) {
        stop("'keep_dist' must be TRUE or FALSE.", call. = FALSE)
    }
    if (!transposed) {
        x <- .get_mat_for_reddim(x, subset_row=subset_row, ntop=ntop, scale=scale)
    }
    x <- as.matrix(x)
    cell_dist <- do.call(FUN, c(list(x), list(...)))
    mds <- cmdscale(cell_dist, k = ncomponents, eig = TRUE)
    ans <- mds$points
    attr(ans, "eig") <- mds$eig
    attr(ans, "GOF") <- mds$GOF
    if (keep_dist) {
        attr(ans, "dist") <- cell_dist
    }
    ans
}

#' @export
#' @rdname runMDS
setMethod("calculateMDS", "ANY", .calculate_mds)

#' @export
#' @rdname runMDS
#' @importFrom SummarizedExperiment assay
setMethod("calculateMDS", "SummarizedExperiment", function(x, ..., exprs_values="logcounts", assay.type=exprs_values) {
    .calculate_mds(assay(x, assay.type), ...)
})

#' @export
#' @rdname runMDS
#' @importFrom SummarizedExperiment assay
setMethod("calculateMDS", "SingleCellExperiment", function(x, ..., exprs_values="logcounts", dimred=NULL, n_dimred=NULL, assay.type=exprs_values)
{
    mat <- .get_mat_from_sce(x, assay.type=assay.type, dimred=dimred, n_dimred=n_dimred)
    .calculate_mds(mat, transposed=!is.null(dimred), ...)
})

#' @export
#' @rdname runMDS
#' @importFrom SingleCellExperiment reducedDim<- altExp
runMDS <- function(x, ..., altexp=NULL, name="MDS") {
    if (!is.null(altexp)) {
        y <- altExp(x, altexp)
    } else {
        y <- x
    }
    reducedDim(x, name) <- calculateMDS(y, ...)
    x
}
