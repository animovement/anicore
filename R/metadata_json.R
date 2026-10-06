#' Read and write a frame's metadata as JSON
#'
#' @description
#' `get_metadata_json()` gives a frame's metadata as JSON, which any language
#' can read. `set_metadata_json()` restores metadata from that JSON, so that
#' the round trip gives back exactly what [get_metadata()] gave.
#'
#' This is how the metadata travels outside R, for instance in the key-value
#' metadata of a Parquet file written by aniread.
#'
#' @param data An aniframe. For `set_metadata_json()`, a frame of the class the
#'   metadata belongs to: its class decides which categories and slots are
#'   valid.
#' @param json A JSON string from `get_metadata_json()`. Or that JSON already
#'   parsed with `jsonlite::fromJSON(simplifyVector = FALSE)`, for when it is
#'   embedded in a larger document.
#'
#' @section Layout:
#' The JSON has the categories of [list_default_metadata()] as objects, in
#' the same order, with `spec_version` saying which version of the layout it
#' follows:
#'
#' * A field with a fixed set of values (`unit_time`, `unit_space`,
#'   `coordinate_system`, ...) is its value as a string.
#' * `NA` is `null`. `source_sampling_rate` can also be the string `"NaN"`:
#'   a device with no fixed rate, which JSON has no number for.
#' * `start_datetime` is an ISO 8601 time in UTC, to the microsecond, with
#'   its time zone beside it as `start_timezone` (an IANA name, or `""` for the
#'   session's own).
#' * `axis_directions` and `axis_extents` are objects from axis role to value.
#' * In `variables`, each role is an object of slots. A slot that maps axis
#'   roles to columns (`where$position`) is an object; one that lists
#'   columns (`what$keys`) is an array, even with one column.
#' * `structure` is an object of structures. Each has `points` (an array),
#'   `segments` and `joints` (arrays of row objects), and `root`, `source`,
#'   `citation`, `license` and `variable`.
#'
#' Numbers are written with as few digits as read back exactly. `Inf` and
#' `-Inf`, which JSON also has no number for, are strings like `"NaN"`.
#'
#' @return `get_metadata_json()`: a JSON string. `set_metadata_json()`: `data`
#'   with the metadata from `json`.
#'
#' @seealso [get_metadata()], [set_metadata()]
#'
#' @examplesIf rlang::is_installed("jsonlite")
#' x <- example_anipoint(n_obs = 2, n_individuals = 1)
#' json <- get_metadata_json(x)
#' json
#'
#' y <- set_metadata_json(x, json)
#' identical(get_metadata(y), get_metadata(x))
#' @name metadata_json
NULL

#' @rdname metadata_json
#' @export
get_metadata_json <- function(data) {
  check_jsonlite()
  metadata <- get_metadata(data)
  tree <- lapply(unclass(metadata), identity)
  tree <- Map(encode_metadata_category, names(tree), tree)
  as.character(jsonlite::toJSON(
    tree,
    auto_unbox = FALSE,
    null = "null",
    na = "null",
    json_verbatim = TRUE
  ))
}

#' @rdname metadata_json
#' @export
set_metadata_json <- function(data, json) {
  check_jsonlite()
  ensure_is_aniframe(data)
  if (rlang::is_string(json)) {
    json <- jsonlite::fromJSON(json, simplifyVector = FALSE)
  }
  if (!is.list(json) || is.null(names(json))) {
    cli::cli_abort(
      "{.arg json} must be a JSON object of metadata, or one parsed with
       {.code jsonlite::fromJSON(simplifyVector = FALSE)}."
    )
  }
  metadata <- Map(decode_metadata_category, names(json), json)
  class(metadata) <- c("aniframe_metadata", "list")
  set_metadata(data, metadata = metadata)
}


check_jsonlite <- function() {
  rlang::check_installed(
    "jsonlite",
    reason = "to read and write metadata as JSON."
  )
}

# Encoding ---------------------------------------------------------------------

encode_metadata_category <- function(name, value) {
  switch(
    name,
    spec_version = lapply(value, jsonlite::unbox),
    variables = lapply(value, \(role) lapply(role, encode_slot)),
    structure = encode_named_list(lapply(value, encode_structure)),
    encode_fields(value)
  )
}

# The fields of recording, time and space
encode_fields <- function(fields) {
  out <- list()
  for (name in names(fields)) {
    value <- fields[[name]]
    if (identical(name, "start_datetime")) {
      out$start_datetime <- jsonlite::unbox(format_datetime(value))
      out$start_timezone <- jsonlite::unbox(attr(value, "tzone") %||% "")
    } else if (name %in% c("axis_directions", "axis_extents")) {
      out[[name]] <- encode_named_list(lapply(as.list(value), encode_scalar))
    } else {
      out[[name]] <- encode_scalar(value)
    }
  }
  out
}

encode_scalar <- function(x) {
  if (is.factor(x)) {
    x <- as.character(x)
  }
  if (is.numeric(x) && length(x) == 1L && !is.na(x)) {
    return(encode_number(x))
  }
  if (is.numeric(x) && length(x) == 1L && is.nan(x)) {
    return(jsonlite::unbox("NaN"))
  }
  jsonlite::unbox(x)
}

