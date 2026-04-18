---
phase: 120-contested-race-bio-photo-authoring
plan: 02
status: complete
completed: 2026-04-16
commits:
  - d54e147
  - a764069
  - (approval commit to follow)
key-files:
  created:
    - .planning/phases/120-contested-race-bio-photo-authoring/120-REVIEW-DATA.md
---

# Plan 120-02 Summary

## What was built

User-approved bio drafts + photo source data for 11 contested-race candidates in `120-REVIEW-DATA.md`.

## Tasks

| Task | Status | Commit | Notes |
|------|--------|--------|-------|
| 1. Research + compile REVIEW-DATA.md | complete | `d54e147` | 11 Ballotpedia-sourced bios, all ≤180 chars |
| — | correction | `a764069` | 10 of 11 already have CDN photos — corrected `NO_PHOTO` → `EXISTING` after direct query |
| 2. User review + approval | complete | (approval commit) | All 11 marked APPROVED as stopgap content |

## Key findings (deviations from plan intent)

1. **Scope narrowed by user at wave boundary.** Plan 02 targeted "all contested-race candidates from CANDIDATE-SCOPE.md" (up to 28); user chose minimum-viable 11-candidate scope (Priority A + B only). 17 Priority C township photo-only candidates deferred.

2. **Photo inventory correction.** Wave 2 executor initially marked all 10 Priority B candidates as `NO_PHOTO` because no photo was researched from Ballotpedia. Direct query of `essentials.politician_images` revealed 10 already have `type='default'` photos in Supabase CDN — only David Waters truly needs a photo re-hosted. REVIEW-DATA.md was corrected and re-committed.

3. **Direction change acknowledged.** During the Task 2 checkpoint, user signaled dissatisfaction with the one-line-bio format and expressed preference for structured resume (degrees + experiences) going forward. Investigation confirmed:
   - 0 of 11 target candidates have rows in `essentials.degrees` or `essentials.experiences`
   - Only 116 / 79,188 politicians system-wide have degrees; 232 have experiences — these tables are effectively dormant
   - `ev-ui/src/PoliticianProfile.jsx` has no render for either table
   User chose to ship the one-line bios as stopgap content and address resume/education in a follow-up phase.

4. **Bio fallback rate.** 4 of 11 bios use the D-15 office-title fallback (Branham, Davis, Lucas, Arrington) — Ballotpedia candidate pages exist but Candidate Connection surveys were not completed, so no extractable biographical detail was available under the single-source rule.

## Downstream handoff for Plan 03

- **Bio updates**: 11 rows → `UPDATE essentials.politicians SET bio_text = ... WHERE id = ...`
- **Photo upload**: 1 row → download David Waters photo, re-host to Supabase Storage, INSERT `essentials.politician_images` row
- **Slug generation**: All 11 candidates have `slug = NULL` in production. Plan 03 must generate slugs (lowercase + hyphenate + optional UUID suffix pattern) and write back to `essentials.politicians.slug` before constructing Storage paths.

## Out of scope (flagged for follow-up)

- 17 Priority C township photo-only candidates (deferred per user scope override)
- Structured resume (degrees + experiences) approach — future phase
- US-9 candidate photo upgrades from Ballotpedia 200/300 thumbnails (noted in REVIEW-DATA.md)

## Self-Check: PASSED

- REVIEW-DATA.md exists with all 11 rows APPROVED
- Every bio ≤ 180 chars, single sentence, single-source (Ballotpedia)
- Antipartisan constraint applied (no party framing)
- Photo column accurately reflects CDN state (EXISTING / URL)
- User approved all rows as stopgap content
