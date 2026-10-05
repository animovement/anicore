# Sampling interval and regularity (#114)

test_that("the interval is derived from the index at construction", {
  af <- example_anipoint(n_obs = 5, n_individuals = 2, n_keypoints = 1)

  expect_equal(get_sampling_interval(af), 1)
  expect_type(get_sampling_interval(af), "double")
})

test_that("the interval is in the unit the index is in", {
  af <- as_anipoint(
    data.frame(
      individual = "a",
      time = seq(0, 0.08, by = 0.02),
      x = 1:5,
      y = 1:5
    )
  )

  expect_equal(get_sampling_interval(af), 0.02)
})

test_that("the interval is measured per key, not pooled", {
  # Both individuals restart at time 1; pooling would see a gap of -4.
  af <- as_anipoint(data.frame(
    individual = rep(c("a", "b"), each = 5),
    time = rep(1:5, 2),
    x = 1:10,
    y = 1:10
  ))

  expect_equal(get_sampling_interval(af), 1)
  expect_true(is_sampling_regular(af))
})

test_that("a frame too short to measure has no interval", {
  af <- example_anipoint(n_obs = 1, n_individuals = 1, n_keypoints = 1)

  expect_true(is.na(get_sampling_interval(af)))
  expect_true(is.na(is_sampling_regular(af)))
})

test_that("an anievent has no interval, having no index", {
  ae <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(b = factor(rep(c("r", "w"), each = 2))) |>
    set_variables(event = list(state = "b")) |>
    to_anievent()

  expect_true(is.na(get_sampling_interval(ae)))
})

# The interval follows the rows and the index (#190) ----

# The issue's worked example: a 300-frame single track.
single_track <- function(n = 300) {
  as_anipoint(data.frame(individual = "a", time = seq_len(n) - 1, x = 1, y = 1))
}

# Overwrites the stored interval, to see whether a verb measures it again.
with_stale_interval <- function(data, interval = 99) {
  md <- attr(data, "metadata")
  md$time$sampling_interval <- interval
  attr(data, "metadata") <- md
  data
}

test_that("filter() measures the interval again (example 5)", {
  af <- single_track() |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s")
  expect_equal(get_sampling_interval(af), 1 / 30)

  every_third <- dplyr::filter(af, dplyr::row_number() %% 3 == 1)

  expect_equal(get_sampling_interval(every_third), 0.1)
  expect_warning(validate_anipoint(every_third), "10 Hz")
})

test_that("slice() and `[` measure the interval again", {
  af <- single_track()

  expect_equal(get_sampling_interval(dplyr::slice(af, seq(1, 300, 2))), 2)
  expect_equal(get_sampling_interval(af[seq(1, 300, 5), ]), 5)
})

test_that("changing the index measures the interval again", {
  af <- single_track()

  expect_equal(get_sampling_interval(dplyr::mutate(af, time = time * 2)), 2)

  replaced <- af
  replaced$time <- replaced$time * 3
  expect_equal(get_sampling_interval(replaced), 3)

  replaced <- af
  replaced[["time"]] <- replaced[["time"]] * 4
  expect_equal(get_sampling_interval(replaced), 4)

  replaced <- af
  replaced[, "time"] <- af$time * 5
  expect_equal(get_sampling_interval(replaced), 5)
})

test_that("changing a key measures the interval again", {
  af <- as_anipoint(data.frame(
    individual = rep(c("a", "b"), each = 5),
    time = c(0:4, 10:14),
    x = 1,
    y = 1
  ))
  stale <- with_stale_interval(af)

  out <- dplyr::mutate(stale, individual = "a")

  # Pooled, the two tracks are one series with a gap of 6 in the middle.
  expect_equal(get_sampling_interval(out), 1)
  expect_equal(compute_sampling_gaps(out), c(rep(1, 4), 6, rep(1, 4)))
})

test_that("verbs that leave the rows and index alone keep the interval", {
  stale <- with_stale_interval(single_track())

  expect_equal(get_sampling_interval(dplyr::mutate(stale, z = x + 1)), 99)
  expect_equal(get_sampling_interval(dplyr::rename(stale, t = time)), 99)
  expect_equal(get_sampling_interval(dplyr::relocate(stale, y)), 99)
  expect_equal(get_sampling_interval(dplyr::select(stale, -y)), 99)
  expect_equal(get_sampling_interval(dplyr::group_by(stale, individual)), 99)
  expect_warning(ungrouped <- dplyr::ungroup(stale), "Ungrouping")
  expect_equal(get_sampling_interval(ungrouped), 99)

  renamed <- stale
  names(renamed)[names(renamed) == "x"] <- "u"
  expect_equal(get_sampling_interval(renamed), 99)
})

test_that("an ungrouped frame is measured per key all the same", {
  af <- as_anipoint(data.frame(
    individual = rep(c("a", "b"), each = 5),
    time = rep(0:4, 2),
    x = 1,
    y = 1
  ))
  expect_warning(ungrouped <- dplyr::ungroup(af), "Ungrouping")

  expect_equal(compute_sampling_gaps(ungrouped), rep(1, 8))
  expect_equal(get_sampling_interval(dplyr::filter(ungrouped, time != 1)), 1)
})

