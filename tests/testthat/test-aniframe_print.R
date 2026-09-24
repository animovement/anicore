# Test outline for tbl_sum.anipoint():
#
# Behaviour:
#   - includes "Individuals" only when the individual column is present
#   - includes "Keypoints" only when the keypoint column is present
#   - includes "Sessions" / "Trials" only when those columns are present
#   - includes "Sampling rate" only when set in metadata
#   - includes "Time" interval (HH:MM:SS) when unit_time is convertible to
#     seconds (issue #50)
#   - "Time" interval becomes absolute datetimes when start_datetime is set
#   - "Time" row is omitted when unit_time = "frame" without sampling_rate
#     (or unit_time = "unknown")
#
# Regression:
#   - does not warn "Unknown or uninitialised column" when `individual` is
#     absent (issue #51)

test_that("tbl_sum omits Individuals row when individual column is absent", {
  df <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 1:5
  )
  data <- as_anipoint(df)

  result <- pillar::tbl_sum(data)

  expect_false("Individuals" %in% names(result))
  expect_true("Keypoints" %in% names(result))
})

test_that("tbl_sum does not warn when individual column is absent", {
  df <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 1:5
  )
  data <- as_anipoint(df)

  expect_no_warning(pillar::tbl_sum(data))
  expect_no_warning(format(data))
})

test_that("tbl_sum includes Individuals when individual column is present", {
  data <- example_anipoint(n_individuals = 2, n_keypoints = 3)

  result <- pillar::tbl_sum(data)

  expect_true("Individuals" %in% names(result))
  expect_true("Keypoints" %in% names(result))
})

test_that("tbl_sum includes Sessions and Trials only when present", {
  data <- example_anipoint(n_sessions = 2, n_trials = 3)
  result <- pillar::tbl_sum(data)
  expect_true("Sessions" %in% names(result))
  expect_true("Trials" %in% names(result))

  data_no_session <- example_anipoint(n_sessions = 1, n_trials = 1) |>
    dplyr::ungroup() |>
    dplyr::select(-dplyr::any_of(c("session", "trial"))) |>
    suppressWarnings()
  result_no_session <- pillar::tbl_sum(data_no_session)
  expect_false("Sessions" %in% names(result_no_session))
  expect_false("Trials" %in% names(result_no_session))
})

test_that("tbl_sum includes Sampling rate only when set in metadata", {
  data <- example_anipoint()
  result <- pillar::tbl_sum(data)
  expect_false("Sampling rate" %in% names(result))

  data_with_sr <- set_metadata(data, sampling_rate = 60)
  result_with_sr <- pillar::tbl_sum(data_with_sr)
  expect_true("Sampling rate" %in% names(result_with_sr))
  expect_equal(unname(result_with_sr["Sampling rate"]), "60 Hz")
})

test_that("tbl_sum omits Time row when unit_time = 'frame' and no sampling rate", {
  data <- example_anipoint(n_obs = 10) # default unit_time is "frame", no sr

  result <- pillar::tbl_sum(data)

  expect_false("Time" %in% names(result))
})

test_that("tbl_sum includes Time row when unit_time = 'frame' and sampling rate set", {
  # 90 frames @ 30 Hz -> 0..89 frames -> 0..2.9667s -> rounds to 00:00:00 / 00:00:03
  data <- example_anipoint(n_obs = 90)
  data <- set_metadata(data, sampling_rate = 30)

  result <- pillar::tbl_sum(data)

  expect_true("Time" %in% names(result))
  expect_equal(unname(result["Time"]), "00:00:00 to 00:00:03")
})

test_that("tbl_sum formats Time interval as HH:MM:SS for unit_time = 's'", {
  df <- data.frame(
    individual = 1L,
    time = seq(0, 3725, length.out = 10), # 1h 02m 05s span
    x = 1:10,
    y = 1:10
  )
  data <- as_anipoint(df)
  data <- set_metadata(data, unit_time = "s")

  result <- pillar::tbl_sum(data)

  expect_true("Time" %in% names(result))
  expect_equal(unname(result["Time"]), "00:00:00 to 01:02:05")
})

test_that("tbl_sum formats Time as absolute datetimes when start_datetime is set", {
  df <- data.frame(
    individual = 1L,
    time = seq(0, 90, length.out = 5), # 90 seconds
    x = 1:5,
    y = 1:5
  )
  data <- as_anipoint(df)
  data <- set_metadata(
    data,
    unit_time = "s",
    start_datetime = "2024-01-15 14:30:00"
  )

  result <- pillar::tbl_sum(data)

  expect_true("Time" %in% names(result))
  # The expected start datetime is the literal value passed; the end is
  # 90 seconds later. Format uses "%Y-%m-%d %H:%M:%S" with system tz.
  start_dt <- anytime::anytime("2024-01-15 14:30:00")
  expected <- paste(
    format(start_dt, "%Y-%m-%d %H:%M:%S"),
    "to",
    format(start_dt + 90, "%Y-%m-%d %H:%M:%S")
  )
  expect_equal(unname(result["Time"]), expected)
})

