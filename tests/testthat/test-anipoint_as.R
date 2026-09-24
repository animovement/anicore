test_that("as_anipoint detects cylindrical data (rho, phi, z), not cartesian_1d", {
  # Cartesian-first detection used to see `z` and return cartesian_1d.
  df <- data.frame(
    individual = 1L,
    time = 1:5,
    rho = 1:5,
    phi = seq(0, pi, length.out = 5),
    z = 1:5
  )

  data <- as_anipoint(df)

  expect_equal(
    as.character(get_metadata(data, "coordinate_system")),
    "cylindrical"
  )
  expect_equal(
    get_variables_where(data),
    c("rho", "phi", "z")
  )
})

test_that("as_anipoint orders cylindrical spatial columns as rho, phi, z (#43)", {
  # rho/phi used to be pushed to "other cols" when only z was detected.
  df <- data.frame(
    individual = 1L,
    time = 1:3,
    rho = 1:3,
    phi = c(0, 1, 2),
    z = 1:3
  )

  data <- as_anipoint(df)

  spatial_idx <- match(c("rho", "phi", "z"), names(data))
  expect_equal(spatial_idx, sort(spatial_idx))
  expect_equal(
    names(data)[spatial_idx[1]:spatial_idx[3]],
    c("rho", "phi", "z")
  )
})

test_that("as_anipoint detects spherical data (rho, phi, theta)", {
  df <- data.frame(
    individual = 1L,
    time = 1:5,
    rho = 1:5,
    phi = seq(0, pi, length.out = 5),
    theta = seq(0, pi, length.out = 5)
  )

  data <- as_anipoint(df)

  expect_equal(
    as.character(get_metadata(data, "coordinate_system")),
    "spherical"
  )
  expect_equal(
    get_variables_where(data),
    c("rho", "phi", "theta")
  )
})

test_that("as_anipoint detects polar data (rho, phi)", {
  df <- data.frame(
    individual = 1L,
    time = 1:5,
    rho = 1:5,
    phi = seq(0, pi, length.out = 5)
  )

  data <- as_anipoint(df)

  expect_equal(
    as.character(get_metadata(data, "coordinate_system")),
    "polar"
  )
  expect_equal(
    get_variables_where(data),
    c("rho", "phi")
  )
})

test_that("as_anipoint does not invent axis extents", {
  # Falling back to max(y) reflected around the highest tracked point, not
  # the frame height.
  df <- data.frame(
    individual = 1L,
    time = 1:4,
    x = c(0, 1, 2, 3),
    y = c(10, 50, 200, 1000)
  )

  expect_length(get_axis_extents(as_anipoint(df)), 0)
})

test_that("as_anipoint keeps axis extents the caller supplies", {
  df <- data.frame(
    individual = 1L,
    time = 1:3,
    x = c(0, 1, 2),
    y = c(10, 50, 200)
  )

  data <- as_anipoint(df, metadata = list(axis_extents = c(y = 1080)))

  expect_equal(get_axis_extents(data), c(y = 1080))
})

test_that("as_anipoint errors when time column missing", {
  df <- data.frame(
    frame = 1:5,
    x = 1:5,
    y = 1:5
  )

  expect_error(
    as_anipoint(df),
    "time.*is required"
  )
})

test_that("as_anipoint errors when other temporal variables missing", {
  df <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 1:5
  )

  expect_error(
    as_anipoint(df, variables_when = c("trial", "time")),
    "Temporal variable.*not found.*trial"
  )
})

test_that("as_anipoint works with additional temporal variables", {
  df <- data.frame(
    trial = c(1L, 1L, 2L, 2L, 2L),
    time = c(1, 2, 1, 2, 3),
    x = 1:5,
    y = 1:5
  )

  result <- as_anipoint(df, variables_when = c("trial", "time"))

  expect_s3_class(result, "aniframe")
  expect_true("trial" %in% dplyr::group_vars(result))
  expect_false("time" %in% dplyr::group_vars(result))
})

