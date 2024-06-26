#' General visualization parameters
#'
#' \pkg{scater} functions that plot points share a number of visualization parameters, which are described on this page.
#'
#' @section Aesthetic parameters:
#' \describe{
#' \item{\code{add_legend}:}{Logical scalar, specifying whether a legend should be shown.
#' Defaults to TRUE.}
#' \item{\code{theme_size}:}{Integer scalar, specifying the font size.
#' Defaults to 10.}
#' \item{\code{point_alpha}:}{Numeric scalar in [0, 1], specifying the transparency.
#' Defaults to 0.6.}
#' \item{\code{point_size}:}{Numeric scalar, specifying the size of the points.
#' Defaults to \code{NULL}.}
#' \item{\code{point_shape}:}{An integer, or a string specifying the shape
#' of the points. Details see \code{vignette("ggplot2-specs")}. Defaults to
#' \code{19}.}
#' \item{\code{jitter_type}:}{String to define how points are to be jittered in a violin plot.
#' This is either with random jitter on the x-axis (\code{"jitter"}) or in a \dQuote{beeswarm} style (if \code{"swarm"}, default).
#' The latter usually looks more attractive, but for datasets with a large number of cells, or for dense plots, the jitter option may work better.}
#' }
#'
#' @section Distributional calculations:
#' \describe{
#' \item{\code{show_median}:}{Logical, should the median of the distribution be shown for violin plots?
#' Defaults to \code{FALSE}.}
#' \item{\code{show_violin}:}{Logical, should the outline of a violin plot be shown?
#' Defaults to \code{TRUE}.}
#' \item{\code{show_smooth}:}{Logical, should a smoother be fitted to a scatter plot?
#' Defaults to \code{FALSE}.}
#' \item{\code{show_se}:}{Logical, should standard errors for the fitted line be shown on a scatter plot when \code{show_smooth=TRUE}?
#' Defaults to \code{TRUE}.}
#' \item{\code{show_boxplot}:}{Logical, should a box plot be shown? Defaults to \code{FALSE}.}
#' }
#'
#' @section Miscellaneous fields: Addititional fields can be added to the
#'   data.frame passed to \link{ggplot} by setting the \code{other_fields}
#'   argument. This allows users to easily incorporate additional metadata for
#'   use in further \pkg{ggplot} operations.
#'
#'   The \code{other_fields} argument should be character vector where each
#'   string is passed to \code{\link{retrieveCellInfo}} (for cell-based plots)
#'   or \code{\link{retrieveFeatureInfo}} (for feature-based plots).
#'   Alternatively, \code{other_fields} can be a named list where each element
#'   is of any type accepted by \code{\link{retrieveCellInfo}} or
#'   \code{\link{retrieveFeatureInfo}}. This includes \link{AsIs}-wrapped
#'   vectors, data.frames or \linkS4class{DataFrame}s.
#'
#'   Each additional column of the output data.frame will be named according to
#'   the \code{name} returned by \code{\link{retrieveCellInfo}} or
#'   \code{\link{retrieveFeatureInfo}}. If these clash with inbuilt names (e.g.,
#'   \code{X}, \code{Y}, \code{colour_by}), a warning will be raised and the
#'   additional column will not be added to avoid overwriting an existing
#'   column.
#'
#' @name scater-plot-args
#' @importFrom stats runif
#'
#' @seealso \code{\link{plotColData}}, \code{\link{plotRowData}},
#' \code{\link{plotReducedDim}}, \code{\link{plotExpression}},
#' \code{\link{plotPlatePosition}}, and most other plotting functions.
NULL

#' @importFrom ggbeeswarm geom_quasirandom
#' @importFrom ggplot2 ggplot geom_violin xlab ylab stat_summary geom_jitter
#'   position_jitter coord_flip geom_point stat_smooth geom_tile theme_bw theme
#'   geom_bin2d geom_hex stat_summary_2d stat_summary_hex geom_boxplot
.central_plotter <- function(object, xlab = NULL, ylab = NULL,
                             colour_by = NULL, shape_by = NULL, size_by = NULL, fill_by = NULL,
                             show_median = FALSE, show_violin = TRUE, show_smooth = FALSE, show_se = TRUE,
                             #  show_points = TRUE,
                             theme_size = 10, point_alpha = 0.6, point_size = NULL, point_shape = 19, add_legend = TRUE,
                             point_FUN = NULL, jitter_type = "swarm",
                             rasterise = FALSE, scattermore = FALSE, bins = NULL,
                             summary_fun = "sum", hex = FALSE, show_boxplot = FALSE)
