capture_md_print <- function(x) {
  old <- Sys.getenv("NO_COLOR", unset = NA)
  Sys.setenv("NO_COLOR" = "1")
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("NO_COLOR")
    } else {
      Sys.setenv("NO_COLOR" = old)
    }
  })
  capture.output(print(x))
}

test_that("print has no leading newline and no blank lines between entries", {
  data <- example_anipoint()
  md <- get_metadata(data)

  out <- capture_md_print(md)

  expect_gt(nchar(out[1]), 0)

  if (length(out) >= 2) {
    blanks <- nchar(out) == 0
    expect_false(any(blanks[-length(blanks)] & blanks[-1]))
  }
})

test_that("print includes the metadata header", {
  data <- example_anipoint()
  md <- get_metadata(data)

  out <- capture_md_print(md)

  expect_true(any(grepl("animovement metadata", out)))
})

test_that("print lists every metadata field name", {
  data <- example_anipoint()
  md <- get_metadata(data)

  out <- capture_md_print(md)
  joined <- paste(out, collapse = "\n")

  for (field in names(md)) {
    expect_match(joined, field, fixed = TRUE)
  }
})

test_that("print handles empty metadata", {
  empty <- structure(list(), class = c("aniframe_metadata", "list"))

  out <- capture_md_print(empty)

  expect_true(any(grepl("No metadata available", out)))
})

test_that("print renders multi-element character vectors comma-separated (#34)", {
  data <- example_anipoint() |>
    set_metadata(filename = c("a.csv", "b.csv"))
  md <- get_metadata(data)

  out <- capture_md_print(md)

  expect_true(any(grepl("a.csv, b.csv", out, fixed = TRUE)))
})

test_that("print wraps single-element character values in quotes", {
  data <- example_anipoint() |>
    set_metadata(source = "deeplabcut")
  md <- get_metadata(data)

  out <- capture_md_print(md)

  expect_true(any(grepl('"deeplabcut"', out, fixed = TRUE)))
})

test_that("print formats single-element non-character values without quotes", {
  data <- example_anipoint() |>
    set_metadata(sampling_rate = 30)
  md <- get_metadata(data)

  out <- capture_md_print(md)

  expect_true(any(grepl("sampling_rate", out, fixed = TRUE)))
  # Numeric value rendered without surrounding quotes
  expect_true(any(grepl(": 30$", out)))
})

test_that("print returns input invisibly", {
  data <- example_anipoint()
  md <- get_metadata(data)

  capture.output(returned <- print(md))

  expect_identical(returned, md)
})

test_that("print renders the category tree with sections", {
  data <- example_anipoint()
  data <- suppressWarnings(set_connections(
    data,
    list(c("head", "thorax"), c("thorax", "abdomen")),
    variable = "keypoint"
  ))
  out <- capture_md_print(get_metadata(data))
  text <- paste(out, collapse = "\n")

  expect_match(text, "spec_version")
  for (category in list_metadata_categories()) {
    expect_match(text, category, fixed = TRUE)
  }
  # variables print one line per role, slots inline
  expect_match(text, "keys:")
  expect_match(text, "index: time")
  # structure prints one line per keyed variable
  expect_match(text, "keypoint: 2 connections")
})

test_that("print renders an empty structure category as (empty)", {
  out <- capture_md_print(get_metadata(example_anipoint()))
  expect_match(paste(out, collapse = "\n"), "(empty)", fixed = TRUE)
})

test_that("print renders a flat field selection", {
  data <- set_metadata(example_anipoint(), sampling_rate = 30)
  out <- capture_md_print(get_metadata(data, c("sampling_rate", "source")))
  text <- paste(out, collapse = "\n")

  expect_match(text, "sampling_rate")
  expect_match(text, "30")
})

test_that("empty categories render as (empty)", {
  expect_match(
    paste(
      cli::cli_format_method(print_metadata_leaves(list())),
      collapse = "\n"
    ),
    "(empty)",
    fixed = TRUE
  )
  expect_match(
    paste(
      cli::cli_format_method(print_metadata_variables(list())),
      collapse = "\n"
    ),
    "(empty)",
    fixed = TRUE
  )
})
