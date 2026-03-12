# Phase 82: Logged-In Sync - Research

**Researched:** 2026-03-12
**Domain:** Cross-app auth detection; authenticated verdict POST from EV-readrank; Essentials CompassContext API fetch for logged-in users
**Confidence:** HIGH

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SYNC-01 | Read & Rank POSTs verdicts to backend when user is logged in | EV-readrank has no auth context today; needs `useEffect` calling `GET /auth/me` to detect session, then `POST /compass/verdicts` when issue completes. Backend endpoint is live. |
| SYNC-02 | Essentials fetches logged-in user's verdicts from backend as highest-priority source | CompassContext.jsx already has the priority branch with a comment "API fetch deferred to Phase 82" — one fetch call to `GET /compass/verdicts` to insert at the top of the priority chain. |
</phase_requirements>

---

## Summary

Phase 82 is the final piece of the verdicts system. Both the backend (`GET /compass/verdicts`, `POST /compass/verdicts`) and the Essentials priority-chain scaffold were built in earlier phases specifically so this phase is additive only — no structural changes required.

**EV-readrank side (SYNC-01):** EV-readrank currently has no auth awareness. The app needs a lightweight auth check (`GET /auth/me`) on mount to determine if a session cookie is present, then a POST call to `POST /compass/verdicts` when an issue reaches the `results` phase. The verdict payload is already computed by `buildVerdictFragment` logic — the same `agreedQuotes`/`disagreedQuotes`/`rankedQuotes` arrays in `useReadRankStore` are the source of truth. The POST call must fire when an issue completes, not when the user clicks "View on Essentials" (which may never happen).

**Essentials side (SYNC-02):** `CompassContext.jsx` already has a `TODO` stub in the logged-in verdict block: `clearGuestVerdicts()` is called but no API fetch happens. The change is a single `fetchUserVerdicts()` call in `lib/compass.js` that hits `GET /compass/verdicts` and converts the array into the `{ [quote_id]: verdict }` map shape the context already expects.

**Primary recommendation:** In EV-readrank, add a `useAuthState` hook that calls `GET /auth/me` once on app mount and exposes `{ isLoggedIn, userId }`. When `setPhase('results')` is called and `isLoggedIn` is true, fire `POST /compass/verdicts` with the full current session verdict map. In Essentials, add `fetchUserVerdicts()` to `lib/compass.js` and call it inside the `authRes.ok` branch of `loadAll()` in CompassContext before `setVerdicts`.

## Standard Stack

### Core — EV-readrank
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Zustand | ^5.0.9 | Already manages all issue progress and verdicts | All quote verdict state lives here |
| React | ^19.2.0 | Component lifecycle for auth check hook | Already in use |
| Vite env (`VITE_API_URL`) | — | API base URL | Already used in `src/data/api.ts`; default `https://api.empowered.vote` |

### Core — Essentials
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React context | React 19 | CompassContext already exposes `verdicts` state | No new library needed |
| Native `fetch` | — | `GET /compass/verdicts` with `credentials: "include"` | All API calls in `lib/compass.js` use this pattern |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| EV-Backend `GET /auth/me` | live | Auth session check | Called once on mount in EV-readrank |
| EV-Backend `POST /compass/verdicts` | live (Phase 79) | Bulk upsert verdicts | Called when issue reaches results phase, user is logged in |
| EV-Backend `GET /compass/verdicts` | live (Phase 79) | Fetch user's full verdict set | Called in Essentials loadAll() when `authRes.ok` |

No new dependencies needed in either repo.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Auth check on mount | Piggyback on SiteHeader profileMenu prop | SiteHeader receives auth state passively; Read & Rank doesn't drive login/logout — only detect. Separate hook is cleaner. |
| POST on phase transition | POST periodically as user evaluates | Phase transition is the natural atomic boundary; POST once at completion is simpler and avoids partial state. |
| Store auth state in Zustand | Local React state in hook | Zustand persists to localStorage by default — auth state should NOT persist (session is server-authoritative). Local React state is correct. |

