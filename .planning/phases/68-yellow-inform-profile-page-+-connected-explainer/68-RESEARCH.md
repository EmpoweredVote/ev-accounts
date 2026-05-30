# Phase 68: Yellow Inform Profile Page + Connected Explainer — Research

**Researched:** 2026-05-07
**Domain:** React UI extension — tier-aware profile page, yellow theming, headlessui modal
**Confidence:** HIGH (all findings from direct source code inspection; no external library questions)

---

## Summary

Phase 68 is a pure frontend phase. The backend is already complete: `GET /api/account/me` returns `inform_profile: { yellow_gem_balance, last_essentials_location }` for all tiers (Phase 66), and Inform users arrive at `/profile` after email confirmation (Phase 67). No new endpoints are required.

The existing `ProfilePage.tsx` already has tier detection logic, yellow badge/pill rendering, and partial Inform theming (yellow border on header card, yellow dot in feature tiles). The majority of Phase 68 work is filling in what that page currently defers for non-Connected users: calling compass stats for Inform users, rendering a yellow header card variant, adding a Connected Explainer dialog, and adding a subtle "Connect your account" CTA section.

The `AccountTypesModal.tsx` component (added in a recent phase) is a fully-built explainer of all three tiers. It does NOT satisfy CEXP-01–03 by itself because it is a general platform overview, not the targeted "What is Connected + how do I get an invite code" focused dialog that CEXP requires. A new, focused `ConnectedExplainerModal.tsx` must be created.

**Primary recommendation:** Extend `ProfilePage.tsx` in-place with Inform-tier branch logic. Create one new modal component `ConnectedExplainerModal.tsx`. No new routes, no backend changes, no new dependencies.

---

## Standard Stack

### Core (already installed — no new installs needed)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `@headlessui/react` | 2.2.9 | Modal/dialog | Already used in `InformConstraintsModal.tsx`, `AccountTypesModal.tsx`, `GrantRoleModal.tsx` |
| `react-router-dom` | 6.21.1 | Routing / Link | All pages use it |
| `tailwindcss` | 4.0.0 | Styling via `@theme` tokens | All UI uses Tailwind v4 |
| `zustand` | 5.0.11 | `useAuthStore` for accessToken | Already in ProfilePage.tsx |

### No new dependencies

This phase requires zero new npm packages. All tooling is already installed and in use.

**Installation:** None needed.

---

## Architecture Patterns

### File Change Map

```
admin/src/
├── pages/
│   └── ProfilePage.tsx          # MODIFY — Inform-tier branch, compass fetch, "connect" section
├── components/
│   └── ConnectedExplainerModal.tsx  # CREATE NEW — focused Connected explainer (CEXP-01–03)
```

No other files change. `App.tsx`, `authStore.ts`, `api.ts`, routing — all untouched.

### Pattern 1: Tier-Aware Rendering (already established in ProfilePage.tsx)

The page already uses `profile.tier` to branch:

```tsx
// Source: admin/src/pages/ProfilePage.tsx lines 619–628
profile.tier === 'inform'
  ? 'border-ev-yellow/60 dark:border-ev-yellow/25'
  : 'border-gray-200 dark:border-gray-800'
```

Extend this existing pattern. Do not add a new tier-detection mechanism — use `profile.tier === 'inform'` throughout.

### Pattern 2: Inform User has `inform_profile` on `/me` Response

```typescript
// Source: backend/src/routes/account.ts line 214
// inform_profile is present for ALL authenticated users
// For Inform tier, connected_profile is undefined/absent
// Shape:
interface MeInformProfile {
  yellow_gem_balance: number;
  last_essentials_location: unknown; // raw JSONB — may be null or an object
}
```

The `MeInformProfile` type in `ProfilePage.tsx` line 18 currently only has `yellow_gem_balance`. It needs `last_essentials_location` added for the Essentials tile (IPRO-04).

### Pattern 3: Compass Stats for Inform Users

`GET /api/compass/answers` and `GET /api/compass/topics` both use `optionalAuth` — they work for Inform-tier users. The current ProfilePage only fetches these when `data.connected_profile` is present (line 475). For Phase 68, also fetch them when tier is `'inform'`.

