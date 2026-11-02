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
- `slice_full` (P0001 at the 6000 cap): up-to-3 retry that re-places the member, **splitting
  the frontier slice** if nothing is open. The three-attempt ceiling is what stops a
  jurisdiction that refuses every insert from dividing once per attempt.

## Splitting (Phase 19-01)

At most **two slices accept new members** for any `(slice_type, geoid)`: the newest and the
second-newest. Everything older is closed, which is not a stored state — it is simply not
being among the two highest `sibling_index` values. New members fill the **second-newest**
first, so the newest keeps room for the arrivals after it.

When both are full the frontier **divides**: `civic_spaces.split_slice()` moves the most
recently joined half into a new sibling and seeds it with a forked window of the parent's
recent threads. It used to create an empty sibling here, which is a room with six thousand
neighbours next door and nobody in it.

🔴 **The split happens inside the database because this module cannot do it.** The pool
connects as `civic_spaces_app`, which holds DML on `slices`, `slice_members` and
`connected_profiles` and nothing else — it cannot read a post, let alone copy one. Widening
that role to make the seed possible would cross a stated privacy boundary for implementation
convenience. The engine decides a split should happen; two `EXECUTE` grants let it ask
(`split_slice`, `is_splittable_slice_type`). Do not widen the table grants.

🔴 `volunteer` does not split — it is a role, not a place. It falls through to the original
create-a-sibling overflow, which is dormant but deliberately still reachable.

🔴 **Nothing calls the split on a schedule yet.** It fires only on the `slice_full` retry
path, which runs inside `POST /api/civic-spaces/assign` — a pool with
`statement_timeout = 10s`, called fire-and-forget by the frontend. A 6000-member split may
not fit in that budget. Scheduling is open; see the civic-spaces design doc §9.4 and §10.
- Unified auto-assign + geo assign + `removeStaleGeoMemberships` on jurisdiction change.

## Cutover
The civic-spaces frontend builds `${VITE_SLICE_ASSIGNMENT_URL}/assign`. Point that env var at
this base (`https://api.empowered.vote/api/civic-spaces`) and rebuild the static site — one env
var, no frontend re-homing. Then retire the standalone `civic-spaces-slice-assignment` Render
service (founder dashboard: autoDeploy off → suspend → delete after a soak).
