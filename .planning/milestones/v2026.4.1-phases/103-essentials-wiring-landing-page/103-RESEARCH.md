# Phase 103: Essentials Wiring + Landing Page - Research

**Researched:** 2026-04-03
**Domain:** React frontend wiring (essentials app), ev-ui component integration, tooltip library, TypeScript audit script
**Confidence:** HIGH

## Summary

Phase 103 wires ev-ui v0.1.55 features into the essentials app: tier hue differentiation on CategorySection, icon metadata overlays on PoliticianCard, election page restructure, landing page coverage cards, and a headshot audit script. All ev-ui building blocks (tierColors token, BallotIcon/CompassIcon/BranchIcon, CategorySection `tier` prop, PoliticianCard `imageFocalPoint` prop) are already shipped in ev-ui v0.1.55 and confirmed in source. The essentials package.json currently references `^0.1.53` — it must be updated to `^0.1.55`.

The largest design work is the icon overlay and tooltip system. The CONTEXT.md decision locks `@floating-ui/react` for tooltips (D-08). This library is NOT yet installed in essentials. It requires a one-line `npm install`. The tooltip pattern is straightforward: `useFloating` + `useHover` + `useFocus` + `useDismiss` + `useRole` + `useInteractions`.

The headshot audit script follows the exact pattern of `audit-is-appointed.ts` already in the `ev-accounts/backend/scripts/` directory: dotenv loading, pg Pool, stdout output. The addition is HTTP fetch and sharp/canvas image dimension checking — or just using `fetch` with a HEAD request for content-length and a manual image dimension check via Node's built-in `https`.

**Primary recommendation:** Wire in this order — (1) update ev-ui dep + `npm install @floating-ui/react`, (2) tier hues on CategorySection (trivial prop pass), (3) icon overlay component in essentials, (4) wire icons to cards in Results.jsx + ElectionsView.jsx, (5) landing page coverage cards, (6) election page restructure, (7) headshot audit script.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Coverage area cards appear ABOVE the address search input, with a divider ("or search by address") separating them. Coverage cards are the first interactive element on the page.
- **D-02:** Two teal-outlined cards with hover shadow — one for "Monroe County, Indiana" and one for "Los Angeles County, California". County name on first line, state on second line.
- **D-03:** Simple factual coverage statement: "We currently cover:" — no "more areas coming soon" or expansion promises.
- **D-04:** Each card navigates to `/results?q={county government building address}` using existing address search flow. Researcher should identify the correct county government building addresses (courthouse, county admin building) that return full representative coverage.
- **D-05:** A "Browse by location →" text link below the cards navigates to the Results page with the LocationBrowser visible. Does NOT duplicate the full LocationBrowser on the landing page.
- **D-06:** All three icons appear on politician cards: BallotIcon (on ballot), CompassIcon (has stances), BranchIcon (branch type). Icons appear on BOTH the representatives page and election page candidate cards.
- **D-07:** Icons positioned as bottom-right corner overlay on the photo area of PoliticianCard.
- **D-08:** Tooltips via @floating-ui/react — hover on desktop, tap on mobile. Tooltip text: "On your ballot — {date}", "Compare your views", "{branch} branch". Mobile dismisses on tap-away.
- **D-09:** Icon visibility computed frontend-side from existing data: ballot status from `getSeatBallotStatus()` (already exists), compass from stances data, branch from district_type.
- **D-10:** Branch type mapping — best-effort heuristic:
  - `NATIONAL_EXEC`, `STATE_EXEC`, `LOCAL_EXEC` → executive
  - `NATIONAL_UPPER`, `NATIONAL_LOWER`, `STATE_UPPER`, `STATE_LOWER`, `LOCAL`, `SCHOOL` → legislative
  - `JUDICIAL` → judicial
  - `COUNTY` → title-based: "council"/"commissioner" → legislative, "sheriff"/"clerk"/"auditor"/"assessor"/"recorder"/"coroner"/"treasurer" → executive, unknown → no branch icon
- **D-11:** Restructure election page to group candidates by position (not by position+party). Party primary labels become lightweight sub-labels within a position group, NOT separate CategorySection headers.
- **D-12:** General elections also group candidates by position — all candidates for the same seat appear together.
- **D-13:** Tier hue differentiation (tierColors from ev-ui) applies to election page tier sections, same as the representatives page.
- **D-14:** Exact election page layout needs browser iteration — researcher/planner should propose 2-3 layout variants that reduce visual noise. The direction is "fewer heavy section headers, lighter party labels."
- **D-15:** Pass `tier` prop to CategorySection on the representatives page. Federal=teal-700, State=teal-500, Local=teal-200 (from ev-ui tierColors token, decided in Phase 102).
- **D-16:** TypeScript CLI script at `ev-accounts/backend/scripts/auditHeadshots.ts`. Run with `npx tsx backend/scripts/auditHeadshots.ts`.
- **D-17:** Four checks: (1) broken CDN URLs (404/timeout), (2) image dimensions/aspect ratio (flag landscape, too small, or non-portrait), (3) file size outliers (unusually large or tiny), (4) missing headshots (politicians with no image record).
- **D-18:** Output is CSV format: `politician_id,name,issue,url,details` — suitable for manual review.

