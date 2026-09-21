# `src/civic_spaces/` — Civic Spaces slice assignment (folded in)

**Canonical.** This is a **vendored copy** (ev-cto decision 0013) of the standalone
`EmpoweredVote/civic-spaces` service `services/slice-assignment`, folded into the engine per
**ev-cto decision 0018**. Production is served from here. The civic-spaces repo copy is frozen
(`services/slice-assignment/FROZEN.md`); its **frontend stays active** and calls this module.

## What it is
One synchronous endpoint: **`POST /api/civic-spaces/assign`** (mounted in `src/index.ts`). It
maps an authenticated Connected member's jurisdiction onto civic "slices" (unified, federal,
state, county, city, volunteer), creating slices on demand and keeping the member's
memberships in sync. No background work — pure request/reply, so it is **not** a job (nothing
in `jobs/registry.ts`). Served under `EV_ROLE=api` like every other route.

## How it differs from the standalone (deliberately)
- **Auth:** uses the engine's single dual-issuer verifier `middleware/auth.ts#requireAuth`.
  The standalone's own `verifyToken.ts` copy is **not** vendored — it 401'd every WorkOS
  member after the 2026-08-28 cutover, and a second dual-issuer verifier is exactly what we
  must not reintroduce. Its unit tests are already covered by `lib/tokenIdentity.test.ts`.
- **Account + roles:** the two outbound HTTP calls are now in-process —
  `services/accountsApi.ts` calls `lib/accountMeService.ts#getAccountMe` (was
  `GET /api/account/me`) and `lib/roleService.ts` `getCachedUserRoles` + `checkRole` (was
  `POST /api/roles/check`, reusing the 90s role cache).
- **Database:** `config/database.ts` is a dedicated pg pool that connects as
  **`civic_spaces_app`**, a least-privilege role granted DML on ONLY
  `civic_spaces.{slices, slice_members, connected_profiles}` (migration **CA_0112**). It does
  NOT use the broad engine key/role — `connected_profiles.user_id` joins to identity
  (PRIVACY-ARCHITECTURE property A), so the module is walled off by construction. Set via the
  `CIVIC_SPACES_DATABASE_URL` env var (founder secret).

## Preserved behaviours (each fixed a recorded bug — see `services/sliceAssigner.ts`)
- `tier === 'inform'` → **403**.
- Volunteer: assign to the volunteer slice if permitted; **remove** from it if not (revocation).
- Null geoid (e.g. an unincorporated address with no `city_geoid`): **skip that level, return
  200** — the member still gets federal/state/county. Never 500.
- `slice_full` (P0001 at the 6000 cap): up-to-3 retry that finds/creates a sibling slice.
- Unified auto-assign + geo assign + `removeStaleGeoMemberships` on jurisdiction change.

## Cutover
The civic-spaces frontend builds `${VITE_SLICE_ASSIGNMENT_URL}/assign`. Point that env var at
this base (`https://api.empowered.vote/api/civic-spaces`) and rebuild the static site — one env
var, no frontend re-homing. Then retire the standalone `civic-spaces-slice-assignment` Render
service (founder dashboard: autoDeploy off → suspend → delete after a soak).
