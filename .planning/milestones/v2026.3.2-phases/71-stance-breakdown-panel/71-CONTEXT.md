# Phase 71: Stance Breakdown Panel - Context

**Gathered:** 2026-03-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the right-side topic list in the CompassCard showing a scannable topic-by-topic stance breakdown. Each topic row displays the politician's stance position label, and expands on tap to show reasoning summary text and source links. This phase replaces the skeleton placeholder from Phase 69.

</domain>

<decisions>
## Implementation Decisions

### Row Layout & Interaction
- Accordion-style clickable topic list — each row shows topic name + politician's stance label
- Tap a row to expand and show reasoning + sources below
- True accordion: only one topic expanded at a time — tapping a new topic closes the previous
- All topics start collapsed on initial load
- Politician's stance label only (e.g., "Strongly Support") — no full stance list, no user stance comparison in rows
- Stance label resolved client-side by mapping Answer.value to Stance.text from allTopics (already in CompassContext)

### Expanded Content
- Reasoning text displayed first, then "References" section below with source links
- Source links follow ComparePanel pattern: numbered list with favicon + truncated display URL
- Port Favicon component from CompassV2 to Essentials (uses Google favicon service)
- Port getDisplayUrl helper from ComparePanel for URL truncation
- When no context data exists (no reasoning or sources): show "No detailed reasoning available for this topic."

### Data Fetching
- Lazy fetch: context data (reasoning + sources) fetched only when user taps to expand a topic row
- Uses existing endpoint: `GET /compass/politicians/{pid}/{tid}/context`
- Cache fetched context in component state (Map keyed by topic ID) — re-expanding shows cached data instantly
- No bulk endpoint needed — lazy loading keeps API calls to only topics the user explores

### Mobile Stacked Behavior
- Full topic list renders in natural page flow below the radar chart (no constrained scroll area)
- All rows collapsed initially, expanding pushes content down naturally
- True accordion behavior maintained on mobile (one open at a time)

### Claude's Discretion
- Expand/collapse animation (smooth height transition or instant)
- Loading spinner style in expanded area while context is fetching
- Exact spacing, padding, and typography within accordion rows
- Whether to show a subtle expand indicator (chevron icon) on rows
- How to handle the right-zone skeleton-to-accordion transition in CompassCard.jsx

</decisions>

<specifics>
## Specific Ideas

- Pattern should feel similar to ComparePanel on the CompassV2 compare page — topic selection, reasoning text, source links with favicons — but adapted as an accordion instead of a dropdown
- Stances are condensed to just the label because the radar chart already provides the visual comparison
- The accordion prioritizes reasoning and sources over stance positions — this is the "why" panel, not the "what" panel

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `CompassV2/src/components/ComparePanel.jsx`: Reference implementation with reasoning fetch, source links, Favicon component, getDisplayUrl helper — pattern to mirror
- `CompassV2/src/components/Favicon.jsx`: Google favicon service component — port to Essentials
- `essentials/src/lib/compass.js`: `fetchPoliticianAnswers()`, `buildAnswerMapByShortTitle()` — already used in CompassCard
- `essentials/src/contexts/CompassContext.jsx`: Provides `allTopics` (with stances array per topic), `userAnswers`, `selectedTopics` — all needed for stance label resolution

### Established Patterns
- Context fetch: `GET /compass/politicians/{politician_id}/{topic_id}/context` returns `{ reasoning, sources }` — ComparePanel lines 47-73 show exact fetch pattern
- Stance label resolution: `topic.stances[answer.value - 1].text` — ComparePanel uses this mapping
- Source display: numbered `<ol>` with Favicon + getDisplayUrl + truncation — ComparePanel lines 259-285

### Integration Points
- `essentials/src/components/CompassCard.jsx:290-296`: Replace right-zone skeleton placeholder with accordion component
- `topicsFiltered` and `polData` already computed in CompassCard — use these to build the topic rows
- `polAnswers` state already available — contains `{ topic_id, value }` for stance label lookup
- Politician ID available as `politicianId` prop in CompassCard

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 71-stance-breakdown-panel*
*Context gathered: 2026-03-08*
