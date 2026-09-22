# The index (#109) ----

test_that("a frame with no declaration is indexed by time", {
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))

  expect_equal(get_index(af), "time")
  # `variables_when` is the temporal *context*, and this frame has none.
  expect_equal(get_variables_when(af), character(0))
})

test_that("a frame can be indexed by a column that is not called time", {
  df <- data.frame(
    frame = 1:3,
    individual = "a",
    x = c(1, 2, 3),
    y = c(0, 1, 0)
  )

  af <- as_anipoint(df, index = "frame")

  expect_equal(get_index(af), "frame")
  # The index is declared separately, never as temporal context.
  expect_false("frame" %in% get_variables_when(af))
  # No column literally named `time` is required any more.
  expect_false("time" %in% names(af))
})

test_that("the index is numeric and the temporal context is not", {
  df <- data.frame(
    frame = c(1, 2, 1, 2),
    session = c("a", "a", "b", "b"),
    individual = "x",
    x = 1:4,
    y = 1:4
  )

  af <- as_anipoint(df, index = "frame")

  expect_true(is.numeric(af$frame))
  expect_s3_class(af$session, "factor")
})

test_that("the frame is grouped by identity and context, never by the index", {
  df <- data.frame(
    frame = c(1, 2, 1, 2),
    session = c("a", "a", "b", "b"),
    individual = "x",
    x = 1:4,
    y = 1:4
  )

  af <- as_anipoint(df, index = "frame")

  expect_setequal(dplyr::group_vars(af), c("individual", "session"))
  expect_false("frame" %in% dplyr::group_vars(af))
})

test_that("set_index() moves the index and regroups the frame", {
  af <- anipoint(
    individual = "a",
    time = 1:3,
    x = c(1, 2, 3),
    y = c(0, 1, 0)
  ) |>
    dplyr::mutate(tick = c(10, 20, 30))

  result <- set_index(af, "tick")

  expect_equal(get_index(result), "tick")
  # The column the frame *was* indexed by must not become a grouping
  # variable: holding one value per row, it would put every row in its own
  # group. It becomes an ordinary undeclared column instead.
  expect_false("time" %in% dplyr::group_vars(result))
  expect_false("tick" %in% dplyr::group_vars(result))
  expect_equal(dplyr::n_groups(result), 1L)
})

test_that("set_index() rejects a column that cannot be an index", {
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))

  expect_error(set_index(af, "absent"), "not present")
  expect_error(set_index(af, "individual"), "must be numeric")
  expect_error(set_index(af, c("time", "x")), "single column name")
})

test_that("as_anipoint() aborts when the declared index is absent", {
  df <- data.frame(
    frame = 1:3,
    individual = "a",
    x = c(1, 2, 3),
    y = c(0, 1, 0)
  )

  expect_error(as_anipoint(df, index = "nope"), "not found in data")
})

test_that("variables_when never contains the index", {
  # Frames built before the field existed list the index in
  # `variables_when`. Carrying that through would group by it, putting
  # every row in its own group, so it is normalised out on construction.
  af <- as_anipoint(data.frame(
    time = 1:4,
    session = c("a", "a", "b", "b"),
    individual = "x",
    x = 1:4,
    y = 1:4
  ))

  expect_false(get_index(af) %in% get_variables_when(af))
  expect_equal(get_variables_when(af), "session")
  expect_setequal(dplyr::group_vars(af), c("individual", "session"))
})

test_that("setting a new index does not promote the old one to a grouping variable", {
  af <- anipoint(individual = "a", time = 1:5, x = 1:5, y = 1:5) |>
    dplyr::mutate(frame = c(10, 20, 30, 40, 50))

  result <- set_index(af, "frame")

  expect_equal(dplyr::group_vars(result), "individual")
  expect_equal(dplyr::n_groups(result), 1L)
  expect_false("time" %in% get_variables_when(result))
})

test_that("set_metadata() refuses the index and names its setter", {
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))

  expect_error(
    set_metadata(af, variables_index = "x"),
    "set_index"
  )
})

test_that("metadata serialised before the field existed reads back as time", {
  # `variables_index` is optional precisely so that objects written by
  # earlier versions still validate. They were built when a column named
  # `time` was mandatory, so that is what they are indexed by.
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))
  md <- get_metadata(af)
  md[["variables_index"]] <- NULL

  expect_true(has_all_metadata_fields(md))
  expect_equal(resolve_index(md), "time")
})


# The index is exactly one column ----

test_that("as_anipoint() rejects an index that is not a single column name", {
  # Unguarded, this fell back to `"time"` instead of complaining.
  df <- data.frame(
    time = 1:4,
    frame = c(1, 2, 3, 4),
    individual = "a",
    x = 1:4,
    y = 1:4
  )

  expect_error(
    as_anipoint(df, index = c("frame", "time")),
    "single column name"
  )
  expect_error(as_anipoint(df, index = character(0)), "single column name")
  expect_error(as_anipoint(df, index = 3), "single column name")
  expect_error(as_anipoint(df, index = NA_character_), "single column name")
})

test_that("anipoint() can declare an index too", {
  af <- anipoint(
    individual = "a",
    frame = 1:3,
    x = c(1, 2, 3),
    y = c(0, 1, 0),
    index = "frame"
  )

  expect_equal(get_index(af), "frame")
  expect_false("time" %in% names(af))
})


