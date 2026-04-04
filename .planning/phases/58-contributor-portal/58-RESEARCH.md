# Phase 58: Contributor Portal - Research

**Researched:** 2026-04-03
**Domain:** React frontend (Vite + React 18 + React Router 6 + Tailwind v4 + Zustand) — `/app` codebase
**Confidence:** HIGH — all findings verified from direct codebase inspection

---

## Summary

Phase 58 is a pure frontend phase. All backend endpoints are already built and deployed. The work is to add a "Contributor" tab to the existing Profile Hub (`DashboardPage.tsx`), wire it to `GET /api/contributor/me`, and implement three role-type editors as dedicated routes within `/app`.

The `/app` codebase is a minimal Vite + React 18 + React Router 6 SPA with Tailwind v4, Zustand, and `@headlessui/react`. There is no toast library — toasts are hand-rolled fixed-position divs with a `useState` boolean (verified from `DashboardPage.tsx`). There is no tab component — the Profile Hub does not currently have tabs at all; DashboardPage is a single scrolling page. The "Contributor" tab needs to be the first real tab UI in this app.

Three gaps require new backend work before or within this phase:
1. `GET /api/contributor/me` omits `granted_at` from its response — the card spec requires "grant date." Must add `granted_at` to the mapped fields in `contributor.ts`.
2. No endpoint returns a jurisdiction-scoped politician list for `essentials_data_editor`. The compass editor uses `GET /api/compass/contributors/politicians` (which handles `compass_stance_editor` + `campaign_manager` only). Essentials editor needs either a new endpoint or a separate service call.
3. "Who granted it" (granter display name) is not stored in `user_roles` and `get_user_roles` RPC does not return it. The `role_audit_log` has `actor_id` but is admin-only. This card spec item cannot be fulfilled as written. Resolution: show "Granted by Empowered Vote" or omit entirely.

**Primary recommendation:** Implement the tab as a route-based layout (`/contributor` prefix), use React Router `<Outlet>` for the dashboard + editor sub-routes, keep the toast pattern identical to `DashboardPage.tsx` (fixed bottom div, 2-3s timeout), and add `granted_at` to `contributor.ts` response as a backend micro-task.

---

## Standard Stack

### Core (already in `/app`)

| Library | Version | Purpose | Verified |
|---------|---------|---------|---------|
| react | ^18.3.1 | UI framework | package.json |
| react-dom | ^18.3.1 | DOM rendering | package.json |
| react-router-dom | ^6.21.1 | Routing, `useNavigate`, `<Outlet>`, `<Link>` | package.json |
| zustand | ^5.0.11 | Auth store (`useAuthStore`) | package.json |
| @headlessui/react | ^2.2.9 | Dialog, accessible components | package.json |
| tailwindcss | ^4.0.0 | Styling (Tailwind v4 — `@theme` custom properties) | package.json |

### No additions required

No new npm packages are needed. All required primitives exist. Do NOT add Framer Motion, a toast library, or a tab component library — those are out of scope per project conventions.

**Installation:**
No new packages.

---

## Architecture Patterns

### Existing App Structure

```
app/src/
├── App.tsx                    # Route definitions (React Router v6)
├── store/authStore.ts         # Zustand auth store
├── lib/api.ts                 # apiFetch() — auth header injected
├── components/
│   ├── AuthGuard.tsx          # Redirects unauthenticated users to accounts.empowered.vote/login
│   └── OnboardingGuard.tsx    # Requires completed onboarding
└── pages/
    ├── DashboardPage.tsx      # Current Profile Hub (single scrolling page)
    ├── LoginPage.tsx
    ├── SignupPage.tsx
    ├── onboarding/
    └── settings/
```

### Pattern 1: Tab layout as nested routes

The Contributor section maps naturally to React Router nested routes. Add a layout component at `/contributor` with a `<Outlet>` and a back-navigation header. Sub-routes:

```
/contributor                    → ContributorDashboard (grant cards)
/contributor/compass-editor     → CompassEditorPage
/contributor/campaign-manager   → CampaignManagerPage
/contributor/essentials-editor  → EssentialsEditorPage
```

