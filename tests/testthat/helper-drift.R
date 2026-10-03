# Force metadata fields onto an object, bypassing every setter, to build a
# frame whose metadata disagrees with its columns (#82). Fields use their old
# flat names; the variables fields drift the matching slot.
drift_metadata <- function(data, ...) {
  fields <- list(...)
  md <- get_metadata(data)
  for (name in names(fields)) {
    value <- fields[[name]]
    md <- switch(
      name,
      variables_what = {
        md$variables$what$keys <- value
        md
      },
      variables_when = {
        md$variables$when$keys <- value
        md
      },
      variables_where = ,
      axes = {
        md$variables$where$position <- value
        md
      },
      variables_index = {
        md$variables$when$index <- value
        md
      },
      variables_event = {
        md$variables$event <- value
        md
      },
      md_field_set(md, name, value)
    )
  }
  attach_metadata(data, md)
}

# Drop a column while keeping the frame's class and metadata. The methods
# refuse to make a frame missing a key or its index (#178), so tests of what
# catches one build it by hand.
drop_column_unchecked <- function(data, col) {
  cls <- class(data)
  md <- get_metadata(data)
  bare <- dplyr::ungroup(strip_animovement_class(data))
  bare[[col]] <- NULL
  class(bare) <- c(setdiff(cls, list_base_frame_classes()), class(bare))
  attach_metadata(bare, md)
}
