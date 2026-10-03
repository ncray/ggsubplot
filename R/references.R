# Modified for the ncray modernization fork, 2026-10-03.
# Derived from ggsubplot by Garrett Grolemund and Hadley Wickham.
# GPL-2.0-or-later; see COPYING and ATTRIBUTION.md.
add_reference <- function(layer, reference) {
  if (is.null(reference)) return(layer)
  if (!is.function(reference)) cli::cli_abort("{.arg reference} must be a reference factory, such as {.fn ref_box}.")
  ref <- clone_layer(layer)
  ref$minor_layer <- reference()
  ref$geom <- ref$minor_layer$geom
  ref$show.legend <- ref$minor_layer$show.legend
  ref$is_reference <- TRUE
  list(ref, layer)
}

reference_rect <- function(mapping, bounds, fill, color, ...) {
  if (is.null(mapping)) mapping <- ggplot2::aes()
  defaults <- do.call(ggplot2::aes, bounds)
  for (aes in setdiff(names(defaults), names(mapping))) mapping[[aes]] <- defaults[[aes]]
  params <- list(...)
  if (is.null(mapping$fill)) params$fill <- fill
  if (is.null(mapping$colour)) params$colour <- color
  do.call(ggplot2::geom_rect, c(list(mapping = mapping, show.legend = FALSE), params))
}

#' Subplot reference boxes and lines
#'
#' Reference coordinates are expressed in the minor range `[-1, 1]`.
#' Reference factories are passed to `reference` in [geom_subplot()] or
#' [geom_subplot2d()]. Each produces one rectangle per occupied subplot.
#' @param mapping Reference aesthetic mapping.
#' @param fill,color Fixed fill and outline colours.
#' @param ... Additional parameters to [ggplot2::geom_rect()].
#' @return A function creating a minor reference layer.
#' @export
#' @examples
#' library(ggplot2)
#' d <- data.frame(X = rep(1:2, each = 3), a = rep(1:3, 2), b = 1:6)
#' ggplot(d) + geom_subplot(aes(X, 0, group = X), width = .8, height = 1,
#'   subplot = geom_point(aes(a, b)), reference = ref_box())
#' ref_hline()
#' ref_vline()
ref_box <- function(mapping = NULL, fill = "grey90", color = "white", ...) {
  force(mapping); force(fill); force(color); params <- list(...)
  function() do.call(reference_rect, c(list(mapping = mapping,
    bounds = list(xmin = -1, xmax = 1, ymin = -1, ymax = 1), fill = fill, color = color), params))
}

#' @rdname ref_box
#' @param thickness Line thickness in minor coordinate units (full box spans 2).
#' @export
ref_hline <- function(mapping = NULL, thickness = .2, fill = "white", ...) {
  if (length(thickness) != 1L || !is.finite(thickness) || thickness <= 0) cli::cli_abort("{.arg thickness} must be positive.")
  force(mapping); force(thickness); force(fill); params <- list(...)
  function() do.call(reference_rect, c(list(mapping = mapping,
    bounds = list(xmin = -1, xmax = 1, ymin = -thickness/2, ymax = thickness/2),
    fill = fill, color = NA), params))
}

#' @rdname ref_box
#' @export
ref_vline <- function(mapping = NULL, thickness = .2, fill = "white", ...) {
  if (length(thickness) != 1L || !is.finite(thickness) || thickness <= 0) cli::cli_abort("{.arg thickness} must be positive.")
  force(mapping); force(thickness); force(fill); params <- list(...)
  function() do.call(reference_rect, c(list(mapping = mapping,
    bounds = list(xmin = -thickness/2, xmax = thickness/2, ymin = -1, ymax = 1),
    fill = fill, color = NA), params))
}
