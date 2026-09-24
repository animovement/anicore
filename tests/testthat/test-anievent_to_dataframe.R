# to_anievent.data.frame()

test_that("factor state column is run-length-encoded into bouts", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:8,
    behaviour = factor(
      c("REM", "REM", "REM", "wake", "wake", "REM", "REM", NA),
      levels = c("REM", "wake")
    )
  )

  ae <- to_anievent(
    df,
    time = time,
    state = behaviour,
    variables_what = individual
  )

  expect_s3_class(ae, "anievent")
  expect_equal(nrow(ae), 3) # REM(1-3), wake(4-5), REM(6-7)
  expect_equal(ae$start, c(1, 4, 6))
  expect_equal(ae$stop, c(3, 5, 7))
  expect_equal(as.character(ae$label), c("REM", "wake", "REM"))
  expect_true(all(ae$channel == "behaviour"))
  expect_equal(as.character(ae$type), rep("state", 3))
})

test_that("character state column is RLE'd like a factor", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:5,
    behaviour = c("REM", "REM", "wake", "wake", "wake")
  )

  ae <- to_anievent(
    df,
    time = time,
    state = behaviour,
    variables_what = individual
  )

  expect_equal(nrow(ae), 2)
  expect_equal(as.character(ae$label), c("REM", "wake"))
})

test_that("logical state column produces TRUE-run bouts labelled by the column name", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:8,
    woke_up = c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE, TRUE, FALSE)
  )

  ae <- to_anievent(
    df,
    time = time,
    state = woke_up,
    variables_what = individual
  )

  # Two TRUE-runs: t=4-5 and t=7
  expect_equal(nrow(ae), 2)
  expect_equal(ae$start, c(4, 7))
  expect_equal(ae$stop, c(5, 7))
  expect_equal(as.character(ae$label), c("woke_up", "woke_up"))
  expect_true(all(ae$channel == "woke_up"))
})

test_that("factor point column emits one bout per non-NA frame", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:5,
    call = factor(c(NA, "alarm", NA, "contact", NA))
  )

  ae <- to_anievent(
    df,
    time = time,
    point = call,
    variables_what = individual
  )

  expect_equal(nrow(ae), 2)
  expect_equal(ae$start, c(2, 4))
  expect_equal(ae$start, ae$stop)
  expect_equal(as.character(ae$label), c("alarm", "contact"))
  expect_true(all(ae$channel == "call"))
  expect_equal(as.character(ae$type), rep("point", 2))
})

test_that("logical point column emits one point bout per TRUE frame", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:5,
    is_alarm = c(FALSE, TRUE, FALSE, FALSE, TRUE)
  )

  ae <- to_anievent(
    df,
    time = time,
    point = is_alarm,
    variables_what = individual
  )

  expect_equal(nrow(ae), 2)
  expect_equal(ae$start, c(2, 5))
  expect_equal(ae$start, ae$stop)
  expect_equal(as.character(ae$label), c("is_alarm", "is_alarm"))
})

test_that("state and point and logical columns can mix in one call", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:8,
    behaviour = factor(c(
      "REM",
      "REM",
      "REM",
      "wake",
      "wake",
      "REM",
      "REM",
      NA
    )),
    woke_up = c(FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
    call = c(NA, "alarm", NA, NA, NA, NA, NA, NA)
  )

  ae <- to_anievent(
    df,
    time = time,
    state = c(behaviour, woke_up),
    point = call,
    variables_what = individual
  )

  expect_setequal(unique(ae$channel), c("behaviour", "woke_up", "call"))
  expect_equal(sum(ae$channel == "behaviour"), 3)
  expect_equal(sum(ae$channel == "woke_up"), 1)
  expect_equal(sum(ae$channel == "call"), 1)
})

test_that("multiple identity columns isolate bouts independently", {
  df <- dplyr::tibble(
    individual = rep(c(1L, 2L), each = 4),
    time = c(1:4, 1:4),
    behaviour = factor(c(
      "REM",
      "REM",
      "wake",
      "wake",
      "wake",
      "wake",
      "REM",
      "REM"
    ))
  )

  ae <- to_anievent(
    df,
    time = time,
    state = behaviour,
    variables_what = individual
  )

  expect_equal(nrow(ae), 4) # 2 bouts per individual
  expect_equal(sum(ae$individual == 1), 2)
  expect_equal(sum(ae$individual == 2), 2)
})

test_that("variables_when isolates bouts across temporal groups", {
  df <- dplyr::tibble(
    individual = 1L,
    observation = c(rep("clip_a", 4), rep("clip_b", 4)),
    time = c(1:4, 1:4),
    behaviour = factor(rep(c("REM", "REM", "wake", "wake"), 2))
  )

  ae <- to_anievent(
    df,
    time = time,
    state = behaviour,
    variables_what = individual,
    variables_when = observation
  )

  expect_true("observation" %in% names(ae))
  expect_true("observation" %in% get_variables(ae, "when", "keys"))
  expect_equal(nrow(ae), 4) # REM/wake per clip
})

test_that("time can be selected via any column name, not just 'time'", {
  df <- dplyr::tibble(
    individual = 1L,
    t_ms = c(100, 200, 300, 400, 500),
    behaviour = factor(c("REM", "REM", "wake", "wake", "wake"))
  )

  ae <- to_anievent(
    df,
    time = t_ms,
    state = behaviour,
    variables_what = individual
  )

  expect_equal(ae$start, c(100, 300))
  expect_equal(ae$stop, c(200, 500))
})

test_that("missing time argument errors", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:3,
    behaviour = factor(c("REM", "REM", "wake"))
  )

  expect_error(
    to_anievent(df, state = behaviour, variables_what = individual),
    "time"
  )
})

test_that("calling without state or point errors with a helpful message", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:3,
    behaviour = factor(c("REM", "REM", "wake"))
  )

  expect_error(
    to_anievent(df, time = time, variables_what = individual),
    "state.*point"
  )
})

test_that("no identity columns is permitted", {
  df <- dplyr::tibble(
    time = 1:5,
    behaviour = factor(c("REM", "REM", "wake", "wake", "wake"))
  )

  ae <- to_anievent(df, time = time, state = behaviour)

  expect_equal(nrow(ae), 2)
  expect_equal(ae$start, c(1, 3))
  expect_equal(ae$stop, c(2, 5))
})

test_that("NA values break runs of the same value", {
  df <- dplyr::tibble(
    individual = 1L,
    time = 1:6,
    behaviour = factor(c("REM", "REM", NA, "REM", "REM", "wake"))
  )

  ae <- to_anievent(
    df,
    time = time,
    state = behaviour,
    variables_what = individual
  )

  expect_equal(nrow(ae), 3) # REM(1-2), REM(4-5), wake(6)
  expect_equal(ae$start, c(1, 4, 6))
  expect_equal(ae$stop, c(2, 5, 6))
})

test_that("an anievent passed to to_anievent returns itself", {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = "REM",
    start = 1,
    stop = 5
  )
  expect_identical(to_anievent(ae), ae)
})
