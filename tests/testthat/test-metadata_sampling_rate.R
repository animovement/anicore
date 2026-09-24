# Test set_sampling_rate ----

test_that("set_sampling_rate converts frames to seconds with correct calibration", {
  # Create test data in frames
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    y = c(15, 25, 35),
    time = c(0, 30, 60)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame")

  # Set sampling rate to 30 Hz (30 frames per second)
  result <- set_sampling_rate(data, sampling_rate = 30)

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "unit_time") |> as.character(), "s")
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("set_sampling_rate works with 'unknown' unit_time", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 50, 100)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "unknown")

  # Set sampling rate to 50 Hz
  result <- set_sampling_rate(data, sampling_rate = 50)

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "unit_time") |> as.character(), "s")
  expect_equal(get_metadata(result, "sampling_rate"), 50)
})

test_that("set_sampling_rate handles different sampling rates correctly", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 60, 120)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame")

  # Set sampling rate to 60 Hz
  result <- set_sampling_rate(data, sampling_rate = 60)

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "sampling_rate"), 60)
})

test_that("set_sampling_rate updates metadata only when unit_time is SI unit", {
  # Create test data already in seconds
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 1, 2)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "s")

  expect_message(
    result <- set_sampling_rate(data, sampling_rate = 30),
    "unit_time is already set to a SI unit"
  )

  # Time values should remain unchanged
  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "unit_time") |> as.character(), "s")
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("set_sampling_rate updates metadata only for milliseconds", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 1000, 2000)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "ms")

  expect_message(
    result <- set_sampling_rate(data, sampling_rate = 100),
    "unit_time is already set to a SI unit"
  )

  expect_equal(result$time, c(0, 1000, 2000))
  expect_equal(get_metadata(result, "unit_time") |> as.character(), "ms")
  expect_equal(get_metadata(result, "sampling_rate"), 100)
})

test_that("set_sampling_rate updates metadata only for minutes", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 1, 2)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "m")

  expect_message(
    result <- set_sampling_rate(data, sampling_rate = 1),
    "unit_time is already set to a SI unit"
  )

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "sampling_rate"), 1)
})

test_that("set_sampling_rate updates metadata only for hours", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 1, 2)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "h")

  expect_message(
    result <- set_sampling_rate(data, sampling_rate = 0.5),
    "unit_time is already set to a SI unit"
  )

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "sampling_rate"), 0.5)
})

test_that("set_sampling_rate preserves all columns", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    y = c(15, 25, 35),
    z = c(5, 10, 15),
    time = c(0, 30, 60),
    id = c("a", "b", "c"),
    value = c(100, 200, 300)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame")

  result <- set_sampling_rate(data, sampling_rate = 30)

  expect_equal(result$x, c(10, 20, 30))
  expect_equal(result$y, c(15, 25, 35))
  expect_equal(result$z, c(5, 10, 15))
  expect_equal(result$id, c("a", "b", "c"))
  expect_equal(result$value, c(100, 200, 300))
})

test_that("set_sampling_rate handles fractional frame values", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 15, 30)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame")

  # Set sampling rate to 30 Hz
  result <- set_sampling_rate(data, sampling_rate = 30)

  expect_equal(result$time, c(0, 0.5, 1))
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("set_sampling_rate works with high sampling rates", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 1000, 2000)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame")

  # Set sampling rate to 1000 Hz
  result <- set_sampling_rate(data, sampling_rate = 1000)

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "sampling_rate"), 1000)
})

test_that("set_sampling_rate works with low sampling rates", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 1, 2)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame")

  # Set sampling rate to 1 Hz
  result <- set_sampling_rate(data, sampling_rate = 1)

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "sampling_rate"), 1)
})

test_that("set_sampling_rate can update sampling_rate multiple times", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 30, 60)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame", sampling_rate = 60)

  # Update to new sampling rate
  result <- set_sampling_rate(data, sampling_rate = 30)

  expect_equal(result$time, c(0, 1, 2))
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("set_sampling_rate returns aniframe object", {
  data <- dplyr::tibble(
    x = c(10, 20, 30),
    time = c(0, 30, 60)
  ) |>
    as_anipoint() |>
    set_metadata(unit_time = "frame")

  result <- set_sampling_rate(data, sampling_rate = 30)

  expect_true(inherits(result, "aniframe"))
})
