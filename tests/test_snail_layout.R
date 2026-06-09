source("R/snail_layout.R", local = TRUE)

if (requireNamespace("testthat", quietly = TRUE)) {
  testthat::test_that("shell sizes for even n", {
    testthat::expect_equal(snail_shell_sizes(2), 2L)
    testthat::expect_equal(snail_shell_sizes(4), c(2L, 4L))
    testthat::expect_equal(snail_shell_sizes(6), c(2L, 4L, 6L))
    testthat::expect_equal(snail_shell_sizes(8), c(2L, 4L, 6L, 8L))
    testthat::expect_equal(snail_shell_sizes(10), c(2L, 4L, 6L, 8L, 10L))
  })

  testthat::test_that("shell sizes for odd n", {
    testthat::expect_equal(snail_shell_sizes(3), c(1L, 3L))
    testthat::expect_equal(snail_shell_sizes(5), c(1L, 3L, 5L))
    testthat::expect_equal(snail_shell_sizes(7), c(1L, 3L, 5L, 7L))
    testthat::expect_equal(snail_shell_sizes(11), c(1L, 3L, 5L, 7L, 9L, 11L))
  })

  testthat::test_that("snail grids use per-cell borders for odd and even n", {
    testthat::expect_false(snail_uses_outer_wrapper_border(5))
    testthat::expect_false(snail_uses_outer_wrapper_border(6))
  })

  testthat::test_that("2x2 kernel has innermost shell borders for n=6", {
    kernel <- snail_cell_border_classes(3, 3, 6)
    testthat::expect_true(grepl("snail-shell-top", kernel))
    testthat::expect_true(grepl("snail-shell-left", kernel))
  })

  testthat::test_that("1x1 kernel has shell borders for n=5", {
    center <- snail_center_cell(5)
    kernel <- snail_cell_border_classes(center[1], center[2], 5)
    testthat::expect_true(grepl("snail-shell-top", kernel))
    testthat::expect_true(grepl("snail-shell-bottom", kernel))
  })

  testthat::test_that("frame 3 borders for n=5", {
    classes <- snail_cell_border_classes(2, 2, 5)
    testthat::expect_true(grepl("snail-shell-top", classes))
    testthat::expect_true(grepl("snail-shell-left", classes))
  })

  testthat::test_that("outer shell borders for n=6 corner cell", {
    classes <- snail_cell_border_classes(1, 1, 6)
    testthat::expect_true(grepl("snail-shell-top", classes))
    testthat::expect_true(grepl("snail-shell-left", classes))
  })
}
