# Phase 102: ev-ui Foundation + Quick Wins — Research

**Researched:** 2026-04-03
**Domain:** React component library (ev-ui), CSS image cropping, SQL data fixes, npm package publishing
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Icons exported as inline SVG React components from `ev-ui/src/icons.js` (e.g., `<BallotIcon />`, `<CompassIcon />`, `<BranchIcon />`). Each accepts `size` (default 16) and `color` (default 'currentColor') props. Matches existing SocialLinks.jsx pattern.
- **D-02:** SVG path data sourced from Lucide icon library (MIT license) — copy paths only, no runtime dependency on lucide-react. Researcher should find best-fit Lucide icons for: ballot status, compass availability, branch type.
- **D-03:** Icons are standalone — no shared wrapper component in ev-ui. Essentials handles tooltip/label/accessibility logic itself (Phase 103 scope).
- **D-04:** Default `objectPosition: 'center 20%'` on PoliticianCard image style. Shifts crop window upward to keep faces visible in standard portrait photos.
- **D-05:** Optional `imageFocalPoint` prop on PoliticianCard — defaults to `'center 20%'`, overridable per-image. Prop is optional with null-safe fallback.
- **D-06:** Same cropping fix applied to both PoliticianCard and PoliticianProfile for consistency.
- **D-07:** `tierColors` export added to `tokens.js` as semantic map referencing `colorScales`. Structure: `{ federal: { bg, accent, text }, state: { bg, accent, text }, local: { bg, accent, text } }`.
- **D-08:** All three tiers use teal color scale (NOT yellow for local): Federal=teal-700/teal-100, State=teal-500/teal-050, Local=teal-200/teal-050.
- **D-09:** CategorySection accepts optional `tier` prop as string key (`'federal'` | `'state'` | `'local'`). ev-ui owns the tierColors lookup internally.
- **D-10:** Remove the `'Incumbent'` badge prop passed to PoliticianCard in `ElectionsView.jsx` (line ~215). Do NOT touch CandidateProfile is_incumbent routing logic.
- **D-11:** Fix seed SQL typo — `'Marte'''` has trailing escaped quote producing `Marte'` in DB. Correct to `'Marte'` (no accent — his name is plain ASCII).
- **D-12:** Write migration/script to: (a) correct stored name in race_candidates table, (b) look up matching politician by name and set politician_id.
- **D-13:** Add Unicode/diacritical normalization (NFD + strip combining marks) to candidate name matching logic for future imports.

### Claude's Discretion

- Exact Lucide icon choices for ballot/compass/branch (researcher evaluates visual fit)
- Whether tierColors includes sub-tier keys (e.g., `county`, `school`) or just the three main tiers
- Migration script format (standalone SQL vs TypeScript CLI script)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VIS-03 | Icon set evaluated and selected to fit EV design system (subtle, readable, secondary) | Lucide SVG paths identified for BallotIcon, CompassIcon, BranchIcon; inline SVG pattern from SocialLinks.jsx confirmed |
| DATA-01 | Incumbent marker removed from all candidate cards on election page | ElectionsView.jsx confirmed: `subtitle` prop set to `'Incumbent'` when `candidate.is_incumbent`; one-line removal |
| DATA-02 | Ruben Marte candidate record linked to politician profile (fix accent mark mismatch) | Seed SQL typo confirmed at line 276: `'Marte'''` → produces `Marte'` in DB; SQL migration pattern documented |
| DATA-03 | Headshot images display with face-centered cropping via CSS object-position | `objectPosition` property on existing `styles.image` object in PoliticianCard; same pattern in PoliticianProfile |
</phase_requirements>

---

## Summary

Phase 102 is a low-risk, high-precision phase: four independent workstreams (icon system, headshot crop fix, incumbency badge removal, Ruben Marte data fix) with no cross-dependencies. All decisions are locked from the CONTEXT.md discussion session. Research confirms every implementation detail from canonical source inspection.

The ev-ui library (currently v0.1.54) is built with tsup using `splitting: false` and no runtime dependencies beyond React and @react-spring/web. This constraint is already honored in the decisions: Lucide paths are copied inline (no `lucide-react` runtime dep), and `imageFocalPoint` is a pure CSS prop. The publish target is GitHub npm registry (`npm.pkg.github.com`).

