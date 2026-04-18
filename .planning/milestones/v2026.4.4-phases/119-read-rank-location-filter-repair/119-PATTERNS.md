# Phase 119: Read & Rank Location Filter Repair — Pattern Map

**Mapped:** 2026-04-15
**Files analyzed:** 6 (2 modified frontend, 4 read-only backend/config)
**Analogs found:** 6 / 6

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `read-rank/src/components/IssueHub.tsx` (modify) | component | request-response + event-driven | `read-rank/src/components/AddressFilterInput.tsx` | exact |
| `read-rank/src/data/api.ts` (modify if needed) | utility | request-response | `read-rank/src/lib/auth.ts` | role-match |
| `ev-accounts/backend/src/index.ts` (modify if needed) | config | — | `ev-accounts/backend/src/lib/env.ts` | role-match |
| `ev-accounts/backend/src/routes/essentials.ts` (read-only/verify) | route | request-response | `ev-accounts/backend/src/routes/essentialsBrowse.ts` | exact |
| `ev-accounts/backend/src/routes/essentialsBrowse.ts` (verify/fix if needed) | route | request-response | `ev-accounts/backend/src/routes/essentialsCandidates.ts` | exact |
| `read-rank/render.yaml` (verify/fix if needed) | config | — | `ev-accounts/render.yaml` | role-match |

---

## Pattern Assignments

### `read-rank/src/components/IssueHub.tsx` (component, event-driven)

**Primary change:** Insert zero-state empty message after `AddressFilterInput` block and before the issue card list. This is the only net-new UI element in the phase.

**Analog:** `read-rank/src/components/AddressFilterInput.tsx`

**Imports pattern** (IssueHub.tsx lines 1–7 — existing, no changes needed):
```tsx
import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useReadRankStore } from '../store/useReadRankStore';
import type { IssueData, Quote } from '../store/useReadRankStore';
import { fetchQuotesData, getQuotesForIssue } from '../data/api';
import { shuffleArray } from '../utils/matchingAlgorithm';
import { AddressFilterInput } from './AddressFilterInput';
```

**Store access pattern** (IssueHub.tsx line 37 — existing, add `clearLocationFilter`):
```tsx
// Current:
const { issueProgress, selectIssue, locationFilter } = useReadRankStore();

// After change — add clearLocationFilter:
const { issueProgress, selectIssue, locationFilter, clearLocationFilter } = useReadRankStore();
```

**Filter predicate** (IssueHub.tsx lines 58–69 — existing, do not change):
```tsx
// Filter issues to only show those with 2+ unique local politicians who have quotes
const filteredIssues = locationFilter
  ? issues.filter(issue => {
      const localPoliticianSet = new Set(locationFilter.politicianIds);
      const uniqueLocalReps = new Set(
        quotes
          .filter(q => q.issue === issue.id && q.candidateId && localPoliticianSet.has(q.candidateId))
          .map(q => q.candidateId as string)
      );
      return uniqueLocalReps.size >= 2;
    })
  : issues;
```

**Zero-state empty message** — INSERT after the `AddressFilterInput` block (after line 151) and before the issue card list `<div>` (line 154). This is from the UI-SPEC and RESEARCH.md code examples:
```tsx
{/* Zero-state: location filter active but no qualifying issues */}
{locationFilter !== null && displayedIssues.length === 0 && (
  <motion.div
    className="max-w-2xl mx-auto text-center py-12"
    initial={{ opacity: 0, y: 8 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ duration: 0.3 }}
  >
    <p style={{
      fontFamily: "'Manrope', sans-serif",
      fontSize: '0.9375rem',
      fontWeight: 700,
      color: '#1a1a2e',
      marginBottom: '0.5rem',
    }}>
      No issues with local quotes for this area
    </p>
    <p style={{
      fontFamily: "'Manrope', sans-serif",
      fontSize: '0.8125rem',
      fontWeight: 400,
      color: '#64748b',
      lineHeight: 1.5,
      marginBottom: '1rem',
    }}>
      We don&apos;t have quotes from your representatives for any issues yet.
    </p>
    <button
      className="ev-button-secondary"
      onClick={clearLocationFilter}
    >
      Clear location filter
    </button>
  </motion.div>
)}
```

