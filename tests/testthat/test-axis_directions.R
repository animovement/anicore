# Declaring which way the axes point, and how far they run (#124)

frame_uv <- function(v = c(0, 5, 10)) {
  as_anipoint(
    data.frame(individual = "a", time = 1:3, u = c(1, 2, 3), v = v),
    variables_where = c(x = "u", y = "v")
  )
}

# Declaring directions ----

test_that("directions are recorded against the axis role", {
  af <- set_axis_directions(frame_uv(), c(x = "right", y = "up"))

  expect_equal(get_axis_directions(af), c(x = "right", y = "up"))
})

test_that("naming one axis leaves the others alone", {
  af <- set_axis_directions(frame_uv(), c(x = "right", y = "up"))
  af <- set_axis_directions(af, c(z = "back"))

  expect_equal(get_axis_directions(af), c(x = "right", y = "up", z = "back"))
})

test_that("NA clears an axis", {
  af <- set_axis_directions(frame_uv(), c(x = "right", y = "up"))
  af <- set_axis_directions(af, c(x = NA))

  expect_equal(get_axis_directions(af), c(y = "up"))
})

test_that("directions come back in axis order however they went in", {
  af <- set_axis_directions(frame_uv(), c(z = "back", x = "right"))

  expect_equal(names(get_axis_directions(af)), c("x", "z"))
})

# What is not a direction ----

test_that("a direction has to be one of the six", {
  expect_error(
    set_axis_directions(frame_uv(), c(x = "rightwards")),
    "not a direction"
  )
})

test_that("only the linear axes point anywhere", {
  # `rho` is a distance and `phi` and `theta` are angles.
  expect_error(
    set_axis_directions(frame_uv(), c(phi = "right")),
    "points anywhere"
  )
})

test_that("directions must be named by role", {
  expect_error(
    set_axis_directions(frame_uv(), "right"),
    "must name an axis role"
  )
  expect_error(
    set_axis_directions(frame_uv(), character(0)),
    "must name an axis role"
  )
})

test_that("directions must be characters", {
  expect_error(set_axis_directions(frame_uv(), c(x = 1)), "must be a character")
})

test_that("two axes cannot point along the same line", {
  expect_error(
    set_axis_directions(frame_uv(), c(x = "right", y = "left")),
    "same line"
  )
  expect_error(
    set_axis_directions(frame_uv(), c(x = "up", y = "up")),
    "same line"
  )
})

test_that("a clash with an axis already declared is caught too", {
  af <- set_axis_directions(frame_uv(), c(x = "right"))

  expect_error(set_axis_directions(af, c(y = "left")), "same line")
})

# Turning an axis over ----

test_that("reflect_axis() reflects an axis around its extent", {
  af <- set_metadata(frame_uv(), axis_extents = c(y = 10))
  af <- set_axis_directions(af, c(x = "right", y = "up"))

  result <- reflect_axis(af, "y")

  expect_equal(result$v, c(10, 5, 0))
  expect_equal(result$u, c(1, 2, 3))
  expect_equal(get_axis_directions(result), c(x = "right", y = "down"))
})

test_that("an axis with no extent is negated instead", {
  # World coordinates are measured from the origin, so the mirror is `-v`.
  af <- set_axis_directions(frame_uv(), c(x = "right", y = "up"))

  expect_equal(reflect_axis(af, "y")$v, c(0, -5, -10))
})

test_that("reflect_axis() leaves an undeclared direction undeclared", {
  result <- reflect_axis(frame_uv(), "y")

  expect_equal(result$v, c(0, -5, -10))
  expect_length(get_axis_directions(result), 0)
})

test_that("reflect_axis() takes one linear axis role", {
  expect_error(reflect_axis(frame_uv(), "phi"))
  expect_error(reflect_axis(frame_uv(), c("x", "y")))
})

test_that("turning an axis over with set_axis_directions() leaves the values alone", {
  af <- set_metadata(frame_uv(), axis_extents = c(y = 10))
  af <- set_axis_directions(af, c(x = "right", y = "up"))

  result <- set_axis_directions(af, c(y = "down"))

  expect_equal(result$v, c(0, 5, 10))
  expect_equal(get_axis_directions(result), c(x = "right", y = "down"))
})

