# Angle primitives, moved from anispace (#128).

test_that("unwrap_angle correctly unwraps continuous angles", {
  # Nothing to unwrap
  x <- c(0, 0.1, 0.2, 0.3)
  expect_equal(unwrap_angle(x), x)

  # Wraps around 2*pi -> 0
  x <- c(3 * pi / 2, 7 * pi / 4, 2 * pi - 0.1, 0.1)
  result <- unwrap_angle(x)
  expect_true(all(diff(result) > 0))
})

test_that("unwrap_angle handles NA at start", {
  x <- c(NA, 0.1, 0.2, 0.3)
  result <- unwrap_angle(x)

  expect_true(is.na(result[1]))
  expect_equal(result[2:4], c(0.1, 0.2, 0.3))
})

test_that("unwrap_angle handles NA in middle", {
  x <- c(0.1, 0.2, NA, 0.4, 0.5)
  result <- unwrap_angle(x)

  expect_equal(result[1:2], c(0.1, 0.2))
  expect_true(is.na(result[3]))
  expect_false(is.na(result[4]))
  expect_false(is.na(result[5]))
})

test_that("unwrap_angle handles NA at end", {
  x <- c(0.1, 0.2, 0.3, NA)
  result <- unwrap_angle(x)

  expect_equal(result[1:3], c(0.1, 0.2, 0.3))
  expect_true(is.na(result[4]))
})

test_that("unwrap_angle handles multiple NAs", {
  x <- c(0.1, NA, 0.3, NA, 0.5)
  result <- unwrap_angle(x)

  expect_false(is.na(result[1]))
  expect_true(is.na(result[2]))
  expect_false(is.na(result[3]))
  expect_true(is.na(result[4]))
  expect_false(is.na(result[5]))
})

test_that("unwrap_angle handles all NA input", {
  x <- c(NA_real_, NA_real_, NA_real_)
  result <- unwrap_angle(x)

  expect_length(result, 3)
  expect_true(all(is.na(result)))
})

test_that("unwrap_angle handles empty vector", {
  result <- unwrap_angle(numeric(0))
  expect_length(result, 0)
})

test_that("unwrap_angle handles single element", {
  expect_equal(unwrap_angle(0.5), 0.5)
  expect_true(is.na(unwrap_angle(NA_real_)))
})

test_that("unwrap_angle preserves monotonicity across 2*pi boundary", {
  x <- c(5.5, 6.0, 6.2, 0.1, 0.3)
  result <- unwrap_angle(x)

  expect_true(all(diff(result) > 0))

  expect_true(result[5] > 2 * pi)
})

test_that("wrap_angle() wraps angles to [0, 2pi)", {
  expect_equal(wrap_angle(0), 0)
  expect_equal(wrap_angle(2 * pi), 0)
  expect_equal(wrap_angle(-pi / 2), 3 * pi / 2)
  expect_equal(wrap_angle(3 * pi), pi)
  expect_equal(wrap_angle(4 * pi), 0)
  expect_equal(wrap_angle(5 * pi / 2), pi / 2)
})

test_that("wrap_angle() is vectorised", {
  input <- c(-pi / 2, 0, pi / 2, pi, 3 * pi / 2, 2 * pi)
  expected <- c(3 * pi / 2, 0, pi / 2, pi, 3 * pi / 2, 0)
  expect_equal(wrap_angle(input), expected)
})

test_that('wrap_angle("asis") leaves the angles alone', {
  angles <- c(-pi, 0, pi, 3 * pi)

  expect_equal(wrap_angle(angles, "asis"), angles)
})

test_that("the degree converters round-trip", {
  expect_equal(rad_to_deg(pi), 180)
  expect_equal(deg_to_rad(180), pi)
  expect_equal(deg_to_rad(rad_to_deg(c(0, 1, 2))), c(0, 1, 2))
})

# Converting between radians and a frame's unit (#170) ------------------------

test_that("angle_from_rad() and angle_to_rad() follow a degree frame", {
  af <- set_metadata(
    example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1),
    unit_angle = "deg"
  )

  expect_equal(angle_from_rad(c(0, pi / 2, -pi), af), c(0, 90, -180))
  expect_equal(angle_to_rad(c(0, 90, -180), af), c(0, pi / 2, -pi))
})

test_that("a radian frame is left as it is", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
  expect_equal(as.character(get_metadata(af, "unit_angle")), "rad")

  expect_equal(angle_from_rad(c(0, 1, NA), af), c(0, 1, NA))
  expect_equal(angle_to_rad(c(0, 1, NA), af), c(0, 1, NA))
})

test_that("the unit can be given as a string or a factor", {
  expect_equal(angle_from_rad(pi, "deg"), 180)
  expect_equal(angle_to_rad(180, "deg"), pi)
  expect_equal(angle_from_rad(pi, "rad"), pi)
  expect_equal(angle_to_rad(180, factor("deg")), pi)
})

test_that("no declared angular unit is read as radians", {
  expect_equal(angle_from_rad(pi, "none"), pi)
  expect_equal(angle_to_rad(pi, "none"), pi)

  # An anievent has no spatial metadata at all
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )
  expect_null(get_metadata(ae, "unit_angle"))
  expect_equal(angle_from_rad(pi, ae), pi)
})

test_that("an unknown unit is an error", {
  expect_error(angle_to_rad(1, "turns"), "must be an aniframe or one of")
  expect_error(angle_from_rad(1, c("rad", "deg")), "must be an aniframe")
  expect_error(angle_from_rad(1, NULL), "must be an aniframe")
})

test_that("rates convert like angles", {
  # 1 rad/s is 180/pi deg/s
  expect_equal(angle_from_rad(1, "deg"), 180 / pi)
})
