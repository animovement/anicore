# Turning an axis over on a frame that stores angles (#134)
#
# No column carries the axis, but the angles are measured from it. The
# reference for every case is the Cartesian round trip: map out, negate the
# axis, map back.

polar_frame <- function(rho, phi, unit_angle = "rad") {
  af <- as_anipoint(
    data.frame(
      individual = "a",
      time = seq_along(rho),
      rho = rho,
      phi = phi
    )
  )
  af <- set_metadata(af, unit_angle = unit_angle)
  set_axis_directions(af, c(x = "right", y = "up"))
}

reference_phi <- function(rho, phi, negate) {
  x <- rho * cos(phi)
  y <- rho * sin(phi)
  if (identical(negate, "x")) {
    x <- -x
  } else {
    y <- -y
  }
  atan2(y, x) %% (2 * pi)
}


# phi ----

test_that("turning y over negates phi", {
  af <- polar_frame(rep(1, 4), c(0, pi / 2, pi, 3 * pi / 2))

  expect_equal(
    set_axis_directions(af, c(y = "down"))$phi,
    c(0, 3 * pi / 2, pi, pi / 2)
  )
})

test_that("turning x over takes the supplement of phi", {
  af <- polar_frame(rep(1, 4), c(0, pi / 2, pi, 3 * pi / 2))

  expect_equal(
    set_axis_directions(af, c(x = "left"))$phi,
    c(pi, pi / 2, 0, 3 * pi / 2)
  )
})

test_that("both agree with negating the axis in Cartesian coordinates", {
  set.seed(1)
  rho <- runif(20, 0.5, 3)
  phi <- runif(20, 0, 2 * pi)
  af <- polar_frame(rho, phi)

  expect_equal(
    set_axis_directions(af, c(x = "left"))$phi,
    reference_phi(rho, phi, "x")
  )
  expect_equal(
    set_axis_directions(af, c(y = "down"))$phi,
    reference_phi(rho, phi, "y")
  )
})

test_that("turning an axis over twice gives the angles back", {
  set.seed(2)
  phi <- runif(20, 0, 2 * pi)
  af <- polar_frame(rep(1, 20), phi)

  there_and_back <- af |>
    set_axis_directions(c(y = "down")) |>
    set_axis_directions(c(y = "up"))

  expect_equal(there_and_back$phi, phi)
})

test_that("rho is a distance and never moves", {
  af <- polar_frame(c(1, 2, 3), c(0, 1, 2))

  expect_equal(set_axis_directions(af, c(y = "down"))$rho, c(1, 2, 3))
})


# The range and unit the frame keeps its angles in ----

test_that("angles in degrees are reflected in degrees", {
  af <- polar_frame(rep(1, 4), c(0, 90, 180, 270), unit_angle = "deg")

  expect_equal(set_axis_directions(af, c(y = "down"))$phi, c(0, 270, 180, 90))
  expect_equal(set_axis_directions(af, c(x = "left"))$phi, c(180, 90, 0, 270))
})

test_that("a frame keeping phi signed gets signed angles back", {
  af <- polar_frame(rep(1, 4), c(-pi / 2, -pi / 4, pi / 4, pi / 2))

  expect_equal(
    set_axis_directions(af, c(y = "down"))$phi,
    c(pi / 2, pi / 4, -pi / 4, -pi / 2)
  )
})


# theta ----

spherical_frame <- function(theta) {
  af <- as_anipoint(
    data.frame(
      individual = "a",
      time = seq_along(theta),
      rho = rep(1, length(theta)),
      phi = rep(0, length(theta)),
      theta = theta
    )
  )
  set_axis_directions(af, c(x = "right", y = "up", z = "back"))
}

test_that("turning z over takes the supplement of theta", {
  af <- spherical_frame(c(0, pi / 4, pi / 2, pi))

  expect_equal(
    set_axis_directions(af, c(z = "forward"))$theta,
    c(pi, 3 * pi / 4, pi / 2, 0)
  )
})

test_that("theta is a colatitude and is not wrapped onto a full turn", {
  # Wrapping the supplement as a bearing would send 0 to pi and pi to pi,
  # which is a different function.
  af <- spherical_frame(c(0, pi))

  expect_equal(set_axis_directions(af, c(z = "forward"))$theta, c(pi, 0))
})

test_that("turning z over leaves phi alone", {
  af <- spherical_frame(c(0, pi / 4, pi / 2, pi))

  expect_equal(set_axis_directions(af, c(z = "forward"))$phi, af$phi)
})

test_that("turning x or y over leaves theta alone", {
  af <- spherical_frame(c(0, pi / 4, pi / 2, pi))

  expect_equal(set_axis_directions(af, c(y = "down"))$theta, af$theta)
})


# What still has nothing to do, and what still refuses ----

test_that("a polar frame has no theta, so turning z over changes nothing", {
  af <- polar_frame(c(1, 2, 3), c(0, 1, 2))

  expect_equal(set_axis_directions(af, c(z = "back"))$phi, af$phi)
})

test_that("an extent puts the mirror somewhere rho would have to express", {
  af <- set_axis_extents(polar_frame(c(1, 2, 3), c(0, 1, 2)), c(y = 10))

  expect_error(
    set_axis_directions(af, c(y = "down")),
    "distance from the origin"
  )
})

test_that("clearing the extent lets the axis turn over about the origin", {
  af <- set_axis_extents(polar_frame(c(1, 2, 3), c(0, 1, 2)), c(y = 10))
  af <- set_axis_extents(af, c(y = NA))

  expect_no_error(set_axis_directions(af, c(y = "down")))
})

test_that("the handedness follows the angles round", {
  af <- polar_frame(rep(1, 3), c(0, 1, 2))
  af <- set_axis_directions(af, c(z = "back"))

  expect_equal(get_handedness(af), "right")
  expect_equal(get_handedness(set_axis_directions(af, c(y = "down"))), "left")
})
