---
phase: 37-express-ports-wave-2-staging
verified: 2026-03-20T00:00:00Z
status: passed
score: 8/8 must-haves verified
---

# Phase 37: Express Ports Wave 2 — Staging Verification Report

**Phase Goal:** The Staging review workflow runs entirely on ev-accounts — role-gated submission, review, and approval routes are operational and enforce the same access rules as the Go server.
**Verified:** 2026-03-20
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #  | Truth                                                         | Status     | Evidence                                                                                              |
|----|---------------------------------------------------------------|------------|-------------------------------------------------------------------------------------------------------|
| 1  | requireStagingReviewer middleware exists with dual-path auth  | VERIFIED   | Lines 22-44: admin_users fast path, then user_roles JOIN roles WHERE slug='staging_reviewer' AND revoked_at IS NULL |
| 2  | stagingService has all 19 exports, zero supabaseAdmin refs    | VERIFIED   | All 19 functions export-declared; grep for supabaseAdmin returns zero matches                         |
| 3  | Approving a politician auto-promotes to essentials.politicians | VERIFIED   | promoteToEssentials() at lines 432-489: INSERT INTO essentials.politicians ... ON CONFLICT (external_id) DO UPDATE |
| 4  | Approving a stance validates topic_id non-null and resolves politician from essentials | VERIFIED | Lines 775-796: 422 if !record.topicId; SELECT id FROM essentials.politicians WHERE external_id = $1; 422 if not found |
| 5  | Approving a photo upserts to essentials.building_photos       | VERIFIED   | Lines 987-995: INSERT INTO essentials.building_photos ... ON CONFLICT (place_geoid) DO UPDATE         |
| 6  | staging.ts mounts router.use(requireAuth, requireStagingReviewer) | VERIFIED | Line 47: router.use(requireAuth as any, requireStagingReviewer as any) — all routes gated             |
| 7  | No lock routes exist for photos                               | VERIFIED   | Line 486 comment: "No lock/unlock routes for photos — building_photos has no locked_by/locked_at columns"; confirmed by route scan |
| 8  | index.ts registers /api/staging                              | VERIFIED   | Line 26: import stagingRouter; Line 68: app.use('/api/staging', stagingRouter)                        |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact                                            | Expected                         | Status   | Details                                |
|-----------------------------------------------------|----------------------------------|----------|----------------------------------------|
| `backend/src/middleware/requireStagingReviewer.ts`  | Dual-path auth middleware        | VERIFIED | 45 lines, exports requireStagingReviewer, correct SQL JOINs |
| `backend/src/lib/stagingService.ts`                 | 19 exports, pool.query() only    | VERIFIED | 1024 lines, 19 named exports, no supabaseAdmin |
| `backend/src/routes/staging.ts`                     | 200+ lines, all routes present   | VERIFIED | 489 lines, all politician/stance/photo routes |
| `backend/src/index.ts`                              | Mounts /api/staging              | VERIFIED | stagingRouter imported and mounted at /api/staging |

### Key Link Verification

| From                        | To                              | Via                             | Status   | Details                                                         |
|-----------------------------|---------------------------------|---------------------------------|----------|-----------------------------------------------------------------|
| staging.ts                  | requireStagingReviewer          | router.use()                    | WIRED    | Line 47 — applied before all route handlers                     |
| reviewPolitician()          | essentials.politicians          | promoteToEssentials() pool.query | WIRED   | INSERT INTO essentials.politicians with ON CONFLICT upsert      |
| reviewStance()              | inform.politician_answers       | pool.query INSERT ON CONFLICT   | WIRED    | Lines 807-812: upserts (politician_id, topic_id, value)         |
| reviewStance()              | essentials.politicians          | pool.query SELECT               | WIRED    | Lines 788-796: validates politician exists before approving     |
| reviewPhoto()               | essentials.building_photos      | pool.query INSERT ON CONFLICT   | WIRED    | Lines 987-995: upserts on place_geoid conflict key              |
| index.ts                    | staging.ts router               | app.use('/api/staging')         | WIRED    | Lines 26 + 68 of index.ts                                       |
| subpath routes (/:id/review, /:id/lock, /:id/merge) | /:id param route | Express ordering | WIRED | All subpath routes defined before /:id param routes per comment |

### Anti-Patterns Found

None. No TODO/FIXME/placeholder patterns. No supabaseAdmin usage in stagingService. No stub implementations. All handlers perform real database operations via pool.query().

### Human Verification Required

None. All must-haves are verifiable statically from the codebase. Route structure, middleware wiring, SQL correctness, and export completeness are all confirmed at the code level.

## Verification Detail

### requireStagingReviewer.ts

- EXISTS: Yes (45 lines)
- SUBSTANTIVE: Yes — no stubs, real pool.query() calls
- WIRED: Imported in staging.ts line 18, used in router.use() at line 47

Admin fast-path: `SELECT 1 FROM public.admin_users WHERE user_id = $1`
Role path: JOIN on user_roles + roles WHERE slug='staging_reviewer' AND revoked_at IS NULL

### stagingService.ts export inventory

19 named exports confirmed:
1. getPoliticians
2. getPoliticianById
3. createPolitician
4. updatePolitician
5. reviewPolitician
6. lockPolitician
7. unlockPolitician
8. mergePolitician
9. getStances
10. getStanceById
11. createStance
12. updateStance
13. reviewStance
14. lockStance
15. unlockStance
16. getPhotos
17. getPhotoById
18. createPhoto
19. reviewPhoto

All pool.query() only. supabaseAdmin grep: zero matches.

### State machine enforcement

assertPending() defined at lines 118-124. Called in: updatePolitician, reviewPolitician, mergePolitician, updateStance, reviewStance, reviewPhoto. Any non-pending record throws httpStatus=422.

### Auto-promotion paths

- Politicians: reviewPolitician calls promoteToEssentials() which runs INSERT INTO essentials.politicians with ON CONFLICT (external_id) DO UPDATE for records with numeric external_id; plain INSERT for null external_id.
- Stances: reviewStance inserts/upserts to inform.politician_answers (politician_id, topic_id, value) ON CONFLICT (politician_id, topic_id).
- Photos: reviewPhoto inserts to essentials.building_photos ON CONFLICT (place_geoid) DO UPDATE covering url, source_url, license, attribution.

### staging.ts route structure

Confirmed ordering pattern: subpath routes (/review, /lock, /merge) declared before /:id on all resource types. UUID validation on all parameterized routes. No lock routes for photos (no locked_by/locked_at columns on building_photos table).

---

_Verified: 2026-03-20_
_Verifier: Claude (gsd-verifier)_
