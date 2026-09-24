# Turn an axis over on a frame that stores angles

`x` reflects `phi` about the vertical, `y` about the horizontal, `z`
reflects `theta` about the equator; anything else leaves the data alone.

## Usage

``` r
reflect_angular_axis(data, role)
```

## Arguments

- data:

  An anipoint object.

- role:

  An axis role.

## Value

`data`, with the angles it stores measured the other way.
