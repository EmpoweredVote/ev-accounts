# Basic accounts can add an address — districts only

**Status:** approved 2026-11-07, built (CA_0368) · **Decided:** 2026-11-07, Chris Andrews — "Districts only"
**Related:** PR #1280 (the 403 message), `docs/PRIVACY-DATA-MODEL.md`, ev-cto decision 0022 (identity vault)

## Problem

A basic (Inform) account cannot add an address. `app.empowered.vote/settings/location` posts to
`POST /api/connect/set-location`, which sits behind `requireConnected` and returns 403. Every
feature that needs districts — your representatives, your elections — is also behind
`requireConnected`. Civic Spaces and this app both send basic users to that page.

## Decision

A basic account gives an address. We geocode it, resolve its districts, and **keep only the
districts**. We keep no street address and no map point, and we seal nothing in the identity
vault.

Why: the vault exists for Connected accounts' one-person-one-account accountability, which basic
accounts do not have (multiple basic accounts are allowed). The vault cannot run a feature, so
option "same as Connected" would store the districts anyway, plus the two most sensitive items.

## What already exists (measured 2026-11-07, prod)

- **`POST /api/account/set-location` (`requireInform`) is a basic-tier address route — and no
  front end calls it.** It stores `{ lat, lng, city, state, matchedAddress }` as **plain JSON** in
  `inform.inform_profiles.last_essentials_location`: the full matched street address and the exact
  point, unencrypted. That is weaker than the Connected path. `PATCH /api/account/location-hint`
  stores whatever point it is sent, the same way. **Both hold 0 rows in prod.**
- **`connect.user_districts`** (TIGER cache) is keyed to `public.users`, not to
  `connected_profiles`, and its writer `essentials.cache_user_districts(user, lat, lng)` takes the
  point as an argument and stores districts only. It covers CA legislative layers, US House and
  school layers only, so it is not a general home for districts.
- **`connect.resolve_user_jurisdiction(p_user_id)`** reads the stored point from
  `connected_profiles`, so it cannot serve a user with no stored point.
- **`connect.resolve_congressional_2026(p_user_id)`** — the mid-decade congressional map fix for
  10 states — also reads the stored point, live, at read time.
- **`POST /api/civic-spaces/assign` refuses `tier === 'inform'`.** This must stay: Civic Spaces
  decides who may post by slice membership, with no tier check (`whyNoWrite`, D-04). A basic
  account placed in a slice could post.

## Design

### 1. Storage — one new table

`inform.account_jurisdictions`, one row per basic account that has added an address:

- `user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE`
- the same district columns `connected_profiles` carries today (congressional, state senate, state
  house, county, school district, city council, municipality, city, state, nation — geo ids and
  names), plus `jurisdiction_state`, `jurisdiction_city`
- `resolved_at timestamptz NOT NULL`

🔴 **Never write basic users' districts into `connect.connected_profiles`.** A row there is what
makes an account Connected (`requireConnected` / `requireInform`). A dedicated table also keeps
location apart from other profile data, as the privacy model asks.

Grants: `ev_api` and `service_role` SELECT/INSERT/UPDATE/DELETE only; RLS on with **no** policy
(default-deny — no front end reads it through PostgREST); nothing for `anon` or `authenticated`.
Same migration (house rule for new tables).

### 2. Resolve from a point, not from a stored point

One migration (a `CA_` slot from the allocator) adds:

- `connect.resolve_jurisdiction_at_point(p_lat, p_lng)` — the body of
  `resolve_user_jurisdiction`, taking the point as arguments. `resolve_user_jurisdiction` becomes a
  thin wrapper that reads the stored point and calls it, so the Connected path does not change.
- `connect.resolve_congressional_2026_at_point(p_lat, p_lng)` — the same split for the 2026 map.

Both `SECURITY DEFINER`, `REVOKE ALL FROM PUBLIC`, `EXECUTE` to `service_role` only — the same ACL as the
existing resolvers, which the API calls through `adminRpc`.

