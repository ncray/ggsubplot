gallery_plots <- function() {
  # Use the same explicit theme across ggplot2 versions and graphics devices.
  theme <- ggplot2::theme_bw(base_size = 11) + ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    plot.title = ggplot2::element_text(size = 13, face = "bold"))
  n <- subset(nasa, year == 1995 & long > -110 & long < -85 & lat > 25 & lat < 45)
  c <- subset(casualties, year == 2004 & lon > 60 & lon < 75 & lat > 29 & lat < 39)
  usa <- ggplot2::map_data("world", region = c("USA", "Mexico"))
  afghan <- ggplot2::map_data("world", region = "Afghanistan")
  map <- function(d) ggplot2::geom_polygon(data = d,
    mapping = ggplot2::aes(long, lat, group = group), inherit.aes = FALSE,
    fill = "grey97", colour = "grey60", linewidth = .3)
  nasa_base <- ggplot2::ggplot(n) + map(usa) + ggplot2::coord_quickmap(
    xlim = c(-112, -83), ylim = c(23, 42)) + theme + ggplot2::labs(x = "Longitude", y = "Latitude")
  afghan_base <- ggplot2::ggplot(c) + map(afghan) + ggplot2::coord_quickmap() + theme +
    ggplot2::labs(x = "Longitude", y = "Latitude")
  points <- nasa_base + geom_subplot(ggplot2::aes(long, lat, group = id),
    subplot = ggplot2::geom_point(ggplot2::aes(month, surftemp), size = .55),
    width = 2, height = 2, reference = ref_box(fill = "grey92", color = "grey65")) +
    ggplot2::labs(title = "Synthetic monthly surface temperatures")
  stars <- nasa_base + geom_subplot(ggplot2::aes(long, lat, group = id),
    subplot = geom_star(ggplot2::aes(angle = month, r = .15 + .85 * (surftemp - min(surftemp)) /
        (max(surftemp) - min(surftemp)), fill = mean(surftemp)),
      linewidth = .2), width = 2, height = 2) +
    ggplot2::scale_fill_viridis_c(name = "Mean temp. (K)") +
    ggplot2::labs(title = "Synthetic seasonal temperature stars")
  bars <- afghan_base + geom_subplot2d(ggplot2::aes(lon, lat), bins = c(7, 5),
    subplot = ggplot2::geom_bar(ggplot2::aes(victim, fill = victim)), y_scale = free) +
    ggplot2::labs(title = "Synthetic events by category in geographic bins")
  coxcombs <- afghan_base + geom_subplot2d(ggplot2::aes(lon, lat), bins = c(7, 5),
    subplot = geom_coxcomb(ggplot2::aes(angle = month, fill = victim)),
    reference = NULL, x_scale = free, y_scale = free) +
    ggplot2::labs(title = "Synthetic events: monthly coxcombs (free scales)")
  d <- box_data()
  reference_base <- ggplot2::ggplot(d) + theme + ggplot2::coord_equal() +
    ggplot2::labs(x = "Major x", y = "Major y")
  refs <- reference_base + geom_subplot(ggplot2::aes(X, Y, group = id),
    subplot = ggplot2::geom_point(ggplot2::aes(a, b), colour = "steelblue"),
    width = 2, height = 2, reference = ref_box(color = "grey50")) +
    geom_subplot(ggplot2::aes(X, Y + 3, group = id),
      subplot = ggplot2::geom_line(ggplot2::aes(a, b, group = k)),
      width = 2, height = 2, reference = ref_hline(fill = "orange")) +
    geom_subplot(ggplot2::aes(X, Y + 6, group = id),
      subplot = ggplot2::geom_point(ggplot2::aes(a, b)),
      width = 2, height = 2, reference = ref_vline(fill = "orange")) +
    ggplot2::labs(title = "Box, horizontal and vertical references")
  dmerge <- data.frame(X = rep(c(0, .8, 1.6, 5), each = 3), Y = 0,
    id = rep(1:4, each = 3), a = rep(1:3, 4), b = 1:12)
  merge <- ggplot2::ggplot(dmerge) + theme + geom_subplot(ggplot2::aes(X, Y, group = id),
    subplot = ggplot2::geom_point(ggplot2::aes(a, b)), width = 1, height = 1,
    position = "merge", reference = ref_box(color = "grey50")) +
    ggplot2::coord_equal() + ggplot2::labs(title = "Overlapping locations merged", x = "Major x", y = "Major y")
  flexible <- reference_base + geom_subplot(ggplot2::aes(X, Y, group = id),
    subplot = ggplot2::geom_line(ggplot2::aes(a, b, group = k)),
    width = 2, height = 2, y_scale = free, reference = ref_box(color = "grey50")) +
    geom_subplot(ggplot2::aes(X, Y + 3, group = id),
      subplot = ggplot2::geom_line(ggplot2::aes(a, b, group = k)),
      width = 2, height = 2, reference = ref_box(color = "grey50")) +
    ggplot2::labs(title = "Free limits below; shared limits above")
  mixed <- reference_base + ggplot2::geom_point(ggplot2::aes(X + 8, b/10),
    colour = "firebrick", size = 2) + geom_subplot(ggplot2::aes(X, Y, group = id),
    subplot = ggplot2::geom_point(ggplot2::aes(a, b, colour = mean(b))),
    width = 2, height = 2, reference = ref_box(color = "grey50")) +
    ggplot2::labs(title = "Ordinary points and embedded points", colour = "Mean b")
  glyph_data <- data.frame(a = 1:8, r = rep(c(1, .3), 4), kind = "Star")
  comb_data <- data.frame(a = 1:8, r = c(.2, .4, .8, 1, .7, .5, .3, .1), kind = "Coxcomb")
  freq_data <- data.frame(a = rep(1:8, c(10, 4, 8, 3, 9, 5, 8, 4)), kind = "Frequency star")
  glyphs <- ggplot2::ggplot() + theme +
    geom_star(data = glyph_data, ggplot2::aes(angle = a, r = r), fill = "skyblue") +
    geom_coxcomb(data = comb_data, ggplot2::aes(angle = a, r = r), stat = "identity", fill = "coral") +
    geom_freqstar(data = freq_data, ggplot2::aes(angle = a), fill = "gold") +
    ggplot2::facet_wrap(~kind, nrow = 1) + ggplot2::coord_equal() +
    ggplot2::labs(title = "Standalone glyphs", x = NULL, y = NULL)
  list(`nasa-stars` = stars, `nasa-points` = points, `casualties-bars-2d` = bars,
    `coxcombs-2d` = coxcombs, references = refs, merge = merge,
    `free-scales` = flexible, `mixed-layers` = mixed, glyphs = glyphs)
}

gallery_prefix <- function() if (utils::packageVersion("ggplot2") < "4.0.0") "gg35-" else ""
