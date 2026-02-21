# Phase 18: Title Display (Frontend) - Context

**Gathered:** 2026-02-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the CompassV2 frontend render standardized topic names from Phase 17's server data. Compass spoke labels, Library cards, calibration cards, library drawer, and compare page all pull from the correct server fields. No "Where do you stand on..." prefix visible anywhere.

</domain>

<decisions>
## Implementation Decisions

### Field-to-view mapping
- **Compass spokes:** ShortTitle only (concise labels)
- **Library cards:** Tension title (Title field) — two-line format (see below)
- **Calibration cards:** Tension title (Title field) — identical layout to Library cards
- **Compare page:** Tension title (Title field) for topic labels
- **QuestionText rule:** Appears everywhere stances are shown — library drawer, calibration, compare page. If stances are visible, QuestionText is visible above them

### Tension title presentation (cards)
- Two-line layout: split at the colon
  - Line 1: Topic name (e.g., "Healthcare")
  - Line 2: Poles (e.g., "Universal Coverage — Market-Driven")
  - Colon is removed — the line break replaces it
- Library cards and calibration cards use identical tension title layout
- Poles line styling: Claude's discretion (smaller/muted vs same size different weight)

### Question text placement
- Position: between tension title and stances (acts as a bridge/context setter)
- Style: italic, medium weight — visually distinct from bold title above and stance text below
- On calibration cards: standalone prompt feel — centered, slightly separated from surrounding content
- On compare page: appears once per topic section, above the user vs politician stance comparison
- If QuestionText is empty/missing: show nothing (skip the area entirely)

### Prefix removal
- Audit the three key views (Library cards, calibration cards, compass labels) for any hardcoded "Where do you stand on..." prepending or StartPhrase usage
- Trust the server — no client-side defensive stripping of prefixes
- Phase 17 makes server data canonical; frontend just renders what it receives

### Claude's Discretion
- Poles line typography (size, weight, color relative to topic name)
- Exact spacing and padding for the two-line tension title layout
- How to structure the code changes (shared component vs per-view edits)
- Any StartPhrase field references found during the audit — removal approach

</decisions>

<specifics>
## Specific Ideas

- The two-line split should feel clean — topic name is the primary read, poles are supporting context
- QuestionText in calibration should feel like "here's the question you're answering" — centered, standalone prompt
- Consistency is the core goal: a user scanning Library, then calibration, then the compass should see the same name for every topic in all three places

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 18-title-display-frontend*
*Context gathered: 2026-02-20*
