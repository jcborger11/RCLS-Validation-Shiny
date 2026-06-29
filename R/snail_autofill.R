# Snail method frame/kernel autofill geometry (1-based indices).
# Top permutation index j links four perimeter positions on a shell of size s.

snail_inside_bounds <- function(i, j, bounds) {
  i >= bounds$row_start &&
    i <= bounds$row_end &&
    j >= bounds$col_start &&
    j <= bounds$col_end
}

snail_on_perimeter <- function(i, j, bounds) {
  i == bounds$row_start ||
    i == bounds$row_end ||
    j == bounds$col_start ||
    j == bounds$col_end
}

# Smallest shell (kernel first, then frames outward) containing this perimeter cell.
snail_assign_shell <- function(i, j, n) {
  min_size <- snail_min_shell_size(n)

  for (shell_size in snail_shell_sizes(n)) {
    bounds <- snail_shell_bounds(n, shell_size)
    if (!snail_inside_bounds(i, j, bounds) || !snail_on_perimeter(i, j, bounds)) {
      next
    }
    if (shell_size > min_size) {
      inner <- snail_shell_bounds(n, shell_size - 2L)
      if (snail_inside_bounds(i, j, inner) && !snail_on_perimeter(i, j, inner)) {
        next
      }
    }
    return(shell_size)
  }

  NA_integer_
}

snail_top_index <- function(i, j, shell_size, bounds) {
  rs <- bounds$row_start
  re <- bounds$row_end
  cs <- bounds$col_start
  ce <- bounds$col_end
  s <- shell_size

  if (i == rs) {
    return(j - cs + 1L)
  }
  if (j == cs) {
    return(i - rs + 1L)
  }
  if (i == re) {
    return(s - (j - cs + 1L) + 1L)
  }
  if (j == ce) {
    return(s - (i - rs + 1L) + 1L)
  }

  NA_integer_
}

snail_linked_positions <- function(n, shell_size, top_index) {
  bounds <- snail_shell_bounds(n, shell_size)
  rs <- bounds$row_start
  re <- bounds$row_end
  cs <- bounds$col_start
  ce <- bounds$col_end
  j <- top_index

  positions <- matrix(
    c(
      rs, cs + j - 1L,
      rs + j - 1L, cs,
      re, ce - j + 1L,
      re - j + 1L, ce
    ),
    ncol = 2L,
    byrow = TRUE
  )

  positions[!duplicated(positions), , drop = FALSE]
}

snail_mirror_cells <- function(n, i, j) {
  shell_size <- snail_assign_shell(i, j, n)
  if (is.na(shell_size)) {
    return(matrix(nrow = 0, ncol = 2))
  }

  bounds <- snail_shell_bounds(n, shell_size)
  top_index <- snail_top_index(i, j, shell_size, bounds)
  if (is.na(top_index)) {
    return(matrix(nrow = 0, ncol = 2))
  }

  snail_linked_positions(n, shell_size, top_index)
}

snail_shell_label <- function(n, shell_size) {
  if (snail_is_kernel_shell(n, shell_size)) {
    "kernel"
  } else {
    sprintf("frame %d", shell_size)
  }
}

snail_center_cell <- function(n) {
  c((n + 1L) %/% 2L, (n + 1L) %/% 2L)
}

# Upper-V autofill positions for n ≡ 2 (mod 4): main diagonal then anti-diagonal (1-based).
snail_upper_v_cells <- function(n) {
  if (n %% 4L != 2L) {
    return(matrix(nrow = 0, ncol = 3))
  }

  half <- n %/% 2L
  rows <- c(seq_len(half), n - seq(half + 1L, n) + 1L)
  cols <- seq_len(n)
  cbind(row = rows, col = cols, value = seq_len(n))
}

# Upper-V seed path expanded through snail shell mirroring (1-based).
snail_upper_v_fill_cells <- function(n) {
  seeds <- snail_upper_v_cells(n)
  if (nrow(seeds) == 0L) {
    return(matrix(nrow = 0, ncol = 3))
  }

  filled <- matrix(NA_integer_, n, n)
  for (k in seq_len(nrow(seeds))) {
    r <- seeds[k, 1L]
    c <- seeds[k, 2L]
    v <- seeds[k, 3L]
    mirrors <- snail_mirror_cells(n, r, c)
    cells <- rbind(c(r, c), mirrors)
    for (m in seq_len(nrow(cells))) {
      ri <- cells[m, 1L]
      cj <- cells[m, 2L]
      existing <- filled[ri, cj]
      if (!is.na(existing) && existing != v) {
        stop(sprintf(
          "Upper-V mirror conflict at (%d,%d): %d vs %d",
          ri, cj, existing, v
        ))
      }
      filled[ri, cj] <- v
    }
  }

  idx <- which(!is.na(filled), arr.ind = TRUE)
  cbind(row = idx[, 1L], col = idx[, 2L], value = filled[idx])
}
