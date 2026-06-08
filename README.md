# RCLS Interactive Validator

Shiny app for interactively building an n x n grid and checking whether the current partial square violates any **v1** necessary conditions for a row-complete Latin square (RCLS).

## Requirements

- R (4.1+ recommended)
- Packages: `shiny` (required), `testthat` (optional, for tests)

Install Shiny:

```r
install.packages("shiny")
```

Optional tests:

```r
install.packages("testthat")
```

## Run locally

From R, with working directory set to this folder:

```r
shiny::runApp("/Users/johnb/Documents/Cursor Files/Latin Squares/rcls-shiny")
```

Or from terminal:

```bash
cd "/Users/johnb/Documents/Cursor Files/Latin Squares/rcls-shiny" && Rscript -e 'shiny::runApp(".")'
```

## Run tests

```bash
cd "/Users/johnb/Documents/Cursor Files/Latin Squares/rcls-shiny" && Rscript tests/testthat.R
```

## v1 checks

| Tier | Check |
|------|--------|
| A1 | Valid symbol (blank or integer in 1..n) |
| A2 | No duplicate in any row |
| A3 | No duplicate in any column |
| A4 | No duplicate horizontal ordered pair (x -> y), x != y |
| B1 | Full row must be a permutation of 1..n |
| B2 | Full column must be a permutation of 1..n |
| C1 | Info banner for impossible orders 3, 5, 7, 11 |
| C2 | Full RCLS confirmation when grid is complete |

Background turns light red when any A/B check fails. Footer shows the first violation (+ count of others).

## Deploy to shinyapps.io

1. Create an account at [shinyapps.io](https://www.shinyapps.io/).
2. Install and configure rsconnect:

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name = "YOUR_ACCOUNT", token = "YOUR_TOKEN", secret = "YOUR_SECRET")
```

3. Deploy:

```r
rsconnect::deployApp("/Users/johnb/Documents/Cursor Files/Latin Squares/rcls-shiny", appName = "rcls-validator")
```

For reproducible deploys, initialize `renv` in this folder before deploying:

```r
install.packages("renv")
renv::init()
renv::snapshot()
```

## Reference

See [RCLS_Reference.md](../RCLS_Reference.md) in the parent folder for definitions and literature notes.