**App.tsx additions:**
```tsx
// Source: existing pattern from App.tsx (OnboardingGuard → nested routes)
<Route element={<OnboardingGuard />}>
  <Route path="/" element={<DashboardPage />} />
  <Route path="/settings/location" element={<UpdateLocationPage />} />
  {/* New contributor routes */}
  <Route path="/contributor" element={<ContributorLayout />}>
    <Route index element={<ContributorDashboard />} />
    <Route path="compass-editor" element={<CompassEditorPage />} />
    <Route path="campaign-manager" element={<CampaignManagerPage />} />
    <Route path="essentials-editor" element={<EssentialsEditorPage />} />
  </Route>
</Route>
```

### Pattern 2: Contributor tab on DashboardPage

The current `DashboardPage.tsx` has NO tab navigation — it is a single page. The "Contributor" tab needs to be added as a tab bar. The simplest approach: add a tab bar at the top of the main content area that switches between "Profile" (existing content) and "Contributor" (new section), OR use a `<Link to="/contributor">` button/tab that navigates to the route.

**Recommended approach:** Navigation-based tabs (Link components), not local state tabs. This avoids prop drilling and matches the route-based approach above. The Contributor tab appears in the header area of DashboardPage as a secondary nav link.

### Pattern 3: Toast notifications (existing pattern)

```tsx
// Source: DashboardPage.tsx lines 453–457 (verified)
const [showToast, setShowToast] = useState(false);
const [toastMessage, setToastMessage] = useState('');

// Trigger:
setToastMessage('Stance saved.');
setShowToast(true);
setTimeout(() => setShowToast(false), 2500);

// Render:
{showToast && (
  <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 bg-gray-900 text-white text-sm font-medium px-5 py-3 rounded-xl shadow-lg">
    {toastMessage}
  </div>
)}
```

### Pattern 4: API data fetching

```tsx
// Source: DashboardPage.tsx lines 159–168 (verified)
const [data, setData] = useState<DataType | null>(null);

useEffect(() => {
  apiFetch<DataType>('/endpoint').then(setData).catch(() => {});
}, []);
```

For loading state on the contributor dashboard, follow the spinner pattern from `AuthGuard.tsx`:
```tsx
<div className="w-6 h-6 border-2 border-ev-teal border-t-transparent rounded-full animate-spin" />
```

### Pattern 5: Card components

DashboardPage uses a consistent card pattern (verified):
```tsx
<div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-4">
  {/* card content */}
</div>
```

All grant cards should use this exact pattern. Scope badge (jurisdiction label) uses inline pill:
```tsx
<span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-ev-teal/15 text-ev-teal">
  Los Angeles County
</span>
```

### Recommended Project Structure Additions

```
app/src/pages/
├── contributor/
│   ├── ContributorLayout.tsx      # Back nav header + <Outlet>
│   ├── ContributorDashboard.tsx   # Grant cards + locked state
│   ├── CompassEditorPage.tsx      # compass_stance_editor view
│   ├── CampaignManagerPage.tsx    # campaign_manager view (single politician)
│   └── EssentialsEditorPage.tsx   # essentials_data_editor view
```

### Anti-Patterns to Avoid

