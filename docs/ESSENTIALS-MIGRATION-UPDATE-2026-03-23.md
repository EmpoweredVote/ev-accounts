# Essentials API — Migration Update for Transparent Motivations

**Date:** 2026-03-23
**Audience:** Transparent Motivations / Essentials team
**Purpose:** Summary of what changed since the Essentials Integration Guide (2026-03-19) was written. Read this alongside `ESSENTIALS-INTEGRATION.md` — it does not replace it.

---

## TL;DR

We completed a full platform consolidation (v1.6) on 2026-03-23. The Go backend is retired. The Empowered Accounts Express API at `https://accounts.empowered.vote/api` is now the single authoritative backend for all Essentials data. Several new endpoints were added, one response shape changed, and one field definition was corrected. Read this document before building against the API.

---

## 1. Base URL Change

The old Render-assigned URL (`ev-accounts-api.onrender.com`) is retired. Any hardcoded references must be updated.

**New canonical base URL (production):**
```
https://accounts.empowered.vote/api
```

This is the same URL the Auth Hub runs on. The API is mounted at `/api`.

---

## 2. New Endpoints

### 2a. Address-Based Candidate Search

`POST /api/essentials/candidates/search`

Accepts a street address and returns the matching politician set — the same result as `GET /address-search` but as a POST with a JSON body. Use this when you need to send a structured address object rather than a raw query string.

**Request body:**
```json
{ "address": "123 Main St, Indianapolis, IN 46204" }
```

**Response:** an array of politician records (same shape as `GET /address-search`)

**Headers on response:**
- `X-Data-Status: fresh | no-geofence-data`
- `X-Formatted-Address: <string>` — the address as parsed by the Census geocoder

> **Note:** This endpoint was missing and returning 404 at the time of initial cutover. It is now live. If you were routing around this with the GET form, you can switch to POST.

---

### 2b. Quotes (Read & Rank)

`GET /api/essentials/quotes`

Returns the full dataset needed to power the Read & Rank experience.

**Auth:** None — fully public.

**Response shape:**
```typescript
{
  quotes: Array<{
    id: string;
    text: string;
    candidateId: string;   // essentials.politicians UUID
    issue: string;         // compass_topic UUID (NOT a slug)
    sourceUrl?: string;
    sourceName?: string;
  }>;
  candidates: Array<{
    id: string;
    name: string;
    party: string;
    office: string;
    photo: string;
    alignmentPercent: number;  // always 0 from this endpoint — compute on client
    issuesAligned: number;     // always 0 from this endpoint
    totalIssues: number;       // always 0 from this endpoint
  }>;
  issues: Array<{
    id: string;      // compass_topic UUID
    title: string;   // e.g. "Medicare/Medicaid"
    question: string;
  }>;
}
```

**Important:** `quote.issue` is a **UUID** matching `inform.compass_topics.id`, not a topic_key slug. Link quotes to compass topics by UUID, not by slug.

**Known gap:** quotes whose `topic_key` is `"medicare"` do not match any compass topic (the stored short_title is `"Medicare/Medicaid"`, not `"Medicare"`). Those quotes are excluded from this endpoint's response until the data is corrected. This is a known content data issue, not an API contract issue.

---

### 2c. Browse-by-Location (No Geocoding Required)

Three new endpoints provide a drill-down location selection flow that does not require a user to type an address. This is the alternative to `GET /address-search` for users who don't know their address or prefer to browse by area.

#### `GET /api/essentials/browse/states`

Returns all states that have politician data. Use this to populate a state picker.

**Response:** array of `{ state: string, state_name: string }` objects.

#### `GET /api/essentials/browse/states/:state/areas`

Returns counties, cities, and townships for the given state (2-letter abbreviation, case-insensitive).

**Response:** array of `{ geo_id, name, area_type, mtfcc }` objects.

#### `POST /api/essentials/browse/by-area`

Given a Census GEOID and MTFCC code, returns all politicians whose legislative districts overlap with that area using PostGIS intersection. This does not require geocoding — it uses the Census boundary files directly.

**Request body:**
```json
{ "geo_id": "18097", "mtfcc": "G4020" }
```

**Response:** array of politician records (same flat shape as address-search)

**Header on response:**
- `X-Data-Status: fresh | no-geofence-data`

MTFCC codes in use:
| Code | Meaning |
|------|---------|
| G4110 | Congressional district |
| G5420 | State senate district |
| G5220 | State house district |
| G4020 | County |
| G6350 | School district |

---

## 3. Response Shape Changes

### 3a. `GET /api/essentials/politicians` — Grouping Key Changed

The group key changed from `office_title` to `party`. The response structure is:

```typescript
// OLD (DO NOT USE)
{ office_title: string; incumbent: Politician | null; candidates: Politician[] }

// NEW
{ party: string; incumbent: Politician | null; candidates: Politician[] }
```

If your code grouped politicians by office title, update the field reference.

### 3b. Politician Records — `district_id` vs. `geo_id` Are Now Two Separate Fields

