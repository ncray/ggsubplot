test_that("grid assignments match cut, including edges and unequal cells", {
  d <- data.frame(X = c(0, 1, 2, 3, 4, NA, 9), Y = c(0, 1, 2, 3, 4, 1, 2), a = 1:7, b = 1:7)
  p <- ggplot(d) + geom_subplot2d(aes(X, Y), breaks = list(c(0, 2, 4), c(0, 1, 4)),
    subplot = geom_point(aes(a, b)), reference = ref_box())
  out <- layer_data(p, 2)
  expected <- as.integer(interaction(cut(d$X, c(0, 2, 4), include.lowest = TRUE),
    cut(d$Y, c(0, 1, 4), include.lowest = TRUE), drop = TRUE))
  expect_equal(out$SUBPLOT, expected[!is.na(expected)])
  ref <- layer_data(p, 1)
  expect_equal(nrow(ref), length(unique(out$SUBPLOT)))
  expect_true(all(out$x >= ref$xmin[match(out$SUBPLOT, ref$SUBPLOT)]))
  expect_true(all(out$x <= ref$xmax[match(out$SUBPLOT, ref$SUBPLOT)]))
  expect_silent(ggplotGrob(p))
})
test_that("bins and binwidth work on constant and variable ranges", {
  expect_equal(interval_breaks(bins = 2)(0:4), c(0, 2, 4))
  expect_equal(interval_breaks(binwidth = 2)(0:4), c(0, 2, 4))
  expect_equal(interval_breaks()(rep(2, 5)), c(1.5, 2.5))
  expect_equal(interval_breaks(binwidth = 2, origin = 2)(-2:4), c(-2, 0, 2, 4))
  for (args in list(list(bins = c(2, 3)), list(binwidth = c(2, 1)))) {
    p <- ggplot(box_data()) + do.call(geom_subplot2d, c(list(aes(X, Y),
      subplot = geom_point(aes(a, b))), args))
    expect_silent(ggplotGrob(p))
  }
})
test_that("references use normalized coordinates and compose in any order", {
  for (ref in list(ref_box(), ref_hline(), ref_vline())) {
    layers <- geom_subplot(aes(X, Y, group = id), subplot = geom_point(aes(a, b)),
      width = 2, height = 2, reference = ref)
    d <- layer_data(ggplot(box_data()) + layers, 1)
    expect_equal(nrow(d), 2L)
    expect_true(all(abs((d$xmin + d$xmax)/2 - c(0, 4)[d$SUBPLOT]) < 1e-10))
    for (order in list(c(1, 2, 3), c(3, 1, 2), c(2, 3, 1))) {
      normal <- geom_point(aes(X + 20, Y))
      p <- ggplot(box_data()) + c(layers, list(normal))[order]
      expect_silent(ggplotGrob(p))
      expect_gt(ggplot_build(p)$layout$panel_params[[1]]$x.range[2], 24)
    }
  }
})
test_that("merge combines transitively overlapping boxes", {
  d <- data.frame(X = rep(c(0, .8, 1.6, 5), each = 3), Y = 0,
    id = rep(1:4, each = 3), a = rep(1:3, 4), b = 1:12)
  p <- ggplot(d) + geom_subplot(aes(X, Y, group = id), subplot = geom_point(aes(a, b)),
    width = 1, height = 1, position = "merge", reference = ref_box())
  expect_equal(length(unique(layer_data(p, 2)$SUBPLOT)), 2L)
  expect_equal(nrow(layer_data(p, 1)), 2L)
  expect_equal(layer_data(p, 1)$xmin, c(.3, 4.5))
})
test_that("grid merges and explicit break functions work", {
  p <- ggplot(box_data()) + geom_subplot2d(aes(X, Y),
    breaks = list(interval_breaks(bins = 2), c(-.5, .5)), width.adjust = 3,
    subplot = geom_point(aes(a, b)), position = "merge")
  expect_equal(length(unique(layer_data(p, 2)$SUBPLOT)), 1L)
  expect_equal(nrow(layer_data(p, 1)), 1L)
  expect_error(geom_subplot2d(subplot = geom_point(), bins = 0), "positive integer")
  expect_error(layer_data(ggplot(box_data()) + geom_subplot2d(aes(X,Y),
    subplot = geom_point(aes(a,b)), breaks = c(0,0,1))), "strictly increasing")
})
