#' Create a structure: points, the segments between them, and joints
#'
#' @description
#' An `anistructure` describes how the levels of one identity or temporal
#' variable relate: the keypoints of a skeleton, or the players of a team.
#' It has three parts, each optional beyond the first:
#'
#' * **points** — the members, levels of the variable it is attached to.
#' * **segments** — directed links between two points, with an optional
#'   expected `length`. Direction matters for joint angles: run limbs
#'   proximal to distal, and paired segments (left to right) the same way.
#' * **joints** — one measured angle each, between an ordered pair of
#'   segments `(a, b)`, with optional limits `min`, `max` and `rest` in
#'   radians. The angle is 0 when the two segments point the same way. In
#'   2D it is signed, turning from `a` to `b`. In 3D it is the included angle,
#'   or, when `axis` is given (`"x"`, `"y"`, `"z"` or a segment name), the
#'   signed angle about it. Several angles on the same pair of segments —
#'   flexion and abduction, say — are several joints with different axes.
#'
#' Lengths and limits are recorded, not enforced: checks compare the data
#' against them.
#'
#' A structure is a template: it records no data and no variable until it
#' is attached to a frame with [set_structure()], so one structure can be
#' reused across frames.
#'
#' @param points Character vector of point names. Defaults to the segment
#'   endpoints.
#' @param segments A data frame with `from` and `to`, and optionally
#'   `segment` (defaults to `"from-to"`) and `length`; or a list of
#'   `c(from, to)` pairs.
#' @param joints A data frame with `a` and `b` (segment names), and
#'   optionally `joint` (defaults to `"a-b"`), `axis`, `min`, `max` and
#'   `rest`.
#' @param root The point the structure hangs from when positions are
#'   rebuilt from segments. `NA` if unset.
#' @param source,citation,license Provenance of the structure.
#'
#' @return An `anistructure`.
#'
#' @examples
#' anistructure(
#'   segments = data.frame(
#'     segment = c("thigh", "shin"),
#'     from = c("hip", "knee"),
#'     to = c("knee", "ankle")
#'   ),
#'   joints = data.frame(joint = "knee", a = "thigh", b = "shin", min = 0, max = 2.5),
#'   root = "hip"
#' )
#'
#' # A team: points only, or points with links between them
#' anistructure(points = c("gk", "lb", "cb", "rb"))
#' anistructure(segments = list(c("lb", "cb"), c("cb", "rb")))
#'
#' @seealso [set_structure()], [example_structure()]
#' @export
anistructure <- function(
  points = NULL,
  segments = NULL,
  joints = NULL,
  root = NA_character_,
  source = NA_character_,
  citation = NA_character_,
  license = NA_character_
) {
  segments <- as_structure_segments(segments)
  x <- new_anistructure(
    points = as.character(points %||% unique(c(segments$from, segments$to))),
    segments = segments,
    joints = as_structure_joints(joints),
    root = as.character(root),
    source = as.character(source),
    citation = as.character(citation),
    license = as.character(license)
  )
  validate_anistructure(x)
}


#' @keywords internal
new_anistructure <- function(
  points = character(),
  segments = as_structure_segments(NULL),
  joints = as_structure_joints(NULL),
  root = NA_character_,
  source = NA_character_,
  citation = NA_character_,
  license = NA_character_,
  variable = NA_character_
) {
  structure(
    list(
      points = points,
      segments = segments,
      joints = joints,
      root = root,
      source = source,
      citation = citation,
      license = license,
      variable = variable
    ),
    class = "anistructure"
  )
}


#' @keywords internal
as_structure_segments <- function(segments) {
  if (is.null(segments)) {
    return(dplyr::tibble(
      segment = character(),
      from = character(),
      to = character(),
      length = numeric()
    ))
  }
  pairs <- coerce_to_pair_df(segments)
  dplyr::tibble(
    segment = if (is.data.frame(segments) && "segment" %in% names(segments)) {
      as.character(segments$segment)
    } else {
      paste(pairs$from, pairs$to, sep = "-")
    },
    from = pairs$from,
    to = pairs$to,
    length = if (is.data.frame(segments) && "length" %in% names(segments)) {
      as.numeric(segments$length)
    } else {
      rep(NA_real_, nrow(pairs))
    }
  )
}


