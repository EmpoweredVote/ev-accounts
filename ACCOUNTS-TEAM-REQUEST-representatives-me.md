# Request: Precise Representative Lookup via `GET /essentials/representatives/me`

**From:** Essentials Frontend Team
**To:** Accounts API Team
**Date:** 2026-03-29
**Priority:** Medium — current workaround is in place, but it degrades first-session UX for logged-in users

---

## Background

Empowered Vote has a "Connected" user concept: authenticated users can save their home address to their profile so the Essentials app can automatically show them their full slate of elected representatives on login — no address re-entry required.

The frontend uses `GET /essentials/representatives/me` to power this experience. When a Connected user logs in, this endpoint is called during app initialization. If it returns data, the user is immediately redirected to their personalized results page without ever seeing the address input form.

This is a high-value UX feature — the goal is that a returning user opens the app and sees their reps in under two seconds.

---

## The Problem

`GET /essentials/representatives/me` currently geocodes at the **city level**, not the **address level**.

### What we observe

- The endpoint returns `X-Formatted-Address: "LOS ANGELES, CA"` — city/state only, not the user's street address
- It returns ~67 politicians for a Los Angeles user — a broad sweep of officials whose geofences overlap the geographic center of the city
- City-district-specific officials are **missing from the results**:
  - **Karen Bass** (Mayor of Los Angeles) — her `LOCAL_EXEC` geofence covers all of LA city, but apparently not the city-center point being used
  - **Traci Park** (LA City Council, District 11) — her geofence covers Playa Vista / Mar Vista / Pacific Palisades, not downtown LA

### Root cause (inferred from the data model)

The `connect.connected_profiles` table stores:
- `encrypted_lat` / `encrypted_lng` — the user's precise geocoded coordinates (AES-encrypted)
- `home_address` — the plain-text address string
- `jurisdiction_state` / `jurisdiction_city` — city/state strings (e.g., "CA" / "LOS ANGELES")
- Pre-computed district fields: `congressional_geo_id`, `state_senate_geo_id`, `state_house_geo_id`, `county_geo_id`, `school_district_geo_id` — and their name counterparts

When `POST /connect/set-location` is called, it correctly geocodes the full street address and stores the encrypted coordinates and city/state. However, the **pre-computed district geo IDs are not populated**, and `GET /representatives/me` appears to be using the city/state text fields for its lookup rather than decrypting the precise coordinates.

The result is a city-center point-in-polygon query instead of the user's actual location — missing any officials whose districts don't overlap downtown.

### Confirmed data state (via Supabase query)

The user's `connected_profiles` row at time of investigation:

```
home_address:               "12048 CULVER BLVD, LOS ANGELES, CA, 90066"
jurisdiction_state:         "CA"
jurisdiction_city:          "LOS ANGELES"
county_name:                null
congressional_district_name: null
state_senate_district_name:  null
state_house_district_name:   null
encrypted_lat:              [set]
encrypted_lng:              [set]
location_set_at:            2026-03-29T06:49:19Z
```

A direct PostGIS query using approximate coordinates for that address confirms the **correct** 17 politicians, including Bass and Park:

```sql
SELECT p.full_name, o.title, d.district_type
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-118.4264, 33.9936), 4326));
-- Returns: Karen Ruth Bass (Mayor), Traci Park (Council Member), Ted Lieu (Rep),
--          Lola Smallwood-Cuevas (Senator), Isaac Bryan (Assembly),
--          Holly Mitchell (Supervisor), Nathan Hochman (DA), and more
```

---

## What We're Asking For

We need two things from the Accounts team. They are independent and can be shipped separately.

---

### Ask 1 — Fix `GET /essentials/representatives/me` to use encrypted coordinates

**What:** When handling `GET /essentials/representatives/me`, decrypt `encrypted_lat` and `encrypted_lng` from `connected_profiles` and use those coordinates for the geofence point-in-polygon query, rather than (or as a fallback from) the city/state text fields.

**Expected behavior after fix:**
- `X-Formatted-Address` response header returns the user's full formatted street address (e.g., `"12048 CULVER BLVD, LOS ANGELES, CA 90066"`) — or at minimum a ZIP-level string, not just city/state
- The returned politician list matches what `POST /essentials/candidates/search` returns for the same address — approximately 15–20 politicians for a typical US address, all district-specific
- City-level officials (Mayors, City Council members) are included when the address falls within a city

**No frontend changes required** once this is fixed — we already handle the response correctly.