### Claude's Discretion

- Exact county government building addresses for location card navigation (researcher verifies)
- How to surface the LocationBrowser link on Results when arriving from "Browse by location" on landing
- Whether to batch-fetch compass stance availability or check per-politician
- Election page layout variant selection (propose options, user picks in browser)
- CSS specifics for icon overlay positioning (z-index, padding, background treatment for visibility over photos)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| VIS-01 | Election and representatives pages use tier-level visual differentiation (hue) for Federal/State/Local | tierColors token confirmed in ev-ui tokens.js; CategorySection `tier` prop confirmed in CategorySection.jsx |
| VIS-02 | Politician cards display small subtle icons for metadata (on ballot, compass available, branch type) | BallotIcon/CompassIcon/BranchIcon confirmed exported from ev-ui index.js; PoliticianCard needs `icons` overlay (not yet implemented in ev-ui — must be built in essentials as wrapper) |
| VIS-04 | Election page information hierarchy improved — race/position structure clearer, party ballot groupings less visually noisy | ElectionsView.jsx source read; current grouping logic identified; D-11/D-12 restructure approach documented |
| VIS-05 | Icons provide additional detail on hover (desktop) and tap (mobile) — accessible per WCAG | @floating-ui/react 0.27.19 confirmed; tooltip pattern documented; useDismiss handles mobile tap-away |
| DATA-04 | Headshot audit script scans all CDN images and flags badly cropped photos | auditHeadshots.ts pattern established from existing scripts; four checks documented; Node fetch + image dimension approach identified |
| NAV-01 | Landing page explicitly displays coverage areas (Monroe County, IN and Los Angeles County, CA) | Landing.jsx source read; coverage card implementation documented |
| NAV-02 | Landing page has prominent location shortcut buttons that navigate to pre-loaded representative results | Address navigation via `/results?q=...` pattern confirmed from existing navigate calls |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| @chrisandrewsedu/ev-ui | 0.1.55 (needs update from 0.1.53) | tierColors, CategorySection tier prop, BallotIcon/CompassIcon/BranchIcon, PoliticianCard imageFocalPoint | Project component library |
| @floating-ui/react | 0.27.19 (latest) | Icon tooltips on hover/tap | Decision D-08; best-in-class floating positioning, handles mobile tap-away via useDismiss |
| React 19 + Vite 7 + Tailwind 4 | (existing) | App framework | Already in essentials/package.json |
| tsx + pg | (existing in backend) | Headshot audit script runtime | Same pattern as importBudgetHierarchy.ts, audit-is-appointed.ts |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| node https (built-in) | — | Fetch CDN image bytes for dimension check in audit script | No extra dep needed for HTTP requests |
| sharp | (optional, avoid) | Image dimension reading | NOT recommended — adds native binary dep; use pure Node approach instead |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| @floating-ui/react | CSS :hover tooltips | CSS-only can't do tap-on-mobile dismiss; D-08 locks floating-ui |
| @floating-ui/react | Headless UI Tooltip | Headless UI requires Tailwind UI license; floating-ui is free/standard |
| Node HTTPS for image check | sharp | sharp requires native compilation; HTTPS + parsing PNG/JPEG headers is 20 lines of pure Node |

**Installation (essentials):**
```bash
cd essentials
npm install @floating-ui/react
npm update @chrisandrewsedu/ev-ui
```

**Version verification:**
- `@floating-ui/react`: `0.27.19` (verified via npm view 2026-04-03)
- `@chrisandrewsedu/ev-ui`: `0.1.55` (verified from ev-ui/package.json directly)

## Architecture Patterns

### Recommended Project Structure

No new directories needed. Work targets existing files with one new utility component:

```
essentials/src/
├── pages/
│   ├── Landing.jsx           # Add coverage cards above address search
│   └── Results.jsx           # Add tier prop to CategorySection calls
├── components/
│   ├── ElectionsView.jsx     # Restructure race grouping
│   └── IconOverlay.jsx       # NEW: icon group + tooltip wrapper
└── utils/
    └── ballotStatus.js       # Already exists — use as-is

ev-accounts/backend/scripts/
└── auditHeadshots.ts         # NEW: CDN audit script
```

### Pattern 1: Tier Prop on CategorySection (VIS-01)

**What:** Pass lowercase tier string to CategorySection. tierColors maps `'federal'`, `'state'`, `'local'` to bg/accent/text values.

