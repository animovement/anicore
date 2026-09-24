# ---- Construction --------------------------------------------------------

test_that("anievent() builds an object with the expected class chain", {
  ae <- anievent(
    individual = c(1L, 1L, 1L),
    channel = c("behaviour", "behaviour", "call"),
    label = c("REM", "wake", "alarm"),
    start = c(3, 14, 4.5),
    stop = c(9, 19, 4.5)
  )

  expect_s3_class(ae, "anievent")
  expect_s3_class(ae, "tbl_df")
  # an anievent inherits the shared aniframe substrate, but is not an anipoint
  expect_s3_class(ae, "aniframe")
  expect_false(inherits(ae, "anipoint"))
})

test_that("as_anievent() coerces a plain data.frame", {
  df <- data.frame(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9,
    stringsAsFactors = FALSE
  )

  ae <- as_anievent(df)
  expect_s3_class(ae, "anievent")
})

test_that("anievent() accepts a single data.frame as its only argument", {
  df <- dplyr::tibble(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )

  ae <- anievent(df)
  expect_s3_class(ae, "anievent")
})

test_that("as_anievent() on an existing anievent is a no-op", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )

  expect_identical(as_anievent(ae), ae)
})

test_that("as_anievent() repairs an anievent serialised before the superclass", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )

  old <- ae
  class(old) <- setdiff(class(old), "aniframe")

  repaired <- as_anievent(old)
  expect_identical(repaired, ae)
  expect_equal(class(repaired)[1:2], c("anievent", "aniframe"))

  # a downstream subclass keeps dispatch priority over the parent
  sub <- old
  class(sub) <- c("anievent_sub", class(sub))
  expect_equal(
    class(as_anievent(sub))[1:3],
    c("anievent_sub", "anievent", "aniframe")
  )
})

test_that("anievent standardises column types", {
  ae <- anievent(
    individual = c("a", "b"),
    channel = factor(c("behaviour", "call")),
    label = c("REM", "alarm"),
    start = c(3L, 4L),
    stop = c(9L, 4L)
  )

  expect_s3_class(ae$individual, "factor")
  expect_type(ae$channel, "character")
  expect_s3_class(ae$label, "factor")
  expect_type(ae$start, "double")
  expect_type(ae$stop, "double")
})

test_that("anievent metadata gets anievent-flavoured defaults", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )

  expect_equal(get_variables(ae, "what"), "individual")
  expect_equal(get_variables(ae, "when"), c("start", "stop"))
  expect_length(get_variables(ae, "when", "keys"), 0)
  expect_length(get_variables(ae, "where"), 0)
  # and no space category at all (#73, #118)
  expect_null(get_metadata(ae, "space"))
})

test_that("anievent auto-detects recognised identity columns", {
  ae <- anievent(
    subject = c("a", "b"),
    channel = c("behaviour", "behaviour"),
    label = c("REM", "wake"),
    start = c(3, 14),
    stop = c(9, 19)
  )

  expect_equal(get_variables(ae, "what"), "subject")
})

test_that("anievent accepts an explicit non-default identity column", {
  ae <- anievent(
    rat = c("a", "b"),
    channel = c("behaviour", "behaviour"),
    label = c("REM", "wake"),
    start = c(3, 14),
    stop = c(9, 19),
    variables_what = "rat"
  )

  expect_equal(get_variables(ae, "what"), "rat")
  expect_s3_class(ae$rat, "factor")
})

test_that("anievent works with no identity column", {
  ae <- anievent(
    channel = c("behaviour", "behaviour"),
    label = c("REM", "wake"),
    start = c(3, 14),
    stop = c(9, 19)
  )

  expect_s3_class(ae, "anievent")
  expect_length(get_variables(ae, "what"), 0)
})

test_that("anievent auto-detects observation / session / trial into the when keys", {
  ae <- anievent(
    individual = c(1L, 1L, 1L, 1L),
    observation = c("clip_a", "clip_a", "clip_b", "clip_b"),
    trial = c(1L, 1L, 2L, 2L),
    channel = c("behaviour", "behaviour", "behaviour", "behaviour"),
    label = c("REM", "wake", "REM", "wake"),
    start = c(3, 14, 1, 7),
    stop = c(9, 19, 5, 12)
  )

  expect_equal(get_variables(ae, "when", "keys"), c("observation", "trial"))
  expect_setequal(
    get_variables(ae, "when"),
    c("observation", "trial", "start", "stop")
  )
})

test_that("anievent coerces auto-detected grouping columns to factor / integer", {
  ae <- anievent(
    individual = 1L,
    observation = c("clip_a", "clip_a"),
    trial = c(1L, 2L),
    channel = c("behaviour", "behaviour"),
    label = c("REM", "wake"),
    start = c(3, 14),
    stop = c(9, 19)
  )

  expect_s3_class(ae$observation, "factor")
  expect_type(ae$trial, "integer")
})

