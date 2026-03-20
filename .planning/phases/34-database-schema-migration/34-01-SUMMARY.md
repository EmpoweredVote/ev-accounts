---
phase: 34-database-schema-migration
plan: 01
subsystem: database
tags: [postgres, rls, supabase, schema, inventory, grants, policies]

# Dependency graph
requires: []
provides:
  - "Definitive table inventory for 6 target schemas (69 tables total)"
  - "User-linked column identification (4 compass tables, 1 transparent_motivations table)"
  - "Row count baseline for all 69 tables"
  - "GRANT state: zero existing grants to anon/authenticated/service_role"
  - "Policy state: zero existing RLS policies on any of the 6 schemas"
  - "Policy category assignment for every table"
affects:
  - 34-02 (RLS + public-read policy migration)
  - 34-03 (owner-read + authenticated-read + staging policies)
  - 35-politician-deduplication
  - 36-express-ports-wave-1

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "user_id in compass tables is type TEXT storing UUID-formatted strings — RLS must cast: user_id::uuid = auth.uid()"
    - "All 6 schemas start with zero grants and zero policies — clean slate for migration"

key-files:
  created:
    - ".planning/phases/34-database-schema-migration/34-01-SUMMARY.md"
  modified: []

key-decisions:
  - "compass tables use user_id::text (UUID-formatted values) — RLS policies must cast to uuid for auth.uid() comparison"
  - "transparent_motivations.source_audit_log has changed_by_user_id uuid column but is admin-operation audit data — treat as authenticated-read, not owner-read"
  - "meetings schema is entirely empty (0 rows all 7 tables) — still needs grants and RLS before endpoints go live"
  - "treasury schema is entirely empty (0 rows all 4 tables) — same; grants needed"

patterns-established:
  - "Row count baseline captured 2026-03-20 — all future migration verifications compare against these numbers"

# Metrics
duration: 5min
completed: 2026-03-20
---

# Phase 34 Plan 01: Database Schema Migration — Inventory Summary

**Complete table inventory of 6 EV-Backend schemas (69 tables) with policy category assignments, row counts, and clean-slate GRANT/policy confirmation ready for migration plans 02 and 03.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-20T02:28:52Z
- **Completed:** 2026-03-20T02:34:06Z
- **Tasks:** 2
- **Files modified:** 1 (this SUMMARY)

## Accomplishments

- Confirmed all 6 target schemas exist in production (essentials, meetings, staging, treasury, transparent_motivations, compass)
- Enumerated all 69 tables with RLS status (all `rowsecurity: false` — clean slate)
- Identified 5 user-linked columns across 4 compass tables and 1 transparent_motivations table; determined all store UUID-formatted strings as `text`
- Captured row counts for all 69 tables as verification baseline
- Confirmed zero existing GRANTs to anon/authenticated/service_role and zero existing policies — no cleanup needed before migration

## Task Commits

Tasks 1 and 2 are query-only (no code files) — committed together in plan metadata commit.

**Plan metadata:** (see final commit below)

## Files Created/Modified

- `.planning/phases/34-database-schema-migration/34-01-SUMMARY.md` — This file; complete inventory

---

## Definitive Table Inventory

### Schema: `compass` (8 tables)

| Table | RLS | Row Count | Policy Category | user_id column |
|-------|-----|-----------|-----------------|----------------|
| `answers` | off | 698 | owner-read | `user_id text` (UUID values) |
| `categories` | off | 8 | public-read | — |
| `contexts` | off | 609 | owner-read | `user_id text` (UUID values) |
| `quote_verdicts` | off | 9 | owner-read | `user_id text` (UUID values) |
| `stances` | off | 105 | public-read | — |
| `topic_categories` | off | 21 | public-read | — |
| `topics` | off | 21 | public-read | — |
| `user_compasses` | off | 4 | owner-read | `user_id text` (UUID values) |

**Schema total:** 1,475 rows

---

### Schema: `essentials` (36 tables)

