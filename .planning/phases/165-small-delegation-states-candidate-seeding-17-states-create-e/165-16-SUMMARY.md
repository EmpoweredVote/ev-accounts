---
phase: 165-small-delegation-states-candidate-seeding-17-states-create-e
plan: 16
state: MT+ND+SD
status: complete
completed: 2026-07-07
requirements: [USHC3-05]
---

# 165-16 SUMMARY — MT + ND + SD stance research pushed to PROD

## What was built
mt/nd/sd-2026-house scaffolds (live federal-24 scale) + stance research for all 8 targets, pushed to PROD. **52 answers (MT 31 + ND 9 + SD 3 + Jackley 9 via UUID), 0 unsourced, 0 surname leaks.**

## Coverage (all 8 targets sourced — 0 whole-record skips)
- **MT (31):** -300101 Aaron Flint 7 (own on-air/campaign words only; a guest quote correctly excluded), -300102 Forstag 11 (rich /policies platform), -300103 Sheedy 2 (MT Free Press questionnaire), -300285 Miller 6, -300286 McCracken 5.
- **ND (9):** -380001 Trygve Hammer (2024 debate record flagged where stale; an uncorroborated quote rejected rather than risked).
- **SD (12):** -460001 Gronli 3 (thin first-time-candidate record, honestly bounded); **Marty Jackley 9 topics pushed via _push_uuid.ts onto the v2.18 SD-AG pid 2537050a** — AG-record provenance (amicus briefs, 287(g) scoping, SB17 sponsorship) noted per row; an AI-inferred iSideWith tariff item correctly excluded.
- Incumbents Downing/Fedorchak partial-tier → skipped; MT-1/SD open seats have no incumbent.

## Incident (documented, resolved)
A failed early sub-pass of the MT-1 agent had fabricated off-scope CSVs named `patrick-mccracken.csv`/`brian-miller.csv`; its cleanup later deleted the MT-2 agent's LEGITIMATE McCracken file (same name, shared dir). Detected via merge count (26 vs 31 expected); the MT-2 agent was resumed and re-wrote the verified file; re-merge + idempotent re-push confirmed 31/31 and -300286 = 5 answers live. Lesson: same-name collisions across concurrent agents sharing a state dir — future phases should scope any agent-side cleanup to its own targets.

## Self-Check: PASSED
0 unsourced on PROD for all MT/ND/SD targets incl. the Jackley UUID push; every target sourced; no pinned skips for these states. **Wave 2 complete — all 8 stance plans done.**