test_that("anievent column ordering mirrors aniframe (what, when incl start/stop, payload)", {
  ae <- anievent(
    individual = 1L,
    observation = "clip_a",
    trial = 1L,
    modifiers = list(character()),
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )

  expect_equal(
    names(ae),
    c(
      "individual",
      "observation",
      "trial",
      "start",
      "stop",
      "channel",
      "type",
      "label",
      "modifiers"
    )
  )
})

test_that("optional modifiers list-column is preserved", {
  ae <- anievent(
    individual = c(1L, 1L),
    channel = c("behaviour", "behaviour"),
    label = c("REM", "REM"),
    start = c(3, 14),
    stop = c(9, 19),
    modifiers = list(
      c("limb", "whisker"),
      "tail"
    )
  )

  expect_true("modifiers" %in% names(ae))
  expect_type(ae$modifiers, "list")
  expect_equal(ae$modifiers[[1]], c("limb", "whisker"))
})

# ---- Validation ---------------------------------------------------------

test_that("validate_anievent rejects missing required columns", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )
  ae$label <- NULL

  expect_error(validate_anievent(ae), "Missing required")
})

test_that("validate_anievent rejects wrong column types", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )
  bad_channel <- ae
  bad_channel$channel <- factor(bad_channel$channel)
  expect_error(validate_anievent(bad_channel), "must be character")

  bad_label <- ae
  bad_label$label <- as.character(bad_label$label)
  expect_error(validate_anievent(bad_label), "must be a factor")

  bad_start <- ae
  bad_start$start <- as.character(bad_start$start)
  expect_error(validate_anievent(bad_start), "start must be numeric")

  bad_stop <- ae
  bad_stop$stop <- as.character(bad_stop$stop)
  expect_error(validate_anievent(bad_stop), "stop must be numeric")
})

test_that("validate_anievent warns (by default) on overlapping bouts in the same channel for the same subject", {
  ae <- anievent(
    individual = c(1L, 1L),
    channel = c("behaviour", "behaviour"),
    label = c("REM", "wake"),
    start = c(3, 5),
    stop = c(8, 10)
  )

  expect_warning(validate_anievent(ae), "overlap")
})

test_that("validate_anievent accepts overlapping bouts on different channels", {
  ae <- anievent(
    individual = c(1L, 1L),
    channel = c("behaviour", "call"),
    label = c("REM", "alarm"),
    start = c(3, 5),
    stop = c(8, 5)
  )

  expect_no_error(validate_anievent(ae))
})

test_that("validate_anievent accepts overlapping bouts in the same channel across subjects", {
  ae <- anievent(
    individual = c(1L, 2L),
    channel = c("behaviour", "behaviour"),
    label = c("REM", "REM"),
    start = c(3, 4),
    stop = c(8, 9)
  )

  expect_no_error(validate_anievent(ae))
})

test_that("validate_anievent rejects negative intervals", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 9,
    stop = 3
  )

  expect_error(validate_anievent(ae), "greater than or equal")
})

test_that("validate_anievent rejects malformed modifiers", {
  ae <- anievent(
    individual = c(1L, 1L),
    channel = c("behaviour", "behaviour"),
    label = c("REM", "REM"),
    start = c(3, 14),
    stop = c(9, 19),
    modifiers = list(
      1:3,
      character()
    )
  )

  expect_error(validate_anievent(ae), "character vector")
})

test_that("validate_anievent rejects a modifiers column that isn't a list", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )
  ae$modifiers <- "not a list"

  expect_error(validate_anievent(ae), "must be a list-column")
})

test_that("validate_anievent accepts well-formed modifiers", {
  ae <- anievent(
    individual = c(1L, 1L, 1L),
    channel = c("behaviour", "behaviour", "call"),
    label = c("REM", "REM", "alarm"),
    start = c(3, 14, 4.5),
    stop = c(9, 19, 4.5),
    modifiers = list(
      c("limb", "whisker"),
      "tail",
      character()
    )
  )

  expect_no_error(validate_anievent(ae))
})

test_that("type auto-derives from start/stop when not supplied", {
  ae <- anievent(
    individual = c(1L, 1L, 1L),
    channel = c("behaviour", "behaviour", "call"),
    label = c("REM", "wake", "alarm"),
    start = c(3, 14, 4.5),
    stop = c(9, 19, 4.5) # middle bout (after arrange): start == stop -> point
  )
  expect_s3_class(ae$type, "factor")
  expect_equal(levels(ae$type), c("state", "point"))
  # Sorted by start, so the point bout sits second.
  expect_equal(
    as.character(ae$type),
    c("state", "point", "state")
  )
})

