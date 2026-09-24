test_that("get_metadata() returns the full list when fields is NULL", {
  data <- example_anipoint()
  md <- get_metadata(data)
  expect_s3_class(md, "aniframe_metadata")
  expect_true(all(list_metadata_categories() %in% names(md)))
  expect_true("spec_version" %in% names(md))
})

test_that("get_metadata() returns a single value when fields is a length-1 vector", {
  data <- example_anipoint() |>
    set_metadata(sampling_rate = 30)
  expect_equal(get_metadata(data, "sampling_rate"), 30)
})

test_that("get_metadata() returns a plain list when fields has length > 1", {
  data <- example_anipoint() |>
    set_metadata(sampling_rate = 30, source = "test")

  sub <- get_metadata(data, c("sampling_rate", "source"))

  expect_false(inherits(sub, "aniframe_metadata"))
  expect_named(sub, c("sampling_rate", "source"), ignore.order = TRUE)
  expect_equal(sub$sampling_rate, 30)
  expect_equal(sub$source, "test")
})

test_that("a field the object does not carry gives NULL", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
  md <- attr(af, "metadata")
  md$time$sampling_rate <- NULL
  attr(af, "metadata") <- md

  expect_null(get_metadata(af, "sampling_rate"))
})

test_that("asking for something that is not a field is an error", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

  expect_error(get_metadata(af, "sampling_frequency"), "not a metadata field")
  expect_error(
    get_metadata(af, c("unit_space", "unit_spce")),
    "not a metadata field"
  )
})
