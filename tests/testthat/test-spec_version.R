# Tests for the spec_version metadata field
#
# Default:
#   - present in list_default_metadata() with expected aniframe + anievent entries
#
# Round-trip:
#   - set_metadata() accepts a new spec_version list and stores it whole
#
# Backwards compatibility:
#   - metadata missing spec_version still passes ensure_valid_metadata()

test_that("list_default_metadata() includes spec_version with aniframe and anievent", {
  md <- list_default_metadata()

  expect_true("spec_version" %in% names(md))
  expect_type(md$spec_version, "list")
  expect_named(md$spec_version, c("aniframe", "anievent"))
  # Major for both: the flat metadata list became the category tree, the
  # variable roles became slotted lists, and an anievent's spatial
  # component became an absent `space` category (#118).
  expect_equal(md$spec_version$aniframe, "3.0.0")
  expect_equal(md$spec_version$anievent, "1.0.0")
})

test_that("set_metadata round-trips a custom spec_version list", {
  data <- dplyr::tibble()

  result <- set_metadata(
    data,
    spec_version = list(aniframe = "1.1.0", anievent = "0.2.0")
  )

  sv <- get_metadata(result, "spec_version")
  expect_equal(sv$aniframe, "1.1.0")
  expect_equal(sv$anievent, "0.2.0")
})

test_that("ensure_valid_metadata() tolerates metadata missing spec_version", {
  md <- list_default_metadata()
  md$spec_version <- NULL

  expect_no_error(ensure_valid_metadata(md))
})
