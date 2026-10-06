# The index (#109) ----

test_that("a frame with no declaration is indexed by time", {
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))

  expect_equal(get_index(af), "time")
  # The when keys are the temporal *context*, and this frame has none.
  expect_equal(get_variables(af, "when", "keys"), character(0))
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
  expect_false("frame" %in% get_variables(af, "when", "keys"))
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
  # Grouping by the old index would put every row in its own group, so it
  # becomes an ordinary undeclared column.
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

# set_index() declares the unit and keeps frame numbers (#190) ----

# Two keypoints over frames 0 to 4, frames counted from 0.
two_keypoints <- function() {
  as_anipoint(data.frame(
    individual = "a",
    keypoint = rep(c("head", "tail"), each = 5),
    time = rep(0:4, 2),
    x = 1:10,
    y = 1:10
  ))
}

test_that("set_index() declares the unit of the new index", {
  af <- dplyr::mutate(two_keypoints(), timestamp = time / 30)

  result <- set_index(af, "timestamp", unit = "s")

  expect_equal(get_index(result), "timestamp")
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
  expect_equal(get_sampling_interval(result), 1 / 30)
})

test_that("set_index() leaves the unit alone without one", {
  af <- dplyr::mutate(two_keypoints(), tick = time * 2)

  result <- set_index(af, "tick")

  expect_equal(as.character(get_metadata(result, "unit_time")), "frame")
  # Declaring the unit of the current index changes nothing else.
  same <- set_index(two_keypoints(), "time", unit = "s")
  expect_equal(get_index(same), "time")
  expect_equal(as.character(get_metadata(same, "unit_time")), "s")
})

test_that("set_index() rejects a unit that is not a unit_time level", {
  af <- two_keypoints()

  for (bad in list("sec", c("s", "ms"), NA_character_, 1)) {
    expect_error(set_index(af, "time", unit = bad), "must be one of")
  }
})

test_that("set_index() moves an index that counts frames to a frame column", {
  af <- dplyr::mutate(two_keypoints(), timestamp = time / 30)

  result <- set_index(af, "timestamp", unit = "s")

  expect_false("time" %in% names(result))
  expect_equal(result$frame, rep(0:4, 2))
  expect_false("frame" %in% get_variables(result, "when"))
})

test_that("the frame numbers set_index() keeps become the index again", {
  af <- dplyr::mutate(two_keypoints(), timestamp = time / 30.11)

  frames <- af |>
    set_index("timestamp", unit = "s") |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("frame")

  expect_equal(get_index(frames), "frame")
  expect_equal(frames$frame, rep(0:4, 2))
  expect_equal(as.character(get_metadata(frames, "unit_time")), "frame")
  expect_equal(frames$timestamp, rep(0:4, 2) / 30.11)
})

test_that("an index in another unit keeps its name", {
  af <- two_keypoints() |>
    set_metadata(unit_time = "s") |>
    dplyr::mutate(tick = time * 1000)

  result <- set_index(af, "tick", unit = "ms")

  expect_equal(result$time, rep(0:4, 2))
  expect_false("frame" %in% names(result))
})

test_that("an index already named frame, or replaced by one, keeps its name", {
  named <- as_anipoint(
    data.frame(frame = 0:2, individual = "a", x = 1:3, y = 1:3),
    index = "frame"
  ) |>
    dplyr::mutate(timestamp = frame / 30)
  result <- set_index(named, "timestamp", unit = "s")
  expect_equal(result$frame, 0:2)

  replaced <- dplyr::mutate(two_keypoints(), frame = time + 100)
  result <- set_index(replaced, "frame")
  expect_equal(get_index(result), "frame")
  expect_equal(result$time, rep(0:4, 2))
})

test_that("set_index() refuses to overwrite another frame column", {
  af <- dplyr::mutate(two_keypoints(), frame = 7, timestamp = time / 30)

  expect_error(
    set_index(af, "timestamp", unit = "s"),
    "already has a column named"
  )
})

test_that("set_index() needs the new index to increase within each key", {
  af <- dplyr::mutate(two_keypoints(), backwards = 10 - time)

  expect_error(set_index(af, "backwards"), "must increase with")
  expect_error(set_index(af, "backwards"), "individual, keypoint")
  expect_error(set_index(af, "backwards"), "goes from 10 to 9")

  # Each key on its own scale is fine.
  per_key <- dplyr::mutate(
    two_keypoints(),
    offset = time + ifelse(keypoint == "head", 100, 0)
  )
  expect_equal(get_index(set_index(per_key, "offset")), "offset")
})

test_that("set_index() refuses missing values and date-times", {
  af <- two_keypoints()

  expect_error(
    set_index(dplyr::mutate(af, gappy = ifelse(time == 2, NA, time)), "gappy"),
    "missing values"
  )
  stamped <- dplyr::mutate(
    af,
    clock = as.POSIXct("2026-01-01", tz = "UTC") + time
  )
  expect_error(set_index(stamped, "clock"), "start_datetime")
})

