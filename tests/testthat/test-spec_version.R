test_that("list_default_metadata() includes spec_version with aniframe and anievent", {
  md <- list_default_metadata()

  expect_true("spec_version" %in% names(md))
  expect_type(md$spec_version, "list")
  expect_named(md$spec_version, c("aniframe", "anievent"))
  # Major for both: metadata became the category tree, variable roles slotted
  # lists, and an anievent's spatial component an absent `space` (#118).
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

test_that("ensure_valid_metadata() requires a well-formed spec_version", {
  md <- list_default_metadata()
  md$spec_version <- NULL
  expect_error(ensure_valid_metadata(md), "spec_version")

  md$spec_version <- list(aniframe = "junk")
  expect_error(ensure_valid_metadata(md), "spec_version")
})
