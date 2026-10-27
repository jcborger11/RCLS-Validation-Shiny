#!/usr/bin/env python3
from __future__ import annotations
from typing import Dict, List, Optional, Set, Tuple

N = 10

# Diagonal-only grid from screenshot (None = blank)
GIVEN = [[None] * N for _ in range(N)]
diag = [1, 2, 3, 4, 5, 5, 4, 3, 2, 1]
anti = [10, 9, 8, 7, 6, 6, 7, 8, 9, 10]
for i in range(N):
    GIVEN[i][i] = diag[i]
    GIVEN[i][N - 1 - i] = anti[i]


def snail_min_shell_size(n: int) -> int:
    return 2 if n % 2 == 0 else 1


def snail_shell_sizes(n: int) -> List[int]:
    return list(range(snail_min_shell_size(n), n + 1, 2))


def snail_shell_bounds(n: int, shell_size: int) -> Tuple[int, int, int, int]:
    start = (n - shell_size) // 2 + 1
    return start, start + shell_size - 1, start, start + shell_size - 1


def snail_inside_bounds(i: int, j: int, b: Tuple[int, int, int, int]) -> bool:
    return b[0] <= i <= b[1] and b[2] <= j <= b[3]


def snail_on_perimeter(i: int, j: int, b: Tuple[int, int, int, int]) -> bool:
    return i == b[0] or i == b[1] or j == b[2] or j == b[3]


def snail_assign_shell(i: int, j: int, n: int) -> Optional[int]:
    min_size = snail_min_shell_size(n)
    for shell_size in snail_shell_sizes(n):
        b = snail_shell_bounds(n, shell_size)
        if not snail_inside_bounds(i, j, b) or not snail_on_perimeter(i, j, b):
            continue
        if shell_size > min_size:
            inner = snail_shell_bounds(n, shell_size - 2)
            if snail_inside_bounds(i, j, inner) and not snail_on_perimeter(i, j, inner):
                continue
        return shell_size
    return None


def snail_top_index(i: int, j: int, shell_size: int, b: Tuple[int, int, int, int]) -> Optional[int]:
    rs, re, cs, ce = b
    s = shell_size
    if i == rs:
        return j - cs + 1
    if j == cs:
        return i - rs + 1
    if i == re:
        return s - (j - cs + 1) + 1
    if j == ce:
        return s - (i - rs + 1) + 1
    return None


def snail_linked_positions(n: int, shell_size: int, top_index: int) -> List[Tuple[int, int]]:
    rs, re, cs, ce = snail_shell_bounds(n, shell_size)
    j = top_index
    pos = [(rs, cs + j - 1), (rs + j - 1, cs), (re, ce - j + 1), (re - j + 1, ce)]
    out: List[Tuple[int, int]] = []
    seen: Set[Tuple[int, int]] = set()
    for p in pos:
        if p not in seen:
            seen.add(p)
            out.append(p)
    return out


def snail_mirror_cells(n: int, i: int, j: int) -> List[Tuple[int, int]]:
    shell_size = snail_assign_shell(i, j, n)
    if shell_size is None:
        return []
    b = snail_shell_bounds(n, shell_size)
    ti = snail_top_index(i, j, shell_size, b)
    if ti is None:
        return []
    return snail_linked_positions(n, shell_size, ti)


def build_snail_groups(n: int) -> List[Set[Tuple[int, int]]]:
    parent: Dict[Tuple[int, int], Tuple[int, int]] = {}

    def find(c):
        if c not in parent:
            parent[c] = c
        while parent[c] != c:
            parent[c] = parent[parent[c]]
            c = parent[c]
        return c

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra

    for i in range(1, n + 1):
        for j in range(1, n + 1):
            for m in snail_mirror_cells(n, i, j):
                union((i, j), m)
    groups: Dict[Tuple[int, int], Set[Tuple[int, int]]] = {}
    for i in range(1, n + 1):
        for j in range(1, n + 1):
            groups.setdefault(find((i, j)), set()).add((i, j))
    return list(groups.values())


def validate_partial(mat, n: int) -> List[str]:
    v: List[str] = []
    for i in range(n):
        seen = {}
        for j in range(n):
            x = mat[i][j]
            if x is None:
                continue
            if x in seen:
                v.append(f"row {i+1} dup {x}")
            seen[x] = j
    for j in range(n):
        seen = {}
        for i in range(n):
            x = mat[i][j]
            if x is None:
                continue
            if x in seen:
                v.append(f"col {j+1} dup {x}")
            seen[x] = i
    loc = {}
    for i in range(n):
        for j in range(n - 1):
            x, y = mat[i][j], mat[i][j + 1]
            if x is None or y is None or x == y:
                continue
            k = (x, y)
            s = f"r{i+1}c{j+1}"
            if k in loc:
                v.append(f"pair {x}->{y} at {loc[k]} and {s}")
            loc[k] = s
    return v