**When to use:** Every CategorySection render in Results.jsx and ElectionsView.jsx tier sections.

**How tierColors maps (from tokens.js, confirmed):**
```javascript
// Source: ev-ui/src/tokens.js
tierColors = {
  federal: { bg: '#E4F3F6', accent: '#003E4D', text: '#003E4D' },  // teal-100/700
  state:   { bg: '#F5F9FA', accent: '#00657C', text: '#00657C' },  // teal-050/500
  local:   { bg: '#F5F9FA', accent: '#C0E8F2', text: '#005366' },  // teal-050/200/600
}
```

**Usage in Results.jsx:**
```jsx
// Source: derived from ev-ui/src/CategorySection.jsx tier prop implementation
<CategorySection
  key={category}
  title={qualifiedTitle}
  tier="federal"   // or "state" or "local"
>
```

The `tier` prop is already implemented in CategorySection.jsx — it reads `tierColors[tier]` and applies bg/accent/text to the titlePill. No ev-ui changes needed.

### Pattern 2: Icon Overlay Component (VIS-02 + VIS-05)

**What:** A `IconOverlay` component that wraps the photo area of a PoliticianCard with positioned icon badges. Each icon has a tooltip managed by @floating-ui/react.

**When to use:** Rendered inside PoliticianCard's image area. Because the `icons` prop doesn't exist yet on ev-ui's PoliticianCard, the overlay is built in essentials as a wrapper div positioned absolutely over the card.

**Key implementation insight:** PoliticianCard renders `<div style={styles.imageWrapper}>` which has `overflow: hidden`. The icon overlay must be positioned on the card's outer div, not inside the imageWrapper. The card root div already has `position: relative`.

**Approach:** In Results.jsx `renderPoliticianCard()`, wrap `<PoliticianCard>` in a relative-positioned div, then add the icon overlay as an absolute-positioned child overlapping the bottom-right of the photo area.

```jsx
// essentials/src/components/IconOverlay.jsx
import { useState } from 'react';
import {
  useFloating, useHover, useFocus, useDismiss, useRole, useInteractions,
  FloatingPortal, offset, flip, shift
} from '@floating-ui/react';
import { BallotIcon, CompassIcon, BranchIcon } from '@chrisandrewsedu/ev-ui';

function IconWithTooltip({ icon: Icon, tooltip, color }) {
  const [open, setOpen] = useState(false);
  const { refs, floatingStyles, context } = useFloating({
    open,
    onOpenChange: setOpen,
    middleware: [offset(6), flip(), shift()],
  });
  const hover = useHover(context, { mouseOnly: false });
  const focus = useFocus(context);
  const dismiss = useDismiss(context);
  const role = useRole(context, { role: 'tooltip' });
  const { getReferenceProps, getFloatingProps } = useInteractions([hover, focus, dismiss, role]);

  return (
    <>
      <span
        ref={refs.setReference}
        {...getReferenceProps()}
        style={{ color, cursor: 'default', display: 'flex' }}
        aria-label={tooltip}
      >
        <Icon size={14} />
      </span>
      {open && (
        <FloatingPortal>
          <div
            ref={refs.setFloating}
            style={{
              ...floatingStyles,
              background: '#2F3237',
              color: '#EBEDEF',
              padding: '4px 8px',
              borderRadius: '6px',
              fontSize: '12px',
              zIndex: 70,
              pointerEvents: 'none',
              whiteSpace: 'nowrap',
            }}
            {...getFloatingProps()}
          >
            {tooltip}
          </div>
        </FloatingPortal>
      )}
    </>
  );
}
```

**CSS for overlay positioning:**
```jsx
// Outer wrapper in renderPoliticianCard()
<div style={{ position: 'relative' }}>
  <PoliticianCard ... />
  <div style={{
    position: 'absolute',
    bottom: 4,
    left: 4,           // photo area is 80px wide in horizontal variant
    width: 80,
    display: 'flex',
    gap: 3,
    alignItems: 'center',
    padding: '2px 4px',
    // semi-transparent bg for visibility over photos:
    background: 'rgba(255,255,255,0.82)',
    borderRadius: 4,
    zIndex: 1,
  }}>
    {/* icons here */}
  </div>
</div>
```

**Note on z-index:** PoliticianCard badge is at z-index 1. The overlay should also be z-index 1 but positioned left (not right) to avoid collision with existing badge. The tooltip uses z-index 70 (from tokens.js `zIndex.tooltip`).

### Pattern 3: Icon Visibility Computation (D-09 + D-10)

**Ballot icon:** Already computed in Results.jsx:
```javascript
const ballot = !isCandidate && getSeatBallotStatus(pol.term_end, pol.term_date_precision);
// ballot is { onBallot: true, termEndDate: Date } or null
```
Format ballot date for tooltip: `ballot.termEndDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })`

