source("R/snail_layout.R", local = TRUE)
source("R/snail_autofill.R", local = TRUE)

if (requireNamespace("testthat", quietly = TRUE)) {
  testthat::test_that("n=6 upper V cells match expected path", {
    cells <- snail_upper_v_cells(6)
    testthat::expect_equal(
      cells,
      matrix(
        c(
          1, 1, 1,
          2, 2, 2,
          3, 3, 3,
          3, 4, 4,
          2, 5, 5,
          1, 6, 6
        ),
        ncol = 3,
        byrow = TRUE,
        dimnames = list(NULL, c("row", "col", "value"))
      )
    )
  })

  testthat::test_that("n=10 upper V cells match expected path", {
    cells <- snail_upper_v_cells(10)
    expected_rows <- c(1:5, 5:1)
    expected_cols <- 1:10
    expected_values <- 1:10
    testthat::expect_equal(cells[, 1], expected_rows)
    testthat::expect_equal(cells[, 2], expected_cols)
    testthat::expect_equal(cells[, 3], expected_values)
  })

  testthat::test_that("ineligible n returns empty matrix", {
    testthat::expect_equal(nrow(snail_upper_v_cells(4)), 0L)
    testthat::expect_equal(nrow(snail_upper_v_cells(8)), 0L)
    testthat::expect_equal(nrow(snail_upper_v_fill_cells(4)), 0L)
    testthat::expect_equal(nrow(snail_upper_v_fill_cells(8)), 0L)
  })

  testthat::test_that("n=6 upper V fill propagates through snail mirrors", {
    fills <- snail_upper_v_fill_cells(6)
    testthat::expect_equal(nrow(fills), 12L)

    mat <- matrix("", 6, 6)
    for (k in seq_len(nrow(fills))) {
      mat[fills[k, 1], fills[k, 2]] <- as.character(fills[k, 3])
    }
    expected <- matrix(
      c(
        "1", "", "", "", "", "6",
        "", "2", "", "", "5", "",
        "", "", "3", "4", "", "",
        "", "", "4", "3", "", "",
        "", "5", "", "", "2", "",
        "6", "", "", "", "", "1"
      ),
      nrow = 6,
      byrow = TRUE
    )
    testthat::expect_equal(mat, expected)
  })

  testthat::test_that("n=10 upper V fill propagates through snail mirrors", {
    fills <- snail_upper_v_fill_cells(10)
    testthat::expect_equal(nrow(fills), 20L)
    testthat::expect_equal(
      sort(fills[fills[, 3] == 5, 1]),
      c(5L, 6L)
    )
    testthat::expect_equal(
      sort(fills[fills[, 3] == 5, 2]),
      c(5L, 6L)
    )
  })
}
