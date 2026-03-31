# Phase 100: Elected/Appointed Filter - Context

**Gathered:** 2026-03-30
**Status:** Ready for planning

<domain>
## Phase Boundary

Add a filter toggle on the main Representatives page letting users view All, Elected-only, or Appointed-only officials. Retention judges (faces_retention_vote=true) appear in both Elected and Appointed views. The filter defaults to All, preserving current behavior. No backend changes — filtering is entirely client-side.

</domain>

<decisions>
## Implementation Decisions

### Filter Placement & Interaction
- **D-01:** Stacked filters — the Elected/Appointed filter is a separate control from the existing tier filter (All/Local/State/Federal). Both are active simultaneously (e.g., "State" + "Elected" = only elected state officials).
- **D-02:** Elected/Appointed filter sits below the tier filter in the sidebar (desktop) and below the tier pills (mobile).

### Filter UI Style
- **D-03:** Segmented control (iOS-style pill toggle) with three options: All / Elected / Appointed. Visually distinct from the tier radio buttons, making it clear this is a separate filter dimension.

### Filtering Logic
- **D-04:** Client-side filtering only — no backend changes. The API already returns `is_appointed` (politician-level), `is_elected` (office-level derived from `!is_appointed_position`), and `faces_retention_vote` on every politician response.
- **D-05:** Client-side resolution of the priority chain: check `politician.is_appointed` first (individual override), then fall back to `offices.is_appointed_position` (per Phase 97 decision). Frontend combines these with `faces_retention_vote` to determine filter visibility.
- **D-06:** Filter logic:
  - **All**: Show everyone (current behavior, default)
  - **Elected**: Show officials where resolved is_appointed=false OR faces_retention_vote=true
  - **Appointed**: Show officials where resolved is_appointed=true (includes retention judges since they are appointed)

### Retention Judge Presentation
- **D-07:** No special visual indicator for retention judges. They silently appear in both Elected and Appointed views. No badge, no tooltip — the filter just works.

### Claude's Discretion
- Segmented control visual styling (colors, active state, sizing)
- Mobile responsive behavior for the segmented control
- State management approach for the new filter (useState, URL param, or cache)
- Animation/transition when filter changes
- Label text variations if "Elected/Appointed" feels too long on mobile

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Frontend
- `essentials/src/pages/Results.jsx` — Main results page with existing tier filter, politician display, and tab toggle (Representatives/Elections)
- `essentials/src/components/LocalFilterSidebar.jsx` — Desktop sidebar with tier radio buttons, search, and candidates toggle
- `essentials/src/utils/sorters.js` — Contains `electedFirstKey` sorter (line 152-153) already aware of is_elected
- `essentials/src/lib/classify.js` — Tier classification logic

### Backend Data Fields
- `ev-accounts/backend/src/lib/essentialsService.ts` — Returns `is_appointed` (politician-level, line 989), `is_elected` (office-level, line 993), `is_appointed_position` (office-level, line 1004)
- `ev-accounts/backend/migrations/043_faces_retention_vote.sql` — faces_retention_vote column on essentials.offices, Indiana appellate judges flagged

### Prior Phase Decisions
- `.planning/phases/97-schema-foundation-data-audit/97-CONTEXT.md` — D-10: faces_retention_vote on offices table; D-08/D-09: is_appointed audit approach

### Requirements
- `.planning/REQUIREMENTS.md` — FILT-01, FILT-02, FILT-03

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **LocalFilterSidebar**: Already has tier filter radio buttons — add segmented control below
- **electedFirstKey sorter**: `sorters.js:152` already sorts elected-before-appointed — can inform default ordering
- **selectedFilter state**: Results.jsx already manages tier filter state — new filter needs parallel state

### Established Patterns
- **Tier filter**: Radio buttons on desktop (LocalFilterSidebar), pill buttons on mobile (Results.jsx ~line 917)
- **useMemo filtering**: Results.jsx uses `useMemo` chains for filtering and classifying politicians — new filter slots into this chain
- **Cache integration**: Results page caches filter state in `cachedResult?.filter` — new filter should follow same pattern

### Integration Points
- **Results.jsx**: Add new state for elected/appointed filter, add useMemo filter step, pass to LocalFilterSidebar
- **LocalFilterSidebar.jsx**: Add segmented control component below tier radio buttons
- **Mobile pills section**: Add segmented control below existing tier pills (~line 912-931)
- **API response**: `faces_retention_vote` needs to be included in the politician response if not already — verify during implementation

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 100-elected-appointed-filter*
*Context gathered: 2026-03-30*
