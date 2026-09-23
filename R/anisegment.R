#' Convert an anipoint to segments: a length and a direction per segment
#'
#' @description
#' Re-expresses the positions of a structure's points as its segments. Each
#' row is one segment at one time: its `length` and the unit vector `ux`,
#' `uy` (and `uz` in 3D) pointing from the segment's `from` point to its
#' `to` point, in the frame's axes and units.
#'
#' The structure's variable (usually `keypoint`) is replaced by a `segment`
#' key. Structures over that variable other than `structure` are dropped;
#' those over the remaining keys are kept. A `confidence` column becomes the
#' lower of the two endpoints' values; other undeclared columns are
#' dropped.
#'
#' [as_anipoint()] inverts the conversion given the root point's trajectory.
#'
#' @param data A Cartesian 2D or 3D anipoint.
#' @param structure Name of the structure to use. May be omitted when only
#'   one structure has segments.
#'
#' @return An `anisegment`.
#'
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1) |>
#'   set_structure(example_structure())
#' seg <- as_anisegment(af)
#' seg
#'
#' # Round trip, given the root's trajectory
#' back <- as_anipoint(seg, root = af)
#'
#' @seealso [anistructure()], [set_structure()]
#' @export
as_anisegment <- function(data, structure = NULL) {
  ensure_is_anipoint(data)
  ensure_coordinate_system(
    data,
    c("cartesian_2d", "cartesian_3d"),
    "2D or 3D Cartesian"
  )
  name <- resolve_segment_structure(data, structure)
  struct <- get_structure(data, name)
  variable <- struct$variable
  if ("segment" %in% names(data)) {
    cli::cli_abort(
      "The frame already has a {.field segment} column, which the conversion would overwrite."
    )
  }

  axes <- get_axes(data)
  keys <- c(setdiff(get_keys(data), variable), get_index(data))
  extras <- intersect("confidence", names(data))
  points <- dplyr::ungroup(strip_animovement_class(data))
  points <- points[, c(keys, variable, unname(axes), extras)]
  points[[variable]] <- as.character(points[[variable]])

  segments <- lapply(seq_len(nrow(struct$segments)), function(i) {
    s <- struct$segments[i, ]
    ends <- dplyr::inner_join(
      points[points[[variable]] == s$from, ],
      points[points[[variable]] == s$to, ],
      by = keys,
      suffix = c(".from", ".to")
    )
    delta <- vapply(
      names(axes),
      function(role) {
        ends[[paste0(axes[[role]], ".to")]] -
          ends[[paste0(axes[[role]], ".from")]]
      },
      numeric(nrow(ends))
    )
    delta <- matrix(delta, nrow = nrow(ends))
    length <- sqrt(rowSums(delta^2))
    out <- ends[, keys]
    out$segment <- s$segment
    out$length <- length
    for (j in seq_along(axes)) {
      out[[paste0("u", names(axes)[[j]])]] <- ifelse(
        length > 0,
        delta[, j] / length,
        NA_real_
      )
    }
    if (length(extras) > 0L) {
      out$confidence <- pmin(ends$confidence.from, ends$confidence.to)
    }
    out
  })
  out <- dplyr::bind_rows(segments)
  out$segment <- factor(out$segment, levels = struct$segments$segment)

  md <- get_metadata(data)
  what <- md$variables$what$keys
  when <- md$variables$when$keys
  md$variables <- list(
    what = list(keys = replace(what, what == variable, "segment")),
    when = list(
      index = md$variables$when$index,
      keys = replace(when, when == variable, "segment")
    ),
    where = list(
      length = "length",
      direction = stats::setNames(paste0("u", names(axes)), names(axes))
    )
  )
  md$structure <- Filter(
    function(s) !identical(s$variable, variable),
    md$structure
  )
  md$structure[[name]] <- struct

  restructure_value_frame(new_anisegment(out), md)
}


#' Pick the structure a segment conversion uses
#'
#' @keywords internal
resolve_segment_structure <- function(data, structure) {
  structures <- get_structure(data)
  if (!is.null(structure)) {
    ensure_known_structure(structures, structure)
    return(structure)
  }
  with_segments <- names(Filter(function(s) nrow(s$segments) > 0L, structures))
  if (length(with_segments) != 1L) {
    cli::cli_abort(c(
      if (length(with_segments) == 0L) {
        "The frame has no structure with segments."
      } else {
        "Several structures have segments: {.val {with_segments}}."
      },
      "i" = "Attach one with {.fn set_structure}, or name it with {.arg structure}."
    ))
  }
  with_segments
}


#' @keywords internal
new_anisegment <- function(x) {
  class(x) <- unique(c("anisegment", "aniframe", class(x)))
  x
}


