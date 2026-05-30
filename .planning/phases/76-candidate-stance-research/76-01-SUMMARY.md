---
plan: 76-01
status: complete
commit: c20cac2
---

# Plan 76-01 Summary — Batch 1 Senate Candidate Stances (AL-IA)

## What Was Done

Researched and ingested federal stance data for 15 non-incumbent 2026 Senate
candidates spanning Alabama through Iowa (external_ids -400101 to -400115).

**Task 1: Research (CSV)**
- CSV: `backend/data/stance-research/2026-05-22-us-senate-candidates-batch1.csv`
- 165 stance rows across 15 candidates
- Committed in `c457a76`

**Task 2: Migration 197**
- File: `backend/migrations/197_us_senate_candidate_stances_batch1.sql`
- Applied via psql to remote Supabase
- Committed in `c20cac2`

## Per-Candidate Coverage (sorted ascending by topic count)

| Candidate | State | Party | topic_count |
|-----------|-------|-------|-------------|
| Dakarai Larriett | AL | D | 10 |
| Derek Dooley | GA | R | 10 |
| David Roth | ID | D | 10 |
| Zach Wahls | IA | D | 11 |
| Ashley Hinson | IA | R | 11 |
| Juliana Stratton | IL | D | 11 |
| Mike Collins | GA | R | 11 |
| Angie Nixon | FL | D | 11 |
| Alex Vindman | FL | D | 11 |
| Hallie Shoffner | AR | D | 11 |
| Mary Peltola | AK | D | 11 |
| Barry Moore | AL | R | 11 |
| Janak Joshi | CO | R | 12 |
| Don Tracy | IL | R | 12 |
| Steve Marshall | AL | R | 12 |

**Total stances inserted: 165** (15 candidates × avg 11 topics)

Candidates at floor (10 topics): Larriett, Dooley, Roth — limited public record
as non-incumbents running in competitive primaries.

## Verification Results

- 15 candidates present with topic_count >= 10 ✓
- 0 unpaired answers (every politician_answers has a politician_context) ✓
- 0 empty sources ✓
- No city-level topic_keys (data-centers excluded) ✓
- Idempotency: migration applied once cleanly; COMMIT at line 2757 ✓

## Migration Numbers

- Migration consumed: 197
- Next available for Plan 76-02: 198
