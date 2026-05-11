# Phase 65: Dashboard Redesign - Research

**Researched:** 2026-05-10
**Domain:** React UI refactor, Tailwind v4, localStorage state, tier-gating patterns
**Confidence:** HIGH — all findings from direct codebase inspection of live source files

---

## Summary

Phase 65 redesigns `app/src/pages/DashboardPage.tsx` from a tab-based profile screen into a
single-page home screen with three new sections: a "continue" card (DASH-01), an inline stats
bar (DASH-02), and a tier-aware feature grid (DASH-03). DASH-04 (Empowered upgrade CTA) is
explicitly out of scope.

The current DashboardPage is large (~669 lines) but self-contained. All needed data already
arrives from the single `GET /api/account/me` call. The tab system (Profile / Referrals / Posts)
must be dissolved: the Referrals and Posts content moves to the profile page at
`login.empowered.vote/profile` (via redirect link only — this phase does not build that page),
leaving the dashboard as a clean home screen.

The continue card (DASH-01) has no existing data source — no `last_used` field exists on any API
endpoint or in localStorage. This must be implemented fresh, and the cleanest path is a
localStorage-only write that each sub-app (Essentials, Compass, CTC, etc.) sets when the user
visits. Since those sub-apps are out of scope, the continue card must either: (a) read a
`ev_last_used` localStorage key that sub-apps set via the hash-token redirect URL convention,
or (b) track last feature click locally within the dashboard itself (user clicks a feature tile
→ localStorage is written → on next load the card appears). Option (b) is fully self-contained
and does not require cross-app coordination.

**Primary recommendation:** Implement the continue card via a dashboard-local localStorage write
on feature tile click. Use key `ev_last_feature` storing `{ name, baseUrl }`. The card reads
this on mount. If the key is absent, the card is omitted (as required). This is immediate,
reliable, and requires zero backend work.

---

## Standard Stack

### Core (already installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 18.3.1 | Component model | Project-wide |
| TypeScript | 5.6.0 | Strict typing | Project-wide |
| Tailwind CSS | 4.2.1 | Utility classes + `@theme` tokens | App-wide |
| react-router-dom | 6.21.1 | `Link` component | Already used |
| zustand | current | `useAuthStore` — tier, accessToken | Auth source of truth |

### No New Dependencies
All three requirements are achievable with existing dependencies. No `npm install` needed.

---

## Existing Code Inventory

### What DashboardPage.tsx currently contains (669 lines total)

**State:**
- `me` (MeFull from `/api/account/me`)
- `jurisdiction` (from `/api/account/me/jurisdiction`, only if `location_consent`)
- `referral` (from `/api/referral`, only if `connected_profile`)
- `inviteesData` (from `/api/invites/my-invitees`, only if `connected_profile`)
- `activeTab` — `'profile' | 'referrals' | 'posts'`
- Several clipboard + generating states for referral code generation

**Tabs:**
- Profile tab: identity card, XP bar, gems card, VR card, Connected Spaces card, location CTA, feature grid
- Referrals tab: full invite management UI (~160 lines of JSX) — quota, generate button with label input, pending codes list, claimed invitees list with XP sub-bars
- Posts tab: `<PostHistory />` component (single line render, 193-line component file)

**Referrals tab (lines 414–573):** Full self-contained invite management. Contains state
(`generatingCode`, `newCode`, `labelInput`, `copiedCode`), API calls (`/invites/generate`,
`/invites/my-invitees`), and ~160 lines of JSX with four sub-sections. This is substantial —
not trivial to move. Recommendation: remove the Referrals tab from DashboardPage entirely and
add a "Manage invites →" link pointing to `login.empowered.vote/profile` (the full profile page
already has invite functionality per Phase 63 plan).

**Posts tab (lines 575–578):** Just `<PostHistory />`. Three lines of JSX. Similarly, remove
and add a "View post history →" link on the full profile page. PostHistory component itself
(193 lines) stays in the codebase for possible reuse.

