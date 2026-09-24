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

test_that("convert_unit_time on a seconds anievent scales start and stop to ms", {
  ae <- make_seconds_anievent()
  result <- convert_unit_time(ae, "ms")

  expect_equal(result$start, c(1000, 5000))
  expect_equal(result$stop, c(2000, 10000))
  expect_equal(as.character(get_metadata(result, "unit_time")), "ms")
})

test_that("convert_unit_time on a frame anievent with no rate or calibration errors", {
  ae <- make_frame_anievent()
  expect_error(convert_unit_time(ae, "s"), "calibration_factor")
})

test_that("convert_unit_time rejects an unrecognised target unit", {
  ae <- make_seconds_anievent()
  expect_error(convert_unit_time(ae, "not_a_unit"), "can only be converted to")
})

test_that("convert_unit_time applies a custom calibration_factor on a frame anievent", {
  ae <- make_frame_anievent()
  result <- convert_unit_time(ae, "s", calibration_factor = 1 / 30)

  expect_equal(result$start, c(1, 5))
  expect_equal(result$stop, c(2, 10))
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
})

test_that("convert_unit_time on a frame anievent uses the declared sampling_rate", {
  result <- make_frame_anievent() |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s")

  expect_equal(result$start, c(1, 5))
  expect_equal(result$stop, c(2, 10))
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("declaring sampling_rate on an SI-unit anievent only updates metadata", {
  result <- set_metadata(make_seconds_anievent(), sampling_rate = 30)

  expect_equal(result$start, c(1, 5))
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})