**Framer Motion motion pattern** (IssueHub.tsx lines 92–97 — copy for zero-state wrapper):
```tsx
// Existing entrance animation pattern used throughout IssueHub:
<motion.div
  initial={{ opacity: 0, y: 12 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
>
// Zero-state uses lighter: initial={{ opacity: 0, y: 8 }}, duration: 0.3 (per UI-SPEC)
```

**Loading state pattern** (IssueHub.tsx lines 75–87 — reference for conditional rendering structure):
```tsx
if (loading) {
  return (
    <div className="text-center py-16">
      <div
        className="inline-block w-6 h-6 border-2 rounded-full animate-spin"
        style={{ borderColor: '#e8e2d9', borderTopColor: '#00657c' }}
      />
      <p className="mt-4" style={{ fontFamily: "'Manrope', sans-serif", color: '#64748b', fontSize: '0.9375rem' }}>
        Loading issues...
      </p>
    </div>
  );
}
```

**Error/empty inline style conventions** (AddressFilterInput.tsx lines 259–263):
```tsx
// Error text uses color '#e64a34' — do NOT use for zero-state (it's informational, not an error)
<p style={{ color: '#e64a34', fontFamily: "'Manrope', sans-serif", fontSize: '0.8125rem', marginTop: '0.375rem' }}>
  No representatives found with quotes for this address.
</p>
// Zero-state heading uses '#1a1a2e' ink; body uses '#64748b' warm-slate (per UI-SPEC)
```

---

### `read-rank/src/data/api.ts` (utility, request-response)

**Context:** Read-only/verify phase. Only modify if the API URL or quotes fallback is the diagnosed root cause.

**Analog:** `read-rank/src/lib/auth.ts`

**`apiFetch` wrapper pattern** (auth.ts lines 36–54 — used by all filter API calls):
```tsx
export async function apiFetch(path: string, options: RequestInit = {}): Promise<Response | null> {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers as Record<string, string> || {}),
    },
  });

  if (res.status === 401) {
    clearToken();
    redirectToLogin();
    return null;
  }

  return res;
}
```

**`fetchQuotesData` fallback pattern** (api.ts lines 16–35 — the silent mock fallback):
```tsx
// NOTE: uses plain fetch() — NOT apiFetch() — because /api/essentials/quotes is public (no auth)
// If this throws (network error, non-ok response), it falls back to MOCK DATA silently.
// During diagnosis: check DevTools Network tab to confirm /api/essentials/quotes returns 200 with real data.
export async function fetchQuotesData(): Promise<QuotesResponse> {
  if (cachedData) return cachedData;
  try {
    const res = await fetch(`${API_BASE}/api/essentials/quotes`);
    if (!res.ok) throw new Error(`API error: ${res.status}`);
    const data: QuotesResponse = await res.json();
    cachedData = data;
    return data;
  } catch (err) {
    console.error('Failed to fetch quotes from API, falling back to mock data', err);
    const { allIssues, mockQuotes, mockCandidates } = await import('./mockData');
    return { quotes: mockQuotes, candidates: mockCandidates, issues: allIssues };
  }
}
```

**`searchPoliticians` pattern** (api.ts lines 58–78 — address mode path):
```tsx
// Uses apiFetch (not plain fetch) — goes through auth header handler
// Reads X-Data-Status and X-Formatted-Address from response headers
export async function searchPoliticians(query: string): Promise<SearchPoliticiansResult> {
  try {
    const res = await apiFetch('/essentials/candidates/search', {
      method: 'POST',
      body: JSON.stringify({ query }),
    });
    if (!res) {
      return { status: 'error', data: [], error: 'Unauthorized', formattedAddress: '' };
    }
    const status = res.headers.get('X-Data-Status') || res.headers.get('x-data-status') || '';
    const formattedAddress = res.headers.get('X-Formatted-Address') || res.headers.get('x-formatted-address') || '';
    if (!res.ok) {
      return { status: 'error', data: [], error: `${res.status} ${res.statusText}`, formattedAddress: '' };
    }
    const data: SearchPolitician[] = await res.json();
    return { status: status || 'fresh', data, formattedAddress };
  } catch (error) {
    return { status: 'error', data: [], error: (error as Error).message, formattedAddress: '' };
  }
}
```

