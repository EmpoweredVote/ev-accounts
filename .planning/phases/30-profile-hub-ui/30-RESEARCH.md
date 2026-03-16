# Phase 30: Profile Hub UI - Research

**Researched:** 2026-03-16
**Domain:** React admin tool UI — profile page expansion
**Confidence:** HIGH

## Summary

Phase 30 expands the existing `ProfilePage.tsx` to add three things the current page lacks: Verification Rating display, an address entry form (calling `POST /connect/set-location`), and a feature hub with cards for all EV apps.

The current `ProfilePage.tsx` already exists at `/profile` (registered in `App.tsx` under `AuthGuard`). It fetches from `GET /api/account/profile/me` which returns the `OwnerProfile` shape from `profileService.ts`. That endpoint does NOT include `verification_rating` — only `GET /api/account/me` does. This is the single most important architecture gap to resolve in planning: the profile page must either call `/api/account/me` instead of (or in addition to) `/api/account/profile/me`, or the profile endpoint must be extended.

The `GET /api/account/me` response already contains all fields needed for PROFILE-01: `tier`, `connected_profile.xp.level`, `connected_profile.xp.total`, `gems.yellow/blue/red`, and `verification_rating`. The existing `ProfilePage.tsx` currently calls the wrong endpoint for this phase's requirements.

The `POST /connect/set-location` endpoint is fully implemented. It accepts `{ address: string }`, requires Connected tier, geocodes the address, checks coverage (Indiana + LA County), and returns `{ location_consent: true, jurisdiction: {...} }` on success. It returns error codes `PO_BOX_REJECTED`, `ADDRESS_NOT_FOUND`, and `OUT_OF_COVERAGE` that the UI must handle.

**Primary recommendation:** Switch ProfilePage to fetch from `GET /api/account/me` (not `/api/account/profile/me`). This gives all needed stats in one call and avoids adding a new endpoint.

## Standard Stack

### Core (already in repo — no new installs needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 18.3.1 | UI framework | Already in use |
| Tailwind CSS | v4 | Styling | Already configured with brand tokens |
| react-router-dom | current | Routing | Already in use |
| Zustand (`useAuthStore`) | current | Auth state | Already in use |
| `apiFetch` (lib/api.ts) | n/a | Authenticated API calls | Existing pattern |

### No new dependencies required

All UI work uses existing patterns. No new npm packages needed for this phase.

**Installation:**
```bash
# Nothing to install
```

## Architecture Patterns

### Recommended Project Structure

No new files needed beyond:
```
admin/src/pages/
└── ProfilePage.tsx          # Expand in place — already registered at /profile
```

The page is standalone (not under AdminLayout), has its own nav bar, and already handles sign-out. All additions go into this single file.

### Pattern 1: API fetch on mount with useState

**What:** Fetch `/api/account/me` on component mount; store result in `useState`.
**When to use:** Single endpoint supplying all profile data for the page.
**Example (existing pattern from ProfilePage.tsx):**
```typescript
// Source: admin/src/pages/ProfilePage.tsx (existing)
useEffect(() => {
  apiFetch<OwnerProfile>('/account/profile/me')
    .then((data) => setProfile(data))
    .catch(() => setProfileError(true));
}, []);
```
For Phase 30: replace with `/account/me` and update the interface to match the `GET /api/account/me` response shape.

### Pattern 2: Form with local draft state + submission handler

**What:** Controlled input, local state for address value, loading/error/success states.
**When to use:** Single-field form with async submission (the location form).
**Example (established in AccountDetailPage.tsx VR edit):**
```typescript
const [address, setAddress] = useState('');
const [submitting, setSubmitting] = useState(false);
const [locationError, setLocationError] = useState<string | null>(null);
const [locationSuccess, setLocationSuccess] = useState(false);

async function handleSetLocation(e: React.FormEvent) {
  e.preventDefault();
  setSubmitting(true);
  setLocationError(null);
  try {
    await apiFetch('/connect/set-location', {
      method: 'POST',
      body: JSON.stringify({ address }),
    });
    setLocationSuccess(true);
  } catch (err) {
    setLocationError(err instanceof Error ? err.message : 'Failed to save location');
  } finally {
    setSubmitting(false);
  }
}
```

### Pattern 3: Card grid layout

**What:** CSS grid (Tailwind `grid grid-cols-1 sm:grid-cols-2`) for feature hub cards.
**When to use:** Displaying 5 feature cards with consistent layout.

The feature hub needs 5 cards: CTC, Validation Quests, Essentials, Read & Rank, Treasury Tracker.

### Recommended `GET /api/account/me` interface for ProfilePage

