# Treasury Tracker — Location-Based Budget Routing

**Version:** 1.0 (2026-04-06)
**Audience:** Treasury Tracker frontend/backend developers
**Purpose:** Route an authenticated user to their local municipal budget automatically, using the jurisdiction stored in their Empowered Accounts Connected profile.

---

## How It Works

Empowered Accounts stores up to 12 jurisdiction fields on every Connected user's profile, resolved when they set their address. Treasury Tracker reads `jurisdiction.city` + `jurisdiction.state` from the accounts API, matches that against the treasury cities list, and navigates directly to that city's budget. If no match exists, or the user is not Connected, the app falls back to a default landing page.

**No geocoding required.** The jurisdiction is pre-resolved by ev-accounts at address-set time. Treasury Tracker just reads the stored result.

---

## Decision Tree

```
User loads Treasury Tracker
│
├─ Not authenticated?
│   └─ Show default landing page (with "Sign in to see your city" CTA)
│
├─ Authenticated but tier = "inform" (no jurisdiction)?
│   └─ Show default landing page (with "Complete your profile" CTA)
│
├─ Connected or Empowered, but jurisdiction.city is null?
│   └─ User hasn't set their address yet
│   └─ Show default landing page (with "Set your location" CTA linking to profile.empowered.vote)
│
├─ Connected or Empowered, jurisdiction.city + jurisdiction.state present?
│   │
│   ├─ Match found in treasury cities list (case-insensitive name + state)?
│   │   └─ Navigate to /city/{treasury_city_id}
│   │
│   └─ No match (city not yet in treasury)?
│       └─ Show "Your city isn't available yet" page
│           └─ Include city name so they know it tried
```

---

## Step-by-Step Integration

### Step 1 — Get the user's location

Call `GET /api/account/me` with the user's Bearer token. The `jurisdiction` object is present for Connected and Empowered users who have set their address. It is `null` for Inform users and for Connected users who haven't set a location yet.

```
GET https://api.empowered.vote/api/account/me
Authorization: Bearer {access_token}
```

Response fields you need:

```json
{
  "tier": "connected",
  "jurisdiction": {
    "city": "Los Angeles",
    "state": "CA",
    "county": "06037",
    "county_name": "Los Angeles County"
  }
}
```

> If `jurisdiction` is `null`, or `jurisdiction.city` is `null`, fall back to the default page.

### Step 2 — Get the treasury cities list

This endpoint requires no authentication and can be fetched once on app load (or cached — it changes infrequently).

```
GET https://api.empowered.vote/api/treasury/cities
```

Response shape:

```json
[
  {
    "id": "uuid",
    "name": "Los Angeles",
    "state": "CA",
    "entity_type": "city",
    "population": 3979576,
    "hero_image_url": "https://...",
    "available_datasets": [
      { "fiscal_year": 2024, "dataset_type": "adopted" },
      { "fiscal_year": 2023, "dataset_type": "adopted" }
    ],
    "created_at": "iso8601",
    "updated_at": "iso8601"
  }
]
```

### Step 3 — Match user city to treasury city

Match on `name` (case-insensitive) **and** `state`. Name alone is not sufficient — there are cities with the same name in different states.

```typescript
function findTreasuryCity(
  cities: TreasuryCity[],
  jurisdictionCity: string,
  jurisdictionState: string
): TreasuryCity | null {
  const cityNorm = jurisdictionCity.trim().toLowerCase();
  const stateNorm = jurisdictionState.trim().toUpperCase();

  return cities.find(
    (c) =>
      c.name.trim().toLowerCase() === cityNorm &&
      c.state.trim().toUpperCase() === stateNorm
  ) ?? null;
}
```

### Step 4 — Route or fall back

