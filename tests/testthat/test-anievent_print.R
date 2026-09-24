test_that("tbl_sum.anievent shows class name and identity row", {
  ae <- anievent(
    individual = c(1L, 1L, 2L),
    channel = c("behaviour", "call", "behaviour"),
    label = c("REM", "alarm", "wake"),
    start = c(3, 4.5, 14),
    stop = c(9, 4.5, 19)
  )

  header <- pillar::tbl_sum(ae)

  expect_identical(names(header)[1], "anievent")
  expect_match(header[[1]], "3 x")
  expect_identical(sum(names(header) == "Individuals"), 1L)
  expect_false(any(c("Starts", "Stops") %in% names(header)))
})

test_that("tbl_sum.anievent surfaces event channels from the channel column", {
  ae <- anievent(
    individual = c(1L, 1L),
    channel = c("behaviour", "call"),
    label = c("REM", "alarm"),
    start = c(3, 4.5),
    stop = c(9, 4.5)
  )

  header <- pillar::tbl_sum(ae)
  expect_true("Event channels" %in% names(header))
  expect_match(unname(header["Event channels"]), "behaviour")
  expect_match(unname(header["Event channels"]), "call")
})

test_that("tbl_sum.anievent surfaces an event-type breakdown when both kinds are present", {
  ae <- anievent(
    individual = c(1L, 1L, 1L),
    channel = c("behaviour", "behaviour", "call"),
    label = c("REM", "wake", "alarm"),
    start = c(1, 5, 3),
    stop = c(4, 10, 3) # 2 state bouts + 1 point bout
  )

  header <- pillar::tbl_sum(ae)
  expect_true("Event types" %in% names(header))
  expect_match(unname(header["Event types"]), "2 state")
  expect_match(unname(header["Event types"]), "1 point")
})

test_that("tbl_sum.anievent shows just one event-type kind when only one is present", {
  ae <- anievent(
    individual = c(1L, 1L),
    channel = c("behaviour", "behaviour"),
    label = c("REM", "wake"),
    start = c(1, 5),
    stop = c(4, 10)
  )

  header <- pillar::tbl_sum(ae)
  expect_true("Event types" %in% names(header))
  expect_match(unname(header["Event types"]), "2 state")
  expect_false(grepl("point", unname(header["Event types"])))
})

test_that("tbl_sum.anievent surfaces sampling rate when set", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 3,
    stop = 9
  )
  ae <- set_metadata(ae, sampling_rate = 30)

  header <- pillar::tbl_sum(ae)
  expect_true("Sampling rate" %in% names(header))
  expect_equal(unname(header["Sampling rate"]), "30 Hz")
})

test_that("tbl_sum.anievent omits event channels row on a zero-row object", {
  ae <- anievent(
    individual = integer(),
    channel = character(),
    label = factor(character()),
    start = numeric(),
    stop = numeric()
  )

  header <- pillar::tbl_sum(ae)
  expect_false("Event channels" %in% names(header))
})
