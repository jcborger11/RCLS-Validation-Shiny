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

From R, with working directory set to this folder (repo root):

```r
shiny::runApp(".")
```

Or from terminal:

```bash
cd rcls-shiny && Rscript -e 'shiny::runApp(".")'
```

## Save grid

Click **Save grid** in the sidebar to download a PNG of what you see on screen (info banners, grid, and status footer). The browser captures the grid from the page and saves the file (usually to **Downloads**, or via a Save As dialog depending on browser settings). The server never writes to folders on your computer — the same pattern works locally and on [shinyapps.io](https://john-borger.shinyapps.io/rcls-validator/).

This is a DOM screenshot (via html2canvas), not a server redraw, so autofill and mirror values match the interactive grid exactly.

## Run tests

```bash
cd rcls-shiny && Rscript tests/testthat.R
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

## Completability check (optional, CP-SAT)

Sidebar toggle **Check completability (CP-SAT)?** (default **Off**). When **On**, the app debounces edits (~500 ms) and calls a small Python script (`scripts/cp_sat_feasibility.py`) using **OR-Tools** to test whether the current partial grid can extend to a full **RCLS** (and **snail shell equalities** when Snail Method = Yes).

| Tier | Behavior |
|------|----------|
| E0 | Python/ortools/script missing — footer note only; no pink |
| E1 | No completion exists — **pink** background (`#fce4ec`) if v1 checks pass |
| E2 | Solver timeout / inconclusive — info banner; no pink |

**Local setup (for the toggle):**

```bash
pip install ortools
```

From the repo root, with working directory set to the app folder, run the app as usual. The solver is invoked as `python3 scripts/cp_sat_feasibility.py` with JSON on stdin.

**shinyapps.io:** the default image does not include Python/ortools; the completability toggle is **shown disabled** with a short explanation (no E0 spam in the footer). Use a custom environment with Python installed, or run locally, to enable the check.

## Snail Method

Under **Order n**, choose **Build RCLS with Snail Method?** (Yes/No, default **No**).

| Setting | Behavior |
|---------|----------|
| **No** | Classic grid layout and validation only (A/B/C tiers). |
| **Yes** | Concentric black boxes: even n uses 2×2 kernel + frames 4, 6, …, n; odd n uses 1×1 center kernel + frames 3, 5, …, n. **Autofill:** editing a kernel/frame cell mirrors to linked positions (same snail symmetry on each shell). D1 banner still notes odd snails cannot exist (Dr. Groves Conjecture). |
| **Yes + odd n** | **D1** informational banner: no odd-order snail exists (Dr. Groves Conjecture). Does not turn the background red. |
| **Yes + n ≡ 2 (mod 4)** | **WLOG Upper V** (Yes/No, default **No**): when **Yes**, autofills 1..n along the upper-V path (main diagonal top-left → center, then anti-diagonal center → top-right), propagating each value through snail shell mirroring. Switching to **No** resets the grid. |

Switching Snail Method or changing n resets the grid.

| Tier | Check |
|------|--------|
| D1 | Info banner when Snail Method = Yes and n is odd (Dr. Groves Conjecture) |

## Deploy to shinyapps.io

1. Create an account at [shinyapps.io](https://www.shinyapps.io/).
2. Install and configure rsconnect:

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name = "YOUR_ACCOUNT", token = "YOUR_TOKEN", secret = "YOUR_SECRET")
```

3. Deploy (from repo root):

```r
rsconnect::deployApp(".", appName = "rcls-validator")
```

For reproducible deploys, initialize `renv` in this folder before deploying:

```r
install.packages("renv")
renv::init()
renv::snapshot()
```

## Reference

See [RCLS_Reference.md](../RCLS_Reference.md) in the parent folder for definitions and literature notes.
