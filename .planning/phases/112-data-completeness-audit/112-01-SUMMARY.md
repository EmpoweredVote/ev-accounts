---
phase: 112-data-completeness-audit
plan: "01"
subsystem: audit-scripts
tags: [audit, elections, data-completeness, scripts]
dependency_graph:
  requires: []
  provides: [BALLOT-BASELINE-2026-05-05, audit-112-races, audit-112-candidates]
  affects: [112-02, 112-03, 112-04]
tech_stack:
  added: []
  patterns: [pg.Pool audit script pattern, dotenv + tsx script runner, CSV-to-stdout pattern]
key_files:
  created:
    - .planning/research/BALLOT-BASELINE-2026-05-05.md
    - ev-accounts/backend/scripts/audit-112-races.ts
    - ev-accounts/backend/scripts/audit-112-candidates.ts
  modified: []
decisions:
  - "Ballot baseline uses HIGH/MEDIUM confidence flags per race level — distinguishes fully verified (official ballot PDFs) from partially verified (press sources)"
  - "State Convention Delegate races explicitly documented as intentional omissions, not data gaps"
  - "Race count comment in script notes expected ~43 denominator so dry-run output is self-explanatory"
  - "County Council District 2 (Kate Wiltz) noted as MEDIUM confidence — no primary contest observed in ballots"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-12"
  tasks_completed: 3
  files_created: 3
requirements: [AUDIT-07, AUDIT-01, AUDIT-02]
---

# Phase 112 Plan 01: Ballot Baseline and Foundational Audit Scripts Summary

**One-liner:** Authoritative Monroe County May 5 2026 ballot baseline with ~43 race slots plus two read-only audit scripts (race coverage and candidate linkage) following the established pg.Pool/tsx/CSV-to-stdout pattern.

---

## What Was Built

### Task 1: Ballot Baseline Document
`.planning/research/BALLOT-BASELINE-2026-05-05.md` — a static reference document extracted directly from official Monroe County Clerk sample ballot PDFs. Covers all race levels: Federal (US Rep D-9), State Legislative (Districts 46, 60, 61, 62), Judicial (Circuit Court Seats 5 and 9), County-Wide (Prosecuting Attorney, Clerk, Recorder, Sheriff, Assessor, Commissioner D-1), County Council (Districts 1-4), Township (11 townships), and Ellettsville Town Council (Wards 4-5). Total denominator: approximately 43 distinct race slots. Includes intentional omissions documentation (State Convention Delegate races are party organizational elections, not civic voter guide content) and HIGH/MEDIUM confidence flags per race level.

### Task 2: Race Coverage Audit Script (AUDIT-01)
`ev-accounts/backend/scripts/audit-112-races.ts` — queries `essentials.elections` + `essentials.races` + `essentials.race_candidates`. Reports position_name, primary_party, candidate_count, linked_to_geofence (Y/N), office_id per race. Validates election existence first and warns on multiple elections. `--dry-run` reports totals without CSV output.

**Live DB output (dry-run):** 1 election found, 46 races (all 46 linked to geofence, 0 unlinked).

### Task 3: Candidate Linkage Audit Script (AUDIT-02)
`ev-accounts/backend/scripts/audit-112-candidates.ts` — reports total_candidates, linked_to_politician, stub_candidates per race. Correctly distinguishes stub candidates (NULL politician_id) from linked politicians — per Pitfall 4 from research, stubs are unlinked entries, not politicians with missing data.

**Live DB output (dry-run):** 46 races, 81 total candidates (51 linked to politician records, 30 stubs), 0 races with zero candidates.

---

## Key Findings from Live DB

| Metric | Value | Notes |
|--------|-------|-------|
| Elections for 2026-05-05 IN | 1 (id: 09fc1b7b) | "2026 Indiana Primary" — assumption A4 confirmed |
| Total races in DB | 46 | vs ~43 expected in baseline — close match |
| Races linked to geofence | 46 (100%) | All races have office_id |
| Unlinked races | 0 | Good — all races geofence-connected |
| Total candidates | 81 | Across all 46 races |
| Linked to politician | 51 (63%) | Have full profile data available |
| Stub candidates | 30 (37%) | No politician_id — stance/quote/profile data N/A |
| Races with zero candidates | 0 | All races have at least one entry |

---

## Commits

### Worktree (planning docs)
- `2b9cf3d`: `feat(112-01): author ballot baseline document for Monroe County May 5 2026 primary`

### ev-accounts repo
- `5043f6d`: `feat(112-01): create race coverage audit script (AUDIT-01)`
- `998517e`: `feat(112-01): create candidate linkage audit script (AUDIT-02)`

---

## Deviations from Plan

None — plan executed exactly as written.

---

## Known Stubs

None — this plan produces static documents and read-only audit scripts with no UI rendering.

---

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced. Scripts are read-only (SELECT only) and load DATABASE_URL via dotenv from `.env` (gitignored). No sensitive data written to stdout — candidate names are public record (official ballot data).

---

## Self-Check

**Files exist:**
- `.planning/research/BALLOT-BASELINE-2026-05-05.md` — FOUND
- `ev-accounts/backend/scripts/audit-112-races.ts` — FOUND
- `ev-accounts/backend/scripts/audit-112-candidates.ts` — FOUND

**Commits exist:**
- `2b9cf3d` — FOUND (worktree)
- `5043f6d` — FOUND (ev-accounts)
- `998517e` — FOUND (ev-accounts)

## Self-Check: PASSED
