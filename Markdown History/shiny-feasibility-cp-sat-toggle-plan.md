# Plan: Optional CP-SAT completion feasibility check (R Shiny)

**Goal:** Add a **sidebar toggle** (default **Off**) that, when On, runs a **completion existence** test after user input. If the partial grid cannot extend to a full **RCLS** (and respects **snail symmetry** when Snail Method = Yes), set the app background **pink**. When Off, behavior stays as today (v1 A/B/C/D checks only; light red on rule violations).

**Scope:** Plan only — no implementation in this document.

---

## 1. Current behavior (baseline)

| Piece | Location | Role |
|--------|-----------|------|
| Partial rules | `R/validate.R` → `validate_partial_rcls()` | A1–A4, B1–B2, C1/C2 info, D1 info |
| Reactive | `app.R` → `validation()` | Re-runs on any input change |
| Background | `output$background_style` | `#ffffff` if `result$ok`, else `#fde8e8` (light red) |
| Snail autofill | `observe()` on cell changes | Mirrors edits; `is_syncing` batches updates |

**Gap:** `ok = TRUE` only means *no v1 violation on filled cells* — not “some full grid exists.”

---

## 2. Desired behavior

### Toggle (UI)

- **Label (suggested):** “Check completability (CP-SAT)?” or “Highlight impossible partials?”
- **Control:** `checkboxInput` or `radioButtons` — **default Off**.
- **Placement:** Sidebar under Snail / WLOG options, with one sentence help text: *When on, uses OR-Tools to test whether any full RCLS (+ snail if enabled) completion exists. Slow on large n; requires Python.*

### When Off

- No CP-SAT calls.
- Background logic unchanged (white / light red only from v1).

### When On

- After each **stable** grid change, run feasibility solver on current partial matrix.
- **If INFEASIBLE:** background **pink** (distinct from violation red), e.g. `#fce4ec` or `#f8d7da` with a CSS class `feasibility-impossible` so theme is easy to tweak.
- **If FEASIBLE or UNKNOWN (timeout):** do **not** use pink; if v1 `ok`, white; if v1 fails, keep light red.
- **Footer / status:** Add informational line (not counted as `violations`), e.g. **E1:** “No full RCLS (+ snail) completion exists (CP-SAT).” On timeout: **E2:** “Completability check timed out — result unknown.”

### Precedence (background color)

Suggested priority (highest wins):

1. **v1 violations** → light red (`#fde8e8`) — definite local errors.
2. **Toggle on + CP-SAT INFEASIBLE** → pink — globally stuck but locally OK.
3. **Otherwise** → white.

Optional: if both violation and infeasible, red is enough; footer can still list both.

---

## 3. What “feasibility” means (match repo + Python prototype)

Encode the same model as `scripts/snail_solve.py` / `ortools_check()`:

1. **Variables:** `1..n` in each blank cell; givens fixed.
2. **Latin:** `AllDifferent` per row and column.
3. **RCLS:** For each row, encode each horizontal adjacent pair `(x,y)`, `x≠y`, as a unique integer; all `n(n−1)` encodings `AllDifferent`.
4. **Snail (iff Snail Method = Yes):** For each snail group from `build_snail_groups(n)` (port to R or pass flag to Python), equality on all cells in the group.

**Do not** treat C1 impossible orders as “skip SAT” unless you want explicit UX — SAT will also return INFEASIBLE; optional fast path: if `n %in% c(3,5,7,11)` and grid could be complete, show C1 banner only and skip SAT.

**Invalid symbols / A1:** If any cell is non-numeric or out of range, skip SAT (or run only after parsing blanks as NA); align with `matrix_from_inputs()`.

---

## 4. Architecture: R Shiny ↔ OR-Tools

OR-Tools is **Python**. The Shiny app is **R**. Recommended approach:

### 4a. Thin Python CLI (single source of truth)

- Add `scripts/cp_sat_feasibility.py` (extract from existing `snail_solve.py`):
  - **stdin or JSON file:** `{ "n": 10, "matrix": [[1, null, ...], ...], "snail": true, "timeout_sec": 2 }`
  - **stdout JSON:** `{ "status": "FEASIBLE" | "INFEASIBLE" | "UNKNOWN", "wall_ms": 12 }`
- Keeps one implementation; R only orchestrates.

### 4b. R wrapper

- New file `R/feasibility_cp_sat.R`:
  - `check_completion_feasible(mat, n, snail_mode, timeout_sec)` → list(`status`, `message`).
  - Uses `sys.which("python3")` and `system2()` with temp JSON; cleans up temp files.
  - If Python/ortools missing → `status = "UNAVAILABLE"`, no pink, footer note once.

### 4c. Optional later: `reticulate`

- Embed Python in-process for lower latency on repeated checks; more deployment friction. Start with **subprocess** for simplicity.

