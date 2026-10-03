test_that("reviewed gallery plots keep their visual appearance", {
  skip_if_not_installed("vdiffr")
  skip_if_not_installed("maps")
  plots <- gallery_plots()
  for (name in names(plots)) {
    vdiffr::expect_doppelganger(name, plots[[name]],
      variant = if (gallery_prefix() == "") "gg4" else "gg35")
  }
})
