# Modified for the ncray modernization fork, 2026-10-03.
# Derived from ggsubplot by Garrett Grolemund and Hadley Wickham.
# GPL-2.0-or-later; see COPYING and ATTRIBUTION.md.
# Staged expressions belong to ggplot2, rather than the per-group evaluator.
is_staged <- function(expr) {
  any(all.names(rlang::get_expr(expr)) %in% c("after_stat", "after_scale", "stage", "from_theme"))
}

prepare_ply <- function(mapping, data, groups, selected = TRUE) {
  if (!(is.logical(selected) && length(selected) == 1L && !is.na(selected)) && !is.character(selected)) cli::cli_abort("{.arg ply.aes} must be TRUE, FALSE, or aesthetic names.")
  for (aes in names(mapping)) {
    if (is_staged(mapping[[aes]])) next
    plied <- isTRUE(selected) || (is.character(selected) && aes %in% selected)
    expr <- mapping[[aes]]
    if (plied) {
      pieces <- lapply(split(seq_len(nrow(data)), groups), function(rows) {
        value <- eval_mapping(expr, data[rows, , drop = FALSE])
        list(rows = rows, value = value)
      })
      if (!length(pieces)) next
      prototype <- do.call(vctrs::vec_ptype_common, lapply(pieces, `[[`, "value"))
      value <- vctrs::vec_init(prototype, nrow(data))
      for (piece in pieces) value <- vctrs::vec_assign(value, piece$rows, piece$value)
    } else value <- eval_mapping(expr, data)
    col <- paste0(".ggsubplot_", aes)
    while (col %in% names(data)) col <- paste0(col, "_")
    data[[col]] <- value
    mapping[[aes]] <- rlang::new_quosure(rlang::sym(col), rlang::base_env())
  }
  list(data = data, mapping = mapping)
}

LayerPly <- ggplot2::ggproto("LayerPly", .Layer,
  compute_aesthetics = function(self, data, plot) {
    mapping <- self$computed_mapping
    vars <- self$ply_vars
    if (is.null(vars)) {
      if (is.null(mapping$group)) cli::cli_abort("{.fn ply_aes} needs a group aesthetic or {.arg .vars}.")
      groups <- interaction(data$PANEL, eval_mapping(mapping$group, data), drop = TRUE)
    } else {
      if (!all(vars %in% names(data))) cli::cli_abort("Unknown grouping column{?s}: {.field {setdiff(vars, names(data))}}.")
      groups <- do.call(interaction, c(data[c("PANEL", vars)], list(drop = TRUE)))
    }
    prepared <- prepare_ply(mapping, data, groups)
    self$computed_mapping <- prepared$mapping
    out <- ggplot2::ggproto_parent(.Layer, self)$compute_aesthetics(prepared$data, plot)
    self$computed_mapping <- mapping
    out
  }
)

#' Evaluate ordinary layer aesthetics within groups
#' @param layer A ggplot2 layer, or a list of layers.
#' @param .vars Character vector of data columns defining the groups. Defaults
#'   to the layer's `group` aesthetic. Outer panels are always kept separate.
#' @return A ggplot2 layer or list of layers.
#' @export
#' @examples
#' library(ggplot2)
#' ggplot(mtcars) + ply_aes(geom_point(aes(wt, mpg, group = cyl,
#'   colour = mean(mpg))))
ply_aes <- function(layer, .vars = NULL) {
  if (is.list(layer) && !inherits(layer, "LayerInstance")) return(lapply(layer, ply_aes, .vars = .vars))
  if (!inherits(layer, "LayerInstance") || inherits(layer, "LayerSubplot")) cli::cli_abort("{.arg layer} must be an ordinary ggplot2 layer.")
  if (!is.null(.vars) && (!is.character(.vars) || !length(.vars))) cli::cli_abort("{.arg .vars} must be a non-empty character vector.")
  out <- ggplot2::ggproto("LayerInstance", LayerPly)
  # Copy the layer configuration, but never its bound methods.
  for (field in c("geom", "stat", "position", "data", "mapping", "aes_params", "geom_params", "stat_params", "inherit.aes", "show.legend", "constructor")) out[[field]] <- layer[[field]]
  out$ply_vars <- .vars
  out
}

# Capture unmapped non-position aesthetics after the inner stat and position.
# Their final mapping waits until all outer layers have trained the scales.
LayerInner <- ggplot2::ggproto("LayerInner", .Layer,
  compute_position = function(self, data, layout) {
    out <- ggplot2::ggproto_parent(.Layer, self)$compute_position(data, layout)
    self$raw_aesthetics <- out[intersect(names(out), self$capture_aes)]
    out
  }
)

capture_layer <- function(minor) {
  layer <- ggplot2::ggproto("LayerInstance", LayerInner)
  for (field in c("geom", "stat", "position", "data", "mapping", "aes_params", "geom_params", "stat_params", "inherit.aes", "show.legend", "constructor")) layer[[field]] <- minor[[field]]
  layer$capture_aes <- setdiff(minor$geom$aesthetics(), c(.x_aes, .y_aes, "group", "PANEL"))
  layer
}