test_that("as_anipoint works with minimal required columns", {
  df <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 1:5
  )

  result <- as_anipoint(df)

  expect_s3_class(result, "aniframe")
  expect_equal(names(result), c("keypoint", "time", "x", "y"))
})

test_that("as_anipoint works with custom spatial variables", {
  df <- data.frame(
    time = 1:5,
    z = 1:5
  )

  result <- as_anipoint(df, variables_where = "z")

  expect_s3_class(result, "aniframe")
  expect_equal(names(result), c("keypoint", "time", "z"))
})

test_that("as_anipoint converts character identity variables to factor", {
  df <- data.frame(
    individual = c("A", "A", "B", "B", "A"),
    time = 1:5,
    x = 1:5,
    y = 1:5
  )

  result <- as_anipoint(df, variables_what = "individual")

  expect_s3_class(result$individual, "factor")
  expect_equal(levels(result$individual), c("A", "B"))
})

test_that("as_anipoint converts character temporal variables to factor", {
  df <- data.frame(
    trial = c("trial1", "trial1", "trial2", "trial2", "trial1"),
    time = 1:5,
    x = 1:5,
    y = 1:5
  )

  result <- as_anipoint(df, variables_when = c("trial", "time"))

  expect_s3_class(result$trial, "factor")
})

test_that("as_anipoint keeps integer temporal variables as integer", {
  df <- data.frame(
    trial = c(1L, 1L, 2L, 2L, 3L),
    time = 1:5,
    x = 1:5,
    y = 1:5
  )

  result <- as_anipoint(df, variables_when = c("trial", "time"))

  expect_type(result$trial, "integer")
})

test_that("as_anipoint converts spatial variables to numeric", {
  df <- data.frame(
    time = 1:5,
    x = c("1", "2", "3", "4", "5"),
    y = 1:5
  )

  result <- as_anipoint(df)

  expect_type(result$x, "double")
})

test_that("as_anipoint relocates columns to standard order", {
  df <- data.frame(
    confidence = rep(0.9, 5),
    x = 1:5,
    time = 1:5,
    y = 1:5,
    individual = "A"
  )

  result <- as_anipoint(df, variables_what = "individual")

  expect_equal(names(result)[1:4], c("individual", "time", "x", "y"))
  expect_true("confidence" %in% names(result))
})

test_that("as_anipoint preserves non-standard columns", {
  df <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 1:5,
    custom_col = letters[1:5]
  )

  result <- as_anipoint(df)

  expect_true("custom_col" %in% names(result))
  expect_equal(result$custom_col, letters[1:5])
})

test_that("as_anipoint groups by identity and temporal context", {
  df <- data.frame(
    individual = c("A", "A", "A", "B", "B", "B"),
    trial = c(1L, 1L, 1L, 2L, 2L, 2L),
    time = 1:6,
    x = 1:6,
    y = 1:6
  )

  result <- as_anipoint(
    df,
    variables_what = "individual",
    variables_when = c("trial", "time")
  )

  expect_s3_class(result, "grouped_df")
  group_vars <- dplyr::group_vars(result)
  expect_true("individual" %in% group_vars)
  expect_true("trial" %in% group_vars)
  expect_false("time" %in% group_vars)
})

test_that("as_anipoint arranges by identity then temporal", {
  df <- data.frame(
    individual = c("B", "A", "B", "A", "B", "A"),
    time = c(3, 1, 2, 3, 1, 2),
    x = 1:6,
    y = 1:6
  )

  result <- as_anipoint(df, variables_what = "individual")

  expect_equal(as.character(result$individual), c("A", "A", "A", "B", "B", "B"))
  expect_equal(result$time, c(1, 2, 3, 1, 2, 3))
})

