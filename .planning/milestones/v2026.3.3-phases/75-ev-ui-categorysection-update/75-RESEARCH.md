# Phase 75: ev-ui CategorySection Update - Research

**Researched:** 2026-03-11
**Domain:** React component library (ev-ui), component prop extension, npm publishing
**Confidence:** HIGH

## Summary

Phase 75 adds an optional `websiteUrl` prop to the `CategorySection` component in `ev-ui`, bumps the version from 0.1.40 to 0.1.41, publishes to GitHub npm registry, and updates the `essentials` app to pass `government_body_url` from the API response to each `CategorySection`. This is a narrow, well-scoped change with zero risk to existing callers because the prop is optional and gated with a conditional render.

The backend already delivers `government_body_url` in the politician JSON response (from Phase 73-74 work). The `essentials` Results.jsx groups politicians into categories and renders `CategorySection` per group — but currently discards `government_body_url`. The planner needs to wire that field through the grouping logic and pass it to CategorySection.

The component library uses inline SVG icons (no external icon libraries), inline `style={}` objects via design tokens, and compiles with `tsup` targeting ESM + CJS. Publishing is via `npm publish` against the GitHub Package Registry. All of this is consistent with existing ev-ui patterns — no new dependencies are needed.

**Primary recommendation:** Add `websiteUrl` prop to CategorySection with an inline external-link SVG anchor alongside the existing title pill, bump to 0.1.41, publish, then update essentials to read `government_body_url` from the first politician in each group and pass it as `websiteUrl`.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| LINK-01 | Each government body section displays a link to its official website | ev-ui CategorySection accepts `websiteUrl`; essentials Results.jsx passes `pol.government_body_url` from the first politician in the category group |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| React | >=17 (peer) | Component rendering | ev-ui peer dep, all callers on React 19 |
| tsup | ^8.0.0 | Build ESM + CJS bundles | Already configured, produces `dist/index.{js,mjs}` |
| npm / GitHub Packages | N/A | Package registry | `publishConfig.registry` already set in package.json |

### No New Dependencies Required
This change uses only:
- Inline SVG (consistent with SocialLinks.jsx pattern)
- Standard HTML `<a>` tag
- Existing design tokens from `tokens.js`

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Inline SVG icon | Heroicons / lucide-react | Adds a new dep to ev-ui; unnecessary for a single icon |
| `<a>` inline | `<button onClick>` | Anchor is semantically correct for external navigation |

**Installation:** No new packages required.

## Architecture Patterns

### Recommended Project Structure
No structural changes. Both files are modified in-place:
```
ev-ui/
└── src/
    └── CategorySection.jsx   ← add websiteUrl prop + external-link anchor

essentials/
└── src/
    └── pages/
        └── Results.jsx       ← derive websiteUrl per group, pass to CategorySection
```

### Pattern 1: Optional Prop with Conditional Render (ev-ui style)
**What:** New prop is optional; guard with `{websiteUrl && (...)}` — identical to how `infoTooltip` is handled today.
**When to use:** Any time adding a feature that must not break existing callers.
**Example:**
```jsx
// Source: ev-ui/src/CategorySection.jsx (existing pattern for infoTooltip)
{infoTooltip && (
  <button type="button" ...>
    i
  </button>
)}

// New websiteUrl follows the same pattern:
{websiteUrl && (
  <a
    href={websiteUrl}
    target="_blank"
    rel="noopener noreferrer"
    style={styles.externalLink}
    aria-label={`Visit official website for ${title}`}
  >
    <svg ...>/* external-link icon */</svg>
  </a>
)}
```

### Pattern 2: Inline SVG Icon (ev-ui style)
**What:** All icons in ev-ui are inline SVG with `stroke="currentColor"` and `style={styles.icon}` using token-based sizing.
**When to use:** Every icon in ev-ui — SocialLinks.jsx, PoliticianCard.jsx, PoliticianProfile.jsx all follow this.
**Example (external-link SVG, standard Heroicons outline path):**
```jsx
// Source: standard external-link SVG path (Heroicons outline)
<svg
  viewBox="0 0 24 24"
  fill="none"
  xmlns="http://www.w3.org/2000/svg"
  style={{ width: '14px', height: '14px', color: colors.textMuted }}
>
  <path
    d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
    stroke="currentColor"
    strokeWidth="2"
    strokeLinecap="round"
    strokeLinejoin="round"
  />
</svg>
```

