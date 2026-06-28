---
phase: 139-single-low-rep-states-house-rep-stances
status: passed
verified: 2026-06-20
requirements: [USHS-13]
---

# Phase 139 Verification — Single/Low-Rep States House Rep Stances

**Goal:** All in-scope reps in the 12 smallest-delegation states — HI/ID/MT/NH/RI/WV (2 each) + AK/DE/ND/SD/VT/WY (1 each, at-large) = **18 reps** — have sourced compass stances, each backed by a real source URL.

## Goal-backward result: PASSED

Per-scope production verification (DB pool fallback — MCP token expired), all `essentials.politicians external_id` for state_fips ∈ {15,16,30,33,44,54,2,10,38,46,50,56}:

```
REPS=18  TOTAL_ANSWERS=192  REPS_WITH_ZERO=0  UNSOURCED=0
```

| Plan | States | Reps | Answers | Unsourced |
|------|--------|------|---------|-----------|
| 139-01 | HI + ID + MT | 6 | 64 | 0 |
| 139-02 | NH + RI + WV | 6 | 58 | 0 |
| 139-03 | AK + DE + ND + SD + VT + WY (at-large) | 6 | 70 | 0 |
| **Total** | **12 states** | **18** | **192** | **0** |

## Success Criteria

1. ✅ Every in-scope rep (18 total, no pre-existing answers) has ≥1 sourced compass stance — REPS_WITH_ZERO=0; range 4 (Downing/Amo) to 17 (Simpson/Pappas).
2. ✅ Every answer row has a paired `inform.politician_context` row with a real fetched source URL — UNSOURCED=0 across all 18.
3. ✅ No-evidence topics honest-skipped, no party-inference — 8 caucus/committee/record-inference rows dropped at review before push (Case civil-rights, Tokuda civil-rights/healthcare/ukraine, Pappas ukraine, Amo climate, Magaziner civil-rights+ukraine, Hageman misinformation, Balint trans-athletes); thin freshmen scored only from documented campaign positions/votes/prior-office records.

## Method notes

- Pure scale-out of the validated phases 127–138 pipeline; 3-concurrency `politician-stance-researcher`, WebFetch-only, five-chairs framing, per-rep CSV → `_merge.ts` RFC-4180 validation (0 problems every batch) → external_id-keyed `_push.ts`.
- 60 quotes inserted + 60 selected across the phase, **0 surname leaks**.
- **At-large external_id quirk handled:** the 6 single-rep states use `-{fips}000` (AK −2000, DE −10000, ND −38000, SD −46000, VT −50000, WY −56000), verified in prod before authoring — assuming `-{fips}001` would have written nothing for them.
- Thin honest-partials (2024 freshmen / source-blocked): Downing MT-2 (4), Amo RI-1 (4), Goodlander NH-2 (6), Moore WV-2 (6), Tokuda HI-2 (6), Fedorchak ND (8), Begich AK (9). Acceptable — honest-skip beats inference; several freshmen scored from documented prior-office records (McBride DE state senate, Fedorchak ND PSC, Zinke Interior, Downing MT Auditor).

**Verdict: PASSED.** USHS-13 satisfied. **All 8 v2.17 research waves complete (132–139).** Next: Phase 140 (consolidated all-212 verification gate, USHS-14) — the final v2.17 step.
