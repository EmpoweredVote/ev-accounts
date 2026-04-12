---
phase: 112-data-completeness-audit
plan: "03"
subsystem: audit-scripts
tags: [audit, elections, geofence, postGIS, data-completeness, scripts, csv, markdown]
dependency_graph:
  requires: [112-01, 112-02]
  provides: [AUDIT-REPORT-112, audit-112-geofence, audit-112-assemble, csv-per-dimension]
  affects: [115-gap-report]
tech_stack:
  added: []
  patterns:
    - "ST_Covers geofence smoke test: spatial query verifies address-to-race resolution end-to-end"
    - "execSync assembler pattern: each dimension script outputs CSV to stdout; assembler captures, saves CSV files, and renders markdown"
    - "Graceful failure handling: try/catch per script; assembler continues if one script fails, writes SCRIPT FAILED in that section"
    - "Pre-geocoded test addresses: Census Geocoder API coordinates hardcoded to avoid runtime external calls"
key_files:
  created:
    - ev-accounts/backend/scripts/audit-112-geofence.ts
    - ev-accounts/backend/scripts/audit-112-assemble.ts
    - .planning/research/AUDIT-REPORT-112.md
    - .planning/research/csv/races.csv
    - .planning/research/csv/candidates.csv
    - .planning/research/csv/stances.csv
    - .planning/research/csv/quotes.csv
    - .planning/research/csv/headshots.csv
    - .planning/research/csv/profile.csv
    - .planning/research/csv/geofence.csv
  modified: []
decisions:
  - "Pre-geocoded coordinates from Census Geocoder API (Public_AR_Current benchmark) hardcoded in geofence script — avoids runtime external API dependency, coordinates are stable for static address test set"
  - "Stance coverage extraction uses pct != '0.0' comparison (not '0.00%') — matches actual script output format (numeric without percent sign)"
  - "Geofence section in assembler rendered with two sub-sections: Resolved Races Per Address and Unlinked Races Not Address-Scoped — mirrors the two-section stdout output of geofence script"
  - "IU Campus address substituted with 1001 E 17th St (Census Geocoder matched) in place of '1 IU Assembly Hall Dr' (no Census match) — same Bloomington Township / D-61 district, functionally equivalent for geofence test"
  - "Ellettsville address substituted with 104 Temperance St (Census Geocoder matched) in place of '101 S Election Rd' (no Census match) — same Ellettsville area, tests Ellettsville Town Council races as intended"
metrics:
  duration: "~25 minutes"
  completed: "2026-04-12"
  tasks_completed: 2
  files_created: 11
requirements: [AUDIT-08, AUDIT-01, AUDIT-02, AUDIT-03, AUDIT-04, AUDIT-05, AUDIT-06]
---

# Phase 112 Plan 03: Geofence Smoke Test and Unified Audit Report Summary

**One-liner:** PostGIS geofence smoke test over 6 Monroe County addresses (25-29 races resolved per Bloomington address) plus an assembler that runs all 7 audit dimension scripts and generates AUDIT-REPORT-112.md with executive summary and per-dimension tables.

---

## What Was Built

### Task 1: Geofence Smoke Test Script (AUDIT-08)
`ev-accounts/backend/scripts/audit-112-geofence.ts` — queries the PostGIS geofence stack for 6 strategically chosen Monroe County addresses. Uses `ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint($lng, $lat), 4326))` to resolve each address to its matching election races. Per Pitfall 5 from research, also runs a separate query for unlinked races (`office_id IS NULL`) which are address-independent and would be invisible to the geofence join.

**Live DB results:**
- Address 1 (Bloomington City Center): 26 races resolved
- Address 2 (Perry Township SE): 29 races resolved
- Address 3 (Clear Creek Township): 25 races resolved
- Address 4 (Richland Township Rural): 26 races resolved
- Address 5 (IU Campus area): 26 races resolved
- Address 6 (Ellettsville): 27 races resolved
- Unlinked races: 0 (all races geofence-connected — consistent with 112-01 finding)

### Task 2: Assembler Script and Unified Audit Report
`ev-accounts/backend/scripts/audit-112-assemble.ts` — runs all 7 dimension scripts via `execSync`, captures stdout CSV, saves individual CSV files to `.planning/research/csv/`, and generates `.planning/research/AUDIT-REPORT-112.md` with executive summary and per-dimension markdown tables.

**Generated report executive summary (live DB):**

| Metric | Value |
|--------|-------|
| Total DB races | 46 (baseline: ~43) |
| Total candidates | 81 (linked: 51, stubs: 30) |
| Stance coverage | 5/51 linked candidates have any stances |
| Quote coverage | 4/51 linked candidates have any quotes |
| Photo coverage | 19 cdn, 0 local, 62 none |
| Profile bio | 0/51 linked candidates have bio |
| Avg contacts per linked candidate | 1.2 |

---

## Commits

### ev-accounts repo
- `79ba8ac`: `feat(112-03): create geofence smoke test script (AUDIT-08)`
- `9b8441f`: `feat(112-03): create audit assembler script that generates unified report`

### Worktree (planning docs)
- `b370f1e`: `feat(112-03): add unified audit report and CSV files for Monroe County May 5 2026 primary`

---

## Deviations from Plan

### Address Substitutions (Rule 1 — Bug Fix)

Two test addresses from the plan spec had no Census Geocoder match (benchmark: Public_AR_Current):
- `1 IU Assembly Hall Dr, Bloomington IN 47405` — no match
- `101 S Election Rd, Ellettsville IN 47429` — no match

**Fix:** Substituted with nearby addresses in the same district:
- IU Campus: `1001 E 17th St, Bloomington IN 47408` (lat=39.179084, lng=-86.521168) — same Bloomington Township / D-61 district as Assembly Hall
- Ellettsville: `104 Temperance St, Ellettsville IN 47429` (lat=39.231254, lng=-86.621252) — same Ellettsville area, tests Ward 4/5 council races as intended

The geofence test purpose (verifying district resolution in the Ellettsville and IU campus areas) is preserved.

### Stance Coverage Extraction Fix (Rule 1 — Bug Fix)

Initial assembler code checked `pct !== '0.00%'` for stance coverage extraction. Actual `audit-112-stances.ts` output format is `80.8` (numeric, no percent sign). Fixed to `pct !== '0.0'`. Without this fix, the executive summary would incorrectly report `51/51 linked candidates have any stances`.

---

## Known Stubs

None — this plan produces audit scripts and documents. No UI rendering.

---

## Threat Flags

No new network endpoints, auth paths, or schema changes. The assembler inherits `DATABASE_URL` from the parent process environment — it never passes the value as a CLI argument (T-112-07 mitigated).

---

## Self-Check

**Files exist:**
- `ev-accounts/backend/scripts/audit-112-geofence.ts` — FOUND
- `ev-accounts/backend/scripts/audit-112-assemble.ts` — FOUND
- `.planning/research/AUDIT-REPORT-112.md` — FOUND
- `.planning/research/csv/races.csv` — FOUND
- `.planning/research/csv/candidates.csv` — FOUND
- `.planning/research/csv/stances.csv` — FOUND
- `.planning/research/csv/quotes.csv` — FOUND
- `.planning/research/csv/headshots.csv` — FOUND
- `.planning/research/csv/profile.csv` — FOUND
- `.planning/research/csv/geofence.csv` — FOUND

**Commits exist:**
- `79ba8ac` — FOUND (ev-accounts: geofence script)
- `9b8441f` — FOUND (ev-accounts: assembler script)
- `b370f1e` — FOUND (worktree: audit report + CSV files)

## Self-Check: PASSED
