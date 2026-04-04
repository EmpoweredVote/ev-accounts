# Phase 102: ev-ui Foundation + Quick Wins - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Publish ev-ui v0.1.55 with icon system (icons.js SVG exports), headshot crop fix (object-position default + imageFocalPoint prop), tierColors token, and optional tier prop on CategorySection. Fix two data issues: remove incumbent badge from election candidate cards, and correct Ruben Marte's name/link in race_candidates.

</domain>

<decisions>
## Implementation Decisions

### Icon System
- **D-01:** Icons exported as inline SVG React components from `ev-ui/src/icons.js` (e.g., `<BallotIcon />`, `<CompassIcon />`, `<BranchIcon />`). Each accepts `size` (default 16) and `color` (default 'currentColor') props. Matches existing SocialLinks.jsx pattern.
- **D-02:** SVG path data sourced from Lucide icon library (MIT license) — copy paths only, no runtime dependency on lucide-react. Researcher should find best-fit Lucide icons for: ballot status, compass availability, branch type.
- **D-03:** Icons are standalone — no shared wrapper component in ev-ui. Essentials handles tooltip/label/accessibility logic itself (Phase 103 scope).

### Headshot Cropping
- **D-04:** Default `objectPosition: 'center 20%'` on PoliticianCard image style. Shifts crop window upward to keep faces visible in standard portrait photos.
- **D-05:** Optional `imageFocalPoint` prop on PoliticianCard — defaults to `'center 20%'`, overridable per-image (e.g., `'center 15%'`). Prop is optional with null-safe fallback.
- **D-06:** Same cropping fix applied to both PoliticianCard and PoliticianProfile for consistency.

### tierColors Token
- **D-07:** `tierColors` export added to `tokens.js` as semantic map referencing `colorScales`. Structure: `{ federal: { bg, accent, text }, state: { bg, accent, text }, local: { bg, accent, text } }`.
- **D-08:** All three tiers use the teal color scale (NOT yellow for local): Federal=teal-700/teal-100, State=teal-500/teal-050, Local=teal-200/teal-050. Differentiation via shade, not hue.
- **D-09:** CategorySection accepts optional `tier` prop as string key (`'federal'` | `'state'` | `'local'`). ev-ui owns the tierColors lookup internally — consumers pass a simple string.

### Incumbent Badge Removal
- **D-10:** Remove the `'Incumbent'` badge prop passed to PoliticianCard in `ElectionsView.jsx` (line ~215). Do NOT touch CandidateProfile is_incumbent routing logic — that's separate functionality. (Carried from STATE.md)

### Ruben Marte Data Fix
- **D-11:** Fix seed SQL typo — `'Marte'''` has trailing escaped quote producing `Marte'` in DB. Correct to `'Marte'` (no accent — his name appears to be plain ASCII).
- **D-12:** Write migration/script to: (a) correct the stored name in race_candidates table, (b) look up matching politician by name and set politician_id to link candidate to politician profile.
- **D-13:** Add Unicode/diacritical normalization (NFD + strip combining marks) to candidate name matching logic for future imports, so accented names auto-match ASCII equivalents.

### Claude's Discretion
- Exact Lucide icon choices for ballot/compass/branch (researcher evaluates visual fit)
- Whether tierColors includes sub-tier keys (e.g., `county`, `school`) or just the three main tiers
- Migration script format (standalone SQL vs TypeScript CLI script)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### ev-ui Components
- `ev-ui/src/PoliticianCard.jsx` — Card component getting imageFocalPoint prop and cropping fix
- `ev-ui/src/PoliticianProfile.jsx` — Profile component getting same cropping fix; has existing getTierColors function
- `ev-ui/src/CategorySection.jsx` — Getting optional tier prop
- `ev-ui/src/SocialLinks.jsx` — Reference for inline SVG icon pattern
- `ev-ui/src/tokens.js` — Design token source; tierColors added here
- `ev-ui/src/index.jsx` — Package entry point; must export new icons.js

### Essentials Frontend
- `essentials/src/components/ElectionsView.jsx` — Incumbent badge removal (lines ~207-236)

### Data/Seed Scripts
- `ev-accounts/backend/scripts/seed-monroe-county-2026-primary.sql` — Ruben Marte name typo (line 276)

### Requirements
- `.planning/REQUIREMENTS.md` — VIS-03 (icons), DATA-01 (incumbent), DATA-02 (Marte), DATA-03 (headshot crop)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SocialLinks.jsx`: Established inline SVG icon pattern with size/color props — icons.js should mirror this
- `tokens.js`: Full design token system with `colorScales.teal` scale (050-950) already defined — tierColors references these directly
- `PoliticianProfile.jsx`: Has existing `getTierColors(tier)` function that may need alignment with new tierColors token

### Established Patterns
- ev-ui uses inline styles (not Tailwind) — all components use token imports
- `tsup` builds with `splitting: false` — no external runtime dependencies allowed in ev-ui
- Optional props with null-safe fallbacks — standard pattern across ev-ui components

### Integration Points
- `ev-ui/src/index.jsx` must export new icons and tierColors token
- Essentials `ElectionsView.jsx` badge prop removal is a one-line change
- `package.json` version bump to 0.1.55 before publish

</code_context>

<specifics>
## Specific Ideas

- User selected the exact preview showing `objectPosition: 'center 20%'` for headshot cropping
- User selected semantic map preview for tierColors referencing colorScales
- User selected inline SVG component preview for icon exports
- Local tier explicitly uses teal-200 (NOT yellow) — user chose to keep all tiers in the same teal family for subtler differentiation

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 102-ev-ui-foundation-quick-wins*
*Context gathered: 2026-04-03*
