library(testthat)

# ---- Tests for ensure_has_metadata() ----

test_that("Tests for ensure_has_metadata()", {
  x <- example_anipoint()
  expect_no_error(ensure_has_metadata(x))
})

test_that("Tests for ensure_has_metadata()", {
  x <- data.frame()
  expect_error(ensure_has_metadata(x))
})

# ---- Tests for ensure_is_list() ----

test_that("Tests for ensure_is_list()", {
  x <- example_anipoint()
  expect_no_error(ensure_is_list(get_metadata(x)))
})

test_that("Tests for ensure_is_list()", {
  x <- data.frame()
  expect_error(ensure_is_list(x))
})

# ---- Tests for ensure_has_all_metadata_fields() ----

test_that("Tests for ensure_has_all_metadata_fields()", {
  x <- example_anipoint()
  expect_no_error(ensure_has_all_metadata_fields(get_metadata(x)))
})

test_that("Tests for ensure_has_all_metadata_fields()", {
  x <- example_anipoint()
  md <- get_metadata(x)
  expect_error(ensure_has_all_metadata_fields(unclass(md)[setdiff(
    names(md),
    "variables"
  )]))
})
