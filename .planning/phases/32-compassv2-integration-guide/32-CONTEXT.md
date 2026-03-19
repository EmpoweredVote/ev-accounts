# Phase 32: CompassV2 Integration Guide - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Write `docs/COMPASSV2-INTEGRATION.md` — a single authoritative reference replacing `docs/COMPASS_CONTRACT.md`. Covers auth redirect flow, all compass API endpoints, tier access model, and the jurisdiction principle. This is a documentation phase: no code changes, one new file, one deletion.

</domain>

<decisions>
## Implementation Decisions

### Primary consumer
- The doc is written for an **AI agent (Claude)** as its primary consumer — not a human developer reading top-to-bottom
- This means: dense, precise, unambiguous over narrative and prose-heavy
- But still needs to stand alone with zero prior context about Empowered Accounts

### Document structure
- **Quick-reference summary at the top**: endpoint table, auth URL, tier summary — Claude can grab what it needs without reading everything
- **Sections organized by workflow/task** (not by system area), e.g., "Authenticate a user", "Fetch compass data", "Read jurisdiction and personalize content" — organized around what CompassV2 needs to do
- Detailed sections follow the quick-reference

### Code example style
- **Both HTTP and TypeScript** — HTTP block first (shows the contract), TypeScript snippet second (shows the implementation)
- Depth of TypeScript examples: **Claude's discretion** — full copy-pasteable functions for complex flows (auth), illustrative fragments for simple fetches
- **Real production field names and types** in response shapes — no schematic placeholders; Claude should never have to guess field names

### Audience baseline
- **Zero prior context assumed** — doc explains what Inform/Connected/Empowered tiers mean, what each unlocks, why the auth design works the way it does
- **Explain from scratch** including Supabase/JWT concepts as they apply to Empowered's specific configuration (not a general Supabase tutorial, but no assumed JWT knowledge either)
- **Explicit anti-patterns** included — what CompassV2 should NOT do, e.g., "don't prompt for address if jurisdiction is present", "don't cache tier status client-side"

### Depth of "why"
- **Full rationale** for the auth redirect flow — explains why hash fragment instead of query param, why login lives at accounts.empowered.vote, etc. Prevents Claude from "fixing" patterns it doesn't understand
- **Full philosophy** for the jurisdiction principle — why jurisdiction flows automatically, why asking for address again is a product violation, the user experience this enables
- **Full platform preamble** — first section explains Empowered Vote's mission, the three-tier model (Inform/Connected/Empowered), and why the auth/tier design is the way it is. Gives Claude complete platform context before any integration specifics

### Claude's Discretion
- Depth of TypeScript examples (full vs. fragment) based on complexity
- Where to add anti-patterns beyond the explicitly mentioned cases (address prompt, tier caching)
- Exact section heading names within the task/workflow structure

</decisions>

<specifics>
## Specific Ideas

- Doc replaces `docs/COMPASS_CONTRACT.md` entirely — it is not additive. Old file deleted, new file is canonical.
- Endpoint table at top: one row per endpoint with method, URL, auth requirement, one-line description
- The "never ask for address again" principle is a first-class section, not a footnote in the jurisdiction section
- Anti-patterns should be visually distinct (callout box or `> ⚠️` blockquote) so Claude can't miss them

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 32-compassv2-integration-guide*
*Context gathered: 2026-03-19*
