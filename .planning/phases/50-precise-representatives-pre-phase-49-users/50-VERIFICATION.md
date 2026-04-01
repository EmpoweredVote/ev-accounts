---
phase: 50-precise-representatives-pre-phase-49-users
verified: 2026-04-01T16:48:33Z
status: passed
score: 12/12 must-haves verified
re_verification: false
---

# Phase 50: Precise Representatives (Pre-Phase-49 Users) — Verification Report

**Phase Goal:** GET /essentials/representatives/me returns the correct district-specific politicians for all Connected users — including those who set their location before Phase 49 shipped and have encrypted_lat/encrypted_lng but null geo_id columns. A new Path 1.5 decrypts stored coordinates via the existing resolve_user_jurisdiction RPC when geo_ids are absent, then writes them back so subsequent requests are fast. A one-time backfill covers all existing users.

**Verified:** 2026-04-01T16:48:33Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Path ordering: geo_ids -> Path 1, encrypted coords + no geo_ids -> Path 1.5, home_address -> Path 2, no location -> 204 | VERIFIED | Lines 447-542 in essentials.ts implement exactly this order. Path 1 at line 448 checks `congressional_geo_id || state_senate_geo_id`. Path 1.5 at line 477 checks `has_coords && !congressional_geo_id && !state_senate_geo_id`. Path 2 at line 538 geocodes home_address. 204 at line 540 when no home_address. |
| 2 | Path 1.5 exists in essentials.ts between Path 1 and Path 2 | VERIFIED | Lines 476-536 — comment `// --- Path 1.5: encrypted coords present but geo_ids not yet stored (pre-Phase-49 users) ---` at line 476, positioned between Path 1 (ends at 474) and Path 2 (begins at 538). |
| 3 | adminRpc('resolve_user_jurisdiction') called in Path 1.5 | VERIFIED | Line 479: `const { data: jData, error: jError } = await adminRpc('resolve_user_jurisdiction', { p_user_id: userId }, 'connect');` |
| 4 | After Path 1.5 fires, connected_profiles row gets geo_ids populated via fire-and-forget pool.query UPDATE | VERIFIED | Lines 487-506: `void pool.query(UPDATE connect.connected_profiles SET congressional_geo_id = $2, ...)` — the `void` confirms fire-and-forget. Writes all 10 columns (geo_id + name for each of 5 jurisdictions). |
| 5 | If resolve_user_jurisdiction returns all-null (no boundary match), request falls through to Path 2 | VERIFIED | Lines 509 and 531-534: fall-through occurs when `!jd.congressional && !jd.state_senate` (line 509 only enters the serve block if at least one resolves). Line 531 comment: "All-null from RPC (no boundary match) — fall through to Path 2". RPC error also falls through at line 533-534. |
| 6 | adminRpc is imported from ../lib/supabase.js | VERIFIED | Line 16 in essentials.ts: `import { adminRpc } from '../lib/supabase.js';` |
| 7 | backend/scripts/backfill-pre-phase49-geo-ids.ts exists | VERIFIED | File exists at `/c/EV-Accounts/backend/scripts/backfill-pre-phase49-geo-ids.ts` (155 lines). |
| 8 | Script filters for: encrypted_lat IS NOT NULL AND location_consent = true AND congressional_geo_id IS NULL | VERIFIED | Lines 68-71: `WHERE encrypted_lat IS NOT NULL AND location_consent = true AND congressional_geo_id IS NULL` — exact match. |
| 9 | Script calls resolve_user_jurisdiction per user | VERIFIED | Lines 89-92: `pool.query('SELECT connect.resolve_user_jurisdiction($1) AS j', [user_id])` in a per-user loop. |
| 10 | Script supports --dry-run flag | VERIFIED | Line 37: `const isDryRun = process.argv.includes('--dry-run');`. All writes gated behind `if (!isDryRun)` at line 101. Dry-run output documented at lines 127 and 143. |
| 11 | Users with location_consent=false are excluded | VERIFIED | Lines 69-70: `AND location_consent = true` in the SELECT filter. Script header comment (line 17) explicitly states "the RPC raises an EXCEPTION for users with consent=false." |
| 12 | Correct column names used: congressional_district_name, state_senate_district_name, state_house_district_name, county_name, school_district_name | VERIFIED | essentials.ts lines 490-498 and backfill script lines 105-113 both use these exact column names in UPDATE statements. |

**Score:** 12/12 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/src/routes/essentials.ts` | Path 1.5 logic wired into /representatives/me route | VERIFIED | 562 lines, substantive. Path 1.5 block at lines 476-536. adminRpc imported at line 16. |
| `backend/scripts/backfill-pre-phase49-geo-ids.ts` | One-time backfill script | VERIFIED | 155 lines, substantive. Exported via main(). Not imported (it's a CLI script — correct). |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `/representatives/me` route (Path 1.5) | `resolve_user_jurisdiction` RPC | `adminRpc()` call | WIRED | Line 479 calls `adminRpc('resolve_user_jurisdiction', { p_user_id: userId }, 'connect')` |
| Path 1.5 | `connect.connected_profiles` (write-back) | `pool.query UPDATE` | WIRED | Lines 487-506: fire-and-forget UPDATE of 10 columns including both geo_id and district name columns |
| Path 1.5 | `getRepresentativesByJurisdiction` | resolved geo_ids from jData | WIRED | Lines 510-518: calls getRepresentativesByJurisdiction with jd.congressional, jd.state_senate etc. |
| Backfill script | `resolve_user_jurisdiction` RPC | `pool.query SELECT connect.resolve_user_jurisdiction($1)` | WIRED | Lines 89-92 |
| Backfill script | `connect.connected_profiles` (write-back) | `pool.query UPDATE` | WIRED | Lines 102-124, gated behind `!isDryRun` |

---

### Anti-Patterns Found

None. No TODO/FIXME/placeholder patterns, no stub returns, no empty handlers. Both files have complete implementations.

---

### TypeScript Compilation

`npx tsc --noEmit` produced no output (zero errors) after filtering pre-existing sqs-worker and aws-lambda errors. Phase 50 changes introduce no new type errors.

---

### Human Verification Required

None required for structural goal verification. The following items would confirm end-to-end correctness in a live environment but are not blockers for goal achievement assessment:

1. **Pre-Phase-49 user round-trip test** — Sign in as a Connected user who has encrypted_lat/encrypted_lng but null geo_ids, hit GET /essentials/representatives/me, and confirm (a) representatives are returned and (b) the connected_profiles row now has geo_ids populated on re-query.
2. **Backfill script live run** — Run without --dry-run against staging and verify affected users count matches expectation and geo_id columns are populated afterward.

These are operational smoke tests, not structural gaps.

---

## Summary

Phase 50 goal is fully achieved. All 12 must-haves are verified in the actual code:

- Path 1.5 is implemented correctly in `essentials.ts` between Path 1 and Path 2, with the correct guard condition (`has_coords && !congressional_geo_id && !state_senate_geo_id`).
- The RPC call uses `adminRpc` (correctly imported from `../lib/supabase.js`) with the `connect` schema parameter.
- The fire-and-forget write-back updates all 10 columns (5 geo_ids + 5 district names) using the correct column names.
- The all-null fall-through to Path 2 is implemented (line 509 gate + implicit fall-through).
- The backfill script is substantive (155 lines), filters correctly, supports `--dry-run`, excludes `location_consent=false` users, and uses the correct column names.
- TypeScript compiles clean with no new errors.

---

_Verified: 2026-04-01T16:48:33Z_
_Verifier: Claude (gsd-verifier)_
