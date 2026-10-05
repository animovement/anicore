# The recorded and the current sampling rate (#190) ----

# A 300-frame single track, frames counted from 0.
single_track <- function(n = 300) {
  as_anipoint(data.frame(individual = "a", time = seq_len(n) - 1, x = 1, y = 1))
}

recorded <- function(x) get_metadata(x, "source_sampling_rate")

# Metadata as written before `source_sampling_rate` existed.
without_field <- function(x) {
  md <- attr(x, "metadata")
  md$recording$source_sampling_rate <- NULL
  attr(x, "metadata") <- md
  x
}

test_that("source_sampling_rate is a recording field, unset by default", {
  expect_true(is.na(list_default_metadata()$recording$source_sampling_rate))
  expect_type(list_default_metadata()$recording$source_sampling_rate, "double")
  expect_false(is.nan(recorded(single_track())))
  expect_true(
    "source_sampling_rate" %in% names(get_metadata(single_track(), "recording"))
  )
})

test_that("the first declared rate fills the recorded rate", {
  af <- set_metadata(single_track(), sampling_rate = 200)

  expect_equal(recorded(af), 200)
  expect_equal(get_metadata(af, "sampling_rate"), 200)
})

test_that("as_anipoint(metadata = ) fills the recorded rate too", {
  df <- data.frame(individual = "a", time = 0:2, x = 1, y = 1)

  af <- as_anipoint(df, metadata = list(sampling_rate = 30))

  expect_equal(recorded(af), 30)
})

test_that("later rates change only the current rate", {
  af <- single_track() |>
    set_metadata(sampling_rate = 200) |>
    set_metadata(sampling_rate = 50)

  expect_equal(get_metadata(af, "sampling_rate"), 50)
  expect_equal(recorded(af), 200)
})

test_that("a rate set alongside the recorded one does not overwrite it", {
  af <- set_metadata(
    single_track(),
    sampling_rate = 50,
    source_sampling_rate = 200
  )
  expect_equal(recorded(af), 200)

  undeclared <- set_metadata(
    single_track(),
    sampling_rate = 50,
    source_sampling_rate = NA
  )
  expect_true(is.na(recorded(undeclared)))
})

test_that("declaring no rate records none", {
  af <- set_metadata(single_track(), sampling_rate = NA)

  expect_true(is.na(recorded(af)))
  expect_true(is.na(recorded(set_metadata(single_track(), source = "x"))))
})

test_that("NaN declares a device with no fixed rate (read_trackball)", {
  af <- single_track() |>
    set_metadata(source_sampling_rate = NaN) |>
    set_metadata(sampling_rate = 100)

  expect_true(is.nan(recorded(af)))
  expect_true(is.na(recorded(af)))
  expect_equal(get_metadata(af, "sampling_rate"), 100)
  expect_no_warning(validate_anipoint(af))
})

test_that("a correction of the camera rate sets both rates (example 4)", {
  fixed <- single_track() |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s") |>
    convert_unit_time("frame") |>
    set_metadata(sampling_rate = 25, source_sampling_rate = 25) |>
    convert_unit_time("s")

  expect_equal(get_metadata(fixed, "sampling_rate"), 25)
  expect_equal(recorded(fixed), 25)
})

test_that("processing leaves the recorded rate alone", {
  af <- set_metadata(single_track(), sampling_rate = 30)

  out <- af |>
    convert_unit_time("s") |>
    dplyr::filter(dplyr::row_number() %% 3 == 1) |>
    dplyr::mutate(z = x)

  expect_equal(recorded(out), 30)
})

test_that("metadata from before the field still validates and fills", {
  af <- without_field(single_track())
  expect_no_error(ensure_valid_metadata(get_metadata(af)))
  expect_null(recorded(af))

  expect_equal(recorded(set_metadata(af, sampling_rate = 30)), 30)
})

test_that("an older frame that already had a rate does not fill it later", {
  # The first declaration has passed; a later rate may be a resampled one.
  af <- without_field(set_metadata(single_track(), sampling_rate = 30))

  expect_null(recorded(set_metadata(af, sampling_rate = 10)))
})

test_that("legacy flat metadata fills on its first declared rate", {
  af <- legacy_anipoint()

  expect_equal(recorded(set_metadata(af, sampling_rate = 60)), 60)
})