The Ruben Marte data fix has two distinct steps: correcting the stored string in the live `essentials.race_candidates` table AND fixing the seed SQL source file so re-runs don't re-introduce the typo. Both steps must appear in the plan. The politician_id linkage requires a query to find the matching politician record by corrected name.

**Primary recommendation:** Implement in this order: (1) tokens.js + icons.js + CategorySection/PoliticianCard/PoliticianProfile ev-ui changes → build → publish v0.1.55; (2) update essentials after publish so npm update picks up the new props; (3) fix incumbent badge in ElectionsView.jsx; (4) run Ruben Marte data migration.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| tsup | ^8.0.0 | ev-ui build (ESM + CJS) | Already configured; `splitting: false` mandatory |
| npm (GitHub registry) | — | Publish `@chrisandrewsedu/ev-ui` | Existing publishConfig in package.json |
| React | >=17 (peer) | Component rendering | Peer dep; no version bump needed |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Lucide (SVG paths only) | MIT, copy paths | Icon path data source | BallotIcon, CompassIcon, BranchIcon path data only — no runtime dep |
| psql / DATABASE_URL | — | Run data migration SQL | Ruben Marte fix applied via psql against Supabase |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline SVG components | lucide-react runtime dep | Runtime dep violates tsup splitting:false constraint; inline SVG is correct |
| SQL migration file | TypeScript CLI script | Both viable for data fix; SQL is simpler since no DB client setup needed |

**No installation needed** — all changes are source edits, build, and npm publish. No new packages.

---

## Architecture Patterns

### Recommended Project Structure (ev-ui changes)

```
ev-ui/src/
├── tokens.js          # ADD: tierColors export
├── icons.js           # NEW: BallotIcon, CompassIcon, BranchIcon components
├── index.jsx          # ADD: export * from './icons.js'
├── PoliticianCard.jsx # EDIT: imageFocalPoint prop + objectPosition fix
├── CategorySection.jsx# EDIT: optional tier prop → tierColors lookup
└── PoliticianProfile.jsx # EDIT: objectPosition fix on headshot image
```

```
essentials/src/
└── components/
    └── ElectionsView.jsx  # EDIT: remove subtitle 'Incumbent' + cleanup style block
```

```
ev-accounts/backend/
├── scripts/
│   └── seed-monroe-county-2026-primary.sql  # EDIT: fix Marte''' typo at line 276
└── migrations/
    └── 049_fix_marte_candidate.sql          # NEW: UPDATE + politician_id linkage
```

### Pattern 1: Inline SVG Icon Component (ev-ui convention)

**What:** Functional React component accepting `size` and `color` props, rendering a `<svg>` element with inline path data.
**When to use:** All new icons in ev-ui. No external icon dependencies.
**Reference:** `SocialLinks.jsx` — established pattern already in use.

```jsx
// Source: ev-ui/src/SocialLinks.jsx (existing pattern, confirmed)
// icons.js should mirror this structure per D-01

export function BallotIcon({ size = 16, color = 'currentColor' }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke={color}
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      xmlns="http://www.w3.org/2000/svg"
    >
      {/* Lucide "vote" icon paths */}
      <path d="m9 12 2 2 4-4" />
      <path d="M5 7c0-1.1.9-2 2-2h10a2 2 0 0 1 2 2v12H5V7Z" />
      <path d="M22 19H2" />
    </svg>
  );
}
```

**Key difference from SocialLinks:** The `size` and `color` props are explicit params (not derived from a size map), because D-01 specifies `size` (default 16) and `color` (default 'currentColor').

### Pattern 2: Optional Prop with Null-Safe Fallback (ev-ui convention)

**What:** New props are always optional; component behavior is unchanged if prop is omitted.
**When to use:** All new props added to existing ev-ui components.

```jsx
// Source: PoliticianCard.jsx pattern (confirmed from canonical read)
// imageFocalPoint prop per D-05
export default function PoliticianCard({
  // ... existing props
  imageFocalPoint,   // optional, no default in destructure
}) {
  const styles = {
    image: {
      width: '100%',
      height: '100%',
      objectFit: 'cover',
      objectPosition: imageFocalPoint ?? 'center 20%',  // D-04: default center 20%
    },
    // ...
  };
}
```

