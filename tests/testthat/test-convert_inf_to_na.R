test_that("Inf and -Inf become NA in numeric columns", {
  df <- data.frame(x = c(1, Inf, -Inf, 3))

  expect_equal(convert_inf_to_na(df)$x, c(1, NA, NA, 3))
})

test_that("finite values, NA and NaN are left alone", {
  df <- data.frame(x = c(1, NA, NaN, 2.5))
  out <- convert_inf_to_na(df)

  expect_equal(out$x[[1]], 1)
  expect_true(is.na(out$x[[2]]))
  expect_true(is.na(out$x[[3]]))
  expect_equal(out$x[[4]], 2.5)
})

test_that("non-numeric columns are untouched", {
  df <- data.frame(
    label = c("a", "b"),
    keep = factor(c("x", "y")),
    value = c(Inf, 1)
  )
  out <- convert_inf_to_na(df)

  expect_equal(out$label, c("a", "b"))
  expect_equal(out$keep, factor(c("x", "y")))
  expect_equal(out$value, c(NA, 1))
})

test_that("a frame with no Inf comes back unchanged", {
  df <- data.frame(x = c(1, 2), y = c("a", "b"))

  expect_equal(convert_inf_to_na(df), df)
})

test_that("it works on an aniframe without dropping its class", {
  data <- example_anipoint()

  expect_s3_class(convert_inf_to_na(data), "aniframe")
})