# Internal ggplot-creating function to plot anything that involves points.
# Creates either a scatter plot, (horizontal) violin plots, or a rectangle plot.
{
    if (is.numeric(object$Y)!=is.numeric(object$X)) {
        ## Making a (horizontal) violin plot.
        flipped <- (is.numeric(object$X) && !is.numeric(object$Y))
        if (flipped) {
            tmp <- object$X
            object$X <- object$Y
            object$Y <- tmp
            tmp <- xlab
            xlab <- ylab
            ylab <- tmp
        }

        # Adding violins.
        plot_out <- ggplot(object, aes(x=.data$X, y=.data$Y)) +
            xlab(xlab) + ylab(ylab)
        if (show_violin) {
            if (is.null(fill_by)) {
                viol_args <- list(fill="grey90")
            } else {
                viol_args <- list(mapping=aes(fill=.data[[fill_by]]))
            }
            plot_out <- plot_out +
                do.call(
                    geom_violin,
                    c(viol_args, list(colour = "gray60", alpha = 0.2, scale = "width", width = 0.8))
                )
        }
        # Adding box plot
        if (show_boxplot) {
            if (is.null(fill_by)) {
                box_args <- list(fill="grey90")
            } else {
                box_args <- list(mapping=aes(fill=.data[[fill_by]]))
            }
            # If violin plot is plotted, make the width of box plot smaller to
            # improve readability.
            if (show_violin) {
                box_args[["width"]] <- 0.25
            }
            box_args <- c(box_args, list(colour = "black", alpha = 0.2))
            # If user wants that jitter plot is not added, add outliers.
            # Otherwise remove outliers since then they would be plotted twice;
            # once as outlier and once as part of jitter plot.
            if (!is.na(point_shape)) {
                box_args[["outlier.shape"]] <- NA
            }
            plot_out <- plot_out +
                do.call(geom_boxplot, box_args)
        }

        # Adding median, if requested.
        if (show_median) {
            plot_out <- plot_out +
                stat_summary(
                    fun = median, fun.min = median, fun.max = median,
                    geom = "crossbar", width = 0.3, alpha = 0.8
                )
        }

        # Adding points.
        point_out <- .get_point_args(
            colour_by, shape_by, size_by,
            alpha = point_alpha, size = point_size, shape = point_shape
        )
        if (is.null(point_FUN)) {
            if (jitter_type=="swarm") {
                point_FUN <- function(...) {
                    geom_quasirandom(..., width=0.4, bandwidth=1)
                }
            } else {
                point_FUN <- function(...) {
                    geom_jitter(..., position = position_jitter(height = 0))
                }
            }
        }
        plot_out <- plot_out + do.call(point_FUN, point_out$args)

        # Flipping.
        if (flipped) {
            plot_out <- plot_out + coord_flip()
        }
    } else if (is.numeric(object$Y) && is.numeric(object$X)) {
        # Creating a scatter plot.
        plot_out <- ggplot(object, aes(x=.data$X, y=.data$Y)) + xlab(xlab) + ylab(ylab)

        if (scattermore) {
            rasterise <- FALSE
            if (!is.null(shape_by) || !is.null(size_by)) {
                warning("shape_by and size_by do not work with scattermore.")
            }
        }
        if (!is.null(bins) && !is.null(colour_by) &&
            !is.numeric(object$colour_by)) {
            warning("Binning only applies to numeric colour_by or point counts")
            bins <- NULL
        }
        # Adding points.
        point_out <- .get_point_args(
            colour_by, shape_by, size_by,
            alpha = point_alpha, size = point_size, shape = point_shape,
            scattermore = scattermore, bins = bins, summary_fun = summary_fun
        )
        if (is.null(point_FUN)) {
            point_FUN <- .get_point_fun(scattermore = scattermore, bins = bins,
                                        colour_by = colour_by, hex = hex)
        }
        plot_out <- plot_out + do.call(point_FUN, point_out$args)

        # Adding smoothing, if requested.
        if (show_smooth) {
            plot_out <- plot_out +
                stat_smooth(colour = "firebrick", linetype = 2, se = show_se)
        }
    } else {
        # Creating a rectangle area plot.
        object$X <- as.factor(object$X)
        object$Y <- as.factor(object$Y)

        # Quantifying the frequency of each combination.
        summary.data <- as.data.frame(table(X=object$X, Y=object$Y))
        summary.data$RelativeProp <- summary.data$Freq / max(summary.data$Freq)

        # Defining the box boundaries (collapses to a mirrored bar plot if there is only one level).
        if (nlevels(object$Y)==1L && nlevels(object$X)!=1L) {
            summary.data$XWidth <- 0.4
            summary.data$YWidth <- 0.49 * summary.data$RelativeProp
        } else if (nlevels(object$Y)!=1L && nlevels(object$X)==1L) {
            summary.data$XWidth <- 0.49 * summary.data$RelativeProp
            summary.data$YWidth <- 0.4
        } else {
            summary.data$XWidth <- summary.data$YWidth <- 0.49 * sqrt(summary.data$RelativeProp)
        }

        # Adding manual jitter to each point in each combination of levels.
        object$Marker <- seq_len(nrow(object))
        combined <- merge(object, summary.data, by=c('X', 'Y'), all.x=TRUE)
        combined <- combined[order(combined$Marker),]
        object$Marker <- NULL
        object$X <- as.integer(object$X) + combined$XWidth*runif(nrow(object), -1, 1)
        object$Y <- as.integer(object$Y) + combined$YWidth*runif(nrow(object), -1, 1)

        # Creating the plot:
        plot_out <- ggplot(object, aes(x=.data$X, y=.data$Y)) + xlab(xlab) + ylab(ylab)
        plot_out <- plot_out +
            geom_tile(
                aes(
                    x = .data$X, y = .data$Y,
                    height = 2 * .data$YWidth, width = 2 * .data$XWidth
                ),
                data = summary.data, colour = 'grey60',
                linewidth = 0.5, fill = 'grey90'
            )

        # Adding points.
        point_out <- .get_point_args(
            colour_by, shape_by, size_by,
            alpha = point_alpha, size = point_size, shape = point_shape
        )
        if (is.null(point_FUN)) {
            point_FUN <- geom_point
        }
        plot_out <- plot_out + do.call(point_FUN, point_out$args)
    }

    # Adding colour.
    if (!is.null(colour_by) || !is.null(bins)) {
        if (!is.null(bins)) {
            if (is.null(colour_by)) colour_by <- "count"
            else if (is.character(summary_fun)) {
                colour_by <- paste0(summary_fun, "(", colour_by, ")")
            }
        }
        plot_out <- .resolve_plot_colours(
            plot_out, object$colour_by, colour_by, fill = !is.null(fill_by) || point_out$fill,
            colour = !is.null(colour_by), do_bin = !is.null(bins)
        )
    }

    ## Define plotting theme
    if (requireNamespace("cowplot", quietly = TRUE)) {
        plot_out <- plot_out + cowplot::theme_cowplot(theme_size)
    } else {
        plot_out <- plot_out + theme_bw(theme_size)
    }

    ## Setting the legend details.
    plot_out <- .add_extra_guide(plot_out, shape_by, size_by)
    if (!add_legend) {
        plot_out <- plot_out + theme(legend.position = "none")
    }
    if (rasterise) {
        plot_out <- ggrastr::rasterise(plot_out)
    }
    plot_out
}