### MeFull interface (DashboardPage.tsx lines 61–73)
```typescript
interface MeFull {
  id: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  display_name: string | null;
  completed_onboarding: boolean;
  location_consent: boolean;
  is_admin: boolean;
  verification_rating: number;       // root-level
  vq_hold_active: boolean;
  red_gem_quests_unlocked: boolean;
  connected_profile: ConnectedProfile | null;
}

interface ConnectedProfile {
  xp: { total: number; level: number; xp_in_level: number; xp_to_next_level: number; }
  gems: { yellow: number; blue: number; red: number; }
  verification_rating: number;
  vq_hold_active: boolean;
}
```

### authStore User interface (authStore.ts lines 3–11)
```typescript
export interface User {
  id: string;
  email: string;
  tier: 'inform' | 'connected' | 'empowered';
  displayName: string | null;
  completedOnboarding: boolean;
  locationConsent: boolean;
}
```

Tier values: `'inform' | 'connected' | 'empowered'`. The authStore tier mirrors the API tier.

### FEATURES array (DashboardPage.tsx lines 87–130) — all 7 items

| Name | baseUrl | dot color | Tier category |
|------|---------|-----------|---------------|
| Essentials | https://essentials.empowered.vote | `bg-ev-yellow` | Inform |
| Empowered Compass | https://compass.empowered.vote | `bg-ev-yellow` | Inform |
| Civic Trivia Championships | https://ctc.empowered.vote | `bg-ev-yellow` | Inform |
| Validation Quests | https://quests.empowered.vote | `bg-ev-teal-light` | Connect |
| Read & Rank | https://readrank.empowered.vote | `bg-ev-yellow` | Inform |
| Civic Spaces | https://civicspaces.empowered.vote | `bg-ev-teal-light` | Connect |
| Treasury Tracker | https://treasurytracker.empowered.vote | `bg-ev-yellow` | Inform |

The `dot` color already encodes tier: `bg-ev-yellow` = Inform, `bg-ev-teal-light` = Connect.
The FEATURES array needs a new `tier` field added: `'inform' | 'connect'` to drive the
Inform/Connect section split. No additional data source needed.

Current feature grid: `grid grid-cols-2 gap-3` — all features shown to all tiers, no locking.
No existing tier-gating logic anywhere in DashboardPage.

### Existing XP progress bar (lines 354–370)
Located in the identity card (profile tab). Reusable inline:
```tsx
<div className="h-2 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden">
  <div
    className="h-full rounded-full bg-ev-teal transition-all duration-700"
    style={{ width: `${xpPercent}%` }}
  />
</div>
```
`xpPercent` = `Math.round((xp.xp_in_level / xp.xp_to_next_level) * 100)`. This exact pattern
can be reused in the stats bar — same data, same calculation.

### Existing tier badge (lines 346–351)
```tsx
const TIER_COLOR: Record<string, string> = {
  inform: 'bg-ev-yellow/20 text-ev-black dark:text-ev-yellow',
  connected: 'bg-ev-teal/15 text-ev-teal',
  empowered: 'bg-ev-red/15 text-ev-red',
};
<span className={`text-xs font-semibold px-2.5 py-1 rounded-full ${TIER_COLOR[me.tier]}`}>
  {TIER_LABEL[me.tier]}
</span>
```

### Existing GemBadge component (lines 153–174)
A tooltip-equipped gem badge showing gem image + count. Uses `/Yellow_Gem.png`, `/Blue_Gem.png`,
`/Red_Gem.png` from the public folder. The inline stats bar (DASH-02) should use a compact
version of this — same images but smaller, no tooltip needed in the bar context.

### AccessToken passthrough for feature links (lines 638–641)
```tsx
const featureUrl = accessToken
  ? `${f.baseUrl}#access_token=${accessToken}`
  : f.baseUrl;
