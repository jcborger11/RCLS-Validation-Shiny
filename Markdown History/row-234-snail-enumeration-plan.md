# Row 2 / 3 / 4 middle-cell snail RCLS enumeration

Diagonal-only givens (screenshot). Three **independent** studies:

| Row | Fixed on row | Fill only (cols) | # cells |
|-----|----------------|------------------|--------|
| 2 | (2,2)=2, (2,9)=9 | 3–8 | 6 |
| 3 | (3,3)=3, (3,8)=8 | 4–7 | 4 |
| 4 | (4,4)=4, (4,7)=7 | 5–6 | 2 |

For each assignment to those cells, CP-SAT asks: exists full grid (diagonal givens + that row segment) satisfying RCLS + snail? Row 1 and other rows are **not** pre-filled from prior top-row study.

Results in `scripts/row_segment_snail_report.txt`.

## Results (independent CP-SAT per assignment)

**Row 2** — fill cols **3–8** (6 cells between 2 and 9); row 2 cols 1,10 stay blank in the test.

- Candidates (no clash with diagonal column entries, distinct in segment): **3,800**
- **12** admit a snail+RCLS completion

Feasible middle (cols 3–8):  
`[1,8,4,7,3,10]`, `[1,8,7,4,3,10]`, `[4,5,10,1,6,7]`, `[4,6,1,10,5,7]`, `[5,1,7,4,10,6]`, `[5,10,4,7,1,6]`, `[6,1,4,7,10,5]`, `[6,10,7,4,1,5]`, `[7,5,1,10,6,4]`, `[7,6,10,1,5,4]`, `[10,8,4,7,3,1]`, `[10,8,7,4,3,1]`

**Row 3** — fill cols **4–7** (4 cells); ignore row 2.

- Candidates: **524** → **12** feasible (same count, different list)

**Row 4** — fill cols **5–6** (2 cells); ignore rows 2–3.

- Candidates: **30** → **4** feasible: `(5,6) = (1,10)`, `(3,8)`, `(8,3)`, `(10,1)`