test_that("type auto-derive is per (channel, label) — mixed-duration group is uniformly state", {
  # REM has a durative and a single-frame bout; any durative bout makes the
  # whole group state.
  ae <- anievent(
    individual = c(1L, 1L, 1L),
    channel = c("behaviour", "behaviour", "call"),
    label = c("REM", "REM", "alarm"),
    start = c(3, 14, 4.5),
    stop = c(9, 14, 4.5)
  )
  by_key <- split(
    as.character(ae$type),
    paste(ae$channel, as.character(ae$label), sep = "/")
  )
  expect_setequal(by_key[["behaviour/REM"]], "state")
  expect_setequal(by_key[["call/alarm"]], "point")
})

test_that("type override wins over auto-derive", {
  # Every bout has start == stop, so auto-derive alone would say "point".
  ae <- anievent(
    individual = 1L,
    channel = "motif",
    label = "M1",
    start = 1,
    stop = 1,
    type = "state"
  )
  expect_equal(as.character(ae$type), "state")
})

test_that("type rejects values outside state/point", {
  expect_error(
    anievent(
      individual = 1L,
      channel = "behaviour",
      label = "REM",
      start = 1,
      stop = 3,
      type = "transient"
    ),
    "must be"
  )
})

test_that("validate_anievent rejects wrong type levels", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 1,
    stop = 3
  )
  ae$type <- factor("state", levels = c("state", "point", "extra"))
  expect_error(
    validate_anievent(ae),
    "levels exactly"
  )
})

test_that("validate_anievent rejects non-factor type", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 1,
    stop = 3
  )
  ae$type <- as.character(ae$type)
  expect_error(
    validate_anievent(ae),
    "factor with levels"
  )
})

test_that("validate_anievent returns the input invisibly on success", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )

  expect_identical(validate_anievent(ae), ae)
})

# ---- Predicates ---------------------------------------------------------

test_that("is_anievent / ensure_is_anievent work as expected", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )

  expect_true(is_anievent(ae))
  expect_false(is_anievent(data.frame()))
  expect_no_error(ensure_is_anievent(ae))
  expect_error(ensure_is_anievent(data.frame()), "not an anievent")
})

# ---- Spatial metadata is not applicable to an anievent (#73) ------------

test_that("an anievent does not claim a spatial layout it cannot have", {
  # BORIS imports used to announce a coordinate system inherited from the
  # movement defaults.
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = c("REM", "wake"),
    start = c(1, 4),
    stop = c(3, 5)
  )
  # An absent `space` category (#118), so every spatial field reads as NULL.
  expect_null(get_metadata(ae, "space"))
  expect_null(get_metadata(ae, "reference_frame"))
  expect_null(get_metadata(ae, "unit_space"))
  expect_null(get_metadata(ae, "coordinate_system"))
  expect_equal(get_angle_direction(ae), "unknown")
  expect_equal(get_handedness(ae), "unknown")
})

test_that("spatial metadata passed to an anievent is dropped", {
  build <- function(metadata) {
    anievent(
      individual = 1L,
      channel = "behaviour",
      label = c("REM", "wake"),
      start = c(1, 4),
      stop = c(3, 5),
      metadata = metadata
    )
  }

  ae <- build(list(unit_space = "none", coordinate_system = "unknown"))
  expect_null(get_metadata(ae, "space"))

  ae <- build(list(unit_space = "mm", handedness = "unknown", source = "x"))
  expect_null(get_metadata(ae, "space"))
  expect_equal(get_metadata(ae, "source"), "x")
})

test_that("an aniframe keeps its movement defaults", {
  af <- anipoint(time = 1:3, x = 1:3, y = 1:3)

  expect_equal(as.character(get_metadata(af, "reference_frame")), "allocentric")
  expect_equal(as.character(get_metadata(af, "unit_space")), "px")
  expect_equal(as.character(get_metadata(af, "unit_angle")), "rad")
})

test_that("to_anievent does not carry the host frame's spatial metadata over", {
  af <- anipoint(
    individual = rep(1L, 5),
    time = 1:5,
    x = 1:5,
    y = 1:5,
    behaviour = factor(c("REM", "REM", "wake", "wake", "wake"))
  )
  af <- set_variables(af, event = list(state = "behaviour"))
  af <- set_metadata(af, sampling_rate = 30, unit_time = "s")

  ae <- to_anievent(af)

  expect_null(get_metadata(ae, "space"))
  expect_null(get_metadata(ae, "unit_space"))
  expect_null(get_metadata(ae, "reference_frame"))
  # Fields that do mean something for bouts are still inherited.
  expect_equal(get_metadata(ae, "sampling_rate"), 30)
  expect_equal(as.character(get_metadata(ae, "unit_time")), "s")
})

test_that("the neutral values are permitted on an aniframe too", {
  af <- anipoint(time = 1:3, x = 1:3, y = 1:3)
  af <- set_metadata(af, reference_frame = "none", unit_space = "none")

  expect_equal(as.character(get_metadata(af, "reference_frame")), "none")
})

test_that("a pre-superclass anievent is pointed at as_anievent()", {
  old <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )
  class(old) <- setdiff(class(old), "aniframe")

  expect_error(ensure_is_aniframe(old), "as_anievent")
})
