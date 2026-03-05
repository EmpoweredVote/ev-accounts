# Phase 11: Admin Tool XP View - Context

**Gathered:** 2026-03-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Add read-only XP visibility to the existing admin account detail page — a summary in the account header and a full ledger history section for Connected users. No XP awarding or editing from the admin tool. Non-Connected users are unaffected.

</domain>

<decisions>
## Implementation Decisions

### XP summary in account header
- Show Level and total XP for Connected (and Empowered) users in the existing account header card
- Display inline with the existing tier/standing badge area — e.g. "Level 4 · 12,500 XP" as a small text field or secondary badge
- Only rendered when `account.tier === 'connected' || account.tier === 'empowered'`
- Does NOT show for Basic (Inform) users — consistent with how Calibration Status is hidden for non-Empowered users

### XP History section
- The account detail page uses stacked card sections (not tabs) — add XP History as a new card section below the existing ones
- Note: roadmap uses the word "tab" but the UI has no tab system; a stacked section delivers the same capability without architectural disruption
- Displays ledger entries in **reverse chronological order** (newest first)
- Table format matching existing admin table pattern: `thead/tbody`, `divide-y divide-gray-100`, `px-4 py-3` cell padding
- Columns: **Source | Amount | Timestamp** — plus a collapsible metadata column
- Paginated using the existing pagination pattern (Previous/Next, page X of Y)
- Loading skeleton using the existing `animate-pulse` pattern

### Non-Connected accounts
- XP summary and XP History section are **entirely hidden** for non-Connected users
- No placeholder, no greyed-out state — same pattern as Calibration Status (existence check, not explicit "not connected" message)

### Metadata column
- Metadata JSONB shown as a small expandable — collapsed by default, click to reveal raw JSON or key-value pairs
- Claude's Discretion on exact expand/collapse implementation (button, accordion, tooltip)

### Claude's Discretion
- Exact visual treatment of the "Level X · Y XP" display in the header (badge vs text vs pill)
- Whether metadata expansion is a toggle row, inline expand, or modal
- Loading/error state copy for XP history fetch failures
- Exact column widths and table header labels

</decisions>

<specifics>
## Specific Ideas

- XP is a Connected-tier feature — XP data follows the same conditional rendering pattern already used for Calibration Status (Empowered only) and Admin-Only Fields
- Existing table pattern already handles pagination, loading skeleton, and error states — reuse exactly, don't invent new patterns
- The `calculate_level` RPC and `GET /api/xp/:userId` + `GET /api/xp/me/history` endpoints from Phase 10 are the data sources; the admin tool should call these directly (or via a new admin-scoped endpoint if service key is needed)

</specifics>

<deferred>
## Deferred Ideas

- Introducing a full tab system to the account detail page — would be a larger refactor; stacked sections deliver the same value with no structural change
- XP awarding or adjustment from the admin UI — out of scope, separate capability

</deferred>

---

*Phase: 11-admin-tool-xp-view*
*Context gathered: 2026-03-04*
