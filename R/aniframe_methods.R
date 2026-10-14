# Each method captures the class vector before dispatch and restores it, so
# downstream subclasses survive a pipeline (#81). A result missing a key,
# the index or an interval bound comes back as a plain data frame instead,
# and renaming carries the new names into the metadata (#178). Each passes
# the frame it was given, so the sampling interval is measured again when
# the rows or the index change (#190); the verbs that only rename or move
# columns pass their result, as they change no values.

#' The metadata for a verb's result
#'
#' `rename()` and `select()` rename through `names<-`, whose method has
#' already carried the new names into the result's metadata; take it from
#' there rather than restoring the stale copy captured before dispatch.
#'
#' @param x The result returned by `NextMethod()`.
#' @param md Metadata captured before dispatch.
#'
#' @return Metadata list.
#' @keywords internal
renamed_metadata <- function(x, md) {
  if (inherits(x, "aniframe")) get_metadata(x) else md
}

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
  before <- x
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md, before)
}

#' Group an aniframe
#'
#' A frame grouped by its keys, one trajectory per group, stays grouped by
#' them: the levels asked for are added after the keys rather than replacing
#' them, so a group is one trajectory or one stretch of it (#208). To group by
#' something else instead, [dplyr::ungroup()] first.
#'
#' @param .data An aniframe object
#' @param ... Variables to group by
#' @return A grouped aniframe
#' @keywords internal
#' @export
group_by.aniframe <- function(.data, ...) {
  cls <- class(.data)
  md <- get_metadata(.data)
  keys <- intersect(c(md_what_keys(md), md_when_keys(md)), names(.data))
  # Only a frame still grouped by every key keeps them; once a user has
  # ungrouped, their grouping is taken as asked.
  keep_keys <- length(keys) > 0 && all(keys %in% dplyr::group_vars(.data))
  before <- .data
  # dplyr ungroups the frame to compute grouping columns, which would warn as
  # if the user had.
  .data <- strip_animovement_class(.data)
  x <- NextMethod()
  asked <- dplyr::group_vars(x)
  if (keep_keys && !all(keys %in% asked)) {
    x <- dplyr::group_by(
      x,
      dplyr::across(dplyr::all_of(c(keys, setdiff(asked, keys)))),
      .drop = dplyr::group_by_drop_default(x)
    )
    if (length(setdiff(asked, keys)) > 0) {
      cli::cli_inform(
        c(
          "{.fn group_by} keeps the keys of an {cls[[1]]}, {.val {keys}}, and adds {.val {setdiff(asked, keys)}} after them.",
          "i" = "To group by other levels only, {.fn ungroup} first."
        ),
        .frequency = "once",
        .frequency_id = "anicore_group_by_keys"
      )
    }
  }
  preserve_animovement_class(x, cls, md, before)
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
  preserve_animovement_class(x, cls, md, .data)
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
  preserve_animovement_class(x, cls, renamed_metadata(x, md), before = x)
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
  preserve_animovement_class(x, cls, md, .data)
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
  preserve_animovement_class(x, cls, md, .data)
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
  preserve_animovement_class(x, cls, renamed_metadata(x, md), before = x)
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
  x <- NextMethod()
  preserve_animovement_class(x, cls, renamed_metadata(x, md), before = x)
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
  preserve_animovement_class(x, cls, md, .data)
}

# ---- dplyr's extension points ----
# Most verbs without a method of their own end in `dplyr_reconstruct()`, and
# those that drop rows go through `dplyr_row_slice()` first. Without these
# methods a grouped frame came back as a plain `grouped_df` and an ungrouped
# one kept its class and metadata unchecked (#199).

#' Rebuild an aniframe after a dplyr verb
#'
#' @param data The verb's result.
#' @param template The frame the verb was given.
#' @return An aniframe, or a plain data frame when a key, the index or an
#'   interval bound is gone.
#' @keywords internal
#' @export
dplyr_reconstruct.aniframe <- function(data, template) {
  cls <- class(template)
  md <- get_metadata(template)
  data <- NextMethod()
  preserve_animovement_class(data, cls, md, template)
}

#' Take rows of an aniframe
#'
#' @param data An aniframe.
#' @param i Row positions or a logical vector.
#' @param ... Passed on.
#' @return An aniframe.
#' @keywords internal
#' @export
dplyr_row_slice.aniframe <- function(data, i, ...) {
  cls <- class(data)
  md <- get_metadata(data)
  before <- data
  out <- NextMethod()
  preserve_animovement_class(out, cls, md, before)
}

#' Apply a function to each group of an aniframe
#'
#' @param .data An aniframe.
#' @param .f,...,.keep Passed to [dplyr::group_modify()].
#' @return An aniframe, or a plain data frame when `.f` drops a key, the
#'   index or an interval bound.
#' @keywords internal
#' @export
group_modify.aniframe <- function(.data, .f, ..., .keep = FALSE) {
  cls <- class(.data)
  md <- get_metadata(.data)
  before <- .data
  # dplyr ungroups the frame on the way, which would warn as if the user had.
  .data <- strip_animovement_class(.data)
  out <- NextMethod()
  preserve_animovement_class(out, cls, md, before)
}

#' Drop rows of an aniframe with missing values
#'
#' @param data An aniframe.
#' @param ... Columns to look in, passed to [tidyr::drop_na()].
#' @return An aniframe.
#' @keywords internal
#' @exportS3Method tidyr::drop_na
drop_na.aniframe <- function(data, ...) {
  cls <- class(data)
  md <- get_metadata(data)
  before <- data
  out <- NextMethod()
  preserve_animovement_class(out, cls, md, before)
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
  before <- x
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md, before)
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
  # Defensive: tibble's `[[` does not currently return a data frame.
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
  before <- x
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md, before)
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
  before <- x
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md, before)
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
  before <- x
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  preserve_animovement_class(x, cls, md, before)
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
  from <- names(x)
  class(x) <- setdiff(class(x), "aniframe")
  x <- NextMethod()
  md <- rename_metadata_columns(md, from, names(x))
  # Renaming moves no values, so the interval stands.
  preserve_animovement_class(x, cls, md, before = x)
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
