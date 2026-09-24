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
