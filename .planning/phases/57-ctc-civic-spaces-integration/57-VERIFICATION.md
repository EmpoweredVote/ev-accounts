---
phase: 57-ctc-civic-spaces-integration
verified: 2026-04-04T04:58:32Z
status: passed
score: 8/8 must-haves verified
---

# Phase 57: CTC + Civic Spaces Integration Verification Report

**Phase Goal:** CTC can read a user's `ctc_content_editor` grant from the accounts API and enforce its own content gate, and Civic Spaces can verify a user's `volunteer` grant via a single API call before allowing privileged writes — without accounts writing directly to either external system.

**Verified:** 2026-04-04T04:58:32Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | GET /api/contributor/me returns ctc_content_editor grant with jurisdiction_geoid | VERIFIED | Test line 105-122 in ctcCivicSpaces.test.ts; route maps `g.slug` → `role_slug` and `g.jurisdiction_geoid` → `jurisdiction_geoid` |
| 2 | POST /api/roles/check returns permitted:true for exact volunteer+18105 match, permitted:false for wrong jurisdiction | VERIFIED | Tests lines 152-175; route calls `checkRole(grants, body.feature_scope, scope)` which implements NULL-safe geoid matching |
| 3 | POST /api/roles/check returns permitted:true for NULL-scope volunteer grant regardless of jurisdiction_geoid | VERIFIED | Test lines 178-191; checkRole in roleService.ts line 76: skips only if `grant.jurisdiction_geoid !== null && !== scope.geoid` |
| 4 | POST /api/roles/check returns permitted:false for user with no volunteer grant | VERIFIED | Test lines 193-203; empty cache array yields no match in checkRole |
| 5 | ROLE_CACHE_TTL_SECONDS env var controls cache TTL (not hardcoded) | VERIFIED | roleService.ts line 118: `parseInt(process.env['ROLE_CACHE_TTL_SECONDS'] ?? '90', 10)` inside function body |
| 6 | Smoke script includes lifecycle check gated on SMOKE_ADMIN_TOKEN; static checks always run | VERIFIED | smoke-phase57.ts: static checks lines 270-282 always in `checks` array; lifecycle check lines 163-247 returns `skipped:true` when `!SMOKE_ADMIN_TOKEN` |
| 7 | Integration guide documents GET /api/contributor/me and POST /api/roles/check for external devs | VERIFIED | INTEGRATION-GUIDE-v2.md section 8.26 (lines 729-779): both endpoints with request/response shapes, NULL-scope semantics, CTC and Civic Spaces integration patterns |
| 8 | Cache behavior called out from external developer perspective | VERIFIED | Line 761: "Design your integration to tolerate this window — do not treat role checks as real-time." |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tests/integration/ctcCivicSpaces.test.ts` | 10-test HTTP integration suite | VERIFIED | 272 lines, 10 tests across 3 describe blocks; substantive, imported by vitest runner via default glob |
| `backend/src/lib/roleService.ts` | ROLE_CACHE_TTL_SECONDS env var controlling TTL | VERIFIED | Line 118: env var read inside getCachedUserRoles function body, not at module scope |
| `backend/scripts/smoke-phase57.ts` | Smoke script with gated lifecycle check | VERIFIED | 324 lines; 4 checks with [PASS]/[FAIL]/[SKIP] output pattern; lifecycle gated on SMOKE_ADMIN_TOKEN |
| `docs/INTEGRATION-GUIDE-v2.md` | Section 8.26 Contributor Roles | VERIFIED | Section present at line 729 with 51-line block; cache behavior, NULL-scope, CTC/Civic Spaces patterns all documented |
| `backend/src/routes/contributor.ts` | GET /api/contributor/me route | VERIFIED | 41 lines; real implementation mapping grants to `{role_slug, feature_scope, jurisdiction_geoid, resource_id}`; registered at `/api/contributor` in index.ts line 92 |
| `backend/src/routes/roles.ts` | POST /api/roles/check route | VERIFIED | 104 lines; validates `feature_scope`, calls getCachedUserRoles + checkRole, returns `{permitted: boolean}`; registered at `/api/roles` in index.ts line 91 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ctcCivicSpaces.test.ts` | `/api/contributor/me` | supertest request | WIRED | Line 110: `request(app).get('/api/contributor/me')` |
| `ctcCivicSpaces.test.ts` | `/api/roles/check` | supertest request | WIRED | Line 156: `request(app).post('/api/roles/check')` |
| `ctcCivicSpaces.test.ts` | `cache` | dynamic import + cache.set | WIRED | Lines 78-84: `import('../../backend/src/lib/cache.js')`; cache.set pre-populates in-memory cache before each HTTP test |
| `contributor.ts` | `roleService.getCachedUserRoles` | import + call | WIRED | Line 3: import; line 26: `getCachedUserRoles(authReq.userId)` |
| `roles.ts (check)` | `roleService.checkRole` | import + call | WIRED | Line 4: import; line 95: `checkRole(grants, body.feature_scope, scope)` |
| `roleService.getCachedUserRoles` | `cache` | cache.get / cache.set | WIRED | Lines 109-119: cache read with fallback to DB; TTL from env var |
| `smoke-phase57.ts` | `/api/contributor/me` | fetchAuth | WIRED | Line 104: `fetchAuth('/api/contributor/me', 'GET')` |
| `smoke-phase57.ts` | `/api/roles/check` | fetchAuth | WIRED | Lines 122-128 and 189: POST with volunteer/jurisdiction body |
| `smoke-phase57.ts` | `SMOKE_ADMIN_TOKEN` | env guard | WIRED | Lines 164-169: `if (!SMOKE_ADMIN_TOKEN)` returns skipped result; lifecycle only runs when token present |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

No TODO/FIXME comments, no placeholder content, no empty handlers, no stub returns in any of the four phase artifacts.

## Narrative Summary

All 8 must-haves are fully achieved. The phase delivers:

1. **Two substantive routes** (contributor.ts, roles.ts) already registered and handling real logic via getCachedUserRoles + checkRole.

2. **10 integration tests** that prove the four core behavioral requirements at the HTTP level using cache pre-population (cache.set) instead of vi.mock, which correctly tests the real cache hit code path.

3. **ROLE_CACHE_TTL_SECONDS** read inside the getCachedUserRoles function body — the only placement that allows per-test override without vitest hoisting conflicts.

4. **Smoke script** (324 lines) with sequential [PASS]/[FAIL]/[SKIP] output; static checks run without any tokens being set up beyond SMOKE_TOKEN; the grant→check→revoke→expire→check lifecycle runs only when SMOKE_ADMIN_TOKEN is present.

5. **Integration guide section 8.26** (51 lines) documents both endpoints with response shapes, NULL-scope semantics, explicit cache tolerance guidance written from the external developer's perspective, and concrete step-by-step patterns for both CTC and Civic Spaces.

The goal — CTC reads ctc_content_editor, Civic Spaces checks volunteer, accounts writes to neither — is structurally achieved. Both endpoints are read-only from the external system's perspective; accounts never pushes role state outward.

---

_Verified: 2026-04-04T04:58:32Z_
_Verifier: Claude (gsd-verifier)_
