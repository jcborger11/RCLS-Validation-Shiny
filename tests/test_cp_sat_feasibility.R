source("R/validate.R", local = TRUE)
source("R/cp_sat_feasibility.R", local = TRUE)

if (requireNamespace("testthat", quietly = TRUE)) {
  python_ok <- nzchar(Sys.which("python3")) || nzchar(Sys.which("python"))
  script_ok <- file.exists(file.path(getwd(), "scripts", "cp_sat_feasibility.py"))

  testthat::test_that("matrix_to_json_array encodes blanks", {
    mat <- matrix(c(1L, NA_integer_, 3L, 4L), nrow = 2)
    json <- matrix_to_json_array(mat)
    testthat::expect_match(json, "null")
    testthat::expect_match(json, "1")
  })

  if (python_ok && script_ok) {
    testthat::test_that("empty 6x6 grid is FEASIBLE", {
      mat <- matrix(NA_integer_, 6, 6)
      res <- check_completion_feasible(mat, 6, snail_mode = FALSE, timeout_sec = 3)
      testthat::expect_equal(res$status, "FEASIBLE")
    })

    testthat::test_that("diagonal upper-V partial is FEASIBLE with snail", {
      n <- 10L
      mat <- matrix(NA_integer_, n, n)
      diag <- c(1L, 2L, 3L, 4L, 5L, 5L, 4L, 3L, 2L, 1L)
      anti <- c(10L, 9L, 8L, 7L, 6L, 6L, 7L, 8L, 9L, 10L)
      for (i in seq_len(n)) {
        mat[i, i] <- diag[i]
        mat[i, n - i + 1L] <- anti[i]
      }
      res <- check_completion_feasible(mat, n, snail_mode = TRUE, timeout_sec = 5)
      testthat::expect_equal(res$status, "FEASIBLE")
    })
  }
}
