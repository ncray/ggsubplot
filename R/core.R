# Modified for the ncray modernization fork, 2026-10-03.
# Derived from ggsubplot by Garrett Grolemund and Hadley Wickham.
# GPL-2.0-or-later; see COPYING and ATTRIBUTION.md.
.Layer <- ggplot2::geom_blank()$super()

.x_aes <- c("x", "xmin", "xmax", "xend", "xintercept")
.y_aes <- c("y", "ymin", "ymax", "yend", "yintercept")

clone_layer <- function(layer) ggplot2::ggproto(NULL, layer)

# Evaluate a mapping with ggplot2's scalar recycling rules.
eval_mapping <- function(expr, data) {
  vctrs::vec_recycle(rlang::eval_tidy(expr, data), nrow(data))
}

numeric_major <- function(x) {
  if (is.factor(x)) return(as.numeric(x))
  if (is.character(x)) return(as.numeric(factor(x)))
  as.numeric(x)
}

subplot_size <- function(size, values) {
  if (inherits(size, "rel")) {
    u <- sort(unique(values[is.finite(values)]))
    spacing <- if (length(u) > 1L) min(diff(u)) else 1
    size <- as.numeric(size) * spacing
  }
  if (length(size) != 1L || !is.finite(size) || size <= 0) {
    cli::cli_abort("Subplot width and height must be positive finite numbers or {.fn ggplot2::rel} values.")
  }
  as.numeric(size)
}

assign_subplots <- function(self, data) {
  mapping <- self$computed_mapping
  required <- c("x", "y", "group")
  missing <- setdiff(required, names(mapping))
  if (length(missing)) cli::cli_abort("Missing major aesthetic{?s}: {.field {missing}}.")
  g <- eval_mapping(mapping$group, data)
  ids <- as.integer(factor(g))
  x <- y <- rep(NA_real_, nrow(data))
  for (i in unique(ids[!is.na(ids)])) {
    rows <- which(ids == i)
    x[rows] <- numeric_major(eval_mapping(mapping$x, data[rows, , drop = FALSE]))
    y[rows] <- numeric_major(eval_mapping(mapping$y, data[rows, , drop = FALSE]))
  }
  # Discrete majors need a common set of levels, rather than one per group.
  for (axis in c("x", "y")) {
    value <- rlang::eval_tidy(mapping[[axis]], data)
    if (is.factor(value) || is.character(value)) {
      if (axis == "x") x <- vctrs::vec_recycle(numeric_major(value), nrow(data))
      else y <- vctrs::vec_recycle(numeric_major(value), nrow(data))
    }
  }
  keep <- !is.na(ids) & is.finite(x) & is.finite(y)
  data <- data[keep, , drop = FALSE]
  ids <- ids[keep]; x <- x[keep]; y <- y[keep]
  globals <- unique(data.frame(SUBPLOT = ids, x = x, y = y))
  if (anyDuplicated(globals$SUBPLOT)) {
    cli::cli_abort("Each major group must have one x and y location; use {.code mean(x)} and {.code mean(y)} for varying locations.")
  }
  globals$width <- rep(subplot_size(self$subplot_width, x), nrow(globals))
  globals$height <- rep(subplot_size(self$subplot_height, y), nrow(globals))
  data$SUBPLOT <- ids
  list(data = data, globals = globals)
}

minor_scale_mode <- function(x, y) {
  is_free <- function(z) identical(z, free) || identical(z, "free")
  if (!(identical(x, identity) || identical(x, "fixed") || is_free(x)) ||
      !(identical(y, identity) || identical(y, "fixed") || is_free(y))) {
    cli::cli_abort("Minor scales must be {.fn identity} (fixed) or {.fn free}.")
  }
  if (is_free(x) && is_free(y)) "free"
  else if (is_free(x)) "free_x"
  else if (is_free(y)) "free_y"
  else "fixed"
}

