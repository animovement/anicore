yaw_frame <- function(heading = c(0.5, 1, -1)) {
  example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(heading = heading) |>
    set_variables(where = list(orientation = c(yaw = "heading")))
}

quat_frame <- function(angle = 0.5) {
  df <- data.frame(
    time = 1:2,
    x = 1:2,
    y = 1:2,
    z = 1:2,
    w = c(1, cos(angle)),
    i = c(0, sin(angle) / sqrt(3)),
    j = c(0, sin(angle) / sqrt(3)),
    k = c(0, sin(angle) / sqrt(3))
  )
  as_anipoint(df) |>
    set_variables(
      where = list(orientation = c(qw = "w", qx = "i", qy = "j", qz = "k"))
    )
}

test_that("yaw is declared, placed after position, and kept through verbs", {
  af <- yaw_frame()
  expect_equal(get_variables(af, "where", "orientation"), c(yaw = "heading"))
  expect_equal(which(names(af) == "heading"), which(names(af) == "y") + 1L)
  expect_true("heading" %in% get_variables(af, "where"))

  af <- dplyr::filter(af, time > 1)
  expect_equal(get_variables(af, "where", "orientation"), c(yaw = "heading"))
  recast <- as_anipoint(af)
  expect_equal(
    get_variables(recast, "where", "orientation"),
    c(yaw = "heading")
  )
})

test_that("clearing the slot removes the orientation", {
  af <- set_variables(yaw_frame(), where = list(orientation = character()))
  expect_equal(get_variables(af, "where", "orientation"), character())
})

test_that("reflecting an axis reflects yaw like phi", {
  af <- yaw_frame()
  expect_equal(reflect_axis(af, "y")$heading, c(-0.5, -1, 1))
  expect_equal(reflect_axis(af, "x")$heading, c(pi - 0.5, pi - 1, -pi + 1))
  expect_equal(reflect_axis(af, "z")$heading, af$heading)
})

test_that("reflecting an axis conjugates the quaternion", {
  af <- quat_frame()
  q <- function(x) {
    unname(as.matrix(as.data.frame(x)[2, c("w", "i", "j", "k")]))[1, ]
  }
  s <- sin(0.5) / sqrt(3)
  expect_equal(q(reflect_axis(af, "x")), c(cos(0.5), s, -s, -s))
  expect_equal(q(reflect_axis(af, "y")), c(cos(0.5), -s, s, -s))
  expect_equal(q(reflect_axis(af, "z")), c(cos(0.5), -s, -s, s))
  expect_equal(q(reflect_axis(reflect_axis(af, "y"), "y")), q(af))
})

test_that("convert_unit_angle() converts yaw", {
  af <- convert_unit_angle(yaw_frame(), "deg")
  expect_equal(af$heading, rad_to_deg(c(0.5, 1, -1)))
})

test_that("roles must form one set", {
  af <- yaw_frame()
  expect_error(
    set_variables(af, where = list(orientation = c(qw = "heading"))),
    "must map the roles"
  )
  expect_error(
    set_variables(af, where = list(orientation = c("heading"))),
    "must map the roles"
  )
  expect_error(
    set_variables(
      af,
      where = list(orientation = c(yaw = "heading", yaw = "x"))
    ),
    "must map the roles"
  )
})

test_that("yaw is 2D and quaternions 3D", {
  expect_error(
    set_variables(
      yaw_frame(),
      where = list(orientation = c(qw = "x", qx = "y", qy = "x", qz = "y"))
    ),
    "needs a 3D frame"
  )
  af <- quat_frame() |> dplyr::mutate(h = 0)
  expect_error(
    set_variables(af, where = list(orientation = c(yaw = "h"))),
    "needs a 2D frame"
  )
})

test_that("a frame with no known coordinate system takes either", {
  df <- data.frame(time = 1:3, u = 1:3, v = 1:3, h = 0)
  af <- suppressWarnings(as_anipoint(df, variables_where = c("u", "v")))
  af <- set_variables(af, where = list(orientation = c(yaw = "h")))
  expect_equal(get_variables(af, "where", "orientation"), c(yaw = "h"))
})

test_that("orientation columns must exist and be numeric", {
  af <- yaw_frame()
  expect_error(
    set_variables(af, where = list(orientation = c(yaw = "nope"))),
    "Missing spatial variable"
  )
  af <- dplyr::mutate(af, label = "a")
  expect_error(
    set_variables(af, where = list(orientation = c(yaw = "label"))),
    "must be numeric"
  )
})

test_that("quaternions must have unit norm", {
  af <- dplyr::mutate(quat_frame(), w = 2)
  expect_error(as_anipoint(af), "unit norm")
})

test_that("the Euler convention is recorded together, validated and upper-cased", {
  af <- set_metadata(
    quat_frame(),
    euler_sequence = "zyx",
    euler_intrinsic = TRUE
  )
  expect_equal(get_metadata(af, "euler_sequence"), "ZYX")
  expect_true(get_metadata(af, "euler_intrinsic"))
  expect_error(
    set_metadata(quat_frame(), euler_sequence = "ZYX"),
    "set together"
  )
  expect_error(
    set_metadata(quat_frame(), euler_sequence = "ZZX", euler_intrinsic = TRUE),
    "three axes"
  )
  expect_error(
    set_metadata(quat_frame(), euler_sequence = "AB", euler_intrinsic = FALSE),
    "three axes"
  )
  cleared <- set_metadata(af, euler_sequence = NA, euler_intrinsic = NA)
  expect_true(is.na(get_metadata(cleared, "euler_sequence")))
  expect_true(is.na(get_metadata(quat_frame(), "euler_sequence")))
})
