# Record the first declared rate as the device's

Fills `source_sampling_rate` when `sampling_rate` is declared on a frame
that has neither yet, unless the call sets `source_sampling_rate`
itself. `NaN` declares that the device has no fixed rate, and is left
alone.

## Usage

``` r
fill_source_sampling_rate(old_md, new_md, user_md)
```

## Arguments

- old_md:

  The metadata before the write.

- new_md:

  The metadata about to be written.

- user_md:

  The fields the caller supplied.

## Value

`new_md`.
