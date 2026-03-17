# Plan 30-02 Summary: Feature Hub Cards

## Status: Complete

## What Was Built

Feature hub card grid added to the profile page, plus Civic Spaces jurisdiction display, masked address with show/hide, and a light/dark mode toggle.

## Deliverables

### Feature Hub (PROFILE-03, PROFILE-04)
- 6 cards rendered in a responsive 2-col grid below the profile card
- Cards: CTC, VQ, Essentials, Read & Rank, Empowered Compass, Treasury Tracker
- Each card has a colored dot indicator, name, description, and "Explore →" link
- All cards open in new tab with correct production URLs
- "Explore freely. Connect to save your progress." subheading visible to all tiers
- Deviation: 6th card (Empowered Compass) added per user request during review

### Civic Spaces (bonus, live-review requested)
- Fetches `/account/me/jurisdiction` on load when `location_consent` is true
- Displays jurisdiction as labeled pills: Civic Space / Local Slice / State Slice / Federal Slice
- Address shown masked (••••••••) with Show/Hide toggle; note that address is not stored server-side

### Dark Mode (bonus, live-review requested)
- `@custom-variant dark` added to index.css for class-based dark mode (Tailwind v4)
- Inline script in index.html applies `.dark` class before React hydrates (no FOUC)
- `useTheme` hook manages localStorage + `document.documentElement` class toggle
- Sun/moon toggle in nav; preference persists across page refreshes and navigation
- Defaults to OS preference if no stored preference exists

### Bug Fixes (discovered during live review)
- Fixed PostGIS schema: `extensions.ST_*` → `public.ST_*` in `resolve_user_jurisdiction` RPC
- Added `service_role` GRANT on `xp_transactions` and `gem_transactions`
- Fixed gem middleware: was reading `Authorization: Bearer`, CTC sends `X-Service-Key`
- Fixed CTC gem request body: camelCase → snake_case field names

## Commits

- f2ae91b feat(30-02): add Civic Spaces section with jurisdiction names and masked address display
- 3568c7c fix(30-02): update Essentials and Read & Rank card descriptions
- 8c5a6f3 fix(location): add name fields to resolve_user_jurisdiction RPC
- 4cb3e83 fix(grants): add service_role SELECT grant on xp_transactions and gem_transactions
- 594f0a8 fix(gems): read X-Service-Key header instead of Authorization: Bearer
- 3fc2f89 feat(profile): add light/dark mode toggle with localStorage persistence
