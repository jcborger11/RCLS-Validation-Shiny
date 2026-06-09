source("R/snail_layout.R", local = TRUE)
source("R/snail_autofill.R", local = TRUE)

if (requireNamespace("testthat", quietly = TRUE)) {
  testthat::test_that("n=4 kernel corner links TL to BR", {
    mirrors <- snail_mirror_cells(4, 2, 2)
    testthat::expect_true(any(mirrors[, 1] == 2 & mirrors[, 2] == 2))
    testthat::expect_true(any(mirrors[, 1] == 3 & mirrors[, 2] == 3))
  })

  testthat::test_that("n=4 kernel side links TR to BL", {
    mirrors <- snail_mirror_cells(4, 2, 3)
    testthat::expect_true(any(mirrors[, 1] == 2 & mirrors[, 2] == 3))
    testthat::expect_true(any(mirrors[, 1] == 3 & mirrors[, 2] == 2))
  })

  testthat::test_that("n=6 outer frame corner assigns shell 6", {
    testthat::expect_equal(snail_assign_shell(1, 1, 6), 6L)
    testthat::expect_equal(snail_assign_shell(3, 3, 6), 2L)
    testthat::expect_equal(snail_assign_shell(2, 2, 6), 4L)
  })

  testthat::test_that("n=6 kernel index mirrors corner pair", {
    mirrors <- snail_mirror_cells(6, 3, 4)
    testthat::expect_equal(nrow(mirrors), 2L)
  })

  testthat::test_that("n=6 frame 4 side mirrors four cells", {
    mirrors <- snail_mirror_cells(6, 2, 3)
    testthat::expect_equal(nrow(mirrors), 4L)
  })

  testthat::test_that("n=5 kernel is center cell only", {
    center <- snail_center_cell(5)
    testthat::expect_equal(snail_assign_shell(center[1], center[2], 5), 1L)
    mirrors <- snail_mirror_cells(5, center[1], center[2])
    testthat::expect_equal(nrow(mirrors), 1L)
  })

  testthat::test_that("n=5 frame 3 side mirrors four cells", {
    testthat::expect_equal(snail_assign_shell(2, 3, 5), 3L)
    mirrors <- snail_mirror_cells(5, 2, 3)
    testthat::expect_equal(nrow(mirrors), 4L)
  })

  testthat::test_that("n=3 frame mirrors four perimeter cells", {
    mirrors <- snail_mirror_cells(3, 1, 2)
    testthat::expect_equal(nrow(mirrors), 4L)
  })
}
