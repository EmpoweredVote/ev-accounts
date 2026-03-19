# Phase 31: Referral Dashboard Card - Research

**Researched:** 2026-03-19
**Domain:** React frontend — end-user app dashboard card, clipboard API
**Confidence:** HIGH

## Summary

The referral dashboard card for Phase 31 is **already fully implemented** and shipped. It was delivered in commit `97b2dab` (2026-03-17) as part of the referral backend work. The implementation lives in `app/src/pages/DashboardPage.tsx` at lines 277–332.

All four requirements (REF-01 through REF-04) are satisfied by the existing code. The `GET /api/referral` backend is wired, the `ReferralState` interface is defined, the three card states (locked, waiting, active) are rendered, and clipboard copy is implemented using `navigator.clipboard.writeText`.

The plan for Phase 31 (31-01: Referral card component with locked/waiting/active states) describes work that is already done. The planner should verify this against the success criteria and either mark the phase complete or scope remaining work (e.g., extraction into a standalone component, test coverage, visual polish).

**Primary recommendation:** Verify the existing implementation satisfies all four success criteria verbatim. If it does, Phase 31 is already complete and can be closed. If gaps exist (e.g., no automated test, different visual treatment expected), the plan should scope only those gaps.

## Standard Stack

### Core (already in repo — nothing to install)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | 18.3.1 | UI framework | Already in use in /app |
| Tailwind CSS v4 | 4.x | Styling with brand tokens | Configured in app/src/index.css |
| `navigator.clipboard` | Browser API | One-click copy | Already used in DashboardPage |
| `apiFetch` (app/src/lib/api.ts) | n/a | Authenticated API calls | Existing pattern |
| Zustand (`useAuthStore`) | current | Auth token access | Already in use |

### No new dependencies required

**Installation:**
```bash
# Nothing to install
```

## Architecture Patterns

### File location

```
app/src/pages/
└── DashboardPage.tsx    # Referral card already lives here (lines 277-332)
```

No separate component file exists for the referral card — it is inlined in `DashboardPage.tsx`. The app has no established pattern of extracted card components (`app/src/components/` contains only `AuthGuard.tsx` and `OnboardingGuard.tsx`). Keep it inlined unless extraction is explicitly required.

### Pattern 1: Three-state referral card (already implemented)

**What:** Conditional rendering based on `referral.unlocked` and `referral.inviteeJoined` / `inviteeLevel`.
**State decision tree:**
```
referral.unlocked === false         → Locked state (lock icon + "Reach level 2 to unlock")
referral.unlocked === true
  && inviteeJoined === true
  && inviteeLevel < 2               → Waiting state (pulse dot + "Friend joined!")
referral.unlocked === true
  && (inviteeJoined === false
      || inviteeLevel >= 2)         → Active state (code display + copy button)
```

**Implementation (existing, DashboardPage.tsx lines 282–329):**
```typescript
// Source: app/src/pages/DashboardPage.tsx lines 282-329
{!referral.unlocked ? (
  /* Locked — lock icon, "Reach level 2 to unlock" */
) : referral.inviteeJoined && (referral.inviteeLevel ?? 0) < 2 ? (
  /* Waiting — pulse dot, "Friend joined!", invitee level display */
) : (
  /* Active — code display, copy button */
)}
```

### Pattern 2: Clipboard copy with 2-second feedback (already implemented)

**What:** `navigator.clipboard.writeText()` + `copied` boolean state for "Copy" → "Copied!" toggle.
**Source:** DashboardPage.tsx lines 156–162.

```typescript
// Source: app/src/pages/DashboardPage.tsx lines 156-162
const copyCode = useCallback(() => {
  if (!referral?.code) return;
  navigator.clipboard.writeText(referral.code).then(() => {
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  }).catch(() => {});
}, [referral?.code]);
```

### Pattern 3: Referral fetch gated on connected_profile (already implemented)

**What:** `GET /api/referral` is only fetched when `me.connected_profile` is non-null, matching the `requireConnected` middleware on the server.

```typescript
// Source: app/src/pages/DashboardPage.tsx lines 150-154
useEffect(() => {
  if (me?.connected_profile) {
    apiFetch<ReferralState>('/referral').then(setReferral).catch(() => {});
  }
}, [me?.connected_profile]);
```

### Pattern 4: Card render guard (already implemented)

The referral card section is gated with `{cp && referral && (...)}` — the card only appears when both `connected_profile` and a successful `/referral` response are present. This naturally hides the card for Inform-tier users (no `cp`) and during loading.

### Anti-Patterns to Avoid

- **Don't fetch `/referral` unconditionally:** The server uses `requireConnected` middleware. Inform-tier users will get a 403. Always gate the fetch on `me?.connected_profile`.
- **Don't add a spinner to the referral card:** The existing pattern is silent loading — the card simply doesn't render until `referral` state is set. Adding a skeleton/spinner is inconsistent with the existing dashboard loading pattern.
- **Don't show inviteeLevel as 0 when null:** The active state condition uses `(referral.inviteeLevel ?? 0) < 2` — the `?? 0` fallback prevents a null display issue. If refactoring, preserve this fallback.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Clipboard write | Custom textarea hack | `navigator.clipboard.writeText()` | Already implemented; browser support is >96% for modern targets |
| Auth header on fetch | Custom fetch wrapper | `apiFetch` from `lib/api.ts` | Already handles Bearer token injection |
| Brand color tokens | Inline hex values | `bg-ev-teal`, `text-ev-teal-light`, etc. | Defined in `app/src/index.css` `@theme` |
| State derivation | Client-side level calculation | Read `referral.unlocked` from server | Backend `unlock_referral_code` RPC computes unlocked state; client trusts it |

## Common Pitfalls

