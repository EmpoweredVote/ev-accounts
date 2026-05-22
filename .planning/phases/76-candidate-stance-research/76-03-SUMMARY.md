---
plan: 76-03
status: complete
commit: 5586938
---

# Plan 76-03 Summary — Batch 3 Senate Candidate Stances (MS-WY)

## What Was Done

Researched and ingested federal stance data for 15 non-incumbent 2026 Senate
candidates spanning Mississippi through Wyoming (external_ids -400129 to -400143).

**Task 1: Research (CSVs)**
- 15 individual CSV files in `backend/data/stance-research/2026-05-22-batch3-*.csv`
- 274 stance rows across 15 candidates
- Committed in `5586938`

**Task 2: Migration 207**
- File: `backend/migrations/207_us_senate_candidate_stances_batch3.sql`
- Applied via psql to remote Supabase (uses number 207; 199-206 already applied)
- Generated from CSVs via `gen_migration.py` (uses canonical topic UUIDs)
- Committed in `5586938`

## Per-Candidate Coverage (sorted ascending by topic count)

| Candidate | State | Party | topic_count |
|-----------|-------|-------|-------------|
| James Byrd | WY | D | 5 |
| Kurt Alme | MT | R | 13 |
| Scott Colom | MS | D | 13 |
| Seth Bodnar | MT | I | 14 |
| Michael Whatley | NC | R | 15 |
| Dan Osborn | NE | I | 17 |
| Chris Pappas | NH | D | 18 |
| Sherrod Brown | OH | D | 18 |
| Harriet Hageman | WY | R | 20 |
| John Sununu | NH | R | 20 |
| Kevin Hern | OK | R | 20 |
| Rachel Fetty Anderson | WV | D | 23 |
| Roy Cooper | NC | D | 23 |
| David Brock Smith | OR | R | 27 |
| Annie Andrews | SC | D | 28 |

**Total stances inserted: 274** (15 candidates × avg 18 topics)

## Notable Floor Cases

- **James Byrd (WY, D)**: Only 5 stances — below the 10-stance floor. He announced
  his Senate candidacy in February 2026 and has almost no public policy record. A single
  WyoFile article was the only accessible source. All other sources (Ballotpedia,
  Wikipedia, campaign sites) returned 404/ECONNREFUSED. Stances included are well-sourced;
  no fabrication was acceptable given the evidence limitations.

- **Kurt Alme (MT, R)** and **Scott Colom (MS, D)**: 13 stances each — both are
  non-incumbent candidates with limited prior legislative record. Evidence was thorough
  for what exists.

## Key Findings

- **Sherrod Brown (OH)**: Notable tariffs=4 (leans protective) — he was the Senate's
  most ardent trade hawk among Democrats, backed Trump's 2018 tariffs.
- **Dan Osborn (NE, I)**: Unusual independent profile — personally pro-life but opposes
  national ban, supports border wall, Medicare for All, removes Social Security payroll cap.
- **Seth Bodnar (MT, I)**: Explicitly opposes government intrusion "in the bedroom" —
  signals same-sex marriage support despite running as independent in conservative state.
- **Harriet Hageman (WY, R)**: Textualist judicial philosophy, voted against Ukraine aid,
  absolute abortion opposition ("no circumstances").

## Verification Results

- 15 candidates present ✓ (Byrd at 5 stances — noted gap, below floor)
- 14/15 candidates have topic_count >= 10 ✓
- 0 unpaired answers (every politician_answers has a politician_context) ✓
- 0 empty sources ✓
- Idempotency: migration applied cleanly; COMMIT confirmed ✓
- All topic UUIDs corrected to canonical values from compass-topics-reference.md ✓

## Migration Numbers

- Migration consumed: 207 (199-206 were already applied to DB — data migrations bypass Supabase tracking)
- Next available for Plan 76-04: 208
