# Get the direction each axis points

Get the direction each axis points

## Usage

``` r
get_axis_directions(data)
```

## Arguments

- data:

  An aniframe or anievent object.

## Value

Named character vector, axis role to direction. Empty when the frame
declares none.

## See also

[`set_axis_directions()`](https://animovement.dev/anicore/reference/set_axis_directions.md),
[`reflect_axis()`](https://animovement.dev/anicore/reference/reflect_axis.md)

## Examples

``` r
af <- example_anipoint(n_obs = 3, n_individuals = 1, n_keypoints = 1)
af <- set_axis_directions(af, c(x = "right", y = "up"))
get_axis_directions(af)
#>       x       y 
#> "right"    "up" 
```
