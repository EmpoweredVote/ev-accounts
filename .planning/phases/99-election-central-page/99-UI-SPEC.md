# Phase 99: Election Central Page — UI Spec

## Page: /elections

### Layout

Standard Layout wrapper (same as Results page). White background with ev-bg-light.

### Address Input Section

At top of page, address search bar (same pattern as Landing/Results).
- Placeholder: "Enter your address to see your ballot"
- On submit: fetch elections and render below

### Loading State

Simple spinner / "Finding elections near you..." text

### Empty State

"No upcoming elections found for this address."

### Elections Display

Group elections by date (ascending). For each election:

**Election Header**
- Election name (bold, large)
- Date formatted as "May 5, 2026"
- Election type badge: "Primary" or "General"

**Races within election**

Group races by jurisdiction category (Federal / State / Local) using the same `classifyCategory()` logic from Results.

For each race:
- Position name
- Seats count (if > 1)
- Candidate cards in a grid

**Candidate Card**

- Photo (if available, else initials avatar)
- Full name
- "Incumbent" badge if `is_incumbent === true`
- Link to `/candidate/:politician_id` if `politician_id` is present

### Colors / Typography

- Use existing Tailwind classes and CSS variables from the app
- ev-coral for action/badge highlights
- Manrope font (already loaded globally)
- Mobile-first responsive grid

### Antipartisan

- Never display party affiliation
- For primaries: show a "Primary Election" label on the election card, not the party
