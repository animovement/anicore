# Getters for the fields that already had setters (#121)
#
# The point is that downstream stops naming metadata fields as literals, so
# a later restructure (#118) does not reach them.

test_that("every field with a setter has a getter that reads it back", {
  af <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1)

  expect_equal(get_sampling_rate(af), get_metadata(af, "sampling_rate"))
  expect_equal(get_axis_directions(af), get_metadata(af, "axis_directions"))
  expect_equal(get_axis_extents(af), get_metadata(af, "axis_extents"))
  expect_equal(get_unit_space(af), as.character(get_metadata(af, "unit_space")))
  expect_equal(get_unit_time(af), as.character(get_metadata(af, "unit_time")))
  expect_equal(get_unit_angle(af), as.character(get_metadata(af, "unit_angle")))
})

test_that("the getters see what their setters wrote", {
  af <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1)

  expect_equal(get_sampling_rate(set_sampling_rate(af, 30)), 30)
  expect_equal(get_axis_extents(set_axis_extents(af, c(y = 1080))), c(y = 1080))
  expect_equal(
    get_axis_directions(set_axis_directions(af, c(x = "right")))[["x"]],
    "right"
  )
  expect_equal(
    get_unit_space(set_unit_space(af, "mm", calibration_factor = 10)),
    "mm"
  )
  expect_equal(
    get_unit_time(set_unit_time(af, "s", calibration_factor = 1 / 30)),
    "s"
  )
})

test_that("the factor-backed getters return a bare character", {
  # Downstream almost always wraps these in as.character(); doing it here
  # means they no longer have to.
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

  for (value in list(
    get_unit_space(af),
    get_unit_time(af),
    get_unit_angle(af),
    get_handedness(af),
    get_angle_direction(af)
  )) {
    expect_type(value, "character")
    expect_length(value, 1)
  }
})

test_that("the getters reject a plain data frame", {
  df <- data.frame(x = 1)

  expect_error(get_sampling_rate(df), "not an aniframe")
  expect_error(get_unit_space(df), "not an aniframe")
  expect_error(get_axis_extents(df), "not an aniframe")
  expect_error(get_handedness(df), "not an aniframe")
})

test_that("they work on an anievent too, where the field applies", {
  ae <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(b = factor(rep(c("r", "w"), each = 2))) |>
    set_variables_event(state = "b") |>
    to_anievent()

  expect_equal(get_unit_time(ae), as.character(get_metadata(ae, "unit_time")))
  # An anievent has no spatial component, so these read as "not applicable".
  expect_true(is.na(get_unit_space(ae)))
  expect_length(get_axis_directions(ae), 0)
  expect_equal(get_handedness(ae), "unknown")
})
