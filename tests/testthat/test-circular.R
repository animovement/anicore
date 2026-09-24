# Reference values from {circular} 0.5-2, which these replace (#147),
# computed once so the suite doesn't depend on it:
#   median: as.numeric(median.circular(circular(x %% (2 * pi)))) %% (2 * pi)
#   sd:     as.numeric(sd.circular(circular(x)))
reference <- list(
  concentrated_odd = list(
    x = c(1.02, 0.87, 1.31, 0.95, 1.44),
    median = 1.02,
    sd = 0.219714880346643
  ),
  concentrated_even = list(
    x = c(1.02, 0.87, 1.31, 0.95),
    median = 0.985,
    sd = 0.166210987048621
  ),
  spread = list(
    x = c(0.2, 1.9, 3.4, 4.8, 5.9, 2.7, 0.4),
    median = 0.4,
    sd = 2.08498715131414
  ),
  straddling_zero = list(
    x = c(6.19, 0.07, 6.02, 0.31, 0.02),
    median = 0.02,
    sd = 0.189430736582268
  ),
  tied_across_zero = list(
    x = c(0.1, 2.2, 4.4, 5.1, 1.3, 3.9, 5.8, 0.6),
    median = 6.091592653589793,
    sd = 1.71811123259889
  )
)

test_that("circ_median() agrees with the reference implementation", {
  for (case in reference) {
    expect_equal(circ_median(case$x), case$median, tolerance = 1e-8)
  }
})

test_that("circ_sd() agrees with the reference implementation", {
  for (case in reference) {
    expect_equal(circ_sd(case$x), case$sd, tolerance = 1e-8)
  }
})

test_that("circ_median() averages tied directions on the circle", {
  # A tie either side of zero: averaging arithmetically gives the antipode.
  x <- reference$tied_across_zero$x
  objective <- function(theta) sum(pi - abs(pi - abs(x - theta)))

  expect_lt(objective(circ_median(x)), objective(mean(c(0.1, 5.8))))
  expect_equal(circ_median(x), circ_mean(c(0.1, 5.8)), tolerance = 1e-9)
})

test_that("circ_mean() is the mean direction, not the arithmetic mean", {
  expect_equal(circ_mean(c(0.2, 0.4)), 0.3, tolerance = 1e-12)
  expect_equal(
    rad_to_deg(circ_mean(deg_to_rad(c(350, 30)))),
    10,
    tolerance = 1e-9
  )

  # The mean of 350 and 10 degrees is 0, reached from below in [0, 2*pi).
  expect_equal(
    circ_difference(0, circ_mean(deg_to_rad(c(350, 10)))),
    0,
    tolerance = 1e-9
  )
})

test_that("the summaries do not depend on where the circle is cut", {
  x <- c(0.1, 0.2, 6.2)

  for (shift in c(pi, 2, -1.5)) {
    expect_equal(
      circ_median(x + shift),
      wrap_angle(circ_median(x) + shift),
      tolerance = 1e-9
    )
    expect_equal(circ_sd(x + shift), circ_sd(x), tolerance = 1e-12)
    expect_equal(circ_mad(x + shift), circ_mad(x), tolerance = 1e-9)
  }
})

test_that("identical angles have no spread", {
  # sd.circular() returns NaN here: a constant sample's resultant length can
  # exceed 1 in floating point.
  x <- rep(2.1, 8) + stats::rnorm(8, 0, 1e-9)

  expect_equal(circ_sd(x), 0, tolerance = 1e-6)
  expect_equal(circ_mad(x), 0, tolerance = 1e-6)
  expect_false(is.nan(circ_sd(x)))
})

test_that("missing values are dropped, or propagate when asked", {
  x <- c(0.1, NA, 0.3)

  expect_equal(circ_median(x), circ_median(c(0.1, 0.3)), tolerance = 1e-12)
  expect_identical(circ_median(x, na_rm = FALSE), NA_real_)
  expect_identical(circ_mean(x, na_rm = FALSE), NA_real_)
  expect_identical(circ_sd(x, na_rm = FALSE), NA_real_)
  expect_identical(circ_mad(x, na_rm = FALSE), NA_real_)
})

test_that("nothing to summarise gives NA", {
  expect_identical(circ_median(numeric(0)), NA_real_)
  expect_identical(circ_mean(numeric(0)), NA_real_)
  expect_identical(circ_sd(numeric(0)), NA_real_)
  expect_identical(circ_mad(numeric(0)), NA_real_)
  expect_identical(circ_median(c(NA_real_, NA_real_)), NA_real_)
})

test_that("circ_difference() takes the shorter way round", {
  expect_equal(
    circ_difference(0.1, 6.1),
    -0.2832,
    tolerance = 1e-3
  )
  expect_equal(circ_difference(0, pi / 2), pi / 2)
  expect_true(all(
    abs(circ_difference(0, seq(0, 2 * pi, 0.1))) <= pi
  ))
})

test_that("circ_successive_difference() takes the shortest way round at each step", {
  # crossing zero is a small step forwards, not a large one backwards
  expect_equal(
    circ_successive_difference(c(6.2, 0.1))[2],
    0.1 + 2 * pi - 6.2,
    tolerance = 1e-12
  )

  expect_equal(
    circ_successive_difference(c(0, pi / 2, pi)),
    c(NA, pi / 2, pi / 2),
    tolerance = 1e-12
  )
})

test_that("circ_successive_difference() pads to the length of its input, unlike base::diff()", {
  x <- c(0.1, 0.4, 0.9, 1.2)

  expect_length(circ_successive_difference(x), length(x))
  expect_identical(circ_successive_difference(x)[1], NA_real_)
  expect_identical(
    circ_successive_difference(x, lag = 2L)[1:2],
    c(NA_real_, NA_real_)
  )
  expect_equal(
    circ_successive_difference(x, lag = 2L)[3:4],
    c(0.8, 0.8),
    tolerance = 1e-12
  )
})

test_that("circ_successive_difference() has nothing to difference", {
  expect_identical(circ_successive_difference(numeric(0)), numeric(0))
  expect_identical(circ_successive_difference(1.2), numeric(0))
  expect_identical(
    circ_successive_difference(c(0.1, 0.2), lag = 5L),
    numeric(0)
  )
})

test_that("circ_successive_difference() rejects what it cannot difference", {
  expect_error(circ_successive_difference("a"), "numeric vector")
  expect_error(
    circ_successive_difference(c(0.1, 0.2), lag = 0L),
    "positive integer"
  )
  expect_error(
    circ_successive_difference(c(0.1, 0.2), lag = c(1L, 2L)),
    "positive integer"
  )
})
