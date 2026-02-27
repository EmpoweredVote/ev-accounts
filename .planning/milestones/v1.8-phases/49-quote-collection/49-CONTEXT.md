# Phase 49: Quote Collection - Context

**Gathered:** 2026-02-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Gather verbatim, sourced politician quotes on compass topics and format them as a CSV ready for Read & Rank import. The 23 politicians researched in Phases 46-48 are the target set. This phase collects quotes only — import scripts are Phase 50.

</domain>

<decisions>
## Implementation Decisions

### Quote CSV Schema
- Separate file: `EV-Backend/data/quote_collection.csv` (not added to stance_research.csv)
- Columns: `full_name,topic_key,quote_text,source_url,source_name`
- Uses compass `topic_key` values (healthcare, abortion, tariffs, etc.) matching stance_research.csv convention
- Multiple quotes per politician per topic are allowed (multiple rows)
- No external_id column needed — import script (Phase 50) handles ID resolution

### Quote Quality Standards
- Verbatim quotes only — must appear in quotation marks in the original source
- No indirect quotes or paraphrases under any circumstances
- Preferred length: 2-4 sentences — enough context to understand the position, not so long it overwhelms the card UI
- All source types acceptable: .gov press releases, news articles, debate transcripts, campaign sites, floor speeches — any source with a verifiable URL
- Recent quotes preferred (2022-present) but older quotes acceptable when they're the best available
- When no verbatim quote exists for a topic, flag it as a gap but do not include indirect quotes

### Topic Coverage Strategy
- Best effort across all 21 compass topics for all 23 researched politicians
- Start from source URLs already in stance_research.csv — mine those first for verbatim quotes
- Expand to fresh research only for gaps where existing sources don't contain direct quotes
- All 23 politicians researched equally — no priority tiers
- Omit CSV rows where no verbatim quote is found (absence = no quote available)

### Claude's Discretion
- Research ordering and batching strategy across politicians
- How to structure plans (by politician, by topic, by state delegation, etc.)
- How to track and report gaps at the end

</decisions>

<specifics>
## Specific Ideas

- Read & Rank mock data shows the target format: quote text displayed on cards with source attribution
- Existing stance_research.csv has ~455 rows across 23 politicians with source URLs — these are the starting point for finding quotes
- Debates and hearings are especially valuable since they often have full transcripts with direct quotes

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 49-quote-collection*
*Context gathered: 2026-02-26*
