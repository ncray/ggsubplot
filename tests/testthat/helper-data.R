library(ggplot2)
box_data <- function() data.frame(X = rep(c(0, 4), each = 6), Y = 0,
  id = rep(1:2, each = 6), a = rep(1:3, 4),
  b = c(1:6, 10 * (1:6)), k = rep(c("a", "b"), each = 3, times = 2))
box_plot <- function(minor, ...) ggplot2::ggplot(box_data()) +
  geom_subplot(ggplot2::aes(X, Y, group = id), subplot = minor, width = 2, height = 2, ...)
