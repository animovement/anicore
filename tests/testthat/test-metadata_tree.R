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


# ---- Branch coverage ---------------------------------------------------

test_that("resolve_axes() handles every position shape", {
  md <- unclass(get_metadata(af()))
  empty <- stats::setNames(character(), character())

  # No position at all
  md$variables$where$position <- character()
  expect_equal(resolve_axes(md), empty)

  # Unnamed columns that do name a coordinate system are inferred
  md$variables$where$position <- c("rho", "phi")
  expect_equal(resolve_axes(md), c(rho = "rho", phi = "phi"))
})

test_that("get_connections() answers empty on legacy flat metadata", {
  data <- af()
  legacy <- unclass(get_metadata(data))
  legacy <- c(
    legacy$recording,
    legacy$time,
    legacy$space,
    list(
      variables_what = "individual",
      variables_when = character(),
      variables_where = c("x", "y"),
      variables_index = "time",
      connections = NULL
    )
  )
  data <- attach_metadata(data, legacy)

  expect_equal(get_connections(data), list())
})

test_that("get_unit_angle() is NA on an anievent", {
  expect_true(is.na(get_unit_angle(ae())))
})

test_that("the flat variables names are refused with a redirect", {
  expect_error(get_metadata(af(), "variables_what"), "get_variables_what")
  expect_error(get_metadata(af(), "connections"), "get_connections")
})

test_that("set_metadata() refuses axes with a pointer at set_axes", {
  expect_error(set_metadata(af(), axes = c(x = "x")), "set_axes")
})

test_that("md_field_set() rejects an unknown field", {
  expect_error(
    md_field_set(unclass(get_metadata(af())), "no_such_field", 1),
    "not a metadata field"
  )
})

test_that("legacy metadata carries its event declaration through migration", {
  legacy <- list(
    variables_what = "individual",
    variables_when = character(),
    variables_where = c("x", "y"),
    variables_index = "time",
    variables_event = list(state = "behaviour", point = character()),
    connections = list()
  )

  migrated <- migrate_metadata_layout(legacy)
  expect_equal(migrated$variables$event$state, "behaviour")
})

# ---- Validator branches ------------------------------------------------

test_that("the validator enforces space presence by class", {
  md <- unclass(get_metadata(af()))
  no_space <- md[setdiff(names(md), "space")]

  expect_error(ensure_valid_metadata(no_space, space = TRUE), "requires")
  expect_error(ensure_valid_metadata(md, space = FALSE), "must not carry")
  expect_no_error(ensure_valid_metadata(no_space, space = FALSE))
})

test_that("a missing mandatory leaf fails the type check", {
  md <- unclass(get_metadata(af()))
  md$time$unit_time <- NULL

  expect_error(ensure_valid_metadata(md), "correct types")
})

test_that("the variables shape is validated", {
  base <- unclass(get_metadata(af()))

  bad <- base
  bad$variables <- "not a list"
  expect_error(ensure_valid_metadata_variables(bad), "list of roles")

  bad <- base
  bad$variables$colour <- list(keys = "x")
  expect_error(ensure_valid_metadata_variables(bad), "Unknown variable role")

  bad <- base
  bad$variables$what <- "not a list"
  expect_error(ensure_valid_metadata_variables(bad), "list of slots")

  bad <- base
  bad$variables$what$level <- "individual"
  expect_error(ensure_valid_metadata_variables(bad), "Unknown slot")

  bad <- base
  bad$variables$what$keys <- 1L
  expect_error(ensure_valid_metadata_variables(bad), "character vector")
})

test_that("set_metadata() points connections writes at set_connections", {
  expect_error(set_metadata(af(), connections = list()), "set_connections")
})
