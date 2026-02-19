# Phase 10: Term Dates - Context

**Gathered:** 2026-02-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Move term date information off dashboard politician cards and onto politician profile pages. Cards get decluttered; profiles gain useful term context. No new data sources or capabilities — this relocates existing date fields.

</domain>

<decisions>
## Implementation Decisions

### Card cleanup
- Remove only term start/end dates from politician cards — keep all other fields (name, title, party, district)
- Apply universally to all cards — federal, state, and local
- Keep card height consistent after removal — let remaining content breathe rather than shrinking cards

### Profile date display
- Show term dates directly below the politician's title/office name, as a subtitle line
- Format as month-year range: "Jan 2023 – Jan 2027"
- No label prefix — just the date range by itself, context makes it obvious
- Subtle/secondary styling — smaller text, muted color, supporting info not a focal point

### Date edge cases
- Missing dates (no data from BallotReady): hide the date line entirely — don't show a placeholder
- Ongoing terms (start date only, no end date): display as "Since Jan 2023"
- Appointed officials (judges, cabinet): same treatment as elected — "Since Jan 2023" works for both
- Expired terms (end date in the past): show normally — "Jan 2021 – Jan 2025" with no special indicator

### Claude's Discretion
- Exact font size and color for the date subtitle
- Spacing between title and date line
- Any animation or transition when dates appear on profile load

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 10-term-dates*
*Context gathered: 2026-02-18*
