#' Convert segments to joints: one angle per joint
#'
#' @description
#' Computes the angle of each joint of a structure from the directions of
#' its two segments `a` and `b`, with [angle_between()]:
#'
#' * In 2D, the signed angle turning from `a` to `b`, in `[-pi, pi]`,
#'   positive from `x` toward `y`. [get_angle_direction()] says how that
#'   looks on screen.
#' * In 3D with no joint `axis`, the included angle, in `[0, pi]`.
#' * In 3D with an `axis` (`"x"`, `"y"`, `"z"` or a segment name), the
#'   signed angle about it after projecting both segments onto the plane
#'   perpendicular to it.
#'
#' The angle is 0 when the two segments point the same way. The segment key
#' is replaced by a `joint` key, the angle is in the frame's `unit_angle`,
#' and `confidence` is the lower of the two segments'.
#'
#' A joint frame cannot be converted back: it keeps no lengths and, in 3D,
#' no rotation about the segments themselves.
#'
#' @param data An [as_anisegment()] frame, or an anipoint, which is
#'   converted to segments first.
#' @param structure For an anipoint, the structure to use; see
#'   [as_anisegment()].
#'
#' @return An `anijoint`.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1) |>
#'   set_structure(example_structure())
#' as_anijoint(af)
#'
#' @seealso [angle_between()], [anistructure()]
#' @export
as_anijoint <- function(data, structure = NULL) {
  if (is_anipoint(data)) {
    data <- as_anisegment(data, structure)
  }
  ensure_is_anisegment(data)

  keys <- get_keys(data)
  struct <- source_structure(data)
  if (nrow(struct$joints) == 0L) {
    cli::cli_abort(c(
      "The structure has no joints.",
      "i" = "Declare them with {.code anistructure(joints = )}."
    ))
  }
  if ("joint" %in% names(data)) {
    cli::cli_abort(
      "The frame already has a {.field joint} column, which the conversion would overwrite."
    )
  }

  direction <- get_variables(data, "where", "direction")
  planar <- length(direction) == 2L
  base <- c(setdiff(keys, "segment"), get_index(data))
  extras <- intersect("confidence", names(data))
  segs <- dplyr::ungroup(strip_animovement_class(data))
  segs$segment <- as.character(segs$segment)
  segs <- segs[, c(base, "segment", unname(direction), extras)]
  pick <- function(name) {
    segs[segs$segment == name, setdiff(names(segs), "segment")]
  }

  joints <- lapply(seq_len(nrow(struct$joints)), function(i) {
    j <- struct$joints[i, ]
    ends <- dplyr::inner_join(
      pick(j$a),
      pick(j$b),
      by = base,
      suffix = c(".a", ".b")
    )
    u <- as.matrix(ends[, paste0(direction, ".a")])
    v <- as.matrix(ends[, paste0(direction, ".b")])
    axis <- joint_axis(j, planar, ends, pick, base, direction)
    out <- ends[, base]
    out$joint <- j$joint
    out$angle <- angle_between(u, v, axis)
    if (length(extras) > 0L) {
      out$confidence <- pmin(ends$confidence.a, ends$confidence.b)
    }
    out
  })
  out <- dplyr::bind_rows(joints)
  out$joint <- factor(out$joint, levels = struct$joints$joint)
  if (identical(as.character(get_metadata(data, "unit_angle")), "deg")) {
    out$angle <- rad_to_deg(out$angle)
  }

  md <- get_metadata(data)
  what <- md$variables$what$keys
  when <- md$variables$when$keys
  md$variables <- list(
    what = list(keys = replace(what, what == "segment", "joint")),
    when = list(
      index = md$variables$when$index,
      keys = replace(when, when == "segment", "joint")
    ),
    where = list(angle = "angle")
  )
  restructure_value_frame(new_anijoint(out), md)
}


#' The axis a joint angle is measured about, one row per observation
#'
#' @return `NULL` for the included angle, or a matrix with 3 columns.
#' @keywords internal
joint_axis <- function(joint, planar, ends, pick, base, direction) {
  axis <- joint$axis
  if (planar) {
    if (!is.na(axis) && !identical(axis, "z")) {
      cli::cli_abort(
        "Joint {.val {joint$joint}} has axis {.val {axis}}, but a 2D frame only turns about {.val z}."
      )
    }
    return(c(0, 0, 1))
  }
  if (is.na(axis)) {
    return(NULL)
  }
  if (axis %in% c("x", "y", "z")) {
    return(as.numeric(c("x", "y", "z") == axis))
  }
  about <- dplyr::left_join(ends[, base], pick(axis), by = base)
  as.matrix(about[, unname(direction)])
}


#' The structure a segment or joint frame was built from
#'
#' The one whose variable is no longer a key.
#'
#' @keywords internal
source_structure <- function(data) {
  keys <- get_keys(data)
  Filter(function(s) !s$variable %in% keys, get_structure(data))[[1]]
}


#' @keywords internal
new_anijoint <- function(x) {
  class(x) <- unique(c("anijoint", "aniframe", class(x)))
  x
}


#' Test whether an object is an anijoint
#'
#' @param x An object.
#' @return `is_anijoint()`: logical. `ensure_is_anijoint()`: errors if not.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1) |>
#'   set_structure(example_structure())
#' is_anijoint(as_anijoint(af))
#' @export
is_anijoint <- function(x) {
  inherits(x, "anijoint")
}

#' @rdname is_anijoint
#' @export
ensure_is_anijoint <- function(x) {
  if (!is_anijoint(x)) {
    cli::cli_abort("Data is not an anijoint.")
  }
  invisible(TRUE)
}


#' @importFrom pillar tbl_sum
#' @export
tbl_sum.anijoint <- function(x, ...) {
  header <- NextMethod()
  names(header)[1] <- "anijoint"
  structure_name <- names(get_structure(x))[
    vapply(get_structure(x), identical, logical(1), source_structure(x))
  ]
  c(header, "Structure" = structure_name)
}
