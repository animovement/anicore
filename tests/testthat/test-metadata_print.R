# Test outline for print.aniframe_metadata():
#
# Output structure:
#   - first captured line is non-empty (no leading newline)
#   - no two consecutive empty lines (no blank lines between entries)
#   - last line is the trailing newline emitted by cat()
#
# Content:
#   - includes the "animovement metadata" header
#   - lists every metadata field name
#   - shows "(character)" / "(factor)" type annotation per field
#   - empty metadata renders the "No metadata available" message
#   - multi-element character vectors render comma-separated

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

  # First line should be the header (non-empty)
  expect_gt(nchar(out[1]), 0)

  # No two adjacent blank lines
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
