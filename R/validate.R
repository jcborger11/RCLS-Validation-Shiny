# Validation logic for partial and complete RCLS grids.
# mat: n x n matrix of integers or NA (blank cells).

IMPOSSIBLE_ORDERS <- c(3L, 5L, 7L, 11L)

parse_cell <- function(raw) {
  if (is.null(raw) || length(raw) == 0) {
    return(NA_integer_)
  }
  text <- trimws(as.character(raw))
  if (text == "") {
    return(NA_integer_)
  }
  if (!grepl("^[0-9]+$", text)) {
    return(structure(NA_integer_, invalid = TRUE, raw = text))
  }
  value <- suppressWarnings(as.integer(text))
  if (is.na(value)) {
    return(structure(NA_integer_, invalid = TRUE, raw = text))
  }
  value
}

matrix_from_inputs <- function(input, n) {
  mat <- matrix(NA_integer_, nrow = n, ncol = n)
  invalid_cells <- list()

  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      id <- paste0("cell_", i, "_", j)
      parsed <- parse_cell(input[[id]])
      if (!is.na(parsed)) {
        mat[i, j] <- parsed
      } else if (isTRUE(attr(parsed, "invalid"))) {
        invalid_cells[[length(invalid_cells) + 1L]] <- list(
          i = i,
          j = j,
          raw = attr(parsed, "raw")
        )
      }
    }
  }

  list(matrix = mat, invalid_cells = invalid_cells)
}