class Solver:
    def __init__(self, n, given, groups, group_of):
        self.n = n
        self.groups = groups
        self.group_of = group_of
        self.group_value = [None] * len(groups)
        for gi, g in enumerate(groups):
            vals = {given[i - 1][j - 1] for i, j in g if given[i - 1][j - 1] is not None}
            if len(vals) > 1:
                raise ValueError(f"group {gi} conflict {vals}")
            if vals:
                self.group_value[gi] = next(iter(vals))

    def cv(self, i, j):
        return self.group_value[self.group_of[(i, j)]]

    def can(self, gi, val):
        if self.group_value[gi] is not None:
            return self.group_value[gi] == val
        g = self.groups[gi]
        rows = {i for i, _ in g}
        cols = {j for _, j in g}
        for i in rows:
            for j in range(1, self.n + 1):
                if (i, j) in g:
                    continue
                if self.cv(i, j) == val:
                    return False
        for j in cols:
            for i in range(1, self.n + 1):
                if (i, j) in g:
                    continue
                if self.cv(i, j) == val:
                    return False
        for i in rows:
            sim = [self.cv(i, j) for j in range(1, self.n + 1)]
            for ri, cj in g:
                if ri == i:
                    sim[cj - 1] = val
            for j in range(self.n - 1):
                x, y = sim[j], sim[j + 1]
                if x is None or y is None or x == y:
                    continue
                for ii in range(1, self.n + 1):
                    if ii == i:
                        continue
                    for jj in range(1, self.n):
                        ox, oy = self.cv(ii, jj), self.cv(ii, jj + 1)
                        if ox is None or oy is None:
                            continue
                        if (ox, oy) == (x, y):
                            return False
        return True

    def mat(self):
        return [[self.cv(i, j) for j in range(1, self.n + 1)] for i in range(1, self.n + 1)]

    def solve(self):
        unset = [gi for gi, v in enumerate(self.group_value) if v is None]
        if not unset:
            m = self.mat()
            for i in range(self.n):
                if sorted(m[i]) != list(range(1, self.n + 1)):
                    return False
            for j in range(self.n):
                if sorted([m[i][j] for i in range(self.n)]) != list(range(1, self.n + 1)):
                    return False
            pairs = {(m[i][j], m[i][j + 1]) for i in range(self.n) for j in range(self.n - 1)}
            return len(pairs) == self.n * (self.n - 1)
        gi = min(unset, key=lambda g: sum(1 for v in range(1, self.n + 1) if self.can(g, v)))
        for val in range(1, self.n + 1):
            if not self.can(gi, val):
                continue
            self.group_value[gi] = val
            if self.solve():
                return True
            self.group_value[gi] = None
        return False


def ortools_check(snail: bool):
    from ortools.sat.python import cp_model

    model = cp_model.CpModel()
    x = {}
    for i in range(N):
        for j in range(N):
            if GIVEN[i][j] is not None:
                x[i, j] = GIVEN[i][j]
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
    if snail:
        for g in build_snail_groups(N):
            cells = list(g)
            if len(cells) <= 1:
                continue
            r0, c0 = cells[0]
            v0 = x[r0 - 1, c0 - 1]
            for ri, cj in cells[1:]:
                model.add(x[ri - 1, cj - 1] == v0)
    solver = cp_model.CpSolver()
    solver.parameters.max_time_in_seconds = 120.0
    res = solver.solve(model)
    st = solver.status_name(res)
    print(f"  OR-Tools snail={snail}: {st}")
    if res not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
        return None
    return [[solver.value(x[i, j]) for j in range(N)] for i in range(N)]


def main():
    print("Filled cells:", sum(1 for r in GIVEN for c in r if c is not None))
    print("Partial v1:", validate_partial(GIVEN, N) or "OK")
    for i in range(1, N + 1):
        for j in range(1, N + 1):
            v = GIVEN[i - 1][j - 1]
            if v is None:
                continue
            for mi, mj in snail_mirror_cells(N, i, j):
                mv = GIVEN[mi - 1][mj - 1]
                if mv is not None and mv != v:
                    print(f"Snail conflict ({i},{j})={v} vs ({mi},{mj})={mv}")
                    return
    print("Snail givens: OK")
    groups = build_snail_groups(N)
    group_of = {c: gi for gi, g in enumerate(groups) for c in g}
    fixed = sum(1 for gi, g in enumerate(groups) if len({GIVEN[i-1][j-1] for i,j in g if GIVEN[i-1][j-1] is not None})==1)
    print(f"Snail groups: {len(groups)}, groups with a fixed value from givens: {fixed}")
    try:
        s = Solver(N, GIVEN, groups, group_of)
        ok = s.solve()
        print(f"Backtracking (RCLS + snail groups): {'SAT' if ok else 'UNSAT'}")
        if ok:
            for row in s.mat():
                print(" ".join(f"{v:2d}" for v in row))
    except ValueError as e:
        print("UNSAT:", e)
    print("OR-Tools:")
    g1 = ortools_check(False)
    g2 = ortools_check(True)
    if g1 and not g2:
        print("(RCLS exists without snail on blanks, but not with snail symmetry)")
    if g2:
        print("Completion with snail:")
        for row in g2:
            print(" ".join(f"{v:2d}" for v in row))


if __name__ == "__main__":
    main()
