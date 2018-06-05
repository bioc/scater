#' Count the number of non-zero counts per cell or feature 
#'
#' @description An efficient internal function that counts the number of non-zero counts in each row (per feature) or column (per cell).
#' This avoids the need to construct an intermediate logical matrix.
#'
#' @param object A SingleCellExperiment object or a numeric matrix of expression values.
#' @param detection_limit Numeric scalar providing the value above which  observations are deemed to be expressed. 
#' @param exprs_values String or integer specifying the assay of \code{object} to obtain the count matrix from, if \code{object} is a SingleCellExperiment.
#' @param byrow Logical scalar indicating whether to count the number of detected cells per feature.
#' If \code{FALSE}, the function will count the number of detected features per cell.
#' @param subset_row Logical, integer or character vector indicating which rows (i.e. features) to use.
#' @param subset_col Logical, integer or character vector indicating which columns (i.e., cells) to use.
#'
#' @details 
#' Setting \code{subset_row} or \code{subset_col} is equivalent to subsetting \code{object} before calling \code{nexprs}, 
#' but more efficient as a new copy of the matrix is not constructed. 
#'
#' @return An integer vector containing counts per gene or cell, depending on the provided arguments.
#'
#' @export
#' @examples
#' data("sc_example_counts")
#' data("sc_example_cell_info")
#' example_sce <- SingleCellExperiment(
#'     assays = list(counts = sc_example_counts), 
#'     colData = sc_example_cell_info)
#'
#' nexprs(example_sce)[1:10]
#' nexprs(example_sce, byrow = TRUE)[1:10]
#'
#' @importClassesFrom SingleCellExperiment SingleCellExperiment
#' @importFrom SummarizedExperiment assay
#' @importFrom methods is
nexprs <- function(object, detection_limit = 0, exprs_values = "counts", 
                   byrow = FALSE, subset_row = NULL, subset_col = NULL) {
    if (is(object, "SingleCellExperiment")) { 
        exprs_mat <- assay(object, i = exprs_values)
    } else {
        exprs_mat <- object
    }
    subset_row <- .subset2index(subset_row, target = exprs_mat, byrow = TRUE)
    subset_col <- .subset2index(subset_col, target = exprs_mat, byrow = FALSE)

    if (!byrow) {
        return(.colAbove(exprs_mat, rows=subset_row, cols=subset_col, value=detection_limit))
    } else {
        return(.rowAbove(exprs_mat, rows=subset_row, cols=subset_col, value=detection_limit))
    }
}