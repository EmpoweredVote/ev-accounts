---
quick_id: 260426-mc5
type: execute
status: complete
date: 2026-04-26
requirements_complete:
  - MC5-01
  - MC5-02
  - MC5-03
key-files:
  modified:
    - ev-ui/src/evContext.js
    - ev-ui/src/index.js
    - CompassV2/src/components/CompassContext.jsx
    - essentials/src/contexts/CompassContext.jsx
    - essentials/src/lib/compass.js
    - read-rank/src/hooks/useAuthState.ts
    - read-rank/src/components/AddressFilterInput.tsx
    - read-rank/src/components/PhaseContainer.tsx
    - read-rank/src/utils/verdictSync.ts
    - read-rank/src/types/ev-ui.d.ts
    - EV-prototypes/treasury-tracker/src/App.tsx
    - EV-prototypes/treasury-tracker/src/types/ev-ui.d.ts
commits:
  - repo: ev-ui
    hash: 178d13c
    msg: "feat(260426-mc5): add userId-stamped authed slice helpers to evContext"
  - repo: CompassV2
    hash: b6f52d1
    msg: "feat(260426-mc5): mirror compass writes into authed ev-context slice"
  - repo: essentials
    hash: ab51cef
    msg: "feat(260426-mc5): mirror compass + address writes into authed ev-context slice"
  - repo: read-rank
    hash: ccb28e4
    msg: "feat(260426-mc5): mirror address + verdicts into authed ev-context slice"
  - repo: EV-prototypes
    hash: 83136d4
    msg: "feat(260426-mc5): read-only ev-context address hydration in treasury-tracker"
---

# Quick Task 260426-mc5: Authed users write through ev-context as a cache — Summary

**One-liner:** Logged-in users now mirror compass / address / verdicts writes
into a userId-stamped `authed` slice in ev-context, gaining the same instant
cross-subdomain hydration guests already enjoy. API remains source of truth
(SWR pattern); userId stamping prevents cross-user leakage.

## Final shape chosen

**Top-level `authed` key with userId stamp** (per the plan's recommended D-03
shape). Stored shape:

```js
{
  // Guest top-level keys (unchanged, untouched by authed writes)
  compass?: {...},
  address?: {...},
  verdicts?: {...},

  // Single authed slice, stamped with the user's id
  authed?: {
    userId: string,
    compass?: {...},
    address?: {...},
    verdicts?: {...},
  }
}
```

Picked over per-key stamping because:
- Single readable position (`current.authed?.userId`) for the mismatch check.
- `setAuthedSlice` can stomp the prior body in one operation on user switch
  rather than per-key.
- Diff with the existing `evContext.set()` merge model is trivial — the helper
  only reads/writes the `authed` key and never touches guest top-level keys.

## New surface in ev-ui

