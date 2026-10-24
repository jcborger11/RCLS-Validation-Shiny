# Top rows admitting snail RCLS (n=10)

## Setup
- **Givens:** upper-V / diagonal screenshot (20 cells on main + anti diagonals).
- **Row 1:** `(1,1)=1`, `(1,10)=10`; enumerate permutations of `{2..9}` in columns 2–9 that respect column givens.
- **Question:** For which row-1 completions does there exist a full **RCLS + snail symmetry** square?

## Method
1. Count valid row-1 permutations (column ban from diagonals).
2. OR-Tools CP-SAT per row: Latin, 90 distinct ordered pairs, snail group equalities.

## Results

- **Valid row-1 candidates** (cols 2–9 permute `{2..9}`, respect diagonal column bans): **4,752** (not 8! = 40,320).
- **Admit at least one snail + RCLS completion:** **16**.
- **Runtime:** ~18 s full sweep (~3.7 ms/row) with OR-Tools CP-SAT.

### Viable top rows (row 1, cols 1–10)

| # | Row 1 |
|---|-------|
| 1 | 1 3 4 6 2 9 5 7 8 10 |
| 2 | 1 3 5 9 4 7 2 6 8 10 |
| 3 | 1 3 6 2 4 7 9 5 8 10 |
| 4 | 1 3 7 5 2 9 6 4 8 10 |
| 5 | 1 5 4 2 3 8 9 7 6 10 |
| 6 | 1 5 4 9 3 8 2 7 6 10 |
| 7 | 1 5 7 2 3 8 9 4 6 10 |
| 8 | 1 5 7 9 3 8 2 4 6 10 |
| 9 | 1 6 4 2 3 8 9 7 5 10 |
| 10 | 1 6 4 9 3 8 2 7 5 10 |
| 11 | 1 6 7 2 3 8 9 4 5 10 |
| 12 | 1 6 7 9 3 8 2 4 5 10 |
| 13 | 1 8 4 5 2 9 6 7 3 10 |
| 14 | 1 8 5 2 4 7 9 6 3 10 |
| 15 | 1 8 6 9 4 7 2 5 3 10 |
| 16 | 1 8 7 6 2 9 5 4 3 10 |

Pattern: second entry is always **3, 5, 6, or 8**; positions 6–7 often include **8,9** or **7,9** pairs.

Full witness grids: `scripts/top_row_snail_report.txt`.

Re-run: `python3 scripts/top_row_snail_enum.py` (requires `ortools`).
