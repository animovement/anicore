# Warn when an axis role is carried by one column while another has its name

E.g. role `x` is column `"u"` but a column `x` also exists (#119).

## Usage

``` r
warn_shadowed_axis_roles(axes, columns)
```

## Arguments

- axes:

  A normalised role-to-column mapping.

- columns:

  The frame's column names.

## Value

`TRUE`, invisibly.
