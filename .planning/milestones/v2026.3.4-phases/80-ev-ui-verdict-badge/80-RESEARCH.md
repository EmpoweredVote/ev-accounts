# Phase 80: ev-ui Verdict Badge - Research

**Researched:** 2026-03-12
**Domain:** React component library (ev-ui) — adding a new prop to StanceAccordion and publishing to GitHub npm registry
**Confidence:** HIGH

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PROF-03 | ev-ui updated to v0.1.42+ with verdict badge prop on StanceAccordion | Full research below: migration path, prop shape, badge visuals, publish workflow |
</phase_requirements>

---

## Summary

Phase 80 is a component library update: move `StanceAccordion` from the `essentials` app into the `ev-ui` package, add a `verdictsByTopic` prop that renders inline agree/disagree badges per topic row, then publish `v0.1.42` to the GitHub npm registry. The existing essentials caller is then updated to import `StanceAccordion` from `@chrisandrewsedu/ev-ui` instead of `./StanceAccordion`.

The component already exists in `essentials/src/components/StanceAccordion.jsx` with all its logic intact. The primary work is (1) copying and adapting the component into ev-ui, resolving its internal `Favicon` dependency, (2) adding the verdict badge rendering inline in the topic row header, and (3) running the established manual publish workflow. No new libraries are required.

The badge visual language is already fully established by Phase 78: `agreed` = cyan-50 background / cyan-700 text / checkmark icon; `disagreed` = amber-50 background / amber-700 text / X icon. These are inline pill badges mirroring exactly what `ResultsPhase.tsx` renders in EV-ReadRank.

**Primary recommendation:** Copy StanceAccordion verbatim into ev-ui, inline the Favicon dependency (it has no external deps), add `verdictsByTopic` as an optional prop, render badges in the collapsed row header alongside the stance label, then publish v0.1.42 and bump essentials to consume it.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| tsup | ^8.0.0 | Bundle ESM + CJS from JSX source | Already configured in ev-ui |
| npm publish | CLI | Publish to GitHub npm registry | Established pattern — no CI workflow, manual publish |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @chrisandrewsedu/ev-ui | 0.1.41 → 0.1.42 | Target package being updated | N/A |
| React peer dep | >=17 | Package peer dep | Already declared |

### No Additional Dependencies Required
StanceAccordion only uses React hooks (`useState`, `useRef`, `useCallback`) and `fetch` — all already available. The `Favicon` sub-component is a pure React component with no dependencies.

**Build command:**
```bash
cd ev-ui && npm run build
```

**Publish command (manual — no CI workflow exists):**
```bash
cd ev-ui && npm publish
```
The global `~/.npmrc` has the GitHub token; no per-project `.npmrc` is needed for local publish.

---

## Architecture Patterns

### Recommended File Structure Addition
```
ev-ui/src/
├── StanceAccordion.jsx   # NEW — migrated from essentials + verdict badge
├── Favicon.jsx           # NEW — inlined dependency, copied from essentials
├── index.js              # UPDATED — add StanceAccordion export
└── ... (existing files unchanged)
```

### Pattern 1: StanceAccordion Migration with Favicon Inline

**What:** Copy `essentials/src/components/StanceAccordion.jsx` and `essentials/src/components/Favicon.jsx` into `ev-ui/src/`. Remove the `VITE_API_URL` env var reference — replace with a required or optional `apiUrl` prop passed by the caller.

**When to use:** Anytime a component with internal deps moves to the library — inline small pure deps, expose env config as props.

**Key adaptation:**
```jsx
// Before (essentials-local):
const API = import.meta.env.VITE_API_URL || '/api';
// ...and...
import Favicon from './Favicon';

// After (ev-ui):
// Favicon.jsx is copied into ev-ui/src/ and imported locally
// apiUrl is passed as a prop with a sensible default
export default function StanceAccordion({ topics, polAnswers, politicianId, allTopics, expandedTopics, verdictsByTopic, apiUrl = '/api' }) {
```

The essentials caller already passes `politicianId` to the component for context fetch; it will simply add `apiUrl={import.meta.env.VITE_API_URL}` and `verdictsByTopic={verdicts}`.

### Pattern 2: verdictsByTopic Prop Shape

