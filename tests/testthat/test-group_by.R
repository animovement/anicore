# Testing group_by() on an aniframe (#208):
# - A frame grouped by its keys keeps them, and adds the levels asked for
#   after them, with a message
# - Grouping by the keys again, or by some of them, changes nothing and
#   says nothing
# - .add = TRUE gives the same grouping as before
# - After ungroup(), the grouping asked for is taken as it is
# - An anievent, which is not grouped by its keys, is grouped as asked

with_behaviour <- function() {
  x <- example_anipoint()
  x$behaviour <- rep(c("walk", "rest"), length.out = nrow(x))
  x
}

test_that("group_by() keeps the keys and adds the levels asked for", {
  rlang::local_options(rlib_message_verbosity = "verbose")
  x <- with_behaviour()
  keys <- dplyr::group_vars(x)

  expect_message(
    out <- dplyr::group_by(x, behaviour),
    "keeps the keys"
  )

  expect_s3_class(out, "anipoint")
  expect_identical(dplyr::group_vars(out), c(keys, "behaviour"))
})

test_that("grouping by the keys, or some of them, changes nothing", {
  rlang::local_options(rlib_message_verbosity = "verbose")
  x <- with_behaviour()
  keys <- dplyr::group_vars(x)

  expect_no_message(out <- dplyr::group_by(x, individual))
  expect_identical(dplyr::group_vars(out), keys)
  expect_identical(
    dplyr::group_vars(dplyr::group_by(x, dplyr::across(dplyr::all_of(keys)))),
    keys
  )
})

test_that(".add = TRUE adds the levels after the keys", {
  x <- with_behaviour()

  out <- dplyr::group_by(x, behaviour, .add = TRUE)

  expect_identical(
    dplyr::group_vars(out),
    c(dplyr::group_vars(x), "behaviour")
  )
})

test_that("after ungroup(), group_by() groups as asked", {
  x <- suppressWarnings(dplyr::ungroup(with_behaviour()))

  out <- dplyr::group_by(x, behaviour)

  expect_s3_class(out, "anipoint")
  expect_identical(dplyr::group_vars(out), "behaviour")
})

test_that("an anievent is grouped as asked", {
  x <- anievent(
    individual = c(1L, 1L, 2L),
    channel = c("b", "call", "b"),
    label = c("rest", "alarm", "walk"),
    start = c(1, 2, 3),
    stop = c(2, 2, 5)
  )

  expect_identical(dplyr::group_vars(dplyr::group_by(x, channel)), "channel")
})
