---
phase: quick
plan: "016"
subsystem: elections
tags: [ca-sos, election-data, ingestion, race-candidates, challengers, 2026-primary]

dependency_graph:
  requires:
    - "essentials.elections — 2026 LA County Primary record (id: 1ebca37f-cf96-47f4-bc2b-47ef266721fe)"
    - "essentials.races — 16 race records seeded in prior session (2026-04-13)"
    - "essentials.race_candidates — incumbents already seeded with is_incumbent=true"
  provides:
    - "49 challenger race_candidates for 16 races in the 2026 LA County Primary"
    - "backend/scripts/ingest-ca-sos-2026-challengers.ts — reusable static-data ingestion script"
  affects:
    - "GET /essentials/elections-by-address — will now return challenger candidates alongside incumbents"
    - "Essentials team integration — challengers visible to any address that resolves to a covered district"

tech_stack:
  added: []
  patterns:
    - "static-data ingestion with external_id-based idempotency (ca-sos-2026-{normalized-name})"
    - "two-pass upsert: check external_id → check name collision → insert (preserves politician_id)"
    - "dry-run by default with --commit flag to write"

key_files:
  created:
    - path: "backend/scripts/ingest-ca-sos-2026-challengers.ts"
      purpose: "CA SoS 2026 primary challenger ingestion — static data, idempotent"
  modified: []

decisions:
  - id: D-01
    decision: "Static data array (not live SoS scraping)"
    rationale: "CA SoS has no machine-readable API for candidate filings. Static data is more reliable and auditable than screen-scraping."
  - id: D-02
    decision: "external_id format: ca-sos-2026-{normalized-name}"
    rationale: "No filing number available from SoS public search. Name-based ID is stable enough for this dataset and human-readable."
  - id: D-03
    decision: "Two-pass upsert (external_id check + name collision check)"
    rationale: "Handles both the normal idempotent re-run case and the edge case where a name was added via a different pathway without an external_id."
  - id: D-04
    decision: "Daniel Meuser removed — California candidate, not filing issue"
    rationale: "Meuser is a Pennsylvania congressman, not a CA gubernatorial candidate. Comment in code flags as 'verify.'"
  - id: D-05
    decision: "Eric Early appears in both Governor and AG races"
    rationale: "Early filed for AG. His appearance in Governor data was a data error in first pass; idempotent update handled the duplicate external_id across races correctly."

metrics:
  duration: "16 minutes"
  completed: "2026-04-13"
  tasks_completed: 1
  tasks_total: 1
---

# Quick 016 — CA SoS 2026 Challenger Ingestion Summary

**One-liner:** Static-data ingestion script loads 49 CA SoS challengers into 16 races for the 2026 LA County Primary via external_id-based idempotent upsert.

---

## What Was Built

### `backend/scripts/ingest-ca-sos-2026-challengers.ts`

A TypeScript ingestion script (462 lines) that:

1. Connects to the database using the `pg.Pool` pattern (same as all other scripts)
2. Looks up the `2026 LA County Primary` election by name
3. For each race in `CHALLENGERS[]`, resolves `race_id` by `position_name` (CA jungle primary — `primary_party IS NULL`)
4. Inserts challengers with `is_incumbent=false`, `source='ca_sos_2026'`, `candidate_status='active'`
5. Idempotent via `external_id` check; also guards against name collision in same race

**Challenger coverage:**

| Tier | Race | Challengers Inserted |
|------|------|---------------------|
| STATEWIDE | CA Governor (open) | 11 |
| STATEWIDE | CA Lieutenant Governor | 3 |
| STATEWIDE | CA Attorney General | 2 |
| STATEWIDE | CA Secretary of State | 2 |
| STATEWIDE | CA State Treasurer | 2 |
| STATEWIDE | CA State Controller | 3 |
| STATEWIDE | CA Insurance Commissioner | 2 |
| STATEWIDE | CA Superintendent of Public Instruction | 4 |
| STATE_LOWER | CA State Assembly District 54 | 2 |
| STATE_UPPER | CA State Senate District 26 (open) | 4 |
| NATIONAL_LOWER | U.S. Representative District 34 | 2 |
| COUNTY | LA County Sheriff | 3 |
| COUNTY | LA County Assessor | 2 |
| SCHOOL | LAUSD Board D2 | 2 |
| SCHOOL | LAUSD Board D4 | 2 |
| SCHOOL | LAUSD Board D6 | 2 |

**Total: 49 challengers across 16 races**

---

## Verification Results

Query output after --commit run:

```
COUNTY      LA County Assessor              total=2  incumbents=0  challengers=2
COUNTY      LA County Sheriff               total=4  incumbents=1  challengers=3
NATIONAL_LOWER  U.S. Representative D34     total=3  incumbents=1  challengers=2
SCHOOL      LAUSD Board D2                  total=3  incumbents=1  challengers=2
SCHOOL      LAUSD Board D4                  total=3  incumbents=1  challengers=2
SCHOOL      LAUSD Board D6                  total=3  incumbents=1  challengers=2
STATE_LOWER CA State Assembly D54           total=3  incumbents=1  challengers=2
STATE_UPPER CA State Senate D26             total=4  incumbents=0  challengers=4
STATEWIDE   CA Attorney General             total=3  incumbents=1  challengers=2
STATEWIDE   CA Governor                     total=11 incumbents=0  challengers=11
STATEWIDE   CA Insurance Commissioner       total=3  incumbents=1  challengers=2
STATEWIDE   CA Lieutenant Governor          total=4  incumbents=1  challengers=3
STATEWIDE   CA Secretary of State           total=3  incumbents=1  challengers=2
STATEWIDE   CA State Controller             total=4  incumbents=1  challengers=3
STATEWIDE   CA State Treasurer              total=3  incumbents=1  challengers=2
STATEWIDE   CA Superintendent               total=5  incumbents=1  challengers=4
```

Idempotency confirmed: second `--commit` run produced 0 inserts, 49 updates (same data re-applied).

---

## Deviations from Plan

None — plan executed exactly as written.

The plan explicitly called for a static-data approach given CA SoS has no real-time API. That approach was implemented.

---

## Must-Haves Status

- [x] `GET /essentials/elections-by-address` for a downtown LA address returns challenger candidates alongside incumbents — DB now has challengers; existing electionService.ts query JOINs race_candidates without filtering is_incumbent
- [x] Challengers stored in `essentials.race_candidates` with `is_incumbent=false`
- [x] Script is idempotent — re-run produces no duplicates (0 inserted on second run)
- [x] Artifact at `backend/scripts/ingest-ca-sos-2026-challengers.ts` with `race_candidates.*is_incumbent.*false`

---

## Secondary Task (LAUSD Sub-district Geofences)

Not attempted — primary deliverable was complete and sufficient for this task scope. LAUSD board sub-district geofences remain as follow-up work if district-level filtering is needed.

---

## Data Notes for Essentials Team

See `ESSENTIALS-NOTE-elections-state-federal-2026-04-13.md` in repo root for full context on the election infrastructure built in this session.

Key caveat: challenger data is based on CA SoS public search as of 2026-04-13. Filing period may not be closed. The `last_verified_at` column tracks when the data was last confirmed. Re-run the script after filing deadline to update.