### Pitfall 1: Confusing /app and /admin directories

**What goes wrong:** Phase 30 built `admin/src/pages/ProfilePage.tsx` (the admin tool at accounts.empowered.vote). Phase 31 is about `app/src/pages/DashboardPage.tsx` (the end-user app at app.empowered.vote). These are different Vite apps in the same repo with separate `src/` directories.

**How to avoid:** Phase 31 work touches `app/src/` exclusively. Never edit `admin/src/` for this phase.

**Warning signs:** If you see `useTheme`, `AdminLayout`, or `ProfilePage` referenced, you are in the wrong app.

### Pitfall 2: Assuming the phase is unimplemented

**What goes wrong:** The phase exists in the roadmap but the work was done ahead-of-schedule in the same commit that shipped the referral backend (`97b2dab`). Planning as if the card does not exist would duplicate code.

**How to avoid:** Read `app/src/pages/DashboardPage.tsx` lines 27–33 (ReferralState interface) and lines 277–332 (card JSX) before writing any plan tasks.

### Pitfall 3: Treating inviteeLevel null as 0 incorrectly

**What goes wrong:** When `inviteeJoined = true` but `inviteeLevel = null` (invitee has no `connected_profiles` row yet), the waiting state display renders `{referral.inviteeLevel ?? 1}` to show "1" rather than "null". This is intentional — a joined-but-not-yet-leveled invitee is logically at level 1. Changing the fallback to 0 would display "Their level: 0" which is confusing.

**How to avoid:** Leave the `?? 1` display fallback on line 309 intact.

### Pitfall 4: navigator.clipboard requires HTTPS

**What goes wrong:** `navigator.clipboard.writeText()` is only available in secure contexts (HTTPS or localhost). The app is deployed to `app.empowered.vote` (HTTPS) so this is not a production issue, but it will silently fail on `http://` local test URLs.

**How to avoid:** Test clipboard behavior at `http://localhost:5173` (which counts as a secure context) or at the HTTPS deployment URL. The existing `.catch(() => {})` prevents uncaught errors if clipboard is unavailable.

## Code Examples

### GET /api/referral response contract

```typescript
// Source: backend/src/lib/referralService.ts lines 3-8
interface ReferralState {
  unlocked: boolean;       // true once user has reached level 2
  code: string | null;     // referral code (null if not yet unlocked)
  inviteeJoined: boolean;  // true if someone has used the code
  inviteeLevel: number | null; // invitee's current level (null if none)
}
```

**State mapping:**
- `unlocked: false` → REF-02 locked card
- `unlocked: true, inviteeJoined: true, inviteeLevel < 2` → REF-03 waiting card
- `unlocked: true, (inviteeJoined: false OR inviteeLevel >= 2)` → REF-01 active card with code

### Brand tokens used in existing referral card

```typescript
// All from app/src/index.css @theme — do not use raw hex values
'bg-ev-teal-light animate-pulse'   // waiting state dot
'text-ev-teal-light'               // "Copy" / "Copied!" button text
'hover:border-ev-teal-light/50'    // copy button hover border
'bg-gray-100 dark:bg-gray-800'     // locked state icon background
```

### Card wrapper pattern (consistent with all dashboard cards)

```typescript
// Source: app/src/pages/DashboardPage.tsx lines 278-279 — consistent card shell
<div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 space-y-3">
  <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">Invite a Friend</p>
  {/* card content */}
</div>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phase 31 as unbuilt | Already shipped in commit 97b2dab | 2026-03-17 | Plan 31-01 describes work already done; planner must verify rather than build |

**Deprecated/outdated:**
- Nothing — this is the first version of this feature.

## Open Questions

1. **Is Phase 31 effectively complete?**
   - What we know: All four requirements (REF-01 through REF-04) appear satisfied by the existing `DashboardPage.tsx` implementation. The card renders all three states. Clipboard copy works. State is driven entirely by `GET /api/referral`.
   - What's unclear: Whether the success criteria include anything not present (e.g., specific visual design, a `ReferralCard` as a separate component file, automated test coverage).
   - Recommendation: The plan for 31-01 should be a verification plan, not a build plan. Walk each success criterion against the existing code. If everything matches, the plan is: (1) verify code against criteria, (2) run the app and confirm behavior, (3) close the phase.

2. **Component extraction — inline vs. separate file?**
   - What we know: The referral card is currently inlined in `DashboardPage.tsx`. No components in `app/src/components/` are dashboard cards.
   - What's unclear: Whether Phase 31 requirements specify a `ReferralCard` component file.
   - Recommendation: Keep it inlined. No requirements language calls for a separate component. Extraction for its own sake is out of scope.

## Sources

### Primary (HIGH confidence)

- Direct code inspection: `app/src/pages/DashboardPage.tsx` lines 1–396 — complete referral card implementation, ReferralState interface, copyCode handler, three-state JSX
- Direct code inspection: `backend/src/routes/referral.ts` — GET /api/referral route contract
- Direct code inspection: `backend/src/lib/referralService.ts` — getReferralState function and ReferralState type
- Direct code inspection: `app/src/lib/api.ts` — apiFetch pattern
- Direct code inspection: `app/src/store/authStore.ts` — User shape, no level field (level lives in MeFull.connected_profile.xp.level)
- Direct code inspection: `app/src/index.css` — brand token definitions
- `git show 97b2dab --stat` — confirms referral card shipped 2026-03-17 in same commit as backend

### Secondary (MEDIUM confidence)

None — all findings from direct code inspection.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — direct code inspection
- Architecture: HIGH — existing implementation verified line-by-line
- Pitfalls: HIGH — derived from actual code patterns and git history

**Research date:** 2026-03-19
**Valid until:** 2026-04-19 (stable, no external dependencies)
