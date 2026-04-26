---
quick_id: 260426-mw6
type: execute
status: complete
date: 2026-04-26
requirements_complete:
  - MW6-01
  - MW6-02
  - MW6-03
  - MW6-04
key-files:
  created:
    - ev-ui/src/useEvContextPromotion.js
  modified:
    - ev-ui/src/evContext.js
    - ev-ui/src/index.js
    - CompassV2/src/pages/Compass.jsx
    - essentials/src/pages/Results.jsx
    - read-rank/src/components/PhaseContainer.tsx
    - read-rank/src/components/AddressFilterInput.tsx
    - read-rank/src/types/ev-ui.d.ts
commits:
  - repo: ev-ui
    hash: 7ec60ad
    msg: "feat(260426-mw6): add useEvContextPromotion hook + extend setAuthedSlice for promotionDismissed"
  - repo: CompassV2
    hash: ad25e89
    msg: "feat(260426-mw6): wire compass promotion banner above /compass topic library"
  - repo: read-rank
    hash: 99ae103
    msg: "feat(260426-mw6): wire verdicts promotion banner on results phase"
  - repo: essentials
    hash: 8ef0962
    msg: "feat(260426-mw6): wire compass + address promotion banners on Results"
  - repo: read-rank
    hash: 03116cb
    msg: "feat(260426-mw6): wire address promotion banner above AddressFilterInput"
---

# Quick Task 260426-mw6: Authed ev-context promotion prompt — Summary

**One-liner:** New `useEvContextPromotion` hook in `@empoweredvote/ev-ui`
detects the "I signed up later" gap (logged in, API empty, ev-context has
guest data, dismissal flag clear) and powers five inline "save this to your
account?" banners across CompassV2, essentials, and read-rank — closing
ev-context follow-up #1 without touching the backend.

## Final shape of `useEvContextPromotion`