```
This pattern must be preserved in the new feature grid tiles.

---

## Architecture Patterns

### Recommended Layout Structure (single-page, no tabs)

```
DashboardPage
├── <header> nav (existing — keep as-is)
├── <main> max-w-lg mx-auto px-4 py-6 space-y-4
│   ├── [DASH-01] ContinueCard     (conditional — absent if no last-used)
│   ├── [DASH-02] StatsBar         (inline strip below nav)
│   ├── [DASH-03] FeatureGrid
│   │   ├── Inform section (all tiers, full interactivity)
│   │   └── Connect section (Connected+ full; Inform-tier dimmed+locked)
│   └── (removed) Referrals/Posts tabs → replaced with profile link
```

### Pattern 1: DASH-01 — Continue Card (localStorage-local)

**What:** On each feature tile click, write to localStorage before navigation. On mount, read
the key and show the card.

**Implementation:**
```typescript
const LAST_FEATURE_KEY = 'ev_last_feature';

interface LastFeature { name: string; baseUrl: string; }

// On tile click:
localStorage.setItem(LAST_FEATURE_KEY, JSON.stringify({ name: f.name, baseUrl: f.baseUrl }));
window.open(featureUrl, '_blank');  // or let the <a> handle navigation

// On mount (in useEffect):
const raw = localStorage.getItem(LAST_FEATURE_KEY);
const lastFeature: LastFeature | null = raw ? JSON.parse(raw) : null;
```

The card only renders when `lastFeature !== null`. No API changes needed.

**Continue button URL:** Same `featureUrl` construction with `#access_token=` appended.

### Pattern 2: DASH-02 — Inline Stats Bar

**What:** A horizontally scrollable or wrapping strip directly below the `<header>` (inside
`<main>`), replacing the four separate cards currently shown in the profile tab.

**Data fields:**
- `me.display_name` → display name (already available)
- `xp.level` → level badge (integer, from `cp.xp.level`)
- `xpPercent` → XP progress bar (already computed at line 272)
- `cp.gems.yellow`, `cp.gems.blue`, `cp.gems.red` → gem counts (already available)
- `cp.verification_rating` → VR score (already available on `cp`)
- Link to `login.empowered.vote/profile` → "View full profile →"

**For Inform-tier users** (`cp === null`): stats bar shows display name + tier badge only.
No XP/gems/VR since those fields are on `connected_profile`. Show "View full profile →" link
regardless.

### Pattern 3: DASH-03 — Tier-Aware Feature Grid

**What:** Split the FEATURES array into two sections. Add `tier: 'inform' | 'connect'` field
to each item. Inform section: all items always fully interactive. Connect section: Connected+
users get full interactivity; Inform-tier users see tiles dimmed with a lock indicator.

**Tier classification (add to FEATURES array):**
- Essentials → `'inform'`
- Empowered Compass → `'inform'`
- Civic Trivia Championships → `'inform'`
- Read & Rank → `'inform'`
- Treasury Tracker → `'inform'`
- Validation Quests → `'connect'`
- Civic Spaces → `'connect'`

**Locked tile pattern (Inform-tier user on Connect section):**
- Render tile but with `opacity-50` and `pointer-events-none` on the `<a>` wrapper
- Add a lock icon in the corner or overlay
- Keep feature name and description visible (requirement: NOT hidden)
- Do not pass `#access_token` in the URL for locked tiles

```tsx
const isLocked = me.tier === 'inform' && f.tier === 'connect';
<a
  href={isLocked ? undefined : featureUrl}
  target={isLocked ? undefined : '_blank'}
  onClick={!isLocked ? () => recordLastUsed(f) : undefined}
  className={`... ${isLocked ? 'opacity-50 cursor-default' : 'hover:border-ev-teal/40'}`}
>
  {isLocked && <LockIcon />}
  ...
</a>
```

The existing lock icon SVG is already in DashboardPage at lines 434–438 (inside the referrals
section). Reuse it.

### Removing the Tab System

The `activeTab` state and tab bar (lines 189, 308–333) must be removed. The profile tab content
(lines 336–412) becomes the new page body. The referrals tab content (lines 414–573) and posts
tab content (lines 575–578) are removed entirely.