- **State-based tabs over routes:** Don't hide the editor views inside local state. Use `useNavigate` to push to `/contributor/compass-editor` etc. This gives back button behavior for free.
- **Calling multiple API endpoints in parallel without error isolation:** Each editor section makes distinct API calls. Wrap each in its own `useEffect` + catch; don't let one failure break the whole page.
- **Exposing raw geoid strings:** `jurisdiction_geoid` is a FIPS code (e.g., `06037`). Don't display it raw. Use the politician's `home_jurisdiction_geoid` against a mapping or derive the label from the politicians list (see "Jurisdiction display" below).
- **Calling `GET /api/compass/contributors/politicians` for essentials editor:** That endpoint only handles `compass_stance_editor` and `campaign_manager` (enforced by `requireRole` middleware). An `essentials_data_editor`-only user will get 403.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auth gating | Custom auth check | `AuthGuard` + `OnboardingGuard` wrappers (already exist) | Handles SSO, loading race conditions, redirect logic |
| Toast UI | Custom notification system | Inline `useState` + fixed-position div (existing pattern) | Exactly what the codebase already uses |
| Role display names | Switch statement inline | `ROLE_DISPLAY_NAMES` constant map | Keep in one place, used across all three editors |
| Accessible dialog/modal | Custom modal | `@headlessui/react` Dialog (already installed, used in admin) | Keyboard nav, aria-modal, focus trap |
| Jurisdiction → human name | DB lookup on frontend | Derive from politician list OR static label function | Politicians in list have `home_jurisdiction_geoid`; scope badge can say "Unrestricted" for null grants |

---

## Backend API Contract (Verified)

### Endpoints available for Phase 58 frontend

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| GET | `/api/contributor/me` | requireAuth | Returns user's active role grants |
| GET | `/api/compass/contributors/politicians` | requireAuth + compass_stance_editor OR campaign_manager | Jurisdiction-filtered politician list for compass editors |
| GET | `/api/compass/topics` | optional | All live topics with stances (for stance editor UI) |
| GET | `/api/compass/politicians/:id/answers` | optional | Politician's existing stance answers |
| PUT | `/api/compass/stances/:politicianId/:topicId` | requireAuth + role | Single stance write |
| PUT | `/api/compass/stances/:politicianId/bulk` | requireAuth + role | Bulk stance write (all-or-nothing) |
| PATCH | `/api/essentials/politicians/:id` | requireAuth + essentials_data_editor | Update bio/preferred_name/photo_origin_url |
| GET | `/api/essentials/politicians` | optional | Full politician list (public); supports `?state=&q=&limit=&offset=` filters |

### `GET /api/contributor/me` Response Shape (CURRENT — missing `granted_at`)

```typescript
// Current response — MISSING granted_at
interface ContributorGrant {
  role_slug: string;        // e.g. "compass_stance_editor"
  feature_scope: string;    // "platform" | "jurisdiction" | "resource"
  jurisdiction_geoid: string | null;  // e.g. "06037" or null
  resource_id: string | null;         // politician UUID for campaign_manager
}
```

**Gap:** `granted_at` is available in `UserRoleGrant` interface but stripped in `contributor.ts` mapping. A backend micro-task must add it before the dashboard card can show "Grant date."

**Gap:** "Who granted it" — `user_roles` table has no `granted_by` column. The `role_audit_log` table has `actor_id` but is admin-only. Resolution: display "Granted by Empowered Vote team" (static string) or "Empowered Vote" as the granter label on all cards for Phase 58. Log this as a future enhancement if granter attribution is needed.

### `GET /api/compass/contributors/politicians` Response Shape

```typescript
interface ContributorPolitician {
  id: string;
  first_name: string | null;
  last_name: string | null;
  full_name: string | null;
  office_title: string;
  photo_url: string;
  home_jurisdiction_geoid: string | null;
}
```

### `GET /api/compass/topics` Response Shape (relevant subset)

```typescript
interface CompassTopic {
  id: string;           // UUID
  title: string;
  short_title: string;
  question_text: string;
  is_live: boolean;
  stances: { id: string; value: number; text: string }[];
}
```

### `PATCH /api/essentials/politicians/:id` Request / Response

```typescript
// Request body (all optional, at least one required)
interface EssentialsPatchBody {
  bio?: string;                // maps to bio_text in DB
  photo_origin_url?: string;   // maps to photo_custom_url in DB
  preferred_name?: string;
}

// Response
interface EssentialsPatchResponse {
  id: string;
  full_name: string | null;
  first_name: string | null;
  last_name: string | null;
  preferred_name: string | null;
  bio: string | null;          // NOTE: API uses "bio" not "bio_text"
  photo_url: string | null;    // COALESCE(photo_custom_url, photo_origin_url)
}

// RESTRICTED fields — sending these returns 422:
// district_type, district_id, is_active, is_candidate, is_vacant
```

