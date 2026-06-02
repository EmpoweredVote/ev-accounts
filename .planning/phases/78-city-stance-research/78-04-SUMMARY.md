---
phase: 78-city-stance-research
plan: 04
status: complete
completed: 2026-06-01
migration: 256
---

# 78-04 Summary: Berkeley Stances

## Outcome

CSTA-03 CLOSED. All 10 Berkeley officials ingested via migration 256.

## Roster Correction

The 78-04 PLAN.md listed Jesse Arreguin as Mayor and outdated council members (Kate Harrison D4, Susan Wengraf D6, Rigel Robinson D7, Sophie Hahn D8). The live DB (migration 214) had the correct current roster — Adena Ishii (Mayor) plus 2024-elected council members. Plan doc was not updated; DB was authoritative.

## Migration Applied

`backend/migrations/256_berkeley_stances.sql` — 128 stance rows, 1,524 lines

## Per-Politician Counts (CSV rows)

| Official | Office | Stances |
|---------|--------|---------|
| Adena Ishii | Mayor | 11 |
| Jenny Wong | City Auditor | 8 |
| Rashi Kesarwani | D1 | 14 |
| Terry Taplin | D2 | 12 |
| Ben Bartlett | D3 | 14 |
| Igor Tregub | D4 | 12 |
| Shoshana O'Keefe | D5 | 14 |
| Brent Blackaby | D6 | 14 |
| Cecilia Lunaparra | D7 | 18 |
| Mark Humbert | D8 | 11 |
| **Total** | | **128** |

## Scale Inversion Fixes Applied

52 corrections on first 6 officials (Ishii, Wong, Kesarwani, Taplin, Bartlett, Tregub) — agents used "liberal=low, conservative=high" mental model. 1 fix on Lunaparra (same-sex-marriage 1→5). O'Keefe, Blackaby, Humbert came back correctly calibrated.

## Floor Cases

- Jenny Wong (City Auditor): 8 stances — administrative/oversight role as predicted; judicial-transparency=5 and judicial-police-accountability=5 are her defining scores
- Mark Humbert (D8): 11 stances — most moderate member; rent-regulation=2 (sole NO on algorithmic rent ban), public-safety-approach=2 (pro-police-expansion)

## Verification

- ✅ 10 distinct politicians in DB
- ✅ All ≥ 8 stances (floor exceeded)
- ✅ 0 data-centers rows
- ✅ 0 orphaned answers (every answer paired with context row)

## CSV

`backend/data/stance-research/2026-06-01-berkeley-officials.csv`