test_that("as_anipoint attaches metadata", {
  df <- data.frame(
    time = 1:5,
    x = 1:5,
    y = 1:5
  )

  md <- list(sampling_rate = 30, source = "test")
  result <- as_anipoint(df, metadata = md)

  result_md <- get_metadata(result)
  expect_equal(result_md$sampling_rate, 30)
  expect_equal(result_md$source, "test")
})

test_that("as_anipoint stores variables in metadata", {
  df <- data.frame(
    individual = "A",
    trial = 1L,
    time = 1:5,
    x = 1:5,
    y = 1:5
  )

  result <- as_anipoint(
    df,
    variables_what = "individual",
    variables_when = c("trial", "time"),
    variables_where = c("x", "y")
  )

  result_md <- get_metadata(result)
  expect_equal(get_variables_what(result), "individual")
  expect_equal(get_variables_when(result), "trial")
  expect_equal(get_variables_where(result), c("x", "y"))
})

test_that("as_anipoint respects custom variables_what", {
  df <- data.frame(
    track = c(1, 1, 2, 2, 3, 3),
    time = rep(1:2, 3),
    x = 1:6,
    y = 1:6
  )

  result <- as_anipoint(df, variables_what = "track")

  expect_equal(names(result)[1], "track")
  expect_true("track" %in% dplyr::group_vars(result))
})

test_that("as_anipoint respects custom variables_when with time", {
  df <- data.frame(
    session = c(1L, 1L, 2L, 2L),
    time = 1:4,
    x = 1:4,
    y = 1:4
  )

  result <- as_anipoint(df, variables_when = c("session", "time"))

  expect_s3_class(result, "aniframe")
  expect_equal(get_variables_when(result), "session")
})

test_that("as_anipoint auto-detects observation as a temporal grouping column", {
  df <- data.frame(
    individual = 1L,
    observation = c("clip_a", "clip_a", "clip_b", "clip_b"),
    time = c(1, 2, 1, 2),
    x = 1:4,
    y = 1:4
  )

  result <- as_anipoint(df)

  expect_equal(
    get_variables_when(result),
    "observation"
  )
})

test_that("as_anipoint works with full tidy movement data", {
  df <- data.frame(
    individual = c("A", "A", "B", "B", "A", "A", "B", "B"),
    keypoint = rep(c("head", "tail"), 4),
    session = c(1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L),
    trial = c(1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L),
    time = rep(1:2, 4),
    x = 1:8,
    y = 1:8,
    confidence = rep(0.95, 8)
  )

  result <- as_anipoint(
    df,
    variables_what = c("individual", "keypoint"),
    variables_when = c("session", "trial", "time"),
    variables_where = c("x", "y")
  )

  expect_s3_class(result, "aniframe")
  expect_equal(
    names(result)[1:8],
    c(
      "individual",
      "keypoint",
      "session",
      "trial",
      "time",
      "x",
      "y",
      "confidence"
    )
  )

  group_vars <- dplyr::group_vars(result)
  expect_true(all(
    c("individual", "keypoint", "session", "trial") %in% group_vars
  ))
  expect_false("time" %in% group_vars)
})

test_that("as_anipoint infers coordinate system from spatial variables", {
  df_2d <- data.frame(time = 1:5, x = 1:5, y = 1:5)
  df_3d <- data.frame(time = 1:5, x = 1:5, y = 1:5, z = 1:5)
  df_polar <- data.frame(time = 1:5, rho = 1:5, phi = 1:5)

  result_2d <- as_anipoint(df_2d)
  result_3d <- as_anipoint(df_3d, variables_where = c("x", "y", "z"))
  result_polar <- as_anipoint(df_polar, variables_where = c("rho", "phi"))

  expect_equal(
    as.character(get_metadata(result_2d, "coordinate_system")),
    "cartesian_2d"
  )
  expect_equal(
    as.character(get_metadata(result_3d, "coordinate_system")),
    "cartesian_3d"
  )
  expect_equal(
    as.character(get_metadata(result_polar, "coordinate_system")),
    "polar"
  )
})

