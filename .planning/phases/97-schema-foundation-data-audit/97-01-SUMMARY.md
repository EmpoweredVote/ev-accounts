---
phase: 97-schema-foundation-data-audit
plan: 01
subsystem: ev-accounts/database
tags: [schema, migrations, elections, antipartisan, retention-vote]
dependency_graph:
  requires: []
  provides: [essentials.elections, essentials.races, essentials.race_candidates, essentials.offices.faces_retention_vote]
  affects: [Phase 98 import pipeline, Phase 99 election endpoints, Phase 100 filter UI]
tech_stack:
  added: []
  patterns: [BEGIN/COMMIT migration wrapping, IF NOT EXISTS idempotency, partial indexes, PostgreSQL CHECK constraints]
key_files:
  created:
    - ev-accounts/backend/migrations/042_election_schema.sql
    - ev-accounts/backend/migrations/043_faces_retention_vote.sql
  modified: []
decisions:
  - "election_date uses PostgreSQL date type (not text) to enable countdown arithmetic in Phase 99"
  - "race_candidates.politician_id is optional FK — NULL for challengers, linked for incumbents (D-05)"
  - "faces_retention_vote lives on essentials.offices not politicians — property of the seat (D-10)"
  - "Partial unique index on external_id WHERE NOT NULL preserves SoS filing ID uniqueness without blocking null challengers"
metrics:
  duration: "~2 minutes"
  completed: "2026-03-29"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 97 Plan 01: Election Schema Foundation Summary

**One-liner:** PostgreSQL election schema (elections → races → race_candidates with antipartisan FK hierarchy) plus faces_retention_vote column on offices with Indiana appellate court flagging.

## What Was Built

### Migration 042: Election Schema (`ev-accounts/backend/migrations/042_election_schema.sql`)

Three new tables in the `essentials` schema, wrapped in BEGIN/COMMIT with full IF NOT EXISTS idempotency:

**`essentials.elections`** — the election event:
- `election_date date NOT NULL` — PostgreSQL date type (enables countdown arithmetic, avoids legacy election_records text anti-pattern)
- `election_type text NOT NULL CHECK (IN ('primary','general','retention','special'))`
- `jurisdiction_level text NOT NULL CHECK (IN ('federal','state','county','city','district'))`
- `state character(2)` nullable for multi-state federal elections

**`essentials.races`** — position within an election:
- FK to `essentials.elections(id) ON DELETE CASCADE`
- Optional FK to `essentials.offices(id)` — nullable for races without existing office records
- `position_name text NOT NULL` — display name for voter-facing UI

**`essentials.race_candidates`** — person running in a race:
- FK to `essentials.races(id) ON DELETE CASCADE`
- Optional FK to `essentials.politicians(id)` — NULL for challengers, linked for incumbents (D-05)
- `candidate_status text NOT NULL DEFAULT 'active' CHECK (IN ('active','withdrawn','filed'))` per D-06
- `last_verified_at`, `source`, `external_id` for data freshness tracking
- Zero party columns — antipartisan exclusion enforced at schema layer

**8 indexes:** election_date, state, election_id, office_id, race_id, politician_id (partial WHERE NOT NULL), candidate_status, external_id (partial unique WHERE NOT NULL).

Migration includes explicit antipartisan rationale comment, distinction from legacy `essentials.election_records` table, and isolation warning against geofence search path contamination.

### Migration 043: Retention Vote Flag (`ev-accounts/backend/migrations/043_faces_retention_vote.sql`)

**Column addition:**
```sql
ALTER TABLE essentials.offices
  ADD COLUMN IF NOT EXISTS faces_retention_vote boolean NOT NULL DEFAULT false;
```

**COMMENT ON COLUMN** explains purpose, qualifying Indiana courts, and distinction from `essentials.districts.retention` (BallotReady geofence data vs operational filter flag).

**Indiana appellate court flagging:**
```sql
UPDATE essentials.offices o
SET faces_retention_vote = true
FROM essentials.chambers ch
JOIN essentials.governments g ON g.id = ch.government_id
WHERE o.chamber_id = ch.id
  AND g.state = 'IN'
  AND o.is_appointed_position = true
  AND (
    ch.name ILIKE '%supreme court%'
    OR ch.name ILIKE '%court of appeals%'
    OR ch.name ILIKE '%tax court%'
  );
```

Only Supreme Court, Court of Appeals, and Tax Court flagged. Circuit and Superior courts excluded (run in partisan elections, not retention).

Verification query included as SQL comment for manual post-migration review.

## Decisions Made

1. **election_date as PostgreSQL `date` type** — Not `text` as in legacy `election_records`. Enables date arithmetic for Phase 99 countdown display.
2. **Partial index on `politician_id WHERE NOT NULL`** — Most race_candidates are challengers (NULL politician_id). Partial index avoids indexing NULLs, reducing index size and write overhead.
3. **Partial unique index on `external_id WHERE NOT NULL`** — Challenger records have no SoS filing ID. Partial unique enforces deduplication only when the ID is present.
4. **`faces_retention_vote` on offices not politicians** (D-10 confirmed) — Property of the seat; new appointments automatically inherit the flag.
5. **Indiana appellate only** (D-11 confirmed) — Official Indiana Courts website confirms only Supreme Court, Court of Appeals, Tax Court face retention votes.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None. These are schema-only migrations. No data is hardcoded; the UPDATE for Indiana courts queries live chamber/government data.

## Self-Check: PASSED

Files created:
- `ev-accounts/backend/migrations/042_election_schema.sql` — FOUND
- `ev-accounts/backend/migrations/043_faces_retention_vote.sql` — FOUND

Commits:
- `7cdde20` feat(97-01): create election schema migration 042 — FOUND
- `1a86259` feat(97-01): create faces_retention_vote migration 043 — FOUND
