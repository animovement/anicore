df <- data.frame(time = 1:5, x = 1:5, y = 1:5)

test_that("return FALSE for a non-aniframe", {
  expect_false(
    is_aniframe(df)
  )
})

test_that("as_anipoint works with minimal required columns", {
  result <- suppressMessages(as_anipoint(df))

  expect_true(
    is_aniframe(result)
  )
})
