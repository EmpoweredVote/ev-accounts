# Issue Report: GET /essentials/representatives/me returns wrong results for connected users

**From:** Essentials Frontend Team
**To:** Accounts API Team
**Date:** 2026-03-30
**Priority:** Medium — workaround in place, but first-login UX is degraded

---

## What's happening

When a logged-in user with a saved home address loads the Essentials app, we call `GET /essentials/representatives/me` to show them their representatives without requiring them to re-enter their address. This is one of our core "Connected" user features.

The endpoint is returning the wrong results. For a user whose saved address is **12048 Culver Blvd, Los Angeles, CA 90066**, the endpoint returns:

- `X-Formatted-Address: "LOS ANGELES, CA"` (city/state only, not their actual address)
- ~67 politicians — a broad sweep of everyone whose district overlaps downtown Los Angeles
- Missing city-specific officials like **Karen Bass** (Mayor of LA) and **Traci Park** (LA City Council District 11)

The correct result for that address is ~17 politicians including Bass and Park, which we can confirm by querying the geofence directly:

```sql
SELECT p.full_name, o.title, d.district_type
FROM essentials.geofence_boundaries gb
JOIN essentials.districts d ON d.geo_id = gb.geo_id
JOIN essentials.offices o ON o.district_id = d.id
JOIN essentials.politicians p ON p.id = o.politician_id
WHERE ST_Covers(gb.geometry, ST_SetSRID(ST_MakePoint(-118.4264, 33.9936), 4326));
```

---

## What we think is wrong

The user's `connected_profiles` row has `encrypted_lat` and `encrypted_lng` set correctly (the address was geocoded when they ran `POST /connect/set-location`). However, the pre-computed district fields (`congressional_geo_id`, `state_senate_geo_id`, etc.) are all null:

```
home_address:                "12048 CULVER BLVD, LOS ANGELES, CA, 90066"
jurisdiction_state:          "CA"
jurisdiction_city:           "LOS ANGELES"
congressional_geo_id:        null
state_senate_geo_id:         null
state_house_geo_id:          null
county_geo_id:               null
encrypted_lat:               [set]
encrypted_lng:               [set]
```

Our best guess is that `GET /representatives/me` is falling back to the city/state text fields for the geofence lookup instead of using the encrypted coordinates — resulting in a city-center point query rather than the user's actual location.

---

## What we need

**The minimum fix we need:** `GET /essentials/representatives/me` should decrypt and use `encrypted_lat`/`encrypted_lng` for the geofence point-in-polygon query, rather than the city/state text fields. This should give us the correct ~15–20 politicians for the user's actual address.

**If possible, also:** When `POST /connect/set-location` is called, populate the pre-computed district geo_id fields (`congressional_geo_id`, `state_senate_geo_id`, `state_house_geo_id`, `county_geo_id`) from the geofence query at that time. This would make the `representatives/me` call faster and more reliable going forward.

---

## Current frontend workaround

We've added a session-scoped patch: after a user manually searches an address, we cache those results in memory so the correct representatives show for the rest of that session. But this doesn't survive a page reload or a fresh login — the user still gets the city-level list on first load.

We're happy to remove this workaround once the endpoint is fixed.

---

## Questions for you

1. Is the encrypted coordinate path in `representatives/me` intentionally bypassed, or is this a bug in the fallback logic?
2. Is there a utility in the Accounts API that already does the reverse-geocode against `essentials.geofence_boundaries`? We want to make sure any fix uses the same geofence data that `/candidates/search` uses, not a separate geometry table.
3. What's the right key management path for decrypting `encrypted_lat`/`lng` in a new code path?

Happy to jump on a call or provide more query output if helpful.
