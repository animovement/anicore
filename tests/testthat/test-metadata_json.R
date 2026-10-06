# Tests for get_metadata_json() and set_metadata_json()
#
# - Round trip gives identical metadata for every frame class: anipoint (with
#   and without a structure), anisegment, anijoint and anievent
# - Round trip keeps every awkward value: factors, NA of each type, NaN and
#   Inf, the start time with its time zone, named axis maps, empty slots
# - Numbers are written as the shortest decimal that reads back exactly
# - The layout is the documented one, readable without R
# - Parsed JSON is accepted as well as a string
# - Errors: not an aniframe, not a JSON object, unknown field

round_trip <- function(x) {
  set_metadata_json(x, get_metadata_json(x))
}

structured <- function() {
  example_anipoint(n_obs = 2, n_individuals = 1) |>
    set_structure(example_structure())
}

test_that("an anipoint's metadata round-trips identically", {
  skip_if_not_installed("jsonlite")
  x <- example_anipoint(n_obs = 2, n_individuals = 2)
  expect_identical(get_metadata(round_trip(x)), get_metadata(x))
})

test_that("a structure round-trips identically", {
  skip_if_not_installed("jsonlite")
  x <- structured()
  expect_identical(get_metadata(round_trip(x)), get_metadata(x))
  expect_identical(get_structure(round_trip(x)), get_structure(x))
})

test_that("anisegment, anijoint and anievent metadata round-trip identically", {
  skip_if_not_installed("jsonlite")
  segments <- as_anisegment(structured())
  joints <- as_anijoint(structured())
  events <- anievent(data.frame(
    individual = 1,
    channel = "behaviour",
    type = "state",
    label = "rest",
    start = 0,
    stop = 1
  ))

  for (x in list(segments, joints, events)) {
    expect_identical(get_metadata(round_trip(x)), get_metadata(x))
  }
})

test_that("every awkward value survives the round trip", {
  skip_if_not_installed("jsonlite")
  x <- example_anipoint(n_obs = 2, n_individuals = 1) |>
    set_metadata(
      source = "sleap",
      source_sampling_rate = NaN,
      filename = "a b.h5",
      sampling_rate = 29.97,
      start_datetime = "2024-05-01 10:00:00.123456",
      unit_space = "mm",
      handedness = "right",
      euler_sequence = "zyx",
      euler_intrinsic = TRUE
    ) |>
    set_axis_directions(c(x = "right", y = "down")) |>
    set_metadata(axis_extents = c(x = 640, y = 480))

  y <- round_trip(x)

  expect_identical(get_metadata(y), get_metadata(x))
  expect_true(is.nan(get_metadata(y, "source_sampling_rate")))
  expect_identical(
    attr(get_metadata(y, "start_datetime"), "tzone"),
    attr(get_metadata(x, "start_datetime"), "tzone")
  )
})

test_that("the layout is readable without R", {
  skip_if_not_installed("jsonlite")
  x <- example_anipoint(n_obs = 2, n_individuals = 1) |>
    set_metadata(
      sampling_rate = 29.97,
      source_sampling_rate = NaN,
      start_datetime = "2024-05-01 10:00:00"
    )
  json <- jsonlite::fromJSON(get_metadata_json(x), simplifyVector = FALSE)

  expect_identical(names(json)[1], "spec_version")
  expect_identical(json$time$unit_time, "frame")
  expect_identical(json$time$sampling_rate, 29.97)
  expect_identical(json$recording$source_sampling_rate, "NaN")
  expect_null(json$recording$source)
  expect_match(json$time$start_datetime, "^\\d{4}-\\d{2}-\\d{2}T.*Z$")
  expect_type(json$time$start_timezone, "character")
  # A slot of columns is an array even with one entry; a role map an object
  expect_identical(json$variables$when$index, list("time"))
  expect_identical(json$variables$where$position, list(x = "x", y = "y"))
  expect_identical(json$structure, stats::setNames(list(), character()))
})

test_that("numbers are written as the shortest decimal that reads back", {
  for (x in c(29.97, 0.1 + 0.2, 1 / 3, 1e-300, -0.5, 2^53)) {
    text <- encode_number(x)
    expect_identical(as.numeric(text), x)
  }
  expect_identical(as.character(encode_number(29.97)), "29.97")
  expect_identical(as.character(encode_number(Inf)), "Inf")
  expect_identical(as.character(encode_number(-Inf)), "-Inf")
  expect_identical(decode_scalar("-Inf", numeric()), -Inf)
})

test_that("parsed JSON is accepted as well as a string", {
  skip_if_not_installed("jsonlite")
  x <- structured()
  parsed <- jsonlite::fromJSON(get_metadata_json(x), simplifyVector = FALSE)

  expect_identical(get_metadata(set_metadata_json(x, parsed)), get_metadata(x))
})

test_that("set_metadata_json() refuses what it cannot restore", {
  skip_if_not_installed("jsonlite")
  x <- example_anipoint(n_obs = 2, n_individuals = 1)

  expect_error(set_metadata_json(data.frame(a = 1), get_metadata_json(x)))
  expect_error(set_metadata_json(x, "[1, 2]"), "JSON object of metadata")
  expect_error(
    set_metadata_json(x, '{"recording": {"colour": "red"}}'),
    "Unknown metadata field"
  )
})