### Pattern 3: Deriving websiteUrl Per Category Group in Results.jsx
**What:** Politicians within a category group share the same government body. Take `government_body_url` from the first politician in the group (all members share the same body, so any one is representative). An empty string from the API (when no URL is seeded) evaluates as falsy — the anchor will not render.
**When to use:** When collapsing per-politician fields to a per-group value.
**Example:**
```jsx
// Source: essentials/src/pages/Results.jsx (pattern mirrors existing group rendering)
{orderedEntries(groups, LOCAL_ORDER).map(([category, polList]) => {
  const websiteUrl = polList[0]?.government_body_url || undefined;
  return (
    <CategorySection
      key={category}
      title={getDisplayName(category)}
      websiteUrl={websiteUrl}
    >
      {defaultSort(category, polList).map((pol) =>
        renderPoliticianCard(pol)
      )}
    </CategorySection>
  );
})}
```
This pattern must be applied to all three tier blocks: Local, State, and Federal.

### Anti-Patterns to Avoid
- **Passing `""` as websiteUrl:** The backend returns `omitempty` so an absent URL becomes `undefined` in JS. But if it arrives as an empty string, pass `websiteUrl || undefined` to prevent a broken anchor rendering an icon with no href.
- **Filtering/transforming government_body_url in classify.js:** This field is display data, not classification data. Keep it out of classify.js.
- **Adding an icon library dependency to ev-ui:** ev-ui has zero runtime dependencies beyond React and @react-spring/web (peer). Keep it that way.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| External link security | Custom window.open with sanitization | Native `<a target="_blank" rel="noopener noreferrer">` | Browser-native, no XSS surface beyond the href itself |
| Icon rendering | Custom icon component system | Inline SVG per ev-ui convention | Consistent with all other icons in the library |

**Key insight:** The entire change is two files and ~15 lines of code. No new infrastructure needed.

## Common Pitfalls

### Pitfall 1: `polList[0]` is undefined for empty groups
**What goes wrong:** If somehow an empty group makes it to the render loop, `polList[0]?.government_body_url` would throw without optional chaining.
**Why it happens:** Rare but possible during search filtering.
**How to avoid:** Always use optional chaining: `polList[0]?.government_body_url || undefined`.
**Warning signs:** React error boundary fires on empty group render.

### Pitfall 2: Publishing without rebuilding dist/
**What goes wrong:** `npm publish` uploads stale dist/ from 0.1.40 — consumers get a package with old code despite version bump.
**Why it happens:** Forgetting `npm run build` before `npm publish`.
**How to avoid:** The publish sequence is always: 1) edit source, 2) bump version in package.json, 3) `npm run build`, 4) `npm publish`.
**Warning signs:** Published package diff shows no changes to dist/index.mjs.

### Pitfall 3: essentials still on `^0.1.40` after publish
**What goes wrong:** `^0.1.40` resolves to 0.1.41 automatically on `npm install`, but the installed version in node_modules may be cached at 0.1.40.
**Why it happens:** npm cache or lockfile pinning.
**How to avoid:** After publishing 0.1.41, run `npm install` in essentials/ to update package-lock.json and pull the new build.
**Warning signs:** `node_modules/@chrisandrewsedu/ev-ui/package.json` still shows `0.1.40`.

### Pitfall 4: `rel="noopener noreferrer"` omission
**What goes wrong:** `target="_blank"` without `rel="noopener noreferrer"` is a security issue (opener access).
**Why it happens:** Forgetting the rel attribute.
**How to avoid:** Always pair `target="_blank"` with `rel="noopener noreferrer"` — check SocialLinks.jsx as the established pattern (line 172).

## Code Examples

Verified patterns from existing ev-ui source:

### Current CategorySection signature (ev-ui 0.1.40)
```jsx
// Source: ev-ui/src/CategorySection.jsx
export default function CategorySection({
  title,
  infoTooltip,
  children,
  style = {},
}) {
```

### Updated CategorySection signature (ev-ui 0.1.41)
```jsx
export default function CategorySection({
  title,
  infoTooltip,
  websiteUrl,       // NEW: optional external link URL
  children,
  style = {},
}) {
```