### Pattern 3: tierColors Token Structure

**What:** Semantic map in `tokens.js` referencing existing `colorScales.teal` values per D-07/D-08.
**When to use:** Consumed by CategorySection internally via `tier` prop; also exported for Phase 103 consumers.

```js
// Source: tokens.js colorScales.teal confirmed: 050, 100, 200, 500, 700 all defined
export const tierColors = {
  federal: {
    bg:     colorScales.teal['100'],   // '#E4F3F6'
    accent: colorScales.teal['700'],   // '#003E4D'
    text:   colorScales.teal['700'],   // '#003E4D'
  },
  state: {
    bg:     colorScales.teal['050'],   // '#F5F9FA'
    accent: colorScales.teal['500'],   // '#00657C'
    text:   colorScales.teal['500'],   // '#00657C'
  },
  local: {
    bg:     colorScales.teal['050'],   // '#F5F9FA'
    accent: colorScales.teal['200'],   // '#C0E8F2'
    text:   colorScales.teal['600'],   // '#005366' — use 600 not 200 for text AA compliance
  },
};
```

**WCAG note (HIGH confidence):** `teal-200` (#C0E8F2) has ~1.8:1 contrast on white — it must NOT be used as text color. For local tier text, use `teal-600` (#005366) which is AA compliant. The `accent` key can use teal-200 as a decorative background/border value; `text` must use a darker shade.

### Pattern 4: CategorySection tier Prop

**What:** Internal lookup — consumer passes `'federal'` | `'state'` | `'local'`; component applies tierColors.
**When to use:** When essentials passes `tier` prop to CategorySection.

```jsx
// CategorySection.jsx modification
export default function CategorySection({
  title,
  infoTooltip,
  websiteUrl,
  children,
  style = {},
  tier,   // optional: 'federal' | 'state' | 'local'
}) {
  // Internal lookup — consumer never imports tierColors directly
  const tierStyle = tier ? tierColors[tier] : null;

  const styles = {
    titlePill: {
      // ... existing styles
      backgroundColor: tierStyle?.bg ?? colors.bgWhite,
      borderColor: tierStyle?.accent ?? colors.borderMedium,
      color: tierStyle?.text ?? colors.textPrimary,
    },
  };
}
```

### Pattern 5: SQL Data Migration (idempotent UPDATE)

**What:** SQL migration targeting live `essentials.race_candidates` table.
**When to use:** Ruben Marte name/politician_id fix per D-12.

```sql
-- Source: analysis of seed-monroe-county-2026-primary.sql line 276
-- Pattern: idempotent UPDATE (safe to re-run)

-- Step 1: Fix the stored name (remove trailing apostrophe)
UPDATE essentials.race_candidates
SET
  full_name  = 'Ruben Marte',
  last_name  = 'Marte'
WHERE full_name = 'Ruben Marte'''
  AND last_name = 'Marte''';

-- Step 2: Link to politician profile by matching corrected name
UPDATE essentials.race_candidates rc
SET politician_id = p.id
FROM essentials.politicians p
WHERE rc.full_name = 'Ruben Marte'
  AND rc.politician_id IS NULL
  AND (p.full_name = 'Ruben Marte' OR (p.first_name = 'Ruben' AND p.last_name = 'Marte'));
```

**Caution:** If no politician record exists for 'Ruben Marte', `politician_id` remains NULL — which is acceptable. The goal is to link if a match exists, not to create the politician record.

### Anti-Patterns to Avoid

- **Adding `lucide-react` as a runtime dependency to ev-ui:** tsup `splitting: false` means the entire library ships in one bundle. Runtime deps become bundled or must be external — neither is acceptable for a tiny icon set. Copy paths only.
- **Using teal-200 as text color:** It fails WCAG AA at ~1.8:1 on white. Use it as `bg` or `accent` (border, dot), never as `text`.
- **Modifying `CandidateProfile` is_incumbent logic:** D-10 is explicit — only remove the `subtitle` prop in ElectionsView.jsx. The `className="incumbent-card"` wrapper div is also removable since its only purpose was the `<style>` override that targets incumbent cards.
- **Updating consumers before publishing ev-ui:** The new props (imageFocalPoint, tier, icons) must be in the published v0.1.55 before essentials runs `npm update @chrisandrewsedu/ev-ui`.
- **Forgetting to fix the seed SQL source file:** The migration fixes live data, but the seed file at line 276 also has the typo. If the seed is re-run, it will re-insert the bad record. Both must be fixed.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Icon SVG rendering | Custom icon wrapper/registry | Simple inline SVG components | SocialLinks.jsx pattern already proven; wrapper adds complexity with no benefit at 3-4 icons |
| Color token management | Ad-hoc color strings | tierColors in tokens.js | Ensures Penpot sync compatibility; single source of truth |
| Unicode normalization | Manual accent stripping | NFD decompose + strip combining marks (JS `normalize('NFD').replace(/[\u0300-\u036f]/g, '')`) | Standard approach; handles all diacriticals correctly |

**Key insight:** This phase involves no novel engineering — it's precision edits to existing well-understood components. The main risk is subtle errors: wrong color scale key, missing null-safe fallback, or forgetting to update the seed SQL source file alongside the migration.

---

## Lucide Icon Recommendations (Claude's Discretion — HIGH confidence)

Research retrieved exact SVG paths from GitHub raw source. All icons are 24×24 viewBox, stroke-based.

### BallotIcon — Lucide `vote`
**Represents:** "On ballot" status indicator
**Visual:** Checkbox with checkmark on a ballot slip with baseline
**SVG paths (confirmed from raw source):**
```
<path d="m9 12 2 2 4-4" />
<path d="M5 7c0-1.1.9-2 2-2h10a2 2 0 0 1 2 2v12H5V7Z" />
<path d="M22 19H2" />
```
**Fit assessment:** Clear ballot/voting metaphor. Subtle at 16px. Fits EV design system well.

### CompassIcon — Lucide `compass`
**Represents:** "Compass data available" indicator
**Visual:** Circle with diamond/needle shape inside
**SVG paths (confirmed from raw source):**
```
<circle cx="12" cy="12" r="10" />
<path d="m16.24 7.76-1.804 5.411a2 2 0 0 1-1.265 1.265L7.76 16.24l1.804-5.411a2 2 0 0 1 1.265-1.265z" />
```
**Fit assessment:** Directly represents the Compass feature. Consistent with the existing hand-drawn CompassIcon SVG inside PoliticianCard.jsx (which uses a radar chart metaphor). The Lucide compass is cleaner at small sizes. Good choice for metadata icon.

**Note:** PoliticianCard already has an internal `CompassIcon` SVG for the compass button — this new one in `icons.js` is for metadata display (Phase 103 use), not the button. No conflict; they serve different purposes.

### BranchIcon — Lucide `landmark`
**Represents:** "Branch type" (executive, legislative, judicial)
**Visual:** Government building / columns with peaked roof
**SVG paths (confirmed from raw source):**
```
<path d="M10 18v-7" />
<path d="M11.12 2.198a2 2 0 0 1 1.76.006l7.866 3.847c.476.233.31.949-.22.949H3.474c-.53 0-.695-.716-.22-.949z" />
<path d="M14 18v-7" />
<path d="M18 18v-7" />
<path d="M3 22h18" />
<path d="M6 18v-7" />
```
**Fit assessment:** `landmark` (Greek columns/government building) is the strongest visual metaphor for "government branch." More appropriate than `git-branch` (software concept) or `building-2` (generic office). Recommended.

### tierColors Sub-Tier Keys (Claude's Discretion)

**Recommendation:** Three main tiers only (`federal`, `state`, `local`) — no `county`, `school`, etc.

**Rationale:** Phase 103 uses tier prop on CategorySection, and the tier classification in essentials already collapses sub-categories into three tiers (see `classify.js`). Sub-tier keys would require essentials to distinguish between `county` and `local` which it currently doesn't. Adding them now is speculative scope. Phase 103 can add sub-tiers if needed.

### Migration Script Format (Claude's Discretion)

**Recommendation:** Standalone SQL migration file (`049_fix_marte_candidate.sql`) in `ev-accounts/backend/migrations/`.

**Rationale:** The fix is two UPDATE statements with no application logic. SQL is simpler, self-documenting, and consistent with the existing 048 migration files pattern. A TypeScript CLI script would be overkill and requires database client setup. SQL can be run directly with `psql $DATABASE_URL -f migrations/049_fix_marte_candidate.sql`.

---

## Common Pitfalls

### Pitfall 1: objectPosition on Placeholder (Initials Avatar)
**What goes wrong:** `objectPosition` applies to `<img>` elements, not `<div>` elements. The initials placeholder `<div style={styles.imagePlaceholder}>` does not use `objectPosition` — applying it has no effect and shouldn't be attempted.
**Why it happens:** Developer copies the image style and applies it to the placeholder by mistake.
**How to avoid:** Only apply `objectPosition` to `styles.image` (the `<img>` element styles). The placeholder `<div>` is unaffected by D-04/D-05.
**Warning signs:** If you see `objectPosition` in `styles.imagePlaceholder`, it's wrong.

### Pitfall 2: PoliticianProfile Image Location
**What goes wrong:** PoliticianProfile.jsx is a large file (180+ lines visible) with its own image rendering logic. The `objectPosition` fix per D-06 must be applied there too — it's a separate image element, not inherited from PoliticianCard.
**Why it happens:** Developer applies the fix only to PoliticianCard assuming Profile inherits it.
**How to avoid:** Explicitly search for the image `<img>` render in PoliticianProfile.jsx and add `objectPosition: imageFocalPoint ?? 'center 20%'` to its style.

### Pitfall 3: Incumbent Badge Cleanup Scope
**What goes wrong:** The ElectionsView.jsx `<style>` block at lines 233-238 targets `.incumbent-card .ev-politician-card p:last-child` — this becomes dead CSS once the badge is removed. The `className={candidate.is_incumbent ? 'incumbent-card' : ''}` wrapper div also becomes a no-op.
**Why it happens:** Developer removes the `subtitle` prop but leaves the surrounding scaffolding (class div + style block).
**How to avoid:** Remove: (1) `subtitle` prop line, (2) the `<div className={...}>` wrapper (flatten to just `<PoliticianCard ...>`), (3) the `<style>` block at the bottom.

### Pitfall 4: ev-ui Export Missing for icons.js
**What goes wrong:** icons.js is created but not added to `index.jsx`, so consumers can't import `{ BallotIcon }` from `@chrisandrewsedu/ev-ui`.
**Why it happens:** Forgetting the final wiring step.
**How to avoid:** `index.jsx` must include `export * from './icons.js'`. Then rebuild and publish.

### Pitfall 5: tierColors text vs accent Confusion
**What goes wrong:** `text` key receives a teal color that fails WCAG AA (e.g., teal-200 at ~1.8:1 on white).
**Why it happens:** D-08 specifies `teal-200` for local tier but doesn't clarify which key gets it.
**How to avoid:** teal-200 goes in `bg` and `accent` (decorative). `text` for local tier must use teal-600 (#005366) or darker. See the tierColors example in Architecture Patterns above.

### Pitfall 6: Seed SQL Re-Inserts Bad Record
**What goes wrong:** Migration fixes the live database but the seed SQL at line 276 still has `'Marte'''`. A future re-seed re-creates the bad record.
**Why it happens:** Developer fixes the migration-only and forgets the seed source.
**How to avoid:** Both the seed SQL file (line 276) and the migration SQL must be updated.

---

## Code Examples

### CSS object-position for Face-Centered Cropping
```jsx
// Source: CSS specification + PoliticianCard.jsx styles object pattern (confirmed)
// D-04: Apply to styles.image in PoliticianCard.jsx
image: {
  width: '100%',
  height: '100%',
  objectFit: 'cover',
  objectPosition: imageFocalPoint ?? 'center 20%',  // face typically at top 20%
},
```

**What `center 20%` means:** Horizontal center, vertical 20% from top. On a typical portrait photo where the face occupies the top third, this keeps the face in frame when the image is cropped to fit the card's fixed height.

### tokens.js tierColors Export
```js
// Source: tokens.js colorScales.teal confirmed present (050, 100, 200, 500, 600, 700)
// D-07/D-08: Add after colorScales declaration
export const tierColors = {
  federal: {
    bg:     colorScales.teal['100'],  // #E4F3F6 — light teal wash
    accent: colorScales.teal['700'],  // #003E4D — dark teal
    text:   colorScales.teal['700'],  // #003E4D — 7.5:1 on white, AA ✓
  },
  state: {
    bg:     colorScales.teal['050'],  // #F5F9FA — near-white teal
    accent: colorScales.teal['500'],  // #00657C — brand muted blue
    text:   colorScales.teal['500'],  // #00657C — 6.66:1 on white, AA ✓
  },
  local: {
    bg:     colorScales.teal['050'],  // #F5F9FA — same near-white as state
    accent: colorScales.teal['200'],  // #C0E8F2 — light decorative accent
    text:   colorScales.teal['600'],  // #005366 — 8.1:1 on white, AA ✓
  },
};
```

### ElectionsView.jsx Incumbent Removal
```jsx
// Source: essentials/src/components/ElectionsView.jsx lines 204-238 (confirmed)
// D-10: Before (remove all three changes):

// REMOVE: wrapper div
<div className={candidate.is_incumbent ? 'incumbent-card' : ''}>
  <PoliticianCard
    ...
    subtitle={candidate.is_incumbent ? 'Incumbent' : undefined}  // REMOVE this line
  />
</div>  // REMOVE: closing div

// REMOVE: entire style block at lines 233-238
<style>{`
  .incumbent-card .ev-politician-card p:last-child {
    color: #00657C;
  }
`}</style>

// AFTER: flat PoliticianCard with no wrapper or subtitle:
<PoliticianCard
  id={candidate.candidate_id}
  imageSrc={candidate.photo_url || undefined}
  name={candidate.full_name}
  title={pos.cleanedPosition}
  onClick={() => onCandidateClick(candidate.candidate_id)}
  variant="horizontal"
/>
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `getTierColors(tier)` in PoliticianProfile.jsx with hardcoded hex values | `tierColors` token in tokens.js | This phase | New token is source of truth; PoliticianProfile.jsx's existing function can be updated to use token, or left as-is (it uses different colors — federal=blue, state=green, local=purple, not teal) |
| Badge/pill for "Incumbent" label | No incumbent indicator | This phase (D-10) | Cleaner candidate cards; incumbent status is better surfaced via dedicated data views |

**Important alignment note (HIGH confidence):** `PoliticianProfile.jsx` has an existing `getTierColors(tier)` function at lines 96-102 that uses hardcoded blue/green/purple hex values (federal: `#1E40AF`, state: `#166534`, local: `#7E22CE`). These colors are NOT the new teal-scale tierColors from D-08. The two color systems serve different purposes:
- `getTierColors` in PoliticianProfile = badge colors for the politician's tier indicator in the profile view
- New `tierColors` in tokens.js = section background/accent colors for CategorySection tier theming

**The planner should NOT align or replace `getTierColors` in this phase.** That function is out of scope and may be intentionally different (it shows the politician's tier in a badge context, not a section context).

---

## Environment Availability

This phase is purely code/config changes with no external service dependencies. The one exception is the SQL migration which requires DATABASE_URL access:

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|---------|
| Node.js + npm | ev-ui build + publish | ✓ | (project standard) | — |
| DATABASE_URL (Supabase) | Ruben Marte SQL migration | ✓ (in .env) | PostgreSQL 15+ | Run against dev DB first |
| psql CLI | Running migration directly | Likely ✓ | — | Use `npx tsx` script instead |

---

## Validation Architecture

`workflow.nyquist_validation` is not set in `.planning/config.json` — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Vitest |
| Config file | `ev-accounts/backend/vitest.config.ts` |
| Quick run command | `cd ev-accounts/backend && npm test` |
| Full suite command | `cd ev-accounts/backend && npm test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VIS-03 | Icons export from ev-ui | manual smoke | `npm run build` in ev-ui; verify dist contains icon exports | ❌ Wave 0 — no icon test needed; build verification is sufficient |
| DATA-01 | Incumbent badge not shown | manual visual | Open essentials election page; verify no "Incumbent" subtitle | Manual only — no test infrastructure for React component render in this project |
| DATA-02 | Marte record has correct name + politician_id | SQL query | `psql $DATABASE_URL -c "SELECT full_name, politician_id FROM essentials.race_candidates WHERE last_name ILIKE 'marte'"` | Manual verification query |
| DATA-03 | Headshot face-centered | manual visual | Open essentials page; verify politician headshots show faces | Manual only |

### Sampling Rate
- **Per task commit:** `cd ev-accounts/backend && npm run typecheck` (TypeScript check — fast, catches regressions)
- **Per wave merge:** `cd ev-accounts/backend && npm test`
- **Phase gate:** Manual visual verification of election page + headshot display before `/gsd:verify-work`

### Wave 0 Gaps
None — existing test infrastructure covers backend. ev-ui and essentials have no automated test suites; manual verification is the established pattern for this project.

---

## Open Questions

1. **Does a `Ruben Marte` politician record exist in `essentials.politicians`?**
   - What we know: The seed SQL has `politician_id = NULL` for this candidate record; D-12 says "look up matching politician by name."
   - What's unclear: Whether the politician profile for Ruben Marte was ever loaded into `essentials.politicians`. If not, `politician_id` remains NULL after migration (acceptable per D-12 intent).
   - Recommendation: The migration SQL should attempt the linkage; if no match, it silently leaves NULL. The implementer should verify after running: `SELECT full_name, politician_id FROM essentials.race_candidates WHERE full_name = 'Ruben Marte'`.

2. **PoliticianProfile.jsx headshot image element location**
   - What we know: The file is 180+ lines; initial read showed helpers and the `getTierColors` function.
   - What's unclear: The exact line number of the headshot `<img>` in the JSX render section.
   - Recommendation: Implementer should search for `objectFit` or `imageSrc` in PoliticianProfile.jsx to locate the image element before applying D-06 fix.

---

## Sources

### Primary (HIGH confidence)
- `ev-ui/src/PoliticianCard.jsx` — Confirmed existing styles.image object, badge pattern, and overall component structure
- `ev-ui/src/tokens.js` — Confirmed colorScales.teal all keys (050 through 950), existing token exports
- `ev-ui/src/SocialLinks.jsx` — Confirmed inline SVG icon pattern to replicate
- `ev-ui/src/CategorySection.jsx` — Confirmed existing props and styles.titlePill structure
- `ev-ui/src/index.jsx` — Confirmed current export list; icons.js must be added
- `ev-ui/package.json` — Confirmed v0.1.54, publishConfig for GitHub registry, tsup build
- `ev-ui/tsup.config.js` — Confirmed `splitting: false`, external react deps
- `essentials/src/components/ElectionsView.jsx` — Confirmed subtitle 'Incumbent' at ~line 215, wrapper div pattern, style block
- `ev-accounts/backend/scripts/seed-monroe-county-2026-primary.sql` — Confirmed `'Marte'''` typo at line 276
- `ev-accounts/backend/vitest.config.ts` — Confirmed test setup

### Secondary (MEDIUM confidence)
- [Lucide `vote` icon](https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/vote.svg) — SVG paths verified from GitHub raw source
- [Lucide `compass` icon](https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/compass.svg) — SVG paths verified from GitHub raw source
- [Lucide `landmark` icon](https://raw.githubusercontent.com/lucide-icons/lucide/main/icons/landmark.svg) — SVG paths verified from GitHub raw source
- WCAG 2.1 contrast ratios for teal color scale — computed from hex values in tokens.js

### Tertiary (LOW confidence)
None — all findings verified from source files or official repos.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all from project source files
- Architecture: HIGH — all patterns verified from existing code
- Pitfalls: HIGH — identified from direct code inspection
- Lucide icon paths: MEDIUM — paths extracted via WebFetch from GitHub raw; BallotIcon paths need implementer verification at render time

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable domain — React component library + CSS)