**What:** An optional object mapping topic IDs (string) to verdict strings.

**Prop type:**
```jsx
// verdictsByTopic: Record<string, 'agreed' | 'disagreed'> | undefined
// When undefined or empty object, renders identically to current behavior
```

**Verdict values come from backend model:**
```go
Verdict string `json:"verdict"` // "agreed" | "disagreed"
```

Phase 81 will populate this prop from CompassContext. Phase 80 only needs to accept and render it — the data wiring is Phase 81's responsibility.

### Pattern 3: Badge Rendering in Topic Row

**What:** An inline pill badge rendered alongside the stance label in the collapsed row header. Placement: after the `<span>` for the stance label, before the chevron — or inline after the stance label on the same line.

**Visual spec (established in Phase 78 — HIGH confidence):**
```jsx
// agreed badge — cyan-50/cyan-700
<span className="inline-flex items-center gap-1 bg-cyan-50 text-cyan-700 px-2 py-0.5 rounded-full text-xs font-medium ml-2">
  <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
  </svg>
  Agreed
</span>

// disagreed badge — amber-50/amber-700
<span className="inline-flex items-center gap-1 bg-amber-50 text-amber-700 px-2 py-0.5 rounded-full text-xs font-medium ml-2">
  <svg className="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
  </svg>
  Disagreed
</span>
```

Note: ev-ui components use inline styles rather than Tailwind utility classes (see `CategorySection.jsx`). However, `StanceAccordion` in essentials already uses Tailwind classes extensively (it was written for the essentials app which has Tailwind 4). For ev-ui, either approach is acceptable — maintain Tailwind classes since they are already in the existing implementation, or convert to inline styles for consistency with other ev-ui components. **Recommended: keep Tailwind classes** — they are already in the component body and ev-ui consumers (essentials) have Tailwind available.

### Pattern 4: Backward Compatibility Guard

**What:** `verdictsByTopic` is optional and defaults to `undefined`. Zero-cost guard in render:

```jsx
const verdict = verdictsByTopic ? verdictsByTopic[topicId] : undefined;
// Only render badge when verdict is 'agreed' or 'disagreed'
```

This satisfies success criterion 3: callers that pass no `verdictsByTopic` prop render identically to before.

### Pattern 5: ev-ui Version Bump + Publish Workflow

**What:** Update `package.json` version, build, publish. There is no GitHub Actions workflow — publish is manual from local with the global `~/.npmrc` token.

```bash
# 1. Bump version in ev-ui/package.json: "0.1.41" → "0.1.42"
# 2. Build
cd ev-ui && npm run build
# 3. Publish to GitHub npm registry
npm publish
# 4. In essentials: bump package.json "@chrisandrewsedu/ev-ui": "^0.1.42"
# 5. npm install in essentials
# 6. Update essentials import: StanceAccordion from '@chrisandrewsedu/ev-ui'
# 7. Remove essentials/src/components/StanceAccordion.jsx and Favicon.jsx
```

### Anti-Patterns to Avoid
- **Do not leave `VITE_API_URL` in the ev-ui component:** Build-time env vars are bundled at the caller app, not the library. The library must receive `apiUrl` as a prop or use a runtime default.
- **Do not add Tailwind as a devDependency to ev-ui:** tsup bundles the JSX and leaves Tailwind class strings as-is. The consumer app provides the Tailwind runtime. ev-ui does not need Tailwind installed.
- **Do not publish with `dts: false` changed:** ev-ui intentionally ships no `.d.ts` files. The STATE.md notes that EV-ReadRank uses a manual `ev-ui.d.ts` shim — essentials does not use TypeScript, so no type shim is needed.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Badge visual design | Custom badge component from scratch | Copy inline JSX from ResultsPhase.tsx in EV-ReadRank | Already established and visually correct |
| Favicon display | New favicon service | Copy Favicon.jsx from essentials | Identical need, proven implementation |
| npm auth for publish | Custom auth config | Global `~/.npmrc` with token | Already in place, works for all scopes |

---

## Common Pitfalls