---

### `ev-accounts/backend/src/index.ts` (config — CORS_ORIGIN)

**Context:** Read-only/verify. Modify only if `readrank.empowered.vote` is missing from the production `CORS_ORIGIN` env var on Render.

**Analog:** `ev-accounts/backend/src/lib/env.ts`

**CORS config pattern** (index.ts lines 54–72 — the exact-match allow-list):
```typescript
const allowedOrigins = env.CORS_ORIGIN
  ? env.CORS_ORIGIN.split(',').map((o) => o.trim())
  : [];

app.use(
  cors({
    origin: (origin, callback) => {
      if (!origin) return callback(null, true);           // same-origin / server-to-server
      if (env.NODE_ENV === 'development') return callback(null, true);  // dev: allow all
      if (allowedOrigins.includes(origin)) return callback(null, true); // prod: exact match
      callback(new Error(`CORS: origin ${origin} not allowed`));
    },
    credentials: true,
    exposedHeaders: ['X-Data-Updated-At', 'X-Data-Status', 'X-Formatted-Address'],
  })
);
```

**Fix pattern:** Add `readrank.empowered.vote` to the `CORS_ORIGIN` env var in the Render dashboard (comma-separated). This is a Render env var change, not a code change. The format is:
```
CORS_ORIGIN=https://existing-origin-1.empowered.vote,https://readrank.empowered.vote
```

---

### `ev-accounts/backend/src/routes/essentials.ts` (route, request-response)

**Context:** Read-only. The `/api/essentials/quotes` endpoint is verified working. Diagnosis only: confirm Monroe County quotes exist with matching `topic_key`.

**Analog:** `ev-accounts/backend/src/routes/essentialsBrowse.ts`

**Quotes endpoint pattern** (essentials.ts lines 191–265 — the critical JOIN and silent-drop filter):
```typescript
router.get('/quotes', async (_req: Request, res: Response): Promise<void> => {
  try {
    const { rows } = await pool.query(`
      SELECT
        q.id           AS quote_id,
        q.quote_text,
        q.politician_id,
        ...
        ct.id          AS topic_id,
        ct.topic_key   AS topic_key,
        ...
      FROM essentials.quotes q
      JOIN essentials.politicians p ON p.id = q.politician_id AND p.is_active = true
      LEFT JOIN essentials.offices o ON o.politician_id = p.id
      LEFT JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key)
      ORDER BY p.full_name, q.topic_key
    `);

    // CRITICAL: quotes with topic_id = null are SILENTLY DROPPED here
    const quotes = rows
      .filter((r) => r.topic_id !== null)
      .map((r) => ({
        id: r.quote_id,
        text: r.quote_text,
        candidateId: r.politician_id,  // UUID — same as what search/browse return
        issue: r.topic_key,            // slug — must match issues[].id
        ...
      }));
```

**Key linkage:** `quotes[].candidateId` = `r.politician_id` (UUID from `essentials.politicians.id`). This must match what `/essentials/candidates/search` and `/essentials/browse/by-area` return as politician `id` values.

---

### `ev-accounts/backend/src/routes/essentialsBrowse.ts` (route, request-response)

**Context:** Read-only/verify. Confirm browse endpoints return politicians for Monroe County. Inspect `by-area` response for Monroe County (`geo_id: "18105"`, `mtfcc: "G4020"`).

**Analog:** `ev-accounts/backend/src/routes/essentialsCandidates.ts`

**Browse by-area pattern** (essentialsBrowse.ts lines 63–85 — the PostGIS path):
```typescript
router.post('/by-area', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { geo_id, mtfcc } = req.body as { geo_id?: string; mtfcc?: string };

    if (!geo_id || typeof geo_id !== 'string' || !geo_id.trim()) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'geo_id is required' });
      return;
    }
    if (!mtfcc || typeof mtfcc !== 'string' || !mtfcc.trim()) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'mtfcc is required' });
      return;
    }

    const politicians = await getPoliticiansByArea(geo_id.trim(), mtfcc.trim());

    const dataStatus = politicians.length === 0 ? 'no-geofence-data' : 'fresh';
    res.setHeader('X-Data-Status', dataStatus);
    res.status(200).json(politicians);
  } catch (err) {
    console.error('[POST /essentials/browse/by-area] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});
```