### 3. Write path — rewrite `POST /api/account/set-location`

1. Geocode the address (the same external geocoder the Connected path uses).
2. Resolve districts at the point. In the 10 refreshed states, store the **2026** congressional
   district, not the old one: a basic row can never be re-resolved later, and the 2026 map is the
   one that stays true after the January 2027 promotion.
3. Upsert `inform.account_jurisdictions`.
4. Call `essentials.cache_user_districts(user, lat, lng)` (districts out, no point stored).
5. Drop the point and the address. Never log either.
6. Respond with the district names (the confirmation screen shows them) — never the address or
   point.

Also: stop the JSON write to `inform_profiles.last_essentials_location` in both this route and
`/location-hint` (0 rows, so nothing to migrate). The admin ProfilePage still reads the column;
it will simply find nothing. Dropping the column is a later clean-up.

### 4. Read path — one helper, then lift the Connected guard

A helper `getStoredJurisdiction(userId)` returns districts from `connected_profiles` for a
Connected account and from `inform.account_jurisdictions` otherwise. Then:

| Route | Change |
|---|---|
| `GET /api/account/me` (`accountMeService`) | jurisdiction block from the helper; `location_consent` true when either source has a row |
| `GET /api/account/me/jurisdiction` | `requireConnected` → `requireAuth`, read via helper |
| `GET /api/essentials/representatives/me` | same; basic rows use the stored-geo-id path; no point-based fallback applies |
| `GET /api/essentials/elections/me` | same |
| `profileService` owner view | `location_consent` from either source |

Unchanged on purpose: `POST /api/civic-spaces/assign` (stays Connected-only), the Connected
write path, the identity vault, `districtStalenessService` (Connected only).

### 5. The app

`LocationStep` posts to `/account/set-location` for a basic user and `/connect/set-location` for a
Connected one (`user.tier` is already in the auth store). The PR #1280 message stays for any
Connected-only route, and stops appearing on this page.

### 6. When a basic account becomes Connected

Nothing is copied. `readStoredJurisdiction` prefers a Connected row only when it holds a location
(the flag, a point, or any stored district), so a promoted account keeps reading its basic
districts until it enters an address on the Connected path. `POST /api/connect/set-location` then
deletes the basic row. This needs no change to the three enrollment paths (`signup_with_invite`,
`complete_connect_flow`, admin promotion). Until the address is re-entered, the weekly re-check does
not cover the account, because there is no point to re-check.

## Known costs

- **No automatic update after redistricting.** A basic row is fixed at the time it was entered.
  When a boundary set is reloaded, rows with `resolved_at` older than the load should be asked to
  confirm their address. Not built in this change; `resolved_at` makes it possible later.
- **Civic Spaces still shows basic users the "Add your address" screen after they add one**,
  because `/assign` refuses them. What a basic account with an address should see there (its own
  places, read-only) is a separate Civic Spaces change and a product question.
- Districts narrow a person to an area. They are less identifying than a point, not anonymous.

## Tests

- `account.setLocation` route tests: stores districts; stores no point or address anywhere
  (assert the row and `inform_profiles` after the call); never echoes them; 2026 congressional
  district chosen in a refreshed state.
- Helper tests: Connected source wins; basic source used otherwise; neither → null.
- Guard test: `/assign` still refuses inform (pin it).
- Migration post-verify gate: wrapper and point function return the same row for every Connected
  profile that has a point (dry-run against prod in `BEGIN … ROLLBACK`).
- Positive control: run the "stores no point" assertion against the current route, which does
  store one, and watch it fail first.

## Build order

1. Migration: table + two point functions + wrapper (dry-run, then apply).
2. Backend: write path, helper, read routes, tests.
3. App: endpoint choice in `LocationStep`; admin page clean-up.
4. Then decide the Civic Spaces question and the redistricting prompt.