#' @keywords internal
as_structure_joints <- function(joints) {
  if (is.null(joints)) {
    joints <- data.frame(a = character(), b = character())
  }
  if (!is.data.frame(joints) || !all(c("a", "b") %in% names(joints))) {
    cli::cli_abort(
      "{.arg joints} must be a data frame with columns {.field a} and {.field b}."
    )
  }
  n <- nrow(joints)
  column <- function(name, default) {
    if (name %in% names(joints)) joints[[name]] else rep(default, n)
  }
  dplyr::tibble(
    joint = as.character(column("joint", paste(joints$a, joints$b, sep = "-"))),
    a = as.character(joints$a),
    b = as.character(joints$b),
    axis = as.character(column("axis", NA_character_)),
    min = as.numeric(column("min", NA_real_)),
    max = as.numeric(column("max", NA_real_)),
    rest = as.numeric(column("rest", NA_real_))
  )
}


#' Check that a structure is internally consistent
#'
#' @param x An `anistructure`.
#'
#' @return `x`, invisibly; errors naming the first problem otherwise.
#'
#' @examples
#' validate_anistructure(example_structure())
#' @export
validate_anistructure <- function(x) {
  ensure_is_anistructure(x)
  points <- x$points
  segments <- x$segments
  joints <- x$joints

  if (anyNA(points) || anyDuplicated(points)) {
    cli::cli_abort("Points must be unique and not {.code NA}.")
  }
  ensure_unique_names(segments$segment, "Segment")
  ensure_unique_names(joints$joint, "Joint")

  endpoints <- c(segments$from, segments$to)
  unknown <- setdiff(endpoints, points)
  if (length(unknown) > 0L) {
    cli::cli_abort(
      "Segment endpoint{?s} {.val {unknown}} {?is/are} not among the points."
    )
  }
  loops <- segments$segment[segments$from == segments$to]
  if (length(loops) > 0L) {
    cli::cli_abort("Segment{?s} {.val {loops}} join{?s/} a point to itself.")
  }
  bad_length <- segments$segment[
    !is.na(segments$length) & !(segments$length > 0)
  ]
  if (length(bad_length) > 0L) {
    cli::cli_abort("Segment length{?s} must be positive: {.val {bad_length}}.")
  }

  unknown <- setdiff(c(joints$a, joints$b), segments$segment)
  if (length(unknown) > 0L) {
    cli::cli_abort(
      "Joint{?s} refer to segment{?s} {.val {unknown}}, which {?is/are} not defined."
    )
  }
  same <- joints$joint[joints$a == joints$b]
  if (length(same) > 0L) {
    cli::cli_abort("Joint{?s} {.val {same}} pair a segment with itself.")
  }
  axes <- joints$axis[!is.na(joints$axis)]
  unknown <- setdiff(axes, c("x", "y", "z", segments$segment))
  if (length(unknown) > 0L) {
    cli::cli_abort(c(
      "Unknown joint axis{?/es}: {.val {unknown}}.",
      "i" = "An axis is {.val {c('x', 'y', 'z')}} or a segment name."
    ))
  }
  inverted <- joints$joint[
    !is.na(joints$min) & !is.na(joints$max) & joints$min > joints$max
  ]
  if (length(inverted) > 0L) {
    cli::cli_abort(
      "Joint{?s} {.val {inverted}} ha{?s/ve} {.field min} above {.field max}."
    )
  }
  outside <- joints$joint[
    !is.na(joints$rest) &
      ((!is.na(joints$min) & joints$rest < joints$min) |
        (!is.na(joints$max) & joints$rest > joints$max))
  ]
  if (length(outside) > 0L) {
    cli::cli_abort(
      "Joint{?s} {.val {outside}} rest{?s/} outside {?its/their} limits."
    )
  }

  if (length(x$root) != 1L || (!is.na(x$root) && !x$root %in% points)) {
    cli::cli_abort("{.field root} must be one of the points, or {.code NA}.")
  }
  invisible(x)
}


