# Modified for the ncray modernization fork, 2026-10-03.
# Derived from ggsubplot by Garrett Grolemund and Hadley Wickham.
# GPL-2.0-or-later; see COPYING and ATTRIBUTION.md.
#' Pick breaks for interval bins
#' @param bins Positive number of bins.
#' @param binwidth Positive bin width, overriding `bins`.
#' @param origin Optional starting break. Bins extend in both directions to
#'   cover the range.
#' @param range Optional finite numeric range, overriding the data range.
#' @return A function accepting a numeric vector and returning bin breaks.
#' @export
#' @examples
#' interval_breaks(bins = 4)(1:9)
interval_breaks <- function(bins = 10, binwidth = NULL, origin = NULL, range = NULL) {
  if (length(bins) != 1L || !is.finite(bins) || bins < 1 || bins != as.integer(bins)) cli::cli_abort("{.arg bins} must be a positive integer.")
  if (!is.null(binwidth) && (length(binwidth) != 1L || !is.finite(binwidth) || binwidth <= 0)) cli::cli_abort("{.arg binwidth} must be positive and finite.")
  function(x) {
    rng <- if (is.null(range)) base::range(x, finite = TRUE) else sort(range)
    if (length(rng) != 2L || any(!is.finite(rng))) cli::cli_abort("Cannot bin an empty or non-finite range.")
    if (diff(rng) == 0) return(rng[1] + c(-.5, .5) * if (is.null(binwidth)) 1 else binwidth)
    if (is.null(binwidth) && is.null(origin)) return(seq(rng[1], rng[2], length.out = bins + 1L))
    step <- if (is.null(binwidth)) diff(rng) / bins else binwidth
    start <- if (is.null(origin)) floor(rng[1] / step) * step else origin + floor((rng[1] - origin) / step) * step
    seq(start, start + ceiling((rng[2] - start) / step) * step, by = step)
  }
}

grid_breaks <- function(bins, binwidth, breaks) {
  if (!is.null(breaks)) {
    if (is.list(breaks)) {
      if (length(breaks) != 2L) cli::cli_abort("{.arg breaks} must contain x and y breaks.")
      return(unname(breaks))
    }
    return(list(breaks, breaks))
  }
  if (!length(bins) %in% 1:2 || (!is.null(binwidth) && !length(binwidth) %in% 1:2)) cli::cli_abort("{.arg bins} and {.arg binwidth} must have length one or two.")
  bins <- rep(bins, length.out = 2)
  lapply(1:2, function(i) interval_breaks(bins[i], if (is.null(binwidth)) NULL else rep(binwidth, length.out = 2)[i]))
}

assign_grid <- function(self, data) {
  m <- self$computed_mapping
  missing <- setdiff(c("x", "y"), names(m))
  if (length(missing)) cli::cli_abort("Missing major aesthetic{?s}: {.field {missing}}.")
  xy <- lapply(m[c("x", "y")], eval_mapping, data = data)
  centers <- sizes <- indices <- vector("list", 2L)
  for (i in 1:2) {
    values <- numeric_major(xy[[i]])
    b <- self$grid_options$breaks[[i]]
    if (is.function(b)) b <- b(values)
    if (length(b) < 2L || any(!is.finite(b)) || any(diff(b) <= 0)) cli::cli_abort("Grid breaks must be strictly increasing finite numbers.")
    index <- cut(values, b, include.lowest = TRUE, labels = FALSE)
    indices[[i]] <- index
    centers[[i]] <- ((b[-length(b)] + b[-1L]) / 2)[index]
    sizes[[i]] <- diff(b)[index] * self$grid_options$adjust[i]
  }
  ids <- as.integer(interaction(indices[[1]], indices[[2]], drop = TRUE))
  keep <- !is.na(ids)
  data <- data[keep, , drop = FALSE]
  data$SUBPLOT <- ids[keep]
  globals <- unique(data.frame(SUBPLOT = ids[keep], x = centers[[1]][keep],
    y = centers[[2]][keep], width = sizes[[1]][keep], height = sizes[[2]][keep]))
  list(data = data, globals = globals)
}

# Connected components, including transitive overlaps, with unequal grid cells.
merge_overlaps <- function(globals) {
  n <- nrow(globals)
  ids <- seq_len(n)
  for (i in seq_len(n)) {
    neighbors <- which(abs(globals$x - globals$x[i]) < (globals$width + globals$width[i]) / 2 &
      abs(globals$y - globals$y[i]) < (globals$height + globals$height[i]) / 2)
    components <- unique(ids[neighbors])
    ids[ids %in% components] <- min(components)
  }
  as.integer(factor(ids))
}

merge_assignment <- function(assigned) {
  g <- assigned$globals
  if (!nrow(g)) return(assigned)
  ids <- merge_overlaps(g)
  assigned$data$SUBPLOT <- ids[match(assigned$data$SUBPLOT, g$SUBPLOT)]
  assigned$globals <- do.call(rbind, lapply(unique(ids), function(i) {
    rows <- g[ids == i, , drop = FALSE]
    data.frame(SUBPLOT = i, x = mean(rows$x), y = mean(rows$y),
      width = max(rows$width), height = max(rows$height))
  }))
  assigned
}

#' Embed subplots in a two-dimensional grid
#' @inheritParams geom_subplot
#' @param bins Number of bins, one number or an x/y pair.
#' @param binwidth Bin widths, one number or an x/y pair, overriding `bins`.
#' @param breaks Break vector or function, or a list of two such objects for
#'   x and y. Overrides `bins` and `binwidth`. Bins use [cut()] with
#'   `include.lowest = TRUE`; out-of-range and missing rows are omitted.
#' @param width.adjust,height.adjust Positive proportions of each cell's
#'   width and height occupied by the subplot.
#' @return A ggplot2 layer or a list of reference and subplot layers.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(subset(casualties, year == 2004)) +
#'   geom_subplot2d(aes(lon, lat), bins = c(5, 5),
#'     subplot = geom_bar(aes(victim, fill = victim))) + coord_quickmap()
geom_subplot2d <- function(mapping = NULL, bins = 10, binwidth = NULL,
                           breaks = NULL, data = NULL, x_scale = identity,
                           y_scale = identity, width.adjust = .95,
                           height.adjust = .95, position = "identity",
                           reference = ref_box(), ply.aes = TRUE, subplot = NULL) {
  adjust <- c(width.adjust, height.adjust)
  if (length(adjust) != 2L || any(!is.finite(adjust)) || any(adjust <= 0)) cli::cli_abort("Grid size adjustments must be positive and finite.")
  layer <- geom_subplot(mapping, data = data, x_scale = x_scale, y_scale = y_scale,
    position = position, ply.aes = ply.aes, subplot = subplot)
  layer$grid_options <- list(breaks = grid_breaks(bins, binwidth, breaks), adjust = adjust)
  add_reference(layer, reference)
}