Three methods added to the existing `evContext` object (no new hook module —
plan's D-04 explicitly allows this minimum-diff shape):

- `getAuthedSlice(userId)` — returns `{ compass?, address?, verdicts? }` iff
  `current.authed.userId === userId`; returns `null` on mismatch / missing
  slice / falsy userId.
- `setAuthedSlice(userId, patch)` — merges `compass / address / verdicts`
  keys into the authed body. Stomps prior body on user switch. Preserves
  guest top-level keys untouched. Rejects falsy userId or empty patch.
- `clearAuthedSlice()` — omits the `authed` key. **Not called by any
  consumer** — logout intentionally relies on userId-mismatch inertia.

Verified in a Node REPL with stubbed `get/set`:
- guest slice preserved across authed writes ✓
- mismatch returns null ✓
- user switch stomps prior body ✓
- falsy userId / empty patch reject with `false` ✓
- clear preserves guest slice ✓

## Per-app wiring summary

### CompassV2
- Capture `userId` from `/account/me` response; expose on `useCompass()`
  context value.
- Existing guest-write effect (single `useEffect`) gained an authed branch:
  when `isLoggedIn && userId`, calls `setAuthedSlice(userId, { compass: { a, i, w } })`.
  Excludes `selectedTopics` per D-01.
- One-shot SWR hydrate on `(isLoggedIn, userId)` change: reads
  `getAuthedSlice(userId)` and seeds `answers / inverted / writeIns` before
  `/compass/answers` resolves. Guarded by `authedHydratedRef` so it only
  runs once per session.

### essentials
- Capture `userId` from `/account/me`; expose on context value.
- SWR hydrate added at the top of the authed branch in `loadAll()`: reads
  `getAuthedSlice(userId)` and seeds `userAnswers / invertedSpokes /
  myRepresentativesAddress` before the API resolves.
- Authed mirror added next to the existing guest writes:
  - After successful reps lookup → mirrors `address` payload.
  - After successful authed answers fetch → mirrors `compass: { a, i }`
    (excludes `s` per D-01).
- `src/lib/compass.js`:
  - `saveUserAddress(addr, state, userId?)` — when `userId` is supplied,
    additionally calls `setAuthedSlice(userId, { address })`.
  - `loadUserAddressFromContext({ ttlMs?, userId? })` — when `userId` is
    supplied, prefers the authed slice and falls back to guest on miss.

### read-rank
- `useAuthState` hook gained `userId` field, captured from `/account/me`.
- `AddressFilterInput`:
  - `writeAddressToContext(addr, userId?)` mirrors to authed slice when
    `isLoggedIn && userId`.
  - Mount-time auto-apply prefers `getAuthedSlice(userId)` and falls back
    to guest slice on miss.
- `verdictSync.ts`:
  - `postVerdicts(issueProgress, userId?)` — after successful
    `POST /compass/verdicts`, mirrors the verdict map under
    `setAuthedSlice(userId, { verdicts })`.
  - Added `loadVerdictsFromContext(userId)` helper (not yet wired into
    PhaseContainer's hydration path — call site is currently API-only).
- `PhaseContainer` updated to pass `userId` into `postVerdicts`.
- `src/types/ev-ui.d.ts` extended with `getAuthedSlice / setAuthedSlice /
  clearAuthedSlice` declarations to satisfy the strict tsc build.

### treasury-tracker (EV-prototypes/treasury-tracker)
- **Read-only consumer** per plan constraint — no writes.
- `App.tsx` mount effect calls `/account/me` (best-effort, `credentials:
  'include'` for SSO cookie path), then prefers `getAuthedSlice(userId)`
  before falling back to `evContext.get()` for the guest `address`.
- Treasury-tracker hardcodes Bloomington and has no multi-city selector,
  so the hydrated address is **logged in dev only** (`import.meta.env.DEV`
  guard). The actual UI hookup is deferred until a multi-city selector
  exists — captured here as a forward-compatible read seam.
- `src/types/ev-ui.d.ts` was missing the `evContext` declaration entirely;
  added it along with the new authed-slice helpers.

## Treasury-tracker UI hookup status

**Console logging only.** No UI wiring — the app currently has no
multi-city selector to drive. The hydration effect is in place and ready
for a future task that adds municipal selection; it just wraps the value
in `console.log` behind a DEV guard for now.

## Apps that needed `/account/me.id` exposed

All three authed consumers had to surface `userId` on their auth state
because none currently exposed it:

- **CompassV2** — added `userId` to `CompassContext` state and value.
- **essentials** — added `userId` to `CompassContext` state and value.
- **read-rank** — extended `useAuthState`'s `AuthState` interface with
  `userId` and threaded it through `loadProfile` and the four explicit
  `setState` callsites.

(Treasury-tracker fetches `/account/me` inline only inside the hydration
effect — no auth state of its own to extend.)

## Commit boundary used

One commit per repo (5 commits total), as the plan suggested:

| Repo | Hash | Message |
|------|------|---------|
| ev-ui | `178d13c` | `feat(260426-mc5): add userId-stamped authed slice helpers to evContext` |
| CompassV2 | `b6f52d1` | `feat(260426-mc5): mirror compass writes into authed ev-context slice` |
| essentials | `ab51cef` | `feat(260426-mc5): mirror compass + address writes into authed ev-context slice` |
| read-rank | `ccb28e4` | `feat(260426-mc5): mirror address + verdicts into authed ev-context slice` |
| EV-prototypes | `83136d4` | `feat(260426-mc5): read-only ev-context address hydration in treasury-tracker` |

## ev-ui release status

**Not yet released — explicitly deferred to user per execution constraint.**
The new helpers exist on `main` of ev-ui at `178d13c` but no `npm version
patch` has been run. Per plan constraint:

> Do NOT publish ev-ui to npm or run npm version bumps — leave that for
> the user to trigger manually after review

Local `npm link` was used to wire the new ev-ui build into all four
consumer repos for build verification. When the user is ready, the next
release flow is:

```bash
cd ev-ui
npm version patch
git push origin main --follow-tags
```

The auto-bump pipeline will then propagate the new version into PRs in
CompassV2 / essentials / read-rank / civic-spaces, and Render will
auto-deploy each consumer on merge. The four consumer commits already
landed in this task will be on `main` ahead of the bump PR — they import
from `@empoweredvote/ev-ui` and call `setAuthedSlice` / `getAuthedSlice`
directly, so they will fail to build against the published `^0.6.1`
until the auto-bump PR lands. The user should sequence:

1. `cd ev-ui && npm version patch && git push --follow-tags`
2. Wait for auto-bump PRs to land in each consumer (auto-merged on
   patch/minor).

(Treasury-tracker is in EV-prototypes monorepo and is **not** wired into
the ev-ui auto-bump consumer list per `ev-ui/README-AUTOBUMP.md`. Its
ev-ui import will still work as long as the consuming Render deployment
runs `npm install` and pulls a recent version, but it is not auto-bumped
on every release. If treasury-tracker is later deployed standalone, the
user should add it to the dispatch list.)

## Build verification

All four apps build cleanly with the local-linked ev-ui:

| App | Build | Notes |
|-----|-------|-------|
| ev-ui | `npm run build` | ESM + CJS bundles, 36ms each |
| CompassV2 | `npm run build` | clean (chunk-size warning is pre-existing) |
| essentials | `npm run build` | clean (dynamic-import warning is pre-existing) |
| read-rank | `npm run build` | `tsc -b && vite build`, both clean |
| treasury-tracker | `npm run build` | `tsc -b && vite build`, both clean |

## Manual smoke test (deferred to user)

The plan's manual smoke test (cross-subdomain hydration as a logged-in
user, user-switch leakage check, logout inertia check) was **not run
under live origins** — the helpers are unit-verified semantically (Node
REPL) and the apps build clean with the linked package. The user should
run the cross-subdomain check after the npm publish + auto-bump PRs land
on real `compass.empowered.vote / essentials.empowered.vote /
readrank.empowered.vote`, since the broker is locked to those origins.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] Missing `evContext` type declarations in treasury-tracker**
- **Found during:** Task 3
- **Issue:** `EV-prototypes/treasury-tracker/src/types/ev-ui.d.ts` did not
  declare `evContext` at all (the file was created before ev-context wiring
  reached this app), so `import { evContext } from '@empoweredvote/ev-ui'`
  would have failed `tsc -b`.
