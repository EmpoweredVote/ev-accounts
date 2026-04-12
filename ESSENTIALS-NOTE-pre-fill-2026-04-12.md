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