#' @keywords internal
ensure_unique_names <- function(x, what) {
  bad <- x[is.na(x) | x == "" | duplicated(x)]
  if (length(bad) > 0L) {
    cli::cli_abort(
      "{what} names must be unique and non-empty: {.val {unique(bad)}}."
    )
  }
  invisible(TRUE)
}


#' Test whether an object is an anistructure
#'
#' @param x An object.
#' @return `is_anistructure()`: logical. `ensure_is_anistructure()`: errors
#'   if not.
#' @examples
#' is_anistructure(example_structure())
#' @export
is_anistructure <- function(x) {
  inherits(x, "anistructure")
}

#' @rdname is_anistructure
#' @export
ensure_is_anistructure <- function(x) {
  if (!is_anistructure(x)) {
    cli::cli_abort("{.arg x} is not an {.cls anistructure}.")
  }
  invisible(TRUE)
}


#' An example structure for the keypoints of [example_anipoint()]
#'
#' A spine from `abdomen` to `neck`, a head, shoulders, and two legs with
#' knee joints. Limits are illustrative, not anatomical.
#'
#' @return An `anistructure`.
#' @examples
#' example_structure()
#' @export
example_structure <- function() {
  anistructure(
    segments = data.frame(
      segment = c(
        "spine",
        "head",
        "shoulder_right",
        "shoulder_left",
        "hip_right",
        "hip_left",
        "thigh_right",
        "thigh_left",
        "shin_right",
        "shin_left"
      ),
      from = c(
        "abdomen",
        "neck",
        "neck",
        "neck",
        "abdomen",
        "abdomen",
        "hip_right",
        "hip_left",
        "knee_right",
        "knee_left"
      ),
      to = c(
        "neck",
        "head",
        "shoulder_right",
        "shoulder_left",
        "hip_right",
        "hip_left",
        "knee_right",
        "knee_left",
        "foot_right",
        "foot_left"
      )
    ),
    joints = data.frame(
      joint = c("neck", "knee_right", "knee_left"),
      a = c("spine", "thigh_right", "thigh_left"),
      b = c("head", "shin_right", "shin_left"),
      min = c(-1, 0, 0),
      max = c(1, 2.5, 2.5)
    ),
    root = "abdomen"
  )
}


#' @export
print.anistructure <- function(x, ...) {
  cat(format(x, ...), sep = "\n")
  invisible(x)
}

#' @export
format.anistructure <- function(x, ...) {
  count <- function(n, what) paste(n, if (n == 1) what else paste0(what, "s"))
  header <- paste0(
    "<anistructure> ",
    paste(
      count(length(x$points), "point"),
      count(nrow(x$segments), "segment"),
      count(nrow(x$joints), "joint"),
      sep = ", "
    )
  )
  details <- c(
    variable = x$variable,
    root = x$root
  )
  details <- details[!is.na(details)]
  lines <- header
  if (length(details) > 0L) {
    lines <- c(
      lines,
      paste(names(details), details, sep = ": ", collapse = "; ")
    )
  }
  if (length(x$points) > 0L) {
    lines <- c(lines, paste("Points:", paste(x$points, collapse = ", ")))
  }
  if (nrow(x$segments) > 0L) {
    lines <- c(
      lines,
      paste(
        "Segments:",
        paste0(
          x$segments$segment,
          " (",
          x$segments$from,
          " -> ",
          x$segments$to,
          ")",
          collapse = ", "
        )
      )
    )
  }
  if (nrow(x$joints) > 0L) {
    lines <- c(
      lines,
      paste(
        "Joints:",
        paste0(
          x$joints$joint,
          " (",
          x$joints$a,
          ", ",
          x$joints$b,
          ")",
          collapse = ", "
        )
      )
    )
  }
  lines
}
