# Metadata in the flat layout written before the category tree (#118).
legacy_metadata <- function(...) {
  md <- unclass(list_default_metadata())
  flat <- c(
    md$recording,
    md$time,
    md$space,
    list(
      variables_index = "time",
      variables_what = c("individual", "keypoint"),
      variables_when = character(),
      variables_where = c("x", "y"),
      variables_event = list(state = character(), point = character()),
      axes = c(x = "x", y = "y"),
      connections = list(),
      spec_version = list(aniframe = "2.1.0", anievent = "0.4.0")
    )
  )
  utils::modifyList(flat, list(...))
}

legacy_anipoint <- function(...) {
  af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 2)
  attr(af, "metadata") <- legacy_metadata(...)
  af
}

# An anievent serialised before #73 still carried spatial fields.
legacy_anievent <- function(...) {
  ae <- anievent(
    individual = 1L,
    channel = "behaviour",
    label = c("REM", "wake"),
    start = c(1, 4),
    stop = c(3, 5)
  )
  md <- legacy_metadata(
    variables_what = "individual",
    variables_when = c("start", "stop"),
    variables_where = character(),
    ...
  )
  md[c("variables_index", "variables_event", "axes")] <- NULL
  attr(ae, "metadata") <- md
  ae
}