```tsx
// Source: admin/src/pages/ProfilePage.tsx lines 473–487
// Currently gated on: if (data.connected_profile) { ... }
// Phase 68: also fetch for inform tier
if (data.connected_profile || data.tier === 'inform') {
  Promise.all([
    apiFetch<unknown>('/compass/answers'),
    apiFetch<unknown>('/compass/topics'),
  ]).then(([answersData, topicsData]) => { ... });
}
```

### Pattern 4: HeadlessUI v2 Dialog (canonical pattern)

```tsx
// Source: admin/src/components/InformConstraintsModal.tsx (most recent modal)
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';

<Dialog open={open} onClose={onClose} className="relative z-50">
  <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
  <div className="fixed inset-0 flex items-center justify-center p-4">
    <DialogPanel className="w-full max-w-md bg-white dark:bg-gray-900 rounded-2xl border border-ev-yellow/30 shadow-xl p-6">
      <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
        ...
      </DialogTitle>
      {/* content */}
    </DialogPanel>
  </div>
</Dialog>
```

The `ConnectedExplainerModal` must use this flat v2 API. Do NOT use `Transition`/`Transition.Child` (that is the legacy v1 API still in `Signup.tsx`).

### Pattern 5: Yellow Gem Display (GemPip)

```tsx
// Source: admin/src/pages/ProfilePage.tsx lines 651–657
// Inform-tier header already uses this:
<GemPip
  count={profile.inform_profile.yellow_gem_balance}
  tooltip="Yellow Gems amplify ideas."
  gemStyle={{
    borderRadius: '4px',
    background: 'linear-gradient(145deg, #FFE566 0%, #FFB800 55%, #E07000 100%)',
    boxShadow: '0 0 8px rgba(255,184,0,0.4)',
  }}
/>
```

This is already correct for IPRO-02. No change needed to GemPip or the header card gem display.

### Pattern 6: Locked (Observe-Only) Feature Tiles

The current page renders Connected tiles for Inform users identically to Connected users — they link out to the external apps. IPRO-05 requires a lock indicator (visible but not interactive). This is a **visual-only** change to how tiles in the Connect section render for Inform tier.

Recommended approach: add a visual lock overlay or lock badge to Connected/Empowered tiles when `profile.tier === 'inform'`. Keep tiles as `<div>` (not `<a>`) when in observe mode, or keep as `<a>` but add a lock icon badge. The spec says "lock indicator shown, not hidden, not interactive" — the simplest reading is a small lock icon badge in the tile corner when locked, while the tile itself remains visually present.

The existing `!cp` check already renders an "Observe Access" badge on the Connect section header and shows explanatory text. IPRO-05 may be mostly satisfied by making this lock indicator per-tile rather than just a section header label.

### Pattern 7: "Connect your account" Bottom Section (IPRO-06 + CEXP-01)

The existing page already has an inline explanation at the Connect section header for non-Connected users (lines 709–711). IPRO-06 requires a separate, minimal section at the page bottom. This should be:
- Outside the feature cards
- Low visual prominence (not a CTA button, more of a quiet text prompt)
- Framed as "when you're ready" — anti-funnel tone
- Links to or opens the `ConnectedExplainerModal`

Recommended position: after the main features card, inside the profile tab content, at the bottom of the `space-y-3` div.

### Pattern 8: AccountTypesModal Already Exists

`AccountTypesModal.tsx` is a broad platform explainer (Inform / Connect / Empower overview). It is **not** the right component for CEXP-01–03, which requires a focused dialog about Connected accounts specifically: what they are, how identity verification works, and an "I have an invite code" CTA.

Create `ConnectedExplainerModal.tsx` as a focused component. It should:
- Use `border-ev-teal/30` (Connected = teal)
- Title: "Connected Accounts"
- Cover: what Connected tier gives you, how identity verification works in Alpha (invite code = verified), what the invite code represents
- Footer CTA: "I have an invite code" → `<Link to="/signup" onClick={onClose}>` — routes to existing Connected signup

### Pattern 9: last_essentials_location Shape

