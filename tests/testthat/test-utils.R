# convert_nan_to_na(), rad_to_deg() and deg_to_rad()

test_that("convert_nan_to_na converts NaN to NA in numeric columns", {
  df <- data.frame(
    x = c(1, NaN, 3),
    y = c(NaN, 5, 6)
  )

  result <- convert_nan_to_na(df)

  expect_true(is.na(result$x[2]))
  expect_true(is.na(result$y[1]))
  expect_false(is.nan(result$x[2]))
  expect_false(is.nan(result$y[1]))
})

test_that("convert_nan_to_na leaves existing NA values unchanged", {
  df <- data.frame(
    x = c(1, NA, 3),
    y = c(NA, 5, NaN)
  )

  result <- convert_nan_to_na(df)

  expect_true(is.na(result$x[2]))
  expect_true(is.na(result$y[1]))
  expect_true(is.na(result$y[3]))
})

test_that("convert_nan_to_na leaves non-numeric columns unchanged", {
  df <- data.frame(
    x = c(1, NaN, 3),
    char = c("a", "b", "c"),
    lgl = c(TRUE, FALSE, TRUE)
  )

  result <- convert_nan_to_na(df)

  expect_equal(result$char, df$char)
  expect_equal(result$lgl, df$lgl)
  expect_true(is.na(result$x[2]))
})

test_that("convert_nan_to_na handles data frames with no numeric columns", {
  df <- data.frame(
    char = c("a", "b", "c"),
    lgl = c(TRUE, FALSE, TRUE)
  )

  result <- convert_nan_to_na(df)

  expect_equal(result, df)
})

test_that("convert_nan_to_na handles empty data frames", {
  df <- data.frame()

  result <- convert_nan_to_na(df)

  expect_equal(result, df)
})

test_that("deg_to_rad() and rad_to_deg() are inverses of each other", {
  degrees <- c(0, 90, 180, 270, 360, -90)
  radians <- deg_to_rad(degrees)

  expect_equal(rad_to_deg(radians), degrees, tolerance = 1e-10)
  expect_equal(deg_to_rad(rad_to_deg(radians)), radians, tolerance = 1e-10)
})

test_that("deg_to_rad() converts correctly for key values", {
  expect_equal(deg_to_rad(0), 0)
  expect_equal(deg_to_rad(180), pi)
  expect_equal(deg_to_rad(90), pi / 2)
  expect_equal(deg_to_rad(270), 3 * pi / 2)
  expect_equal(deg_to_rad(360), 2 * pi, tolerance = 1e-10)
})

test_that("rad_to_deg() converts correctly for key values", {
  expect_equal(rad_to_deg(0), 0)
  expect_equal(rad_to_deg(pi / 2), 90)
  expect_equal(rad_to_deg(pi), 180)
  expect_equal(rad_to_deg(3 * pi / 2), 270)
  expect_equal(rad_to_deg(2 * pi), 360, tolerance = 1e-10)
})