LayerSubplot <- ggplot2::ggproto("LayerSubplot", .Layer,
  compute_aesthetics = function(self, data, plot) {
    if (!inherits(plot$facet, "FacetNull")) cli::cli_abort("Outer facetting is not supported by subplot layers.")
    if (!nrow(data)) return(data.frame())
    assigned <- if (is.null(self$grid_options)) assign_subplots(self, data) else assign_grid(self, data)
    if (self$subplot_position == "merge") assigned <- merge_assignment(assigned)
    data <- assigned$data
    globals <- assigned$globals
    if (!nrow(data)) return(data.frame())
    original_mapping <- self$minor_layer$mapping
    minor <- capture_layer(self$minor_layer)
    minor$data <- ggplot2::waiver()
    minor$inherit.aes <- FALSE
    # Position constants must participate in the inner scale training too.
    fixed_positions <- intersect(names(minor$aes_params), c(.x_aes, .y_aes, "group"))
    for (aes in fixed_positions) minor$mapping[[aes]] <- rlang::new_quosure(minor$aes_params[[aes]], rlang::base_env())
    minor$aes_params[fixed_positions] <- NULL
    prepared <- prepare_ply(minor$mapping, data, data$SUBPLOT, self$ply.aes)
    data <- prepared$data; minor$mapping <- prepared$mapping
    if (isTRUE(self$is_reference)) {
      data <- data[!duplicated(data$SUBPLOT), , drop = FALSE]
      minor$mapping$group <- rlang::new_quosure(quote(SUBPLOT), rlang::base_env())
    }
    inner <- ggplot2::ggplot(data) + minor +
      ggplot2::facet_wrap(~SUBPLOT, scales = minor_scale_mode(self$minor_scales$x, self$minor_scales$y))
    for (scale in plot$scales$non_position_scales()$scales) inner <- inner + scale$clone()
    built <- ggplot2::ggplot_build(inner)
    out <- built$data[[1L]]
    inner_layer <- built$plot$layers[[1L]]
    self$computed_geom_params <- inner_layer$computed_geom_params
    self$aes_params <- self$minor_layer$aes_params[setdiff(names(self$minor_layer$aes_params), c(.x_aes, .y_aes, "group"))]
    self$outer_scales <- plot$scales
    for (scale in built$plot$scales$non_position_scales()$scales) {
      existing <- plot$scales$get_scales(scale$aesthetics[1L])
      if (is.null(existing)) {
        existing <- scale$clone()
        plot$scales$add(existing)
      }
      values <- scale$range$range
      if (inherits(scale, "ScaleDiscrete") && isTRUE(scale$range$factor)) {
        values <- factor(values, levels = values)
      }
      existing$train(values)
      aes <- scale$aesthetics[1L]
      if (inherits(existing$name, "waiver") && aes %in% names(original_mapping)) {
        existing$name <- if (!is.null(plot$labels[[aes]])) plot$labels[[aes]] else rlang::as_label(original_mapping[[aes]])
      }
      if (inherits(existing, "ScaleDiscrete")) {
        existing$palette.cache <- NULL
        existing$n.breaks.cache <- NULL
      }
    }
    for (aes in names(inner_layer$raw_aesthetics)) {
      value <- inner_layer$raw_aesthetics[[aes]]
      if (!inherits(value, "AsIs")) out[[paste0(".subplot_raw_", aes)]] <- I(value)
    }
    panel <- built$layout$layout
    ids <- as.integer(as.character(panel$SUBPLOT))[match(as.integer(out$PANEL), as.integer(panel$PANEL))]
    centers <- globals[match(ids, globals$SUBPLOT), , drop = FALSE]
    for (axis in c("x", "y")) {
      cols <- intersect(if (axis == "x") .x_aes else .y_aes, names(out))
      size <- if (axis == "x") centers$width else centers$height
      for (p in unique(as.integer(out$PANEL))) {
        rows <- which(as.integer(out$PANEL) == p)
        limits <- built$layout$panel_params[[p]][[paste0(axis, ".range")]]
        for (col in cols) {
          v <- as.numeric(out[[col]][rows])
          v <- if (isTRUE(self$is_reference)) v else if (diff(limits) == 0) rep(0, length(v)) else 2 * (v - limits[1]) / diff(limits) - 1
          out[[col]][rows] <- centers[[axis]][rows] + v * size[rows] / 2
        }
      }
    }
    out$SUBPLOT <- ids
    out$group <- as.integer(interaction(ids, out$group, drop = TRUE))
    out$PANEL <- rep(data$PANEL[1L], nrow(out))
    for (col in setdiff(names(out), c(.x_aes, .y_aes, "PANEL", "group", "SUBPLOT"))) out[[col]] <- I(out[[col]])
    self$computed_mapping <- self$mapping
    for (aes in setdiff(names(original_mapping), c(.x_aes, .y_aes, "group"))) self$computed_mapping[[aes]] <- original_mapping[[aes]]
    out
  },
  compute_statistic = function(data, layout) data,
  map_statistic = function(data, plot) data,
  compute_geom_1 = function(data) data,
  compute_position = function(data, layout) data,
  compute_geom_2 = function(self, data, params = self$aes_params, ...) {
    # Guides call this method on key data as well as on the layer data.
    if (!"PANEL" %in% names(data)) {
      return(subplot_defaults(self, data, params, ...))
    }
    for (col in names(data)[startsWith(names(data), ".subplot_raw_")]) {
      aes <- substring(col, nchar(".subplot_raw_") + 1L)
      scale <- self$outer_scales$get_scales(aes)
      if (!is.null(scale)) data[[aes]] <- I(scale$map(remove_asis(data[[col]])))
      data[[col]] <- NULL
    }
    # Re-evaluate after_scale against the final shared outer palette.
    subplot_defaults(self, data, params, ...)
  },
  finish_statistics = function(data) data
)