### 4d. Deployment notes

| Environment | Consideration |
|-------------|----------------|
| Local dev | `pip install ortools` in project `.venv`; document in README. |
| Cloud Agent / custom image | Add Python + ortools to `environment.json` install steps. |
| shinyapps.io | Default image may **lack** Python/ortools — toggle shows “unavailable” unless you use a **custom Docker** manifest or drop feasibility on hosted deploy. Call this out in README. |

---

## 5. Server integration (app.R)

### New reactives

```r
feasibility_check_enabled <- reactive({
  isTRUE(input$check_completability)  # name TBD
})

feasibility_result <- reactive({
  req(feasibility_check_enabled())
  # ... build mat from input, honor is_syncing, debounce ...
})
```

### When to run (avoid storms)

1. **`is_syncing()`:** return early (same as snail mirror observer) until `grid_snapshot` updated.
2. **Debounce:** e.g. `shiny::debounce(reactive({ ... read grid ... }), 500)` or `invalidateLater(300)` after last change so typing “12” doesn’t run SAT twice.
3. **Skip empty grid:** all-blank → FEASIBLE (many completions) or skip message “Grid empty.”
4. **Skip if v1 not ok:** optional optimization — infeasible partial may already violate Latin; still OK to run SAT for pink-on-infeasible-only UX when v1 ok.

### Update `output$background_style`

```r
bg <- if (!result$ok) {
  "#fde8e8"
} else if (feas_enabled && feas$status == "INFEASIBLE") {
  "#fce4ec"   # pink
} else {
  "#ffffff"
}
```

### Non-blocking UI (recommended phase 2)

- CP-SAT for `n=10` is ~ms–low seconds, but `n=12` or pathological cases may stall UI.
- **Phase 1:** synchronous call with **short timeout** (1–2 s).
- **Phase 2:** `promises` + `future` + background worker; show “checking…” in footer until result returns.

---

## 6. UI copy and accessibility

- Sidebar help text + link to `RCLS_Reference` / README “Completability check.”
- Footer distinguishes:
  - **Violation** (existing red footer),
  - **E1 completability** (pink background),
  - **E2 timeout** (no pink, yellow info banner?).
- Ensure pink vs red is distinguishable (not only color: footer text always states reason).

---

## 7. Files to touch (implementation checklist)

| File | Change |
|------|--------|
| `app.R` | Toggle input; `feasibility_result` reactive; debounce; extend `background_style`, `status_footer`, maybe `info_banner` for E1/E2 |
| `R/feasibility_cp_sat.R` | **New** — R → Python bridge |
| `scripts/cp_sat_feasibility.py` | **New** — SAT model (refactor from `snail_solve.py`) |
| `R/snail_autofill.R` or `R/feasibility_snail.R` | Export snail groups for Python **or** duplicate group logic only in Python (already in `snail_solve.py`) |
| `www/styles.css` | Optional `.app-container.feasibility-impossible` |
| `README.md` | Toggle, Python/ortools setup, shinyapps limitation |
| `tests/` | R test with `skip_if_no_python()`; fixture matrices: diagonal-only → FEASIBLE; diagonal+8 extra 2s → INFEASIBLE |

---

## 8. Testing strategy

1. **Unit (Python):** JSON fixtures → FEASIBLE/INFEASIBLE match known enumeration results (e.g. 16 row-1 cases).
2. **Unit (R):** Mock `system2` return JSON; assert pink CSS branch.
3. **Smoke (Shiny):** `shinytest2` or manual — toggle on, fill known impossible partial, expect pink.
4. **CI:** Install ortools in workflow or `skip_on_cran()` / skip if no python.

---

## 9. Phased rollout

| Phase | Deliverable |
|-------|-------------|
| **P0** | Python CLI + R wrapper + toggle + pink + E1 footer; debounce; default off |
| **P1** | Timeout tuning; UNAVAILABLE handling; README / env setup |
| **P2** | Async check; cache last `(n, hash(mat), snail)` result to avoid duplicate SAT on mirror-only sync |
| **P3** | Optional: witness grid preview (“one completion”) for FEASIBLE — **not** required for pink feature |

---

## 10. Risks and mitigations

| Risk | Mitigation |
|------|------------|
| UI freeze | Debounce + timeout + async (P2) |
| shinyapps.io no Python | Graceful UNAVAILABLE; feature local/custom image |
| Drift vs R validator | Single Python model; snail groups generated from same formulas as `snail_mirror_cells` (test parity on n=6,10) |
| User confusion red vs pink | Clear labels; footer always explains |
| Playing “what-if” | Toggle default **Off** |

---

## 11. Out of scope (this plan)

- Enumerating all completions or counting solutions.
- Replacing v1 checks with SAT.
- Running enumeration (row 1, row 2 segments) inside Shiny.

---

*Plan saved for John — implementation not started per request.*