**Installation:** No new packages needed.

## Architecture Patterns

### Recommended Project Structure Changes

```
EV-readrank/src/
├── hooks/
│   ├── useDeviceType.ts        # exists
│   └── useAuthState.ts         # NEW — checks /auth/me, returns { isLoggedIn }
├── utils/
│   ├── verdictFragment.ts      # exists
│   └── verdictSync.ts          # NEW — buildVerdictPayload(), postVerdicts()
└── components/
    └── PhaseContainer.tsx      # MODIFY — call postVerdicts() when phase → results

essentials/src/
└── lib/
    └── compass.js              # MODIFY — add fetchUserVerdicts(); call in loadAll()
```

### Pattern 1: Auth Detection in EV-readrank

**What:** Single `GET /auth/me` on mount to detect existing session cookie. No login UI — Read & Rank is not an auth destination.
**When to use:** App mount, once. Result cached in component state (not persisted to Zustand/localStorage).
**Example:**

```typescript
// src/hooks/useAuthState.ts
// Source: pattern from CompassContext.jsx in essentials and CompassV2/src/pages/Login.jsx

const API_BASE = (import.meta.env as Record<string, string>).VITE_API_URL
  || 'https://api.empowered.vote';

interface AuthState {
  isLoggedIn: boolean;
  loading: boolean;
}

export function useAuthState(): AuthState {
  const [state, setState] = useState<AuthState>({ isLoggedIn: false, loading: true });

  useEffect(() => {
    fetch(`${API_BASE}/auth/me`, { credentials: 'include' })
      .then(res => setState({ isLoggedIn: res.ok, loading: false }))
      .catch(() => setState({ isLoggedIn: false, loading: false }));
  }, []);

  return state;
}
```

Key points:
- `credentials: 'include'` is mandatory — session cookie must accompany the request
- CORS is already configured for `readrank.empowered.vote` in `EV-Backend/internal/middleware/middleware.go`
- No username/password handling — only detect an existing cookie

### Pattern 2: Verdict Payload Construction and POST

**What:** Build the `[{quote_id, verdict}]` array from Zustand store state and POST to `/compass/verdicts`.
**When to use:** When `phase` transitions to `'results'` and `isLoggedIn` is true.
**Example:**

```typescript
// src/utils/verdictSync.ts
// Source: mirrors buildVerdictFragment (verdictFragment.ts) but produces API payload instead of URL fragment

import type { IssueProgress } from '../store/useReadRankStore';

const API_BASE = (import.meta.env as Record<string, string>).VITE_API_URL
  || 'https://api.empowered.vote';

interface VerdictPayload {
  quote_id: string;
  verdict: 'agreed' | 'disagreed';
}

export function buildVerdictPayload(
  issueProgress: Record<string, IssueProgress>
): VerdictPayload[] {
  const map = new Map<string, 'agreed' | 'disagreed'>();
  for (const progress of Object.values(issueProgress)) {
    for (const q of progress.agreedQuotes)    map.set(q.id, 'agreed');
    for (const q of progress.rankedQuotes)    map.set(q.id, 'agreed'); // idempotent
    for (const q of progress.disagreedQuotes) map.set(q.id, 'disagreed');
  }
  return Array.from(map.entries()).map(([quote_id, verdict]) => ({ quote_id, verdict }));
}

export async function postVerdicts(
  issueProgress: Record<string, IssueProgress>
): Promise<void> {
  const payload = buildVerdictPayload(issueProgress);
  if (payload.length === 0) return;
  try {
    await fetch(`${API_BASE}/compass/verdicts`, {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
  } catch (err) {
    // Fire-and-forget: log but don't surface to user
    console.warn('Failed to sync verdicts to backend:', err);
  }
}
```

Key points:
- `IssueProgress.rankedQuotes` is a subset of `agreedQuotes` — using `Map.set` is idempotent (same pattern as `buildVerdictFragment`)
- POST is fire-and-forget from the UX perspective: failure must not block the results phase render
- `quote_id` values in EV-readrank are the same UUIDs stored in the backend `compass.quotes` table (they came from `GET /essentials/quotes`)

