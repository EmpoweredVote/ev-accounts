# 107-02 — Bodies Search + Roster Endpoints

## What was built
- `ev-accounts/backend/src/lib/essentialsBodiesService.ts` — `searchBodies(q, state)` and `getRosterBySlug(slug)`. Party-free. Uses `ch.slug` from migration 060, DISTINCT ON dedupe per D-13, titleRank→last_name→politician_id ordering per D-17, `At-Large` fallback for `*_EXEC` per D-18, photo_url chain `photo_custom_url → photo_origin_url → politician_images.url` per D-19.
- `ev-accounts/backend/src/routes/essentialsBodies.ts` — `GET /` and `GET /:slug/roster` with `optionalAuth`, inline validation (422 VALIDATION_ERROR), 404 BODY_NOT_FOUND, 500 INTERNAL_ERROR. No Zod (matches essentials family convention).
- `ev-accounts/backend/src/index.ts` — imported `essentialsBodiesRouter`; mounted at `/api/essentials/bodies` immediately after `/api/essentials/browse` and **before** the catch-all `/api/essentials` (offset 5049 < 5395 verified).

## Requirements covered
- **ESSBODY-01** — body search endpoint with q/state validation.
- **ESSBODY-02** — roster payload in locked D-16 shape.
- **ESSBODY-04** — antipartisan grep clean; active-only via `p.is_active = true AND o.is_vacant = false`.

## Verification evidence
- `npm run typecheck` passes from `ev-accounts/backend`.
- `grep -inE '\b(party|affiliation)\b'` on both new files → 0 matches (BLOCKING gate passed).
- Mount precedence script asserts `/api/essentials/bodies` offset < `/api/essentials` offset in `index.ts`.
- Live shape sanity via Supabase MCP against prod: `searchBodies('bloom', null)` returns 3 distinct slugs (`bloomington-common-council`, `bloomington-township`, `city-of-bloomington`) with active member counts 9/4/2.

## Notes
- No party columns exist on `essentials.politicians` anywhere in the new code. The `p.party` reference on line 145 of `essentialsBrowseService.ts` was intentionally NOT copied.
- `d.label` and `pi.url` used (not the tempting `d.name`/`photo_url` phantoms).