Named export from `@empoweredvote/ev-ui` (matches 260426-mc5's "minimum
diff, hang it off the existing surface" style). Signature unchanged from the
plan's `<interfaces>` block:

```js
useEvContextPromotion({ domain, isLoggedIn, userId, apiData, apiWriter, enabled? })
  -> { shouldPrompt, payload, promote, dismiss, status, error }
```

`apiWriter` signature is `(payload) => Promise<unknown>` — unchanged. The
hook never inspects the writer's return value; it cares only that the promise
resolves on success. Status transitions: `idle → saving → saved` on success;
`idle → saving → error` on failure (with `shouldPrompt` left as-is so the
user can retry).

Two pure helpers ship alongside the hook in
`ev-ui/src/useEvContextPromotion.js` and are not re-exported from the package
index — `isApiEmpty(domain, apiData)` and `isGuestPopulated(domain,
fullEvContext)`. Spot-checked via direct module import in node:

| Case                                                | Result        |
|-----------------------------------------------------|---------------|
| `isApiEmpty('compass', {})`                         | true (empty)  |
| `isApiEmpty('compass', [{topic_id:'t'}])`           | false         |
| `isApiEmpty('address', null)`                       | true (empty)  |
| `isApiEmpty('address', { formatted: 'x' })`         | false         |
| `isApiEmpty('verdicts', {})`                        | true (empty)  |
| `isApiEmpty('verdicts', { q1: 'agreed' })`          | false         |
| `isGuestPopulated('compass', { compass:{a:{t1:5}}})`| true          |
| `isGuestPopulated('compass', { compass: {} })`      | false         |
| `isGuestPopulated('address', { address:{addr:'1'}})`| true          |
| `isGuestPopulated('verdicts', { verdicts:{q1:'a'}})`| true          |

The hook also subscribes to `evContext.subscribe(...)` so cross-tab/subdomain
dismissals or promotes re-trigger detection without remounting.

## `setAuthedSlice` allow-list extension (chosen approach)

**Extended the existing helper** in `ev-ui/src/evContext.js` rather than
adding a separate `setAuthedFlag` — the diff was tiny because the helper was
already an explicit allow-list (`if (patch.compass !== undefined) ...`).
Added a fourth recognised key, `promotionDismissed`, with a special merge
rule: instead of replacing the prior body wholesale (the way
`compass / address / verdicts` are replaced), the new patch is *deep-merged
per-domain* into the prior `promotionDismissed` map so writing
`{ compass: true }` does not clobber an earlier `{ address: true }` stamp.

`getAuthedSlice` was also updated to surface `promotionDismissed` so the
hook's read path picks it up.

## Per-app wiring summary

### CompassV2 — `src/pages/Compass.jsx`

- Pulls `userId` from `useCompass()` (already exposed in 260426-mc5).
- `apiData` is the existing `answers` map; `isApiEmpty(compass, ...)` treats
  `{}` as empty.
- `apiWriter` loops `evContext.compass.a` keyed by `short_title`, maps to
  `topic_id`, and calls `POST /compass/answers` per row (no batch write
  endpoint exists — `POST /compass/answers/batch` is a *read* that returns
  answers for a list of topic IDs; the plan was wrong on the endpoint name
  but right on the route file). After the loop, merges into local context
  state via `setAnswers / setInvertedSpokes / setWriteIns` so the chart
  re-renders without reload.
- `CompassPromotionBanner` is a tiny in-file component above
  `BelowThresholdChart`, rendered just before `<TabBar />` inside
  `max-w-6xl mx-auto` so it lines up with the desktop 2-column layout.

### essentials — `src/pages/Results.jsx`

essentials does **not** have a dedicated compass page (`pages/Compass.jsx`
does not exist) — see "Deviations" below. Both compass and address banners
live on `Results.jsx`, the canonical address-entry surface.

- Pulls `userId` from `useCompass()`.
- Compass `apiWriter` loops the same way as CompassV2.
- Address `apiWriter` calls the existing `saveMyLocation(addr)` (POST
  `/connect/set-location`), then routes through `saveUserAddress(addr,
  state, userId)` to keep the legacy cookie + guest slice + authed slice
  mirrors consistent.
- A single `PromotionBanner` local component (with a `kind` discriminator)
  serves both placements, matching the existing `suggestedSaveAddress`
  visual treatment so the page's design system stays coherent.
- Both banners rendered at the top of `<main>` above the existing
  `suggestedSaveAddress` block — first compass, then address.

### read-rank — `src/components/PhaseContainer.tsx` (verdicts) + `src/components/AddressFilterInput.tsx` (address)

- `PhaseContainer.tsx` derives a `localVerdictMap` from the zustand store
  (rankedQuotes → 'agreed', disagreedQuotes → 'disagreed'). The hook only
  fires when this map is empty AND `evContext.verdicts` has entries.
  `apiWriter` posts the legacy format directly (`{quote_id, verdict}[]` to
  `POST /compass/verdicts`).
- `AddressFilterInput.tsx` reuses `handlePlaceSelected` as the writer so the
  search → save → `writeAddressToContext` chain runs unchanged. The
  pre-existing silent auto-apply remains and covers the common case; this
  banner is the explicit-consent fallback when the user clears the filter.
- `src/types/ev-ui.d.ts` extended with the `useEvContextPromotion`
  declaration and `promotionDismissed` field on `EvAuthedSlice` (read-rank's
  local d.ts shadows the unbundled package types).

### treasury-tracker

**No banner.** Read-only consumer per the plan and the task constraints.
Verified: `grep -r useEvContextPromotion EV-prototypes/treasury-tracker/src/`
returns nothing.

## Endpoint payload shapes used

| Domain   | Endpoint                          | Body shape                                                  |
|----------|-----------------------------------|-------------------------------------------------------------|
| compass  | `POST /compass/answers` (per row) | `{ topic_id, value, inverted, write_in_text? }`             |
| address  | `POST /connect/set-location`      | `{ address }` (via existing `saveMyLocation`)               |
| verdicts | `POST /compass/verdicts`          | `[{ quote_id, verdict: 'agreed'\|'disagreed' }]` (legacy)   |

Backend handlers verified against `ev-accounts/backend/src/routes/compass.ts`
and `ev-accounts/backend/src/routes/connect.ts`. The legacy verdict format
is still accepted (see `postVerdictsLegacySchema`) so we ride that path
rather than the new `{ verdicts: [{ quote_id, supported, rank, session_size }] }`
shape — the legacy form matches what guest data we have available.

## Suggested commit boundary used

Five commits, one per concern (matches 260426-mc5 precedent):

| Repo       | Hash      | Message                                                                         |
|------------|-----------|---------------------------------------------------------------------------------|
| ev-ui      | `7ec60ad` | `feat(260426-mw6): add useEvContextPromotion hook + extend setAuthedSlice for promotionDismissed` |
| CompassV2  | `ad25e89` | `feat(260426-mw6): wire compass promotion banner above /compass topic library`  |
| read-rank  | `99ae103` | `feat(260426-mw6): wire verdicts promotion banner on results phase`             |
| essentials | `8ef0962` | `feat(260426-mw6): wire compass + address promotion banners on Results`         |
| read-rank  | `03116cb` | `feat(260426-mw6): wire address promotion banner above AddressFilterInput`      |

## ev-ui release status

**Deferred to user per task constraint.** The new hook + helper extension
exist on `main` of ev-ui at `7ec60ad` but no `npm version patch` has been
run. Local `npm link` was used to wire the new ev-ui build into all three
consumer repos for build verification.

When ready, the user runs:

```bash
cd ev-ui
npm version patch  # 0.6.2 → 0.6.3
git push origin main --follow-tags
```

The auto-bump pipeline propagates the new version to PRs in CompassV2 /
essentials / read-rank / civic-spaces. The four consumer commits already on
`main` will fail to build against `^0.6.2` until the auto-bump PR lands —
sequence the release before/with the consumer merges.

## Build verification

| App         | Build               | Notes                                              |
|-------------|---------------------|----------------------------------------------------|
| ev-ui       | `npm run build`     | ESM + CJS bundles, ~45ms each                      |
| CompassV2   | `npm run build`     | clean (chunk-size warning is pre-existing)         |
| essentials  | `npm run build`     | clean (dynamic-import warning is pre-existing)     |
| read-rank   | `tsc -b && vite build` | clean (verdicts + address builds in same pass) |

## Manual smoke test (deferred to user post-publish)

The plan's manual cross-subdomain smoke test was **not run under live
origins** — the helpers are spot-checked semantically (Node REPL) and all
apps build clean against the linked package. The user should run after
`npm version patch` lands and the auto-bump PRs merge:

1. Calibrate compass + set address as a guest on read-rank or CompassV2.
2. Sign up via essentials' Connected onboarding *without* using its
   compass-import flow.
3. Land on Results.jsx — both compass and address banners should appear.
4. Click Save on each — banners disappear; refresh shows no banner; profile
   has the answers + saved address.
5. Click Dismiss on a separate user/domain — banner stays gone across
   reloads for that user; switching to a different user clears the
   dismissal stamp (userId mismatch inertia).
6. Treasury-tracker shows no banner anywhere.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocking] essentials has no `pages/Compass.jsx`**
- **Found during:** Task 3
- **Issue:** The plan's `files_modified` lists
  `essentials/src/pages/Compass.jsx`, but no such file exists. essentials is
  a politician-discovery app whose compass surface is rendered via
  `CompassCardVertical` inside Results.jsx — there is no dedicated compass
  route.
