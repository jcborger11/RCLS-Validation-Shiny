source("R/validate.R", local = TRUE)

if (requireNamespace("testthat", quietly = TRUE)) {
  testthat::test_that("blank 6x6 grid has no violations", {
    mat <- matrix(NA_integer_, 6, 6)
    result <- validate_partial_rcls(mat, 6)
    testthat::expect_true(result$ok)
    testthat::expect_false(result$complete)
    testthat::expect_true(is.na(result$full_rcls))
  })

  testthat::test_that("duplicate in row is detected", {
    mat <- matrix(NA_integer_, 4, 4)
    mat[1, 1:2] <- c(1L, 1L)
    result <- validate_partial_rcls(mat, 4)
    testthat::expect_false(result$ok)
    testthat::expect_match(result$violations[1], "A2 Row Latin")
  })

  testthat::test_that("duplicate ordered pair across rows is detected", {
    mat <- matrix(NA_integer_, 4, 4)
    mat[1, 1:2] <- c(1L, 2L)
    mat[2, 3:4] <- c(1L, 2L)
    result <- validate_partial_rcls(mat, 4)
    testthat::expect_false(result$ok)
    testthat::expect_match(result$violations[1], "A4 Row-complete")
  })

  testthat::test_that("Williams 6x6 is a full RCLS", {
    mat <- williams_rcls_6()
    result <- validate_partial_rcls(mat, 6)
    testthat::expect_true(result$ok)
    testthat::expect_true(result$complete)
    testthat::expect_true(result$full_rcls)
  })

  testthat::test_that("invalid symbol is flagged", {
    mat <- matrix(NA_integer_, 3, 3)
    mat[1, 1] <- 9L
    result <- validate_partial_rcls(mat, 3)
    testthat::expect_false(result$ok)
    testthat::expect_match(result$violations[1], "A1 Valid symbol")
  })

  testthat::test_that("impossible order n=11 shows C1 info", {
    mat <- matrix(NA_integer_, 11, 11)
    result <- validate_partial_rcls(mat, 11)
    testthat::expect_true(result$ok)
    testthat::expect_match(result$info[1], "C1:")
  })
}
