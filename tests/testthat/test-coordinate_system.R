# Coordinate-system predicates
#
# These read `coordinate_system`, which is derived from the axis roles, so
# they follow the frame's declaration rather than its column names (#109).
# A helper keeps the frames terse.

spatial_af <- function(...) {
  cols <- list(...)
  as_anipoint(
    data.frame(time = 1:3, individual = "a", cols),
    variables_where = names(cols)
  )
}

test_that("is_cartesian() correctly identifies Cartesian coordinate systems", {
  expect_true(is_cartesian(spatial_af(x = 1:3, y = 2:4)))
  expect_true(is_cartesian(spatial_af(z = 1:3)))
  expect_false(is_cartesian(spatial_af(rho = 1:3, phi = 2:4)))
})

test_that("ensure_is_cartesian() aborts when data is not Cartesian", {
  expect_silent(ensure_is_cartesian(spatial_af(x = 1:3)))
  expect_error(
    ensure_is_cartesian(spatial_af(rho = 1:3, phi = 2:4)),
    "not in a Cartesian coordinate system"
  )
})

test_that("is_polar() correctly identifies polar coordinate systems", {
  expect_true(is_polar(spatial_af(rho = 1:3, phi = 2:4)))
  expect_false(is_polar(spatial_af(rho = 1:3, phi = 2:4, theta = 1:3)))
  expect_false(is_polar(spatial_af(x = 1:3, y = 2:4)))
})

test_that("ensure_is_polar() aborts when data is not polar", {
  expect_silent(ensure_is_polar(spatial_af(rho = 1:3, phi = 2:4)))
  expect_error(
    ensure_is_polar(spatial_af(x = 1:3, y = 2:4)),
    "not in a polar coordinate system"
  )
})

test_that("is_cylindrical() correctly identifies cylindrical coordinate systems", {
  expect_true(is_cylindrical(spatial_af(rho = 1:3, phi = 2:4, z = 1:3)))
  expect_false(is_cylindrical(spatial_af(rho = 1:3, phi = 2:4)))
  expect_false(is_cylindrical(spatial_af(x = 1:3, y = 2:4, z = 1:3)))
})

test_that("ensure_is_cylindrical() aborts when data is not cylindrical", {
  expect_silent(ensure_is_cylindrical(spatial_af(
    rho = 1:3,
    phi = 2:4,
    z = 1:3
  )))
  expect_error(
    ensure_is_cylindrical(spatial_af(rho = 1:3, phi = 2:4)),
    "not in a cylindrical coordinate system"
  )
})

test_that("is_spherical() correctly identifies spherical coordinate systems", {
  expect_true(is_spherical(spatial_af(rho = 1:3, phi = 2:4, theta = 1:3)))
  expect_false(is_spherical(spatial_af(rho = 1:3, phi = 2:4)))
  expect_false(is_spherical(spatial_af(x = 1:3, y = 2:4, z = 1:3)))
})

test_that("ensure_is_spherical() aborts when data is not spherical", {
  expect_silent(
    ensure_is_spherical(spatial_af(rho = 1:3, phi = 2:4, theta = 1:3))
  )
  expect_error(
    ensure_is_spherical(spatial_af(rho = 1:3, phi = 2:4)),
    "not in a spherical coordinate system"
  )
})


# 1D / 2D / 3D Cartesian ----

test_that("is_cartesian_1d() correctly identifies 1D Cartesian data", {
  expect_true(is_cartesian_1d(spatial_af(x = 1:3)))
  expect_true(is_cartesian_1d(spatial_af(z = 1:3)))
  expect_false(is_cartesian_1d(spatial_af(rho = 1:3, phi = 2:4)))
  expect_false(is_cartesian_1d(spatial_af(x = 1:3, y = 2:4)))
})

test_that("ensure_is_cartesian_1d() aborts when data isn't 1D Cartesian", {
  expect_silent(ensure_is_cartesian_1d(spatial_af(x = 1:3)))
  expect_error(
    ensure_is_cartesian_1d(spatial_af(x = 1:3, y = 2:4)),
    "1D Cartesian"
  )
})

test_that("is_cartesian_2d() correctly identifies 2D Cartesian data", {
  expect_true(is_cartesian_2d(spatial_af(x = 1:3, y = 2:4)))
  expect_false(is_cartesian_2d(spatial_af(x = 1:3, y = 2:4, z = 1:3)))
  expect_false(is_cartesian_2d(spatial_af(x = 1:3)))
})

test_that("ensure_is_cartesian_2d() aborts when data isn't 2D Cartesian", {
  expect_silent(ensure_is_cartesian_2d(spatial_af(x = 1:3, y = 2:4)))
  expect_error(
    ensure_is_cartesian_2d(spatial_af(x = 1:3, y = 2:4, z = 1:3)),
    "2D Cartesian"
  )
})

test_that("is_cartesian_3d() correctly identifies 3D Cartesian data", {
  expect_true(is_cartesian_3d(spatial_af(x = 1:3, y = 2:4, z = 1:3)))
  expect_false(is_cartesian_3d(spatial_af(x = 1:3, y = 2:4)))
})

test_that("ensure_is_cartesian_3d() aborts when data isn't 3D Cartesian", {
  expect_silent(ensure_is_cartesian_3d(spatial_af(x = 1:3, y = 2:4, z = 1:3)))
  expect_error(
    ensure_is_cartesian_3d(spatial_af(x = 1:3, y = 2:4)),
    "3D Cartesian"
  )
})


# The predicates follow the declaration, not the column names (#109) ----

test_that("a renamed frame satisfies the predicate for its coordinate system", {
  # This is the point of axis roles: the frame is polar, so every spatial
  # function that gates on `ensure_is_polar()` must accept it.
  af <- as_anipoint(
    data.frame(time = 1:3, individual = "a", rr = c(1, 2, 3), aa = c(0, 1, 2)),
    variables_where = c(rho = "rr", phi = "aa")
  )

  expect_equal(get_coordinate_system(af), "polar")
  expect_true(is_polar(af))
  expect_silent(ensure_is_polar(af))
  expect_false(is_cartesian(af))
})

test_that("an undeclared column does not decide the coordinate system", {
  # `rho` is dropped from the declaration but stays in the data. Matching
  # column names would still call this spherical.
  af <- as_anipoint(
    data.frame(
      time = 1:3,
      individual = "a",
      rho = c(1, 2, 3),
      phi = c(0, 1, 2),
      theta = c(0, 1, 2)
    )
  )
  expect_true(is_spherical(af))

  reduced <- suppressWarnings(remove_variables_where(af, "rho"))

  expect_equal(get_coordinate_system(reduced), "unknown")
  expect_false(is_spherical(reduced))
  expect_true("rho" %in% names(reduced))
})

test_that("the guards report what the frame is in, and what to do", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

  expect_error(ensure_is_polar(af), "cartesian_2d")
  expect_error(ensure_is_polar(af), "anispace")

  unknown <- suppressWarnings(as_anipoint(
    data.frame(time = 1:3, individual = "a", u = c(1, 2, 3), v = c(0, 1, 0)),
    variables_where = c("u", "v")
  ))
  expect_error(ensure_is_cartesian(unknown), "set_axes")
})

test_that("get_coordinate_system() reads the derived field", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

  expect_equal(get_coordinate_system(af), "cartesian_2d")
  expect_type(get_coordinate_system(af), "character")
  expect_error(get_coordinate_system(data.frame(x = 1)), "not an aniframe")
})
