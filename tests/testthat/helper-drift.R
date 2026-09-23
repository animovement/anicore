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