`last_essentials_location` is stored as raw JSONB. The shape is defined by whatever Essentials passes to `PATCH /api/account/location-hint`. Based on the route handler in `account.ts` (line 679), the Essentials app sends `{ location: { ... } }`. The stored value is the `location` property (inner object). The shape is not defined in the accounts codebase — it is Essentials-app-defined.

For IPRO-04, the profile page shows "last searched location" or a prompt. A safe display strategy: if `last_essentials_location` is non-null, try to show a human-readable string from it (e.g., `location.city`, `location.name`, `location.label`, or fallback to a generic "Location set"). If null, show "Explore Essentials →" prompt.

```tsx
// Safe rendering pattern:
const locationLabel = (() => {
  if (!profile.inform_profile?.last_essentials_location) return null;
  const loc = profile.inform_profile.last_essentials_location as Record<string, unknown>;
  return (loc.city as string) || (loc.name as string) || (loc.label as string) || 'Location saved';
})();
```

### Anti-Patterns to Avoid

- **Do NOT create a new route or page for Inform profile.** The single `ProfilePage.tsx` with tier branches is the canonical pattern. Memory note: "Do NOT build a duplicate at app.empowered.vote/profile."
- **Do NOT fetch compass stats only for Connected users.** Compass works for Inform tier — fetch it unconditionally for authenticated users.
- **Do NOT add a `connected_profile` guard around the "Connect" button.** The `ConnectedExplainerModal` should be reachable from the Inform profile.
- **Do NOT use `Transition`/`Transition.Child` from headlessui.** Use the flat v2 Dialog API.
- **Do NOT import `AccountTypesModal` for CEXP.** Build a focused `ConnectedExplainerModal`.
- **Do NOT add a pressure-heavy CTA.** Anti-funnel: "when you're ready" language. No "Upgrade now!" no conversion funnel language.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Modal with focus trap + backdrop | Custom overlay + React portal | `Dialog`/`DialogPanel` from `@headlessui/react` v2 | Already in codebase, accessible, handles Escape key |
| Yellow gem display | Custom gem component | Existing `GemPip` in ProfilePage.tsx | Already implemented, same inline style pattern |
| Tier detection | New API call or store field | `profile.tier` from `MeResponse` already in state | Already fetched at page load |
| Compass calibration count | Custom counter | Reuse existing `compassStats` state + `CompassStats` type | Already implemented for Connected — extend to Inform |
| Lock icon SVG | External icon library | Inline SVG (same pattern as SunIcon/MoonIcon in the file) | No icon library in this project |

**Key insight:** Almost everything needed is already in `ProfilePage.tsx`. This phase is mostly enabling existing code paths for Inform users rather than writing new logic.

---

## Common Pitfalls

### Pitfall 1: MeInformProfile Type Missing `last_essentials_location`

**What goes wrong:** TypeScript errors when trying to render IPRO-04 (last searched location). The `MeInformProfile` interface in `ProfilePage.tsx` line 18 only has `yellow_gem_balance: number`. `last_essentials_location` is returned by the backend but not typed.

**How to avoid:** Update the interface:
```typescript
interface MeInformProfile {
  yellow_gem_balance: number;
  last_essentials_location: unknown; // raw JSONB, may be null
}
```

**Warning signs:** TypeScript error "Property 'last_essentials_location' does not exist on type 'MeInformProfile'."

### Pitfall 2: Compass Stats Only Fetched for Connected Users

**What goes wrong:** For an Inform user on `/profile`, `compassStats` remains `null` even though they have calibrated their Compass. The Compass tile (IPRO-03) shows no calibration count.

**Why it happens:** Lines 473–487 of ProfilePage.tsx gate the compass fetch on `data.connected_profile`. Inform users never have `connected_profile`.

**How to avoid:** Fetch compass stats when `data.tier === 'inform'` OR `data.connected_profile` exists. The endpoints `GET /compass/answers` and `GET /compass/topics` are `optionalAuth` — they work for authenticated Inform users.

**Warning signs:** Compass tile shows no stats for an Inform user who has calibrated.

### Pitfall 3: "Connect your account" Section Shows for Connected/Empowered Users

**What goes wrong:** The IPRO-06 bottom section renders for all tiers, creating visual confusion for Connected users who see a prompt to connect their already-connected account.

