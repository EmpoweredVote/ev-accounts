---
phase: 49-quote-collection
plan: 07
subsystem: data
tags: [csv, quote-collection, data-cleanup, verbatim-quotes, read-rank]

# Dependency graph
requires:
  - phase: 49-quote-collection plans 01-06
    provides: quote_collection.csv with 179 rows across 23 politicians
provides:
  - Cleaned quote_collection.csv with 63 rows of verifiably-sourced verbatim quotes
  - Zero congress.gov/member, /bill, /vote rows — only specific press releases and news articles
affects: [50-read-rank-import, phase-50]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Verbatim quote standard: source_url must be a specific press release or news article, never a general index page"
    - "Omit rather than fabricate: rows without verifiable verbatim sources are removed, not replaced"

key-files:
  created: []
  modified:
    - EV-Backend/data/quote_collection.csv

key-decisions:
  - "49-07: Removed 116 rows citing congress.gov member/bill/vote pages and bloomington.in.gov/mayor — these are general index pages that do not contain verbatim politician quotes. Correct behavior per CONTEXT.md: omit rows where no verbatim quote is found."
  - "49-07: 12 politicians now have zero quotes in CSV (Young, Banks, Houchin, Sherman, Aguilar, Gomez, Lieu, Kamlager-Dove, Sanchez, Waters, Barragan, Thomson). Per CONTEXT.md standard, absence = no verbatim quote available. These politicians require real press release/news article sourcing before Read & Rank inclusion."
  - "49-07: 11 politicians retained: Gavin Newsom (26), Eleni Kounalakis (11), Mike Braun (11), Micah Beckwith (4), Laura Friedman (4), Alex Padilla (2), Adam Schiff (1), George Whitesides (1), Judy Chu (1), Karen Bass (1), Tony Cardenas (1). All 10 source domains are specific and verifiable."

patterns-established:
  - "Quote sourcing standard: gov.ca.gov, ltgov.ca.gov, latimes.com, indystar.com, in.gov, politico.com, calmatters.org, leginfo.legislature.ca.gov, mayor.lacity.org, washingtonpost.com are valid; congress.gov general pages are not"

requirements-completed: [QUOTE-01, QUOTE-02, QUOTE-03, QUOTE-04]

# Metrics
duration: 10min
completed: 2026-02-26
---

# Phase 49 Plan 07: Quote Collection Cleanup Summary

**Removed 116 non-compliant rows (congress.gov/bill, /member, /vote pages) from quote_collection.csv — CSV reduced from 179 to 63 rows, all citing specific verifiable press releases and news articles**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-02-26T23:22:00Z
- **Completed:** 2026-02-26T23:32:57Z
- **Tasks:** 2 of 2
- **Files modified:** 1

## Accomplishments
- Removed all 116 rows where source_url cited general index pages (congress.gov/member, /bill, /vote, and bloomington.in.gov/mayor)
- CSV reduced from 179 rows to 63 rows — all remaining rows cite specific dated press releases or news articles
- Zero new rows added — plan executed the "omit rather than fabricate" rule from CONTEXT.md
- Full validation passed: correct schema, all 21 topic_keys valid, no empty fields, no duplicates, no general page URLs

## Coverage Report

### Politicians Retained (11 politicians, 63 quotes)

| Politician | Quotes | Topics | Source Domains |
|------------|--------|--------|----------------|
| Gavin Newsom | 26 | 21 | gov.ca.gov, washingtonpost.com, calmatters.org |
| Eleni Kounalakis | 11 | 10 | ltgov.ca.gov, calmatters.org |
| Mike Braun | 11 | 11 | in.gov, indystar.com, politico.com |
| Micah Beckwith | 4 | 4 | indystar.com |
| Laura Friedman | 4 | 4 | leginfo.legislature.ca.gov, latimes.com |
| Alex Padilla | 2 | 2 | latimes.com |
| Adam Schiff | 1 | 1 | latimes.com |
| George Whitesides | 1 | 1 | latimes.com |
| Judy Chu | 1 | 1 | latimes.com |
| Karen Bass | 1 | 1 | mayor.lacity.org |
| Tony Cardenas | 1 | 1 | latimes.com |