```typescript
async function routeToUserBudget(accessToken: string): Promise<RoutingResult> {
  // Fetch in parallel — no dependency between these two calls
  const [meRes, citiesRes] = await Promise.all([
    fetch('https://api.empowered.vote/api/account/me', {
      headers: { Authorization: `Bearer ${accessToken}` },
    }),
    fetch('https://api.empowered.vote/api/treasury/cities'),
  ]);

  const me = await meRes.json();
  const cities: TreasuryCity[] = await citiesRes.json();

  // No jurisdiction — Inform tier or no address set
  if (!me.jurisdiction?.city || !me.jurisdiction?.state) {
    return { type: 'no_location', tier: me.tier };
  }

  const match = findTreasuryCity(cities, me.jurisdiction.city, me.jurisdiction.state);

  if (match) {
    return { type: 'matched', cityId: match.id, cityName: match.name };
  }

  return {
    type: 'not_in_treasury',
    cityName: me.jurisdiction.city,
    state: me.jurisdiction.state,
  };
}
```

---

## Fallback Page Recommendations

| Case | Message | CTA |
|------|---------|-----|
| Not authenticated | "Sign in to jump straight to your city's budget" | "Sign In" → Auth Hub |
| Inform tier (no jurisdiction) | "Upgrade your account to get your local budget" | "Set Up Profile" → accounts.empowered.vote |
| Connected, no address | "Set your location to see your city's budget" | "Set Location" → profile.empowered.vote/location |
| City not in treasury yet | "We don't have {city name}'s budget yet" | "Browse All Cities" → /cities |

---

## Auth Hub Redirect (Sign In)

If the user isn't authenticated, send them to the Auth Hub with a `redirect` param so they land back on Treasury Tracker after login:

```
https://accounts.empowered.vote/login?redirect=https%3A%2F%2Ftreasurytracker.empowered.vote%2F
```

After a successful login, the Auth Hub redirects back and puts the `access_token` in the URL hash:

```
https://treasurytracker.empowered.vote/#access_token=eyJ...&token_type=bearer&...
```

Extract it:

```typescript
const hash = new URLSearchParams(window.location.hash.slice(1));
const token = hash.get('access_token');
if (token) {
  localStorage.setItem('ev_token', token);
  window.history.replaceState(null, '', window.location.pathname); // clean the hash
}
```

See [INTEGRATION-GUIDE-v2.md §3.3](./INTEGRATION-GUIDE-v2.md) for the full SSO flow.

---

## Notes & Gotchas

**City name matching is exact (normalized).** `"Los Angeles"` matches `"los angeles"` but `"LA"` does not match `"Los Angeles"`. The `jurisdiction.city` value is whatever Cicero/geocoder returned, which should be the full city name. If you see unexpected misses in production, log both sides of the comparison before the match.

**`jurisdiction.city` reflects the user's stored address, not their current IP.** A user who moved and hasn't updated their address will still get their old city. This is correct behavior — the platform trusts explicit address confirmation over inferred location.

**County ≠ City.** `jurisdiction.county` and `jurisdiction.county_name` are Census county FIPS codes and names (e.g., `"06037"` / `"Los Angeles County"`). Treasury cities are matched on `city` + `state`, not county. A future iteration could add county-level budget support using these fields.

**`available_datasets` tells you what fiscal years exist** for a given city before you make the budgets call. If the array is empty, the city is in the system but has no budget data loaded yet — treat it the same as "not in treasury" for routing purposes.

**CORS:** `treasurytracker.empowered.vote` is already in the API's CORS allowlist. No Render config change needed for production. For staging domains, coordinate with the accounts team.

---

## Quick Reference

| What you need | Where to get it |
|---------------|-----------------|
| User's city + state | `GET /api/account/me` → `jurisdiction.city`, `jurisdiction.state` |
| All treasury cities | `GET /api/treasury/cities` → array of `{ id, name, state, available_datasets }` |
| Budgets for a city | `GET /api/treasury/cities/{id}/budgets` |
| Budget detail + categories | `GET /api/treasury/budgets/{id}/categories` |
| Budget line items | `GET /api/treasury/budgets/{id}/line-items` |
| Natural language search | `GET /api/treasury/search?q=roads&city_id={uuid}&year=2024` |
| SSO login redirect | `https://accounts.empowered.vote/login?redirect={encodedReturnUrl}` |
