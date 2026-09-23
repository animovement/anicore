test_that("example_anipoint errors when n_keypoints > 11", {
  expect_error(
    example_anipoint(n_keypoints = 12),
    "n_keypoints.*must be at most 11"
  )
})

test_that("example_anipoint errors when n_dims is invalid", {
  expect_error(
    example_anipoint(n_dims = 4),
    "n_dims.*must be 1, 2, or 3"
  )

  expect_error(
    example_anipoint(n_dims = 0),
    "n_dims.*must be 1, 2, or 3"
  )
})

test_that("example_anipoint creates aniframe with default parameters", {
  result <- example_anipoint()

  expect_s3_class(result, "aniframe")
  expect_true(all(
    c(
      "individual",
      "keypoint",
      "session",
      "trial",
      "time",
      "x",
      "y",
      "confidence"
    ) %in%
      names(result)
  ))
})

test_that("example_anipoint has correct dimensions with defaults", {
  result <- example_anipoint()

  # Default: 50 obs * 3 individuals * 11 keypoints * 1 trial * 1 session
  expected_rows <- 50 * 3 * 11 * 1 * 1
  expect_equal(nrow(result), expected_rows)
})

test_that("example_anipoint uses centroid when n_keypoints is 1", {
  result <- example_anipoint(n_keypoints = 1)

  expect_equal(levels(result$keypoint), "centroid")
  expect_true(all(result$keypoint == "centroid"))
})
test_that("example_anipoint uses anatomical keypoints when n_keypoints > 1", {
  result <- example_anipoint(n_keypoints = 3)

  expect_equal(levels(result$keypoint), c("head", "neck", "shoulder_right"))
})

test_that("example_anipoint creates 1D data with only x", {
  result <- example_anipoint(n_dims = 1)

  expect_true("x" %in% names(result))
  expect_false("y" %in% names(result))
  expect_false("z" %in% names(result))
  expect_equal(get_variables_where(result), "x")
})

test_that("example_anipoint creates 2D data with x and y", {
  result <- example_anipoint(n_dims = 2)

  expect_true(all(c("x", "y") %in% names(result)))
  expect_false("z" %in% names(result))
  expect_equal(get_variables_where(result), c("x", "y"))
})

test_that("example_anipoint creates 3D data with x, y, and z", {
  result <- example_anipoint(n_dims = 3)

  expect_true(all(c("x", "y", "z") %in% names(result)))
  expect_equal(
    get_variables_where(result),
    c("x", "y", "z")
  )
})

test_that("example_anipoint creates correct number of rows", {
  result <- example_anipoint(
    n_obs = 10,
    n_individuals = 2,
    n_keypoints = 3,
    n_trials = 2,
    n_sessions = 2
  )

  expected_rows <- 10 * 2 * 3 * 2 * 2
  expect_equal(nrow(result), expected_rows)
})

test_that("example_anipoint respects n_trials and n_sessions", {
  result <- example_anipoint(
    n_obs = 5,
    n_individuals = 1,
    n_keypoints = 1,
    n_trials = 3,
    n_sessions = 2
  )

  expect_equal(length(unique(result$trial)), 3)
  expect_equal(length(unique(result$session)), 2)
})

test_that("example_anipoint sets correct metadata variables", {
  result <- example_anipoint()

  expect_equal(get_variables_what(result), c("individual", "keypoint"))
  expect_equal(
    get_variables_when(result),
    # The index is declared separately and is not temporal *context*.
    c("session", "trial")
  )
})
