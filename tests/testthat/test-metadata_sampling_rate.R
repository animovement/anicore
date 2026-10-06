# Declaring a sampling rate, then converting frames to seconds ----

frame_data <- function(time, unit_time = "frame", ...) {
  dplyr::tibble(x = seq_along(time) * 10, time = time) |>
    as_anipoint() |>
    set_metadata(unit_time = unit_time, ...)
}

test_that("declaring sampling_rate leaves values and unit_time unchanged", {
  data <- frame_data(c(0, 30, 60))
  result <- set_metadata(data, sampling_rate = 30)

  expect_equal(result$time, c(0, 30, 60))
  expect_equal(as.character(get_metadata(result, "unit_time")), "frame")
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("convert_unit_time converts frames to seconds via the declared rate", {
  result <- frame_data(c(0, 30, 60)) |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s")

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("convert_unit_time scales by the declared rate", {
  rescale <- function(time, rate) {
    frame_data(time) |>
      set_metadata(sampling_rate = rate) |>
      convert_unit_time("s") |>
      dplyr::pull(time)
  }
  expect_equal(rescale(c(0, 60, 120), 60), c(0, 1, 2))
  expect_equal(rescale(c(0, 15, 30), 30), c(0, 0.5, 1))
  expect_equal(rescale(c(0, 1000, 2000), 1000), c(0, 1, 2))
  expect_equal(rescale(c(0, 1, 2), 1), c(0, 1, 2))
})

test_that("convert_unit_time uses the most recently declared rate", {
  result <- frame_data(c(0, 30, 60), sampling_rate = 60) |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s")

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("convert_unit_time from 'unknown' needs a calibration_factor", {
  data <- frame_data(c(0, 50, 100), unit_time = "unknown", sampling_rate = 50)
  expect_error(convert_unit_time(data, "s"), "calibration_factor")

  result <- convert_unit_time(data, "s", calibration_factor = 1 / 50)
  expect_equal(result$time, c(0, 1, 2))
})

test_that("declaring sampling_rate on an SI-unit frame leaves values unchanged", {
  for (unit in c("s", "ms", "m", "h")) {
    result <- frame_data(c(0, 1, 2), unit_time = unit) |>
      set_metadata(sampling_rate = 30)
    expect_equal(result$time, c(0, 1, 2))
    expect_equal(as.character(get_metadata(result, "unit_time")), unit)
    expect_equal(get_metadata(result, "sampling_rate"), 30)
  }
})

test_that("convert_unit_time preserves other columns and the class", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    y = c(15, 25, 35),
    z = c(5, 10, 15),
    time = c(0, 30, 60),
    id = c("a", "b", "c"),
    value = c(100, 200, 300)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame", sampling_rate = 30)

  result <- convert_unit_time(data, "s")

  expect_true(inherits(result, "aniframe"))
  expect_equal(result$x, c(10, 20, 30))
  expect_equal(result$y, c(15, 25, 35))
  expect_equal(result$z, c(5, 10, 15))
  expect_equal(result$id, c("a", "b", "c"))
  expect_equal(result$value, c(100, 200, 300))
})


# Converting to frames, and the issue's worked examples (#190) ----

# A 300-frame single track, frames counted from 0.
single_track <- function(n = 300) {
  as_anipoint(data.frame(individual = "a", time = seq_len(n) - 1, x = 1, y = 1))
}

test_that("frames to seconds keeps the interval in step (example 3)", {
  af <- single_track() |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s")

  expect_equal(af$time, (0:299) / 30)
  expect_equal(get_sampling_interval(af), 1 / 30)
  expect_no_warning(validate_anipoint(af))
})

test_that("seconds convert back to frames with the declared rate (example 4)", {
  in_seconds <- single_track() |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s")

  frames <- convert_unit_time(in_seconds, "frame")

  expect_identical(frames$time, as.numeric(0:299))
  expect_equal(as.character(get_metadata(frames, "unit_time")), "frame")
  expect_equal(get_sampling_interval(frames), 1)
  expect_equal(get_metadata(frames, "sampling_rate"), 30)
})

test_that("a wrong rate is put right through frames (example 4)", {
  # The camera was really 25 fps, discovered after converting at 30.
  fixed <- single_track() |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s") |>
    convert_unit_time("frame") |>
    set_metadata(sampling_rate = 25) |>
    convert_unit_time("s")

  expect_equal(fixed$time, (0:299) / 25)
  expect_equal(get_sampling_interval(fixed), 1 / 25)
  expect_no_warning(validate_anipoint(fixed))
})

test_that("any SI unit converts to frames", {
  in_ms <- single_track(5) |>
    set_metadata(sampling_rate = 50) |>
    convert_unit_time("ms")
  expect_equal(in_ms$time, c(0, 20, 40, 60, 80))

  frames <- convert_unit_time(in_ms, "frame")
  expect_identical(frames$time, as.numeric(0:4))
})

test_that("converting to frames rounds to the nearest whole frame", {
  # Jitter well within 1% of a frame.
  af <- data.frame(
    individual = "a",
    time = (0:4) / 30 + c(0, 1e-5, -2e-5, 3e-5, 0),
    x = 1,
    y = 1
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "s", sampling_rate = 30)

  frames <- convert_unit_time(af, "frame")

  expect_identical(frames$time, as.numeric(0:4))
  expect_equal(get_sampling_interval(frames), 1)
})

test_that("converting to frames keeps dropped frames as gaps", {
  in_seconds <- single_track(10) |>
    dplyr::filter(!time %in% c(3, 4)) |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s")

  frames <- convert_unit_time(in_seconds, "frame")

  expect_identical(frames$time, as.numeric(c(0:2, 5:9)))
})

test_that("converting to frames refuses irregular sampling", {
  # Sampled at 25 Hz, declared 30 Hz: every gap is 1.2 frames.
  af <- data.frame(individual = "a", time = (0:9) / 25, x = 1, y = 1) |>
    as_anipoint() |>
    set_metadata(unit_time = "s", sampling_rate = 30)

  expect_error(convert_unit_time(af, "frame"), "sampling is irregular")
  expect_error(convert_unit_time(af, "frame"), "1.2 frames")
  # The rate that matches converts.
  fixed <- convert_unit_time(set_metadata(af, sampling_rate = 25), "frame")
  expect_identical(fixed$time, as.numeric(0:9))
})

test_that("converting to frames refuses to put two times on one frame", {
  # A log averaging 30.11 Hz drifts from a declared 30 Hz by a frame in 300.
  af <- data.frame(
    individual = "a",
    time = (0:299) / 30.11,
    x = 1,
    y = 1
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "s", sampling_rate = 30)

  expect_error(convert_unit_time(af, "frame"), "round to frame")
})

test_that("frames are computed within each key", {
  # Two keypoints at the same moments do not collide; nor does a second
  # individual whose times sit off the grid of the first.
  af <- data.frame(
    individual = rep(c("a", "b"), each = 6),
    keypoint = rep(c("head", "tail"), times = 6),
    time = c(rep((0:2) / 30, each = 2), rep((0:2) / 30 + 0.4 / 30, each = 2)),
    x = 1,
    y = 1
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "s", sampling_rate = 30)

  frames <- convert_unit_time(af, "frame")

  expect_setequal(frames$time, c(0, 1, 2))
  expect_equal(nrow(frames), 12L)
})

test_that("converting to frames uses recorded frame numbers in a frame column", {
  # A log averaging 30.11 Hz, with frame 3 dropped: too irregular to
  # compute frames from, but the recorded ones are kept.
  af <- data.frame(
    individual = "a",
    frame = c(0, 1, 2, 4, 5),
    timestamp = c(0, 1, 2, 4, 5) / 30.11,
    x = 1,
    y = 1
  ) |>
    as_anipoint(index = "timestamp") |>
    set_metadata(unit_time = "s", sampling_rate = 30)

  frames <- convert_unit_time(af, "frame")

  expect_equal(get_index(frames), "frame")
  expect_identical(frames$frame, c(0, 1, 2, 4, 5))
  expect_equal(as.character(get_metadata(frames, "unit_time")), "frame")
  expect_equal(get_sampling_interval(frames), 1)
  # The timestamps it replaces stay, as an ordinary column.
  expect_equal(frames$timestamp, c(0, 1, 2, 4, 5) / 30.11)
  expect_false("timestamp" %in% get_variables(frames, "when"))
})

test_that("recorded frame numbers need no rate and refuse a calibration_factor", {
  af <- data.frame(
    individual = "a",
    frame = c(0, 1, 2),
    timestamp = c(0, 0.5, 1),
    x = 1,
    y = 1
  ) |>
    as_anipoint(index = "timestamp") |>
    set_metadata(unit_time = "s")

  expect_identical(convert_unit_time(af, "frame")$frame, c(0, 1, 2))
  expect_error(
    convert_unit_time(af, "frame", calibration_factor = 2),
    "calibration_factor"
  )

  af$frame <- c("a", "b", "c")
  expect_error(convert_unit_time(af, "frame"), "must be numeric")
})

test_that("an anievent refuses irregular frames too", {
  ae <- frame_data(c(0, 0, 1, 1)) |>
    dplyr::mutate(b = factor(c("r", "r", "w", "w"))) |>
    set_variables(event = list(state = "b")) |>
    set_metadata(unit_time = "s", sampling_rate = 30) |>
    to_anievent() |>
    dplyr::mutate(stop = c(0.51 / 30, 1))

  expect_error(convert_unit_time(ae, "frame"), "start and stop")
})

test_that("converting a frame to itself needs no rate", {
  af <- single_track(3)

  expect_identical(convert_unit_time(af, "frame")$time, c(0, 1, 2))
})

test_that("an anievent converts to frames", {
  ae <- frame_data(c(0, 0, 30, 30)) |>
    dplyr::mutate(b = factor(c("r", "r", "w", "w"))) |>
    set_variables(event = list(state = "b")) |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s") |>
    to_anievent()

  result <- convert_unit_time(ae, "frame")

  expect_equal(as.character(get_metadata(result, "unit_time")), "frame")
  expect_true(all(result$start == round(result$start)))
  expect_true(all(result$stop == round(result$stop)))
})

# The rate check fits real timestamps (#190) ----

# A camera log: jittered, averaging 30.11 Hz, with frame 100 dropped.
logged_track <- function() {
  set.seed(190)
  stamps <- cumsum(c(0, rep(1 / 30.11, 299))) + stats::rnorm(300, 0, 1e-4)
  single_track() |>
    dplyr::filter(time != 100) |>
    dplyr::mutate(timestamp = stamps[time + 1]) |>
    set_index("timestamp", unit = "s") |>
    set_metadata(sampling_rate = 30)
}

test_that("a jittered timestamp log agrees with its nominal rate (example 6)", {
  af <- logged_track()

  expect_equal(1 / get_sampling_interval(af), 30.11, tolerance = 1e-3)
  expect_false(is_sampling_regular(af))
  expect_no_warning(validate_anipoint(af))
})

test_that("rate_tolerance makes the rate check strict", {
  expect_warning(
    validate_anipoint(logged_track(), rate_tolerance = 1e-6),
    "spaced 30.1 Hz"
  )
})

test_that("a rate more than 1% off still warns", {
  af <- set_metadata(logged_track(), sampling_rate = 29.5)

  expect_warning(validate_anipoint(af), "differ by more than 1%")
})

test_that("validate_anipoint() rejects a nonsense rate_tolerance", {
  af <- single_track(3)

  for (bad in list("a", c(0.1, 0.2), NA_real_, -1)) {
    expect_error(validate_anipoint(af, rate_tolerance = bad), "rate_tolerance")
  }
})