test_that("as_anipoint errors when no spatial variables found", {
  df <- data.frame(
    time = 1:5,
    value = 1:5
  )

  expect_error(
    as_anipoint(df),
    "No spatial variables found"
  )
})

test_that("as_anipoint errors when specified spatial variables missing", {
  df <- data.frame(
    time = 1:5,
    x = 1:5
  )

  expect_error(
    as_anipoint(df, variables_where = c("x", "y", "z")),
    "Missing spatial variable"
  )
})

test_that("as_anipoint warns for unknown coordinate system", {
  df <- data.frame(
    time = 1:5,
    lon = 1:5,
    lat = 1:5
  )

  expect_warning(
    as_anipoint(df, variables_where = c("lon", "lat")),
    "Could not infer coordinate system"
  )
})

test_that("as_anipoint detects polar coordinates", {
  df <- data.frame(
    time = 1:5,
    rho = 1:5,
    phi = seq(0, pi, length.out = 5)
  )

  result <- as_anipoint(df)

  expect_s3_class(result, "aniframe")
  expect_equal(
    get_variables_where(result),
    c("rho", "phi")
  )
  expect_equal(as.character(get_metadata(result, "coordinate_system")), "polar")
})

test_that("detect_variables_where returns NULL when no spatial columns", {
  df <- data.frame(
    time = 1:5,
    value = 1:5
  )

  result <- detect_variables_where(df)

  expect_null(result)
})

# ---- Casting keeps what the frame already declares (#96) ----------------

test_that("casting an aniframe keeps a custom identity declaration", {
  # `id` isn't a recognised identity name, so re-detection used to inject
  # `keypoint = "centroid"` and overwrite the declaration.
  af <- anipoint(keypoint = "centroid", time = 1:4, x = 1:4, y = 1:4) |>
    dplyr::mutate(id = "a") |>
    add_variables_what("id") |>
    remove_variables_what("keypoint") |>
    dplyr::select(-keypoint)

  out <- as_anipoint(af)

  expect_equal(get_variables_what(out), "id")
  expect_false("keypoint" %in% names(out))
})

test_that("casting keeps a declared opt-out rather than injecting an identity", {
  af <- anipoint(
    time = 1:4,
    x = 1:4,
    y = 1:4,
    variables_what = character(0)
  )

  out <- as_anipoint(af)

  expect_length(get_variables_what(out), 0)
  expect_false("keypoint" %in% names(out))
})

test_that("a declaration whose columns are gone falls back to detection", {
  # A cast should still repair metadata that has drifted from the columns.
  af <- anipoint(individual = "a", time = 1:4, x = 1:4, y = 1:4, z = 1:4)
  drifted <- dplyr::select(af, -z)

  out <- as_anipoint(drifted)

  expect_equal(get_variables_where(out), c("x", "y"))
  expect_equal(
    as.character(get_metadata(out, "coordinate_system")),
    "cartesian_2d"
  )
})

test_that("explicit arguments still win over what the frame declares", {
  af <- anipoint(individual = "a", time = 1:4, x = 1:4, y = 1:4)
  af <- dplyr::mutate(af, track = 1L)

  out <- as_anipoint(af, variables_what = "track")

  expect_equal(get_variables_what(out), "track")
})

test_that("the unit setters leave the declarations alone", {
  af <- anipoint(keypoint = "centroid", time = 1:4, x = 1:4, y = 1:4) |>
    dplyr::mutate(id = "a") |>
    add_variables_what("id") |>
    remove_variables_what("keypoint") |>
    dplyr::select(-keypoint)

  for (out in list(
    set_unit_space(af, "cm", calibration_factor = 1 / 394),
    set_unit_time(af, "s", calibration_factor = 1 / 30),
    set_sampling_rate(af, 30),
    set_unit_angle(af, "deg")
  )) {
    expect_equal(get_variables_what(out), "id")
    expect_false("keypoint" %in% names(out))
  }
})
