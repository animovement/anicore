# The metadata category tree (#118): nested storage, flat access.

af <- function() {
  suppressMessages(as_anipoint(
    data.frame(time = 1:3, individual = "a", x = 1:3, y = c(0, 1, 0))
  ))
}

ae <- function() {
  anievent(
    individual = 1L,
    channel = "behaviour",
    label = c("REM", "wake"),
    start = c(1, 4),
    stop = c(3, 5)
  )
}

# ---- The tree ----------------------------------------------------------

test_that("the default tree carries the decided categories", {
  md <- list_default_metadata()
  expect_named(
    unclass(md),
    c("spec_version", list_metadata_categories()),
    ignore.order = TRUE
  )
  expect_named(
    md$variables,
    c("what", "when", "where", "event"),
    ignore.order = TRUE
  )
})

test_that("the anievent tree has no space, and an interval instead of an index", {
  md <- list_default_metadata("anievent")
  expect_false("space" %in% names(unclass(md)))
  expect_equal(md$variables$when$interval, c("start", "stop"))
  expect_null(md$variables$when$index)
  expect_false("where" %in% names(md$variables))
})

# ---- Flat access over nested storage ----------------------------------

test_that("get_metadata() resolves a field by name wherever it lives", {
  data <- set_metadata(af(), sampling_rate = 30, source = "test")
  expect_equal(get_metadata(data, "sampling_rate"), 30)
  expect_equal(get_metadata(data, "source"), "test")
  expect_equal(as.character(get_metadata(data, "handedness")), "unknown")
})

test_that("a category name returns the whole category", {
  space <- get_metadata(af(), "space")
  expect_type(space, "list")
  expect_true(all(c("coordinate_system", "unit_space") %in% names(space)))
})

test_that("set_metadata() writes a field into its category", {
  data <- set_metadata(af(), handedness = "left")
  md <- attr(data, "metadata")
  expect_equal(as.character(md$space$handedness), "left")
})

test_that("set_metadata() refuses category writes", {
  expect_error(set_metadata(af(), space = list()), "not categories")
  expect_error(set_metadata(af(), variables = list()), "cannot write")
  expect_error(set_metadata(af(), structure = list()), "cannot write")
})

test_that("a space field cannot be set on an anievent", {
  expect_error(set_metadata(ae(), unit_space = "mm"), "space")
})

# ---- The classed metadata object --------------------------------------

test_that("$ and [[ on the metadata object resolve flat", {
  md <- get_metadata(set_metadata(af(), sampling_rate = 30))
  expect_equal(md$sampling_rate, 30)
  expect_equal(md[["sampling_rate"]], 30)
  expect_type(md$recording, "list")
  expect_null(md$not_a_field)
})

# ---- Legacy flat metadata migrates on write ----------------------------

test_that("a legacy flat metadata list migrates to the tree on restore", {
  legacy <- list(
    source = "old",
    source_version = NA_character_,
    filename = NA_character_,
    sampling_rate = 25,
    start_datetime = as.POSIXct(NA),
    variables_index = "frame",
    variables_what = "individual",
    variables_when = "trial",
    variables_where = c("x", "y"),
    axes = c(x = "x", y = "y"),
    unit_space = factor("px", levels = c("px", "none", "mm")),
    unit_angle = factor("rad", levels = c("rad", "deg", "none")),
    unit_time = factor("frame", levels = c("unknown", "frame", "s")),
    reference_frame = factor("allocentric"),
    coordinate_system = factor("cartesian_2d"),
    axis_directions = stats::setNames(character(), character()),
    axis_extents = stats::setNames(numeric(), character()),
    handedness = factor("unknown"),
    connections = list()
  )

  data <- data.frame(
    trial = 1L,
    individual = "a",
    frame = 1:3,
    x = 1:3,
    y = 1:3
  )
  restored <- set_metadata(
    suppressMessages(as_anipoint(data, index = "frame")),
    metadata = legacy
  )
  md <- attr(restored, "metadata")

  expect_true(is_nested_metadata(md))
  expect_equal(md$recording$source, "old")
  expect_equal(md$time$sampling_rate, 25)
  expect_equal(md$variables$what$keys, "individual")
  expect_equal(md$variables$when$index, "frame")
  expect_equal(md$variables$when$keys, "trial")
  expect_equal(md$variables$where$position, c(x = "x", y = "y"))
})

test_that("legacy anievent metadata migrates without a space category", {
  legacy <- unclass(get_metadata(ae()))
  flat <- c(
    legacy$recording,
    legacy$time,
    list(
      spec_version = legacy$spec_version,
      variables_what = "individual",
      variables_when = c("start", "stop"),
      variables_where = character(),
      unit_space = "none",
      connections = list()
    )
  )

  migrated <- migrate_metadata_layout(flat)
  expect_false("space" %in% names(unclass(migrated)))
  expect_equal(migrated$variables$when$interval, c("start", "stop"))
})

# ---- Round trips -------------------------------------------------------

test_that("metadata survives a get/set round trip unchanged", {
  data <- set_metadata(af(), sampling_rate = 30, handedness = "right")
  again <- set_metadata(data, metadata = get_metadata(data))
  expect_identical(
    unclass(attr(again, "metadata")),
    unclass(attr(data, "metadata"))
  )
})

test_that("dplyr operations carry the tree through unchanged", {
  data <- set_metadata(af(), sampling_rate = 30)
  out <- dplyr::mutate(data, x2 = x * 2)
  expect_identical(get_metadata(out, "sampling_rate"), 30)
  expect_true(is_nested_metadata(attr(out, "metadata")))
})