---

### Ask 2 — Populate pre-computed district fields at `set-location` time, and keep them fresh

**Context:** The `connected_profiles` table has fields for pre-computed district geo IDs:

```
congressional_geo_id          congressional_district_name
state_senate_geo_id           state_senate_district_name
state_house_geo_id            state_house_district_name
county_geo_id                 county_name
school_district_geo_id        school_district_name
jurisdiction_state
jurisdiction_city
```

These fields are currently null for most users despite encrypted coordinates being present.

**What we'd like:** When `POST /connect/set-location` is called (or on the next login for existing users), decrypt the coordinates and reverse-geocode them to populate all district fields. This gives the platform several benefits:

1. **Faster `representatives/me` queries** — look up by geo_id instead of a live point-in-polygon every request
2. **Offline eligibility checks** — know a user's congressional district without a DB geometry query
3. **Targeting and notifications** — "notify users in State Senate District 28 about this bill" becomes a simple indexed column lookup
4. **Ballot matching** — jurisdictions can be matched to election records without coordinates

**Suggested implementation:**

```
POST /connect/set-location
  → geocode address → encrypt + store lat/lng  (already working)
  → run reverse-geocode against essentials.geofence_boundaries
  → write geo_ids and names to connected_profiles
  → return updated profile (including district names) in response body
```

---

### Ask 3 — Weekly / daily staleness check for active users

District boundaries change: redistricting cycles, annexations, special district changes. We'd like a background job that:

- Runs daily (or at minimum weekly)
- For each `connected_profiles` row where `location_set_at` is not null and `encrypted_lat`/`encrypted_lng` are set
- Re-runs the reverse-geocode and updates the district fields if any have changed
- Updates a `districts_last_verified_at` column (new column, or reuse `location_set_at`)

This ensures that a user who set their address two years ago still gets correct reps after a redistricting.

---

## Privacy Model

To be clear about what we are and are not asking the Essentials frontend to receive:

| Data | Essentials frontend receives? | Notes |
|---|---|---|
| Raw street address | **No** | Never leaves the Accounts API |
| Encrypted coordinates | **No** | Decrypted only server-side |
| Formatted address string | **Yes** (already, via `X-Formatted-Address` header) | Used only to display "Showing results for 12048 Culver Blvd…" |
| District geo IDs | **No** | Used server-side for the geofence query |
| Politician list | **Yes** | The output of the geofence lookup |

The Essentials frontend never needs the raw address or coordinates — it only needs the resulting politician list and a display-safe formatted address string.

---

## Current Frontend Workaround

While the above is not yet fixed, we've implemented a session-scoped workaround on the Essentials frontend:

- After a logged-in user performs a manual address search (which calls `POST /essentials/candidates/search` and returns the correct politician list), we write those results directly into the in-memory `myRepresentatives` context
- This means a user who does a search in their session will get correct data for the duration of that session
- **The workaround does not survive a page reload or fresh login** — on first load, `GET /representatives/me` is still called and still returns the city-level list

The workaround commit: `fix(prefilled): update context with search results instead of re-calling /representatives/me` (2026-03-29)

We are happy to remove this workaround once Ask 1 is resolved.

---

## Acceptance Criteria

**Ask 1 is resolved when:**
- `GET /essentials/representatives/me` for user `4e6dde8f-2bd0-4054-824f-4164744165ea` returns Karen Bass and Traci Park in the response body
- `X-Formatted-Address` contains a street-level or ZIP-level address, not just city/state

**Ask 2 is resolved when:**
- After `POST /connect/set-location` succeeds, the user's `connected_profiles` row has non-null values for at least `congressional_geo_id`, `state_senate_geo_id`, `state_house_geo_id`, and `county_geo_id`

**Ask 3 is resolved when:**
- A background job exists and is scheduled to run at least weekly
- It updates district fields when a user's stored location no longer matches current geofence data

---

## Questions for the Accounts Team

1. Is the encrypted coordinate path in `representatives/me` intentionally bypassed, or is it a bug?
2. Is there an existing reverse-geocode utility in the Accounts API that we could point at the essentials geofence table?
3. Would it be easier to expose a `GET /connect/profile/jurisdiction` endpoint that returns the district fields directly (so the Essentials app could call that and then call its own geofence query), rather than having Accounts do the geofence query internally?
4. What is the key management story for `encrypted_lat`/`encrypted_lng`? We want to make sure any server-side decryption in a new code path uses the same key correctly.
