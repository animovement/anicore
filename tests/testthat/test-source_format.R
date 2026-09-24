# Tests for the source_format metadata field
#
# Covers:
#   - list_default_metadata() includes source_format, as NA character
#   - set_metadata() stores and get_metadata() returns it
#   - metadata missing source_format still passes ensure_valid_metadata(),
#     so objects serialised before the field existed continue to validate
#   - a non-character value is rejected

test_that("list_default_metadata() includes source_format as NA character", {
  md <- list_default_metadata()

  expect_true("source_format" %in% names(md))
  expect_type(md$source_format, "character")
  expect_true(is.na(md$source_format))
})

test_that("source_format round-trips through set_metadata()", {
  data <- example_anipoint() |>
    set_metadata(source = "freemocap", source_format = "by_frame_9col")

  expect_equal(get_metadata(data)$source_format, "by_frame_9col")
  expect_equal(get_metadata(data)$source, "freemocap")
})

test_that("source_format is independent of source_version", {
  data <- example_anipoint() |>
    set_metadata(source_format = "by_frame_8col")

  expect_equal(get_metadata(data)$source_format, "by_frame_8col")
  expect_true(is.na(get_metadata(data)$source_version))
})

test_that("metadata without source_format still validates", {
  md <- list_default_metadata()
  md$source_format <- NULL

  expect_silent(ensure_valid_metadata(md))
})

test_that("a non-character source_format is rejected", {
  md <- list_default_metadata()
  md$source_format <- 1L

  expect_error(ensure_valid_metadata(md), "correct types")
})
