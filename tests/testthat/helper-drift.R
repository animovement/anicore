# Force metadata fields directly onto an object, bypassing every setter.
#
# The structural fields have dedicated setters that restructure the frame
# to match (#82), and `set_metadata()` refuses them, so a frame whose
# metadata disagrees with its columns can no longer be built through the
# public API. Tests that need such a frame — to check that
# `validate_anipoint()` reports the divergence, or that a helper
# early-returns on it — build it here instead.
drift_metadata <- function(data, ...) {
  fields <- list(...)
  md <- get_metadata(data)
  md[names(fields)] <- fields
  attach_metadata(data, md)
}
