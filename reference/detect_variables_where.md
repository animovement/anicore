# Detect spatial variables from data

Polar-family runs first so cylindrical data isn't taken as Cartesian
because of its `z` column.

## Usage

``` r
detect_variables_where(data)
```

## Arguments

- data:

  Data frame to check.

## Value

Character vector of detected spatial variable names, or NULL if none
found.