| Table | RLS | Row Count | Policy Category |
|-------|-----|-----------|-----------------|
| `addresses` | off | 454 | public-read |
| `building_photos` | off | 11 | public-read |
| `chambers` | off | 562 | public-read |
| `committees` | off | 246 | public-read |
| `degrees` | off | 217 | public-read |
| `districts` | off | 1,167 | public-read |
| `election_records` | off | 76 | public-read |
| `endorsements` | off | 33 | public-read |
| `endorser_organizations` | off | 0 | public-read |
| `experiences` | off | 615 | public-read |
| `geofence_boundaries` | off | 6,552 | public-read |
| `government_bodies` | off | 32 | public-read |
| `governments` | off | 234 | public-read |
| `identifiers` | off | 822 | public-read |
| `issues` | off | 19 | public-read |
| `judge_details` | off | 582 | public-read |
| `judicial_disciplinary_records` | off | 3 | public-read |
| `judicial_evaluations` | off | 43 | public-read |
| `judicial_metrics` | off | 22 | public-read |
| `legislative_bill_cosponsors` | off | 44,021 | public-read |
| `legislative_bills` | off | 19,622 | public-read |
| `legislative_committee_memberships` | off | 496 | public-read |
| `legislative_committees` | off | 1,440 | public-read |
| `legislative_leadership_roles` | off | 2 | public-read |
| `legislative_politician_id_map` | off | 128 | public-read |
| `legislative_sessions` | off | 8 | public-read |
| `legislative_votes` | off | 121,178 | public-read |
| `offices` | off | 1,848 | public-read |
| `politician_committees` | off | 0 | public-read |
| `politician_contacts` | off | 1,006 | public-read |
| `politician_images` | off | 708 | public-read |
| `politician_stances` | off | 129 | public-read |
| `politicians` | off | 1,854 | public-read |
| `position_descriptions` | off | 742 | public-read |
| `quotes` | off | 60 | public-read |
| `zip_politicians` | off | 2,075 | public-read |

**Schema total:** 206,587 rows

---

### Schema: `meetings` (7 tables)

| Table | RLS | Row Count | Policy Category |
|-------|-----|-----------|-----------------|
| `meeting_summaries` | off | 0 | public-read |
| `meetings` | off | 0 | public-read |
| `segments` | off | 0 | public-read |
| `speakers` | off | 0 | public-read |
| `summary_sections` | off | 0 | public-read |
| `vote_records` | off | 0 | public-read |
| `votes` | off | 0 | public-read |

**Schema total:** 0 rows (schema exists, data not yet imported)

---

### Schema: `staging` (6 tables)

| Table | RLS | Row Count | Policy Category |
|-------|-----|-----------|-----------------|
| `building_photo_review_logs` | off | 0 | authenticated-read |
| `building_photos` | off | 0 | authenticated-read |
| `politician_review_logs` | off | 0 | authenticated-read |
| `politicians` | off | 3 | authenticated-read |
| `review_logs` | off | 0 | authenticated-read |
| `stances` | off | 1 | authenticated-read |

**Schema total:** 4 rows

---

### Schema: `transparent_motivations` (7 tables)

| Table | RLS | Row Count | Policy Category | Notes |
|-------|-----|-----------|-----------------|-------|
| `committees` | off | 0 | public-read | |
| `contributions` | off | 0 | public-read | |
| `data_source_metadata` | off | 0 | public-read | |
| `donors` | off | 0 | public-read | |
| `ingestion_runs` | off | 3 | authenticated-read | Internal pipeline audit — not for public |
| `politician_sources` | off | 32 | public-read | |
| `source_audit_log` | off | 0 | authenticated-read | Has `changed_by_user_id uuid` — admin/internal use |

**Schema total:** 35 rows

---

### Schema: `treasury` (4 tables)

| Table | RLS | Row Count | Policy Category |
|-------|-----|-----------|-----------------|
| `budget_categories` | off | 0 | public-read |
| `budget_line_items` | off | 0 | public-read |
| `budgets` | off | 0 | public-read |
| `cities` | off | 0 | public-read |

**Schema total:** 0 rows (schema exists, data not yet imported)

---