**How to avoid:** Gate the entire IPRO-06 + CEXP section on `profile.tier === 'inform'`:
```tsx
{profile.tier === 'inform' && (
  <div className="...">
    {/* Connect prompt */}
  </div>
)}
```

**Warning signs:** Connected users see "Connect your account" text on their profile.

### Pitfall 4: "Inform Account" Badge Already Exists but Is Not Clickable

**What goes wrong:** CEXP-01 requires the Inform Account badge to open the explainer dialog. The badge already exists at lines 619–628 as a `<span>`. If it stays as a `<span>`, no click handler is possible without forking the rendering logic.

**How to avoid:** For Inform tier, render the badge as a `<button>` instead of `<span>`:
```tsx
{profile.tier === 'inform' ? (
  <button
    type="button"
    onClick={() => setExplainerOpen(true)}
    className="border text-xs font-semibold px-3 py-1 rounded-full flex-shrink-0 mb-px border-ev-yellow bg-ev-yellow/15 text-yellow-700 dark:bg-ev-yellow/10 dark:border-ev-yellow/50 dark:text-ev-yellow hover:bg-ev-yellow/25 transition-colors"
  >
    Inform Account
  </button>
) : (
  <span className="...">
    {/* Connected / Empowered badge — non-clickable */}
  </span>
)}
```

**Warning signs:** Clicking the "Inform Account" badge does nothing.

### Pitfall 5: last_essentials_location JSON Shape Unknown

**What goes wrong:** Attempting to access a specific field on `last_essentials_location` (e.g., `location.city`) causes a runtime error because the shape is undefined by the accounts codebase.

**Why it happens:** The field is raw JSONB stored from whatever Essentials passes. The accounts API has no schema contract on this field.

**How to avoid:** Always cast to `Record<string, unknown>` and use optional chaining with fallbacks. Never assert a specific shape. If the value can't be interpreted as a display string, show a generic "Location saved" label.

### Pitfall 6: Locked Tiles Are Still Interactive Links

**What goes wrong:** IPRO-05 says Connected/Empowered tiles should be visible but "not interactive" for Inform users. The current code renders them as `<a>` elements that link out to the external apps.

