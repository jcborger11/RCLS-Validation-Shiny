#!/usr/bin/env python3
"""CP-SAT completion feasibility for partial RCLS (+ optional snail). JSON stdin -> JSON stdout."""

from __future__ import annotations

import json
import sys
import time
from pathlib import Path
from typing import Any, List, Optional

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from snail_solve import build_snail_groups  # noqa: E402


def parse_matrix(raw: List[List[Any]], n: int) -> tuple[Optional[List[List[Optional[int]]]], str]:
    if len(raw) != n or any(len(row) != n for row in raw):
        return None, "bad_dimensions"
    out: List[List[Optional[int]]] = []
    for row in raw:
        parsed_row: List[Optional[int]] = []
        for cell in row:
            if cell is None:
                parsed_row.append(None)
            elif isinstance(cell, bool):
                return None, "invalid_cell"
            elif isinstance(cell, int):
                parsed_row.append(cell)
            elif isinstance(cell, float) and cell == int(cell):
                parsed_row.append(int(cell))
            else:
                return None, "invalid_cell"
        out.append(parsed_row)
    return out, "ok"


def solve_feasibility(
    n: int,
    matrix: List[List[Optional[int]]],
    snail: bool,
    timeout_sec: float,
) -> str:
    from ortools.sat.python import cp_model

    model = cp_model.CpModel()
    x = {}
    for i in range(n):
        for j in range(n):
            v = matrix[i][j]
            if v is not None:
                if v < 1 or v > n:
                    return "SKIP"
                x[i, j] = v
            else:
                x[i, j] = model.new_int_var(1, n, f"x_{i}_{j}")

    for i in range(n):
        model.add_all_different([x[i, j] for j in range(n)])
    for j in range(n):
        model.add_all_different([x[i, j] for i in range(n)])

    tuples = []
    code = 0
    for a in range(1, n + 1):
        for b in range(1, n + 1):
            if a != b:
                code += 1
                tuples.append((a, b, code))
    enc = []
    for i in range(n):
        for j in range(n - 1):
            e = model.new_int_var(1, n * (n - 1), f"e_{i}_{j}")
            model.add_allowed_assignments([x[i, j], x[i, j + 1], e], tuples)
            enc.append(e)
    model.add_all_different(enc)

    if snail:
        for grp in build_snail_groups(n):
            cells = list(grp)
            if len(cells) <= 1:
                continue
            r0, c0 = cells[0]
            v0 = x[r0 - 1, c0 - 1]
            for ri, cj in cells[1:]:
                model.add(x[ri - 1, cj - 1] == v0)

    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = float(timeout_sec)
    res = solver.solve(model)
    if res in (cp_model.OPTIMAL, cp_model.FEASIBLE):
        return "FEASIBLE"
    if res == cp_model.INFEASIBLE:
        return "INFEASIBLE"
    return "UNKNOWN"


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        print(json.dumps({"status": "UNAVAILABLE", "reason": "invalid_json"}))
        return

    n = int(payload.get("n", 0))
    snail = bool(payload.get("snail", False))
    timeout_sec = float(payload.get("timeout_sec", 2.0))
    raw_matrix = payload.get("matrix")

    if n < 1 or not isinstance(raw_matrix, list):
        print(json.dumps({"status": "SKIP", "reason": "bad_request"}))
        return

    matrix, reason = parse_matrix(raw_matrix, n)
    if matrix is None:
        print(json.dumps({"status": "SKIP", "reason": reason}))
        return

    filled = sum(1 for row in matrix for v in row if v is not None)
    if filled == 0:
        print(json.dumps({"status": "FEASIBLE", "wall_ms": 0, "note": "empty_grid"}))
        return

    t0 = time.time()
    try:
        status = solve_feasibility(n, matrix, snail, timeout_sec)
    except ImportError:
        print(json.dumps({"status": "UNAVAILABLE", "reason": "ortools_missing"}))
        return
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({"status": "UNAVAILABLE", "reason": str(exc)}))
        return

    wall_ms = int((time.time() - t0) * 1000)
    print(json.dumps({"status": status, "wall_ms": wall_ms}))


if __name__ == "__main__":
    main()
