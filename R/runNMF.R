#' Perform NMF on cell-level data
#'
#' Perform non-negative matrix factorization (NMF) for the cells, based on the data in a SingleCellExperiment object.
#'
#' @param x For \code{calculateNMF}, a numeric matrix of log-expression values where rows are features and columns are cells.
#' Alternatively, a \linkS4class{SummarizedExperiment} or \linkS4class{SingleCellExperiment} containing such a matrix.
#'
#' For \code{runNMF}, a \linkS4class{SingleCellExperiment} object.
#' @param ncomponents Numeric scalar indicating the number of NMF dimensions to obtain.
#' @inheritParams runPCA
#' @param seed Random number generation seed to be passed to \code{\link[RcppML]{nmf}}.
#' @param ... For the \code{calculateNMF} generic, additional arguments to pass to specific methods.
#' For the ANY method, additional arguments to pass to \code{\link[Rtsne]{Rtsne}}.
#' For the SummarizedExperiment and SingleCellExperiment methods, additional arguments to pass to the ANY method.
#'
#' For \code{runNMF}, additional arguments to pass to \code{calculateNMF}.
#'
#' @inheritSection calculatePCA Feature selection
#' @inheritSection calculatePCA Using reduced dimensions
#' @inheritSection calculatePCA Using alternative Experiments
#' @return 
#' For \code{calculateNMF}, a numeric matrix is returned containing the NMF coordinates for each cell (row) and dimension (column).
#' 
#' For \code{runNMF}, a modified \code{x} is returned that contains the NMF coordinates in \code{\link{reducedDim}(x, name)}.
#'
#' In both cases, the matrix will have the attribute \code{"basis"} containing the gene-by-factor basis matrix.
#'
#' @details 
#' The function \code{\link[RcppML]{nmf}} is used internally to compute the NMF. 
#' Note that the algorithm is not deterministic, so different runs of the function will produce differing results. 
#' Users are advised to test multiple random seeds, and then use \code{\link{set.seed}} to set a random seed for replicable results. 
#'
#'
#' @name runNMF
#' @seealso 
#' \code{\link[RcppML]{nmf}}, for the underlying calculations.
#' 
#' \code{\link{plotNMF}}, to quickly visualize the results.
#'
#' @author Aaron Lun
#'
#' @examples
#' example_sce <- mockSCE()
#' example_sce <- logNormCounts(example_sce)
#'
#' example_sce <- runNMF(example_sce)
#' reducedDimNames(example_sce)
#' head(reducedDim(example_sce))
NULL

#' @importFrom BiocNeighbors KmknnParam findKNN
#' @importFrom BiocParallel SerialParam
.calculate_nmf <- function(x, ncomponents = 2, ntop = 500,
    subset_row = NULL, scale=FALSE, transposed=FALSE, seed=1, ...)
{ 
    if (!transposed) {
        x <- .get_mat_for_reddim(x, subset_row=subset_row, ntop=ntop, scale=scale) 
    }
    x <- t(as.matrix(x))

    args <- list(k=ncomponents, verbose=FALSE, seed=seed, ...)
    nmf_out <- do.call(RcppML::nmf, c(list(x), args))

    # RcppML doesn't use transposed data
    nmf_x <- t(nmf_out$h)
    rownames(nmf_x) <- colnames(x)
    colnames(nmf_x) <- paste0("NMF", seq_len(ncol(nmf_x)))
    nmf_basis <- nmf_out$w
    rownames(nmf_basis) <- rownames(x)
    colnames(nmf_basis) <- paste0("NMF", seq_len(ncol(nmf_basis)))
    attr(nmf_x, "basis") <- nmf_basis

    nmf_x
}

#' @export
#' @rdname runNMF
setMethod("calculateNMF", "ANY", .calculate_nmf)

#' @export
#' @rdname runNMF
#' @importFrom SummarizedExperiment assay
setMethod("calculateNMF", "SummarizedExperiment", function(x, ..., exprs_values="logcounts", assay.type=exprs_values) {
    .calculate_nmf(assay(x, assay.type), ...)
})

#' @export
#' @rdname runNMF
setMethod("calculateNMF", "SingleCellExperiment",
    function(x, ..., exprs_values="logcounts", dimred=NULL, n_dimred=NULL, assay.type=exprs_values) {
    mat <- .get_mat_from_sce(x, assay.type=assay.type, dimred=dimred, n_dimred=n_dimred)
    .calculate_nmf(mat, transposed=!is.null(dimred), ...)
})

#' @export
#' @rdname runNMF
#' @importFrom SingleCellExperiment reducedDim<- 
runNMF <- function(x, ..., altexp=NULL, name="NMF") {
    if (!is.null(altexp)) {
        y <- altExp(x, altexp)
    } else {
        y <- x
    }
    reducedDim(x, name) <- calculateNMF(y, ...)
    x
}
