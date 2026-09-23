make_test_aniframe <- function(df, unit = "rad") {
  df %>%
    as_anipoint() %>%
    set_metadata(unit_angle = unit)
}

raw_df <- data.frame(
  time = c(0, 1, 2),
  x = c(1, 1, 1),
  y = c(2, 2, 2),
  head_left = c(0, pi / 2, pi),
  head_right = c(pi / 4, pi / 3, pi / 6),
  speed = c(1, 2, 3) # not an angle
)

test_that("convert_unit_angle converts rad → deg correctly", {
  anif <- make_test_aniframe(raw_df, unit = "rad")

  out <- convert_unit_angle(
    anif,
    cols = c("head_left", "head_right"),
    to_unit = "deg"
  )

  expect_equal(get_metadata(out, "unit_angle") |> as.character(), "deg")

  expect_equal(out$head_left, rad_to_deg(raw_df$head_left))
  expect_equal(out$head_right, rad_to_deg(raw_df$head_right))
  expect_equal(out$speed, raw_df$speed)
})

test_that("convert_unit_angle converts deg → rad correctly", {
  deg_df <- data.frame(
    time = c(0, 1, 2),
    x = c(1, 1, 1),
    y = c(2, 2, 2),
    head_left = rad_to_deg(raw_df$head_left),
    head_right = rad_to_deg(raw_df$head_right),
    speed = raw_df$speed
  )
  anif <- make_test_aniframe(deg_df, unit = "deg")

  out <- convert_unit_angle(
    anif,
    cols = c("head_left", "head_right"),
    to_unit = "rad"
  )

  expect_equal(get_metadata(out, "unit_angle") |> as.character(), "rad")
  expect_equal(out$head_left, deg_to_rad(deg_df$head_left))
  expect_equal(out$head_right, deg_to_rad(deg_df$head_right))
  expect_equal(out$speed, deg_df$speed)
})

test_that("no conversion occurs when target unit already set", {
  anif <- make_test_aniframe(raw_df, unit = "rad")

  expect_message(
    out <- convert_unit_angle(
      anif,
      cols = c("head_left", "head_right"),
      to_unit = "rad"
    ),
    "Angular unit is already rad"
  )

  expect_identical(
    out,
    as_anipoint(raw_df) |> set_metadata(unit_angle = "rad")
  )
})

test_that("invalid target unit triggers an error", {
  anif <- make_test_aniframe(raw_df, unit = "rad")

  expect_error(
    convert_unit_angle(anif, cols = c("head_left"), to_unit = "turns"),
    "Angular unit can only be"
  )
})

test_that("missing columns raise an informative error", {
  anif <- make_test_aniframe(raw_df, unit = "rad")

  expect_error(
    convert_unit_angle(anif, cols = c("nonexistent"), to_unit = "deg"),
    "All provided columns must be in the data."
  )
})

test_that("non‑numeric columns raise an informative error", {
  bad_df <- raw_df
  bad_df$head_left <- as.character(bad_df$head_left)

  anif <- make_test_aniframe(bad_df, unit = "rad")

  expect_error(
    convert_unit_angle(anif, cols = c("head_left"), to_unit = "deg"),
    "All provided columns must be numeric."
  )
})

# ---- Spatial angular columns (phi, theta) are auto-converted (#21) ----

test_that("convert_unit_angle auto-converts phi for polar data (rad -> deg)", {
  df <- data.frame(
    time = 1:3,
    rho = 1:3,
    phi = c(0, pi / 2, pi)
  )
  anif <- as_anipoint(df) |> set_metadata(unit_angle = "rad")

  out <- convert_unit_angle(anif, to_unit = "deg")

  expect_equal(get_metadata(out, "unit_angle") |> as.character(), "deg")
  expect_equal(out$phi, c(0, 90, 180))
  expect_equal(out$rho, df$rho) # rho is not angular
})

test_that("convert_unit_angle auto-converts phi and z-agnostic for cylindrical (rad -> deg)", {
  df <- data.frame(
    time = 1:3,
    rho = 1:3,
    phi = c(0, pi / 4, pi / 2),
    z = c(10, 20, 30)
  )
  anif <- as_anipoint(df) |> set_metadata(unit_angle = "rad")

  out <- convert_unit_angle(anif, to_unit = "deg")

  expect_equal(out$phi, c(0, 45, 90))
  expect_equal(out$z, df$z) # z is spatial, not angular
})

test_that("convert_unit_angle auto-converts phi and theta for spherical (rad -> deg)", {
  df <- data.frame(
    time = 1:3,
    rho = 1:3,
    phi = c(0, pi / 2, pi),
    theta = c(0, pi / 4, pi / 2)
  )
  anif <- as_anipoint(df) |> set_metadata(unit_angle = "rad")

  out <- convert_unit_angle(anif, to_unit = "deg")

  expect_equal(out$phi, c(0, 90, 180))
  expect_equal(out$theta, c(0, 45, 90))
})

test_that("convert_unit_angle round-trips deg -> rad for spatial angular columns", {
  df <- data.frame(
    time = 1:3,
    rho = 1:3,
    phi = c(0, pi / 2, pi),
    theta = c(0, pi / 4, pi / 2)
  )
  anif <- as_anipoint(df) |> set_metadata(unit_angle = "rad")

  out <- convert_unit_angle(anif, to_unit = "deg") |>
    convert_unit_angle(to_unit = "rad")

  expect_equal(out$phi, df$phi)
  expect_equal(out$theta, df$theta)
  expect_equal(get_metadata(out, "unit_angle") |> as.character(), "rad")
})

test_that("convert_unit_angle combines spatial auto-detect with user cols", {
  df <- data.frame(
    time = 1:3,
    rho = 1:3,
    phi = c(0, pi / 2, pi),
    heading = c(0, pi / 4, pi / 3)
  )
  anif <- as_anipoint(df) |> set_metadata(unit_angle = "rad")

  out <- convert_unit_angle(anif, to_unit = "deg", cols = "heading")

  expect_equal(out$phi, c(0, 90, 180))
  expect_equal(out$heading, rad_to_deg(c(0, pi / 4, pi / 3)))
})

test_that("convert_unit_angle is a no-op for non-angular spatial cols (cartesian)", {
  df <- data.frame(time = 1:3, x = 1:3, y = 1:3)
  anif <- as_anipoint(df) |> set_metadata(unit_angle = "rad")

  out <- convert_unit_angle(anif, to_unit = "deg")

  # Cartesian columns are not converted; metadata still updates
  expect_equal(out$x, df$x)
  expect_equal(out$y, df$y)
  expect_equal(get_metadata(out, "unit_angle") |> as.character(), "deg")
})