---

## Critical Implementation Details

### Role display name mapping

```typescript
// Source: Phase 58 CONTEXT.md decisions
const ROLE_DISPLAY_NAMES: Record<string, string> = {
  compass_stance_editor: 'Compass Editor',
  campaign_manager: 'Candidate Coordinator',    // NOT "Campaign Manager" — strictly enforced
  essentials_data_editor: 'Essentials Editor',
};
```

### Jurisdiction scope display

For the scope badge in editor headers and on dashboard cards:
- `jurisdiction_geoid = null` AND `feature_scope = "platform"` → `"Unrestricted"`
- `jurisdiction_geoid` is present → use the name from the politician list's `home_jurisdiction_geoid` values, OR display the geoid formatted (e.g., "Jurisdiction 06037") — the DB has a `inform.district_boundaries` table with `geoid` → `name` but there's no API endpoint for this lookup. Recommend: for Alpha, use "Restricted jurisdiction" with the geoid as a tooltip, OR display the geoid directly. The admin panel currently shows `font-mono text-xs` geoid (verified in `RolesTab.tsx`).
- `resource_id` is present (campaign_manager) → the "jurisdiction" is the politician themselves; scope badge shows the politician's name and office.

### Essentials editor: missing politician list endpoint

`GET /api/compass/contributors/politicians` excludes `essentials_data_editor`. To populate the Essentials Editor politician list, the frontend must either:

**Option A (no backend change):** Call `GET /api/essentials/politicians` (public endpoint), then filter client-side by `home_jurisdiction_geoid === grant.jurisdiction_geoid`. This works but may return hundreds of politicians before filtering.

**Option B (backend micro-task):** Add `essentials_data_editor` to the `requireRole` check in `GET /api/compass/contributors/politicians` (or create a parallel endpoint). The `getContributorPoliticians` function already handles the jurisdiction logic correctly for `compass_stance_editor` — `essentials_data_editor` uses identical jurisdiction semantics.

**Recommendation:** Option B is one line change in `compassContributor.ts` plus adding `'essentials_data_editor'` to the `requireRole` array and the `contributorGrants` filter. This is the correct approach.

### Campaign Manager: single politician, no list

The `campaign_manager` grant has `resource_id` = a politician UUID. The frontend should call `GET /api/compass/contributors/politicians` (which returns exactly one politician for campaign_manager grants) and route directly to that politician's stance editor page — displaying a single-item "list" before navigating to the editor (per CONTEXT.md spec for consistent UI patterns).

### Locked tab state (no active grants)

When `GET /api/contributor/me` returns an empty array `[]`, show an "encourage + contact link" empty state — NOT a cold "you have no roles" message. Based on CONTEXT.md spec. Use the same card container style as other dashboard sections.

### Tab visibility

The "Contributor" tab must always be visible to logged-in users, but in a locked/disabled visual state when the user has no active grants. When grants exist, the tab is the active navigation entry.

---

## Common Pitfalls

### Pitfall 1: Routing to editor from DashboardPage — which navigate call?

**What goes wrong:** Clicking "Open Compass Editor" from the grant card on `/` (DashboardPage) should navigate to `/contributor/compass-editor`. But if the Contributor section is a local tab on DashboardPage (not a route), this becomes state management.

**How to avoid:** Use routes. The Contributor "tab" on DashboardPage is a `<Link to="/contributor">` — navigates to the contributor dashboard route. Individual editor links from the grant cards navigate to `/contributor/compass-editor` etc. The DashboardPage itself shows a "Contributor" tab link in the nav area.

### Pitfall 2: `GET /api/compass/contributors/politicians` returns 403 for essentials_data_editor

**What goes wrong:** An `essentials_data_editor` calls this endpoint and gets 403 (requireRole only allows compass_stance_editor and campaign_manager).

**How to avoid:** Create backend micro-task before implementing EssentialsEditorPage. The route guard in `compassContributor.ts` must be updated.