# Everything temporal follows the index, not the name `time` ----

test_that("set_unit_time() converts the index column", {
  af <- as_anipoint(
    data.frame(frame = c(1, 2, 3), individual = "a", x = 1:3, y = 1:3),
    index = "frame"
  ) |>
    set_metadata(unit_time = "frame")

  result <- set_unit_time(af, "s", calibration_factor = 1 / 30)

  expect_equal(result$frame, c(1, 2, 3) / 30)
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
})

test_that("set_sampling_rate() rescales the index column", {
  af <- as_anipoint(
    data.frame(frame = c(1, 2, 3), individual = "a", x = 1:3, y = 1:3),
    index = "frame"
  ) |>
    set_metadata(unit_time = "frame")

  result <- set_sampling_rate(af, 30)

  expect_equal(result$frame, c(1, 2, 3) / 30)
  expect_equal(get_metadata(result, "sampling_rate"), 30)
})

test_that("to_anievent() delimits bouts by the host frame's index", {
  af <- as_anipoint(
    data.frame(
      frame = c(10, 20, 30, 40),
      individual = "a",
      x = 1:4,
      y = 1:4,
      behaviour = c("rest", "rest", "walk", "walk")
    ),
    index = "frame"
  ) |>
    set_variables_event(state = "behaviour")

  ae <- to_anievent(af)

  expect_equal(ae$start, c(10, 30))
  expect_equal(ae$stop, c(20, 40))
})


# An anievent has no index ----

test_that("an anievent declares no index", {
  ae <- as_anipoint(
    data.frame(
      time = 1:4,
      individual = "a",
      x = 1:4,
      y = 1:4,
      behaviour = c("rest", "rest", "walk", "walk")
    )
  ) |>
    set_variables_event(state = "behaviour") |>
    to_anievent()

  expect_true(is.na(get_metadata(ae, "variables_index")))
  expect_error(get_index(ae), "no index column")
})


# The validator knows about the index ----

test_that("get_declared_variables() reports the index alongside the other roles", {
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))

  declared <- get_declared_variables(get_metadata(af))

  expect_true("variables_index" %in% names(declared))
  expect_equal(declared$variables_index, "time")
})

test_that("validate_anipoint() catches an index column that has been dropped", {
  af <- as_anipoint(
    data.frame(frame = c(1, 2, 3), individual = "a", x = 1:3, y = 1:3),
    index = "frame"
  )
  dropped <- af
  dropped$frame <- NULL

  expect_error(validate_anipoint(dropped), "Index column")
})

test_that("validate_anipoint() catches an index column that is no longer numeric", {
  af <- as_anipoint(
    data.frame(frame = c(1, 2, 3), individual = "a", x = 1:3, y = 1:3),
    index = "frame"
  )
  retyped <- af
  retyped$frame <- as.character(retyped$frame)

  expect_error(validate_anipoint(retyped), "must be numeric")
})

test_that("the default metadata skeleton keeps the index out of variables_when", {
  md <- list_default_metadata()

  expect_equal(md$variables_index, "time")
  expect_false(md$variables_index %in% md$variables_when)
})


# Keys plus index identify an observation (#49) ----

test_that("validate_anipoint() warns when keys and index repeat", {
  # Two rows for the same individual at the same time: whatever tells them
  # apart is undeclared, and every grouped operation folds them together.
  af <- as_anipoint(
    data.frame(individual = "a", time = c(1, 2, 2), x = 1:3, y = 1:3)
  )

  expect_warning(validate_anipoint(af), "not uniquely identified")
  expect_warning(validate_anipoint(af), "individual")
})

test_that("validate_anipoint() is quiet when the declaration identifies rows", {
  af <- example_anipoint(n_obs = 4, n_individuals = 2, n_keypoints = 2)

  expect_no_warning(warn_duplicate_observations(af))
})

test_that("declaring the missing variable resolves the duplication", {
  af <- as_anipoint(
    data.frame(
      individual = "a",
      keypoint = c("head", "tail", "head", "tail"),
      time = c(1, 1, 2, 2),
      x = 1:4,
      y = 1:4
    ),
    variables_what = "individual"
  )
  expect_warning(validate_anipoint(af), "not uniquely identified")

  expect_no_warning(
    warn_duplicate_observations(add_variables_what(af, "keypoint"))
  )
})

test_that("the temporal context counts towards the key", {
  # Same individual and index, different session: not a duplicate.
  af <- as_anipoint(
    data.frame(
      individual = "a",
      session = c("s1", "s1", "s2", "s2"),
      time = c(1, 2, 1, 2),
      x = 1:4,
      y = 1:4
    )
  )

  expect_equal(get_variables_when(af), "session")
  expect_no_warning(warn_duplicate_observations(af))
})

test_that("there is nothing to check when no key column is present", {
  # Reachable only by calling the helper directly: through
  # `validate_anipoint()` the index check aborts first. A frame that has
  # drifted this far has bigger problems, and this should not be one of them.
  af <- suppressWarnings(as_anipoint(
    data.frame(time = 1:3, x = 1:3, y = 1:3),
    variables_what = character(0)
  ))
  stripped <- suppressWarnings(dplyr::select(dplyr::ungroup(af), -"time"))

  expect_no_warning(warn_duplicate_observations(stripped))
  expect_true(warn_duplicate_observations(stripped))
})
