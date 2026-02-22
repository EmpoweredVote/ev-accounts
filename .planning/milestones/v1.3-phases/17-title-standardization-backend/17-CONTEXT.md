# Phase 17: Title Standardization (Backend) - Context

**Gathered:** 2026-02-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Standardize all topic naming fields in the compass.topics database table so they serve as the canonical source of truth for downstream display. This phase covers the 20 active topics plus 1 inactive topic (Ukraine). The seed file (topics.json) is outdated and not the source of truth — the live database is.

</domain>

<decisions>
## Implementation Decisions

### Naming format — Tension titles
- Title field repurposed to the "tension title" format: `[Topic]: [Pole A] — [Pole B]`
- Example: `Healthcare: Universal Coverage — Market-Driven`
- Pole names use policy outcome pairs (not abstract labels like "Left vs Right")
- Em dash (—) separates the two poles — conveys spectrum without combative "vs" framing
- Pole order is **randomized per topic** — no consistent left-to-right political ordering. This is a core anti-partisan design principle: nobody should detect a pattern that frames one side as default/correct
- Target ~70 character max for tension titles to fit card display

### Naming format — Short titles (spoke labels)
- ShortTitle field remains the compass spoke label — must be concise
- Current short titles need improvement for clarity (e.g., some are too vague)
- Claude drafts improved short titles for all 21 topics alongside tension titles

### Naming format — Custom questions
- QuestionText field repurposed to hold a unique, hand-crafted policy question per topic
- Shown above the stances in: library drawer, compass calibration, compare compass pages
- Tone: direct and policy-focused (not exploratory/curious)
- Format: single question only, no context line prefix
- Avoid all leading phrases: no "Where do you stand on...", "Do you think...", "Should we...", "Is it right to..."
- Example: "How should the U.S. healthcare system be structured?"

### Field structure — Cleanup
- **Keep:** ShortTitle (spoke label), Title (tension title), QuestionText (custom question)
- **Drop:** ShortName (always null, redundant with ShortTitle), StartPhrase (replaced by custom QuestionText)
- 3 fields with distinct, clear purposes — no ambiguity

### Review process
- Claude drafts all 21 topics: short name + tension title + custom question
- User reviews in batches grouped by category (domestic policy, foreign policy, social issues, etc.)
- User approves, flags edits, and signs off before database migration

### Scope
- Standardize all 21 topics (20 active + 1 inactive Ukraine topic)
- Live database is the source of truth, not topics.json seed file
- Current stances have 5 per topic (not 10 as in seed file) — stance content is not in scope

### Claude's Discretion
- Exact tension title wording for each topic (user reviews in batches)
- How to group topics into review batches
- Database migration approach (direct UPDATE vs migration script)
- Whether to update topics.json seed file to match or deprecate it
- Column removal strategy for ShortName and StartPhrase

</decisions>

<specifics>
## Specific Ideas

- Anti-partisan principle is paramount: "We don't want anyone to feel like we are persuading them on which direction to go"
- "No one can accuse us of being partisan in any way" — this drives randomized pole order and neutral policy outcome framing
- User referenced iSideWith as an example of specific questions, but noted those are yes/no which doesn't fit the spectrum model
- The spectrum stances already reveal the actual dimension — tension titles make that dimension explicit

</specifics>

<deferred>
## Deferred Ideas

- Topic merging/consolidation (e.g., overlapping topics) — future content review phase
- Stance text review/rewriting — separate from naming standardization
- Updating topics.json seed file — Claude's discretion whether to include in Phase 17

</deferred>

---

*Phase: 17-title-standardization-backend*
*Context gathered: 2026-02-20*
