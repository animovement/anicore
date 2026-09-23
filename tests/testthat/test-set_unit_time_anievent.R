make_frame_anievent <- function(sampling_unit = "frame") {
  ae <- anievent(
    individual = 1L,
    channel = c("behaviour", "behaviour"),
    label = c("REM", "wake"),
    start = c(30, 150),
    stop = c(60, 300)
  )
  set_metadata(ae, unit_time = sampling_unit)
}

make_seconds_anievent <- function() {
  ae <- anievent(
    individual = 1L,
    channel = c("behaviour", "behaviour"),
    label = c("REM", "wake"),
    start = c(1, 5),
    stop = c(2, 10)
  )
  set_metadata(ae, unit_time = "s")
}

test_that("set_unit_time on a seconds anievent scales start and stop to ms", {
  ae <- make_seconds_anievent()
  result <- set_unit_time(ae, "ms")

  expect_equal(result$start, c(1000, 5000))
  expect_equal(result$stop, c(2000, 10000))
  expect_equal(as.character(get_metadata(result, "unit_time")), "ms")
})

test_that("set_unit_time on a frame anievent with no calibration leaves data unchanged but flips metadata", {
  ae <- make_frame_anievent()

  expect_message(
    result <- set_unit_time(ae, "s"),
    "calibration_factor is not set"
  )
  expect_equal(result$start, c(30, 150))
  expect_equal(result$stop, c(60, 300))
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
})

test_that("set_unit_time rejects an unrecognised target unit", {
  ae <- make_seconds_anievent()
  expect_error(set_unit_time(ae, "not_a_unit"), "Time unit can only be")
})

test_that("set_unit_time applies a custom calibration_factor on a frame anievent", {
  ae <- make_frame_anievent()
  result <- set_unit_time(ae, "s", calibration_factor = 1 / 30)

  expect_equal(result$start, c(1, 5))
  expect_equal(result$stop, c(2, 10))
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
})

test_that("set_sampling_rate on a frame anievent converts start/stop to seconds and stores sampling_rate", {
  ae <- make_frame_anievent()
  result <- set_sampling_rate(ae, 30)

  expect_equal(result$start, c(1, 5))
  expect_equal(result$stop, c(2, 10))
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("set_sampling_rate on an SI-unit anievent only updates metadata", {
  ae <- make_seconds_anievent()

  expect_message(
    result <- set_sampling_rate(ae, 30),
    "unit_time is already set to a SI unit"
  )
  expect_equal(result$start, c(1, 5)) # unchanged
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})
