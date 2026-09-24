# The angle between two vectors

Row-wise angle between direction vectors, as used for joint angles.

- With no `axis`, the included angle `acos(u . v / |u||v|)`, in
  `[0, pi]`.

- With an `axis`, both vectors are projected onto the plane
  perpendicular to it, and the angle turns from `u` to `v` about the
  axis by the right-hand rule, in `[-pi, pi]`. For 2D vectors,
  `c(0, 0, 1)` gives the signed angle from `x` toward `y`.

Vectors need not be unit length. A zero vector, or one parallel to the
axis, gives `NA`.

## Usage

``` r
angle_between(u, v, axis = NULL)
```

## Arguments

- u, v:

  Numeric vectors of length 2 or 3, or matrices or data frames with 2 or
  3 columns and one row per vector. A single vector is recycled.

- axis:

  `NULL`, or a vector (or one per row) of length 3.

## Value

Numeric vector of angles in radians.

## Examples

``` r
angle_between(c(1, 0), c(0, 1))
#> [1] 1.570796
angle_between(c(1, 0), c(0, 1), axis = c(0, 0, 1))
#> [1] 1.570796
angle_between(c(1, 0), c(0, 1), axis = c(0, 0, -1))
#> [1] -1.570796

# One angle per row
angle_between(rbind(c(1, 0, 0), c(0, 1, 0)), c(0, 0, 1))
#> [1] 1.570796 1.570796
```
