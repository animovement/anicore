# Axis orientation, handedness and angle direction (#124).

frame_2d <- function(y = c(0, 5, 10)) {
  as_anipoint(
    data.frame(individual = "a", time = 1:3, x = c(1, 2, 3), y = y)
  )
}

# Reading the orientation off the axes ----

test_that("a frame with no axis directions claims no orientation", {
  af <- frame_2d()

  expect_length(get_axis_directions(af), 0)
  expect_equal(get_handedness(af), "unknown")
  expect_equal(get_angle_direction(af), "unknown")
})

test_that("two axes give the sense the recording shows", {
  # `atan2(y, x)` counts counter-clockwise, so an image-plane frame runs the
  # other way.
  expect_equal(
    get_angle_direction(set_axis_directions(
      frame_2d(),
      c(x = "right", y = "down")
    )),
    "clockwise"
  )
  expect_equal(
    get_angle_direction(set_axis_directions(
      frame_2d(),
      c(x = "right", y = "up")
    )),
    "counter_clockwise"
  )
})

test_that("two axes cannot fix a handedness", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "up"))

  expect_equal(get_handedness(af), "unknown")
})

test_that("three axes fix both, and agree with each other", {
  # A right-handed frame always counts counter-clockwise about its depth axis.
  for (z in c("back", "forward")) {
    af <- set_axis_directions(frame_2d(), c(x = "right", y = "up", z = z))

    expect_equal(
      identical(get_handedness(af), "right"),
      identical(get_angle_direction(af), "counter_clockwise")
    )
  }
})

test_that("handedness matches the table in #124", {
  expect_equal(
    get_handedness(set_axis_directions(
      frame_2d(),
      c(x = "right", y = "down", z = "back")
    )),
    "left"
  )
  expect_equal(
    get_handedness(set_axis_directions(
      frame_2d(),
      c(x = "right", y = "down", z = "forward")
    )),
    "right"
  )
  expect_equal(
    get_handedness(set_axis_directions(
      frame_2d(),
      c(x = "right", y = "up", z = "back")
    )),
    "right"
  )
  expect_equal(
    get_handedness(set_axis_directions(
      frame_2d(),
      c(x = "right", y = "up", z = "forward")
    )),
    "left"
  )
})

# The side the recording was made from ----

test_that("the viewing side is what tells two mirrored recordings apart", {
  # Filmed from above vs through a glass floor: same x/y, opposite rotations.
  above <- set_axis_directions(
    frame_2d(),
    c(x = "right", y = "down", z = "back")
  )
  below <- set_axis_directions(
    frame_2d(),
    c(x = "right", y = "down", z = "forward")
  )

  expect_equal(get_angle_direction(above), "clockwise")
  expect_equal(get_angle_direction(below), "counter_clockwise")
  expect_equal(get_handedness(above), "left")
  expect_equal(get_handedness(below), "right")
})

test_that("turning the depth axis over leaves an x-y frame's data alone", {
  # Nothing carries `z`; the direction describes the space, not the columns.
  above <- set_axis_directions(
    frame_2d(),
    c(x = "right", y = "down", z = "back")
  )
  below <- set_axis_directions(above, c(z = "forward"))

  expect_equal(below$x, above$x)
  expect_equal(below$y, above$y)
  expect_equal(get_angle_direction(below), "counter_clockwise")
})

# Stating the convention without spelling out the axes ----

test_that("handedness can be declared on its own", {
  af <- set_metadata(frame_2d(), handedness = "left")

  expect_equal(get_handedness(af), "left")
  expect_length(get_axis_directions(af), 0)
})

test_that("a declared handedness settles the sense two axes leave open", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "down"))

  expect_equal(get_angle_direction(af), "clockwise")
  expect_equal(
    get_angle_direction(set_metadata(af, handedness = "right")),
    "counter_clockwise"
  )
  expect_equal(
    get_angle_direction(set_metadata(af, handedness = "left")),
    "clockwise"
  )
})

test_that("declaring a handedness does not invent a third axis", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "down"))

  expect_equal(
    get_axis_directions(set_metadata(af, handedness = "right")),
    c(x = "right", y = "down")
  )
})

test_that("declared axes are read in preference to a declared handedness", {
  # The directions say more, so the stored handedness is brought into line.
  af <- set_metadata(frame_2d(), handedness = "left")
  af <- set_axis_directions(af, c(x = "right", y = "up", z = "back"))

  expect_equal(get_handedness(af), "right")
  expect_equal(as.character(get_metadata(af, "handedness")), "right")
})

test_that("handedness must be one of the two", {
  expect_error(
    set_metadata(frame_2d(), handedness = "widdershins"),
    "can only be"
  )
})

# Turning an axis over flips the orientation ----

test_that("reflecting the depth axis turns the handedness over", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "up", z = "back"))

  result <- reflect_axis(af, "z")

  expect_equal(
    get_axis_directions(result),
    c(x = "right", y = "up", z = "forward")
  )
  expect_equal(get_handedness(result), "left")
  expect_equal(result$x, af$x)
  expect_equal(result$y, af$y)
})

test_that("reflecting an axis flips a handedness declared on its own", {
  af <- set_metadata(frame_2d(), handedness = "right")

  expect_equal(get_handedness(reflect_axis(af, "y")), "left")
})

test_that("reflecting the vertical axis reverses the angle direction", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "down"))
  af <- set_metadata(af, axis_extents = c(y = 10))

  result <- reflect_axis(af, "y")

  expect_equal(get_axis_directions(result)[["y"]], "up")
  expect_equal(get_angle_direction(result), "counter_clockwise")
  expect_equal(result$y, c(10, 5, 0))
})

test_that("an unknown handedness stays unknown when an axis is reflected", {
  expect_equal(get_handedness(reflect_axis(frame_2d(), "y")), "unknown")
})

test_that("angle direction is derived, not declared", {
  expect_error(
    set_metadata(frame_2d(), angle_direction = "clockwise"),
    "not a metadata field"
  )
})

# An anievent has no orientation at all ----

test_that("an anievent claims neither", {
  ae <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(b = factor(rep(c("r", "w"), each = 2))) |>
    set_variables(event = list(state = "b")) |>
    to_anievent()

  expect_equal(get_handedness(ae), "unknown")
  expect_equal(get_angle_direction(ae), "unknown")
})

# The derivations on their own ----

test_that("a stated handedness settles the sense when no z is declared", {
  expect_equal(
    derive_angle_direction(c(x = "right", y = "down"), "right"),
    "counter_clockwise"
  )
  expect_equal(
    derive_angle_direction(c(x = "right", y = "down"), "left"),
    "clockwise"
  )
})

test_that("axes that do not span the view give no sense of rotation", {
  # x across and y into the frame are seen edge-on from the default viewpoint.
  expect_equal(derive_angle_direction(c(x = "right", y = "back")), "unknown")
})

test_that("parallel axes give no handedness", {
  # Rejected at declaration, but stored metadata may not come from the setter.
  expect_equal(
    derive_handedness(c(x = "right", y = "left", z = "up")),
    "unknown"
  )
})