test_that("format_seconds_as_hms produces expected integer formats", {
  expect_equal(format_seconds_as_hms(0), "00:00:00")
  expect_equal(format_seconds_as_hms(59), "00:00:59")
  expect_equal(format_seconds_as_hms(60), "00:01:00")
  expect_equal(format_seconds_as_hms(3725), "01:02:05")
  expect_equal(format_seconds_as_hms(3600 * 25), "25:00:00") # > 24h is fine
})

test_that("format_seconds_as_hms produces expected fractional (ms) formats", {
  expect_equal(format_seconds_as_hms(0, fractional = TRUE), "00:00:00.000")
  expect_equal(format_seconds_as_hms(0.088, fractional = TRUE), "00:00:00.088")
  expect_equal(format_seconds_as_hms(0.5, fractional = TRUE), "00:00:00.500")
  expect_equal(format_seconds_as_hms(60, fractional = TRUE), "00:01:00.000")
  expect_equal(
    format_seconds_as_hms(3725.123, fractional = TRUE),
    "01:02:05.123"
  )
})

test_that("tbl_sum Time row uses millisecond precision when span is sub-second", {
  # Recording lasts only 88 ms
  df <- data.frame(
    individual = 1L,
    time = c(0, 50, 88),
    x = 1:3,
    y = 1:3
  )
  data <- as_anipoint(df) |> set_metadata(unit_time = "ms")

  result <- pillar::tbl_sum(data)

  expect_true("Time" %in% names(result))
  expect_equal(unname(result["Time"]), "00:00:00.000 to 00:00:00.088")
})

test_that("tbl_sum Time row uses integer precision when span >= 1 second", {
  df <- data.frame(
    individual = 1L,
    time = c(0, 1500),
    x = 1:2,
    y = 1:2
  )
  data <- as_anipoint(df) |> set_metadata(unit_time = "ms")

  result <- pillar::tbl_sum(data)

  # 0 ms .. 1500 ms span = 1.5 s, not sub-second -> integer hms
  expect_equal(unname(result["Time"]), "00:00:00 to 00:00:02")
})

test_that("compute_seconds_per_time_unit returns expected multipliers", {
  expect_equal(compute_seconds_per_time_unit("s", NA), 1)
  expect_equal(compute_seconds_per_time_unit("ms", NA), 1e-3)
  expect_equal(compute_seconds_per_time_unit("us", NA), 1e-6)
  expect_equal(compute_seconds_per_time_unit("ns", NA), 1e-9)
  expect_equal(compute_seconds_per_time_unit("m", NA), 60)
  expect_equal(compute_seconds_per_time_unit("h", NA), 3600)
  expect_equal(compute_seconds_per_time_unit("frame", 30), 1 / 30)
  expect_true(is.na(compute_seconds_per_time_unit("frame", NA)))
  expect_true(is.na(compute_seconds_per_time_unit("frame", 0)))
  expect_true(is.na(compute_seconds_per_time_unit("unknown", 30)))
})

test_that("format_seconds_as_hms handles negative seconds with a leading minus", {
  expect_equal(format_seconds_as_hms(-30), "-00:00:30")
  expect_equal(format_seconds_as_hms(-3725), "-01:02:05")
  expect_equal(
    format_seconds_as_hms(-0.5, fractional = TRUE),
    "-00:00:00.500"
  )
})

test_that("format_time_interval returns NULL when time column is absent", {
  data <- example_anipoint()
  md <- get_metadata(data)
  data$time <- NULL
  expect_null(format_time_interval(data, md))
})

test_that("format_time_interval returns NULL when time has no finite values", {
  data <- example_anipoint()
  md <- get_metadata(data)
  data$time <- rep(NA_real_, nrow(data))
  expect_null(format_time_interval(data, md))
})

test_that("tbl_sum Time row uses sub-second datetime format with start_datetime", {
  # Sub-second span + start_datetime exercises the "%Y-%m-%d %H:%M:%OS3"
  # format branch.
  df <- data.frame(
    individual = 1L,
    time = c(0, 22, 88),
    x = 1:3,
    y = 1:3
  )
  data <- as_anipoint(df) |>
    set_metadata(
      unit_time = "ms",
      start_datetime = "2024-01-15 14:30:00"
    )

  result <- pillar::tbl_sum(data)

  expect_true("Time" %in% names(result))
  # Output includes ".XXX" millisecond fragment in both endpoints
  expect_match(unname(result["Time"]), "\\.\\d{3}.* to .*\\.\\d{3}")
})