# The shortest decimal that reads back as exactly `x`: 29.97, not
# 29.969999999999999
encode_number <- function(x) {
  if (!is.finite(x)) {
    return(jsonlite::unbox(if (x > 0) "Inf" else "-Inf"))
  }
  for (digits in 15:17) {
    text <- formatC(x, digits = digits, format = "g")
    if (as.numeric(text) == x) {
      break
    }
  }
  structure(trimws(text), class = "json")
}

# A slot naming axis roles is an object; a list of columns is an array
encode_slot <- function(x) {
  if (is.null(names(x))) {
    return(as.character(x))
  }
  encode_named_list(lapply(as.list(x), jsonlite::unbox))
}

# A named list that stays an object when empty
encode_named_list <- function(x) {
  if (length(x) == 0L) {
    return(stats::setNames(list(), character()))
  }
  x
}

encode_structure <- function(s) {
  s <- unclass(s)
  list(
    points = as.character(s$points),
    segments = encode_rows(s$segments),
    joints = encode_rows(s$joints),
    root = encode_scalar(s$root),
    source = encode_scalar(s$source),
    citation = encode_scalar(s$citation),
    license = encode_scalar(s$license),
    variable = encode_scalar(s$variable)
  )
}

encode_rows <- function(df) {
  lapply(seq_len(nrow(df)), \(i) {
    lapply(as.list(df[i, , drop = FALSE]), \(v) encode_scalar(v[[1]]))
  })
}

format_datetime <- function(x) {
  if (is.na(x)) {
    return(NA_character_)
  }
  format(x, "%Y-%m-%dT%H:%M:%OS6Z", tz = "UTC")
}

# Decoding ---------------------------------------------------------------------

decode_metadata_category <- function(name, value) {
  switch(
    name,
    spec_version = lapply(value, as.character),
    variables = lapply(value, \(role) lapply(role, decode_slot)),
    structure = decode_structures(value),
    decode_fields(value)
  )
}

decode_fields <- function(fields) {
  out <- list()
  for (name in setdiff(names(fields), "start_timezone")) {
    value <- fields[[name]]
    template <- default_metadata_leaf(name)
    out[[name]] <- if (identical(name, "start_datetime")) {
      parse_datetime(value, fields$start_timezone %||% "")
    } else if (name %in% c("axis_directions", "axis_extents")) {
      decode_named_vector(value, template)
    } else if (is.null(template)) {
      cli::cli_abort("Unknown metadata field {.field {name}} in the JSON.")
    } else {
      decode_scalar(value, template)
    }
  }
  out
}

decode_scalar <- function(x, template) {
  if (is.factor(template)) {
    return(factor(x %||% NA_character_, levels = levels(template)))
  }
  if (is.numeric(template)) {
    if (is.character(x)) {
      return(c("NaN" = NaN, "Inf" = Inf, "-Inf" = -Inf)[[x]])
    }
    return(as.numeric(x %||% NA_real_))
  }
  if (is.logical(template)) {
    return(as.logical(x %||% NA))
  }
  as.character(x %||% NA_character_)
}

decode_named_vector <- function(x, template) {
  values <- vapply(
    x,
    \(v) decode_scalar(v, template[NA_integer_]),
    vector(typeof(template), 1L),
    USE.NAMES = FALSE
  )
  stats::setNames(values, names(x) %||% character())
}

decode_slot <- function(x) {
  values <- vapply(x, as.character, character(1), USE.NAMES = FALSE)
  if (is.null(names(x))) {
    return(values)
  }
  stats::setNames(values, names(x))
}

parse_datetime <- function(x, tz) {
  if (is.null(x)) {
    out <- as.POSIXct(NA)
  } else {
    out <- as.POSIXct(x, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  }
  attr(out, "tzone") <- tz
  out
}

decode_structures <- function(x) {
  out <- lapply(x, decode_structure)
  if (length(out) == 0L) {
    return(list())
  }
  out
}

decode_structure <- function(s) {
  new_anistructure(
    points = vapply(s$points, as.character, character(1), USE.NAMES = FALSE),
    segments = decode_rows(s$segments, as_structure_segments(NULL)),
    joints = decode_rows(s$joints, as_structure_joints(NULL)),
    root = decode_scalar(s$root, NA_character_),
    source = decode_scalar(s$source, NA_character_),
    citation = decode_scalar(s$citation, NA_character_),
    license = decode_scalar(s$license, NA_character_),
    variable = decode_scalar(s$variable, NA_character_)
  )
}

# Rows back into a table typed like `template`
decode_rows <- function(rows, template) {
  columns <- lapply(names(template), \(col) {
    vapply(
      rows,
      \(r) decode_scalar(r[[col]], template[[col]]),
      vector(typeof(template[[col]]), 1L),
      USE.NAMES = FALSE
    )
  })
  dplyr::as_tibble(stats::setNames(columns, names(template)))
}