### Pitfall 1: VITE_API_URL Bundled at Library Build Time
**What goes wrong:** If `import.meta.env.VITE_API_URL` remains in StanceAccordion when tsup bundles it, it will be `undefined` (Vite env vars are not available during tsup builds — tsup uses esbuild, not Vite).
**Why it happens:** The component was written for a Vite app; tsup does not process Vite env substitutions.
**How to avoid:** Replace `const API = import.meta.env.VITE_API_URL || '/api'` with an `apiUrl` prop defaulting to `'https://api.empowered.vote'` (or pass it from the essentials caller).
**Warning signs:** Context fetch returns 404 or NetworkError in production after library update.

### Pitfall 2: Tailwind Classes Not Purged in ev-ui Build
**What goes wrong:** If someone tries to run a Tailwind purge/build inside ev-ui, classes will be stripped because the CSS pipeline is not set up.
**Why it happens:** ev-ui has no Tailwind config — it is purely a component bundle.
**How to avoid:** Do nothing — tsup emits class strings as-is. The consumer app (essentials with Tailwind 4) renders them correctly.
**Warning signs:** N/A — this is a non-issue for the current approach.

### Pitfall 3: Favicon.jsx Import Path After Migration
**What goes wrong:** StanceAccordion imports `'./Favicon'` — this works in essentials but must still resolve correctly inside ev-ui.
**Why it happens:** Relative import — as long as Favicon.jsx is in ev-ui/src/ alongside StanceAccordion.jsx, the path is identical.
**How to avoid:** Copy both files to ev-ui/src/ before running build.

### Pitfall 4: essentials Imports StanceAccordion From Two Places
**What goes wrong:** If the local StanceAccordion.jsx is not deleted after migrating to ev-ui, the import in CompassCard.jsx still points to the local copy — the new ev-ui prop has no effect.
**Why it happens:** Import path not updated.
**How to avoid:** After updating essentials to use the ev-ui version, delete `essentials/src/components/StanceAccordion.jsx` and `Favicon.jsx`, and verify the only import is `import { StanceAccordion } from '@chrisandrewsedu/ev-ui'`.

### Pitfall 5: npm publish Version Already Exists
**What goes wrong:** `npm publish` fails with "cannot publish over existing version."
**Why it happens:** Version not bumped before publish.
**How to avoid:** Always increment version in package.json before building and publishing. Target is `0.1.42`.

---

## Code Examples

### Full verdictsByTopic Prop Integration in Topic Row
```jsx
// Source: pattern derived from essentials/src/components/StanceAccordion.jsx + EV-ReadRank ResultsPhase.tsx

// In the collapsed row button, after stance label span:
{verdict === 'agreed' && (
  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px',
    backgroundColor: '#ecfeff', color: '#0e7490',
    padding: '2px 8px', borderRadius: '9999px',
    fontSize: '11px', fontWeight: 500, marginLeft: '6px', flexShrink: 0 }}>
    {/* checkmark icon */}
    Agreed
  </span>
)}
{verdict === 'disagreed' && (
  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px',
    backgroundColor: '#fffbeb', color: '#b45309',
    padding: '2px 8px', borderRadius: '9999px',
    fontSize: '11px', fontWeight: 500, marginLeft: '6px', flexShrink: 0 }}>
    {/* X icon */}
    Disagreed
  </span>
)}
```

