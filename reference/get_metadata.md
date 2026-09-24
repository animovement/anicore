# Get metadata

The metadata is stored as a category tree (see
[`list_default_metadata()`](https://animovement.dev/anicore/reference/list_default_metadata.md)),
but lookup stays flat: a field is found by its own name wherever it
lives, and a category name returns the whole category. The `variables`
category is the exception — its slots are reached through the
`*_variables_*()` accessors,
[`get_index()`](https://animovement.dev/anicore/reference/get_index.md)
and
[`get_axes()`](https://animovement.dev/anicore/reference/get_axes.md),
not by flat name.

## Usage

``` r
get_metadata(data, fields = NULL)
```

## Arguments

- data:

  An aniframe or anievent object.

- fields:

  Field or category names. A field the object does not carry gives
  `NULL` — an
  [`anievent()`](https://animovement.dev/anicore/reference/anievent.md)
  has no `space` category, so its spatial fields read as absent rather
  than as neutral values. A name that is not a metadata field at all is
  an error.

## Value

The metadata associated with the object.

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
names(get_metadata(af))
#> [1] "spec_version" "recording"    "time"         "space"        "variables"   
#> [6] "structure"   

# A single field can be pulled out by name, wherever it lives
get_metadata(af, 'sampling_rate')
#> [1] NA

# A category name returns the whole category
names(get_metadata(af, 'space'))
#> [1] "coordinate_system" "reference_frame"   "handedness"       
#> [4] "axis_directions"   "axis_extents"      "unit_space"       
#> [7] "unit_angle"        "euler_sequence"    "euler_intrinsic"  
```