**Compass icon:**
```javascript
const hasStances = politicianIdsWithStances && politicianIdsWithStances.has(String(pol.id));
```
This set is already populated in Results.jsx from CompassContext. No new fetch needed.

**Branch icon (D-10 heuristic):**
```javascript
function getBranch(districtType, officeTitle) {
  const execTypes = ['NATIONAL_EXEC', 'STATE_EXEC', 'LOCAL_EXEC'];
  const legisTypes = ['NATIONAL_UPPER', 'NATIONAL_LOWER', 'STATE_UPPER', 'STATE_LOWER', 'LOCAL', 'SCHOOL'];
  const judicialTypes = ['JUDICIAL'];

  if (execTypes.includes(districtType)) return 'executive';
  if (legisTypes.includes(districtType)) return 'legislative';
  if (judicialTypes.includes(districtType)) return 'judicial';
  if (districtType === 'COUNTY') {
    const t = (officeTitle || '').toLowerCase();
    if (/council|commissioner/.test(t)) return 'legislative';
    if (/sheriff|clerk|auditor|assessor|recorder|coroner|treasurer/.test(t)) return 'executive';
    return null; // unknown — no icon
  }
  return null;
}
```

### Pattern 4: Landing Page Coverage Cards (NAV-01 + NAV-02)

