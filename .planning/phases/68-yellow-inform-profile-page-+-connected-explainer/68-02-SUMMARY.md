---
phase: 68-yellow-inform-profile-page-+-connected-explainer
plan: 02
status: complete
completed: 2026-05-09
commits:
  - 34da106  # 68-02 auto tasks complete
  - 661f6de  # light mode contrast + Connected pill clickable
  - fdeb9f0  # hide gem pips when count is 0
  - 330c431  # modal tier awareness — Connected sees only Close
---

# Plan 68-02 Summary

## What Was Built

### Core deliverables (plan spec)

**ProfilePage.tsx — Inform branch completion:**
- `MeInformProfile` type extended with `last_essentials_location: unknown`
- Compass stats fetch broadened from `data.connected_profile` gate to `data.connected_profile || data.tier === 'inform'` — Inform users now see calibration count on the Compass tile
- `FeatureTile` extended with optional `lastEssentialsLocation?: unknown` prop — Essentials tile renders last searched location string when present and no election countdown is active
- `FeatureTile` extended with optional `locked?: boolean` prop — Connect tiles show a small yellow padlock badge (absolute-positioned top-right) for Inform users; tile remains an `<a>` link (Observe Access preserved)
- `ConnectedExplainerModal` imported; `explainerOpen` state added
- "Inform Account" pill converted from `<span>` to `<button onClick={() => setExplainerOpen(true)}>` — clickable for Inform tier only
- `<ConnectedExplainerModal>` rendered at page level, wired to `explainerOpen`
- "Ready to participate?" section added at bottom of profile tab — Inform-tier-only, anti-funnel copy ("when you are"), teal link opens the same modal

### Fixes applied during UAT

**Light mode contrast (UAT Gap A):**
- Calibration count text: `text-white` → `text-gray-900 dark:text-white` — was invisible on light tile backgrounds
- Inform section background: `bg-ev-inform-section/20` → `/40` — washed-out yellow now visible
- Connect section background: `bg-ev-connect-section/20` → `/40` — washed-out teal now visible

**Connected Account pill (UAT Gap B):**
- Connected/Empowered `<span>` → `<button onClick={() => setExplainerOpen(true)}>` — both tiers can now open the explainer
- Connected pill color updated to `border-ev-blue/40 text-ev-blue` — matches the Level 3 XP badge color as requested
- Empowered pill retains `border-ev-red/40 text-ev-red hover:bg-ev-red/10`

**Gem visibility:**
- Connected user gem pips hidden individually when count is 0 — users with no earned gems see only their pseudonym
- Inform user yellow gem pip hidden when `yellow_gem_balance === 0`

**Modal tier awareness:**
- `ConnectedExplainerModal` extended with `tier` prop (defaults to `'inform'`)
- "Connect Account" CTA + limitations panel gated to `tier === 'inform'` only
- Connected and Empowered users see only the infographic + "Close" button (no connect CTA)
- `tier={profile.tier}` passed from ProfilePage

## Requirement Coverage

| Req | Description | Status |
|-----|-------------|--------|
| IPRO-01 | Inform profile is yellow-themed (header card border, badge, gem display) | ✅ |
| IPRO-02 | Header shows display name + clickable yellow "Inform Account" pill + yellow gem balance | ✅ |
| IPRO-03 | Compass tile shows calibration count for Inform users | ✅ |
| IPRO-04 | Essentials tile shows last searched location string or no stat row when null | ✅ |
| IPRO-05 | Connect tiles show visible lock badge for Inform users; tiles remain `<a>` links | ✅ |
| IPRO-06 | Subtle "Connect your account" section at bottom, Inform-only, anti-funnel copy | ✅ |
| CEXP-01 | Inform Account badge is clickable and opens ConnectedExplainerModal | ✅ |
| CEXP-02 | Modal reachable from both entry points (badge + bottom section) | ✅ |
| CEXP-03 | Modal shows tier explainer, Connect CTA → limitations → invite code → /signup | ✅ |

All 9 Phase 68 requirements satisfied.

## Deviations from Plan Spec

1. **Connected pill also made clickable** — Plan spec left Connected/Empowered as non-clickable `<span>`. UAT revealed users expect to click the Connected pill to open the same explainer (future home of "Empower your account" CTA). Made it a button during UAT gap fixes.

2. **Pill color update** — Connected pill styled `ev-blue` to match Level 3 XP badge (user request during UAT). Not in original spec.

3. **Gem visibility logic added** — Gem pips hidden when count is 0 (user request during UAT). Not in original spec.

4. **Modal tier awareness** — Plan spec did not address what Connected/Empowered users see when they open the modal via their pill. Added `tier` prop during UAT to suppress the Connect CTA for already-connected users.

5. **Light mode opacity bumped** — Section backgrounds `/20` → `/40`. Not in spec but necessary for legibility.

## No Regressions

Connected and Empowered users:
- See their existing teal/red-themed profile unchanged
- Feature tiles have no lock badges
- No "Ready to participate?" section
- Compass tile continues to show calibration count (was already working for connected tier)
- Clicking their tier pill opens the explainer (new capability — was previously inert)