State to remove: `activeTab`, `referral`, `inviteesData`, `generatingCode`, `newCode`,
`newCodeCopied`, `labelInput`, `copiedCode`, `copied`.

The jurisdiction fetch (lines 195–201) and Connected Spaces card (lines 580–613) can be
retained as a lower section of the page or removed to simplify — the requirement does not
mention Connected Spaces on the dashboard. Recommendation: keep the jurisdiction section since
it adds value and is already implemented.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead |
|---------|-------------|-------------|
| Last-used persistence | Custom backend endpoint | localStorage with `ev_last_feature` key |
| Token pass-through to sub-apps | New auth mechanism | Existing `#access_token=` URL hash pattern (lines 638–641) |
| XP progress bar | New component | Extract existing 3-line pattern from identity card |
| Lock icon SVG | New SVG | Reuse existing SVG from referrals section (lines 434–438) |
| Gem display | New component | Reuse `GemBadge` component (lines 153–174) for compact variant |

---

## Common Pitfalls

### Pitfall 1: Referrals State Entanglement

**What goes wrong:** The referrals tab has 8 state variables and 3 API calls tightly coupled
to the current component. Naively removing the tab without removing state and API calls leaves
dead code and wasted network requests.

**How to avoid:** When removing the tab, also remove: `referral` state, `inviteesData` state,
`generatingCode`/`newCode`/`newCodeCopied`/`labelInput`/`copiedCode` state, the
`apiFetch('/referral')` call, the `apiFetch('/invites/my-invitees')` call, `handleGenerate`,
`copyCode`, `copyNewCode`, `copyPendingCode`, and the `ReferralState`/`InviteesData`/
`InviteeEntry` interfaces.

### Pitfall 2: Stats Bar Inform-Tier Null Safety

**What goes wrong:** `cp` (connected_profile) is null for Inform-tier users. Accessing
`cp.xp.level` without guard throws.

**How to avoid:** Gate all XP/gem/VR stats on `cp !== null`. The stats bar shows a minimal
version (name + tier badge + profile link) for Inform users. The pattern is already established
in the identity card (`{xp && (...)}` pattern at line 354).

### Pitfall 3: Feature URL Skips accessToken for Locked Tiles

**What goes wrong:** Locked tiles (Inform user on Connect feature) must not navigate, but the
existing pattern always constructs a URL with the access token. If the anchor renders with href,
click-through still works.

**How to avoid:** Use `href={undefined}` or `role="button"` with `onClick` no-op for locked
tiles. The lock indicator must be the UX signal — not just styling.

### Pitfall 4: localStorage JSON Parse Failure

**What goes wrong:** If `ev_last_feature` localStorage key contains malformed JSON (e.g., from
a stale write), `JSON.parse()` throws and crashes the component.

**How to avoid:** Wrap the parse in a try/catch that falls back to `null`:
```typescript
try { lastFeature = JSON.parse(raw); } catch { lastFeature = null; }
```

### Pitfall 5: Continue Card Shows Stale Feature

**What goes wrong:** User clicks Essentials, then stops using the app for months. The card
still shows Essentials even though it's irrelevant.

**How to avoid:** This is acceptable behavior for Alpha — the roadmap does not require expiry.
No TTL needed. If desired later, write `{ name, baseUrl, clickedAt }` and filter if `> 30 days`.

---

## Code Examples