**Search endpoint pattern** (essentialsCandidates.ts lines 66–93 — the Census Geocoder path):
```typescript
router.post('/search', optionalAuth, async (req: Request, res: Response): Promise<void> => {
  try {
    const { query, includeChallengers } = req.body as { query?: string; includeChallengers?: boolean };

    if (!query || typeof query !== 'string' || !query.trim()) {
      res.status(422).json({ code: 'VALIDATION_ERROR', message: 'query is required' });
      return;
    }

    const result = await getRepresentativesByAddress(query.trim(), { includeChallengers: !!includeChallengers });
    const dataStatus = result.politicians.length === 0 ? 'no-geofence-data' : 'fresh';
    res.setHeader('X-Data-Status', dataStatus);
    res.setHeader('X-Formatted-Address', result.matchedAddress);
    res.status(200).json(result.politicians);
  } catch (err: unknown) {
    const code = (err as { code?: string }).code;
    if (code === 'ADDRESS_NOT_FOUND' || code === 'PO_BOX_REJECTED') {
      res.status(422).json({ code, message: (err as Error).message });
      return;
    }
    if (code === 'GEOCODER_UNAVAILABLE') {
      res.status(503).json({ code, message: (err as Error).message });
      return;
    }
    console.error('[POST /essentials/candidates/search] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});
```

---

### `read-rank/render.yaml` (config — VITE_API_URL)

**Context:** Verify/fix. This file sets the production API URL baked into the Vite build.

**Current state** (render.yaml lines 8–9):
```yaml
- key: VITE_API_URL
  value: https://accounts-api.empowered.vote
```

**Conflict:** `read-rank/.env.production` contains `VITE_API_URL=https://ev-accounts-api.onrender.com` (old Render internal URL). Render service env vars from `render.yaml` override `.env.production` at build time — so `accounts-api.empowered.vote` should win. Confirm via DevTools Network tab in production.

**Analog:** `ev-accounts/render.yaml` (lines 8–9):
```yaml
- key: VITE_API_URL
  value: https://accounts-api.empowered.vote
```

Both render.yaml files use the same `accounts-api.empowered.vote` value — this is the intended API host.

---

## Shared Patterns

### Zustand Store Access
**Source:** `read-rank/src/store/useReadRankStore.ts` lines 559–560
**Apply to:** All read-rank components that touch the location filter
```tsx
// Location filter state — simple get/set/clear, no async
setLocationFilter: (filter) => set({ locationFilter: filter }),
clearLocationFilter: () => set({ locationFilter: null }),
```

The `LocationFilter` type (lines 82–85):
```tsx
export interface LocationFilter {
  address: string;
  politicianIds: string[];  // UUIDs from essentials.politicians.id
}
```

### apiFetch for Authenticated/Optional-Auth Routes
**Source:** `read-rank/src/lib/auth.ts` lines 36–54
**Apply to:** All `AddressFilterInput` API calls (browse/states, browse/by-area, candidates/search)
- Use `apiFetch` — NOT plain `fetch` — for all filter-path API calls
- Use plain `fetch` for `/api/essentials/quotes` (intentionally unauthenticated, has mock fallback)

### Framer Motion Entrance Animation
**Source:** `read-rank/src/components/IssueHub.tsx` lines 92–97
**Apply to:** Zero-state empty message wrapper
```tsx
// Full motion pattern in IssueHub uses ease + longer duration:
initial={{ opacity: 0, y: 12 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 0.5, ease: [0.22, 1, 0.36, 1] }}

// Zero-state uses simpler (per UI-SPEC):
initial={{ opacity: 0, y: 8 }}
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 0.3 }}
```

### Inline Style Conventions
**Source:** `read-rank/src/components/IssueHub.tsx` throughout
**Apply to:** Zero-state empty message text elements
```tsx
// All text: fontFamily: "'Manrope', sans-serif"
// Heading: fontWeight: 700, fontSize: '0.9375rem', color: '#1a1a2e'
// Body: fontWeight: 400, fontSize: '0.8125rem', color: '#64748b', lineHeight: 1.5
// Error text (do NOT use for zero-state): color: '#e64a34'
```