test_that("declaring a direction the axis did not have reflects nothing", {
  af <- set_metadata(frame_uv(), axis_extents = c(y = 10))

  expect_equal(set_axis_directions(af, c(y = "up"))$v, c(0, 5, 10))
})

test_that("turning an axis onto a different line reflects nothing", {
  # Saying y points forward rather than up re-describes the same numbers.
  af <- set_axis_directions(frame_uv(), c(y = "up"))

  expect_equal(set_axis_directions(af, c(y = "forward"))$v, c(0, 5, 10))
})

test_that("an angular frame moves its angles instead of a column", {
  # Covered fully in test-angular_flips.R (#134).
  pol <- as_anipoint(
    data.frame(individual = "a", time = 1:3, rho = c(1, 2, 3), phi = c(0, 1, 2))
  )
  pol <- set_axis_directions(pol, c(x = "right", y = "up"))

  expect_equal(
    reflect_axis(pol, "y")$phi,
    -c(0, 1, 2) %% (2 * pi)
  )
})

# Extents ----

test_that("extents are recorded against the axis role", {
  af <- set_metadata(frame_uv(), axis_extents = c(x = 1920, y = 1080))

  expect_equal(get_metadata(af, "axis_extents"), c(x = 1920, y = 1080))
})

test_that("an extent must be positive and finite", {
  expect_error(
    set_metadata(frame_uv(), axis_extents = c(y = 0)),
    "positive and finite"
  )
  expect_error(
    set_metadata(frame_uv(), axis_extents = c(y = -1080)),
    "positive and finite"
  )
  expect_error(
    set_metadata(frame_uv(), axis_extents = c(y = Inf)),
    "positive and finite"
  )
})

test_that("extents must be numbers named by role", {
  expect_error(
    set_metadata(frame_uv(), axis_extents = c(y = "1080")),
    "must be a numeric"
  )
  expect_error(
    set_metadata(frame_uv(), axis_extents = 1080),
    "must name an axis role"
  )
  expect_error(
    set_metadata(frame_uv(), axis_extents = c(phi = 6.28)),
    "points anywhere"
  )
})

test_that("an extent the data runs past is worth saying so about", {
  expect_warning(
    set_metadata(frame_uv(v = c(0, 5, 2000)), axis_extents = c(y = 1080)),
    "less than the largest"
  )
})

test_that("the warning is silenced with the package option", {
  previous <- options(aniframe.quiet = TRUE)
  on.exit(options(previous), add = TRUE)

  expect_no_warning(
    set_metadata(frame_uv(v = c(0, 5, 2000)), axis_extents = c(y = 1080))
  )
})

test_that("an axis with no column is not measured against the data", {
  expect_no_warning(set_metadata(frame_uv(), axis_extents = c(z = 1)))
})

test_that("extents follow the spatial unit they are lengths in", {
  # Otherwise the frame would claim a height in a unit it no longer uses.
  af <- set_metadata(frame_uv(), axis_extents = c(y = 1080))

  expect_equal(
    get_metadata(
      convert_unit_space(af, "mm", calibration_factor = 10),
      "axis_extents"
    ),
    c(y = 10800)
  )
})

# Construction ----

test_that("a frame is constructed with neither declared", {
  af <- frame_uv()

  expect_length(get_axis_directions(af), 0)
  expect_length(get_metadata(af, "axis_extents"), 0)
})

test_that("the accessors reject a plain data frame", {
  df <- data.frame(x = 1)

  expect_error(get_axis_directions(df), "not an aniframe")
  expect_error(set_axis_directions(df, c(x = "right")), "not an anipoint")
})

# The reflection helper's own guards ----

test_that("reflect_column() takes one column name and one finite reference", {
  af <- frame_uv()

  expect_error(reflect_column(af, c("u", "v"), 10), "single column name")
  expect_error(reflect_column(af, "u", c(1, 2)), "single finite")
  expect_error(reflect_column(af, "u", Inf), "single finite")
  expect_error(reflect_column(af, "nope", 10), "not found in data")
})

test_that("an extent is not measured against a column that is not there", {
  af <- set_axis_directions(frame_uv(), c(x = "right", y = "up"))
  stripped <- suppressWarnings(dplyr::select(dplyr::ungroup(af), -"v"))

  expect_no_warning(warn_short_axis_extents(stripped, c(y = 1)))
})
