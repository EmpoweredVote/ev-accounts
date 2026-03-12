---
phase: quick-10
plan: 01
subsystem: ev-ui / essentials
tags: [contact-section, social-links, websites, ui, ev-ui]
dependency_graph:
  requires: []
  provides: [ev-ui@0.1.48]
  affects: [essentials/Profile.jsx]
tech_stack:
  added: []
  patterns: [domain-extraction, social-platform-detection, explicit-grid-columns]
key_files:
  created: []
  modified:
    - ev-ui/src/PoliticianProfile.jsx
    - ev-ui/src/SocialLinks.jsx
    - ev-ui/package.json
    - essentials/package.json
decisions:
  - Split allWebsites into plain sites vs socialWebsiteUrls during aggregation — avoids showing social URLs as text links while still surfacing their icons
  - hasSocial now only covers identifier-based handles — socialWebsiteUrls carries website-list-derived social URLs separately to avoid double-counting
  - SocialLinks extraLinks deduplication checks both exact URL match and platform substring match — prevents duplicate icons when a handle and a URL for same platform both exist
  - SOCIAL_PLATFORMS constant duplicated in SocialLinks.jsx — no shared module system in this library
metrics:
  duration: ~15 minutes
  completed: "2026-03-12T23:45:00Z"
  tasks_completed: 2
  files_changed: 4
---

# Quick Task 10: Refactor Contact Info Section on Politician Profiles — Summary

**One-liner:** Domain-only website display, social URLs as icon-only buttons at bottom of websites column, phone column fixed-narrow and email column wider, social icons removed from hero row — all in ev-ui v0.1.48.

## What Was Built

The contact information section in `PoliticianProfile` had four problems addressed:

1. **Website display text** — Full paths like `en.wikipedia.org/wiki/Mike_Braun` now display as `en.wikipedia.org`. The `extractDomain` helper uses `new URL().hostname` with `www.` stripped. The `href` still points to the full URL.

2. **Social URLs in websites list rendered as icons** — A `SOCIAL_PLATFORMS` pattern array and `detectSocialPlatform` helper split incoming website URLs into `allWebsites` (plain) vs `socialWebsiteUrls` (social). Social URLs are passed to `SocialLinks` via a new `extraLinks` prop and rendered as boxed icon buttons, not text links.

3. **Social icons moved from hero to contact section** — The `SocialLinks` row previously rendered in the hero `infoCol` above the contact grid was removed. Social icons now appear at the bottom of the websites column alongside any identifier-based handles (Twitter/Facebook/Instagram/LinkedIn).

4. **Column widths** — `contactGrid` now uses explicit column sizing instead of `repeat(N, 1fr)`: phone gets `140px` fixed, email gets `minmax(180px, 1fr)`, address and websites get `1fr`. This prevents phone numbers (short content) from taking up proportional space at the expense of email addresses.

`SocialLinks.jsx` was updated to:
- Accept `extraLinks` prop (array of URLs)
- Extract platform icons into a `platformIconMap` object for reuse
- Add YouTube icon (rect + polygon)
- Append `extraLinks` to the links array, skipping duplicates

## Files Changed

| File | Change |
|------|--------|
| `ev-ui/src/PoliticianProfile.jsx` | Added helpers, split social/plain website arrays, removed hero social row, updated websites column render, updated grid columns |
| `ev-ui/src/SocialLinks.jsx` | Added `extraLinks` prop, `platformIconMap`, YouTube icon, duplicate detection |
| `ev-ui/package.json` | Bumped `0.1.47` → `0.1.48` |
| `essentials/package.json` | Updated `@chrisandrewsedu/ev-ui` to `^0.1.48` |

## Commits

| Repo | Hash | Description |
|------|------|-------------|
| ev-ui | 2a382ed | feat(quick-10): refactor contact section social links and website display |
| ev-ui | 24bdb51 | chore(quick-10): bump ev-ui version to 0.1.48 |
| essentials | 1e61a35 | chore(quick-10): update ev-ui dependency to v0.1.48 |

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- `ev-ui/src/PoliticianProfile.jsx` — modified and committed (2a382ed)
- `ev-ui/src/SocialLinks.jsx` — modified and committed (2a382ed)
- `ev-ui/package.json` — version bumped and committed (24bdb51)
- `essentials/package.json` — dependency updated and committed (1e61a35)
- ev-ui build: success (no errors)
- essentials build: success ("built in 784ms")
- npm publish: `@chrisandrewsedu/ev-ui@0.1.48` confirmed published to GitHub npm registry
