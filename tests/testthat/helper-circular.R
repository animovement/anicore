# The O(n^2) circ_median() that circ_summed_distance() replaced (#182): the
# summed distance evaluated at every candidate in turn. Kept to check the fast
# version gives the same answers. Its search runs on [0, 2*pi) like the fast
# one, and both return through circ_mean(), so in (-pi, pi] (#181).
circ_median_brute <- function(x, na_rm = TRUE) {
  x <- circ_drop_na(x, na_rm)
  if (!length(x) || anyNA(x)) {
    return(NA_real_)
  }

  x <- wrap_angle(x, "2pi")

  candidates <- wrap_angle(c(x, x + pi), "2pi")
  distance <- vapply(
    candidates,
    function(theta) sum(pi - abs(pi - abs(x - theta))),
    numeric(1)
  )

  circ_mean(candidates[distance <= min(distance) + .Machine$double.eps^0.5])
}