**Verified addresses (Claude's Discretion — D-04):**
- Monroe County, Indiana: **100 W Kirkwood Ave, Bloomington, IN 47404** (Monroe County Courthouse — confirmed via web search)
- Los Angeles County, California: **500 W Temple St, Los Angeles, CA 90012** (Kenneth Hahn Hall of Administration — confirmed as seat of LA County government via web search)

**Navigation pattern (existing):**
```jsx
navigate(`/results?q=${encodeURIComponent('100 W Kirkwood Ave, Bloomington, IN 47404')}`);
```

**"Browse by location" link (D-05):** Navigate to `/results` and activate browse mode. The Results page already has a searchMode toggle. Passing a query param like `?mode=browse` is the cleanest approach — Results.jsx reads it on mount and sets `setSearchMode('browse')`. This avoids prop drilling and works with the existing navigation pattern.

**Landing.jsx insertion point:**
```jsx
// Coverage cards go ABOVE the <div className="flex flex-col sm:flex-row gap-3">
// A divider with "or search by address" separates them
```

### Pattern 5: Election Page Restructure (VIS-04 — D-11/D-12)

**Current behavior (confirmed from ElectionsView.jsx source):**
- Each `pos` in `tierMap[tier]` becomes its own `CategorySection` with `displayTitle = cleanedPosition + " — Party Primary"` for primaries
- This creates separate heavy headers for "Monroe County Council — Democratic Primary" and "Monroe County Council — Republican Primary"

**Required behavior (D-11):**
- Group all races for the same `cleanedPosition` together as one `CategorySection`
- Inside that section, party label becomes a lightweight sub-header (`<p>` or `<span>`) before that party's candidates

**Data structure change:**
```javascript
// Current: each race = one CategorySection
{ displayTitle: "Monroe County Council — Dem Primary", candidates: [...] }

// New: group by cleanedPosition
{
  cleanedPosition: "Monroe County Council",
  parties: [
    { party: "Democratic", candidates: [...] },
    { party: "Republican", candidates: [...] },
  ]
}
// → one CategorySection with party sub-labels
```

**General elections (D-12):** `primary_party` is null/undefined for general election races. All candidates are already in one race entry — no grouping change needed except ensuring consistent position-grouped rendering.

**Proposed layout variants for D-14 (planner presents to user in browser):**

- **Variant A — Party chips:** CategorySection per position; party shown as a small `<span>` chip ("D Primary" / "R Primary") before each candidate group, styled like the tier header dividers (light text, thin rule).
- **Variant B — Party indented block:** CategorySection per position; each party's candidates indented under a left-border-accented party label (teal-100 left border, muted text).
- **Variant C — Merged with divider:** CategorySection per position; candidates from all parties listed continuously with a thin divider + party label between groups.

Variant A is simplest to implement. Variants B and C require additional styling work. The planner should implement Variant A as default and note that the user can iterate.

### Pattern 6: Headshot Audit Script (DATA-04)

**Script structure (matches existing backend scripts):**
```typescript
// ev-accounts/backend/scripts/auditHeadshots.ts
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import https from 'https';
import http from 'http';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
dotenv.config({ path: path.resolve(__dirname, '..', '.env') });
```

**Four checks (D-17):**

1. **Broken CDN URLs:** HTTP GET, flag non-200 responses or timeouts
2. **Image dimensions:** Fetch image bytes, parse PNG/JPEG header to read width/height without a library:
   - PNG: bytes 16-23 in the IHDR chunk are width (4 bytes) and height (4 bytes)
   - JPEG: scan for SOF marker (0xFFC0/FFC2) to find width/height
   - Flag: landscape (width > height), too small (height < 100px), aspect ratio outside 0.5–1.2
3. **File size outliers:** Content-Length from response headers — flag > 500KB (unusually large) or < 2KB (unusually tiny/placeholder)
4. **Missing headshots:** LEFT JOIN `essentials.politicians` with `essentials.politician_images` WHERE image_id IS NULL

**Database query:**
```sql
SELECT p.id, p.first_name, p.last_name, pi.url
FROM essentials.politicians p
LEFT JOIN essentials.politician_images pi ON pi.politician_id = p.id AND pi.type = 'default'
ORDER BY p.id
```

**CSV output format (D-18):**
```
politician_id,name,issue,url,details
12345,"Jane Smith",broken_url,https://cdn.../img.jpg,"HTTP 404"
12346,"John Doe",wrong_aspect_ratio,https://cdn.../img2.jpg,"width=400 height=300 ratio=1.33"
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tooltip positioning | Custom absolute/fixed tooltip with JS | @floating-ui/react | Handles viewport clipping, scroll, resize, z-index automatically |
| Icon rendering | SVG strings in JSX | BallotIcon/CompassIcon/BranchIcon from ev-ui | Already built, sized, accessible |
| Tier colors | Hardcoded hex values | tierColors from ev-ui tokens | Single source of truth; tokens already AA compliant |
| Image dimension parsing | sharp/jimp | Read PNG/JPEG header bytes directly | Pure Node, no native compilation, ~20 lines |
| Compass stance check | New API call | `politicianIdsWithStances` Set from CompassContext | Already fetched, already a Set, O(1) lookup |

**Key insight:** All data needed for icon visibility is already loaded — ballot status from `pol.term_end`, compass from `politicianIdsWithStances` Set in context, branch from `pol.district_type`. Zero new API calls for the icon system.

## Common Pitfalls

### Pitfall 1: ImageWrapper Overflow Clips the Icon Overlay

**What goes wrong:** Icon overlay placed inside `imageWrapper` div gets clipped because `imageWrapper` has `overflow: hidden`.

**Why it happens:** PoliticianCard's imageWrapper is `overflow: hidden` to crop photos. Any child element gets clipped.

**How to avoid:** Position the overlay OUTSIDE imageWrapper. In Results.jsx, wrap the entire `<PoliticianCard>` in a relative-positioned div and place the overlay as a sibling of PoliticianCard (position absolute on the outer wrapper, not inside the card's internal DOM).

**Warning signs:** Icons appear then disappear, or are invisible in horizontal variant.

### Pitfall 2: ev-ui PoliticianCard Does NOT Have an `icons` Prop Yet

**What goes wrong:** Planner assumes `icons` prop exists on PoliticianCard and instructs implementer to just pass `icons={[...]}`. Nothing renders.

**Why it happens:** CONTEXT.md references `icons` and `imageFocalPoint` props. `imageFocalPoint` was added in Phase 102 and IS in the source. `icons` was NOT added — the icon overlay is a Phase 103 task.

**How to avoid:** Build the icon overlay as a local essentials component wrapping PoliticianCard. Do not expect an `icons` prop on the ev-ui component.

### Pitfall 3: essentials Still on ev-ui v0.1.53

**What goes wrong:** `tierColors`, icon exports, CategorySection `tier` prop, and `imageFocalPoint` appear to work locally (using linked/cached version) but production build or fresh install uses 0.1.53.

**Why it happens:** `package.json` shows `"@chrisandrewsedu/ev-ui": "^0.1.53"` — the caret allows patch updates but 0.1.55 requires a minor bump to 0.1.55 explicitly or updating to `^0.1.55`.

**How to avoid:** First task in Wave 0: `npm install @chrisandrewsedu/ev-ui@0.1.55` in essentials. Verify `package.json` shows `^0.1.55` after.

### Pitfall 4: Tooltip z-index Stacks Under Sidebar or Header

**What goes wrong:** Tooltips render behind the desktop filter sidebar or page header.

**Why it happens:** `FloatingPortal` renders into document body but the tooltip `zIndex` in the code example uses a small value.

**How to avoid:** Use `zIndex: 70` (from tokens.js `zIndex.tooltip = 70`). The EV design system z-index scale has tooltip at 70, above header (30) and overlay (40).

### Pitfall 5: seededShuffle Must Be Preserved in Election Restructure

**What goes wrong:** Antipartisan candidate ordering breaks after election page restructure.

**Why it happens:** The current `seededShuffle` runs per-race. After grouping by position, candidates from different party ballots are merged into one list — the shuffle must run on the merged list, not per-party.

**How to avoid:** When building the merged position group in `processedElections`, apply `seededShuffle` to all candidates for that position after merging, before splitting into party sub-groups for display.

### Pitfall 6: Landing Page Auto-Redirect Fires Before Coverage Cards Show

**What goes wrong:** Connected users who already have saved representatives get redirected to `/results?prefilled=true` immediately on landing, so they never see the coverage cards.

**Why it happens:** Landing.jsx has a `useEffect` that redirects connected users with `myRepresentatives` data.

**How to avoid:** This is intentional and correct — connected users skip the landing page. The coverage cards are for anonymous/new users. No change needed; document this so implementers don't think coverage cards are broken for connected users.

## Code Examples

### Tier Prop — CategorySection

```jsx
// Source: ev-ui/src/CategorySection.jsx (confirmed in source)
// The tier prop accepts 'federal' | 'state' | 'local' (lowercase)
// Maps directly to tierColors[tier] from tokens.js

// In Results.jsx — Federal sections:
<CategorySection key={category} title={qualifiedTitle} tier="federal">

// In Results.jsx — State sections:
<CategorySection key={category} title={qualifiedTitle} tier="state">

// In Results.jsx — Local sections:
<CategorySection key={`${category}-${title}-${idx}`} title={title} websiteUrl={websiteUrl} tier="local">
```

### Floating-UI Tooltip Pattern

```jsx
// Source: https://floating-ui.com/docs/react + https://floating-ui.com/docs/useHover
// @floating-ui/react 0.27.19

import {
  useFloating, useHover, useFocus, useDismiss, useRole, useInteractions,
  FloatingPortal, offset, flip, shift, autoUpdate,
} from '@floating-ui/react';

function TooltipIcon({ icon: Icon, tooltip, color = '#005366' }) {
  const [open, setOpen] = useState(false);
  const { refs, floatingStyles, context } = useFloating({
    open,
    onOpenChange: setOpen,
    middleware: [offset(6), flip(), shift({ padding: 4 })],
    whileElementsMounted: autoUpdate,
  });
  const hover = useHover(context);
  const focus = useFocus(context);
  const dismiss = useDismiss(context);         // handles tap-outside on mobile
  const role = useRole(context, { role: 'tooltip' });
  const { getReferenceProps, getFloatingProps } = useInteractions([hover, focus, dismiss, role]);

  return (
    <>
      <span ref={refs.setReference} {...getReferenceProps()} style={{ color, display: 'flex' }}>
        <Icon size={14} color={color} />
      </span>
      {open && (
        <FloatingPortal>
          <div
            ref={refs.setFloating}
            style={{ ...floatingStyles, zIndex: 70, background: '#2F3237', color: '#EBEDEF',
                     padding: '3px 7px', borderRadius: '6px', fontSize: '12px',
                     pointerEvents: 'none', whiteSpace: 'nowrap' }}
            {...getFloatingProps()}
          >
            {tooltip}
          </div>
        </FloatingPortal>
      )}
    </>
  );
}
```

### Headshot Audit Script — PNG Header Parsing

```typescript
// Source: PNG spec (https://www.w3.org/TR/PNG/#11IHDR)
// PNG IHDR chunk: bytes 0-3 signature, 4-7 length, 8-11 "IHDR", 16-19 width, 20-23 height
function parsePngDimensions(buf: Buffer): { width: number; height: number } | null {
  const PNG_SIG = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  if (!buf.subarray(0, 8).equals(PNG_SIG)) return null;
  const width = buf.readUInt32BE(16);
  const height = buf.readUInt32BE(20);
  return { width, height };
}

// JPEG: scan for SOF0/SOF2 markers (0xFF 0xC0 or 0xFF 0xC2) — height at offset+3, width at offset+5
function parseJpegDimensions(buf: Buffer): { width: number; height: number } | null {
  for (let i = 0; i < buf.length - 8; i++) {
    if (buf[i] === 0xFF && (buf[i+1] === 0xC0 || buf[i+1] === 0xC2)) {
      const height = buf.readUInt16BE(i + 5);
      const width = buf.readUInt16BE(i + 7);
      return { width, height };
    }
  }
  return null;
}
```

### Landing Page Coverage Cards

```jsx
// essentials/src/pages/Landing.jsx — insert above address search
const COVERAGE_AREAS = [
  {
    county: 'Monroe County',
    state: 'Indiana',
    address: '100 W Kirkwood Ave, Bloomington, IN 47404',
  },
  {
    county: 'Los Angeles County',
    state: 'California',
    address: '500 W Temple St, Los Angeles, CA 90012',
  },
];

// Render:
<div>
  <p style={{ fontFamily: "'Manrope', sans-serif", fontSize: '14px', color: '#718096',
               textAlign: 'center', marginBottom: '12px' }}>
    We currently cover:
  </p>
  <div style={{ display: 'flex', gap: '12px', justifyContent: 'center', flexWrap: 'wrap' }}>
    {COVERAGE_AREAS.map(({ county, state, address }) => (
      <button
        key={county}
        onClick={() => navigate(`/results?q=${encodeURIComponent(address)}`)}
        style={{
          border: '2px solid #00657C',
          borderRadius: '10px',
          padding: '12px 20px',
          background: 'white',
          cursor: 'pointer',
          textAlign: 'left',
          transition: 'box-shadow 0.15s ease',
          fontFamily: "'Manrope', sans-serif",
        }}
        onMouseEnter={(e) => e.currentTarget.style.boxShadow = '0 4px 12px rgba(0,101,124,0.15)'}
        onMouseLeave={(e) => e.currentTarget.style.boxShadow = 'none'}
      >
        <div style={{ fontWeight: 700, fontSize: '15px', color: '#00657C' }}>{county}</div>
        <div style={{ fontSize: '13px', color: '#718096' }}>{state}</div>
      </button>
    ))}
  </div>
  <div style={{ textAlign: 'center', marginTop: '10px' }}>
    <button
      onClick={() => navigate('/results?mode=browse')}
      style={{ background: 'none', border: 'none', color: '#00657C', cursor: 'pointer',
               fontSize: '14px', fontFamily: "'Manrope', sans-serif" }}
    >
      Browse by location →
    </button>
  </div>
  {/* Divider */}
  <div style={{ display: 'flex', alignItems: 'center', gap: '12px', margin: '20px 0' }}>
    <hr style={{ flex: 1, borderColor: '#E2EBEF' }} />
    <span style={{ fontSize: '13px', color: '#718096', fontFamily: "'Manrope', sans-serif" }}>
      or search by address
    </span>
    <hr style={{ flex: 1, borderColor: '#E2EBEF' }} />
  </div>
</div>
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Heavy per-section party headers in elections | Position-grouped with lightweight party sub-labels | Phase 103 | Less visual noise; same data |
| No tier differentiation on CategorySection | tierColors bg/accent/text per Federal/State/Local | Phase 103 | Visual hierarchy for government levels |
| Text "On Ballot" badge (coral pill) | Small icon with tooltip (BallotIcon) | Phase 103 | Less prominent, more contextual |
| No coverage info on landing page | Explicit "We currently cover" cards | Phase 103 | Honest about scope, navigable |

**Deprecated/outdated:**
- `badge="On Ballot"` prop on PoliticianCard in Results.jsx: Replace with icon overlay (remove the `badge` prop for ballot status)

## Open Questions

1. **Results.jsx `?mode=browse` param handling**
   - What we know: Results.jsx reads `searchParams.get('q')` and `searchParams.get('view')`. searchMode is local state.
   - What's unclear: There is no existing `?mode=browse` handling — it needs to be added as a `useEffect` that reads the param on mount and calls `setSearchMode('browse')`.
   - Recommendation: Add `useEffect(() => { if (searchParams.get('mode') === 'browse') setSearchMode('browse'); }, [])` on mount in Results.jsx.

2. **Compass stance data in ElectionsView candidates**
   - What we know: ElectionsView receives `elections` prop with candidate objects. CompassContext provides `politicianIdsWithStances` for politicians. Candidates have `candidate_id`.
   - What's unclear: Do candidates (BallotReady records) map to politician IDs for stance lookup? ElectionsView currently uses `candidate.candidate_id` not `candidate.politician_id`.
   - Recommendation: Check if election candidate data has a `politician_id` field. If yes, use it for stance lookup. If no, skip CompassIcon for election candidates (showing only BallotIcon + BranchIcon there).

3. **Icon overlay on vertical vs. horizontal PoliticianCard**
   - What we know: D-07 says bottom-right of photo area. In horizontal variant, photo is 80x96px on the left. In vertical variant, photo fills full width at 4:5 aspect ratio.
   - What's unclear: Should icon overlay positioning differ by variant? The CONTEXT.md says bottom-right of photo area consistently.
   - Recommendation: Use `position: absolute; bottom: 4px; left: 4px; width: 80px` for horizontal (photo width), and a different width/positioning for vertical if needed. The essentials app uses horizontal cards everywhere — implement horizontal first.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Backend audit script | ✓ | v25.8.2 | — |
| tsx | `npx tsx scripts/auditHeadshots.ts` | ✓ | in backend devDeps | — |
| pg | DB queries in audit script | ✓ | in backend deps | — |
| @floating-ui/react | Icon tooltips in essentials | ✗ (not installed) | — | None — D-08 locks this dep; must install |
| @chrisandrewsedu/ev-ui 0.1.55 | tierColors, icons, tier prop | ✗ (0.1.53 installed) | 0.1.53 currently | None — must update |
| Census Geocoder / Google Maps | Coverage card addresses | ✓ (indirect — addresses verified manually) | — | Hardcoded addresses already confirmed |

**Missing dependencies with no fallback:**
- `@floating-ui/react` — must `npm install @floating-ui/react` in essentials before implementing icon tooltips
- `@chrisandrewsedu/ev-ui@0.1.55` — must update from 0.1.53 before using tierColors/icon exports/tier prop

**Missing dependencies with fallback:**
- None

## Validation Architecture

No automated test infrastructure exists in `essentials/` (no vitest config, no test files). The backend has vitest configured but no test files for scripts. Given the nature of this phase (visual wiring + a CLI script), validation is primarily manual visual inspection.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None in essentials; vitest in ev-accounts/backend |
| Config file | `ev-accounts/backend/vitest.config.ts` (backend only) |
| Quick run command | N/A (essentials); `npm test` (backend) |
| Full suite command | N/A (essentials); `npm test` (backend) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| VIS-01 | Tier hue renders on CategorySection | manual-only | visual inspection in browser | N/A |
| VIS-02 | Icons appear on cards | manual-only | visual inspection in browser | N/A |
| VIS-04 | Election page position grouping | manual-only | visual inspection in browser | N/A |
| VIS-05 | Tooltips show on hover/tap | manual-only | visual inspection in browser | N/A |
| DATA-04 | Audit script runs + outputs CSV | smoke test | `cd ev-accounts && DATABASE_URL="..." npx tsx backend/scripts/auditHeadshots.ts 2>&1 | head -5` | ❌ Wave 0 |
| NAV-01 | Coverage cards visible on landing | manual-only | visual inspection in browser | N/A |
| NAV-02 | Coverage card click loads results | manual-only | navigate in browser, verify results load | N/A |

### Sampling Rate
- **Per task commit:** `cd essentials && npm run build` (type/build errors), `cd ev-accounts/backend && npx tsx backend/scripts/auditHeadshots.ts --dry-run` (script only)
- **Per wave merge:** `npm run build` in essentials (zero build errors = green)
- **Phase gate:** Visual review of all 7 requirements in running dev server before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] No test file needed for visual work — build check suffices
- [ ] `auditHeadshots.ts` must be written before it can be smoke-tested
- Framework install: `cd essentials && npm install @floating-ui/react && npm install @chrisandrewsedu/ev-ui@0.1.55`