### Pattern 3: Triggering POST on Issue Completion

**What:** Call `postVerdicts` when the phase transitions to `results` AND the user is logged in.
**When to use:** In `PhaseContainer.tsx` or by observing the Zustand phase state.
**Example:**

```typescript
// src/components/PhaseContainer.tsx — add useEffect watching phase

import { useAuthState } from '../hooks/useAuthState';
import { postVerdicts } from '../utils/verdictSync';

export const PhaseContainer: React.FC = () => {
  const { phase, issueProgress } = useReadRankStore();
  const { isLoggedIn } = useAuthState();

  useEffect(() => {
    if (phase === 'results' && isLoggedIn) {
      postVerdicts(issueProgress);
    }
  }, [phase, isLoggedIn]); // deps: fire when phase becomes 'results'

  // ... existing renderPhase() logic unchanged
};
```

Alternative: trigger inside `useReadRankStore.setPhase()` directly — but that would require injecting the API call into the Zustand store, which is an anti-pattern (stores should be pure state).

### Pattern 4: Essentials fetchUserVerdicts() and CompassContext Wiring

**What:** Add a `fetchUserVerdicts()` function to `essentials/src/lib/compass.js` that calls `GET /compass/verdicts` and converts the array response to the `{ [quote_id]: verdict }` object shape.
**When to use:** Inside the `if (authRes.ok)` block of `loadAll()` in `CompassContext.jsx`.
**Example:**

```javascript
// essentials/src/lib/compass.js — add this function

/**
 * Fetches the authenticated user's verdicts from the backend.
 * Returns { [quote_id]: 'agreed' | 'disagreed' } shape.
 * Returns {} on error or unauthenticated (should only be called when authRes.ok).
 */
export async function fetchUserVerdicts() {
  try {
    const res = await fetch(`${API}/compass/verdicts`, { credentials: 'include' });
    if (!res.ok) return {};
    const list = await res.json(); // [{ id, user_id, quote_id, verdict, created_at }]
    const map = {};
    for (const item of list) {
      map[item.quote_id] = item.verdict;
    }
    return map;
  } catch {
    return {};
  }
}
```

```javascript
// essentials/src/contexts/CompassContext.jsx — modify the verdict block

// Before (Phase 81 stub):
if (authRes.ok) {
  clearGuestVerdicts(); // API fetch deferred to Phase 82
}

// After (Phase 82 implementation):
if (authRes.ok) {
  newVerdicts = await fetchUserVerdicts();
  clearGuestVerdicts();
}
```

The `setVerdicts(newVerdicts)` call below this block already handles the populated map — no other changes needed in CompassContext.

### Anti-Patterns to Avoid

- **Persisting auth state in Zustand:** Auth state is session-cookie-driven and server-authoritative. Storing `isLoggedIn` in the persisted Zustand store would serve stale data after logout. Use local React state.
- **Blocking results render on POST:** `postVerdicts` must be fire-and-forget. Users should not see a spinner or error if the POST fails.
- **Calling POST on every quote verdict:** The correct trigger is phase transition to `results`, not individual swipe events. One POST with the full session payload is cleaner than many per-quote calls.
- **Deriving the verdict payload in the component:** The `buildVerdictPayload` logic belongs in a utility function (same pattern as `buildVerdictFragment`) — keeps the component thin.
- **Using GET /essentials/quotes response quote IDs directly as UUIDs in POST:** The `Quote.id` field in EV-readrank is a string (see `useReadRankStore.ts` line 5 `id: string`). The backend `POST /compass/verdicts` accepts `quote_id` as `uuid.UUID`. These should match already since they come from the same API, but the payload should send the string ID as-is (`json:"quote_id"` on the Go side accepts a valid UUID string).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auth session check | Custom cookie parsing / localStorage token | `fetch('/auth/me', { credentials: 'include' })` | Session is HTTP-only cookie; only the server can verify it |
| Verdict payload deduplication | Custom set logic | `Map.set()` with idempotent reassignment | Same pattern proven in `buildVerdictFragment` — handles rankedQuotes ⊂ agreedQuotes overlap |
| Backend retry logic | Custom exponential backoff | None — fire-and-forget is correct | Verdict loss on rare network failure is acceptable; re-sync happens on next visit when fragment/localStorage covers the gap |