This was a bug that shipped and has been corrected. Previously, `district_id` was returning the raw Census GEOID (e.g., `"1805860"`). It now returns the human-readable district identifier (e.g., `"At Large"` or `"6"`).

The raw Census GEOID is now returned separately as `geo_id`.

**Updated interface:**
```typescript
interface PoliticianRecord {
  // ... other fields unchanged ...
  district_id: string;   // human-readable: "6", "At Large", "30", etc.
  geo_id: string;        // Census TIGER/Line GEOID: "1805860", "18097", etc.
  district_type: string; // "congressional" | "state_senate" | "state_house" | "county" | "school_district"
}
```

**Matching politicians to a user's jurisdiction:**

From `GET /api/account/me`, `jurisdiction.congressional_district` returns the Census GEOID (e.g., `"1807"`). To match politicians, compare against `geo_id`, not `district_id`:

```typescript
const myReps = politicians.filter(p =>
  p.district_type === 'congressional' &&
  p.geo_id === me.jurisdiction.congressional_district
);
```

> This is a **breaking change** from any code that was matching `district_id` against jurisdiction GEOIDs. Update all jurisdiction matching logic to use `geo_id`.

### 3c. Politician Records — `is_incumbent` Now Included in Address Search

Address-search responses now include `is_incumbent: boolean` on each politician record. This was previously missing. If you were inferring incumbency from other fields, you can now use this directly.

### 3d. Politician Photos — Now Populated

Politician images were returning as empty `[]` in all responses due to an unreachable code path (a `return` statement placed before the batch-fetch call). This is fixed. Photos are now fetched and returned correctly.

---

## 4. Geocoding Change

The geocoder was switched from Google Maps to the **US Census Geocoder** (free, no API key required).

**Impact for Essentials:** No integration change required. The address-search interface is identical. Error codes are slightly different:

| Situation | Old code | New code |
|-----------|----------|----------|
| Network/timeout failure | `GEOCODING_API_ERROR` | `GEOCODER_UNAVAILABLE` |
| Low-confidence match | `LOW_CONFIDENCE` | (now treated as `ADDRESS_NOT_FOUND`) |

If you were catching `GEOCODING_API_ERROR` or `LOW_CONFIDENCE`, update to `GEOCODER_UNAVAILABLE` and `ADDRESS_NOT_FOUND` respectively.

---

## 5. `inform.politicians` Table Dropped

The `inform.politicians` table no longer exists. `essentials.politicians` is now the sole source of truth for all politician data across the platform.

**Impact for Essentials:** None if you are only calling the API. This only matters if you or your data team have any scripts or pipelines that query the Supabase database directly and reference `inform.politicians`. Those must be updated to `essentials.politicians`.

---

## 6. Platform Architecture (For Context)

The following changes completed during the consolidation are worth knowing as context, but don't affect the Essentials API surface:

- **Go backend retired.** All routes previously served by the Go server are now served by the Accounts Express API. You should not have any direct calls to the Go backend.
- **All 4 frontends now use the Auth Hub.** CompassV2, Profile Hub, Read & Rank, and Essentials all authenticate through `accounts.empowered.vote`. The hash-fragment token delivery described in `ESSENTIALS-INTEGRATION.md` Section 7 is live and confirmed working.
- **RLS enabled on all schemas.** All 69 tables across 6 schemas now have Row Level Security enabled. This does not change the API surface but it means direct Supabase client access patterns (if any exist in your codebase) must use the authenticated client.

---

## 7. Known Gaps (Do Not Block On)

These are known issues that will be addressed in future work:

| Gap | Impact | Status |
|-----|--------|--------|
| CA geofence boundaries incomplete | Address search for CA returns only ~3 reps (LOCAL, STATE_UPPER, LOCAL_EXEC) instead of full set | Fix: TIGER files for cd119, sldl, sldu, county, unsd need to load via RUNBOOK-TIGER-LOAD.md |
| `medicare` topic_key mismatch | Quotes with `topic_key = "medicare"` excluded from `/essentials/quotes` | Content data fix needed — not an API contract issue |
| Essentials XP provisioning | `essentials-rep-lookup` XP source not yet wired to a service key | Deferred to v1.7 — do not attempt XP awards until Accounts team confirms key is provisioned |

---

## 8. What Has NOT Changed

Everything in `ESSENTIALS-INTEGRATION.md` that is not listed above remains accurate:

- Auth flow (redirect → hash fragment → `ev_token` → Bearer header)
- Jurisdiction principle (never re-ask Connected users for address)
- Three-tier access states (Inform / Connected with jurisdiction / Connected without)
- `/api/account/me` response shape
- XP and gem award endpoints and idempotency pattern
- Error response shape (`{ code, message }`)
- All entity routes (`/politicians/:id`, `/governments/:id`, `/chambers/:id`, `/districts/:id`)
- All legislative subroutes (`/:id/bills`, `/:id/votes`, `/:id/committees`, etc.)

---

*Generated from ev-accounts master @ 5cf67fa — 2026-03-23*
