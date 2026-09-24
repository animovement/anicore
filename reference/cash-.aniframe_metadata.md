# Flat resolution for `$` and `[[` on the classed metadata object

Fields resolve through the category tree (#155); a category name returns
the whole category.

## Usage

``` r
# S3 method for class 'aniframe_metadata'
x$name

# S3 method for class 'aniframe_metadata'
x[[i, ...]]

# S3 method for class 'aniframe_metadata'
x$name <- value

# S3 method for class 'aniframe_metadata'
x[[i, ...]] <- value
```

## Arguments

- x:

  An `aniframe_metadata` object.

- name, i:

  The entry to read.

- value:

  The value to write.

## Value

The entry's value, or `NULL`.