**Recommendation:** Keep tiles as `<a>` elements but add a visual lock badge (small lock icon in the corner). The spec says "lock indicator shown, not hidden, not interactive" — interpreting "not interactive" as the locked feature being non-participatory (can't contribute) rather than the tile being un-clickable. Inform users CAN observe (they have observe access per the existing "Observe Access" badge). A lock icon signals "read-only" without breaking the observe experience. This reading is consistent with the existing "Observe Access" badge text already in the UI.

If the requirement is interpreted strictly as "tile is not a link," then render the Connect/Empower tiles as `<div>` when `profile.tier === 'inform'`. Discuss with planner.

---

## Code Examples

### ProfilePage.tsx: Extended Compass Fetch for Inform Users

```tsx
// Source: admin/src/pages/ProfilePage.tsx — modify lines 473–487
// Change: gate on tier === 'inform' OR connected_profile exists
if (data.connected_profile || data.tier === 'inform') {
  Promise.all([
    apiFetch<unknown>('/compass/answers'),
    apiFetch<unknown>('/compass/topics'),
  ]).then(([answersData, topicsData]) => {
    const answered = Array.isArray(answersData)
      ? answersData.length
      : ((answersData as { answers?: unknown[] })?.answers?.length ?? 0);
    const total = Array.isArray(topicsData)
      ? topicsData.length
      : ((topicsData as { topics?: unknown[] })?.topics?.length ?? 21);
    setCompassStats({ answered, total });
  }).catch(() => {});
}
```

### ProfilePage.tsx: Inform Account Badge as Clickable Button

```tsx
// Source: admin/src/pages/ProfilePage.tsx — replace the tier pill span at lines 619–628
{profile.tier === 'inform' ? (
  <button
    type="button"
    onClick={() => setExplainerOpen(true)}
    className="border text-xs font-semibold px-3 py-1 rounded-full flex-shrink-0 mb-px cursor-pointer
      border-ev-yellow bg-ev-yellow/15 text-yellow-700
      dark:bg-ev-yellow/10 dark:border-ev-yellow/50 dark:text-ev-yellow
      hover:bg-ev-yellow/25 transition-colors"
  >
    Inform Account
  </button>
) : (
  <span className={`border text-xs font-semibold px-3 py-1 rounded-full flex-shrink-0 mb-px ${
    profile.tier === 'empowered'
      ? 'border-ev-red/40 text-ev-red'
      : 'border-gray-300 dark:border-gray-700 text-gray-600 dark:text-gray-400'
  }`}>
    {profile.tier === 'empowered' ? 'Empowered Account' : 'Connected Account'}
  </span>
)}
```

### ProfilePage.tsx: IPRO-04 Essentials Location Display

```tsx
// Inside the Essentials feature tile or a dedicated Inform-only tile:
const locationLabel = (() => {
  if (!profile?.inform_profile?.last_essentials_location) return null;
  const loc = profile.inform_profile.last_essentials_location as Record<string, unknown>;
  return (loc.city as string) || (loc.name as string) || (loc.label as string) || 'Location saved';
})();

// In tile footer:
{locationLabel ? (
  <p className="text-xs text-gray-600 dark:text-gray-400 mt-auto pt-2 border-t border-gray-200 dark:border-gray-700/60">
    <span className="text-gray-900 dark:text-white font-semibold">{locationLabel}</span>
    {' '}— last searched
  </p>
) : (
  <p className="text-xs text-gray-400 mt-auto pt-2 border-t border-gray-200 dark:border-gray-700/60">
    Explore who represents you →
  </p>
)}
```

### ConnectedExplainerModal.tsx: Component Skeleton

```tsx
// Source: pattern from admin/src/components/InformConstraintsModal.tsx
import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import { Link } from 'react-router-dom';

interface ConnectedExplainerModalProps {
  open: boolean;
  onClose: () => void;
}

export default function ConnectedExplainerModal({ open, onClose }: ConnectedExplainerModalProps) {
  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="w-full max-w-md bg-white dark:bg-gray-900 rounded-2xl border border-ev-teal/30 shadow-xl p-6 space-y-4">
          <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white">
            Connected Accounts
          </DialogTitle>
          {/* CEXP-02: what Connected is, how identity verification works, invite codes in Alpha */}
          <p className="text-sm text-gray-600 dark:text-gray-300">
            Connected Accounts unlock the participatory side of Empowered Vote — contributing to
            Validation Quests, posting in Focused Communities, and voting with your values.
          </p>
          <ul className="space-y-3">
            <li className="text-sm text-gray-700 dark:text-gray-300">
              <span className="font-semibold text-gray-900 dark:text-white">Identity verified, privately.</span>
              {' '}One real person, one voice. Your identity is verified but your participation is pseudonymous.
            </li>
            <li className="text-sm text-gray-700 dark:text-gray-300">
              <span className="font-semibold text-gray-900 dark:text-white">Alpha access via invite code.</span>
              {' '}During Alpha, Connected Accounts require an invite code from an existing member.
            </li>
          </ul>
          {/* CEXP-03: "I have an invite code" CTA */}
          <Link
            to="/signup"
            onClick={onClose}
            className="block w-full text-center py-2.5 px-4 bg-ev-teal hover:bg-ev-teal/90 text-white font-semibold rounded-xl text-sm transition-colors"
          >
            I have an invite code →
          </Link>
          <button
            type="button"
            onClick={onClose}
            className="block w-full text-center py-2 text-sm text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
          >
            Close
          </button>
        </DialogPanel>
      </div>
    </Dialog>
  );
}
```

### ProfilePage.tsx: IPRO-06 "Connect your account" Bottom Section

```tsx
// At the bottom of the profile tab content, inside the space-y-3 div:
{profile.tier === 'inform' && (
  <div className="text-center py-4 space-y-1.5">
    <p className="text-xs text-gray-500 dark:text-gray-600">
      Ready to participate? Connect your account when you are —
    </p>
    <button
      type="button"
      onClick={() => setExplainerOpen(true)}
      className="text-xs text-ev-teal dark:text-ev-teal-light hover:underline font-medium"
    >
      Learn about Connected Accounts →
    </button>
  </div>
)}
```

---

## State Management Changes in ProfilePage.tsx

One new state variable needed:

```tsx
const [explainerOpen, setExplainerOpen] = useState(false);
```

This controls the `ConnectedExplainerModal`. No other state changes.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Profile page only for Connected users | Tier-aware, single ProfilePage.tsx | Phase 63 already established this; Phase 68 extends Inform branch |
| Compass stats only for Connected users | Fetch compass for all authenticated users | Phase 68 change: `optionalAuth` on compass routes supports this |
| Inform Account badge is a `<span>` | Clickable `<button>` that opens ConnectedExplainerModal | Phase 68 CEXP-01 requirement |

**No deprecated approaches affect this phase.**

---

## Open Questions

1. **IPRO-05 lock tile interactivity interpretation**
   - What we know: "lock indicator shown, not hidden, not interactive"
   - What's unclear: Does "not interactive" mean tiles are `<div>` (no link), or just that they have a visual lock indicator showing the feature is read-only?
   - Recommendation: Keep tiles as `<a>` links (Inform users have Observe Access — they can visit but not contribute). Add a small lock icon badge to each Connected/Empowered tile. This is consistent with the existing "Observe Access" language in the section header.

2. **Essentials tile — dedicated tile vs. stats on existing Essentials FeatureTile**
   - What we know: IPRO-04 says "Essentials tile shows last searched location (if any) or prompt to explore Essentials." The Essentials feature is already in `INFORM_FEATURES` array (line 128) with `statsKey: 'election'` (shows upcoming election countdown). For Inform users with no jurisdiction, that countdown won't show.
   - What's unclear: Should `last_essentials_location` display replace the election countdown, or add to it?
   - Recommendation: Add `last_essentials_location` as an additional stat display in the Essentials tile footer for Inform users (alongside or replacing the election stats since Inform users have no jurisdiction). Add a new `statsKey: 'essentials-location'` variant, or just render it inline when `profile.tier === 'inform'`.

3. **"Connect your account" section copy**
   - What we know: Anti-funnel philosophy — must be invitational, never pressured
   - What's unclear: Exact copy not specified beyond "when you're ready" framing
   - Recommendation: "Ready to participate? Learn about Connected Accounts when you are." with a subtle text link. Avoid "upgrade," "convert," or "unlock" language.

---

## Sources

### Primary (HIGH confidence — direct source code inspection)

- `admin/src/pages/ProfilePage.tsx` — full file read, all tier logic, GemPip, FeatureTile, compass fetch
- `admin/src/components/InformConstraintsModal.tsx` — canonical headlessui v2 modal pattern
- `admin/src/components/AccountTypesModal.tsx` — full modal, existing platform explainer
- `admin/src/App.tsx` — routing table, AuthGuard
- `admin/src/store/authStore.ts` — User type, tier field
- `admin/src/lib/api.ts` — apiFetch pattern
- `admin/src/hooks/useTheme.ts` — useTheme hook
- `admin/src/index.css` — Tailwind v4 @theme color tokens
- `admin/src/pages/InformSignup.tsx` — yellow theming patterns, InformConstraintsModal usage
- `backend/src/routes/account.ts` — GET /me inform_profile shape, last_essentials_location JSONB upsert
- `backend/src/routes/compass.ts` — optionalAuth on /answers and /topics confirmed
- `admin/package.json` — @headlessui/react 2.2.9, react-router-dom 6.21.1, tailwindcss 4.0.0
- `.planning/phases/66-inform-profiles-backend-foundation/66-RESEARCH.md` — inform_profile schema
- `.planning/phases/67-login-hub-+-inform-signup-flow/67-RESEARCH.md` — modal patterns, existing signup flow

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — direct package.json inspection, no new dependencies needed
- Architecture (tier branching, modal pattern): HIGH — all patterns read directly from source
- Pitfalls: HIGH — root-caused from actual code, not speculation
- `last_essentials_location` shape: MEDIUM — shape is caller-defined (Essentials app), not typed in this codebase; fallback pattern handles this safely
- IPRO-05 lock tile interactivity: MEDIUM — requirement text is slightly ambiguous; recommended interpretation is consistent with existing "Observe Access" framing

**Research date:** 2026-05-07
**Valid until:** 2026-06-07 (stable codebase, 30-day window)