### SocialLinks.jsx anchor pattern (reference implementation)
```jsx
// Source: ev-ui/src/SocialLinks.jsx lines 168-183
<a
  key={link.label}
  href={link.href}
  target="_blank"
  rel="noopener noreferrer"
  style={styles.link}
  aria-label={link.label}
>
  {link.icon}
</a>
```

### npm publish sequence
```bash
# In ev-ui/
npm run build       # produces dist/index.{js,mjs}
npm publish         # publishes to https://npm.pkg.github.com with @chrisandrewsedu scope

# In essentials/ (after publish)
npm install         # updates lockfile to 0.1.41
```

### Verification that new version was picked up
```bash
cat node_modules/@chrisandrewsedu/ev-ui/package.json | grep '"version"'
# Should show: "version": "0.1.41"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| CategorySection: title + infoTooltip only | Add websiteUrl anchor in header | Phase 75 (now) | Government body sections can link to official sites |
| `government_body_url` unused in frontend | Pass to CategorySection as websiteUrl | Phase 75 (now) | Closes LINK-01 requirement |

**Field already in API:** `government_body_url` is already returned in politician JSON (implemented Phase 73-74). The frontend just hasn't consumed it yet.

## Open Questions

1. **Icon size and color**
   - What we know: Existing icon buttons in CategorySection header are `20x20px`; SocialLinks icons are `16x16px`.
   - What's unclear: The design spec doesn't specify exact size for the external-link icon in the title pill context.
   - Recommendation: Use `14x14px` at `colors.textMuted` (#718096) — subtle, consistent with the pill's `fontSizes.base` (16px) label. Adjust if it looks visually off during implementation.

2. **Icon placement relative to title pill**
   - What we know: The header `flex` row currently has: `[titlePill] [infoButton?]`
   - What's unclear: Should the link icon be inside the title pill, or after it in the flex row?
   - Recommendation: Place after the title pill in the flex row (same position as infoButton) for consistency. If both `infoTooltip` and `websiteUrl` are present, order is: pill → link icon → info button.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None detected — ev-ui has no test suite; essentials has no test suite |
| Config file | none |
| Quick run command | Manual browser verification |
| Full suite command | Manual browser verification |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LINK-01 | External link icon appears when websiteUrl is provided | manual | n/a | ❌ no test suite |
| LINK-01 | No icon rendered when websiteUrl is absent | manual | n/a | ❌ no test suite |
| LINK-01 | Link opens with target=_blank rel=noopener noreferrer | manual | n/a | ❌ no test suite |
| LINK-01 | ev-ui 0.1.41 published to GitHub registry | manual | `npm view @chrisandrewsedu/ev-ui version` | ❌ post-publish check |

### Sampling Rate
- **Per task commit:** Manual browser check of local essentials dev server
- **Phase gate:** Published 0.1.41 visible in registry + essentials renders link icons for Monroe County sections

### Wave 0 Gaps
- None — no test infrastructure exists or is expected for this library. Manual verification is the established pattern.

## Sources

### Primary (HIGH confidence)
- ev-ui/src/CategorySection.jsx — current component implementation, read directly
- ev-ui/src/SocialLinks.jsx — anchor + SVG icon pattern reference, read directly
- ev-ui/package.json — current version (0.1.40), registry config, build scripts
- ev-ui/tsup.config.js — build configuration (ESM + CJS output)
- ev-ui/src/tokens.js — design tokens (colors, spacing, fontSizes)
- EV-Backend/internal/essentials/handlers.go lines 214-215 — confirms `government_body_url` in API response struct
- essentials/src/pages/Results.jsx lines 742-748 — current CategorySection usage pattern
- essentials/src/lib/classify.js — confirm no changes needed to classification logic

### Secondary (MEDIUM confidence)
- .planning/STATE.md — confirmed "Phase 75 (ev-ui) can run in parallel with Phases 73-74 — no backend dependency for the prop addition"
- .planning/REQUIREMENTS.md — LINK-01 definition and traceability to Phase 75

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries and build tooling read directly from source
- Architecture: HIGH — pattern derived from existing ev-ui component conventions (CategorySection.jsx, SocialLinks.jsx)
- Pitfalls: HIGH — derived from direct code inspection of publish workflow and API response handling

**Research date:** 2026-03-11
**Valid until:** 2026-04-10 (stable — no fast-moving dependencies involved)
