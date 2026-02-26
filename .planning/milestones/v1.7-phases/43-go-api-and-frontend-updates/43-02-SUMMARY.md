---
phase: 43-go-api-and-frontend-updates
plan: 02
subsystem: ui
tags: [react, ev-ui, politician-profile, contacts, social-links]

# Dependency graph
requires:
  - phase: 43-01
    provides: GET /essentials/politician/{id} contacts array with phone, email, website_url, synced_at
  - phase: 41-candidacy-and-contacts
    provides: PoliticianContact table populated with enriched contact data

provides:
  - Contact section in PoliticianProfile component below profile photo
  - Consolidated contact display merging enriched contacts + BallotReady person-level data
  - PoliticianProfile named export from ev-ui index.jsx

affects:
  - essentials frontend Profile page
  - ev-ui consumers importing PoliticianProfile

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Contact data consolidation: merge pol.contacts (enriched) with pol.urls/pol.email_addresses (BallotReady) with deduplication"
    - "Icon-identified contact items: phone/globe/envelope SVG icons replace text labels in narrow column layout"

key-files:
  created: []
  modified:
    - ev-ui/src/PoliticianProfile.jsx
    - ev-ui/src/index.jsx

key-decisions:
  - "Contact section placed in left column below profile photo — not a separate card or in the info column"
  - "Icons identify contact type (phone, globe, envelope) instead of text labels — fits narrow 192px column"
  - "Website and email show full URL/address text; social media stays icon-only"
  - "Dropped contact_type labels (District Office, City Website) — icon-based identification is sufficient"
  - "SocialLinks component reused for social media icons only — email/website moved to contact list with full text"
  - "BallotReady person-level urls/email_addresses merged with enriched contacts, deduplicated"

patterns-established:
  - "Left column layout: photo + contact section below, info column to the right"

requirements-completed: [CONT-03]

# Metrics
duration: 15min
completed: 2026-02-25
---

# Phase 43 Plan 02: Frontend Contact Section Summary

**Contact info consolidated under profile photo with icon-identified links — merges enriched contacts and BallotReady data, PoliticianProfile exported from ev-ui**

## Performance

- **Duration:** 15 min (including iterative design refinement)
- **Started:** 2026-02-26T01:30:00Z
- **Completed:** 2026-02-26T01:45:00Z
- **Tasks:** 2 (1 code + 1 human verification)
- **Files modified:** 2

## Accomplishments
- Added consolidated contact section below profile photo in left column — phone numbers (tel: links), websites (external links with full URLs), emails (mailto: links with full addresses)
- Merged enriched contacts from `pol.contacts` with BallotReady person-level `urls` and `email_addresses` with deduplication
- Social media icons (Twitter, Facebook, Instagram, contact form) rendered via SocialLinks component below contact links
- Added PoliticianProfile as named export from ev-ui index.jsx
- Human verification confirmed correct rendering on LA County supervisor and city council profiles

## Task Commits

Each task was committed atomically:

1. **Task 1: Add contact section to PoliticianProfile and export from index** - `29f0b50` (feat, ev-ui repo)
2. **Design refinement: consolidate contact info under profile photo** - `901dba6` (feat, ev-ui repo)

## Files Created/Modified
- `ev-ui/src/PoliticianProfile.jsx` - Restructured layout: left column (photo + contact section) + right column (name, title, info). Contact section merges enriched contacts + BallotReady data. Icons identify contact types. Removed separate contact card and formatContactType function.
- `ev-ui/src/index.jsx` - Added `PoliticianProfile` named export

## Decisions Made
- Contact section placed below the profile photo in the left column rather than as a separate card — keeps related info grouped and uses vertical space efficiently
- Icons replace text labels ("Phone:", "Website:", "Email:") — phone icon, globe icon, envelope icon are sufficient identifiers in the narrow column
- Websites and emails display full text (URL/address) so users can see where links go before clicking
- Social media links (Twitter, Facebook, Instagram) remain icon-only via SocialLinks component
- Contact type labels ("District Office", "City Website") dropped — icon-based identification is cleaner
- BallotReady person-level data (urls, email_addresses) merged with enriched contacts and deduplicated to avoid showing the same link twice

## Deviations from Plan

### Design Iteration

Original plan specified a separate contact card with text labels and contact_type headings. After human verification, the design was refined to:
- Move contact section from separate card into left column below photo
- Replace text labels with icon-only identification
- Drop contact_type labels
- Merge social links into the same section
- Show full URLs/emails instead of truncated display

This was a user-directed design improvement, not a scope deviation.

## Issues Encountered

None.

## User Setup Required

None - ev-ui rebuild is complete. Essentials app picks up changes via `file:../ev-ui` reference in package.json.

## Next Phase Readiness

- Phase 43 complete — both API (plan 01) and frontend (plan 02) changes are in place
- Contact info visible on politician profiles for officials with enriched contact data
- Building photo endpoint ready for frontend consumption

## Self-Check: PASSED

All created/modified files verified present on disk. Task commits `29f0b50` and `901dba6` verified in git log (ev-ui repo).

---
*Phase: 43-go-api-and-frontend-updates*
*Completed: 2026-02-25*
