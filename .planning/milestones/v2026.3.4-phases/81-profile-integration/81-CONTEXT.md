# Phase 81: Profile Integration - Context

**Gathered:** 2026-03-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire Read & Rank quote verdicts (agree/disagree evaluations) into Essentials politician profiles as per-quote badges inside the StanceAccordion expanded row. Works for guests via URL fragment (encoded in the "View on Essentials" CTA) with localStorage caching for session persistence. Logged-in server sync is Phase 82.

</domain>

<decisions>
## Implementation Decisions

### Verdict granularity
- Badges are **per-quote**, not per-topic: `verdictsByQuote: Record<quote_id, 'agreed'|'disagreed'>`
- No topic-level summary badge on the collapsed row — the existing `verdictsByTopic` prop from Phase 80 is superseded by quote-level verdicts
- When a user expands a topic row in StanceAccordion, ALL quotes for that politician/topic are shown — even if the user has zero verdicts
- Quotes with verdicts show Agreed (cyan) or Disagreed (amber) badge; unrated quotes show no badge

### Quote display in StanceAccordion
- Quotes are ALWAYS shown in the expanded row, not just when the user has verdicts
- Quote loading: lazy-fetch per topic alongside the context fetch (reasoning + sources)
  - Extend the existing context fetch or fire a parallel GET /essentials/quotes?politician_id=X
  - Quotes + reasoning both resolve when user expands the row
- Quote cards display: quote text + verdict badge (if any) + source attribution
- Requires ev-ui update (v0.1.43+): new `verdictsByQuote` prop and quote display in expanded rows

### Fragment format (VERD-05)
- Fragment key `v` encodes `{ [quote_id]: 'agreed' | 'disagreed' }` directly — no topic_key→UUID mapping needed
- Full fragment schema becomes: `#compass=BASE64({ a, s, i, v })`
- `v` carries ALL verdicts from the current Read & Rank session (across all politicians and topics) — not scoped to one politician
- This way, when a guest visits any politician profile in Essentials, badges appear for any quote they evaluated regardless of which politician they clicked "View on Essentials" from

### "View on Essentials" CTA (PROF-04)
- Appears on **both** surfaces in Read & Rank:
  1. **CandidateAlignmentPage** — direct link to that politician's Essentials profile with full verdict fragment
  2. **ResultsPhase** — one CTA per candidate card in the results list, each linking to the respective politician's profile
- Fragment encodes all session verdicts (full `v` map), not scoped to the candidate being linked
- The `candidate.id` in Read & Rank is the politician's UUID — Essentials profile URL: `essentials.empowered.vote/politician/{candidate.id}#{compass+verdict fragment}`

### CompassContext verdicts field (PROF-01)
- New `verdicts` state field: `Record<quote_id, 'agreed' | 'disagreed'>`
- Priority: API (Phase 82, not this phase) > URL fragment `v` key > `guestVerdicts` localStorage key > empty `{}`
- Populated in the same `loadAll()` effect that handles compass data — verdicts from fragment are cached to localStorage alongside compass data being cached to guestCompass

### localStorage strategy
- **Separate key**: `guestVerdicts` (not bundled into `guestCompass`)
- **Format**: `{ [quote_id]: 'agreed' | 'disagreed' }`
- **Expiry**: Never expires automatically; cleared when user logs in (analogous to `clearGuestCompass()` on login)
- `saveGuestVerdicts(verdicts)` and `loadGuestVerdicts()` helper functions in `essentials/src/lib/compass.js`

### Claude's Discretion
- Whether quotes inside the expanded row render as cards with border or as a simple list
- Exact loading state treatment when quotes are fetching (spinner inline or skeleton)
- Whether to collapse or remove `verdictsByTopic` prop from StanceAccordion given it's superseded (can deprecate silently)
- ev-ui version bump number (v0.1.43 or higher as appropriate)

</decisions>

<specifics>
## Specific Ideas

- "I want all their agrees/disagrees to show up on Essentials" — verdicts are session-wide, not scoped to one politician
- "Users should be able to see all information/quotes" — quotes always visible in expanded rows, verdict badges are additive on top
- The guest experience should be as full-featured as possible without requiring account creation

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `essentials/src/lib/compass.js` — `parseCompassFragment`, `saveGuestCompass`, `loadGuestCompass`, `clearGuestCompass` — add parallel `saveGuestVerdicts`/`loadGuestVerdicts`/`clearGuestVerdicts` following the same pattern
- `essentials/src/contexts/CompassContext.jsx` — existing `loadAll()` effect already handles fragment → cache flow; add `v` key parsing and `verdicts` state here
- `ev-ui StanceAccordion` — already has `verdictsByTopic` prop (Phase 80); needs new `verdictsByQuote` prop and quote display in expanded rows
- `GET /essentials/quotes?politician_id=X` — already exists; StanceAccordion can use this per-topic (filter by candidateId client-side after fetch, or add topic_key filter server-side)
- `EV-ReadRank/src/store/useReadRankStore.ts` — `issueProgress[issueId].agreedQuotes` and `disagreedQuotes` contain `Quote` objects with `id` — these are the quote IDs for the fragment

### Established Patterns
- Compass fragment already uses `#compass=BASE64(JSON)` with `{ a, s, i }` keys — `v` is a direct extension
- `candidate.id` in Read & Rank = politician UUID = `/politician/:id` route param in Essentials — no slug lookup needed
- EV design tokens for badges: Agreed = cyan-700/ecfeff (matches Phase 78 swipe color), Disagreed = amber-700/fffbeb (matches Phase 78) — already in ev-ui StanceAccordion
- Fragment stripping via `history.replaceState` already done in `parseCompassFragment` — carries through to `v` key

### Integration Points
- `essentials/src/components/CompassCard.jsx` — passes `verdictsByTopic` to StanceAccordion today; will pass `verdictsByQuote` from context instead
- `EV-ReadRank/src/components/ResultsPhase.tsx` — needs "View on Essentials" CTA per candidate card
- `EV-ReadRank/src/components/CandidateAlignmentPage.tsx` — needs "View on Essentials" CTA for the featured candidate
- Read & Rank needs `VITE_ESSENTIALS_URL` env var (or hardcoded `https://essentials.empowered.vote`) for the CTA link base

</code_context>

<deferred>
## Deferred Ideas

- "Explore this topic on Read & Rank" deep-link from StanceAccordion back to Read & Rank with topic pre-selected — noted as PROF-05 in requirements, future phase
- Verdict history view ("all quotes I evaluated for this politician") — PROF-06, future phase
- Phase 82 handles the logged-in sync (POST verdicts to backend; fetch from API as highest-priority source)

</deferred>

---

*Phase: 81-profile-integration*
*Context gathered: 2026-03-12*