test_that("a camera log is matched to rows by frame number", {
  # The tail is missing from frame 2, and frame 3 was dropped altogether;
  # the log has one entry per frame the camera took.
  stamps <- c(0, 0.0332, 0.0668, 0.1001, 0.1333)
  af <- two_keypoints() |>
    dplyr::filter(!(keypoint == "tail" & time == 2), time != 3)

  logged <- af |>
    dplyr::mutate(timestamp = stamps[time + 1]) |>
    set_index("timestamp", unit = "s")

  tail <- dplyr::filter(logged, keypoint == "tail")
  expect_equal(tail$timestamp, stamps[c(0, 1, 4) + 1])
  expect_equal(tail$frame, c(0, 1, 4))
  expect_equal(
    convert_unit_time(logged, "frame")$frame,
    c(0, 1, 2, 4, 0, 1, 4)
  )
})

test_that("set_index() does not check rows that already repeat the old index", {
  # Duplicates of the old index are reported by validate_anipoint().
  af <- as_anipoint(
    data.frame(individual = "a", time = c(0, 1, 1, 2), x = 1:4, y = 1:4)
  ) |>
    dplyr::mutate(tick = c(0, 20, 10, 30))

  expect_equal(get_index(set_index(af, "tick")), "tick")
})

test_that("set_index() works when the old index column is gone", {
  af <- dplyr::mutate(two_keypoints(), tick = time * 2)
  stripped <- drop_column_unchecked(af, "time")

  result <- set_index(stripped, "tick")

  expect_equal(get_index(result), "tick")
  expect_false("frame" %in% names(result))
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

test_that("the when keys never contain the index", {
  # Older frames list the index among the when keys; grouping by it would put
  # every row in its own group, so construction normalises it out.
  af <- as_anipoint(data.frame(
    time = 1:4,
    session = c("a", "a", "b", "b"),
    individual = "x",
    x = 1:4,
    y = 1:4
  ))

  expect_false(get_index(af) %in% get_variables(af, "when", "keys"))
  expect_equal(get_variables(af, "when", "keys"), "session")
  expect_setequal(get_variables(af, "when"), c("time", "session"))
  expect_setequal(dplyr::group_vars(af), c("individual", "session"))
})

test_that("setting a new index does not promote the old one to a grouping variable", {
  af <- anipoint(individual = "a", time = 1:5, x = 1:5, y = 1:5) |>
    dplyr::mutate(frame = c(10, 20, 30, 40, 50))

  result <- set_index(af, "frame")

  expect_equal(dplyr::group_vars(result), "individual")
  expect_equal(dplyr::n_groups(result), 1L)
  expect_false("time" %in% get_variables(result, "when", "keys"))
})

test_that("set_metadata() refuses the index and names its setter", {
  af <- anipoint(individual = "a", time = 1:3, x = c(1, 2, 3), y = c(0, 1, 0))

  expect_error(
    set_metadata(af, variables_index = "x"),
    "set_index"
  )
})

test_that("metadata serialised before the field existed reads back as time", {
  # Before #109 the index sat in variables_when.
  af <- legacy_anipoint(variables_when = "time")
  md <- attr(af, "metadata")
  md$variables_index <- NULL
  attr(af, "metadata") <- md

  expect_equal(get_index(af), "time")
  expect_equal(get_variables(af, "when", "keys"), character())
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

test_that("convert_unit_time() converts the index column", {
  af <- as_anipoint(
    data.frame(frame = c(1, 2, 3), individual = "a", x = 1:3, y = 1:3),
    index = "frame"
  ) |>
    set_metadata(unit_time = "frame")

  result <- convert_unit_time(af, "s", calibration_factor = 1 / 30)

  expect_equal(result$frame, c(1, 2, 3) / 30)
  expect_equal(as.character(get_metadata(result, "unit_time")), "s")
})

test_that("convert_unit_time() rescales the index column by the declared rate", {
  af <- as_anipoint(
    data.frame(frame = c(1, 2, 3), individual = "a", x = 1:3, y = 1:3),
    index = "frame"
  ) |>
    set_metadata(unit_time = "frame", sampling_rate = 30)

  result <- convert_unit_time(af, "s")

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
    set_variables(event = list(state = "behaviour"))

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
    set_variables(event = list(state = "behaviour")) |>
    to_anievent()

  # The `when` role carries an interval instead of an index (#118)
  expect_null(get_metadata(ae, "variables")$when$index)
  expect_equal(get_metadata(ae, "variables")$when$interval, c("start", "stop"))
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
  dropped <- drop_column_unchecked(af, "frame")

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

test_that("the default metadata skeleton keeps the index out of the when keys", {
  when <- list_default_metadata()$variables$when

  expect_equal(when$index, "time")
  expect_false(when$index %in% when$keys)
})

# Keys plus index identify an observation (#49) ----

test_that("validate_anipoint() warns when keys and index repeat", {
  # Whatever tells these rows apart is undeclared, so grouped operations
  # fold them together.
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
    warn_duplicate_observations(add_variables(af, what = "keypoint"))
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

  expect_equal(get_variables(af, "when", "keys"), "session")
  expect_setequal(get_variables(af, "when"), c("time", "session"))
  expect_no_warning(warn_duplicate_observations(af))
})

test_that("there is nothing to check when no key column is present", {
  # Only reachable directly: via `validate_anipoint()` the index check aborts
  # first.
  af <- suppressWarnings(as_anipoint(
    data.frame(time = 1:3, x = 1:3, y = 1:3),
    variables_what = character(0)
  ))
  stripped <- drop_column_unchecked(af, "time")

  expect_no_warning(warn_duplicate_observations(stripped))
  expect_true(warn_duplicate_observations(stripped))
})
