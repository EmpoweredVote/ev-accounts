---
phase: quick
plan: "017"
subsystem: elections
tags: [ca-sos, election-data, ingestion, race-candidates, challengers, 2026-primary, assembly-district, idempotent]

dependency_graph:
  requires:
    - "quick-016 — initial challenger ingestion script and 9 Calmatters Governor challengers"
    - "essentials.races — 16+ race records in 2026 LA County Primary with incumbents seeded"
    - "essentials.districts — CA STATE_LOWER sldl:54 and sldl:55 geofences present"
  provides:
    - "124 additional challengers across 13 races (133 total processed, 9 idempotent skips)"
    - "5 incumbent status corrections (withdrawn) for term-limited/cross-running officials"
    - "Assembly District 54/55 discrepancy verified and confirmed resolved"
    - "Complete 2026 LA County Primary challenger field for all statewide, district, and county races"
  affects:
    - "GET /essentials/elections-by-address — now returns full competitive field per race"
    - "Any Essentials team UI displaying candidates for 2026 LA County Primary races"

tech_stack:
  added: []
  patterns:
    - "external_id-based two-pass upsert (check external_id → check name collision → insert)"
    - "INCUMBENT_STATUS_UPDATES array for declarative withdrawn corrections separate from challenger inserts"
    - "dry-run by default, --commit flag to write — verified before committing"

key_files:
  created: []
  modified:
    - path: "backend/scripts/ingest-ca-sos-2026-challengers.ts"
      purpose: "Expanded from 9 initial Governor challengers to 133 candidates across 13 races; adds INCUMBENT_STATUS_UPDATES, full CA SoS + lavote.gov data"

decisions:
  - id: D-01
    decision: "AD-54 vs AD-55 discrepancy was already resolved in DB prior to script execution"
    rationale: "Race record 4bb5149b was already linked to ocd-division/country:us/state:ca/sldl:55 (geo_id 06055) with position_name 'CA State Assembly District 55' and Isaac G. Bryan as incumbent. Script header documents this correction for audit trail."
  - id: D-02
    decision: "5 incumbents set to 'withdrawn' via INCUMBENT_STATUS_UPDATES (not via deletion)"
    rationale: "Soft status change preserves the record while accurately reflecting they are not seeking re-election in this race. Enables historical querying. All 5 confirmed absent from their respective races on the CA SoS certified list or lavote.gov."
  - id: D-03
    decision: "LAUSD Board D2/D4/D6 get no challengers — documented in script comment, not an error"
    rationale: "These races do not appear on the June 2026 primary ballot per CA SoS and lavote.gov. Existing incumbent-only records are for reference. No action needed."
  - id: D-04
    decision: "LA County Assessor: only Stephen A. Adamus inserted (Jeff Prang marked withdrawn)"
    rationale: "Per lavote.gov 2026 filing list (updated 2026-04-10), only Adamus filed. Prang did not seek re-election. This is an open seat with a single candidate (will be uncontested)."

metrics:
  duration: "22 minutes"
  completed: "2026-04-13"
  tasks_completed: 2
  tasks_total: 2
---

# Quick 017 — Import Verified 2026 LA County Primary Challengers (CA SoS Certified List) Summary

**One-liner:** 124 challengers inserted and 5 incumbents corrected to 'withdrawn' across 13 races in the 2026 LA County Primary using CA SoS Certified List (2026-03-26) and lavote.gov (2026-04-10).

---

## What Was Built

### `backend/scripts/ingest-ca-sos-2026-challengers.ts` (expanded)

Significantly expanded the ingestion script from Quick-016's initial 9 Calmatters Governor challengers to a complete data set covering all statewide, state legislative, federal, and county races in the 2026 LA County Primary.

**What changed:**
- Added `INCUMBENT_STATUS_UPDATES` array with 5 declarative corrections for officials not seeking re-election in their current race
- Added CA SoS-sourced challengers for all remaining races (54 additional Governor candidates, 16 Lt. Gov, 2 AG, 3 SoS, 2 Controller, 6 Treasurer, 11 Insurance Commissioner, 10 Superintendent, 8 Senate D26, 5 US Rep D34, 3 Assembly D55)
- Added lavote.gov-sourced challengers for county races (3 Sheriff, 1 Assessor)
- Added data quality note in header confirming AD-55 correction

