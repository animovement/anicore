test_that("anipoint() accepts a single data.frame as the only positional arg", {
  df <- data.frame(
    individual = 1L,
    time = 1:3,
    x = 1:3,
    y = 1:3
  )
  result <- anipoint(df)
  expect_s3_class(result, "aniframe")
  expect_equal(nrow(result), 3)
})

test_that("anipoint() accepts loose name=value pairs", {
  result <- anipoint(
    individual = 1L,
    time = 1:3,
    x = 1:3,
    y = 1:3
  )
  expect_s3_class(result, "aniframe")
  expect_equal(nrow(result), 3)
})
