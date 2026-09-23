#' Convert a data frame to anipoint
#'
#' @param data A data frame with movement data.
#' @param metadata A list of metadata to attach to the anipoint.
#' @param variables_what Character vector of identity columns that together
#'   define a unique entity, and which the frame is grouped by. If `NULL`
#'   (the default), detected from the data: whichever of `model`,
#'   `individual`, `subject`, `track` and `keypoint` are present, in the
#'   order [list_recognised_variables_what()] lists them. Order carries no
#'   meaning of its own — see its documentation. An anipoint needs
#'   at least one identity variable, so if none of them is found, a
#'   `keypoint` column is added with the value `"centroid"`. Pass
#'   `character(0)` to declare no identity variables at all — a
#'   deliberate opt-out, which leaves the frame ungrouped. Every column
#'   named here must exist in `data`.
#' @param variables_when Character vector of temporal columns that together
#'   define a unique timepoint. If `NULL` (the default), detected from the
#'   data: whichever of `observation`, `session`, `trial` and `time` are
#'   present, minus the index. These are the temporal *context* — which
#'   session, which trial — and, together with `variables_what`, they are
#'   what the frame is grouped by. The index itself is declared separately
#'   and is never one of them.
#' @param index Length-one character vector naming the column the frame is
#'   indexed by — the position of each row within its temporal context.
#'   It is never a grouping variable. If
#'   `NULL` (the default), the frame's existing declaration is kept, or
#'   `"time"` for a frame that has none. The column must exist and be
#'   numeric; it may be called anything.
#' @param variables_where The spatial columns that together define
#'   position. Either a plain character vector of column names, in which
#'   case the name is taken to be the axis role, or a vector named by axis
#'   role — `c(x = "u", y = "v")` — which lets the columns be called
#'   anything. The roles themselves are a closed set (`x`, `y`, `z`,
#'   `rho`, `phi`, `theta`), so that transformations between coordinate
#'   systems stay well defined; an unrecognised role is rejected by name.
#'   If `NULL` (the default), detected from the data.
#'
#' @param root For an [as_anisegment()] frame: an anipoint holding the root
#'   point's trajectory, such as the frame the segments came from. The other
#'   points are rebuilt by walking the structure's segments outward from it.
#' @return An anipoint object
#' @examples
#' df <- data.frame(
#'   time = 1:3, individual = 'a', keypoint = 'centroid',
#'   x = c(0, 1, 2), y = c(0, 1, 0)
#' )
#' as_anipoint(df)
#' @export
as_anipoint <- function(
  data,
  metadata = list(),
  variables_what = NULL,
  variables_when = NULL,
  variables_where = NULL,
  index = NULL,
  root = NULL
) {
  if (is_anisegment(data)) {
    return(anisegment_to_anipoint(data, root))
  }
  defaults <- list_default_metadata()

  if (!is.null(index)) {
    ensure_index_name(index)
  }
  index <- index %||%
    (if (is_aniframe(data)) {
      resolve_index(get_metadata(data))
    } else {
      NULL
    }) %||%
    "time"

  # Keep existing declarations so a re-cast doesn't overwrite a custom
  # identity with `keypoint = "centroid"` (#96).
  variables_when <- variables_when %||%
    get_declared_if_present(data, "variables_when")
  variables_what <- variables_what %||%
    get_declared_if_present(data, "variables_what")
  variables_where <- variables_where %||%
    get_declared_if_present(data, "variables_where")

  if (is.null(variables_when)) {
    recognised_when <- c("observation", "session", "trial", "time")
    variables_when <- recognised_when[recognised_when %in% names(data)]
  }

  variables_when <- setdiff(variables_when, index)

  if (is.null(variables_what)) {
    data <- add_default_identity(data)
    variables_what <- list_recognised_variables_what()[
      list_recognised_variables_what() %in% names(data)
    ]
  }

  if (is.null(variables_where)) {
    variables_where <- detect_variables_where(data)
    if (is.null(variables_where)) {
      cli::cli_abort(
        c(
          "No spatial variables found in data.",
          "i" = "Expected columns like {.val x}, {.val y}, {.val z}, {.val rho}, {.val phi}, or {.val theta}.",
          "i" = "Alternatively, specify {.arg variables_where} explicitly."
        )
      )
    }
  }

  data <- new_anipoint(data)
  data <- set_metadata(data, metadata = metadata)

  # `set_metadata()` refuses declarations, so the index is attached directly.
  md <- get_metadata(data)
  md$variables$when$index <- index
  data <- attach_metadata(data, md)

  data <- restructure_anipoint(
    data,
    variables_what,
    variables_when,
    variables_where
  )

  data
}


#' Add a default identity variable when the data has none
#'
#' Adds `keypoint = "centroid"` (kept over alternatives in #77).
#'
#' @param data Data frame to complete.
#'
#' @return `data`, with an identity column added if it had none.
#' @keywords internal
add_default_identity <- function(data) {
  has_identity <- any(list_recognised_variables_what() %in% names(data))

  if (!has_identity) {
    data$keypoint <- "centroid"
  }

  data
}

#' Detect spatial variables from data
#'
#' Polar-family runs first so cylindrical data isn't taken as Cartesian
#' because of its `z` column.
#'
#' @param data Data frame to check.
#' @return Character vector of detected spatial variable names, or NULL if none found.
#' @keywords internal
detect_variables_where <- function(data) {
  has_rho <- "rho" %in% names(data)
  has_phi <- "phi" %in% names(data)
  has_theta <- "theta" %in% names(data)
  has_z <- "z" %in% names(data)

  if (has_rho && has_phi) {
    if (has_theta) {
      return(c("rho", "phi", "theta")) # spherical
    } else if (has_z) {
      return(c("rho", "phi", "z")) # cylindrical
    } else {
      return(c("rho", "phi")) # polar
    }
  }

  cartesian <- c("x", "y", "z")
  present_cartesian <- cartesian[cartesian %in% names(data)]
  if (length(present_cartesian) > 0) {
    return(present_cartesian)
  }

  NULL
}


#' A role the data already declares, when its columns are still there
#'
#' @param data Data frame, possibly carrying metadata.
#' @param field One of the `variables_*` metadata fields.
#'
#' @return The declared column names, or `NULL` to detect instead.
#' @keywords internal
get_declared_if_present <- function(data, field) {
  if (!has_metadata(data)) {
    return(NULL)
  }

  md <- migrate_metadata_layout(attr(data, "metadata"))
  declared <- switch(
    sub("^variables_", "", field),
    what = md_what_keys(md),
    when = md_when_keys(md),
    # Keep the role mapping, or renamed axes degrade to "unknown" (#109).
    where = if (length(resolve_axes(md)) > 0L) {
      resolve_axes(md)
    } else {
      unname(md_where_position(md))
    }
  )
  declared <- declared[!is.na(declared)]

  # An empty `variables_what` is a deliberate opt-out, not re-detected.
  if (length(declared) == 0) {
    return(if (identical(field, "variables_what")) character(0) else NULL)
  }

  if (all(declared %in% names(data))) declared else NULL
}
