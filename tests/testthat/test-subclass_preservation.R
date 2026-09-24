# Downstream subclasses (e.g. animetric's) survive the class-preserving
# methods, ahead of their parent so their own methods win dispatch (#81).

# ---- Helpers -----------------------------------------------------------

make_subclassed_af <- function(grouped = TRUE) {
  af <- example_anipoint(n_obs = 4, n_individuals = 2, n_keypoints = 2)
  if (!grouped) {
    af <- suppressWarnings(dplyr::ungroup(af))
  }
  class(af) <- c("test_kin2d", "test_kin", class(af))
  af
}

make_subclassed_ae <- function() {
  ae <- anievent(
    individual = c(1L, 1L, 2L, 2L),
    channel = c("behaviour", "behaviour", "behaviour", "call"),
    label = c("REM", "wake", "REM", "alarm"),
    start = c(3, 14, 1, 7.5),
    stop = c(9, 19, 6, 7.5)
  )
  ae <- set_metadata(ae, sampling_rate = 30)
  class(ae) <- c("test_bout2d", "test_bout", class(ae))
  ae
}

# The full stack survives, in the right order, with metadata intact.
expect_subclass_preserved <- function(out, parent = "aniframe", md = NULL) {
  subclasses <- if (parent == "aniframe") {
    c("test_kin2d", "test_kin")
  } else {
    c("test_bout2d", "test_bout")
  }

  for (cl in c(subclasses, parent)) {
    expect_s3_class(out, cl)
  }

  cls <- class(out)
  expect_lt(match(subclasses[[1]], cls), match(subclasses[[2]], cls))
  expect_lt(match(subclasses[[2]], cls), match(parent, cls))

  if (!is.null(md)) {
    expect_equal(get_metadata(out, "sampling_rate"), md)
  }

  invisible(out)
}

# ---- aniframe: dplyr verbs ---------------------------------------------

test_that("dplyr verbs preserve a downstream subclass on grouped data", {
  af <- make_subclassed_af(grouped = TRUE)

  expect_subclass_preserved(dplyr::mutate(af, doubled = x * 2))
  expect_subclass_preserved(dplyr::filter(af, x > -Inf))
  expect_subclass_preserved(dplyr::select(af, dplyr::everything()))
  expect_subclass_preserved(dplyr::arrange(af, time))
  expect_subclass_preserved(dplyr::slice(af, 1))
  expect_subclass_preserved(dplyr::group_by(af, individual))
  expect_subclass_preserved(dplyr::rename(af, moment = time))
  expect_subclass_preserved(dplyr::relocate(af, x))
})

test_that("dplyr verbs preserve a downstream subclass on ungrouped data", {
  af <- make_subclassed_af(grouped = FALSE)

  expect_subclass_preserved(dplyr::mutate(af, doubled = x * 2))
  expect_subclass_preserved(dplyr::filter(af, x > -Inf))
  expect_subclass_preserved(dplyr::select(af, dplyr::everything()))
  expect_subclass_preserved(dplyr::arrange(af, time))
  expect_subclass_preserved(dplyr::slice(af, 1))
  expect_subclass_preserved(dplyr::rename(af, moment = time))
  expect_subclass_preserved(dplyr::relocate(af, x))
})

test_that("ungroup preserves the subclass without re-grouping the result", {
  af <- make_subclassed_af(grouped = TRUE)
  expect_warning(out <- dplyr::ungroup(af))

  expect_subclass_preserved(out)
  # The dplyr-owned class tail comes from `NextMethod()`, not the input, or
  # ungrouping would restore `grouped_df`.
  expect_false(inherits(out, "grouped_df"))
  expect_false(dplyr::is_grouped_df(out))
})

# ---- aniframe: base-R extraction and assignment ------------------------

test_that("base-R extraction and assignment preserve a downstream subclass", {
  af <- make_subclassed_af()

  expect_subclass_preserved(af[1:2, ])

  sub_assign <- af
  sub_assign[1, "x"] <- 0
  expect_subclass_preserved(sub_assign)

  col_assign <- af
  col_assign[["x"]] <- col_assign[["x"]] * 2
  expect_subclass_preserved(col_assign)

  dollar_assign <- af
  dollar_assign$x <- dollar_assign$x * 2
  expect_subclass_preserved(dollar_assign)

  renamed <- af
  names(renamed) <- toupper(names(renamed))
  expect_subclass_preserved(renamed)
})

# ---- aniframe: metadata and regression ---------------------------------

test_that("metadata survives alongside a preserved subclass", {
  af <- set_metadata(make_subclassed_af(), sampling_rate = 60)
  out <- dplyr::filter(af, x > -Inf)

  expect_subclass_preserved(out, md = 60)
  expect_equal(get_metadata(out), get_metadata(af))
})

test_that("a plain aniframe is unchanged by the preservation logic", {
  af <- example_anipoint(n_obs = 4, n_individuals = 2, n_keypoints = 2)

  out <- dplyr::mutate(af, doubled = x * 2)
  expect_identical(class(out), class(af))
  expect_s3_class(out, "aniframe")

  # No duplicated entries when the result already carries the class.
  expect_equal(sum(class(out) == "aniframe"), 1L)
})

# ---- anievent ----------------------------------------------------------

test_that("anievent methods preserve a downstream subclass", {
  ae <- make_subclassed_ae()

  expect_subclass_preserved(
    dplyr::filter(ae, start > 0),
    parent = "anievent",
    md = 30
  )
  expect_subclass_preserved(dplyr::mutate(ae, dur = stop - start), "anievent")
  expect_subclass_preserved(dplyr::arrange(ae, start), "anievent")
  expect_subclass_preserved(dplyr::slice(ae, 1), "anievent")
  expect_subclass_preserved(ae[1:2, ], "anievent")

  dollar_assign <- ae
  dollar_assign$start <- dollar_assign$start + 1
  expect_subclass_preserved(dollar_assign, "anievent")
})

# ---- the helper itself -------------------------------------------------

test_that("preserve_animovement_class restores order and drops dplyr classes", {
  bare <- dplyr::tibble(a = 1)
  cls <- c("test_kin", "aniframe", "grouped_df", "tbl_df", "tbl", "data.frame")

  out <- preserve_animovement_class(bare, cls, list_default_metadata())

  expect_identical(
    class(out),
    c("test_kin", "aniframe", "tbl_df", "tbl", "data.frame")
  )
  expect_false(inherits(out, "grouped_df"))
})