```typescript
interface MeGems {
  yellow: number;
  blue: number;
  red: number;
}

interface MeXp {
  total: number;
  level: number;
  xp_in_level: number;
  xp_to_next_level: number;
}

interface MeConnectedProfile {
  xp: MeXp;
  gems: MeGems;
  verification_rating: number;
  vq_hold_active: boolean;
  completed_onboarding: boolean;
  // ...other fields
}

interface MeResponse {
  id: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  is_admin: boolean;
  verification_rating: number;          // root-level convenience copy
  location_consent: boolean;
  gems?: MeGems;                        // present when connected
  connected_profile?: MeConnectedProfile;
}
```

### Anti-Patterns to Avoid

- **Using `/api/account/profile/me` for stat display:** The `OwnerProfile` from `profileService.ts` does not include `verification_rating`. Only `/api/account/me` has it.
- **Spreading DB row data:** All components in this repo build from explicit whitelists. Follow the same discipline in the interface types.
- **Calling set-location without Connected check in UI:** The endpoint enforces `requireConnected` server-side. The UI should show the form only for `tier === 'connected'` or `tier === 'empowered'`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auth header on API calls | Custom fetch wrapper | `apiFetch` from `lib/api.ts` | Already handles Bearer token injection |
| Tailwind brand color tokens | Inline hex values | `bg-ev-yellow`, `text-ev-teal`, `bg-ev-red` etc. | Defined in `index.css` `@theme` |
| Error code mapping | Custom error parsing | Catch error message from apiFetch | apiFetch throws with `body.error` already extracted |

## Common Pitfalls

### Pitfall 1: Endpoint mismatch for verification_rating

**What goes wrong:** The existing ProfilePage fetches `/api/account/profile/me`. The `OwnerProfile` shape from `profileService.ts` does not include `verification_rating`. Displaying a VR field while fetching from the wrong endpoint will always show `undefined` or `0`.

**Why it happens:** Two separate "me" endpoints exist in this repo — they serve different purposes. `profile/me` is for public-profile-compatible owner views. `account/me` is the full tier-aware session response.

**How to avoid:** Switch to `GET /api/account/me` as the single data source for the full page.

**Warning signs:** TypeScript will not catch this — both are `unknown` until typed. Write the interface from the actual response shape documented in `account.ts`.

### Pitfall 2: Location form shown to Inform-tier users

**What goes wrong:** `POST /connect/set-location` uses `requireConnected` middleware. An Inform-tier user submitting the form will get a 403. The UI should conditionally render the location form only when `tier !== 'inform'`.

**Why it happens:** Inform users have no `connected_profiles` row; the middleware enforces this.

**How to avoid:** Gate the location form with `profile?.tier !== 'inform'` before rendering.

### Pitfall 3: Set-location error codes need distinct user messages

**What goes wrong:** Treating all location errors as "something went wrong" — `OUT_OF_COVERAGE` needs a specific message ("We don't cover your area yet"), `PO_BOX_REJECTED` needs its own message, `ADDRESS_NOT_FOUND` needs another.

**Why it happens:** The server returns structured codes. `apiFetch` throws with `body.error` as the message string — but that's the server's `message` field, not the `code`. The codes are: `PO_BOX_REJECTED`, `ADDRESS_NOT_FOUND`, `OUT_OF_COVERAGE`.

**How to avoid:** The server's `message` field is already user-friendly (e.g., "Your address is outside our current coverage area. We're expanding soon."). Use `err.message` directly from the caught error — `apiFetch` already extracts `body.error` which maps to the server's `message`.

### Pitfall 4: gem_balances vs. gems field naming inconsistency

**What goes wrong:** `GET /api/account/profile/me` returns `gem_balances: { yellow, blue, red }`. `GET /api/account/me` returns `gems: { yellow, blue, red }` (root-level) AND `connected_profile.gems`. The existing `ProfilePage.tsx` uses `profile.gem_balances`. If you switch endpoints without updating the interface, the gem display will be silent-zero.

**How to avoid:** When refactoring the interface to use `MeResponse`, use `profile.gems?.yellow` etc. (or `profile.connected_profile?.gems`). Both are present on the `/account/me` response for connected users.

## Code Examples

### Current ProfilePage endpoint call (needs updating)

```typescript
// Source: admin/src/pages/ProfilePage.tsx line 59
// CURRENT (wrong endpoint for phase 30 requirements):
apiFetch<OwnerProfile>('/account/profile/me')

// SHOULD BE (switch to full me response):
apiFetch<MeResponse>('/account/me')
```

### GemPip component (already exists, reuse as-is)