- **Fix:** Added the full `evContext` declaration including the new
  authed-slice helpers, mirroring the shape used in read-rank's local d.ts.
- **Files modified:** `EV-prototypes/treasury-tracker/src/types/ev-ui.d.ts`
- **Commit:** `83136d4`

**2. [Rule 3 — Blocking] Missing authed-slice declarations in read-rank's local d.ts**
- **Found during:** Task 2 — initial `npm run build` in read-rank failed
  with TS2339 on `setAuthedSlice` / `getAuthedSlice`.
- **Issue:** `read-rank/src/types/ev-ui.d.ts` shadows the package types
  (none ship from ev-ui itself), and the local declaration only included
  the original four methods.
- **Fix:** Added `EvAuthedSlice` interface and the three new method
  signatures (`getAuthedSlice / setAuthedSlice / clearAuthedSlice`).
- **Files modified:** `read-rank/src/types/ev-ui.d.ts`
- **Commit:** `ccb28e4`

### Auth gates

None encountered — all build verification was offline.

## Self-Check: PASSED

Verified files exist (modified files):
- `ev-ui/src/evContext.js` — FOUND (contains `getAuthedSlice` / `setAuthedSlice` / `clearAuthedSlice`)
- `ev-ui/src/index.js` — FOUND (re-export comment updated)
- `CompassV2/src/components/CompassContext.jsx` — FOUND (`userId` state, `setAuthedSlice` call)
- `essentials/src/contexts/CompassContext.jsx` — FOUND (`userId` state, SWR hydrate, mirrors)
- `essentials/src/lib/compass.js` — FOUND (`saveUserAddress(addr, state, userId)`)
- `read-rank/src/hooks/useAuthState.ts` — FOUND (`userId` in AuthState)
- `read-rank/src/components/AddressFilterInput.tsx` — FOUND (authed mirror + auto-apply)
- `read-rank/src/components/PhaseContainer.tsx` — FOUND (passes `userId` into `postVerdicts`)
- `read-rank/src/utils/verdictSync.ts` — FOUND (`postVerdicts(progress, userId?)`, `loadVerdictsFromContext`)
- `read-rank/src/types/ev-ui.d.ts` — FOUND (authed-slice declarations)
- `EV-prototypes/treasury-tracker/src/App.tsx` — FOUND (hydration effect)
- `EV-prototypes/treasury-tracker/src/types/ev-ui.d.ts` — FOUND (evContext declared)

Verified commits exist:
- ev-ui `178d13c` — FOUND
- CompassV2 `b6f52d1` — FOUND
- essentials `ab51cef` — FOUND
- read-rank `ccb28e4` — FOUND
- EV-prototypes `83136d4` — FOUND