test_that("a frame with no keys is measured as one series", {
  af <- as_anipoint(
    data.frame(time = c(0, 2, 4, 6), x = 1, y = 1),
    variables_what = character(0)
  )
  expect_equal(get_sampling_interval(af), 2)

  expect_equal(get_sampling_interval(dplyr::filter(af, time != 2)), 3)
  expect_equal(get_sampling_interval(dplyr::filter(af, time != 6)), 2)
})

test_that("a frame filtered down to one row per key has no interval", {
  af <- single_track()

  expect_true(is.na(get_sampling_interval(dplyr::filter(af, time == 0))))
})

test_that("an anievent keeps no interval through its verbs", {
  ae <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    dplyr::mutate(b = factor(rep(c("r", "w"), each = 2))) |>
    set_variables(event = list(state = "b")) |>
    to_anievent()

  expect_true(is.na(get_sampling_interval(dplyr::filter(ae, start >= 0))))
})

# Regularity is computed, not stored ----

test_that("regularity follows the data rather than the metadata", {
  # A stored logical would go stale when a row is dropped.
  af <- example_anipoint(n_obs = 5, n_individuals = 1, n_keypoints = 1)
  expect_true(is_sampling_regular(af))

  gapped <- dplyr::filter(af, time != 3)
  expect_false(is_sampling_regular(gapped))
})

test_that("tolerance is the caller's to set", {
  af <- example_anipoint(n_obs = 5, n_individuals = 1, n_keypoints = 1)
  gapped <- dplyr::filter(af, time != 3)

  expect_false(is_sampling_regular(gapped))
  expect_true(is_sampling_regular(gapped, tolerance = 2))
})

test_that("tolerance is relative, so it survives floating-point timestamps", {
  # Regular to any precision that matters, but not one `==` would accept.
  jitter <- c(0, 0.02, 0.04 + 1e-12, 0.06, 0.08)
  af <- as_anipoint(
    data.frame(individual = "a", time = jitter, x = 1:5, y = 1:5)
  )

  expect_true(is_sampling_regular(af))
  expect_false(is_sampling_regular(af, tolerance = 1e-15))
})

test_that("is_sampling_regular() rejects a nonsense tolerance", {
  af <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1)

  expect_error(is_sampling_regular(af, tolerance = "a"), "single number")
  expect_error(is_sampling_regular(af, tolerance = c(1, 2)), "single number")
})

# A declared rate that disagrees with the index ----

test_that("validate_anipoint() warns when sampling_rate contradicts the index", {
  af <- as_anipoint(
    data.frame(
      individual = "a",
      time = seq(0, 0.08, by = 0.02),
      x = 1:5,
      y = 1:5
    )
  ) |>
    set_metadata(unit_time = "s", sampling_rate = 50)

  expect_no_warning(validate_anipoint(af))
  expect_warning(
    validate_anipoint(set_metadata(af, sampling_rate = 30)),
    "sampling_rate"
  )
})

test_that("a frame-indexed recording is not second-guessed", {
  # Here the rate converts frames to seconds; the gaps can't contradict it.
  af <- example_anipoint(n_obs = 4, n_individuals = 1, n_keypoints = 1) |>
    set_metadata(sampling_rate = 30)

  expect_no_warning(validate_anipoint(af))
})

test_that("aniframe.quiet silences the mismatch warning", {
  af <- as_anipoint(
    data.frame(
      individual = "a",
      time = seq(0, 0.08, by = 0.02),
      x = 1:5,
      y = 1:5
    )
  ) |>
    set_metadata(unit_time = "s", sampling_rate = 30)

  previous <- options(aniframe.quiet = TRUE)
  on.exit(options(previous), add = TRUE)

  expect_no_warning(validate_anipoint(af))
})

test_that("metadata written before the field existed still validates", {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
  md <- get_metadata(af)
  md$time$sampling_interval <- NULL

  expect_no_error(ensure_valid_metadata(md))
  expect_true(has_all_metadata_fields(md))
})

test_that("a non-numeric index does not abort construction", {
  # `sampling_interval` is derived before the index is type-checked, so an
  # empty or untyped column must not blow up there (via aniread).
  df <- data.frame(
    individual = character(0),
    time = character(0),
    x = numeric(0),
    y = numeric(0)
  )

  expect_no_error(af <- as_anipoint(df))
  expect_true(is.na(get_sampling_interval(af)))
  expect_true(is.na(is_sampling_regular(af)))
})

# Frames with nothing to measure ----

test_that("no gaps are taken when the index column is gone", {
  af <- example_anipoint(n_obs = 5, n_individuals = 1, n_keypoints = 1)
  stripped <- drop_column_unchecked(af, "time")

  expect_equal(compute_sampling_gaps(stripped), numeric())
})

test_that("the interval is NA when metadata predates the field", {
  af <- example_anipoint(n_obs = 5, n_individuals = 1, n_keypoints = 1)
  md <- attr(af, "metadata")
  md$time$sampling_interval <- NULL
  attr(af, "metadata") <- md

  expect_true(is.na(get_sampling_interval(af)))
})

test_that("regularity is undecidable when every gap is zero", {
  af <- suppressWarnings(as_anipoint(
    data.frame(
      individual = "a",
      keypoint = "nose",
      time = c(1, 1, 1),
      x = 1:3,
      y = 1:3
    )
  ))

  expect_true(is.na(is_sampling_regular(af)))
})