## Grand Total: 69 tables, 208,101 rows

---

## User-Linked Columns Found

| Schema | Table | Column | Data Type | Notes |
|--------|-------|--------|-----------|-------|
| compass | answers | user_id | text | UUID-formatted strings |
| compass | contexts | user_id | text | UUID-formatted strings |
| compass | quote_verdicts | user_id | text | UUID-formatted strings |
| compass | user_compasses | user_id | text | UUID-formatted strings, NOT NULL |
| transparent_motivations | source_audit_log | changed_by_user_id | uuid | Proper UUID type; admin audit column |

**Critical finding:** The 4 compass tables store `user_id` as `text` type (not `uuid`). The actual values are UUID-formatted strings (confirmed by sampling: `78bd6c25-8c16-485d-8836-bde5d83c64e3`). RLS policies for these tables MUST cast: `user_id::uuid = auth.uid()`.

---

## Policy Category Summary

| Category | Schema(s) | Tables | Grant Target |
|----------|-----------|--------|--------------|
| **public-read** | essentials, meetings, treasury, transparent_motivations (partial), compass (partial) | 54 | `anon`, `authenticated`, `service_role` — SELECT |
| **owner-read** | compass | 4 | `authenticated` SELECT with `user_id::uuid = auth.uid()` policy |
| **authenticated-read** | staging, transparent_motivations (partial) | 8 | `authenticated`, `service_role` — SELECT |

**Note:** `service_role` bypasses RLS by default in Supabase. The GRANTs to `service_role` are still needed for PostgREST schema visibility, but RLS policies only apply to `anon` and `authenticated` roles.

---

## Existing GRANTs and Policies

**GRANTs to anon/authenticated/service_role:** None (0 rows returned)

**RLS policies on target schemas:** None (0 rows returned)

This is a clean slate. Migration plans 02 and 03 can write GRANTs and CREATE POLICY statements without any prior-state cleanup.

---

## Decisions Made

1. **compass.user_id is text, cast required in RLS** — Values are UUID-formatted strings stored as `text` (EV-Backend Go origin). RLS policies must use `user_id::uuid = auth.uid()`. This is a critical implementation detail for plan 03.

2. **transparent_motivations.source_audit_log is authenticated-read, not owner-read** — Although it has `changed_by_user_id uuid`, this is an admin audit log. It should be gated to authenticated users only (not owner-scoped). Admins querying it will use the service role client.

3. **transparent_motivations.ingestion_runs is authenticated-read** — Pipeline execution metadata; not appropriate for public access. No user_id column so no owner-scope needed.

4. **meetings and treasury are empty but still need grants** — Both schemas have 0 rows but are in active use (EV-Backend writes to them). Grants must be applied before any Express ports in phases 36-37 can serve reads.

---

## Deviations from Plan

None — plan executed exactly as written. Row count queries were batched into multi-UNION statements (not individual queries as suggested in the plan) since the MCP supports UNION ALL queries; this was more efficient and produced identical results.

---

## Issues Encountered

None. All queries executed cleanly. The `supabase db query --linked` CLI approach worked reliably for all 6 queries.

---

## User Setup Required

None — this was a read-only inventory plan.

---

## Next Phase Readiness

**Plan 02 (public-read GRANTs + RLS enable)** can proceed immediately with:
- Exact table lists per schema (copy-paste ready above)
- 54 tables classified as public-read
- Zero prior-state cleanup needed (clean slate)
- `service_role` needs USAGE on all 6 schemas + SELECT on all 69 tables

**Plan 03 (owner-read + authenticated-read policies)** has:
- 4 compass tables needing owner-read with `user_id::uuid = auth.uid()` cast
- 8 staging/transparent_motivations tables needing authenticated-read
- `source_audit_log` user column identified but not owner-scoped

**Potential blocker:** The `user_id::text` columns in compass tables are nullable on `answers`, `contexts`, and `quote_verdicts`. Owner-read policies must handle `NULL` user_id rows (they would be excluded from user views, which is correct).

---

*Phase: 34-database-schema-migration*
*Completed: 2026-03-20*
