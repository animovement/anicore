# Which way the axes point, and what follows from it (#124)
#
# The cases that matter are the ones two axes cannot tell apart: the same
# scene recorded from opposite sides.

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
  # `atan2(y, x)` counts counter-clockwise, so an image-plane frame counts
  # the other way round from the maths convention.
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
  # `det[x y z]` is `(x cross y) . z`, so a right-handed frame counts
  # counter-clockwise about its own depth axis, always.
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
  # A rodent filmed from above and through a glass floor gives images whose
  # x and y are declared identically, but whose rotations run opposite ways.
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
  # Nothing carries `z`, so there is nothing to express differently -- the
  # direction is a fact about the space, not about the columns.
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

test_that("handedness can be stated on its own", {
  af <- set_handedness(frame_2d(), "left")

  expect_equal(get_handedness(af), "left")
  expect_length(get_axis_directions(af), 0)
})

test_that("right-handed is what set_handedness() defaults to", {
  expect_equal(get_handedness(set_handedness(frame_2d())), "right")
})

test_that("a stated handedness settles the sense two axes leave open", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "down"))

  expect_equal(get_angle_direction(af), "clockwise")
  expect_equal(
    get_angle_direction(set_handedness(af, "right")),
    "counter_clockwise"
  )
  expect_equal(get_angle_direction(set_handedness(af, "left")), "clockwise")
})

test_that("stating a handedness completes the third axis", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "down"))

  expect_equal(
    get_axis_directions(set_handedness(af, "right"))[["z"]],
    "forward"
  )
  expect_equal(get_axis_directions(set_handedness(af, "left"))[["z"]], "back")
})

test_that("declared axes are read in preference to a stated handedness", {
  # The three directions say more, so nothing can drift out of step: the
  # recorded value is brought into line rather than left contradicting them.
  af <- set_handedness(frame_2d(), "left")
  af <- set_axis_directions(af, c(x = "right", y = "up", z = "back"))

  expect_equal(get_handedness(af), "right")
  expect_equal(as.character(get_metadata(af, "handedness")), "right")
})

test_that("turning the handedness over reverses the depth axis", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "up", z = "back"))

  expect_equal(
    get_axis_directions(set_handedness(af, "left"))[["z"]],
    "forward"
  )
  # The axes that were not the depth one are left alone.
  expect_equal(get_axis_directions(set_handedness(af, "left"))[["x"]], "right")
})

test_that("asking for the handedness a frame already has changes nothing", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "up", z = "back"))

  expect_equal(set_handedness(af, "right"), af)
})

test_that("handedness must be one of the two", {
  expect_error(set_handedness(frame_2d(), "widdershins"), "must be one of")
  expect_error(set_handedness(frame_2d(), c("right", "left")), "must be one of")
})


# Asking for a sense of rotation ----

test_that("set_angle_direction() determines the axis that is missing", {
  af <- set_axis_directions(frame_2d(), c(x = "right"))

  expect_equal(
    get_axis_directions(set_angle_direction(af, "counter_clockwise"))[["y"]],
    "up"
  )
  expect_equal(
    get_axis_directions(set_angle_direction(af, "clockwise"))[["y"]],
    "down"
  )
})

test_that("set_angle_direction() turns the vertical axis over", {
  af <- set_axis_directions(frame_2d(), c(x = "right", y = "down"))
  af <- set_axis_extents(af, c(y = 10))

  result <- set_angle_direction(af, "counter_clockwise")

  expect_equal(get_axis_directions(result)[["y"]], "up")
  expect_equal(result$y, c(10, 5, 0))
})

test_that("set_angle_direction() needs an axis to work from", {
  expect_error(
    set_angle_direction(frame_2d(), "clockwise"),
    "Not enough axes"
  )
})

test_that("angle direction must be one of the two", {
  expect_error(set_angle_direction(frame_2d(), "sideways"), "must be one of")
})


# An anievent has no orientation at all ----

test_that("an anievent claims neither", {
  ae <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(b = factor(rep(c("r", "w"), each = 2))) |>
    set_variables_event(state = "b") |>
    to_anievent()

  expect_equal(get_handedness(ae), "unknown")
  expect_equal(get_angle_direction(ae), "unknown")
})


# The derivations on their own ----

test_that("a stated handedness settles the sense when no z is declared", {
  # Not reachable through `set_handedness()`, which completes the third
  # axis when two are declared -- but metadata can carry the coarser
  # statement without them.
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
  # x across and y into the frame turn about the vertical, which the
  # default viewpoint sees edge-on.
  expect_equal(derive_angle_direction(c(x = "right", y = "back")), "unknown")
})

test_that("parallel axes give no handedness", {
  # Rejected at declaration, but stored metadata is not required to have
  # come from the setter.
  expect_equal(
    derive_handedness(c(x = "right", y = "left", z = "up")),
    "unknown"
  )
})

test_that("solving says so when no direction gives the answer", {
  expect_error(
    solve_axis_direction(
      c(x = "right"),
      "y",
      "widdershins",
      derive_angle_direction
    ),
    "No direction"
  )
})
