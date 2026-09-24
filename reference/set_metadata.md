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
```
