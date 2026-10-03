# Modified for the ncray modernization fork, 2026-10-03.
# Derived from ggsubplot by Garrett Grolemund and Hadley Wickham.
# GPL-2.0-or-later; see COPYING and ATTRIBUTION.md.
# Angle positions cover one cycle without duplicating the first ray at 2*pi.
glyph_angles <- function(x) {
  x <- numeric_major(x)
  values <- sort(unique(x[is.finite(x)]))
  if (!length(values)) return(rep(NA_real_, length(x)))
  step <- if (length(values) > 1L) min(diff(values)) else 1
  2 * pi * (x - min(values)) / (diff(range(values)) + step)
}

# Invisible corners train symmetric position ranges, keeping every glyph centred.
glyph_bounds <- function(data, radius, x = 0, y = 0) {
  bounds <- data[rep(1L, 4L), , drop = FALSE]
  bounds$x <- x + c(-1, -1, 1, 1) * radius
  bounds$y <- y + c(-1, 1, -1, 1) * radius
  data$.glyph_boundary <- FALSE
  bounds$.glyph_boundary <- TRUE
  rbind(data, bounds)
}

glyph_draw <- function(data, panel_params, coord) {
  if (".glyph_boundary" %in% names(data)) data <- data[!data$.glyph_boundary, , drop = FALSE]
  if (!nrow(data)) return(grid::nullGrob())
  ggplot2::GeomPolygon$draw_panel(data, panel_params, coord)
}

GeomStar <- ggplot2::ggproto("GeomStar", ggplot2::GeomPolygon,
  required_aes = c("x", "y", "r", "angle"),
  default_aes = ggplot2::aes(colour = "grey20", fill = NA, linewidth = .5,
    linetype = 1, alpha = NA, weight = 1),
  extra_params = c("na.rm", "r.zero"),
  setup_data = function(data, params) {
    theta <- glyph_angles(data$angle)
    r <- as.numeric(data$r)
    low <- if (isTRUE(params$r.zero)) 0 else min(r, na.rm = TRUE)
    high <- max(r, na.rm = TRUE)
    if (isTRUE(params$r.zero) && any(r < 0, na.rm = TRUE)) cli::cli_abort("Star radii must be non-negative when {.arg r.zero} is TRUE.")
    radius <- if (high == low) rep(1, length(r)) else (r - low) / (high - low)
    data$.glyph_theta <- theta
    data$.glyph_radius <- radius
    pieces <- split(seq_len(nrow(data)), interaction(data$PANEL, data$group, drop = TRUE))
    do.call(rbind, lapply(pieces, function(rows) {
      d <- data[rows, , drop = FALSE]
      d <- d[is.finite(d$.glyph_theta) & is.finite(d$.glyph_radius), , drop = FALSE]
      if (!nrow(d)) return(NULL)
      d <- d[order(d$.glyph_theta), , drop = FALSE]
      x <- d$x[1L]; y <- d$y[1L]
      d$x <- x + d$.glyph_radius * cos(d$.glyph_theta)
      d$y <- y + d$.glyph_radius * sin(d$.glyph_theta)
      glyph_bounds(d, max(d$.glyph_radius), x, y)
    }))
  },
  draw_panel = glyph_draw
)

GeomFreqstar <- ggplot2::ggproto("GeomFreqstar", GeomStar,
  required_aes = c("x", "y"),
  setup_data = function(data, params) {
    data$angle <- data$x
    data$r <- data$y
    data$x <- data$y <- 0
    params$r.zero <- TRUE
    GeomStar$setup_data(data, params)
  }
)

GeomCoxcomb <- ggplot2::ggproto("GeomCoxcomb", ggplot2::GeomPolygon,
  required_aes = c("x", "y"),
  default_aes = ggplot2::aes(colour = NA, fill = "grey20", linewidth = .5,
    linetype = 1, alpha = NA, weight = 1),
  extra_params = c("na.rm", "npoints"),
  setup_data = function(data, params) {
    if (any(data$y < 0, na.rm = TRUE)) cli::cli_abort("Coxcomb areas must be non-negative.")
    values <- sort(unique(data$x[is.finite(data$x)]))
    step <- if (length(values) > 1L) min(diff(values)) else 1
    span <- diff(range(values)) + step
    data$.theta_min <- 2 * pi * (data$x - min(values) - step/2) / span
    data$.theta_max <- data$.theta_min + 2 * pi * step / span
    pieces <- split(seq_len(nrow(data)), interaction(data$PANEL, data$x, drop = TRUE))
    polygons <- lapply(pieces, function(rows) {
      d <- data[rows, , drop = FALSE]
      d <- d[is.finite(d$y), , drop = FALSE]
      if (!nrow(d)) return(NULL)
      area <- c(0, cumsum(d$y))
      do.call(rbind, lapply(seq_len(nrow(d)), function(i) {
        theta <- seq(d$.theta_min[i], d$.theta_max[i], length.out = params$npoints)
        r <- c(rep(sqrt(area[i]), length(theta)), rep(sqrt(area[i+1L]), length(theta)))
        theta <- c(theta, rev(theta))
        wedge <- d[rep(i, length(theta)), , drop = FALSE]
        wedge$x <- r * cos(theta); wedge$y <- r * sin(theta)
        wedge$group <- rows[i]
        glyph_bounds(wedge, sqrt(area[i+1L]))
      }))
    })
    do.call(rbind, polygons)
  },
  draw_panel = glyph_draw
)

