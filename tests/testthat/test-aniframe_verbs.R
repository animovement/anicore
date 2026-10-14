# Testing how dplyr and tidyr verbs without a method of their own treat an
# aniframe, through dplyr_reconstruct(), dplyr_row_slice(), group_modify()
# and drop_na() (#199):
# - Verbs that keep the keys and index keep the class and metadata, on a
#   grouped anipoint, an ungrouped one and an anievent alike
# - Grouping survives on a grouped anipoint
# - Verbs that drop rows measure the sampling interval again
# - Verbs whose result loses a key or the index return a plain data frame
#   without metadata, rather than an invalid aniframe
# - group_modify() keeps the class when .f keeps the keys and index
# - drop_na() keeps the class and measures the interval again

verb_frames <- function() {
  point <- example_anipoint(n_obs = 20, n_individuals = 2, n_keypoints = 2) |>
    set_metadata(sampling_rate = 30) |>
    convert_unit_time("s")
  list(
    grouped = point,
    ungrouped = suppressWarnings(dplyr::ungroup(point)),
    event = anievent(
      individual = c(1L, 1L, 2L, 2L),
      channel = c("b", "b", "b", "call"),
      label = c("rest", "walk", "rest", "alarm"),
      start = c(3, 14, 4, 4.5),
      stop = c(9, 19, 8, 4.5)
    )
  )
}

expect_same_frame_class <- function(result, x, label) {
  expect_identical(class(result)[[1]], class(x)[[1]], label = label)
  expect_identical(
    get_metadata(result, "coordinate_system"),
    get_metadata(x, "coordinate_system"),
    label = label
  )
}

test_that("verbs that keep the keys keep the class and metadata", {
  for (name in names(verb_frames())) {
    x <- verb_frames()[[name]]
    lookup <- dplyr::tibble(individual = unique(x$individual), group = "g")
    results <- list(
      distinct = dplyr::distinct(x),
      semi_join = dplyr::semi_join(x, lookup, by = "individual"),
      anti_join = dplyr::anti_join(x, lookup[0, ], by = "individual"),
      left_join = dplyr::left_join(x, lookup, by = "individual"),
      inner_join = dplyr::inner_join(x, lookup, by = "individual"),
      add_count = dplyr::add_count(x),
      bind_cols = dplyr::bind_cols(x, dplyr::tibble(extra = seq_len(nrow(x))))
    )
    for (verb in names(results)) {
      expect_same_frame_class(results[[verb]], x, paste(verb, name))
    }
  }
})

test_that("a grouped anipoint keeps its grouping", {
  x <- verb_frames()$grouped
  lookup <- dplyr::tibble(individual = unique(x$individual), group = "g")

  expect_identical(dplyr::group_vars(dplyr::distinct(x)), dplyr::group_vars(x))
  expect_identical(
    dplyr::group_vars(dplyr::left_join(x, lookup, by = "individual")),
    dplyr::group_vars(x)
  )
})

test_that("verbs that drop rows measure the sampling interval again", {
  x <- verb_frames()$ungrouped
  every_third <- dplyr::distinct(x, time) |>
    dplyr::slice(seq(1, dplyr::n(), by = 3))

  thinned <- dplyr::semi_join(x, every_third, by = "time")

  expect_equal(get_sampling_interval(x), 1 / 30)
  expect_equal(get_sampling_interval(thinned), 3 / 30)
})

test_that("a verb that loses a key or the index returns a plain frame", {
  for (name in names(verb_frames())) {
    x <- verb_frames()[[name]]
    counted <- dplyr::count(x)

    expect_false(inherits(counted, "aniframe"), label = name)
    expect_null(attr(counted, "metadata"), label = name)
  }
})

test_that("group_modify() keeps the class when .f keeps the keys", {
  x <- verb_frames()$grouped

  kept <- dplyr::group_modify(x, \(d, k) utils::head(d, 2))
  summarised <- dplyr::group_modify(x, \(d, k) dplyr::tibble(n = nrow(d)))

  expect_same_frame_class(kept, x, "head")
  expect_false(inherits(summarised, "aniframe"))
})

test_that("drop_na() keeps the class and measures the interval again", {
  skip_if_not_installed("tidyr")
  x <- verb_frames()$grouped
  # Every other frame is missing, so what is left is spaced twice as far
  x$x[round(x$time * 30) %% 2 == 1] <- NA

  out <- tidyr::drop_na(x)

  expect_same_frame_class(out, x, "drop_na")
  expect_identical(dplyr::group_vars(out), dplyr::group_vars(x))
  expect_false(anyNA(out$x))
  expect_equal(get_sampling_interval(out), 2 / 30)

  event <- verb_frames()$event
  expect_s3_class(tidyr::drop_na(event), "anievent")
})