### DASH-01: Continue Card Pattern
```tsx
// Source: dashboard research — localStorage pattern
const LAST_FEATURE_KEY = 'ev_last_feature';

function recordLastUsed(f: { name: string; baseUrl: string }) {
  try {
    localStorage.setItem(LAST_FEATURE_KEY, JSON.stringify({ name: f.name, baseUrl: f.baseUrl }));
  } catch { /* quota exceeded — ignore */ }
}

// In component:
const [lastFeature, setLastFeature] = useState<{ name: string; baseUrl: string } | null>(null);
useEffect(() => {
  try {
    const raw = localStorage.getItem(LAST_FEATURE_KEY);
    if (raw) setLastFeature(JSON.parse(raw));
  } catch { /* malformed — ignore */ }
}, []);

// Render (only if lastFeature exists):
{lastFeature && (
  <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5">
    <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">Continue where you left off</p>
    <div className="flex items-center justify-between">
      <p className="text-sm font-semibold text-ev-black dark:text-white">{lastFeature.name}</p>
      <a
        href={accessToken ? `${lastFeature.baseUrl}#access_token=${accessToken}` : lastFeature.baseUrl}
        target="_blank"
        rel="noopener noreferrer"
        className="text-sm font-semibold text-ev-teal bg-ev-teal/10 px-4 py-2 rounded-xl hover:bg-ev-teal/20 transition-colors"
      >
        Continue →
      </a>
    </div>
  </div>
)}
```

### DASH-02: Stats Bar (Connected-tier)
```tsx
// Shows below nav, above continue card
{me && cp && xp && (
  <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-4">
    <div className="flex items-center justify-between mb-3">
      <div className="flex items-center gap-2">
        <span className="font-semibold text-ev-black dark:text-white text-sm">{me.display_name}</span>
        <span className={`text-xs font-semibold px-2 py-0.5 rounded-full ${TIER_COLOR[me.tier]}`}>
          Lv {xp.level}
        </span>
      </div>
      <a href="https://login.empowered.vote/profile" className="text-xs text-ev-teal hover:underline">
        View full profile →
      </a>
    </div>
    {/* XP bar */}
    <div className="h-1.5 rounded-full bg-gray-100 dark:bg-gray-800 overflow-hidden mb-3">
      <div className="h-full rounded-full bg-ev-teal transition-all duration-700" style={{ width: `${xpPercent}%` }} />
    </div>
    {/* Gem row */}
    <div className="flex items-center gap-4">
      <span className="text-xs text-gray-500 tabular-nums">
        <img src="/Yellow_Gem.png" className="inline w-4 h-4 mr-1" alt="" />{cp.gems.yellow}
      </span>
      <span className="text-xs text-gray-500 tabular-nums">
        <img src="/Blue_Gem.png" className="inline w-4 h-4 mr-1" alt="" />{cp.gems.blue}
      </span>
      <span className="text-xs text-gray-500 tabular-nums">
        <img src="/Red_Gem.png" className="inline w-4 h-4 mr-1" alt="" />{cp.gems.red}
      </span>
      <span className="text-xs text-gray-500 tabular-nums ml-auto">VR {cp.verification_rating}/150</span>
    </div>
  </div>
)}
```

### DASH-03: Feature Grid with Tier Sections
```tsx
// Updated FEATURES array with tier field:
const FEATURES = [
  { name: 'Essentials',          tier: 'inform',  ... },
  { name: 'Empowered Compass',   tier: 'inform',  ... },
  { name: 'Civic Trivia',        tier: 'inform',  ... },
  { name: 'Read & Rank',         tier: 'inform',  ... },
  { name: 'Treasury Tracker',    tier: 'inform',  ... },
  { name: 'Validation Quests',   tier: 'connect', ... },
  { name: 'Civic Spaces',        tier: 'connect', ... },
];

const informFeatures = FEATURES.filter(f => f.tier === 'inform');
const connectFeatures = FEATURES.filter(f => f.tier === 'connect');
const isConnectedPlus = me?.tier === 'connected' || me?.tier === 'empowered';

// Inform section:
<div className="space-y-2">
  <p className="text-xs font-semibold text-ev-yellow uppercase tracking-wider px-1">Inform</p>
  <div className="grid grid-cols-2 gap-3">
    {informFeatures.map((f) => <FeatureTile key={f.name} f={f} locked={false} accessToken={accessToken} onVisit={recordLastUsed} />)}
  </div>
</div>

// Connect section:
<div className="space-y-2">
  <p className="text-xs font-semibold text-ev-teal uppercase tracking-wider px-1">Connect</p>
  <div className="grid grid-cols-2 gap-3">
    {connectFeatures.map((f) => <FeatureTile key={f.name} f={f} locked={!isConnectedPlus} accessToken={accessToken} onVisit={recordLastUsed} />)}
  </div>