#' Order, group and declare a segment or joint frame
#'
#' @param data An anisegment or anijoint.
#' @param md Its complete metadata.
#'
#' @return `data`, restructured, with `md` attached.
#' @keywords internal
restructure_value_frame <- function(data, md) {
  cls <- class(data)
  variables <- md$variables
  what <- as.character(variables$what$keys)
  when <- as.character(variables$when$keys)
  index <- variables$when$index
  value_cols <- unname(unlist(variables$where))

  bare <- strip_animovement_class(data)
  ensure_has_declared_cols(bare, c(what, when, index), "what")
  ensure_has_declared_cols(bare, value_cols, "where")

  standard <- unique(c(what, when, index, value_cols))
  bare <- bare[, c(standard, setdiff(names(bare), standard))]
  bare <- dplyr::arrange(
    bare,
    dplyr::across(dplyr::all_of(c(what, when, index)))
  )
  bare <- regroup_frame(bare, c(what, when))
  preserve_animovement_class(bare, cls, md)
}


#' Rebuild point positions from an anisegment
#'
#' Walks the structure's segments outward from its root; segments that close
#' a cycle are not needed and are ignored.
#'
#' @param data An anisegment.
#' @param root An anipoint holding the root point's trajectory, such as the
#'   frame the segments came from.
#'
#' @return An anipoint.
#' @keywords internal
anisegment_to_anipoint <- function(data, root) {
  if (is.null(root) || !is_anipoint(root)) {
    cli::cli_abort(c(
      "Rebuilding positions from segments needs the root's trajectory.",
      "i" = "Pass an anipoint holding the root point as {.arg root}, such as the frame the segments came from."
    ))
  }
  keys <- get_keys(data)
  struct <- source_structure(data)
  variable <- struct$variable
  if (is.na(struct$root)) {
    cli::cli_abort(c(
      "The structure has no {.field root} to rebuild from.",
      "i" = "Set one with {.code anistructure(root = )}."
    ))
  }

  axes <- get_axes(root)
  direction <- get_variables(data, "where", "direction")
  if (!setequal(names(axes), names(direction))) {
    cli::cli_abort(
      "The root is in {.val {names(axes)}} but the segments in {.val {names(direction)}}."
    )
  }
  axes <- axes[names(direction)]
  base <- c(setdiff(keys, "segment"), get_index(data))

  anchor <- dplyr::ungroup(strip_animovement_class(root))
  anchor <- anchor[as.character(anchor[[variable]]) == struct$root, ]
  anchor <- anchor[, c(base, unname(axes))]
  if (nrow(anchor) == 0L) {
    cli::cli_abort(
      "{.arg root} has no rows for the root point {.val {struct$root}}."
    )
  }

  segs <- dplyr::ungroup(strip_animovement_class(data))
  position <- list()
  position[[struct$root]] <- as.matrix(anchor[, unname(axes)])
  pending <- struct$segments
  repeat {
    placed <- pending$from %in%
      names(position) |
      pending$to %in% names(position)
    if (!any(placed)) {
      break
    }
    for (i in which(placed)) {
      s <- pending[i, ]
      rows <- dplyr::left_join(
        anchor[, base],
        segs[as.character(segs$segment) == s$segment, ],
        by = base
      )
      step <- rows$length * as.matrix(rows[, unname(direction)])
      if (s$from %in% names(position) && !s$to %in% names(position)) {
        position[[s$to]] <- position[[s$from]] + step
      } else if (!s$from %in% names(position)) {
        position[[s$from]] <- position[[s$to]] - step
      }
    }
    pending <- pending[!placed, ]
  }
  unplaced <- setdiff(struct$points, names(position))
  if (length(unplaced) > 0L) {
    cli::cli_abort(
      "{cli::qty(unplaced)}Point{?s} {.val {unplaced}} {?is/are} not connected to the root {.val {struct$root}}."
    )
  }

  out <- dplyr::bind_rows(lapply(struct$points, function(p) {
    block <- anchor[, base]
    block[[variable]] <- p
    block[, unname(axes)] <- position[[p]]
    block
  }))
  out[[variable]] <- factor(out[[variable]], levels = struct$points)

  md <- get_metadata(data)
  what <- md$variables$what$keys
  when <- md$variables$when$keys
  af <- as_anipoint(
    out,
    variables_what = replace(what, what == "segment", variable),
    variables_when = replace(when, when == "segment", variable),
    variables_where = axes,
    index = get_index(data)
  )
  restored <- get_metadata(af)
  for (category in c("recording", "time", "space")) {
    restored[[category]] <- md[[category]]
  }
  restored$structure <- md$structure
  write_metadata(af, restored)
}


#' Test whether an object is an anisegment
#'
#' @param x An object.
#' @return `is_anisegment()`: logical. `ensure_is_anisegment()`: errors if
#'   not.
#' @examples
#' af <- example_anipoint(n_obs = 3, n_individuals = 1) |>
#'   set_structure(example_structure())
#' is_anisegment(as_anisegment(af))
#' @export
is_anisegment <- function(x) {
  inherits(x, "anisegment")
}

#' @rdname is_anisegment
#' @export
ensure_is_anisegment <- function(x) {
  if (!is_anisegment(x)) {
    cli::cli_abort("Data is not an anisegment.")
  }
  invisible(TRUE)
}


#' @importFrom pillar tbl_sum
#' @export
tbl_sum.anisegment <- function(x, ...) {
  header <- NextMethod()
  names(header)[1] <- "anisegment"
  structure_name <- names(get_structure(x))[
    vapply(get_structure(x), identical, logical(1), source_structure(x))
  ]
  c(header, "Structure" = structure_name)
}
