# Set metadata

Sets or updates metadata for an aniframe or anievent object. Metadata
can be provided either as named arguments or as a list. If the object
already has metadata, the new values will be merged with existing
values, with new values taking precedence.

Fields are written by their own name wherever they live in the category
tree (see
[`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md)):
`set_metadata(data, sampling_rate = 30)` lands in `time`,
`set_metadata(data, handedness = "left")` in `space`. Categories
themselves are not writable, and the variable declaration goes through
its dedicated setters.

Character values for factor fields will be automatically converted to
factors if they match allowed levels.

## Usage

``` r
set_metadata(data, ..., metadata = NULL)
```

## Arguments

- data:

  An aniframe or anievent object.

- ...:

  Named metadata values (e.g., `sampling_rate = 30, source = "sleap"`)

- metadata:

  Alternatively, a named list of metadata. Cannot be used simultaneously
  with `...`

## Value

The object with updated metadata.

## The recorded and the current sampling rate

A frame keeps two rates apart. `source_sampling_rate`, with the other
provenance in `recording`, is the rate the device recorded at, and no
processing changes it. `sampling_rate`, in `time`, is the rate of the
data as it is now: the rate filters and conversions compute with, and
the one resampling changes.

The first declaration of a rate fills both. Setting `sampling_rate` on a
frame that has neither rate yet also sets `source_sampling_rate`, since
that is the moment the camera's rate is declared; this holds for
`as_anipoint(metadata = )` too. After that `sampling_rate` changes on
its own, so correcting a wrong camera rate means setting
`source_sampling_rate` as well, in the same call.

A device with no fixed rate, such as an event-driven sensor whose
readings a reader integrates into windows, is declared with
`source_sampling_rate = NaN`: "no fixed rate", as distinct from `NA`,
"not declared yet". The first declaration then leaves it alone, and
[`is.na()`](https://rdrr.io/r/base/NA.html) is still `TRUE` for code
that only asks whether there is a recorded rate to use.

## See also

[`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md),
[`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Set metadata using named arguments
data <- set_metadata(data, sampling_rate = 30, source = "sleap")

# Set metadata using a list
md <- list(sampling_rate = 30, source = "sleap")
data <- set_metadata(data, metadata = md)
} # }

# The first declared rate is also recorded as the device's
af <- set_metadata(example_anipoint(), sampling_rate = 200)
get_metadata(af, "source_sampling_rate")
#> [1] 200

# Later rates are the data's own, as after resampling
af <- set_metadata(af, sampling_rate = 50)
get_metadata(af, c("sampling_rate", "source_sampling_rate"))
#> $sampling_rate
#> [1] 50
#> 
#> $source_sampling_rate
#> [1] 200
#> 

# A sensor with no fixed rate
trackball <- example_anipoint() |>
  set_metadata(source_sampling_rate = NaN) |>
  set_metadata(sampling_rate = 100)
get_metadata(trackball, "source_sampling_rate")
#> [1] NaN
```