</div>
```

---

## Tab Disposition Decision

**Referrals tab → Remove from DashboardPage.** The content is substantial (8 state variables,
3 API calls, ~160 JSX lines). The full profile page at `login.empowered.vote/profile` (Phase 63)
already handles invite functionality. In the new dashboard, show a single link:
`"Manage referrals →" → login.empowered.vote/profile`.

**Posts tab → Remove from DashboardPage.** It renders a single `<PostHistory />` component.
Show a link: `"View post history →" → login.empowered.vote/profile`.

The PostHistory component file itself (`app/src/components/PostHistory.tsx`) stays in the
codebase — it is used by or will be used by the profile page.

This is the cleanest path: DashboardPage becomes a home screen, not a profile screen. The full
profile is the canonical identity view at `login.empowered.vote/profile`.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| 4 separate stat cards (XP, gems, VR, identity) | Single compact inline stats bar | Reduces scroll, info visible above fold |
| Tab-based layout (profile/referrals/posts) | Single-page home screen | Dashboard becomes a launcher, not a profile |
| All features shown equally to all tiers | Inform/Connect sections with lock indicators | Communicates tier value without hiding features |
| No continue card | localStorage-tracked last-used card | Reduces re-navigation friction |

---

## Open Questions

1. **Connected Spaces card on dashboard?**
   - What we know: The Connected Spaces section (jurisdiction display) is currently in the profile tab, requires `location_consent`, and is useful context.
   - What's unclear: Does the redesigned dashboard include it, or is it dashboard-only content now handled by the profile page?
   - Recommendation: Keep it on the dashboard as a lower section. It's lightweight, location-aware, and not duplicated at profile page yet.

2. **Stats bar for Inform-tier (no `connected_profile`)?**
   - What we know: Inform-tier users have no XP, gems, or VR since `connected_profile` is null.
   - What's unclear: Does DASH-02 render a minimal bar (name + tier badge + profile link) or is the bar suppressed for Inform users?
   - Recommendation: Render minimal bar (name + tier badge + "View full profile →") for Inform. This keeps the layout consistent and surfaces the profile link.

3. **Icon for continue card?**
   - The DASH-01 requirement mentions "last-used feature name + icon." Each feature currently has only a colored dot (`w-2 h-2 rounded-full`), not an SVG icon.
   - Recommendation: Use the colored dot as the "icon" (it's the existing visual identity per tile). Name + dot is sufficient for the card.

---

## Sources

### Primary (HIGH confidence)
- `app/src/pages/DashboardPage.tsx` — direct read, 669 lines
- `app/src/store/authStore.ts` — direct read, 48 lines
- `app/src/components/PostHistory.tsx` — direct read, 193 lines
- `app/src/App.tsx` — direct read, routing structure
- `app/src/pages/ProfilePage.tsx` — direct read (app/ version), 404 lines
- `app/src/index.css` — direct read, Tailwind v4 tokens
- `app/src/components/AppNav.tsx` — direct read, 28 lines
- `.planning/phases/60-design-foundation/60-RESEARCH.md` — Phase 60 design tokens
- `.planning/phases/63-profile-page-activity-feed/63-RESEARCH.md` — activity API shape
- `.planning/phases/64-informlanding/64-RESEARCH.md` — routing split context
- `.planning/ROADMAP.md` — Phase 65 success criteria

## Metadata

**Confidence breakdown:**
- Current DashboardPage inventory: HIGH — read directly from source
- FEATURES array classification: HIGH — dot colors are explicit tier indicators
- Continue card implementation: HIGH — localStorage pattern is established in codebase
- Stats bar data availability: HIGH — all fields present in MeFull / ConnectedProfile interfaces
- Tab removal recommendation: HIGH — Referrals/Posts both have equivalents at profile page

**Research date:** 2026-05-10
**Valid until:** 2026-06-10 (stable codebase — no external library changes needed)
