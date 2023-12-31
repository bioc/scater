#' Cell-based data retrieval
#'
#' Retrieves a per-cell (meta)data field from a \linkS4class{SingleCellExperiment} based on a single keyword,
#' typically for use in visualization functions.
#'
#' @param x A \linkS4class{SingleCellExperiment} object.
#' @param by A string specifying the field to extract (see Details).
#' Alternatively, a data.frame, \linkS4class{DataFrame} or an \link{AsIs} vector.
#' @param search Character vector specifying the types of data or metadata to use.
#' @param assay.type String or integer scalar specifying the assay from which expression values should be extracted.
#' @param swap_rownames Column name of \code{rowData(object)} to be used to
#'  identify features instead of \code{rownames(object)} when labelling plot
#'  elements.
#' @param exprs_values Alias to \code{assay.type}.
#'
#' @return A list containing \code{name}, a string with the name of the extracted field (usually identically to \code{by});
#' and \code{value}, a vector of length equal to \code{ncol(x)} containing per-cell (meta)data values.
#' If \code{by=NULL}, both \code{name} and \code{value} are set to \code{NULL}.
#'
#' @details
#' Given an \link{AsIs}-wrapped vector in \code{by}, this function will directly return the vector values as \code{value},
#' while \code{name} is set to an empty string.
#' For data.frame or DataFrame instances with a single column,
#' this function will return the vector from that column as \code{value} and the column name as \code{name}.
#' This allows downstream visualization functions to accommodate arbitrary inputs for adjusting aesthetics.
#'
#' Given a character string in \code{by}, this function will:
#' \enumerate{
#' \item Search \code{\link{colData}} for a column named \code{by},
#' and return the corresponding field as the output \code{value}.
#' We do not consider nested elements within the \code{colData}.
#' \item Search \code{\link{assay}(x, assay.type)} for a row named \code{by},
#' and return the expression vector for this feature as the output \code{value}.
#' \item Search each alternative experiment in \code{\link{altExps}(x)} for a row names \code{by},
#' and return the expression vector for this feature at \code{assay.type} as the output \code{value}.
#' }
#' Any match will cause the function to return without considering later possibilities.
#' The search can be modified by changing the presence and ordering of elements in \code{search}.
#'
#' If there is a name clash that results in retrieval of an unintended field,
#' users should explicitly set \code{by} to a data.frame, DataFrame or AsIs-wrapped vector containing the desired values.
#' Developers can also consider setting \code{search} to control the fields that are returned.
#'
#' @author Aaron Lun
#' @seealso
#' \code{\link{makePerCellDF}}, which provides a more user-friendly interface to this function.
#'
#' \code{\link{plotColData}},
#' \code{\link{plotReducedDim}},
#' \code{\link{plotExpression}},
#' \code{\link{plotPlatePosition}},
#' and most other cell-based plotting functions.
#'
#' @examples
#' example_sce <- mockSCE()
#' example_sce <- logNormCounts(example_sce)
#'
#' retrieveCellInfo(example_sce, "Cell_Cycle")
#' retrieveCellInfo(example_sce, "Gene_0001")
#'
#' arbitrary.field <- rnorm(ncol(example_sce))
#' retrieveCellInfo(example_sce, I(arbitrary.field))
#' retrieveCellInfo(example_sce, data.frame(stuff=arbitrary.field))
#'
#' @export
#' @importFrom SingleCellExperiment altExp altExpNames
#' @importFrom SummarizedExperiment colData assay
retrieveCellInfo <- function(x, by, search = c("colData", "assays", "altExps"),
        exprs_values = "logcounts", swap_rownames = NULL, assay.type=exprs_values)
{
    .mopUp <- function(name, value) {
        list(name=name, value=value)
    }
    if (is.null(by)) {
        return(.mopUp(NULL, NULL))
    }
    if (is(by, "AsIs")) {
        if (length(by) != ncol(x)) {
            stop("length of 'AsIs' input should be equal to 'ncol(x)'")
        }
        if (is.factor(by)) {
            class(by) <- setdiff(class(by), "AsIs")
        } else {
            by <- as.vector(by)
        }
        return(.mopUp("", by))
    } else if (is.data.frame(by) || is(by, "DataFrame")) {
        if (ncol(by) != 1L) {
            stop("input data frame should only have one column")
        }
        if (nrow(by) != ncol(x)) {
            stop("number of rows of input data frame should be equal to 'ncol(x)'")
        }
        return(.mopUp(colnames(by)[1], by[,1]))
    }

    if (is.null(by)) {
        search <- character(0)
    } else if (!is.character(by) || length(by)>1L) {
        stop("invalid value for 'by'")
    } else {
        search <- match.arg(search, several.ok=TRUE)
    }

    for (s in search) {
        if (s=="colData") {
            cd <- colData(x)
            if (by %in% colnames(cd)) {
                return(.mopUp(by, cd[,by]))
            }
        } else if (s=="assays") {
            x <- .swap_rownames(x, swap_rownames)
            m <- match(by, rownames(x))
            if (!is.na(m)) {
                return(.mopUp(by, assay(x, assay.type, withDimnames = FALSE)[m, ]))
            }
        } else if (s=="altExps") {
            for (i in seq_along(altExpNames(x))) {
                current <- altExp(x, i)
                current <- .swap_rownames(current, swap_rownames)
                m <- match(by, rownames(current))
                if (!is.na(m)) {
                    return(.mopUp(by, assay(current, assay.type, withDimnames = FALSE)[m, ]))
                }
            }
        }
    }

    stop(sprintf("cannot find '%s'", by))
}

.coerce_to_factor <- function(x, level.limit, msg) {
    if (!is.null(x)) {
        x <- as.factor(x)
        if (nlevels(x) > level.limit) {
            stop(sprintf("more than %i levels for '%s'", level.limit, msg))
        }
    }
    x
}

