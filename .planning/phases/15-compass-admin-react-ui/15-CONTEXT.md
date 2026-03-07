# Phase 15: Compass Admin React UI - Context

**Gathered:** 2026-03-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the React admin UI for managing all compass data — topics (with stances), politicians (with answers and context), and categories — so an admin can seed and manage the compass entirely through the admin app without touching the database directly.

The backend (Phase 14) is complete: all 12 admin routes exist and are 401-guarded. This phase wires up the React admin frontend to those routes.

</domain>

<decisions>
## Implementation Decisions

### Page structure & navigation
- Extend the existing admin sidebar: add Topics, Politicians, Categories as new top-level sidebar items (alongside Users, Logs, etc.)
- No separate Compass section grouping — flat integration into current sidebar
- Clicking a topic or politician row opens a slide-out panel (detail stays visible alongside list)

### Topic creation flow
- New topic created via modal dialog: title, question text, short title (optional), and all 5 stance texts in a single form
- Stances are labeled by value (1–5, representing the spectrum) with a text field each
- After creation, modal closes and the new topic's slide-out panel auto-opens
- Live/draft toggle appears in BOTH the list row AND the panel header for convenience

### Politician detail view
- Slide-out panel layout: profile fields at top (name, office title, photo URL), then Compass Answers section below
- Compass Answers shows all topics as expandable rows (collapsed by default)
- Filter/search field within the panel to find topics by name — important as topic count grows
- Each expanded topic row shows: answer selector (pick one of the 5 topic-specific stance texts) + reasoning textarea + sources (text array, add/remove)
- Context fields (reasoning + sources) are always shown when a topic is expanded — not hidden behind a secondary action

### Inline editing & save patterns
- Stance texts in the topic detail panel: click text to enter edit mode; a single "Save stances" button commits all 5 at once
- Politician answer + context per topic: single "Save" button per topic row (edit answer/reasoning/sources for that topic, then save that row)
- Save feedback: Claude's discretion — inline button state (spinner → checkmark) is preferred for this admin context over toasts

### Claude's Discretion
- Exact save feedback pattern (inline button state vs toast — lean toward inline)
- Stance value selector UI (radio group showing full stance text, or equivalent)
- Empty state treatment for lists (topics, politicians, categories)
- Exact spacing, typography, component sizing within existing admin design system

</decisions>

<specifics>
## Specific Ideas

- The compass uses 1–5 spectrum values (not a +/-2 scale) — each value maps to a full stance text written per topic. The admin UI must show the actual stance text when selecting a politician's answer, not just a numeric label.
- The existing CompassV2 frontend (ev-compass.netlify.app) handles the user-facing compass. The admin tool is a separate React app — no shared components, but should match the operational spirit.
- Stance values 1–5 represent a policy spectrum (strongly oppose → strongly support, or equivalent framing per topic).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 15-compass-admin-react-ui*
*Context gathered: 2026-03-06*