### Pitfall 3: Stance value schema — values 1–5 not 0–4

**What goes wrong:** Compass topics have stances with `value: 1 | 2 | 3 | 4 | 5` (integers). The stance editor UI must use these exact values (not array indices).

**How to avoid:** Always use `stance.value` from the API response as the PUT body value, not the array index.

### Pitfall 4: Bulk PUT vs single PUT

**What goes wrong:** Building a stance editor that saves one topic at a time is slow; bulk PUT saves all-or-nothing. But bulk PUT requires all topic_ids to be valid UUIDs and live topics.

**How to avoid:** For the compass editor, use `PUT /api/compass/stances/:politicianId/bulk` with all modified stances at once. Show a loading state during submission. Single-topic edits can use `PUT /api/compass/stances/:politicianId/:topicId` for inline saves.

### Pitfall 5: `bio` vs `bio_text` naming confusion

**What goes wrong:** The PATCH request uses `bio` (not `bio_text`), and the response also uses `bio` (not `bio_text`). However the DB column is `bio_text`. This mapping is handled server-side.

**How to avoid:** Always use `bio` in the frontend request and response. Never use `bio_text` in the client code. (Verified in `essentialsEditor.ts` — API intentionally renames it.)

### Pitfall 6: Tailwind v4 syntax — no `tailwind.config.js`

**What goes wrong:** Adding utility classes or custom colors using Tailwind v3 config conventions (`tailwind.config.js`, `theme.extend`) will have no effect.

**How to avoid:** This codebase uses Tailwind v4 with `@theme` in `index.css`. Custom colors are already defined: `ev-red`, `ev-teal`, `ev-teal-light`, `ev-yellow`, `ev-black`. Use these tokens. No config file to edit.

### Pitfall 7: `granted_by` / granter info is not available

**What goes wrong:** Card spec says "who granted it" — could lead to a complex solution involving role_audit_log queries (admin-only) or new RPC work.

**How to avoid:** For Phase 58, show a static "Granted by Empowered Vote" label on all cards. The real granter attribution system (if needed) belongs in a future phase when `granted_by` can be added to `user_roles` table.

---

## Code Examples

### Grant card component shape

```tsx
// Source: Derived from DashboardPage.tsx card pattern + CONTEXT.md spec
interface GrantCardProps {
  roleSlug: string;
  featureScope: string;
  jurisdictionGeoid: string | null;
  resourceId: string | null;
  grantedAt: string;  // ISO8601 — needs micro-task to add to contributor/me response
  onOpenEditor: () => void;
}
```

### useNavigate to editor

```tsx
// Source: React Router v6 — same pattern as useNavigate in OnboardingPage.tsx
import { useNavigate } from 'react-router-dom';

const navigate = useNavigate();

// From grant card CTA button:
<button onClick={() => navigate('/contributor/compass-editor')}>
  Open Compass Editor
</button>
```

### apiFetch with typed response

```tsx
// Source: lib/api.ts + DashboardPage.tsx pattern
interface ContributorGrant {
  role_slug: string;
  feature_scope: string;
  jurisdiction_geoid: string | null;
  resource_id: string | null;
  granted_at: string; // after micro-task adds this
}

const [grants, setGrants] = useState<ContributorGrant[]>([]);
const [loading, setLoading] = useState(true);

useEffect(() => {
  apiFetch<ContributorGrant[]>('/contributor/me')
    .then(setGrants)
    .catch(() => {})
    .finally(() => setLoading(false));
}, []);
```

### Scope badge examples

```tsx
// Jurisdiction scope → human label
function jurisdictionLabel(grant: ContributorGrant): string {
  if (grant.jurisdiction_geoid === null) return 'Unrestricted';
  // campaign_manager: show politician name instead (fetched separately)
  return grant.jurisdiction_geoid; // fallback: show geoid; enhance later
}
```

---

## Open Questions

