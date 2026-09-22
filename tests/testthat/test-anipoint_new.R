# Tests for the anipoint constructor and the class vector it lays down

test_that("new_anipoint lays down the anipoint and aniframe classes in order", {
  df <- dplyr::tibble(
    time = 1:10,
    x = rnorm(10),
    y = rnorm(10)
  )

  df <- new_anipoint(df)

  expect_s3_class(df, "anipoint")
  expect_s3_class(df, "aniframe")
  expect_s3_class(df, "tbl_df")
  expect_equal(class(df)[1:2], c("anipoint", "aniframe"))
})

test_that("an anipoint passes both the grain and the family predicate", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

  expect_true(is_anipoint(af))
  expect_true(is_aniframe(af))
  expect_no_error(ensure_is_anipoint(af))
  expect_no_error(ensure_is_aniframe(af))
})

test_that("an anievent is an aniframe but not an anipoint", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )

  expect_true(is_aniframe(ae))
  expect_false(is_anipoint(ae))
  expect_error(ensure_is_anipoint(ae), "not an anipoint")
})