**Key insight:** The backend is already built (Phase 79). The Essentials scaffold is already built (Phase 81, with the `clearGuestVerdicts()` stub). This phase is two small additions — a hook and a utility in EV-readrank, and one function + one call in Essentials.

## Common Pitfalls

### Pitfall 1: `credentials: 'include'` Missing on Either Fetch
**What goes wrong:** Auth check returns 401 even when user is logged in; verdict POST silently returns 401.
**Why it happens:** Session cookie is HTTP-only and only sent when `credentials: 'include'` is in the fetch options.
**How to avoid:** Every `fetch()` to `api.empowered.vote` must include `credentials: 'include'`. This is already the pattern in `essentials/src/lib/compass.js` — match it exactly.
**Warning signs:** `authRes.ok` is always false in EV-readrank even after logging in via CompassV2.

### Pitfall 2: Quote ID Type Mismatch
**What goes wrong:** POST returns 400 "invalid verdict value" or a GORM `invalid input syntax for type uuid` DB error.
**Why it happens:** `Quote.id` in the Zustand store is typed as `string`. The backend handler decodes `quote_id` as `uuid.UUID`. If the string is not a valid UUID format, Go's JSON decoder rejects it.
**How to avoid:** The IDs come from `GET /essentials/quotes` which returns them as `id::text` — verified UUIDs. No transformation needed; send as-is.
**Warning signs:** 400 responses from `POST /compass/verdicts`.

### Pitfall 3: POST Fires on Every Phase Render, Not Just Transition
**What goes wrong:** Multiple POST calls fire — once per re-render while in `results` phase.
**Why it happens:** `useEffect` without correct dependency array will re-fire. Using `[phase, isLoggedIn]` as deps means it fires whenever phase changes to results, but if both values remain stable (results phase held for a while), it fires only once. However, navigating away and back to results could fire it again.
**How to avoid:** Add a `hasSynced` ref or check inside `postVerdicts` — or accept idempotency: the backend upsert is idempotent (`clause.OnConflict` updates verdict on conflict), so duplicate POSTs are harmless but wasteful.
**Recommendation:** Use a `useRef(false)` sentinel that gets set to `true` after the first POST within a given component lifecycle. Reset is not needed — the store's `completed` flag per issue handles the multi-issue case.

### Pitfall 4: Essentials `fetchUserVerdicts` Called When Not Logged In
**What goes wrong:** Extra network call, 401 response, unnecessary error logging.
**Why it happens:** Called outside the `authRes.ok` guard.
**How to avoid:** `fetchUserVerdicts()` must only be called inside the `if (authRes.ok) { }` block in `loadAll()`. The function itself also returns `{}` on non-ok response as a safety net.

### Pitfall 5: EV-readrank Is a Separate Git Repo
**What goes wrong:** Commits go to workspace root git instead of `EV-readrank/.git`.
**Why it happens:** The workspace root is also a git repo. `git commit` from the wrong directory goes to the wrong repo.
**How to avoid:** All EV-readrank changes must be committed from `/Users/chrisandrews/Documents/GitHub/EV-readrank/`. This was documented in Phase 81 STATE decisions.

## Code Examples

Verified patterns from official sources:

### Auth Check Pattern (from CompassContext.jsx)
```javascript
// Source: essentials/src/contexts/CompassContext.jsx lines 50-51
const authRes = await fetch(`${API}/auth/me`, { credentials: "include" });
if (authRes.ok) {
  const authData = await authRes.json();
  setIsLoggedIn(true);
  setUserName(authData.username ?? null);
}
```