Note: Inline styles are preferred for ev-ui to avoid Tailwind dependency. The color values map to cyan-700 (#0e7490) and amber-700 (#b45309) matching the established Phase 78 palette.

### essentials CompassCard Update (after ev-ui publish)
```jsx
// Before:
import StanceAccordion from './StanceAccordion';

// After:
import { StanceAccordion } from '@chrisandrewsedu/ev-ui';

// Usage — new prop added, existing props unchanged:
<StanceAccordion
  topics={...}
  polAnswers={polAnswers}
  politicianId={politicianId}
  allTopics={allTopics}
  expandedTopics={...}
  apiUrl={import.meta.env.VITE_API_URL}
  verdictsByTopic={verdicts}  // Phase 81 wires this; Phase 80 just makes it available
/>
```

### ev-ui index.js Export Addition
```js
// Add after existing exports:
export { default as StanceAccordion } from "./StanceAccordion.jsx";
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| StanceAccordion in essentials app only | StanceAccordion in ev-ui shared library | Phase 80 | Enables Phase 81 to wire verdicts from CompassContext cleanly |
| No verdict display on profile | Inline agree/disagree badge per topic | Phase 80+81 | Users see their Read & Rank verdicts on politician profiles |

**The badge visual pair (cyan=agreed, amber=disagreed) was locked in Phase 78** — it is already consistent across EvaluationPhase swipe feedback, QuoteCard borders, and ResultsPhase verdict labels.

---

## Open Questions

1. **Should `apiUrl` have a hardcoded fallback or require the caller to pass it?**
   - What we know: essentials passes `VITE_API_URL`; other potential ev-ui consumers may not know the API URL
   - What's unclear: whether ev-ui should hard-code `https://api.empowered.vote` as the default
   - Recommendation: Default to `'https://api.empowered.vote'` — it is the production URL; callers can override for dev

2. **Badge placement: after stance label inline, or on a separate sub-line?**
   - What we know: Existing layout is `topic.short_title` on line 1, `questionText` on line 2, `label` (stance) on line 3
   - What's unclear: Whether adding the badge after the stance label on line 3 is visually cramped at mobile widths
   - Recommendation: Add badge inline after stance label on line 3 — it's a compact pill, same pattern as ResultsPhase agreed/disagreed pills

3. **Should Favicon.jsx be exported from ev-ui index.js?**
   - What we know: Favicon is only used internally by StanceAccordion
   - Recommendation: Do NOT export it — keep it a private implementation detail within ev-ui

---

## Validation Architecture

`nyquist_validation` key is absent from `.planning/config.json` — treated as enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None — ev-ui has no test infrastructure |
| Config file | None |
| Quick run command | Manual visual verification |
| Full suite command | Manual visual verification |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PROF-03 | ev-ui v0.1.42+ published with verdictsByTopic prop | manual | `npm view @chrisandrewsedu/ev-ui version` | N/A |
| PROF-03 | Badge renders when verdict present | manual | Load essentials Profile page with test verdicts passed | N/A |
| PROF-03 | No prop = identical to previous render | manual | Load essentials Profile page without verdictsByTopic prop | N/A |

### Sampling Rate
- **Per task commit:** Visual inspection of StanceAccordion in browser
- **Per wave merge:** Verify `npm view @chrisandrewsedu/ev-ui` shows 0.1.42
- **Phase gate:** Published package resolves correctly in essentials `npm install` before marking phase complete

### Wave 0 Gaps
None — no automated test infrastructure exists or is expected for this component library. Manual verification is the established pattern for ev-ui releases (consistent with Phases 67-76).

---

## Sources

### Primary (HIGH confidence)
- Direct file reads: `ev-ui/src/StanceAccordion` does not exist yet — confirmed by `ls ev-ui/src/`
- Direct file reads: `essentials/src/components/StanceAccordion.jsx` — current implementation, 265 lines
- Direct file reads: `ev-ui/package.json` — current version 0.1.41, publishConfig, peerDeps
- Direct file reads: `ev-ui/tsup.config.ts` — entry: `src/index.js`, jsx transform configured
- Direct file reads: `EV-Backend/internal/compass/models.go` — verdict values: `"agreed" | "disagreed"`
- Direct file reads: `EV-ReadRank/src/components/ResultsPhase.tsx` — established badge visual pattern
- Direct file reads: `.planning/STATE.md` — architectural decisions for Phase 80
- Direct file reads: `~/.npmrc` (redacted) — GitHub npm registry token in place for publish

### Secondary (MEDIUM confidence)
- STATE.md accumulated context: "ev-ui `verdictsByTopic` prop shape and verdict enum values need agreement before either phase begins" — confirmed by backend model read
- Phase 78 decisions in STATE.md: amber-700/cyan-700 badge pair confirmed as locked design

### Tertiary (LOW confidence)
- None

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — ev-ui codebase fully inspected, publish workflow confirmed
- Architecture: HIGH — migration pattern is identical to Phase 75 CategorySection move; verdict enum confirmed from backend
- Pitfalls: HIGH — VITE_API_URL pitfall verified by inspecting tsup config (esbuild-based, no Vite env processing)

**Research date:** 2026-03-12
**Valid until:** 2026-04-12 (stable domain)
