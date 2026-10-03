test_that("minor aesthetics are evaluated per subplot with selective opt outs", {
  minor <- geom_point(aes(a, b, colour = mean(b), size = mean(b)))
  p <- box_plot(minor)
  d <- layer_data(p)
  expect_equal(vapply(split(d$colour, d$SUBPLOT), function(x) length(unique(x)), integer(1)), c(`1`=1L,`2`=1L))
  expect_equal(length(unique(d$colour)), 2L)
  expect_equal(length(unique(layer_data(box_plot(minor, ply.aes = FALSE))$colour)), 1L)
  d <- layer_data(box_plot(minor, ply.aes = "colour"))
  expect_equal(length(unique(d$colour)), 2L)
  expect_equal(length(unique(d$size)), 1L)
  expect_silent(ggplotGrob(p))
  expect_equal(unique(layer_data(box_plot(geom_point(aes(a, b, colour = I("red")))))$colour), "red")
})
test_that("non-position scales and legends match the original values", {
  d <- box_data(); d$k <- factor(d$k, levels = c("b", "a"))
  p <- ggplot(d) + geom_subplot(aes(X, Y, group = id), width = 2, height = 2,
    subplot = geom_bar(aes(k, fill = k))) + scale_fill_manual(values = c(a = "red", b = "blue"))
  b <- ggplot_build(p)
  expect_equal(sort(unique(as.character(b$data[[1]]$fill))), c("blue", "red"))
  expect_equal(as.character(b$plot$scales$get_scales("fill")$get_breaks()), c("b", "a"))
  expect_silent(ggplotGrob(p))
  expect_true(any(grepl("guide-box", ggplotGrob(p)$layout$name)))
  # Different layers must use a shared palette, regardless of insertion order.
  d <- box_data(); d$j <- ifelse(d$id == 1, "z", "a")
  a <- geom_subplot(aes(X, Y, group = id), data = subset(d, id == 1),
    subplot = geom_point(aes(a, b, colour = j)), width = 2, height = 2)
  z <- geom_subplot(aes(X, Y, group = id), data = subset(d, id == 2),
    subplot = geom_point(aes(a, b, colour = j)), width = 2, height = 2)
  for (layers in list(list(a,z), list(z,a))) {
    b <- ggplot_build(ggplot() + layers)
    scale <- b$plot$scales$get_scales("colour")
    expect_equal(unique(as.character(b$data[[1]]$colour)), scale$map(if (identical(layers[[1]], a)) "z" else "a"))
    expect_equal(unique(as.character(b$data[[2]]$colour)), scale$map(if (identical(layers[[2]], a)) "z" else "a"))
  }
})
test_that("staged mappings and references use the intended data", {
  p <- box_plot(geom_bar(aes(k, fill = after_stat(count))))
  expect_silent(ggplotGrob(p))
  p <- box_plot(geom_point(aes(a, b, colour = b, fill = after_scale(colour)), shape = 21))
  expect_equal(layer_data(p)$fill, layer_data(p)$colour)
  p <- box_plot(geom_point(aes(a, b)), reference = ref_box(aes(fill = mean(b))))
  expect_equal(length(unique(layer_data(p, 1)$fill)), 2L)
  expect_silent(ggplotGrob(p))
})
test_that("ply_aes wraps ordinary layers and honours .vars and facets", {
  d <- box_data()
  p <- ggplot(d) + ply_aes(geom_point(aes(a, b, group = id, colour = mean(b))))
  out <- layer_data(p)
  expect_equal(length(unique(out$colour)), 2L)
  p2 <- ggplot(d) + ply_aes(geom_point(aes(a, b, colour = mean(b))), "id")
  expect_equal(out$colour, layer_data(p2)$colour)
  expect_silent(ggplotGrob(p + facet_wrap(~id)))
  expect_error(layer_data(ggplot(d) + ply_aes(geom_point(aes(a,b)))), "needs a group")
})
test_that("stage and mixed continuous scales retain their final palette", {
  p <- box_plot(geom_point(aes(a, b, colour = stage(start = b, after_scale = colour))))
  expect_silent(ggplotGrob(p))
  layers <- list(geom_point(aes(X + 10, Y, colour = b)),
    geom_subplot(aes(X, Y, group = id), subplot = geom_point(aes(a, b, colour = b)), width = 2, height = 2))
  for (ord in list(1:2, 2:1)) {
    built <- ggplot_build(ggplot(box_data()) + layers[ord] + scale_colour_viridis_c(transform = "log10"))
    scale <- built$plot$scales$get_scales("colour")
    sub <- which(ord == 2)
    expect_equal(as.character(built$data[[sub]]$colour), scale$map(log10(box_data()$b)))
  }
})
test_that("group-specific factor expressions union their levels", {
  p <- box_plot(geom_point(aes(a, b, colour = factor(b))))
  expect_silent(ggplotGrob(p))
  expect_equal(length(unique(layer_data(p)$colour)), 12L)
})