#' @importFrom utils modifyList
.get_point_args <- function(colour_by, shape_by, size_by, alpha=0.65, size=NULL,
                            shape = NULL, scattermore = FALSE, bins = NULL,
                            summary_fun = sum)
## Note the use of colour instead of fill when shape_by is set, as not all shapes have fill.
{
    fill_colour <- FALSE
    ## used to be able to use aes_string but this is now duplicated
    ## adding a list to a ggplot adds all the list elements
    ## this means we need to be careful about what geoms inherit the global aes
    aes <- list()
    if (!is.null(bins)) {
        shape_by <- size_by <- size <- shape <- NULL
        fill_colour <- TRUE
    }
    if (!is.null(shape_by)) {
        aes <- modifyList(aes, aes(shape = shape_by))
        fill_colour <- FALSE
    }
    if (!is.null(colour_by)) {
        if (is.null(bins)) {
            if (fill_colour) {
                aes <- modifyList(aes, aes(fill = colour_by))
            } else {
                aes <- modifyList(aes, aes(colour = colour_by))
            }
        } else {
            aes <- modifyList(aes, aes(z = colour_by))
        }
    }
    if (!is.null(size_by)) {
        aes <- modifyList(aes, aes(size = size_by))
    }

    geom_args <- list(alpha=alpha)
    if (is.null(bins)) {
        if (is.null(colour_by) || fill_colour) {
            geom_args$colour <- "grey70"
        }
        if (is.null(colour_by) || !fill_colour) { # set fill when there is no fill colour, to distinguish between e.g., pch=16 and pch=21.
            geom_args$fill <- "grey20"
        }
        if (is.null(shape_by)) {
            geom_args$shape <- shape
        }
        if (is.null(size_by)) {
            if (scattermore) geom_args$pointsize <- size
            else geom_args$size <- size
        }
    } else {
        if (!is.null(colour_by)) {
            if (is.character(summary_fun)) summary_fun <- match.fun(summary_fun)
            geom_args$fun <- summary_fun
        }
        geom_args$bins <- bins
        geom_args$alpha <- NULL
    }

    class(aes) <- "uneval"
    return(list(aes = aes, args = c(geom_args, list(mapping = aes)), fill=fill_colour))
}

#' @importFrom ggplot2 guide_legend guides
.add_extra_guide <- function(plot_out, shape_by, size_by)
# Adding extra legend information on the shape and size.
{
    guide_args <- list()
    if (!is.null(shape_by)) {
        guide_args$shape <- guide_legend(title = shape_by)
    }
    if (!is.null(size_by)) {
        guide_args$size <- guide_legend(title = size_by)
    }
    if (length(guide_args)) {
        plot_out <- plot_out + do.call(guides, guide_args)
    }
    return(plot_out)
}

# Get function plotting points
.get_point_fun <- function(scattermore, bins, colour_by = NULL,
                           hex = FALSE) {
    if (!is.null(bins)) {
        if (is.null(colour_by))
            point_FUN <- if (hex) geom_hex else geom_bin2d
        else
            point_FUN <- if (hex) stat_summary_hex else stat_summary_2d
    } else if (scattermore) {
        rlang::check_installed("scattermore")
        point_FUN <- scattermore::geom_scattermore
    } else
        point_FUN <- geom_point
    point_FUN
}
