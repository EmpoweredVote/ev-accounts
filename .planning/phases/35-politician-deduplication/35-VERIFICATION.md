---
phase: 35-politician-deduplication
verified: 2026-03-20T06:13:50Z
status: passed
score: 4/4 must-haves verified
re_verification:
  previous_status: gaps_found
  previous_score: 3/4
  gaps_closed:
    - "All join paths resolve to essentials.politicians"
  gaps_remaining: []
  regressions: []
---

# Phase 35: Politician Deduplication -- Verification Report

**Phase Goal:** essentials.politicians is the single source of truth for all politician records.
**Verified:** 2026-03-20T06:13:50Z
**Status:** passed
**Re-verification:** Yes -- after gap closure (commit d7af2a4)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | public.politician_id_bridge exists with 30 rows mapping inform IDs to essentials IDs | VERIFIED | Migration 20260320000050_phase35_politician_deduplication.sql creates table with 30 rows (4 identity-insert + 26 name-match). Applied per commit 5931936. Orphan-check DO block would raise exceptions if any FK values failed. |
| 2 | GET /api/compass/politicians/:id/answers returns correct stances | VERIFIED | compassService.getPoliticianAnswers() queries inform.politician_answers. Migration updated all 588 FK values from inform IDs to essentials IDs. Orphan check = zero orphaned rows. |
| 3 | inform.politicians does not exist; all code paths resolve to essentials.politicians | VERIFIED | Migration drops inform.politicians. profileService.ts lines 244-277 now use pool.query() targeting essentials.politicians (fixed in commit d7af2a4). No inform.politicians references remain. |
| 4 | confirm_vq_stance validates politician against essentials.politicians | VERIFIED | Migration Step 8 rebuilds connect.confirm_vq_stance with FROM essentials.politicians p WHERE p.id = p_politician_id. SECURITY DEFINER, SET search_path empty, fully-qualified. |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| supabase/migrations/20260320000050_phase35_politician_deduplication.sql | Atomic deduplication migration | VERIFIED | 200+ lines: bridge table, FK reassignment (3 tables), RPC rebuilds (2), orphan checks, DROP TABLE, RLS, grants. |
| public.politician_id_bridge DB table | 30 rows | VERIFIED | 30 rows in migration INSERT. Orphan check confirms FK integrity. |
| backend/src/lib/compassService.ts getCompassPoliticians() | pool.query() to essentials | VERIFIED | Lines 172-188: pool.query() targeting essentials.politicians. |
| backend/src/lib/essentialsService.ts getPoliticiansGrouped() | pool.query() to essentials | VERIFIED | Lines 81-106: pool.query() targeting essentials.politicians. PostgREST import removed. |
| backend/src/lib/adminService.ts adminSetPoliticianContext() | pool.query() | VERIFIED | Lines 389-398: pool.query() INSERT ON CONFLICT. PostgREST anti-pattern eliminated. |
| backend/src/lib/adminService.ts adminCreatePolitician()/adminUpdatePolitician() | essentials via pool.query() | VERIFIED | Lines 478-499 and 539-542: pool.query() targeting essentials.politicians. |
| scripts/seedPoliticians.ts | Targets essentials.politicians | PARTIAL | Updated to essentials schema. Uses PostgREST .schema(essentials) -- essentials not exposed; execution fails. Dev-only per JSDoc. |
| backend/src/lib/profileService.ts | Updated to query essentials.politicians | VERIFIED | Fixed in commit d7af2a4. Lines 244-277 now use pool.query() on essentials.politicians, selecting correct column set (id, first_name, last_name, preferred_name, full_name, photo_origin_url, is_active, is_incumbent, is_vacant, party, party_short_name, slug, bio_text). No inform reference remains. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| inform.politician_answers | essentials.politicians | FK constraint | VERIFIED | Steps 4/5/7: drop old FK, update 588 rows, re-add FK to essentials.politicians. |
| inform.politician_context | essentials.politicians | FK constraint | VERIFIED | Steps 4/6/7: same pattern, 500 rows migrated. |
| empower.empowered_profiles | essentials.politicians | FK constraint | VERIFIED | Undocumented dependency found during apply. All values NULL -- no data migration needed. |
| connect.confirm_vq_stance | essentials.politicians | SELECT EXISTS in RPC | VERIFIED | Step 8 RPC body references essentials.politicians. |
| public.admin_list_politicians | essentials.politicians | SELECT FROM in function | VERIFIED | Step 9 function body queries essentials.politicians. |
| profileService.ts empowered profile lookup | essentials.politicians | pool.query() | VERIFIED | Fixed in commit d7af2a4. Lines 244-277 use pool.query() targeting essentials.politicians. No inform reference. |

### Requirements Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| Bridge table with 30-row mapping | SATISFIED | All 30 politicians mapped. |
| inform.politicians dropped | SATISFIED | DROP TABLE in migration Step 11. |
| FK reassignment on 3 tables | SATISFIED | politician_answers, politician_context, empowered_profiles all updated. |
| confirm_vq_stance references essentials | SATISFIED | RPC rebuilt in Step 8. |
| All application code reads from essentials | SATISFIED | profileService.ts gap closed in commit d7af2a4. All read paths target essentials.politicians. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| scripts/seedPoliticians.ts | 135-139 | .schema(essentials).from(politicians) via PostgREST -- essentials not exposed | Warning | Script fails if run; dev-only per JSDoc. |

The previous blocker (profileService.ts querying dropped inform.politicians table) is resolved.

### Gap Fix Note

**Commit d7af2a4** updated `backend/src/lib/profileService.ts` lines 244-277 from `supabaseAdmin.schema('inform').from('politicians')` (PostgREST, broken against dropped table) to `pool.query()` targeting `essentials.politicians`. Column set correctly maps to essentials schema: id, first_name, last_name, preferred_name, full_name, photo_origin_url, is_active, is_incumbent, is_vacant, party, party_short_name, slug, bio_text. Inform-specific columns (office_title, is_candidate, representing_city, district_type, district_label, district_id, chamber_name, chamber_name_formal, government_name) correctly excluded.

---

_Verified: 2026-03-20T06:13:50Z_
_Verifier: Claude (gsd-verifier)_