## Sources

### Primary (HIGH confidence)
- `ev-ui/src/icons.js` — BallotIcon, CompassIcon, BranchIcon SVG source (read directly)
- `ev-ui/src/tokens.js` — tierColors values confirmed, zIndex scale confirmed (read directly)
- `ev-ui/src/CategorySection.jsx` — `tier` prop implementation confirmed (read directly)
- `ev-ui/src/PoliticianCard.jsx` — NO `icons` prop confirmed (read directly)
- `ev-ui/src/index.js` — icon exports confirmed (read directly)
- `ev-ui/package.json` — version 0.1.55 confirmed (read directly)
- `essentials/package.json` — ev-ui 0.1.53 installed, @floating-ui/react not installed (read directly)
- `essentials/src/pages/Landing.jsx` — current structure (read directly)
- `essentials/src/pages/Results.jsx` — renderPoliticianCard, tier grouping, politicianIdsWithStances (read directly)
- `essentials/src/components/ElectionsView.jsx` — current election grouping logic (read directly)
- `essentials/src/utils/ballotStatus.js` — getSeatBallotStatus API (read directly)
- `ev-accounts/backend/scripts/audit-is-appointed.ts` — script pattern (read directly)

### Secondary (MEDIUM confidence)
- [floating-ui.com/docs/react](https://floating-ui.com/docs/react) — useFloating, useHover, useInteractions pattern
- [floating-ui.com/docs/useDismiss](https://floating-ui.com/docs/useDismiss) — outsidePress for mobile tap-away
- [floating-ui.com/docs/useHover](https://floating-ui.com/docs/useHover) — mouseOnly option, touch behavior
- Monroe County Courthouse: 100 W Kirkwood Ave, Bloomington, IN 47404 (multiple web sources confirm)
- Kenneth Hahn Hall of Administration: 500 W Temple St, Los Angeles, CA 90012 (Wikipedia + Yelp confirm)

### Tertiary (LOW confidence)
- PNG/JPEG header parsing approach — well-documented spec but not verified against Supabase CDN content-type specifics

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — ev-ui source read directly, floating-ui docs fetched, npm version confirmed
- Architecture: HIGH — all canonical files read, integration points confirmed
- Pitfalls: HIGH — derived from direct source inspection (no icons prop, overflow:hidden, 0.1.53 version)
- County addresses: MEDIUM — verified via multiple web sources, but Census Geocoder match should be confirmed on first run

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stable libraries; floating-ui 0.27.x API is stable)
