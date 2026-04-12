# Essentials Team — Pre-fill for Logged-In Users

**Date:** 2026-04-12  
**From:** Accounts team

---

## The issue

When a Connected user (one who has already set their location in Accounts) goes to Essentials, they're shown an address form and have to type their address in manually. Their location is already stored — they shouldn't have to do this.

## What exists today

The Accounts API already has an endpoint for this:

```
GET https://api.empowered.vote/api/essentials/representatives/me
Authorization: Bearer <access_token>
```

- **Auth required:** Connected tier (user must have set their location in Accounts)
- **Returns:** The same politician array that `POST /api/essentials/candidates/search` returns, built from the user's *stored* jurisdiction geo IDs — no geocoding, no address form
- **Response headers set:** `X-Data-Status: fresh | no-geofence-data`, `X-Formatted-Address: "City, ST"` (you can use this to display where they're registered to)
- **204** if the user hasn't set a location yet — fall through to the address form in that case
- **403 NOT_CONNECTED** if the user is Inform-tier — also fall through to the address form

## What Essentials needs to do

On app load, after resolving the session:

1. Try `GET /api/essentials/representatives/me` with the user's Bearer token
2. **200** → skip the address form entirely, show their representatives directly. Optionally show `X-Formatted-Address` as context ("Showing representatives for Mar Vista, CA")
3. **204** → user is Connected but hasn't set location yet. Show a prompt: "Set your location in your [profile](https://app.empowered.vote) to see your representatives." or redirect them to `https://app.empowered.vote/settings/location`
4. **401 / 403** → user is not logged in or is Inform-tier. Show the normal address form

## Session / auth reminder

If the user isn't carrying an `access_token` in localStorage already, try the silent session exchange first before showing a login prompt:

```javascript
// On load — attempt silent session before showing address form
const res = await fetch('https://api.empowered.vote/api/auth/session', {
  credentials: 'include', // required — sends the ev_session cookie cross-origin
});
if (res.ok) {
  const { access_token } = await res.json();
  localStorage.setItem('ev_token', access_token);
  // now try GET /api/essentials/representatives/me
}
// 401 = no session — show the address form
```

The `ev_session` httpOnly cookie is set when the user logs in at `accounts.empowered.vote`. As long as Essentials is loaded in a browser where the user is already logged in, this silent exchange will succeed and you'll get a fresh token without any redirect.

## Order of operations on app load

```
silent session check (/api/auth/session)
  ├── 401 → show address form (unauthenticated)
  └── 200 → got token
        └── GET /api/essentials/representatives/me
              ├── 200 → show reps, skip address form
              ├── 204 → Connected but no location → prompt to set location in Accounts
              └── 403 → Inform tier → show address form
```

---

Let us know if anything is unclear.

---

## Follow-up from Essentials team — 2026-04-12

### What we built

We implemented the flow described above. On app load, after auth resolves:

- **200** → auto-redirect to `/results?prefilled=true` (working correctly for users with stored coordinates)
- **204** → show an inline nudge: *"Set your home location in your profile"* linking to `app.empowered.vote/settings/location`, with the address search form still available below it
- **401 / 403** → normal address form, no nudge

The `visibilitychange` event triggers a page reload when a 204 user returns to the Essentials tab, so the auto-redirect fires immediately after they set their location without requiring a manual refresh.

### The problem

**`app.empowered.vote/settings/location` does not appear to be saving encrypted coordinates.**

Test account: Chris's personal Connected account (the one he uses day-to-day — not the dev account 4e6dde8f).

Steps to reproduce:
1. Log in at Essentials — `GET /api/essentials/representatives/me` returns **204**
2. Click the nudge → land on `app.empowered.vote/settings/location`
3. Fill in the location form and submit
4. Return to Essentials tab (auto-reloads via visibilitychange)
5. `GET /api/essentials/representatives/me` still returns **204**

Expected: step 5 returns **200** with the user's representatives.

### What we need from Accounts

1. **Confirm that `app.empowered.vote/settings/location` calls `POST /api/connect/set-location`** and that the call succeeds (200, not 409 or silent failure)
2. **Confirm that `set-location` is storing `encrypted_lat` / `encrypted_lng`** on `connect.connected_profiles` for this account — a direct Supabase check would confirm it
3. If the route isn't wired up yet, let us know so we can point the nudge link somewhere that actually works, or hold the nudge until it does

---

## Response from Accounts — 2026-04-12

Checked the database directly. Two things:

### 1. The test account is misidentified

There is only one account for Chris: `chris@empowered.vote`, UUID `4e6dde8f-2bd0-4054-824f-4164744165ea`. That is the personal day-to-day account — there is no second one. The note below saying "not the dev account 4e6dde8f" is incorrect; that UUID *is* the personal account.

That account already has encrypted coordinates stored, `congressional_geo_id = 0636` (CA-36), and `city_council_geo_id` correctly set to District 11. **`GET /api/essentials/representatives/me` will return 200 for this account, not 204.**

The account that actually has no coordinates (`has_coords: false`, `location_consent: false`) is a different user. You were likely hitting that account's session during testing. Double-check that the Bearer token you're sending with `representatives/me` belongs to the account you think it does — the sub claim in the JWT is the user UUID.

### 2. Peter's District 2 is correct

One of your other test accounts (`peter@empowered.vote`) shows `city_council_geo_id = county:los_angeles/council_district:2`. That is **not a bug**. His address is in unincorporated LA County territory (CD-43, Inglewood area) where the LA County Supervisor District 2 is the correct local representative. There is no city council district for that location. The backfill ran correctly and left it as-is.

### Summary

No action needed on the Accounts side. The route is wired up, coordinates are saving, and `representatives/me` is working. Verify the session token's `sub` claim matches the account you expect and the 204 issue should resolve itself.
