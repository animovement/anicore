df <- data.frame(time = 1:3, individual = "a", x = 1:3, y = 1:3)

test_that("as_aniframe forwards to as_anipoint with a deprecation warning", {
  rlang::local_options(lifecycle_verbosity = "warning")
  expect_warning(old <- suppressMessages(as_aniframe(df)), "deprecated")
  expect_identical(old, suppressMessages(as_anipoint(df)))
})

test_that("aniframe forwards to anipoint with a deprecation warning", {
  rlang::local_options(lifecycle_verbosity = "warning")
  expect_warning(
    old <- suppressMessages(aniframe(time = 1:3, x = 1:3, y = 1:3)),
    "deprecated"
  )
  expect_identical(
    old,
    suppressMessages(anipoint(time = 1:3, x = 1:3, y = 1:3))
  )
})

test_that("example_aniframe forwards to example_anipoint with a warning", {
  rlang::local_options(lifecycle_verbosity = "warning")
  expect_warning(
    old <- example_aniframe(n_obs = 3, n_individuals = 1, n_keypoints = 1),
    "deprecated"
  )
  expect_s3_class(old, "anipoint")
})

test_that("validate_aniframe forwards to validate_anipoint with a warning", {
  rlang::local_options(lifecycle_verbosity = "warning")
  af <- suppressMessages(as_anipoint(df))
  expect_warning(validate_aniframe(af), "deprecated")
})

test_that("calls from inside another package do not warn", {
  env <- new.env(parent = asNamespace("stats"))
  env$df <- df
  expect_no_warning(suppressMessages(eval(quote(as_aniframe(df)), env)))
})
