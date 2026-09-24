# Metadata written by the setters and converters reads back (#121).

test_that("get_axis_directions() reads the stored field", {
  af <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1)
  expect_equal(get_axis_directions(af), get_metadata(af, "axis_directions"))
})

test_that("metadata reads back what the setters and converters wrote", {
  af <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1)

  expect_equal(
    get_metadata(set_metadata(af, sampling_rate = 30), "sampling_rate"),
    30
  )
  expect_equal(
    get_metadata(set_metadata(af, axis_extents = c(y = 1080)), "axis_extents"),
    c(y = 1080)
  )
  expect_equal(
    get_axis_directions(set_axis_directions(af, c(x = "right")))[["x"]],
    "right"
  )
  expect_equal(
    as.character(get_metadata(
      convert_unit_space(af, "mm", calibration_factor = 10),
      "unit_space"
    )),
    "mm"
  )
  expect_equal(
    as.character(get_metadata(
      convert_unit_time(af, "s", calibration_factor = 1 / 30),
      "unit_time"
    )),
    "s"
  )
})

test_that("the factor-backed getters return a bare character", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)

  for (value in list(get_handedness(af), get_angle_direction(af))) {
    expect_type(value, "character")
    expect_length(value, 1)
  }
})

test_that("the getters reject a plain data frame", {
  df <- data.frame(x = 1)

  expect_error(get_metadata(df, "sampling_rate"), "hasn't been initiated")
  expect_error(get_metadata(df, "unit_space"), "hasn't been initiated")
  expect_error(get_handedness(df), "not an aniframe")
  expect_error(get_axis_directions(df), "not an aniframe")
})

test_that("they work on an anievent too, where the field applies", {
  ae <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(b = factor(rep(c("r", "w"), each = 2))) |>
    set_variables(event = list(state = "b")) |>
    to_anievent()

  expect_type(as.character(get_metadata(ae, "unit_time")), "character")
  # An anievent has no spatial component, so these read as "not applicable".
  expect_null(get_metadata(ae, "unit_space"))
  expect_length(get_axis_directions(ae), 0)
  expect_equal(get_handedness(ae), "unknown")
})