**Source domains:** calmatters.org, leginfo.legislature.ca.gov, ltgov.ca.gov, mayor.lacity.org, www.gov.ca.gov, www.in.gov, www.indystar.com, www.latimes.com, www.politico.com, www.washingtonpost.com

### Politicians Fully Removed (12 politicians, 0 quotes)

These politicians now have zero representation in the quote CSV. Per CONTEXT.md, absence = no verbatim quote was available from verified sources. Real press release or news article sourcing is needed before these politicians can appear in Read & Rank:

- Todd Young — 7 rows removed (all congress.gov bill/vote/member pages)
- Jim Banks — 7 rows removed (all congress.gov bill/vote/member pages)
- Erin Houchin — 7 rows removed (all congress.gov bill/vote/member pages)
- Brad Sherman — 7 rows removed (all congress.gov bill/vote/member pages)
- Pete Aguilar — 7 rows removed (all congress.gov member page)
- Jimmy Gomez — 7 rows removed (all congress.gov bill pages)
- Ted Lieu — 7 rows removed (all congress.gov member page)
- Sydney Kamlager-Dove — 7 rows removed (all congress.gov bill/vote pages)
- Linda Sanchez — 7 rows removed (all congress.gov bill/vote pages)
- Maxine Waters — 7 rows removed (all congress.gov bill/vote pages)
- Nanette Barragan — 7 rows removed (all congress.gov bill/vote pages)
- Kerry Thomson — 1 row removed (bloomington.in.gov/mayor generic homepage)

### Removal Breakdown by Pattern

| Pattern | Count |
|---------|-------|
| congress.gov/bill/ | 65 rows |
| congress.gov/member/ | 42 rows |
| congress.gov/vote/ | 8 rows |
| bloomington.in.gov/mayor | 1 row |
| **Total removed** | **116 rows** |

## Task Commits

1. **Task 1: Remove non-compliant rows from quote_collection.csv** - `f3abbe1` (fix)
2. **Task 2: Validate cleaned CSV and produce coverage report** - no commit (validation-only task, no file changes)

## Files Created/Modified
- `EV-Backend/data/quote_collection.csv` — Reduced from 179 to 63 rows; all general index page citations removed

## Decisions Made

- Removed all 116 rows citing congress.gov member/bill/vote pages and the bloomington.in.gov/mayor homepage. These pages are legislative reference pages (member bios, bill text, vote tallies, city office homepage) — they do not contain verbatim politician quotes. The "omit rather than fabricate" rule from CONTEXT.md was applied.
- Did NOT add replacement rows for any removed politician. The plan explicitly states "Do NOT fabricate replacement rows." Real verbatim sourcing for the 12 fully-removed politicians is a future task.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None. The CSV filtering was straightforward. Python csv module handled multi-line quoted fields and embedded commas correctly via the QUOTE_MINIMAL quoting strategy.

## Next Phase Readiness
- `EV-Backend/data/quote_collection.csv` is now clean — 63 rows, all with specific verifiable press release or news article source URLs
- Phase 50 (Read & Rank import) can proceed with the 63 rows as-is
- The 12 politicians without quotes will simply have no cards in Read & Rank; this is acceptable per the verbatim standard
- Future improvement: find real LA Times, AP, or press release quotes for the 12 fully-removed politicians to expand Read & Rank coverage

## Self-Check: PASSED

- FOUND: `EV-Backend/data/quote_collection.csv` (63 rows, verified)
- FOUND: commit `f3abbe1` (fix(49-07): remove 116 non-compliant rows)
- FOUND: `49-07-SUMMARY.md`

---
*Phase: 49-quote-collection*
*Completed: 2026-02-26*
