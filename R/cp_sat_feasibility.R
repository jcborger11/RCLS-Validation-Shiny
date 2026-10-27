# CP-SAT completion feasibility via scripts/cp_sat_feasibility.py (OR-Tools).

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) {
    return(y)
  }
  if (is.atomic(x) && length(x) == 1L && is.na(x)) {
    return(y)
  }
  x
}

grid_chars_to_matrix <- function(grid_chr, n) {
  mat <- matrix(NA_integer_, nrow = n, ncol = n)
  invalid <- FALSE
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      parsed <- parse_cell(grid_chr[i, j])
      if (isTRUE(attr(parsed, "invalid"))) {
        invalid <- TRUE
      } else if (!is.na(parsed)) {
        mat[i, j] <- parsed
      }
    }
  }
  list(matrix = mat, invalid = invalid)
}

cp_sat_script_path <- function() {
  file.path(getwd(), "scripts", "cp_sat_feasibility.py")
}

cp_sat_python_bin <- function() {
  python <- Sys.which("python3")
  if (nzchar(python)) {
    return(python)
  }
  Sys.which("python")
}

#' Encode integer matrix (NA = blank) as JSON array for the Python solver.
matrix_to_json_array <- function(mat) {
  rows <- apply(mat, 1, function(row) {
    cells <- vapply(
      row,
      function(v) {
        if (is.na(v)) {
          "null"
        } else {
          as.character(as.integer(v))
        }
      },
      character(1)
    )
    paste0("[", paste(cells, collapse = ","), "]")
  })
  paste0("[", paste(rows, collapse = ","), "]")
}

#' @return list(status, wall_ms, reason, message)
check_completion_feasible <- function(
    mat,
    n,
    snail_mode = FALSE,
    timeout_sec = 2
) {
  status_unavailable <- function(reason) {
    list(
      status = "UNAVAILABLE",
      wall_ms = NA_integer_,
      reason = reason,
      message = paste0(
        "E0: Completability check unavailable (",
        reason,
        "). Install Python 3 and ortools; see README."
      )
    )
  }

  script <- cp_sat_script_path()
  if (!file.exists(script)) {
    return(status_unavailable("script_missing"))
  }

  python <- cp_sat_python_bin()
  if (!nzchar(python)) {
    return(status_unavailable("python_missing"))
  }

  if (!is.matrix(mat) || nrow(mat) != n || ncol(mat) != n) {
    return(list(
      status = "SKIP",
      wall_ms = NA_integer_,
      reason = "bad_matrix",
      message = NULL
    ))
  }

  payload <- paste0(
    '{"n":', as.integer(n),
    ',"snail":', if (isTRUE(snail_mode)) "true" else "false",
    ',"timeout_sec":', as.numeric(timeout_sec),
    ',"matrix":', matrix_to_json_array(mat),
    "}"
  )

  t0 <- Sys.time()
  out <- tryCatch(
    system2(
      python,
      args = shQuote(normalizePath(script, winslash = "/")),
      input = payload,
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(e) NULL
  )
  wall_ms <- as.integer(as.numeric(difftime(Sys.time(), t0, units = "secs")) * 1000)

  if (is.null(out) || length(out) == 0L) {
    return(status_unavailable("solver_failed"))
  }

  line <- out[length(out)]
  st <- sub('.*"status"[[:space:]]*:[[:space:]]*"([^"]+)".*', "\\1", line)
  if (!nzchar(st) || identical(st, line)) {
    return(status_unavailable("bad_solver_output"))
  }

  ms_match <- regmatches(
    line,
    regexpr('"wall_ms"[[:space:]]*:[[:space:]]*([0-9]+)', line)
  )
  ms <- if (length(ms_match) > 0L) {
    as.integer(sub('.*:', "", ms_match))
  } else {
    wall_ms
  }

  reason <- NA_character_
  reason_match <- regmatches(
    line,
    regexpr('"reason"[[:space:]]*:[[:space:]]*"([^"]*)"', line)
  )
  if (length(reason_match) > 0L) {
    reason <- sub('.*"reason"[[:space:]]*:[[:space:]]*"([^"]*)".*', "\\1", line)
  }

  snail_note <- if (isTRUE(snail_mode)) " (+ snail symmetry)" else ""
  message <- switch(
    st,
    INFEASIBLE = paste0(
      "E1: No full RCLS completion exists",
      snail_note,
      " for this partial grid (CP-SAT). Background pink."
    ),
    UNKNOWN = "E2: Completability check timed out or was inconclusive — not marked impossible.",
    UNAVAILABLE = status_unavailable(if (nzchar(reason)) reason else "unknown")$message,
    FEASIBLE = NULL,
    SKIP = NULL,
    NULL
  )

  list(
    status = st,
    wall_ms = ms,
    reason = reason,
    message = message
  )
}
