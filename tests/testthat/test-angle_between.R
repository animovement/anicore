test_that("the included angle ignores order and length", {
  expect_equal(angle_between(c(1, 0), c(0, 2)), pi / 2)
  expect_equal(angle_between(c(0, 2), c(1, 0)), pi / 2)
  expect_equal(angle_between(c(1, 0, 0), c(-1, 0, 0)), pi)
  expect_equal(angle_between(c(1, 1, 0), c(1, 1, 0)), 0)
})

test_that("an axis gives the signed angle by the right-hand rule", {
  expect_equal(angle_between(c(1, 0), c(0, 1), axis = c(0, 0, 1)), pi / 2)
  expect_equal(angle_between(c(1, 0), c(0, 1), axis = c(0, 0, -1)), -pi / 2)
  expect_equal(
    angle_between(c(1, 0), c(-1, -1e-9), axis = c(0, 0, 1)),
    -pi,
    tolerance = 1e-6
  )
})

test_that("vectors are projected onto the plane perpendicular to the axis", {
  expect_equal(
    angle_between(c(1, 0, 5), c(0, 1, -3), axis = c(0, 0, 2)),
    pi / 2
  )
})

test_that("rows are paired, and a single vector is recycled", {
  u <- rbind(c(1, 0, 0), c(0, 1, 0))
  expect_equal(angle_between(u, c(0, 0, 1)), c(pi / 2, pi / 2))
  expect_equal(
    angle_between(u, data.frame(x = c(0, 0), y = c(1, 0), z = c(0, 1))),
    c(pi / 2, pi / 2)
  )
  axes <- rbind(c(0, 0, 1), c(0, 0, -1))
  expect_equal(
    angle_between(c(1, 0, 0), c(0, 1, 0), axis = axes),
    c(pi / 2, -pi / 2)
  )
})

test_that("degenerate vectors give NA", {
  expect_true(is.na(angle_between(c(0, 0), c(1, 0))))
  expect_true(is.na(angle_between(c(0, 0, 1), c(1, 0, 0), axis = c(0, 0, 1))))
  expect_true(is.na(angle_between(c(NA, 1), c(1, 0))))
})

test_that("bad input is refused", {
  expect_error(angle_between("a", c(1, 0)), "numeric vector")
  expect_error(angle_between(c(1, 0, 0, 0), c(1, 0)), "2 or 3")
  expect_error(angle_between(c(1, 0), c(1, 0, 0)), "same number")
  expect_error(angle_between(c(1, 0), c(1, 0), axis = c(0, 1)), "3 components")
  expect_error(
    angle_between(rbind(c(1, 0), c(0, 1)), rbind(c(1, 0), c(0, 1), c(1, 1))),
    "one row or 3"
  )
})
