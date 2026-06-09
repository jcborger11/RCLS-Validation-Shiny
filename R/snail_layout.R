# Concentric snail shell geometry (1-based row/column indices).
#
# Even n: 2x2 kernel, shells 2, 4, 6, ..., n
# Odd n:  1x1 kernel (center cell), shells 1, 3, 5, ..., n

snail_min_shell_size <- function(n) {
  if (n %% 2L == 0L) {
    2L
  } else {
    1L
  }
}

snail_shell_sizes <- function(n) {
  min_size <- snail_min_shell_size(n)
  if (n < min_size) {
    return(integer(0))
  }
  seq(min_size, n, by = 2L)
}

snail_shell_bounds <- function(n, shell_size) {
  start <- (n - shell_size) %/% 2L + 1L
  list(
    row_start = start,
    row_end = start + shell_size - 1L,
    col_start = start,
    col_end = start + shell_size - 1L
  )
}

snail_cell_border_sides <- function(i, j, n) {
  sides <- character(0)
  for (shell_size in snail_shell_sizes(n)) {
    b <- snail_shell_bounds(n, shell_size)
    if (i == b$row_start && j >= b$col_start && j <= b$col_end) {
      sides <- c(sides, "top")
    }
    if (i == b$row_end && j >= b$col_start && j <= b$col_end) {
      sides <- c(sides, "bottom")
    }
    if (j == b$col_start && i >= b$row_start && i <= b$row_end) {
      sides <- c(sides, "left")
    }
    if (j == b$col_end && i >= b$row_start && i <= b$row_end) {
      sides <- c(sides, "right")
    }
  }
  unique(sides)
}

snail_cell_border_classes <- function(i, j, n) {
  sides <- snail_cell_border_sides(i, j, n)
  if (length(sides) == 0L) {
    return("")
  }
  paste0("snail-shell-", sides, collapse = " ")
}

# Per-cell shell borders for all snail grids (even and odd).
snail_uses_outer_wrapper_border <- function(n) {
  FALSE
}

snail_is_kernel_shell <- function(n, shell_size) {
  shell_size == snail_min_shell_size(n)
}
