# Phase 33: Essentials Integration Guide - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Write `docs/ESSENTIALS-INTEGRATION.md` — a reference document for the Essentials team covering the Inform Pillar access pattern, the "never ask address again" jurisdiction principle, and how to surface Connected enhancements as opt-in. No code changes; documentation only.

</domain>

<decisions>
## Implementation Decisions

### Document structure
- Flow: Concepts → Code (not reference-style, not scenarios-first)
- Opening section: The jurisdiction principle — "never ask for address again" as the framing anchor
- Section order: Jurisdiction Principle → Access States → Detection Pattern → Jurisdiction Fields Reference → Connected Enhancements
- Navigation: ToC at the top with anchor links (markdown-standard, GitHub-compatible)

### Audience & assumptions
- Assumed baseline: Knows Essentials well, new to Accounts — explain Accounts concepts inline as needed, do not assume they've read PROJECT.md or any other Accounts docs
- Cross-references: Self-contained — all needed Accounts context explained inline, no external links required to implement correctly
- Voice: Essentials product terms where known (specific features and screens), not generic developer language
- Key behavior to document: Connected users get their jurisdiction pre-populated as the default locality; they can still type in and explore other areas the same way anonymous/Inform users do

### Code example depth
- Form: Real TypeScript using actual field names (e.g., `jurisdiction.congressional_district`, `jurisdiction.county`)
- Completeness: Full decision pattern with both null and non-null jurisdiction branches, no error handling boilerplate
- Volume: One canonical example per concept — most common case shown, variants described in prose
- Values: Real/realistic production values (actual FIPS codes, district codes, string formats as they appear in production)

### Anonymous→Connected transition
- UX framing: Decision tree — null jurisdiction = address input required, non-null jurisdiction = use silently and pre-populate locality
- Connect prompt: Specify WHEN to show it (anonymous user performs a persistent action), not WHAT it says — UI copy is Essentials' decision
- User detection: `GET /api/account/me` on every page load — null response = anonymous, populated response = Connected with jurisdiction data; Essentials does not maintain its own auth state
- Connected enhancements: Endpoint reference + opt-in framing — list XP award, gem award, and persistence endpoints with their shapes; frame clearly as optional

### Claude's Discretion
- Exact prose wording and section titles
- Whether to add a quick-reference summary box at the top
- How to handle edge cases (e.g., Connected user with null jurisdiction due to incomplete profile setup)

</decisions>

<specifics>
## Specific Ideas

- "Never ask for an address twice" as the opening principle statement
- Connected users: jurisdiction is the default locality, but manual area exploration works the same as for Inform users — this distinction is the core Essentials integration behavior

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 33-essentials-integration-guide*
*Context gathered: 2026-03-19*
