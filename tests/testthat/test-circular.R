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
  # The reference medians are in [0, 2*pi); circ_median() is in (-pi, pi].
  for (case in reference) {
    expect_equal(
      wrap_angle(circ_median(case$x), "2pi"),
      case$median,
      tolerance = 1e-8
    )
  }
})

test_that("circ_summed_distance() is the summed distance to every observation", {
  set.seed(147)
  x <- wrap_angle(
    c(stats::runif(40, 0, 2 * pi), 0, pi, 2 * pi - 1e-12),
    "2pi"
  )
  theta <- wrap_angle(c(x, x + pi, stats::runif(40, 0, 2 * pi)), "2pi")

  expect_equal(
    circ_summed_distance(theta, x),
    vapply(theta, function(t) sum(pi - abs(pi - abs(x - t))), numeric(1)),
    tolerance = 1e-12
  )
})

test_that("circ_median() picks the same minimisers as the brute-force search", {
  set.seed(148)
  sample_angles <- function(n) {
    list(
      uniform = stats::runif(n, -4 * pi, 4 * pi),
      clustered = stats::rnorm(n, 1, 0.3),
      across_zero = stats::rnorm(n, 0, 0.2),
      bimodal = stats::rnorm(n, 0, 0.1) + pi * stats::rbinom(n, 1, 0.5),
      whole_degrees = deg_to_rad(sample(0:359, n, replace = TRUE)),
      clustered_degrees = deg_to_rad(round(stats::rnorm(n, 350, 20))),
      coarse_degrees = deg_to_rad(sample(seq(0, 315, 45), n, replace = TRUE)),
      antipodal_pairs = rep(stats::runif(ceiling(n / 2), 0, 2 * pi), 2) +
        c(rep(0, ceiling(n / 2)), rep(pi, ceiling(n / 2)))
    )
  }

  for (n in c(1, 2, 3, 4, 5, 8, 25, 100, 501, 2000)) {
    for (x in sample_angles(n)) {
      expect_identical(circ_median(x), circ_median_brute(x))
    }
  }
})

test_that("circ_median() handles ties and edge cases as the brute-force search does", {
  ties <- list(
    single = 2.5,
    two = c(0.4, 1.1),
    two_across_zero = c(6.1, 0.3),
    antipodal = c(0, pi),
    antipodal_degrees = deg_to_rad(c(90, 270)),
    identical = rep(1.3, 10),
    symmetric_odd = c(1 - 0.4, 1 - 0.1, 1, 1 + 0.1, 1 + 0.4),
    symmetric_even = c(1 - 0.4, 1 - 0.1, 1 + 0.1, 1 + 0.4),
    quarters = deg_to_rad(c(0, 90, 180, 270)),
    evenly_spaced = seq(0, 2 * pi, length.out = 13)[-13],
    wraps_to_two_pi = c(-1e-20, 0.5, 3),
    reference = reference$tied_across_zero$x
  )

  for (x in ties) {
    expect_identical(circ_median(x), circ_median_brute(x))
    expect_identical(circ_median(x + pi), circ_median_brute(x + pi))
  }
})

test_that("circ_median() scales to long recordings", {
  skip_on_cran()
  set.seed(149)
  x <- stats::runif(20000, 0, 2 * pi)

  expect_lt(system.time(circ_median(x))[["elapsed"]], 1)
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

  # The mean of 350 and 10 degrees is 0, which floating point may reach from
  # either side of zero.
  expect_equal(
    circ_difference(0, circ_mean(deg_to_rad(c(350, 10)))),
    0,
    tolerance = 1e-9
  )
})

test_that("circ_mean() and circ_median() are signed, in (-pi, pi]", {
  # Directions just below zero stay just below zero, like the data.
  expect_equal(circ_mean(c(-0.3, -0.1)), -0.2, tolerance = 1e-12)
  expect_equal(circ_median(c(-0.3, -0.2, -0.1)), -0.2, tolerance = 1e-12)
  expect_equal(circ_median(c(6.0, 6.1, 6.2)), 6.1 - 2 * pi, tolerance = 1e-12)

  # The direction opposite x comes out as pi, the included end, not -pi.
  expect_identical(circ_mean(pi), pi)
  expect_identical(circ_mean(-pi), pi)
  expect_identical(circ_median(-pi), pi)
  expect_identical(circ_median(c(-pi, pi)), pi)

  set.seed(181)
  for (i in 1:50) {
    x <- stats::runif(stats::rpois(1, 20) + 1, -6 * pi, 6 * pi)
    for (summary in c(circ_mean(x), circ_median(x))) {
      expect_gt(summary, -pi)
      expect_lte(summary, pi)
    }
  }
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
