---
phase: 25-deployment-runbook-completion
verified: 2026-03-15T07:40:00Z
status: passed
score: 3/3 must-haves verified
---

# Phase 25: Deployment Runbook Completion — Verification Report

**Phase Goal:** applyMigrations.ts and DEPLOY.md cover the full migration set (030–036) so a cold-start re-deploy succeeds without manual intervention — satisfying the DEPLOY-02 success criterion.
**Verified:** 2026-03-15T07:40:00Z
**Status:** passed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | backend/migrations/ contains 034, 035, and 036, each a verbatim copy of its supabase/migrations/ counterpart | VERIFIED | `diff` of all three pairs returned empty output — byte-for-byte identical |
| 2 | DEPLOY.md Step 2 explicitly lists all 11 migrations 026–036 in apply order, manual psql fallback, post-apply verification queries, and per-migration rollback SQL | VERIFIED | Lines 102, 128–138, 146–199, 277–370 cover every migration end-to-end |
| 3 | applyMigrations.ts MIGRATIONS array has 11 entries (026–036), each with a PRE_VERIFY and POST_VERIFY query, and every referenced file exists on disk | VERIFIED | 11 MIGRATIONS entries confirmed; 11 PRE_VERIFY + 11 POST_VERIFY keys confirmed; all 11 files exist in backend/migrations/ at substantive line counts |

**Score:** 3/3 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/migrations/034_gem_idempotency.sql` | Present, verbatim copy of supabase counterpart | VERIFIED | 206 lines; diff vs supabase/migrations/20260314000034_phase22_gems_idempotency.sql: empty |
| `backend/migrations/035_tier_promotion.sql` | Present, verbatim copy of supabase counterpart | VERIFIED | 157 lines; diff vs supabase/migrations/20260314000035_phase23_tier_promotion.sql: empty |
| `backend/migrations/036_signup_with_invite.sql` | Present, verbatim copy of supabase counterpart | VERIFIED | 108 lines; diff vs supabase/migrations/20260314000036_phase24_signup_with_invite.sql: empty |
| `backend/scripts/applyMigrations.ts` | 11 MIGRATIONS entries with full PRE/POST verify coverage | VERIFIED | 143 lines; `{ file: '026'...}` through `{ file: '036'...}` (11 entries); PRE_VERIFY_QUERIES and POST_VERIFY_QUERIES both contain keys '026'–'036' |
| `DEPLOY.md` | Step 2 covers 026–036 apply order, psql fallback, verification queries, rollback | VERIFIED | 389 lines; explicit sequential apply order line 102; all 11 psql commands lines 128–138; all 11 post-apply queries lines 146–199; all 11 rollback sections lines 277–370 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| applyMigrations.ts MIGRATIONS array | backend/migrations/034_gem_idempotency.sql | `path.resolve(cwd, 'backend', 'migrations', file)` | WIRED | File referenced by label '034' and file exists at that path |
| applyMigrations.ts MIGRATIONS array | backend/migrations/035_tier_promotion.sql | `path.resolve(cwd, 'backend', 'migrations', file)` | WIRED | File referenced by label '035' and file exists at that path |
| applyMigrations.ts MIGRATIONS array | backend/migrations/036_signup_with_invite.sql | `path.resolve(cwd, 'backend', 'migrations', file)` | WIRED | File referenced by label '036' and file exists at that path |
| PRE_VERIFY_QUERIES['034'] | connect.award_gems | `SELECT proname FROM pg_proc WHERE proname='award_gems'` | WIRED | Migration 034 creates `connect.award_gems`; query checks pg_proc for that name |
| PRE_VERIFY_QUERIES['035'] | connect.promote_to_connected | `SELECT proname FROM pg_proc WHERE proname='promote_to_connected'` | WIRED | Migration 035 creates `connect.promote_to_connected`; query checks pg_proc for that name |
| PRE_VERIFY_QUERIES['036'] | connect.signup_with_invite | `SELECT proname FROM pg_proc WHERE proname='signup_with_invite'` | WIRED | Migration 036 creates `connect.signup_with_invite`; query checks pg_proc for that name |
| DEPLOY.md Step 2 apply sequence | backend/migrations/034–036 | psql -f commands | WIRED | Lines 136–138 list all three files by exact path |

---

### Anti-Patterns Found

None. No TODO/FIXME/placeholder patterns found in any of the five modified files. Migration SQL is substantive DDL. applyMigrations.ts has real implementation throughout. DEPLOY.md is a complete operational document with no stubs.

---

### Human Verification Required

One item requires human execution — not blocking automated verification, but required before Alpha launch:

**1. Live DB cold-start run**

**Test:** Set `DATABASE_URL` to the direct Supabase connection (port 5432) and run `npx tsx backend/scripts/applyMigrations.ts` against a fresh or partially-applied production database.

**Expected:** Each migration prints `[NNN] OK` or `[NNN] SKIP — already applied`; script exits 0; all 12 post-apply queries in DEPLOY.md Step 2 return exactly 1 row in Supabase SQL Editor.

**Why human:** Cannot execute against the live Supabase instance programmatically from this verification context. Structural verification (file existence, array completeness, SQL content correctness) has been confirmed; runtime behavior against a real Postgres instance with PostGIS and pgcrypto extensions requires a human operator.

---

## Summary

All three automated criteria pass:

1. **Migration files 034–036 exist and match supabase counterparts.** Byte-for-byte verified via `diff`. No drift between the deployment-era files and the Supabase-managed baseline.

2. **DEPLOY.md is a complete cold-start runbook.** All 11 migrations are listed in the canonical apply order (line 102), the psql fallback (lines 128–138), the post-apply verification query block (lines 146–199), and individual rollback sections (lines 277–370). Step 1b documents the mandatory PostgREST schema config that the dashboard UI does not reliably apply.

3. **applyMigrations.ts covers the full 026–036 set.** Exactly 11 entries in the MIGRATIONS array; every entry has a corresponding PRE_VERIFY and POST_VERIFY query; all 11 referenced SQL files exist on disk at substantive line counts. The pre-verify pattern (0 rows = not applied, proceed; 1+ rows = skip) makes the script safe to re-run against any partially-applied database.

The DEPLOY-02 success criterion — cold-start re-deploy succeeds without manual intervention — is satisfied at the structural level. The single human-verification item (live DB run) is an operational gate, not a code gap.

---

_Verified: 2026-03-15T07:40:00Z_
_Verifier: Claude (gsd-verifier)_
