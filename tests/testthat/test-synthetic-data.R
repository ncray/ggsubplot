test_that("bundled examples are explicitly synthetic and keep usable schemas", {
  expect_match(attr(nasa, "provenance"), "Entirely synthetic; not NASA")
  expect_match(attr(casualties, "provenance"), "Entirely synthetic fictional")
  expect_equal(nrow(nasa), 8640L)
  expect_equal(nrow(casualties), 2400L)
  expect_true(all(grepl("^synthetic-", nasa$id)))
  expect_true(all(casualties$type == "Synthetic event"))
  expect_true(all(casualties$category == "Fictional example"))
  expect_true(is.ordered(casualties$month))
  expect_equal(levels(casualties$month), month.name)
  expect_equal(length(unique(nasa$month)), 12L)
  expect_true(all(is.finite(nasa$surftemp)))
  expect_true(any(nasa$year == 1995 & nasa$long > -100 & nasa$long < -90 &
    nasa$lat > 30 & nasa$lat < 40))
  expect_true(any(casualties$year == 2004 & casualties$lon > 60 &
    casualties$lon < 75 & casualties$lat > 29 & casualties$lat < 39))
})
