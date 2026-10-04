# Print the metadata of a frame

Prints the metadata of an
[`anipoint()`](https://animovement.dev/anicore/reference/anipoint.md) or
[`anievent()`](https://animovement.dev/anicore/reference/anievent.md)
one category at a time, one `name: value` line per field, wrapped to the
console width. Values carry their units where the metadata declares
them, such as `sampling_rate: 30 Hz`. Fields that are not set are left
out and named together on a closing line.

`all = TRUE` prints every field, including those not set, the values
each factor field allows, and `spec_version`.

## Usage

``` r
# S3 method for class 'aniframe_metadata'
print(x, all = FALSE, ...)
```

## Arguments

- x:

  An `aniframe_metadata` object, as returned by
  [`get_metadata()`](https://animovement.dev/anicore/reference/get_metadata.md).

- all:

  Whether to print every field (default `FALSE`): those not set, the
  allowed values of factor fields, and `spec_version`.

- ...:

  Unused.

## Value

`x`, invisibly.

## Examples

``` r
md <- get_metadata(set_metadata(example_anipoint(), sampling_rate = 30))
md
#> ── animovement metadata ────────────────────────────────────────────────────────
#> 
#> ── time 
#> unit_time: frame
#> sampling_rate: 30 Hz
#> sampling_interval: 1 frame
#> 
#> ── space 
#> coordinate_system: cartesian_2d
#> reference_frame: allocentric
#> handedness: unknown
#> unit_space: px
#> unit_angle: rad
#> 
#> ── variables 
#> what   keys: individual, keypoint
#> when   index: time | keys: session, trial
#> where  position: x = x, y = y
#> event  state: - | point: -
#> 
#> Not set: source, source_version, source_format, filename, start_datetime,
#>   axis_directions, axis_extents, euler_sequence, euler_intrinsic, structure
print(md, all = TRUE)
#> ── animovement metadata ────────────────────────────────────────────────────────
#> 
#> ── recording 
#> source: -
#> source_version: -
#> source_format: -
#> filename: -
#> 
#> ── time 
#> unit_time: frame
#>   levels: unknown, frame, ns, us, ms, s, m, h
#> sampling_rate: 30 Hz
#> sampling_interval: 1 frame
#> start_datetime: -
#> 
#> ── space 
#> coordinate_system: cartesian_2d
#>   levels: unknown, cartesian_1d, cartesian_2d, cartesian_3d, polar, cylindrical,
#>     spherical
#> reference_frame: allocentric
#>   levels: allocentric, egocentric, none
#> handedness: unknown
#>   levels: right, left, unknown
#> axis_directions: -
#> axis_extents: -
#> unit_space: px
#>   levels: px, none, nm, um, mm, cm, m, km
#> unit_angle: rad
#>   levels: rad, deg, none
#> euler_sequence: -
#> euler_intrinsic: -
#> 
#> ── variables 
#> what   keys: individual, keypoint
#> when   index: time | keys: session, trial
#> where  position: x = x, y = y
#> event  state: - | point: -
#> 
#> ── structure 
#> -
#> 
#> spec_version: aniframe 3.0.0, anievent 1.0.0
```
