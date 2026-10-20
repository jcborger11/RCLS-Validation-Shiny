# Plan: Lesson 32 & 33 Instructor LaTeX with Conditional Solutions

## Goal
Deliver full LaTeX with step-by-step solutions in red, visible only when `\showsolutionstrue` (hidden when `\showsolutionsfalse`).

## Approach
1. Add `\sol{...}` wrapper (or `\ifshowsolutions` + `{\color{red}...}`) for each problem.
2. Solve each problem with explicit steps for instructor copy.

## Problems worked
- Warm-up: Gaussian on semicircle; polar conversion; rose loop area
- Probability: normalize C, marginal Y probability, P(x+y<1)
- Mass/COM: triangle (0,0),(1,0),(0,2) with ρ=1+3x+y
- Practice: triangle (0,1),(1,1),(1,0) with ρ=xy; rectangle with ρ=ky²
- Harder: semicircle constant ρ; semicircle ρ ∝ distance from center

## Output file
`/workspace/Lesson32-33-Applications-Double-Integrals-Instructor.tex`