#' Embed a ggplot2 layer at grouped locations
#'
#' A subplot is an ordinary ggplot2 layer. Major x and y give its centre and
#' group identifies its rows. Minor positions are scaled into its box.
#' Outer facets are unsupported. Discrete major coordinates become numeric
#' positions. Use numeric major coordinates with continuous outer scales.
#' @param mapping Major aesthetics, created with [ggplot2::aes()].
#' @param width,height Box size in major units, or [ggplot2::rel()] times the
#'   smallest spacing between centres (one unit for a single centre).
#' @param data Layer data; defaults to the plot data.
#' @param x_scale,y_scale `identity` for shared minor limits, or [free] for
#'   limits computed separately for each subplot.
#' @param position Subplot adjustment: `"identity"` or `"merge"`.
#' @param reference A reference factory such as [ref_box()], or `NULL`.
#' @param ply.aes `TRUE` evaluates minor aesthetics within each subplot;
#'   `FALSE` evaluates them on all rows; a character vector selects which
#'   aesthetics to evaluate within subplots. Staged aesthetics are left to ggplot2.
#' @param subplot A single ggplot2 layer. May alternatively be supplied as the
#'   `subplot` aesthetic in `mapping`.
#' @return A ggplot2 layer, or a list of reference and subplot layers.
#' @export
#' @examples
#' library(ggplot2)
#' d <- subset(nasa, id %in% c("synthetic-06-05", "synthetic-07-05", "synthetic-08-05"))
#' ggplot(d) + geom_subplot(aes(long, lat, group = id),
#'   subplot = geom_point(aes(day, surftemp)), width = 2, height = 2)
geom_subplot <- function(mapping = NULL, width = ggplot2::rel(0.95),
                         height = ggplot2::rel(0.95), data = NULL,
                         x_scale = identity, y_scale = identity,
                         position = "identity", reference = NULL,
                         ply.aes = TRUE, subplot = NULL) {
  if (is.null(mapping)) mapping <- ggplot2::aes()
  if (!is.null(mapping$subplot)) {
    if (!is.null(subplot)) cli::cli_abort("Supply {.arg subplot} only once.")
    subplot <- rlang::eval_tidy(mapping$subplot)
    mapping$subplot <- NULL
  }
  if (!inherits(subplot, "LayerInstance")) cli::cli_abort("{.arg subplot} must be a single ggplot2 layer.")
  if (inherits(subplot, "LayerSubplot")) cli::cli_abort("A subplot cannot contain another subplot.")
  if (!position %in% c("identity", "merge")) cli::cli_abort("Unsupported subplot position: {.val {position}}.")
  minor_scale_mode(x_scale, y_scale)
  layer <- ggplot2::layer(geom = subplot$geom, stat = "identity", position = "identity",
                         mapping = mapping, data = data, check.aes = FALSE,
                         layer_class = LayerSubplot, show.legend = subplot$show.legend)
  layer$minor_layer <- subplot
  layer$subplot_width <- width; layer$subplot_height <- height
  layer$minor_scales <- list(x = x_scale, y = y_scale)
  layer$ply.aes <- ply.aes
  layer$subplot_position <- position
  add_reference(layer, reference)
}

#' Deprecated plot identity function
#' @param plot A ggplot2 plot.
#' @return The input plot, unchanged, with a deprecation warning.
#' @export
#' @examples
#' suppressWarnings(ggsubplot(ggplot2::ggplot()))
ggsubplot <- function(plot) {
  cli::cli_warn("{.fn ggsubplot} is deprecated; subplot layers now work in ordinary ggplot2 plots.")
  plot
}

# ggplot2 4.0 added parameters/theme to this extension method.
subplot_defaults <- function(self, data, params, ...) {
  parent <- ggplot2::ggproto_parent(.Layer, self)
  if (utils::packageVersion("ggplot2") >= "4.0.0") parent$compute_geom_2(data, params, ...)
  else parent$compute_geom_2(data)
}

remove_asis <- function(x) {
  cls <- setdiff(class(x), "AsIs")
  class(x) <- if (length(cls)) cls else NULL
  x
}