```typescript
// Source: admin/src/pages/ProfilePage.tsx lines 34-50
function GemPip({ count, color, label }: { count: number; color: string; label: string }) {
  return (
    <div className="flex items-center gap-1.5">
      <span className={`inline-block w-3 h-3 rounded-full ${color}`} />
      <span className="text-sm text-gray-700 font-medium">{count}</span>
      <span className="text-xs text-gray-400">{label}</span>
    </div>
  );
}
// Colors: bg-ev-yellow, bg-blue-500, bg-ev-red
```

### Feature hub card pattern (new, no existing example)

```typescript
// Pattern from AccountDetailPage.tsx section headers
// Use bg-white rounded-lg shadow-sm border border-gray-200 p-5
// Cards should be anchor tags or react-router Link components
interface FeatureCard {
  title: string;
  description: string;
  href: string;           // external URL for CTC etc.
  color: string;          // ev-teal, ev-yellow, ev-red per brand
  requiresConnected: boolean;
}
```

### set-location POST contract

```typescript
// Source: backend/src/routes/connect.ts lines 511-596
// POST /api/connect/set-location
// Body: { address: string }  (min 1, max 500 chars)
// Auth: requireAuth + requireConnected
// Success 200: { location_consent: true, jurisdiction: { congressional_district, state_senate_district, state_house_district, county, school_district } }
// Errors:
//   422 PO_BOX_REJECTED — "P.O. Box addresses are not accepted."
//   422 ADDRESS_NOT_FOUND — address could not be geocoded
//   422 OUT_OF_COVERAGE — "Your address is outside our current coverage area. We're expanding soon."
//   500 INTERNAL_ERROR
```

### Tier badge classes (existing pattern)

```typescript
// Source: admin/src/pages/ProfilePage.tsx lines 28-32
const TIER_BADGE_CLASS: Record<string, string> = {
  inform: 'bg-gray-100 text-gray-700',
  connected: 'bg-ev-teal/10 text-ev-teal',
  empowered: 'bg-ev-red/10 text-ev-red',
};
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `xp` column (integer) | `total_xp` + `calculate_level` RPC | Phase 9 | ProfilePage must use `connected_profile.xp.level` and `connected_profile.xp.total` from `/account/me`, not the legacy `level`/`total_xp` fields from `/account/profile/me` |
| `gem_balances` key | `gems` key | account.ts refactor | `/account/me` uses `gems`, `/account/profile/me` uses `gem_balances` — don't confuse them |

## Open Questions

1. **Feature hub card links — external URLs or in-app navigation?**
   - What we know: CTC, VQ, Essentials, Read & Rank, Treasury Tracker are separate apps/repos. The admin tool is internal.
   - What's unclear: Whether these should be placeholder hrefs, environment variable URLs, or literal external links. None of the feature apps are in this repo.
   - Recommendation: Use hardcoded external URL placeholders (or `href="#"`) with a `TODO` comment. The planner should decide whether real URLs are required for success criteria 3.

2. **Location form: show jurisdiction result after success?**
   - What we know: `POST /connect/set-location` returns jurisdiction data (districts, county, school district).
   - What's unclear: Whether PROFILE-02 success just means "confirms success" (a toast/message) or displays the returned jurisdiction breakdown.
   - Recommendation: Success message only. Jurisdiction display is not called out in success criteria. Keep it simple.

3. **`/account/me` already fetched in App.tsx — share or re-fetch?**
   - What we know: `App.tsx` fetches `/account/me` on mount and stores minimal fields in `useAuthStore` (`tier`, `email`, `id`, `completedOnboarding`). The store does NOT cache the full me response (no `gems`, `verification_rating`, etc.).
   - What's unclear: Whether to extend the Zustand store or simply re-fetch in ProfilePage.
   - Recommendation: Re-fetch in ProfilePage on mount (same pattern as current code). Extending the store is out of scope for this phase.

## Sources

### Primary (HIGH confidence)

- Direct code inspection: `admin/src/pages/ProfilePage.tsx` — current page state, existing components
- Direct code inspection: `backend/src/routes/account.ts` — full `/api/account/me` response shape
- Direct code inspection: `backend/src/routes/connect.ts` lines 511-597 — `set-location` contract
- Direct code inspection: `backend/src/lib/profileService.ts` — confirms `verification_rating` NOT in `OwnerProfile`
- Direct code inspection: `admin/src/App.tsx` — route registration, auth flow
- Direct code inspection: `admin/src/lib/api.ts` — `apiFetch` pattern
- Direct code inspection: `admin/src/index.css` — Tailwind v4 brand token definitions

### Secondary (MEDIUM confidence)

None — all findings are from direct code inspection.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all from direct code inspection
- Architecture: HIGH — endpoint shapes verified line-by-line
- Pitfalls: HIGH — gem field naming difference verified by reading both endpoints

**Research date:** 2026-03-16
**Valid until:** 2026-04-16 (stable codebase, no fast-moving external dependencies)