- **Fix:** Wired the compass promotion banner on Results.jsx alongside the
  address banner. Both flow from the same `useCompass()` data and live near
  the same point of user attention (the address-entry top of `<main>`).
  This actually consolidates the work: a single in-file `PromotionBanner`
  component (`kind="compass" | "address"`) serves both placements.
- **Files modified:** `essentials/src/pages/Results.jsx` only (instead of
  Compass.jsx + Results.jsx).

**2. [Rule 1 — Bug] Plan referenced a non-existent batch write endpoint**
- **Found during:** Tasks 2 and 3
- **Issue:** The plan's `<interfaces>` matrix says compass save uses
  `POST /compass/answers/batch`. That route exists, but it's a *read*
  endpoint — given a list of `ids`, it returns the user's answers. The
  actual write path is `POST /compass/answers` for a single topic.
- **Fix:** Both the CompassV2 and essentials writers loop `Object.entries`
  on the guest answers map and POST to `/compass/answers` per row, mapping
  `short_title → topic_id` via `topics`. Each call is sequential to keep
  the failure surface obvious — a partial failure throws, the hook moves to
  `status='error'`, and the user can retry. (For a guest with 8–10
  answers, sequential POSTs in <1s on production latency is acceptable; if
  this becomes a hot path the backend can grow a real batch route later.)
- **Files modified:** `CompassV2/src/pages/Compass.jsx`,
  `essentials/src/pages/Results.jsx`.

### Auth gates

None encountered — all build verification was offline against linked ev-ui.

## Self-Check: PASSED

Verified files exist:

- `ev-ui/src/useEvContextPromotion.js` — FOUND (hook + isApiEmpty + isGuestPopulated)
- `ev-ui/src/evContext.js` — FOUND (promotionDismissed allow-listed in setAuthedSlice + surfaced in getAuthedSlice)
- `ev-ui/src/index.js` — FOUND (re-export of useEvContextPromotion)
- `CompassV2/src/pages/Compass.jsx` — FOUND (CompassPromotionBanner + hook wiring)
- `essentials/src/pages/Results.jsx` — FOUND (PromotionBanner + compass + address hook wiring)
- `read-rank/src/components/PhaseContainer.tsx` — FOUND (VerdictsPromotionBanner + verdicts hook wiring)
- `read-rank/src/components/AddressFilterInput.tsx` — FOUND (AddressPromotionBanner + address hook wiring)
- `read-rank/src/types/ev-ui.d.ts` — FOUND (useEvContextPromotion + promotionDismissed declarations)

Verified commits exist:

- ev-ui `7ec60ad` — FOUND
- CompassV2 `ad25e89` — FOUND
- read-rank `99ae103` — FOUND
- essentials `8ef0962` — FOUND
- read-rank `03116cb` — FOUND
