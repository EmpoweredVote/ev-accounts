---
phase: 61
plan: 01
subsystem: app-ui-components
tags: [react, typescript, tailwind, auth, component-api]
one-liner: "Added inputClassName escape-hatch prop to AuthInput for per-field utility class injection without breaking the spread-order guarantee"

dependency-graph:
  requires: [60-02]  # AuthInput was built in plan 60-02
  provides: [AuthInput with inputClassName prop]
  affects: [61-04]   # SignupPage restyle needs this for invite-code mono styling

tech-stack:
  added: []
  patterns: [escape-hatch prop pattern for className injection without disrupting HTMLAttribute spread order]

key-files:
  created: []
  modified:
    - app/src/components/AuthInput.tsx

decisions:
  - "Dedicated inputClassName prop rather than merging inputProps.className — preserves spread-before-explicit-attrs safety and gives a cleaner consumer API"

metrics:
  duration: "< 5 minutes"
  completed: "2026-04-25"
---

# Phase 61 Plan 01: AuthInput inputClassName Prop Summary

## What Was Done

Patched `AuthInput` to accept an optional `inputClassName?: string` prop that appends to the internal `<input>` element's className string via a template literal with `.trim()`. The default is `''` so existing callers render byte-identically to before.

## Key Decisions

**Dedicated prop vs. merging inputProps.className**

The `{...inputProps}` spread comes before the explicit `className` attribute — this is intentional so consumers cannot accidentally override `type`, `value`, or `onChange` via inputProps. Merging `inputProps.className` would require either reordering the spread (unsafe) or extra Object.assign gymnastics (fragile). A named `inputClassName` prop is the cleanest, most explicit API for this escape hatch.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add inputClassName prop to AuthInput | ed7bf9d | app/src/components/AuthInput.tsx |

## Verification Results

- `npx tsc --noEmit` — zero errors
- `npm run build` — Vite build succeeded (56 modules, 1.07s)
- `grep -n inputClassName` — 3 occurrences: interface, destructure, className template
- `grep -c "{...inputProps}"` — 1 (spread preserved unchanged)

## Deviations from Plan

None — plan executed exactly as written.

## Next Phase Readiness

Plan 61-02 (and subsequent plans) can now pass `inputClassName="font-mono tracking-wider"` to AuthInput for the invite-code field. No further component changes needed to unblock the SignupPage restyle.
