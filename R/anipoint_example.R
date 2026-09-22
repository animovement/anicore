#' Create example anipoint data
#'
#' Generates a synthetic anipoint object with random coordinates for
#' testing and demonstration purposes. The function creates a complete design
#' with all combinations of time points, individuals, keypoints, trials, and
#' sessions.
#'
#' @param n_obs Integer. Number of time observations per combination. Default is 50.
#' @param n_individuals Integer. Number of individuals to simulate. Default is 3.
#' @param n_keypoints Integer. Number of keypoints per individual (max 11).
#'   Default is 11. When set to 1, only "centroid" is used. Otherwise, anatomical
#'   keypoints are used (head, neck, shoulders, etc.).
#' @param n_trials Integer. Number of trials per session. Default is 1.
#' @param n_sessions Integer. Number of sessions. Default is 1.
#' @param n_dims Integer. Number of spatial dimensions (1, 2, or 3). Default is 2.
#'   If 1, only x coordinates are generated. If 2, x and y coordinates are generated.
#'   If 3, x, y, and z coordinates are generated.
#'
#' @return An anipoint object containing randomly generated tracking data with
#'   columns for individual, keypoint, time, trial, session, and spatial coordinates
#'   (x, y, and/or z depending on `n_dims`). The coordinates are drawn from a
#'   standard normal distribution.
#'
#' @export
#'
#' @examples
#' # Create a basic example with default parameters (2D)
#' example_anipoint()
#'
#' # Create a 1D example
#' example_anipoint(n_dims = 1)
#'
#' # Create a 3D example
#' example_anipoint(n_dims = 3)
#'
#' # Create a smaller example with 2 individuals and 5 keypoints
#' example_anipoint(n_individuals = 2, n_keypoints = 5)
#'
#' # Create example with multiple trials and sessions
#' example_anipoint(n_obs = 100, n_trials = 3, n_sessions = 2)
#'
#' # Create minimal example with just centroid in 3D
#' example_anipoint(n_keypoints = 1, n_dims = 3)
example_anipoint <- function(
  n_obs = 50,
  n_individuals = 3,
  n_keypoints = 11,
  n_trials = 1,
  n_sessions = 1,
  n_dims = 2
) {
  if (n_keypoints > 11) {
    cli::cli_abort("{.arg n_keypoints} must be at most 11.")
  }

  if (!n_dims %in% c(1, 2, 3)) {
    cli::cli_abort("{.arg n_dims} must be 1, 2, or 3.")
  }

  # Make vector of keypoints
  if (n_keypoints == 1) {
    keypoints <- "centroid"
  } else {
    keypoints <- c(
      "head",
      "neck",
      "shoulder_right",
      "shoulder_left",
      "abdomen",
      "hip_right",
      "hip_left",
      "knee_right",
      "knee_left",
      "foot_right",
      "foot_left"
    )[seq_len(n_keypoints)]
  }

  # Create the design matrix with all combinations
  design <- expand.grid(
    time = seq_len(n_obs),
    individual = seq_len(n_individuals),
    keypoint = keypoints,
    trial = seq_len(n_trials),
    session = seq_len(n_sessions)
  )

  n_total <- nrow(design)

  # Build spatial variables based on dimensions
  variables_where <- switch(
    as.character(n_dims),
    "1" = "x",
    "2" = c("x", "y"),
    "3" = c("x", "y", "z")
  )

  # Create base anipoint arguments
  anipoint_args <- list(
    individual = design$individual,
    keypoint = design$keypoint,
    session = design$session,
    trial = design$trial,
    time = design$time,
    x = stats::rnorm(n_total),
    confidence = stats::rbeta(n_total, shape1 = 5, shape2 = 2),
    variables_what = c("individual", "keypoint"),
    variables_when = c("session", "trial"),
    index = "time",
    variables_where = variables_where
  )

  if (n_dims >= 2) {
    anipoint_args$y <- stats::rnorm(n_total)
  }

  if (n_dims == 3) {
    anipoint_args$z <- stats::rnorm(n_total)
  }

  do.call(anipoint, anipoint_args)
}