### Existing Verdict Priority Chain in CompassContext.jsx (Phase 81 scaffold)
```javascript
// Source: essentials/src/contexts/CompassContext.jsx lines 102-113
// Verdict priority: API (Phase 82, skip) > fragment > localStorage > empty
let newVerdicts = {};
if (authRes.ok) {
  // Logged-in: clear any stale guest verdicts (API fetch deferred to Phase 82)
  clearGuestVerdicts();
} else if (fragment && Object.keys(fragment.verdicts || {}).length > 0) {
  newVerdicts = fragment.verdicts;
  saveGuestVerdicts(newVerdicts);
} else {
  newVerdicts = loadGuestVerdicts() || {};
}
```

Phase 82's change: replace the `clearGuestVerdicts()` stub with `newVerdicts = await fetchUserVerdicts(); clearGuestVerdicts();`.

### GET /compass/verdicts Response Shape (from Phase 79 backend implementation)
```go
// Source: EV-Backend/internal/compass/handlers.go — GetVerdicts
// Returns JSON array: [{ "id": "...", "user_id": "...", "quote_id": "uuid", "verdict": "agreed"|"disagreed", "created_at": "..." }]
// Empty array [] (never null) when user has no verdicts
```

The `quote_id` field in the response matches the `Quote.id` in EV-readrank's Zustand store.

### POST /compass/verdicts Request Body (from Phase 79 backend implementation)
```go
// Source: EV-Backend/internal/compass/handlers.go — BulkUpsertVerdicts
// Accepts: [{ "quote_id": "uuid-string", "verdict": "agreed"|"disagreed" }]
// Returns: full updated verdict set for the user (same shape as GET)
```

### CORS Configuration (already includes readrank)
```go
// Source: EV-Backend/internal/middleware/middleware.go lines 74-75
"https://readrank.empowered.vote":        {},
"https://readrank-dev.empowered.vote":    {},
```

No CORS changes needed.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fragment-only verdicts (guest path) | Fragment (guest) + API (logged-in) | Phase 82 (this phase) | Logged-in users get cross-device verdict persistence without URL fragment dependency |
| CompassContext ignores API for verdicts | CompassContext fetches API verdicts as highest priority | Phase 82 (this phase) | Direct Essentials profile visits show badges without needing to navigate from Read & Rank |

**Deprecated/outdated:**
- The Phase 81 comment "API fetch deferred to Phase 82" in `CompassContext.jsx` will be replaced with the real implementation.

## Open Questions

1. **Should EV-readrank also display a "Sync successful" indication?**
   - What we know: Success criteria say verdicts must be POSTed automatically — no mention of UI feedback
   - What's unclear: Whether silent fire-and-forget matches user expectations
   - Recommendation: Silent sync is correct. The user's confirmation of sync is seeing badges on Essentials. No toast needed.

2. **What happens to guest verdicts in EV-readrank when the user is logged in?**
   - What we know: EV-readrank stores verdicts in Zustand (persisted to `ev_readrank` localStorage key). There are no guest-separate vs logged-in verdict buckets in the store.
   - What's unclear: If a user logs in mid-session, should existing Zustand verdicts be retroactively POSTed?
   - Recommendation: Yes — `postVerdicts(issueProgress)` sends ALL current session verdicts when triggered (not just the current issue). Since `buildVerdictPayload` iterates `issueProgress` (all issues), a completed-issue trigger will sync all completed issues' verdicts. This is correct behavior.

3. **EV-readrank env variable for API URL in production**
   - What we know: `src/data/api.ts` defaults to `https://api.empowered.vote` when `VITE_API_URL` is not set. `.env.local` sets `VITE_API_URL=http://localhost:5050` for dev.
   - What's unclear: Whether a Cloudflare Pages env var is set for the production build.
   - Recommendation: Rely on the default fallback in the new `useAuthState.ts` and `verdictSync.ts` (both pattern-match `src/data/api.ts`). Production builds without `VITE_API_URL` will correctly use `https://api.empowered.vote`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — neither EV-readrank nor EV-Backend nor essentials have automated test suites |
