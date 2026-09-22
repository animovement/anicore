# Force metadata fields directly onto an object, bypassing every setter.
#
# The structural fields have dedicated setters that restructure the frame
# to match (#82), and `set_metadata()` refuses them, so a frame whose
# metadata disagrees with its columns can no longer be built through the
# public API. Tests that need such a frame — to check that
# `validate_anipoint()` reports the divergence, or that a helper
# early-returns on it — build it here instead.
#
# Fields are addressed by their old flat names and written into the
# category tree; the variables fields drift the matching slot.
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
