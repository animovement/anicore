# Methods for the aniframe family to preserve class through dplyr
# operations. `aniframe` is the abstract parent of every animovement
# frame class, so one method set serves anipoint, anievent and any
# downstream subclass.
#
# Each method captures the incoming class vector *before* dispatch and
# hands it back to `preserve_animovement_class()`, which restores it. That
# is what carries subclasses (anipoint, anievent, animetric's
# `aniframe_kin` and friends) through a pipeline — rebuilding a fixed
# `aniframe` here would drop them (#81).

# ---- dplyr verb methods ----

#' Ungroup an aniframe
#'
#' @param x An aniframe object
#' @param ... Additional arguments passed to dplyr::ungroup
#' @return An ungrouped aniframe
#' @keywords internal
#' @export
ungroup.aniframe <- function(x, ...) {
  cli::cli_warn(
    "Ungrouping an {class(x)[[1]]} data frame makes errors more likely. Proceed with care."
  )
  cls <- class(x)
  md <- get_metadata(x)
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Group an aniframe
#'
#' @param .data An aniframe object
#' @param ... Variables to group by
#' @return A grouped aniframe
#' @keywords internal
#' @export
group_by.aniframe <- function(.data, ...) {
  cls <- class(.data)
  md <- get_metadata(.data)
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Mutate columns in an aniframe
#'
#' @param .data An aniframe object
#' @param ... Name-value pairs of expressions
#' @return An aniframe with modified columns
#' @keywords internal
#' @export
mutate.aniframe <- function(.data, ...) {
  cls <- class(.data)
  md <- get_metadata(.data)
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Select columns from an aniframe
#'
#' @param .data An aniframe object
#' @param ... Columns to select
#' @return An aniframe with selected columns
#' @keywords internal
#' @export
select.aniframe <- function(.data, ...) {
  cls <- class(.data)
  md <- get_metadata(.data)
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Filter rows of an aniframe
#'
#' @param .data An aniframe object
#' @param ... Logical predicates
#' @param .preserve Keep group structure
#' @return A filtered aniframe
#' @keywords internal
#' @export
filter.aniframe <- function(.data, ..., .preserve = FALSE) {
  cls <- class(.data)
  md <- get_metadata(.data)
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Arrange rows of an aniframe
#'
#' @param .data An aniframe object
#' @param ... Variables to order by
#' @param .by_group If TRUE, arrange within groups
#' @return An arranged aniframe
#' @keywords internal
#' @export
arrange.aniframe <- function(.data, ..., .by_group = FALSE) {
  cls <- class(.data)
  md <- get_metadata(.data)
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Rename columns in an aniframe
#'
#' @param .data An aniframe object
#' @param ... Name-value pairs for renaming
#' @return An aniframe with renamed columns
#' @keywords internal
#' @export
rename.aniframe <- function(.data, ...) {
  cls <- class(.data)
  md <- get_metadata(.data)
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Relocate columns in an aniframe
#'
#' @param .data An aniframe object
#' @param ... Columns to relocate
#' @return An aniframe with relocated columns
#' @keywords internal
#' @export
relocate.aniframe <- function(.data, ...) {
  cls <- class(.data)
  md <- get_metadata(.data)
  class(.data) <- setdiff(class(.data), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Slice rows from an aniframe
#'
#' @param .data An aniframe object
#' @param ... Integer row positions
#' @param .preserve Keep group structure
#' @return A sliced aniframe
#' @keywords internal
#' @export
slice.aniframe <- function(.data, ..., .preserve = FALSE) {
  cls <- class(.data)
  md <- get_metadata(.data)
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

# ---- Base R extraction methods ----

#' Subset aniframe with [
#'
#' @param x An aniframe object
#' @param i Row indices
#' @param j Column indices
#' @param ... Additional arguments
#' @param drop If TRUE, simplify to vector when possible
#' @return A subset aniframe
#' @keywords internal
#' @export
`[.aniframe` <- function(x, i, j, ..., drop = FALSE) {
  cls <- class(x)
  md <- get_metadata(x)
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Extract single column from aniframe with [[
#'
#' @param x An aniframe object
#' @param i Column index or name
#' @param ... Additional arguments
#' @return A vector or data frame
#' @keywords internal
#' @export
`[[.aniframe` <- function(x, i, ...) {
  cls <- class(x)
  md <- get_metadata(x)
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  # Defensive: tibble's `[[` returns a vector for normal column extracts
  # and a list (or list element) for list-columns; it doesn't return a
  # data.frame in any path we've found. Kept in case a future tibble
  # release changes that.
  if (is.data.frame(x)) {
    # nocov start
    x <- preserve_animovement_class(x, cls, md)
  } # nocov end
  x
}

#' Extract column from aniframe with $
#'
#' @param x An aniframe object
#' @param name Column name
#' @return A vector
#' @keywords internal
#' @export
`$.aniframe` <- function(x, name) {
  class(x) <- setdiff(class(x), "aniframe")
  NextMethod()
}

# ---- Assignment methods ----

#' Subset assignment for aniframe with [<-
#'
#' @param x An aniframe object
#' @param i Row indices
#' @param j Column indices
#' @param ... Additional arguments
#' @param value Replacement values
#' @return Modified aniframe
#' @keywords internal
#' @export
`[<-.aniframe` <- function(x, i, j, ..., value) {
  cls <- class(x)
  md <- get_metadata(x)
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Column assignment for aniframe with [[<-
#'
#' @param x An aniframe object
#' @param i Column index or name
#' @param ... Additional arguments
#' @param value Replacement value
#' @return Modified aniframe
#' @keywords internal
#' @export
`[[<-.aniframe` <- function(x, i, ..., value) {
  cls <- class(x)
  md <- get_metadata(x)
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Column assignment for aniframe with $<-
#'
#' @param x An aniframe object
#' @param name Column name
#' @param value Replacement value
#' @return Modified aniframe
#' @keywords internal
#' @export
`$<-.aniframe` <- function(x, name, value) {
  cls <- class(x)
  md <- get_metadata(x)
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

#' Rename columns with names<-
#'
#' @param x An aniframe object
#' @param value New column names
#' @return Modified aniframe
#' @keywords internal
#' @export
`names<-.aniframe` <- function(x, value) {
  cls <- class(x)
  md <- get_metadata(x)
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md)
}

# ---- Conversion methods ----

#' Convert aniframe to regular data frame
#'
#' @param x An aniframe object
#' @param ... Additional arguments
#' @return A regular data frame
#' @keywords internal
#' @export
as.data.frame.aniframe <- function(x, ...) {
  class(x) <- setdiff(class(x), "aniframe")
  NextMethod()
}