test_that("source_sampling_rate must be a positive number, NA or NaN", {
  af <- single_track()

  for (bad in list(0, -30, Inf, c(30, 60))) {
    expect_error(
      set_metadata(af, source_sampling_rate = bad),
      "positive number"
    )
  }
  expect_error(set_metadata(af, source_sampling_rate = "30"), "correct types")
  expect_no_error(set_metadata(af, source_sampling_rate = NA))
  expect_no_error(set_metadata(af, source_sampling_rate = 29.97))
})

test_that("the marker survives serialisation, as aniread's parquet uses", {
  af <- set_metadata(single_track(), source_sampling_rate = NaN)

  # arrow stores R attributes through serialize().
  for (ascii in c(TRUE, FALSE)) {
    back <- unserialize(serialize(af, NULL, ascii = ascii))
    expect_true(is.nan(recorded(back)))
  }
  back <- unserialize(serialize(single_track(), NULL, ascii = TRUE))
  expect_false(is.nan(recorded(back)))
})

test_that("an anievent records its first declared rate", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = c("REM", "wake"),
    start = c(30, 150),
    stop = c(60, 300)
  )

  expect_equal(recorded(set_metadata(ae, sampling_rate = 30)), 30)
})

test_that("to_anievent() carries the recorded rate", {
  af <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(b = factor(rep(c("r", "w"), each = 2))) |>
    set_variables(event = list(state = "b"))

  ae <- to_anievent(set_metadata(af, sampling_rate = 200))
  expect_equal(recorded(ae), 200)

  windowed <- af |>
    set_metadata(source_sampling_rate = NaN, sampling_rate = 100) |>
    to_anievent()
  expect_true(is.nan(recorded(windowed)))
  expect_equal(get_metadata(windowed, "sampling_rate"), 100)
})

# Printing ----

print_lines <- function(x, ...) {
  no_color <- Sys.getenv("NO_COLOR", unset = NA)
  Sys.setenv("NO_COLOR" = "1")
  on.exit(
    if (is.na(no_color)) {
      Sys.unsetenv("NO_COLOR")
    } else {
      Sys.setenv("NO_COLOR" = no_color)
    },
    add = TRUE
  )
  cli::ansi_strip(utils::capture.output(print(x, ...)))
}

test_that("the compact print shows the recorded rate only when it differs", {
  same <- set_metadata(single_track(), sampling_rate = 200)
  out <- print_lines(get_metadata(same))
  expect_true("sampling_rate: 200 Hz" %in% out)
  expect_false(any(grepl("source_sampling_rate|recorded", out)))

  resampled <- set_metadata(same, sampling_rate = 50)
  out <- print_lines(get_metadata(resampled))
  expect_true("sampling_rate: 50 Hz (recorded at 200 Hz)" %in% out)
  expect_false(any(grepl("source_sampling_rate", out)))
})

test_that("the compact print says when there is no fixed recorded rate", {
  af <- single_track() |>
    set_metadata(source_sampling_rate = NaN) |>
    set_metadata(sampling_rate = 100)
  out <- print_lines(get_metadata(af))
  expect_true("sampling_rate: 100 Hz (recorded with no fixed rate)" %in% out)

  # With no current rate, the recorded one has a line of its own.
  marker_only <- set_metadata(single_track(), source_sampling_rate = NaN)
  out <- print_lines(get_metadata(marker_only))
  expect_true("source_sampling_rate: no fixed rate" %in% out)
  expect_false(any(grepl("Not set:.*source_sampling_rate", out)))

  recorded_only <- set_metadata(single_track(), source_sampling_rate = 200)
  out <- print_lines(get_metadata(recorded_only))
  expect_true("source_sampling_rate: 200 Hz" %in% out)
})

test_that("all = TRUE prints the recorded rate on its own line", {
  af <- set_metadata(single_track(), sampling_rate = 200) |>
    set_metadata(sampling_rate = 50)
  out <- print_lines(get_metadata(af), all = TRUE)

  expect_true("source_sampling_rate: 200 Hz" %in% out)
  expect_true("sampling_rate: 50 Hz" %in% out)
})

test_that("the frame header shows the recorded rate when it differs", {
  af <- set_metadata(single_track(), sampling_rate = 200) |>
    set_metadata(sampling_rate = 50)
  expect_equal(
    tbl_sum(af)[["Sampling rate"]],
    "50 Hz (recorded at 200 Hz)"
  )

  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = c("REM", "wake"),
    start = c(30, 150),
    stop = c(60, 300)
  ) |>
    set_metadata(sampling_rate = 30)
  expect_equal(tbl_sum(ae)[["Sampling rate"]], "30 Hz")
  expect_null(format_sampling_rate(get_metadata(single_track())))
})
