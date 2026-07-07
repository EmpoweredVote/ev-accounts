---
phase: 164-ky-or-ct-ok-ar-ia-ks-ms-candidate-seeding-create-elections-r
plan: 10
state: KY
status: complete
completed: 2026-07-06
requirements: [USHC3-05]
---

# 164-10 SUMMARY — KY Stances

## Result
All 15 new KY candidates resolved on **PROD**: **13 stance-complete (69 sourced answers), 2 gate-pinned whole-record skips**, 0 unsourced, 0 surname leaks.

## Pipeline
Scaffold `ky-2026-house/` (IN_SCOPE = 15 KY ids; excludes 98 MA state-leg rows at -210101..-210198). 3 agents (KY-1/2/3, KY-4, KY-5/6) @3-concurrency. Merge: 13 files, 69 rows, 0 problems. Push: 69 answers + 69 contexts + 51 quotes, 0 leaks. Gate: 0 unsourced.

## Per-candidate row counts (13 covered)
Williams 9 (KY-1); Wingfield 7, Loecken 4 (KY-2); Rodriguez 1 (KY-3); Gallrein 4, Strange 3, Todd 7 (KY-4 open); Pillersdorf 3, Wein 6 (KY-5); Alvarado 5, Dembo 7, Bowman 6, Lynch 7 (KY-6 open).

## Whole-record skips (gate-pinned for 164-13, trails in `_SKIPS.md`)
- **-210403 Mohammad Wael Ahmad (KY-4, Kentucky Party)** — no site/questionnaire/verified social; only a third-party characterization (not his words).
- **-210502 Gerardo Serrano (KY-5, Independent)** — no usable position evidence located.

## Integrity calls (verified)
- **John "Drew" Williams (-210300) confirmed the 2026 candidate**, not the historical "John Y. Brown (1835)" homonym that the headshot guard rejected in 164-04. Placed healthcare=2 (incremental reform) from an explicit quote — a Dem≠1 counter-example.
- **Jeremy Todd `ukraine-support` row DROPPED** by orchestrator (inferred from general non-interventionism, Ukraine never named — same standard as CT's Chai). Kept tariffs=1 (free-trade page) and voting-rights=4 (SAVE Act support) as concrete. Todd now 7 rows.
- No row references Massie (KY-4) or Barr (KY-6) — open seats clean.
- Agent-surfaced bio corrections (already reflected): Alvarado's post-Senate role was **Tennessee** Health Commissioner (not NV); Dembo is a former **federal** prosecutor (not KY asst. AG).

## Files (gitignored → PROD durable store)
`backend/data/stance-research/ky-2026-house/` scaffold + `_SKIPS.md` + gitignored CSVs.

## Self-Check: PASSED
0 unsourced on prod; 13/15 stance-complete; 2 skips with written trails; ≤3 concurrency; verification pass per agent; open-seat departing incumbents absent.