star_mapping <- function(mapping) {
  if (is.null(mapping)) mapping <- ggplot2::aes()
  if (is.null(mapping$angle) && !is.null(mapping$x)) {
    mapping$angle <- mapping$x; mapping$x <- NULL
  }
  if (is.null(mapping$r) && !is.null(mapping$y)) {
    mapping$r <- mapping$y; mapping$y <- NULL
  }
  if (is.null(mapping$x)) mapping$x <- 0
  if (is.null(mapping$y)) mapping$y <- 0
  if (is.null(mapping$group)) mapping$group <- 1
  mapping
}

polar_stat_mapping <- function(mapping) {
  if (is.null(mapping)) mapping <- ggplot2::aes()
  if (!is.null(mapping$angle)) {mapping$x <- mapping$angle; mapping$angle <- NULL}
  if (!is.null(mapping$r)) {mapping$y <- mapping$r; mapping$r <- NULL}
  mapping
}

#' Star glyphs
#'
#' Rays are placed around a full cycle in angle order, and radii are normalized
#' across the layer. Set `r.zero = FALSE` to subtract the minimum radius.
#' `angle` and `r` may also be supplied as `x` and `y`; with explicit `angle`
#' and `r`, optional `x` and `y` give the centre. Supply `group` for multiple
#' stars. A star uses the first row's fill and outline aesthetics.
#' @param mapping Aesthetic mapping created with [ggplot2::aes()].
#' @param data Optional layer data.
#' @param stat Statistical transformation.
#' @param position Position adjustment.
#' @param na.rm Remove missing values silently?
#' @param r.zero Should radius zero be the origin?
#' @param ... Parameters passed to [ggplot2::layer()].
#' @param inherit.aes Inherit the plot's aesthetics?
#' @param show.legend Include this layer in legends?
#' @return A ggplot2 layer.
#' @export
#' @examples
#' library(ggplot2)
#' d <- data.frame(a = 1:8, r = c(1, .4, .9, .5, 1, .5, .9, .4))
#' ggplot(d) + geom_star(aes(angle = a, r = r), fill = "skyblue") + coord_equal()
#' d <- subset(nasa, long > -100 & long < -90 & lat > 30 & lat < 40)
#' ggplot(d) + geom_subplot(aes(long, lat, group = id), width = 2, height = 2,
#'   subplot = geom_star(aes(angle = month, r = surftemp), r.zero = FALSE)) +
#'   coord_quickmap()
geom_star <- function(mapping = NULL, data = NULL, stat = "identity",
                      position = "identity", na.rm = FALSE, r.zero = TRUE,
                      ..., inherit.aes = TRUE, show.legend = NA) {
  ggplot2::layer(mapping = star_mapping(mapping), data = data, stat = stat,
    geom = GeomStar, position = position, inherit.aes = inherit.aes,
    show.legend = show.legend, params = c(list(na.rm = na.rm, r.zero = r.zero), list(...)))
}

#' Coxcomb glyphs
#'
#' Each angle receives a wedge whose area represents its count, or its `r`
#' value with `stat = "identity"`. Fill groups at the same angle are stacked
#' in area. Glyphs are centred at zero; embed them to place them on a map.
#' @inheritParams geom_star
#' @param npoints Number of points per arc, at least three.
#' @return A ggplot2 layer.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(casualties) + geom_coxcomb(aes(angle = month, fill = victim)) +
#'   coord_equal()
#' ggplot(subset(casualties, year == 2004)) +
#'   geom_subplot2d(aes(lon, lat), bins = 4,
#'     subplot = geom_coxcomb(aes(angle = month, fill = victim)),
#'     reference = NULL) + coord_quickmap()
geom_coxcomb <- function(mapping = NULL, data = NULL, stat = "count",
                        position = "identity", npoints = 20, na.rm = FALSE,
                        ..., inherit.aes = TRUE, show.legend = NA) {
  if (length(npoints) != 1L || !is.finite(npoints) || npoints < 3) cli::cli_abort("{.arg npoints} must be at least three.")
  ggplot2::layer(mapping = polar_stat_mapping(mapping), data = data, stat = stat,
    geom = GeomCoxcomb, position = position, inherit.aes = inherit.aes,
    show.legend = show.legend, params = c(list(na.rm = na.rm, npoints = as.integer(npoints)), list(...)))
}

#' Frequency star glyphs
#'
#' A star of angle frequencies, centred at zero. Use `stat = "bin"` with
#' numeric angles and an explicit `bins` or `binwidth` for histograms.
#' @inheritParams geom_star
#' @return A ggplot2 layer.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(casualties) + geom_freqstar(aes(angle = month), fill = "skyblue") +
#'   coord_equal()
#' ggplot(subset(casualties, year == 2004)) + geom_subplot2d(aes(lon, lat),
#'   bins = 4, subplot = geom_freqstar(aes(angle = month)), reference = NULL) +
#'   coord_quickmap()
geom_freqstar <- function(mapping = NULL, data = NULL, stat = "count",
                         position = "identity", na.rm = FALSE,
                         ..., inherit.aes = TRUE, show.legend = NA) {
  mapping <- polar_stat_mapping(mapping)
  if (is.null(mapping$group)) mapping$group <- 1
  ggplot2::layer(mapping = mapping, data = data, stat = stat,
    geom = GeomFreqstar, position = position, inherit.aes = inherit.aes,
    show.legend = show.legend, params = c(list(na.rm = na.rm, r.zero = TRUE), list(...)))
}