1. **Jurisdiction geoid → display name**
   - What we know: `inform.district_boundaries` table has `geoid → name` mapping. No API endpoint exposes this.
   - What's unclear: Whether to add a lookup endpoint or display raw geoid with a tooltip.
   - Recommendation: For Alpha, display geoid raw or as "Jurisdiction [geoid]". Document as low-polish / future improvement. The scope badge primary purpose is "there is a restriction" — exact name is secondary.

2. **`granted_at` in `/contributor/me` response**
   - What we know: `granted_at` exists on `UserRoleGrant` but is stripped in `contributor.ts` mapping.
   - What's unclear: Whether this is intentional or an oversight.
   - Recommendation: Add as a micro-task at the start of Phase 58. One-line change in `contributor.ts`.

3. **Essentials editor politician list endpoint**
   - What we know: No endpoint handles `essentials_data_editor` for politician lists. Two options: client-side filter or extend `compassContributor.ts`.
   - Recommendation: Extend `compassContributor.ts` (add `'essentials_data_editor'` to requireRole + filter). Backend micro-task before frontend work.

4. **Stance editor UI pattern for compass editor**
   - What we know: Topics have stances with values 1–5 and text labels. Politicians have existing answers.
   - What's unclear: Whether to show a dropdown, radio buttons, or inline stance cards for the editor UI.
   - Recommendation: Claude's discretion per CONTEXT.md. Suggest radio-button-style stance selector (matches the CompassV2 frontend convention) with stance text visible.

---

## Backend Micro-Tasks Required Before Frontend

These are small, targeted backend changes that unblock frontend implementation:

| Task | File | Change | Blocking? |
|------|------|--------|-----------|
| Add `granted_at` to `/contributor/me` response | `backend/src/routes/contributor.ts` | Add `granted_at: g.granted_at` to the mapped object | YES — card spec requires grant date |
| Extend contributor politicians endpoint for essentials_data_editor | `backend/src/routes/compassContributor.ts` | Add `'essentials_data_editor'` to `requireRole` array and `contributorGrants` filter | YES — EssentialsEditorPage cannot fetch its politician list |

---

## Sources

### Primary (HIGH confidence — direct code inspection)

- `app/src/pages/DashboardPage.tsx` — Card patterns, toast pattern, API fetch pattern, existing UI
- `app/src/App.tsx` — Route structure, guard nesting
- `app/src/lib/api.ts` — `apiFetch` implementation
- `app/src/store/authStore.ts` — Auth state, `User` type
- `app/package.json` — Exact installed library versions
- `app/src/index.css` — Tailwind v4 `@theme` custom tokens
- `backend/src/routes/contributor.ts` — `GET /api/contributor/me` response shape
- `backend/src/routes/compassContributor.ts` — `GET /api/compass/contributors/politicians`, PUT stance endpoints
- `backend/src/routes/essentialsEditor.ts` — `PATCH /api/essentials/politicians/:id` contract
- `backend/src/lib/stanceService.ts` — `ContributorPolitician` type, `getContributorPoliticians` logic
- `backend/src/lib/roleService.ts` — `UserRoleGrant` type, `getCachedUserRoles`
- `backend/migrations/047_role_scope_migration.sql` — `get_user_roles` RPC return shape, `user_roles` table schema
- `admin/src/components/RolesTab.tsx` — How admin currently displays jurisdiction_geoid (raw geoid in `font-mono`)

### Secondary (HIGH confidence — planning artifacts)

- `.planning/phases/53-*/53-02-SUMMARY.md` — Confirms `/contributor/me` response fields
- `.planning/phases/55-*/55-01-SUMMARY.md` — Confirms `granted_at` in `UserRoleGrant`, `ContributorPolitician` shape
- `.planning/phases/56-*/56-01-SUMMARY.md` — Confirms essentials editor field name mappings, fail-CLOSED jurisdiction

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — package.json verified
- API contracts: HIGH — all route files inspected directly
- Architecture patterns: HIGH — derived from existing pages in same codebase
- Backend gaps identified: HIGH — verified by absence in route files and type interfaces
- Jurisdiction display: MEDIUM — geoid lookup gap confirmed, resolution approach is judgment call

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable codebase)
