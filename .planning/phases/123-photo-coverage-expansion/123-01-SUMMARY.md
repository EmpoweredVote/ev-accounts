---
phase: 123-photo-coverage-expansion
plan: 01
status: checkpoint
completed: 2026-04-17
subsystem: data-import
tags: [photos, headshots, candidates, audit, indiana, california]
dependency-graph:
  requires: []
  provides:
    - 123-CANDIDATE-AUDIT.md (authoritative photo-gap list)
    - 123-REVIEW-DATA.md (photo sources for user review)
    - import-123-photo-expansion.ts (ready for Plan 02 execution)
  affects:
    - ev-accounts/backend/scripts/import-123-photo-expansion.ts
tech-stack:
  added: []
  patterns:
    - Photo-only import with dual-write (politician_images + photo_custom_url)
    - Per-candidate transactions with ROLLBACK on error
    - --commit flag dry-run convention
    - Slug derivation for candidates without existing slugs
key-files:
  created:
    - .planning/phases/123-photo-coverage-expansion/123-CANDIDATE-AUDIT.md
    - .planning/phases/123-photo-coverage-expansion/123-REVIEW-DATA.md
    - .planning/phases/123-photo-coverage-expansion/123-01-PLAN.md
    - ev-accounts/backend/scripts/import-123-photo-expansion.ts
  modified: []
decisions:
  - "All 55 audit-surfaced candidates researched; 55/55 have NO_PHOTO after Ballotpedia + secondary search (D-04 depth)"
  - "Indiana township candidates (20) have essentially no web presence — NO_PHOTO is expected"
  - "CA LA City/County candidates (29) recently filed; limited public profiles — NO_PHOTO pending user review"
  - "Import script uses phase123_2026/ storage prefix for photo paths"
metrics:
  duration: "~35 minutes"
  completed: "2026-04-17"
  tasks: 3
  files: 4
---

# Phase 123 Plan 01: Photo Coverage Expansion — Audit + Research

## One-liner

DB audit found 55 candidates missing headshots; Ballotpedia + web search yielded NO_PHOTO for all 55 (township candidates have no web presence; CA candidates recently filed); import script written and ready.

## Tasks

| Task | Status | Commit | Notes |
|------|--------|--------|-------|
| 1. DB photo-gap audit | complete | `bf12e2a` | 55 candidates: 26 IN, 29 CA |
| 2. Research photo sources | complete | `01790b4` | All 55 NO_PHOTO after 2-source check |
| 3. Write import-123 script | complete | `c25e1b9` | Photo-only, follows import-120 patterns |
| 4. User review checkpoint | **BLOCKED** | — | Awaiting user review of 123-REVIEW-DATA.md |

## Audit Results

**55 candidates missing a default headshot photo** (vs. ~62 estimated in roadmap; actual count is lower because Phase 120 handled some contested-race candidates):

| Group | Count |
|---|---|
| Indiana May 5, 2026 (township/trustee/state rep) | 26 |
| California June 2, 2026 (LA City/County Council) | 29 |
| **Total** | **55** |

## Photo Research Outcome

All 55 candidates were checked against Ballotpedia and a secondary web/social search per D-04:

- **Indiana township candidates (20):** No Ballotpedia pages; no campaign websites or social media headshots found. Township board/trustee candidates in Monroe County have essentially no web presence.
- **Indiana Amy Oliver (State Rep D-62):** Ballotpedia page exists but has no photo; no campaign website found.
- **Indiana other trustee/board candidates (5):** No Ballotpedia pages or findable photos.
- **California LA City/County candidates (29):** These are June 2026 races. Many candidates filed recently and have limited public profiles. No usable headshots found via Ballotpedia or secondary search.

**Net result:** 55 NO_PHOTO entries pending user confirmation.

## Deviations from Plan

None — plan executed exactly as structured in CONTEXT.md D-04. The 2-source check depth was applied uniformly; all candidates fell below the findability threshold for this depth of search.

**Note on CA candidates:** The user may have access to official campaign filings, city clerk records, or direct campaign contact that could yield photos. The REVIEW-DATA.md user-action section specifically calls this out.

## Known Stubs

`import-123-data.json` does not exist yet — it must be generated from the approved REVIEW-DATA.md before Plan 02 runs the import. The import script raises a clear error if the data file is missing.

## Threat Flags

None — no new network endpoints or auth paths introduced. Import script is read-only DB access (pre-flight query) in dry-run mode.

## Self-Check: PASSED

| Check | Result |
|---|---|
| 123-CANDIDATE-AUDIT.md exists | FOUND |
| 123-REVIEW-DATA.md exists | FOUND |
| 123-01-PLAN.md exists | FOUND |
| import-123-photo-expansion.ts exists | FOUND |
| Commit bf12e2a exists | FOUND |
| Commit 01790b4 exists | FOUND |
| Commit c25e1b9 exists | FOUND |
