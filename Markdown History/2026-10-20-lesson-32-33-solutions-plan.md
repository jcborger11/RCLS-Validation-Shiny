# Plan: Lesson 32 & 33 Instructor Solutions LaTeX

## Goal
Produce the full worksheet LaTeX for **Lesson 32 & 33 Applications of Double Integrals** with step-by-step solutions in red that appear only when `\ifshowsolutions` is true (instructor copy).

## Approach
1. Keep the existing document structure, header, and problem statements.
2. Add a `\sol{...}` macro that wraps content in `\color{red}` only when `\showsolutionstrue`.
3. Set `\showsolutionstrue` for the instructor copy (comment notes how to hide for student version).
4. Fix markdown-style `###{}` headings to proper `\subsection{}`.
5. Work each problem with clear intermediate steps suitable for lecture follow-along.

## Problems covered
- Warm-up: Gaussian over semicircle; polar conversion of iterated integral; four-leaved rose area
- Probability: normalize joint density; marginal-style event; \(X+Y<1\)
- Mass / center of mass examples and practice
- Harder: constant-density and distance-proportional semicircular plates

## Deliverable
- `Lesson32_33_Applications_Double_Integrals.tex` in the repo root