| Config file | None |
| Quick run command | `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && npm run build` (TypeScript compilation) |
| Full suite command | `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && npm run build && cd /Users/chrisandrews/Documents/GitHub/EV-Backend && go build ./...` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SYNC-01 | Read & Rank POSTs verdicts when logged in | manual smoke | `cd /Users/chrisandrews/Documents/GitHub/EV-readrank && npm run build` | N/A — no test files |
| SYNC-02 | Essentials shows badges from API without fragment | manual smoke | `cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build` | N/A — no test files |

### Sampling Rate
- **Per task commit:** `npm run build` (TypeScript compile) for EV-readrank; `go build ./...` for EV-Backend (no changes expected); `npm run build` for essentials
- **Per wave merge:** All three build commands pass
- **Phase gate:** Manual smoke test — log in to Read & Rank (via another app), complete an issue, visit Essentials politician profile directly (no URL fragment), verify verdict badges appear

### Manual Smoke Test Procedure
1. Log in on CompassV2 or any EV app that shares the `api.empowered.vote` cookie domain
2. Open `readrank.empowered.vote` (session cookie should be present)
3. Complete rating an issue
4. Navigate directly to an Essentials politician profile (no `#compass=` fragment in URL)
5. Expand a StanceAccordion topic row for a politician with rated quotes
6. Verdict badges should appear (served from API, not fragment)
7. Repeat on a different device/browser with same account to verify cross-device sync

### Wave 0 Gaps
- [ ] `EV-readrank/src/hooks/useAuthState.ts` — new file, covers SYNC-01 auth detection
- [ ] `EV-readrank/src/utils/verdictSync.ts` — new file, covers SYNC-01 POST logic
- [ ] `essentials/src/lib/compass.js` — add `fetchUserVerdicts()` export, covers SYNC-02

## Sources

### Primary (HIGH confidence)
- `essentials/src/contexts/CompassContext.jsx` — existing verdict priority chain with Phase 82 stub comment at lines 102-113
- `essentials/src/lib/compass.js` — `fetchUserAnswers`, `fetchSelectedTopics` patterns; `saveGuestVerdicts`/`loadGuestVerdicts` helpers already present
- `EV-readrank/src/store/useReadRankStore.ts` — full Zustand store shape; `issueProgress`, `agreedQuotes`, `disagreedQuotes`, `rankedQuotes` fields verified
- `EV-readrank/src/utils/verdictFragment.ts` — `buildVerdictFragment` logic that Phase 82's `buildVerdictPayload` mirrors
- `EV-readrank/src/data/api.ts` — `VITE_API_URL` pattern and default value
- `EV-Backend/internal/compass/routes.go` — verified `GET /verdicts` and `POST /verdicts` registered inside SessionMiddleware group
- `EV-Backend/internal/middleware/middleware.go` — CORS allowlist includes `readrank.empowered.vote`
- `CompassV2/src/pages/Login.jsx` — auth check and POST pattern with `credentials: 'include'`
- `EV-Backend/internal/compass/handlers.go` lines 1255-1320 — verified handler implementations from Phase 79

### Secondary (MEDIUM confidence)
- `.planning/phases/79-backend-verdict-endpoints/79-01-SUMMARY.md` — confirms backend verdict endpoints complete and live
- `.planning/STATE.md` Decisions section — "Phase 82: Logged-in sync is last — guest path via URL fragment is the MVP delivery; sync is an enhancement"

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new libraries; all patterns already in the codebase
- Architecture: HIGH — CompassContext scaffold and backend are complete; patterns directly verifiable in source
- Pitfalls: HIGH — identified from direct code inspection of Zustand store, CompassContext, and backend handlers
- Validation: HIGH — no test framework exists in any repo; build + manual smoke is the established gate

**Research date:** 2026-03-12
**Valid until:** 60 days (stable codebase; no external API dependencies)
