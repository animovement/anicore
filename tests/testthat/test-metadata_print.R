capture_md_print <- function(x, ...) {
  old <- Sys.getenv("NO_COLOR", unset = NA)
  Sys.setenv("NO_COLOR" = "1")
  on.exit({
    if (is.na(old)) {
      Sys.unsetenv("NO_COLOR")
    } else {
      Sys.setenv("NO_COLOR" = old)
    }
  })
  capture.output(print(x, ...))
}

example_print_frame <- function() {
  example_anipoint() |>
    set_metadata(sampling_rate = 30, source = "deeplabcut") |>
    set_structure(example_structure()) |>
    set_structure(
      anistructure(segments = list(c("1", "2"))),
      "individual",
      "pair"
    )
}

test_that("metadata prints one compact line per field set", {
  md <- get_metadata(example_print_frame())
  expect_snapshot(print(md))
})

test_that("all = TRUE prints every field, the allowed values and spec_version", {
  md <- get_metadata(example_print_frame())
  expect_snapshot(print(md, all = TRUE))
})

test_that("anievent metadata prints without a space category", {
  ev <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )
  expect_snapshot(print(get_metadata(ev)))
})

test_that("metadata print wraps to the console width", {
  local_reproducible_output(width = 50)
  expect_snapshot(print(get_metadata(example_anipoint())))
})

test_that("print has no leading newline and no blank lines between entries", {
  out <- capture_md_print(get_metadata(example_anipoint()))

  expect_gt(nchar(out[1]), 0)
  blanks <- nchar(out) == 0
  expect_false(any(blanks[-length(blanks)] & blanks[-1]))
})

test_that("print leaves out fields not set and names them at the end", {
  out <- capture_md_print(get_metadata(example_anipoint()))
  text <- paste(out, collapse = "\n")

  expect_no_match(text, "<NA>", fixed = TRUE)
  expect_no_match(text, "(character)", fixed = TRUE)
  expect_no_match(text, "levels", fixed = TRUE)
  expect_no_match(text, "spec_version", fixed = TRUE)
  expect_no_match(text, "-- recording", fixed = TRUE)
  expect_match(text, "Not set: source, source_version", fixed = TRUE)
  expect_match(text, "euler_intrinsic, structure", fixed = TRUE)
})

test_that("print lists every category and field with all = TRUE", {
  md <- get_metadata(example_anipoint())
  text <- paste(capture_md_print(md, all = TRUE), collapse = "\n")

  for (category in names(md)) {
    expect_match(text, category, fixed = TRUE)
  }
  for (field in names(list_metadata_field_categories())) {
    expect_match(text, paste0(field, ":"), fixed = TRUE)
  }
  expect_match(text, "source: -", fixed = TRUE)
  expect_match(text, "levels: rad, deg, none", fixed = TRUE)
  expect_no_match(text, "Not set", fixed = TRUE)
})

test_that("print handles empty metadata", {
  empty <- structure(list(), class = c("aniframe_metadata", "list"))

  out <- capture_md_print(empty)

  expect_true(any(grepl("No metadata available", out)))
})

test_that("print renders multi-element values comma-separated (#34)", {
  data <- example_anipoint() |>
    set_metadata(filename = c("a.csv", "b.csv"))

  out <- capture_md_print(get_metadata(data))

  expect_true(any(out == "filename: a.csv, b.csv"))
})

test_that("values print with their units", {
  data <- example_anipoint() |>
    set_metadata(
      sampling_rate = 30,
      axis_extents = c(x = 1920, y = 1080),
      axis_directions = c(x = "right", y = "down")
    )
  out <- capture_md_print(get_metadata(data))

  expect_true(any(out == "sampling_rate: 30 Hz"))
  expect_true(any(out == "sampling_interval: 1 frame"))
  expect_true(any(out == "axis_extents: x = 1920 px, y = 1080 px"))
  expect_true(any(out == "axis_directions: x = right, y = down"))

  md <- list_default_metadata()
  md$time$unit_time <- factor("s", levels = levels(md$time$unit_time))
  md$time$sampling_interval <- 0.5
  expect_true(any(capture_md_print(md) == "sampling_interval: 0.5 s"))
})

test_that("a unit of none or unknown is left off", {
  md <- list_default_metadata()
  md$space$unit_space <- factor("none", levels = levels(md$space$unit_space))
  md$space$axis_extents <- c(x = 2)
  md$time$unit_time <- factor("unknown", levels = levels(md$time$unit_time))
  md$time$sampling_interval <- 2

  out <- capture_md_print(md)

  expect_true(any(out == "axis_extents: x = 2"))
  expect_true(any(out == "sampling_interval: 2"))
})

test_that("an interval of several frames reads in frames", {
  md <- list_default_metadata()
  md$time$sampling_interval <- 2

  expect_true(any(capture_md_print(md) == "sampling_interval: 2 frames"))
})

test_that("start_datetime prints as a date-time", {
  data <- set_metadata(
    example_anipoint(),
    start_datetime = "2024-01-15 14:30:00"
  )

  out <- capture_md_print(get_metadata(data))

  expect_true(any(grepl("^start_datetime: 2024-01-15 14:30:00", out)))
})

test_that("print returns input invisibly", {
  md <- get_metadata(example_anipoint())

  capture.output(returned <- withVisible(print(md)))

  expect_identical(returned$value, md)
  expect_false(returned$visible)
})

test_that("attached structures print as counts, naming a differing variable", {
  out <- capture_md_print(get_metadata(example_print_frame()))

  expect_true(any(out == "keypoint: 11 points, 10 segments, 3 joints"))
  expect_true(any(
    out == "pair (over individual): 2 points, 1 segment, 0 joints"
  ))
})

test_that("print renders a flat field selection", {
  flat <- structure(
    list(sampling_rate = 30, source = NA_character_),
    class = "aniframe_metadata"
  )
  out <- capture_md_print(flat)

  expect_true(any(out == "sampling_rate: 30 Hz"))
  expect_true(any(out == "Not set: source"))
})

test_that("empty variables render as a dash", {
  expect_equal(
    cli::cli_format_method(print_metadata_variables(list())),
    "-"
  )
})

test_that("wrap_items() breaks between items and indents continuations", {
  expect_equal(wrap_items("Label:", character(), 20), "Label:")
  expect_equal(
    wrap_items("Label:", c("aaa", "bbb", "ccc"), 16),
    c("Label: aaa, bbb,", "  ccc")
  )
  # An item wider than the line gets a line of its own.
  expect_equal(
    wrap_items("L:", c("a", strrep("b", 30), "c"), 10),
    c("L: a,", paste0("  ", strrep("b", 30), ","), "  c")
  )
})
