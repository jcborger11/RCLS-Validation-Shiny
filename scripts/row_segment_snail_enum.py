#!/usr/bin/env python3
"""Enumerate middle-segment fillings for rows 2,3,4 (independent) from diagonal givens."""

from __future__ import annotations

import itertools
import time
from pathlib import Path
from typing import Callable, Iterable, List, Optional, Sequence, Tuple

from snail_solve import N, build_snail_groups

REPORT = Path(__file__).resolve().parent / "row_segment_snail_report.txt"


def diagonal_givens() -> List[List[Optional[int]]]:
    g: List[List[Optional[int]]] = [[None] * N for _ in range(N)]
    diag = [1, 2, 3, 4, 5, 5, 4, 3, 2, 1]
    anti = [10, 9, 8, 7, 6, 6, 7, 8, 9, 10]
    for i in range(N):
        g[i][i] = diag[i]
        g[i][N - 1 - i] = anti[i]
    return g


def solve_snail_rcls(given: List[List[Optional[int]]], timeout: float = 3.0) -> bool:
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
    return res in (cp_model.OPTIMAL, cp_model.FEASIBLE)


def row_filled(g: List[List[Optional[int]]], row: int) -> set[int]:
    return {g[row][j] for j in range(N) if g[row][j] is not None}


def col_filled(g: List[List[Optional[int]]], col: int) -> set[int]:
    return {g[i][col] for i in range(N) if g[i][col] is not None}


def quick_row_segment_ok(
    g0: List[List[Optional[int]]],
    row: int,
    cols: Sequence[int],
    values: Sequence[int],
) -> bool:
    """Cheap filters before CP-SAT."""
    if len(cols) != len(values):
        return False
    if len(set(values)) != len(values):
        return False
    fixed = row_filled(g0, row)
    for v in values:
        if v in fixed:
            return False
    for j, v in zip(cols, values):
        if v in col_filled(g0, j):
            return False
    return True


def enumerate_segment(
    name: str,
    row: int,
    cols: Sequence[int],
    value_pool: Iterable[Tuple[int, ...]],
    g0: List[List[Optional[int]]],
) -> Tuple[int, int, List[Tuple[int, ...]], float]:
    candidates: List[Tuple[int, ...]] = []
    for vals in value_pool:
        if quick_row_segment_ok(g0, row, cols, vals):
            candidates.append(vals)
    t0 = time.time()
    good: List[Tuple[int, ...]] = []
    for vals in candidates:
        g = [r[:] for r in g0]
        for j, v in zip(cols, vals):
            g[row][j] = v
        if solve_snail_rcls(g):
            good.append(vals)
    return len(candidates), len(good), good, time.time() - t0


def row2_pool() -> Iterable[Tuple[int, ...]]:
    # Row 2: (2,2)=2, (2,9)=9; fill cols 3..8 (6 cells). Other row-2 cells stay free.
    pool = [1, 3, 4, 5, 6, 7, 8, 10]
    for combo in itertools.permutations(pool, 6):
        yield combo


def row3_pool() -> Iterable[Tuple[int, ...]]:
    pool = [1, 2, 4, 5, 6, 7, 9, 10]
    for combo in itertools.permutations(pool, 4):
        yield combo


def row4_pool() -> Iterable[Tuple[int, ...]]:
    pool = [1, 2, 3, 5, 6, 8, 9, 10]
    for combo in itertools.permutations(pool, 2):
        yield combo


def format_row_line(g0: List[List[Optional[int]]], row: int, cols: Sequence[int], vals: Sequence[int]) -> str:
    line = []
    for j in range(N):
        if g0[row][j] is not None:
            line.append(g0[row][j])
        elif j in cols:
            idx = cols.index(j)
            line.append(vals[idx])
        else:
            line.append("_")
    return " ".join(f"{x:>2}" if x != "_" else " _" for x in line)


def main() -> None:
    g0 = diagonal_givens()
    lines: List[str] = [
        "Row segment snail+RCLS enumeration (diagonal givens only)",
        "Each project fixes only the middle cells on that row; other cells on that row stay blank.",
        "=" * 70,
        "",
    ]

    # cols: (start, end) inclusive, 0-based column indices
    projects = [
        ("Row 2 (cols 3-8 between 2 and 9)", 1, 2, 7, row2_pool),
        ("Row 3 (cols 4-7 between 3 and 8)", 2, 3, 6, row3_pool),
        ("Row 4 (cols 5-6 between 4 and 7)", 3, 4, 5, row4_pool),
    ]

    for title, row, c0, c1, pool_fn in projects:
        cols_list = list(range(c0, c1 + 1))
        n_cand, n_good, good, elapsed = enumerate_segment(title, row, cols_list, pool_fn(), g0)
        lines.append(title)
        lines.append(f"  Columns filled: {cols_list}")
        lines.append(f"  Candidates after row/col clash filter: {n_cand}")
        lines.append(f"  Admit snail+RCLS completion: {n_good}")
        lines.append(f"  Time: {elapsed:.2f}s")
        lines.append("  Feasible middle segments (values in column order):")
        for vals in good:
            lines.append(f"    {list(vals)}  |  row preview: {format_row_line(g0, row, cols_list, vals)}")
        lines.append("")

    text = "\n".join(lines)
    REPORT.write_text(text, encoding="utf-8")
    print(text)


if __name__ == "__main__":
    main()
