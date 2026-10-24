#!/usr/bin/env python3
"""Enumerate row-1 completions from diagonal givens; test snail+RCLS."""

from __future__ import annotations

import itertools
import time
from pathlib import Path
from typing import List, Optional, Tuple

from snail_solve import N, build_snail_groups

REPORT = Path(__file__).resolve().parent / "top_row_snail_report.txt"


def diagonal_givens() -> List[List[Optional[int]]]:
    g: List[List[Optional[int]]] = [[None] * N for _ in range(N)]
    diag = [1, 2, 3, 4, 5, 5, 4, 3, 2, 1]
    anti = [10, 9, 8, 7, 6, 6, 7, 8, 9, 10]
    for i in range(N):
        g[i][i] = diag[i]
        g[i][N - 1 - i] = anti[i]
    return g


def col_used(g: List[List[Optional[int]]], j: int) -> set[int]:
    return {g[i][j] for i in range(N) if g[i][j] is not None}


def valid_row1_permutations(g0: List[List[Optional[int]]]) -> List[Tuple[int, ...]]:
    pool = [2, 3, 4, 5, 6, 7, 8, 9]
    out: List[Tuple[int, ...]] = []
    for perm in itertools.permutations(pool):
        row = (1,) + perm + (10,)
        ok = True
        for j in range(1, 9):
            if row[j] in col_used(g0, j):
                ok = False
                break
        if ok:
            out.append(row)
    return out


def solve_snail_rcls(given: List[List[Optional[int]]], timeout: float = 3.0) -> Tuple[bool, Optional[List[List[int]]]]:
    from ortools.sat.python import cp_model

    model = cp_model.CpModel()
    x = {}
    for i in range(N):
        for j in range(N):
            if given[i][j] is not None:
                x[i, j] = given[i][j]
            else:
                x[i, j] = model.new_int_var(1, N, f"x_{i}_{j}")
    for i in range(N):
        model.add_all_different([x[i, j] for j in range(N)])
    for j in range(N):
        model.add_all_different([x[i, j] for i in range(N)])
    tuples = []
    code = 0
    for a in range(1, N + 1):
        for b in range(1, N + 1):
            if a != b:
                code += 1
                tuples.append((a, b, code))
    enc = []
    for i in range(N):
        for j in range(N - 1):
            e = model.new_int_var(1, N * (N - 1), f"e_{i}_{j}")
            model.add_allowed_assignments([x[i, j], x[i, j + 1], e], tuples)
            enc.append(e)
    model.add_all_different(enc)
    for grp in build_snail_groups(N):
        cells = list(grp)
        if len(cells) <= 1:
            continue
        r0, c0 = cells[0]
        v0 = x[r0 - 1, c0 - 1]
        for ri, cj in cells[1:]:
            model.add(x[ri - 1, cj - 1] == v0)
    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = timeout
    res = solver.solve(model)
    if res not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
        return False, None
    grid = [[solver.value(x[i, j]) for j in range(N)] for i in range(N)]
    return True, grid


def main() -> None:
    g0 = diagonal_givens()
    rows = valid_row1_permutations(g0)
    t0 = time.time()
    good: List[Tuple[Tuple[int, ...], List[List[int]]]] = []
    for row in rows:
        g = [r[:] for r in g0]
        g[0] = list(row)
        ok, grid = solve_snail_rcls(g)
        if ok and grid is not None:
            good.append((row, grid))
    elapsed = time.time() - t0

    lines = [
        "Top rows admitting snail RCLS (n=10, diagonal givens)",
        "=" * 60,
        f"Valid row-1 permutations (column-feasible): {len(rows)}",
        f"Admit snail+RCLS completion: {len(good)}",
        f"Elapsed: {elapsed:.2f}s ({elapsed / max(len(rows), 1) * 1000:.2f} ms/row)",
        "",
        "Viable row 1 (cols 1..10):",
    ]
    for row, _ in good:
        lines.append("  " + " ".join(f"{v:2d}" for v in row))
    lines.append("")
    lines.append("One witness completion per viable row:")
    lines.append("")
    for row, grid in good:
        lines.append("Row 1: " + " ".join(f"{v:2d}" for v in row))
        for r in grid:
            lines.append("  " + " ".join(f"{v:2d}" for v in r))
        lines.append("")

    text = "\n".join(lines)
    REPORT.write_text(text, encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