### ev-button-secondary CSS Class
**Source:** `read-rank/src/index.css` (`.ev-button-secondary` class)
**Apply to:** Zero-state "Clear location filter" button
```tsx
// Use className="ev-button-secondary" — already defined in index.css
// Spec: border '1.5px solid #00657c', color '#00657c', background transparent,
//       border-radius '0.5rem', padding '0.5rem 1.5rem'
// Do NOT inline-style this button — use the class
```

### CORS Route Pattern
**Source:** `ev-accounts/backend/src/index.ts` lines 54–72
**Apply to:** Render env var fix for `CORS_ORIGIN`
```typescript
// CORS_ORIGIN is a comma-separated string parsed at startup:
// env.CORS_ORIGIN.split(',').map((o) => o.trim())
// Add 'https://readrank.empowered.vote' to this list in Render dashboard
// No code change needed — this is a runtime config change only
```

### optionalAuth Middleware
**Source:** `ev-accounts/backend/src/routes/essentialsBrowse.ts` lines 25, 41, 63
**Apply to:** All essentials browse and candidate search routes (already applied — verify unchanged)
```typescript
router.get('/states', optionalAuth, async (_req, res) => { ... });
router.get('/states/:state/areas', optionalAuth, async (req, res) => { ... });
router.post('/by-area', optionalAuth, async (req, res) => { ... });
```

---

## Diagnostic Patterns (Wave 0 — Run Before Any Code Changes)

### DB Audit — Monroe County Quotes
```sql
-- Confirm Monroe County politicians have quotes AND those quotes join to compass_topics
SELECT
  q.topic_key          AS quote_topic_key,
  ct.topic_key         AS compass_topic_key,
  ct.short_title,
  COUNT(q.id)          AS quote_count,
  CASE WHEN ct.id IS NULL THEN 'DROPPED' ELSE 'MATCHED' END AS status
FROM essentials.quotes q
LEFT JOIN inform.compass_topics ct ON ct.topic_key = lower(q.topic_key)
GROUP BY q.topic_key, ct.topic_key, ct.short_title, ct.id
ORDER BY status DESC, q.topic_key;

-- Also check: any quotes with null politician_id (would produce undefined candidateId)
SELECT COUNT(*) FROM essentials.quotes WHERE politician_id IS NULL;
```

### CORS Smoke Test
```bash
# Include -H "Origin: ..." to trigger CORS evaluation
# Look for Access-Control-Allow-Origin in response headers
curl -s -X POST https://accounts-api.empowered.vote/api/essentials/candidates/search \
  -H "Content-Type: application/json" \
  -H "Origin: https://readrank.empowered.vote" \
  -d '{"query": "401 N Morton St, Bloomington, IN 47404"}' \
  -v 2>&1 | grep -E "HTTP|Access-Control|id|full_name" | head -20
```

### Browse Smoke Test (Monroe County)
```bash
# geo_id 18105 = Indiana Monroe County (TIGER G4020 county FIPS)
curl -s -X POST https://accounts-api.empowered.vote/api/essentials/browse/by-area \
  -H "Content-Type: application/json" \
  -H "Origin: https://readrank.empowered.vote" \
  -d '{"geo_id": "18105", "mtfcc": "G4020"}' \
  -v 2>&1 | grep -E "HTTP|Access-Control|id|full_name" | head -30
```

---

## No Analog Found

None — all files have direct analogs in the codebase. The zero-state UI element has no standalone analog but is built entirely from existing patterns (Framer Motion, Manrope inline styles, `ev-button-secondary` class, `clearLocationFilter` action) already present in `IssueHub.tsx` and `AddressFilterInput.tsx`.

---

## Metadata

**Analog search scope:** `read-rank/src/`, `ev-accounts/backend/src/routes/`, `ev-accounts/backend/src/lib/`, `ev-accounts/backend/src/index.ts`
**Files scanned:** 10 source files + 2 render.yaml configs + 1 UI-SPEC + CONTEXT.md + RESEARCH.md
**Pattern extraction date:** 2026-04-15
