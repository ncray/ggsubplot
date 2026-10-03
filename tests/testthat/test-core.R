test_that("positions are embedded inside each box and groups stay separate", {
  d <- layer_data(box_plot(geom_point(aes(a, b, group = k))))
  expect_true(all(abs(d$x - c(0, 4)[d$SUBPLOT]) <= 1))
  expect_true(all(abs(d$y) <= 1))
  expect_equal(length(unique(d$group)), 4L)
  expect_equal(nrow(d), 12L)
  expect_silent(ggplotGrob(box_plot(geom_line(aes(a, b, group = k)))))
})
test_that("fixed limits preserve sizes while free limits fill boxes", {
  fixed <- layer_data(box_plot(geom_point(aes(a, b))))
  flexible <- layer_data(box_plot(geom_point(aes(a, b)), y_scale = free))
  spans <- function(d) vapply(split(d$y, d$SUBPLOT), function(y) diff(range(y)), numeric(1))
  expect_equal(unname(spans(fixed)[2] / spans(fixed)[1]), 10)
  expect_equal(unname(spans(flexible)[1]), unname(spans(flexible)[2]))
})
test_that("relative dimensions and all position columns work", {
  p <- ggplot(box_data()) + geom_subplot(aes(X, Y, group = id),
    subplot = geom_col(aes(a, b)), height = 2, width = rel(.5))
  d <- layer_data(p)
  expect_true(all(d$xmin >= c(0, 4)[d$SUBPLOT] - 1))
  expect_true(all(d$xmax <= c(0, 4)[d$SUBPLOT] + 1))
  expect_silent(ggplotGrob(box_plot(geom_bar(aes(k)))))
  expect_silent(ggplotGrob(box_plot(geom_rect(aes(xmin = a, xmax = a + 1, ymin = 0, ymax = b)))))
})
test_that("major mappings and composition work", {
  p <- box_plot(geom_point(aes(a, b))) + geom_point(aes(X + 20, Y))
  b <- ggplot_build(p)
  expect_gt(b$layout$panel_params[[1]]$x.range[2], 24)
  expect_silent(ggplotGrob(p))
  expect_silent(ggplotGrob(ggplot(box_data(), aes(X, Y, group = id)) +
    geom_subplot(subplot = geom_point(aes(a, b)))))
  expect_silent(ggplotGrob(ggplot(box_data()) + geom_subplot(aes(X, Y, group = id,
    subplot = geom_point(aes(a, b))))))
})
test_that("invalid inputs fail clearly", {
  expect_error(geom_subplot(aes(X, Y)), "single ggplot2 layer")
  expect_error(layer_data(ggplot(box_data()) + geom_subplot(aes(X, Y),
    subplot = geom_point(aes(a, b)))), "Missing major.*group")
  for (axis in c("x", "y")) {
    m <- aes(X, Y, group = id); m[[axis]] <- NULL
    expect_error(layer_data(ggplot(box_data()) + geom_subplot(m,
      subplot = geom_point(aes(a, b)))), "Missing major")
  }
  expect_error(geom_subplot(subplot = geom_subplot(subplot = geom_point())), "cannot contain")
  expect_error(geom_subplot(subplot = geom_point(), position = "jitter"), "Unsupported")
  expect_error(layer_data(box_plot(geom_point(aes(a, b))) + facet_wrap(~id)), "Outer facetting")
})
test_that("fixed minor positions are embedded and empty assignments draw nothing", {
  d <- layer_data(box_plot(geom_point(x = 1, y = 2)))
  expect_equal(unique(d$x), c(0, 4))
  expect_equal(unique(d$y), 0)
  expect_equal(length(unique(d$group)), 2L)
  empty <- box_data(); empty$X <- NA_real_
  p <- ggplot(empty) + geom_subplot(aes(X, Y, group = id), subplot = geom_point(aes(a,b)))
  expect_equal(nrow(layer_data(p)), 0L)
  expect_silent(ggplotGrob(p))
})
