test_that("stars have ordered rays and symmetric bounds", {
  d <- data.frame(a = 1:8, r = rep(c(1, .4), 4))
  p <- ggplot(d) + geom_star(aes(angle = a, r = r), fill = "blue")
  out <- layer_data(p)
  vertices <- out[!out$.glyph_boundary, ]
  expect_equal(nrow(vertices), 8L)
  expect_equal(sqrt(vertices$x^2 + vertices$y^2), d$r)
  expect_equal(range(out$x), c(-1, 1))
  expect_equal(range(out$y), c(-1, 1))
  expect_silent(ggplotGrob(p + coord_equal()))
  expect_silent(ggplotGrob(box_plot(geom_star(aes(angle = a, r = b)), reference = ref_box()) + coord_quickmap()))
})
test_that("coxcomb wedges have correct areas and can stack", {
  d <- data.frame(a = 1:4, r = c(1, 4, 9, 16))
  p <- ggplot(d) + geom_coxcomb(aes(angle = a, r = r), stat = "identity")
  out <- layer_data(p)
  radii <- vapply(split(out, out$group), function(x) max(sqrt(x$x^2 + x$y^2)), numeric(1))
  # Corners are invisible and lie sqrt(2) times farther than the arcs.
  expect_equal(unname(radii), sqrt(2 * d$r))
  expect_silent(ggplotGrob(p + coord_equal()))
  expect_silent(ggplotGrob(box_plot(geom_coxcomb(aes(angle = a, fill = k))) + coord_quickmap()))
  q <- ggplot(data.frame(a = c(1,1), r = c(1,3), k = c("a","b"))) +
    geom_coxcomb(aes(angle = a, r = r, fill = k), stat = "identity")
  expect_equal(max(layer_data(q)$x), 2)
})
test_that("frequency geoms support categorical counts and continuous bins", {
  p <- ggplot(box_data()) + geom_freqstar(aes(angle = k), fill = "red")
  expect_silent(ggplotGrob(p))
  expect_silent(ggplotGrob(ggplot(box_data()) + geom_freqstar(aes(angle = b), stat = "bin", bins = 5)))
  expect_silent(ggplotGrob(ggplot(box_data()) + geom_coxcomb(aes(angle = b), stat = "bin", bins = 5)))
  expect_silent(ggplotGrob(box_plot(geom_freqstar(aes(angle = a))) + coord_quickmap()))
})