**Script stats after this run:**
- Total CHALLENGERS array entries: 133
- Races covered: 13 (LAUSD Board D2/D4/D6 intentionally excluded)
- Sources: `calmatters-2026` (9), `ca-sos-2026` (120), `lavote-2026` (4)

---

## Task 1: Assembly District 54/55 Discrepancy — Resolution

**Finding:** The DB race record was already correctly resolved before this script ran.

**Confirmed DB state:**
- Race `4bb5149b` has `position_name = 'CA State Assembly District 55'`
- `office_id` links to district `ff723e47` which has `ocd_id = 'ocd-division/country:us/state:ca/sldl:55'` and `geo_id = '06055'`
- Isaac G. Bryan is the incumbent (`is_incumbent = true`)

**AD-54 status:** District record exists (`ocd_id = ocd-division/country:us/state:ca/sldl:54`, `geo_id = 06054`) but no race record in this election — correct, as Mark Gonzalez is uncontested and not tracked.

**Script header** documents this correction for audit trail in case future readers wonder why the race is named "District 55" when earlier seed data said "District 54."

---

## Task 2: Challenger Ingestion Results

### Commit run output:
```
Challengers inserted: 124
Challengers updated:  0
Challengers skipped (name collision): 9   ← Calmatters Governor challengers already in DB
Challengers skipped (race not found): 0
Incumbent status corrections applied: 5
```

### Idempotency verification (second --commit run):
```
Challengers inserted: 0                   ← CONFIRMED idempotent
Challengers updated:  124
Challengers skipped (name collision): 9
Incumbent corrections not needed: 5
```

---

## Verification Query Results

Statewide races (active candidates only, withdrawn excluded):

| Tier | Race | Total | Inc | Chal |
|------|------|-------|-----|------|
| STATEWIDE | CA Governor | 63 | 0 | 63 |
| STATEWIDE | CA Lieutenant Governor | 16 | 0 | 16 |
| STATEWIDE | CA Attorney General | 3 | 1 | 2 |
| STATEWIDE | CA Secretary of State | 4 | 1 | 3 |
| STATEWIDE | CA State Controller | 3 | 1 | 2 |
| STATEWIDE | CA State Treasurer | 6 | 0 | 6 |
| STATEWIDE | CA Insurance Commissioner | 11 | 0 | 11 |
| STATEWIDE | CA Superintendent of Public Instruction | 10 | 0 | 10 |
| STATE_UPPER | CA State Senate District 26 | 8 | 0 | 8 |
| STATE_LOWER | CA State Assembly District 55 | 4 | 1 | 3 |
| NATIONAL_LOWER | U.S. Representative District 34 | 6 | 1 | 5 |
| COUNTY | LA County Sheriff | 4 | 1 | 3 |
| COUNTY | LA County Assessor | 1 | 0 | 1 |
| SCHOOL | LAUSD Board D2/D4/D6 | 1 each | 1 each | 0 each |

All counts match the CA SoS Certified List expectations from the plan.

---

## Incumbent Status Corrections (5 total)

| Race | Incumbent | Reason |
|------|-----------|--------|
| CA Insurance Commissioner | Ricardo Lara | Term-limited — not on SoS 2026 list |
| CA Lieutenant Governor | Eleni Kounalakis | Running for CA State Treasurer instead |
| CA Superintendent of Public Instruction | Tony Thurmond | Running for CA Governor instead |
| CA State Treasurer | Fiona Ma | Running for CA Lieutenant Governor instead |
| LA County Assessor | Jeff Prang | Not on lavote.gov 2026 filing list |

---

## Deviations from Plan

None — plan executed exactly as written. The AD-54/55 discrepancy was already resolved in the DB (likely during the race seeding session that preceded Quick-016/017), so Task 1 was a verification task only with no corrective SQL needed.

---

## Next Phase Readiness

- The 2026 LA County Primary now has a complete competitive field for all statewide, district, and county races
- `GET /essentials/elections-by-address` will now return the full candidate field for any LA County address
- Essentials team can integrate and display complete race data
- Board of Supervisors District 1-5 (the 5 "plain" ones vs the longer-named LA County Board ones) still have incumbents only — these may be a different race set; worth reviewing if they show up in address queries unexpectedly
- LAUSD Board D2/D4/D6 incumbents remain as reference records — may want to deactivate or hide these races if they are not on the 2026 ballot