validate_partial_rcls <- function(mat, n, snail_mode = FALSE) {
  violations <- character()
  info <- character()

  if (n < 1) {
    return(list(
      ok = FALSE,
      violations = "Order n must be at least 1.",
      info = info,
      full_rcls = NA,
      complete = FALSE
    ))
  }

  if (!is.matrix(mat) || nrow(mat) != n || ncol(mat) != n) {
    return(list(
      ok = FALSE,
      violations = sprintf("Internal error: expected a %d x %d matrix.", n, n),
      info = info,
      full_rcls = NA,
      complete = FALSE
    ))
  }

  # A1: valid symbols
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      value <- mat[i, j]
      if (!is.na(value)) {
        if (value < 1L || value > n) {
          violations <- c(
            violations,
            sprintf(
              "A1 Valid symbol: cell (%d, %d) contains %d; entries must be blank or in {1, ..., %d}.",
              i, j, value, n
            )
          )
        }
      }
    }
  }

  # A2: row duplicates among filled cells
  for (i in seq_len(n)) {
    filled <- mat[i, !is.na(mat[i, ])]
    if (length(filled) > 0) {
      dupes <- unique(filled[duplicated(filled)])
      for (d in dupes) {
        cols <- which(!is.na(mat[i, ]) & mat[i, ] == d)
        violations <- c(
          violations,
          sprintf(
            "A2 Row Latin: symbol %d appears more than once in row %d (columns %s).",
            d, i, paste(cols, collapse = ", ")
          )
        )
      }
    }
  }

  # A3: column duplicates among filled cells
  for (j in seq_len(n)) {
    filled <- mat[!is.na(mat[, j]), j]
    if (length(filled) > 0) {
      dupes <- unique(filled[duplicated(filled)])
      for (d in dupes) {
        rows <- which(!is.na(mat[, j]) & mat[, j] == d)
        violations <- c(
          violations,
          sprintf(
            "A3 Column Latin: symbol %d appears more than once in column %d (rows %s).",
            d, j, paste(rows, collapse = ", ")
          )
        )
      }
    }
  }

  # A4: duplicate horizontal ordered pairs (x -> y), x != y
  pair_locations <- list()
  for (i in seq_len(n)) {
    for (j in seq_len(n - 1L)) {
      x <- mat[i, j]
      y <- mat[i, j + 1L]
      if (is.na(x) || is.na(y) || x == y) {
        next
      }
      key <- paste(x, y, sep = "->")
      loc <- sprintf("row %d, cols %d-%d", i, j, j + 1L)
      if (key %in% names(pair_locations)) {
        violations <- c(
          violations,
          sprintf(
            "A4 Row-complete: ordered pair (%d -> %d) appears more than once (%s and %s).",
            x, y, pair_locations[[key]], loc
          )
        )
      } else {
        pair_locations[[key]] <- loc
      }
    }
  }

  complete <- all(!is.na(mat))

  # B1: completed rows must be permutations
  for (i in seq_len(n)) {
    row_vals <- mat[i, ]
    if (all(!is.na(row_vals))) {
      if (!setequal(row_vals, seq_len(n))) {
        violations <- c(
          violations,
          sprintf(
            "B1 Completed row: row %d is full but is not a permutation of 1, ..., %d.",
            i, n
          )
        )
      }
    }
  }

  # B2: completed columns must be permutations
  for (j in seq_len(n)) {
    col_vals <- mat[, j]
    if (all(!is.na(col_vals))) {
      if (!setequal(col_vals, seq_len(n))) {
        violations <- c(
          violations,
          sprintf(
            "B2 Completed column: column %d is full but is not a permutation of 1, ..., %d.",
            j, n
          )
        )
      }
    }
  }

  # C1: impossible orders (informational)
  if (n %in% IMPOSSIBLE_ORDERS) {
    info <- c(
      info,
      sprintf(
        "C1: No RCLS of order %d exists (proved). You can still explore, but a complete valid square is impossible.",
        n
      )
    )
  }

  # D1: odd-order snail impossible (informational, snail mode only)
  if (isTRUE(snail_mode) && n %% 2L == 1L) {
    info <- c(
      info,
      "D1: No odd-order snail exists (Dr. Groves Conjecture). You can still explore, but a complete odd-order snail is impossible."
    )
  }

  ok <- length(violations) == 0L
  full_rcls <- NA

  if (complete && ok) {
    pairs <- list()
    for (i in seq_len(n)) {
      for (j in seq_len(n - 1L)) {
        x <- mat[i, j]
        y <- mat[i, j + 1L]
        pairs[[length(pairs) + 1L]] <- c(x, y)
      }
    }
    pair_matrix <- do.call(rbind, pairs)
    distinct_count <- nrow(unique(pair_matrix))
    expected <- n * (n - 1L)
    full_rcls <- distinct_count == expected

    info <- c(
      info,
      sprintf(
        "C2: Grid complete and passes v1 checks. Full RCLS confirmed: %s.",
        if (isTRUE(full_rcls)) "yes" else "no"
      )
    )
  } else if (ok) {
    filled <- sum(!is.na(mat))
    info <- c(
      info,
      sprintf(
        "Incomplete but OK so far (%d of %d cells filled). Missing ordered pairs are not violations until the grid is finished.",
        filled, n * n
      )
    )
  }

  list(
    ok = ok,
    violations = violations,
    info = info,
    full_rcls = full_rcls,
    complete = complete
  )
}

validate_from_inputs <- function(input, n, snail_mode = FALSE, invalid_cells = list()) {
  parsed <- matrix_from_inputs(input, n)
  result <- validate_partial_rcls(parsed$matrix, n, snail_mode = snail_mode)

  for (cell in parsed$invalid_cells) {
    result$violations <- c(
      sprintf(
        "A1 Valid symbol: cell (%d, %d) contains %s; entries must be blank or an integer in {1, ..., %d}.",
        cell$i, cell$j, cell$raw, n
      ),
      result$violations
    )
  }

  for (cell in invalid_cells) {
    result$violations <- c(
      sprintf(
        "A1 Valid symbol: cell (%d, %d) contains %s; entries must be blank or an integer in {1, ..., %d}.",
        cell$i, cell$j, cell$raw, n
      ),
      result$violations
    )
  }

  result$ok <- length(result$violations) == 0L
  result
}

# Williams RCLS(6) in 1..6 notation (even order reference square).
williams_rcls_6 <- function() {
  base <- c(1L, 2L, 6L, 3L, 5L, 4L)
  mat <- matrix(0L, nrow = 6, ncol = 6)
  for (i in seq_len(6)) {
    mat[i, ] <- ((base + i - 2L) %% 6L) + 1L
  }
  mat
}
