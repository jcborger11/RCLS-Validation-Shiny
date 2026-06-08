# Smoke tests for validate.R — run from rcls-shiny directory:
#   Rscript tests/smoke_test.R

source("R/validate.R", local = TRUE)

cat("1. Blank 6x6 grid -> ok, not complete\n")
r <- validate_partial_rcls(matrix(NA_integer_, 6, 6), 6)
stopifnot(r$ok, !r$complete, is.na(r$full_rcls))

cat("2. Duplicate in row -> A2 violation\n")
m <- matrix(NA_integer_, 4, 4)
m[1, 1:2] <- c(1L, 1L)
r <- validate_partial_rcls(m, 4)
stopifnot(!r$ok, grepl("A2 Row Latin", r$violations[1]))

cat("3. Duplicate ordered pair across rows -> A4 violation\n")
m <- matrix(NA_integer_, 4, 4)
m[1, 1:2] <- c(1L, 2L)
m[2, 3:4] <- c(1L, 2L)  # cols 3-4 avoids column duplicates (A3) masking A4
r <- validate_partial_rcls(m, 4)
stopifnot(!r$ok, grepl("A4 Row-complete", r$violations[1]))

cat("4. Williams 6x6 -> full RCLS confirmed\n")
r <- validate_partial_rcls(williams_rcls_6(), 6)
stopifnot(r$ok, r$complete, isTRUE(r$full_rcls))

cat("All smoke tests passed.\n")
