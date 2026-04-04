# Technology Stack

**Project:** v2026.4.1 Essentials Visual Polish & Election Improvements
**Researched:** 2026-04-02
**Overall confidence:** HIGH for icon/tooltip libraries (npm-verified); MEDIUM for CSS-only tooltip approach; HIGH for CSS object-position headshot fix; HIGH for Tailwind CSS 4 tier theming

---

## Context: What Is and Is Not New

This document covers **only what is new for v2026.4.1**. Prior STACK.md covers v2026.3.8 (Election Central).

**Existing stack — do not re-research:**
- React 19 + Vite 7 + Tailwind CSS 4 (`tailwindcss ^4.1.12`) + react-router-dom `^7.8.2`
- `@chrisandrewsedu/ev-ui ^0.1.53` (PoliticianCard, PoliticianProfile, RadarChartCore, SiteHeader, CategorySection)
- `@react-spring/web ^10.0.2` — animation
- Supabase PostgreSQL + PostGIS
- Google Maps Places autocomplete (wired)
- `recharts ^3.8.0` (already in package.json)
- Cloudflare Pages

**New capabilities needed:**
1. Icon system — subtle, readable icons for secondary metadata (branch type, on-ballot, compass availability)
2. Tooltip/popover — hover detail disclosure on icons
3. Headshot crop fix — face centering without JS library overhead
4. Tier hue differentiation — Federal/State/Local + sub-tier visual hierarchy
5. Compass-first card prototype — no photos, data-forward layout

---

## Recommended Stack — New Additions Only

### New npm Dependencies

| Package | Version | Purpose | Why |
|---------|---------|---------|-----|
| `lucide-react` | `^0.471.0` (latest: `1.7.0`) | Icon system for badge replacement | 1,500+ icons on a consistent 24px grid; tree-shakeable (one import = one icon, nothing else ships); React 19 peer dep explicitly listed (`^16.5.1 \|\| ^17.0.0 \|\| ^18.0.0 \|\| ^19.0.0`); 29.4M weekly downloads; maintained by community fork of Feather |
| `@floating-ui/react` | `^0.27.19` | Tooltip/popover positioning for icon hover details | ~3kB for positioning core; handles viewport collision detection, flip/shift middleware; accessible ARIA patterns built-in; peer dep `react >= 17.0.0` (React 19 compatible); no pre-built styles — compose with Tailwind |

**Total new bundle impact:** `lucide-react` per-icon ~1–2kB after tree-shaking; `@floating-ui/react` ~3kB positioning core + ~4kB React interaction hooks = ~7kB gzipped total for tooltip primitives. Acceptable for Cloudflare Pages CDN.

### No Additional Dependencies Needed

The following features are implemented **without new packages** using existing tools:

| Feature | Approach | Uses |
|---------|----------|------|
| Tier hue differentiation | Tailwind CSS 4 `@theme` CSS custom properties + `data-tier` attribute selectors | Existing Tailwind CSS 4 |
| Headshot crop fix | CSS `object-fit: cover` + `object-position: center top` on `<img>` | Native CSS |
| Compass-first card prototype | New JSX layout in essentials app — reuse RadarChartCore from ev-ui | Existing ev-ui + React Spring |

---

## Library Details

### lucide-react

**Version confirmed via npm registry:** `1.7.0` (published ~1 day ago as of research date)
**React 19 peer dependency:** `"react": "^16.5.1 || ^17.0.0 || ^18.0.0 || ^19.0.0"` — confirmed compatible

**Usage pattern:**
```jsx
// Named imports — tree-shaken by Vite. Only these icons ship in bundle.
import { Building2, Scale, Landmark, Vote, Compass } from 'lucide-react'

// Usage with size + stroke-width for EV design system feel
<Landmark size={14} strokeWidth={1.5} className="text-ev-muted-blue" />
```

**Recommended icons for EV use cases:**
- `Landmark` — federal/legislative branch
- `Building2` — local/municipal  
- `Scale` — judicial
- `Vote` — on-ballot indicator
- `Compass` — compass data available
- `MapPin` — location/district
- `Calendar` — election date
- `ChevronRight` / `ChevronDown` — expand/collapse

**Why not Heroicons:** Only 292 icons; missing several civic domain icons. Package is designed for Tailwind but the icon selection is too narrow for the range of metadata badges needed.

**Why not Phosphor Icons:** `@phosphor-icons/react` has 16–18x bundle overhead vs lucide-react due to multi-weight component abstraction. At ~100K weekly downloads vs lucide's 29.4M, ecosystem momentum is lower.

### @floating-ui/react

**Version confirmed via npm registry:** `0.27.19` (published ~1 month ago)
**React peer dependency:** `"react": ">=17.0.0"` — React 19 compatible

**What it provides:** Positioning primitives (`useFloating`, `useHover`, `useFocus`, `useDismiss`, `useRole`, `FloatingPortal`) — NOT pre-built components. You compose with Tailwind classes.

**Usage pattern for icon tooltip:**
```jsx
import {
  useFloating, useHover, useFocus, useDismiss,
  useRole, useInteractions, FloatingPortal, offset, flip, shift
} from '@floating-ui/react'

function IconTooltip({ icon: Icon, label, detail }) {
  const [isOpen, setIsOpen] = useState(false)
  const { refs, floatingStyles, context } = useFloating({
    open: isOpen,
    onOpenChange: setIsOpen,
    middleware: [offset(6), flip(), shift()],
    placement: 'top',
  })
  const hover = useHover(context, { move: false })
  const focus = useFocus(context)
  const dismiss = useDismiss(context)
  const role = useRole(context, { role: 'tooltip' })
  const { getReferenceProps, getFloatingProps } = useInteractions([hover, focus, dismiss, role])

  return (
    <>
      <span ref={refs.setReference} {...getReferenceProps()}>
        <Icon size={14} strokeWidth={1.5} className="text-ev-muted-blue/70 hover:text-ev-muted-blue transition-colors" />
      </span>
      {isOpen && (
        <FloatingPortal>
          <div
            ref={refs.setFloating}
            style={floatingStyles}
            {...getFloatingProps()}
            className="z-50 max-w-[200px] rounded-md bg-gray-900 px-2.5 py-1.5 text-xs text-white shadow-lg"
          >
            {detail}
          </div>
        </FloatingPortal>
      )}
    </>
  )
}
```

**Why not CSS-only tooltips:** CSS `:hover` + `group-hover:` approaches work for simple labels but break at viewport edges (no collision detection), cannot be keyboard-focused accessibly without JS, and lack proper ARIA `tooltip` role. For a civic platform aimed at broad accessibility, floating-ui's ARIA implementation is the right trade-off.

**Why not Headless UI Popover:** Headless UI's `Popover` is click-triggered by default; hover-on-icon requires workaround hacks (`Discussion #425` in headlessui repo). Floating-ui is purpose-built for hover tooltips.

**Why not react-tooltip:** Heavier (~20kB); less composable with Tailwind; floating-ui gives same functionality at ~7kB total with more control.

---

## CSS Techniques — No New Libraries

### Tier Hue Differentiation (Tailwind CSS 4 `@theme`)

Tailwind CSS 4 uses CSS-first configuration via `@theme` directive. Design tokens defined in `@theme` become CSS custom properties available at runtime.

**Approach: semantic color tokens per tier:**
```css
/* In essentials/src/index.css — add to @theme block */
@theme {
  /* Existing EV colors */
  --color-ev-coral: #ff5740;
  --color-ev-muted-blue: #00657c;
  --color-ev-light-blue: #59b0c4;
  --color-ev-yellow: #fed12e;

  /* New tier accent colors — variations of existing palette */
  --color-tier-federal: oklch(39% 0.12 230);    /* deep teal — authority */
  --color-tier-state: oklch(52% 0.10 200);      /* mid teal — intermediate */
  --color-tier-local: oklch(62% 0.09 170);      /* lighter teal-green — municipal */
  --color-tier-county: oklch(55% 0.08 160);     /* county distinction */
}
```

**Usage with `data-tier` attributes:**
```jsx
// CategorySection or card wrapper
<div data-tier="federal" className="border-l-2 border-[--color-tier-federal]">
```

```css
/* In index.css — scoped tier accent for section headers */
[data-tier="federal"] .tier-accent { color: var(--color-tier-federal); }
[data-tier="state"]   .tier-accent { color: var(--color-tier-state); }
[data-tier="local"]   .tier-accent { color: var(--color-tier-local); }
[data-tier="county"]  .tier-accent { color: var(--color-tier-county); }
```

**Why OKLCH:** Tailwind CSS 4 uses OKLCH natively for perceptually even color steps. Colors defined in OKLCH maintain consistent perceived brightness across the tier spectrum, ensuring the hue shift reads as a hierarchy rather than arbitrary color change. Use the same lightness/chroma channel, vary only hue.

**Why not hue-rotate filter:** `hue-rotate()` shifts ALL colors of an element including text and borders simultaneously. For cards that may contain photos, this creates unpredictable results. Per-token semantic colors give precise control.

### Headshot Face Centering (CSS Only)

**Problem:** Politicians' faces are cropped at mid-chest in many headshots. The `<img>` element uses `object-fit: cover` but defaults to `object-position: center center`, centering the torso instead of the face.

**Fix — no JS library needed:**
```jsx
// In PoliticianCard / avatar img element
<img
  src={headshot_url}
  alt={name}
  className="w-full h-full object-cover object-top"
  // object-position: top = aligns image top edge to container top
  // Face is almost always in the top 40% of a standard headshot photo
/>
```

**When `object-top` is insufficient:** For photos where the face is off-center laterally, use inline style:
```jsx
<img
  style={{ objectPosition: 'center 15%' }}
  className="w-full h-full object-cover"
/>
```

**Why not react-image-crop (`v11.0.10`):** react-image-crop is a cropping *tool* for user interaction (drag-to-crop with handles). It is not a display fix — it's for building an admin upload flow where a human crops the image. For the headshot audit use case (fixing display of pre-uploaded CDN images), CSS `object-position` is the correct and zero-cost solution. react-image-crop would only be appropriate if building a headshot upload interface in the staging admin.

**Why not Browser Face Detection API:** The Shape Detection API (`FaceDetector`) has limited browser support (~70% as of 2026) and is behind experimental flags in Firefox. Unreliable for production. `object-position: top` with a 1:1 square crop container captures the face in 90%+ of standard portrait headshots.

### Compass-First Card Prototype

No new libraries. The prototype uses:
- `RadarChartCore` from `@chrisandrewsedu/ev-ui` (already installed)
- Tailwind CSS 4 grid utilities for compact layout
- `@react-spring/web` for card entry animation (already installed)
- Text hierarchy using Tailwind `text-xs`/`text-sm`/`text-base` + `font-semibold`

The prototype explores **removing `<img>` entirely** and leading with:
1. Politician name + title (large)
2. Mini `RadarChartCore` (compact, 80–100px, non-interactive)
3. 2–3 top stance topics as text chips
4. Contact/profile link

This is a layout experiment, not a library decision. No new deps required.

---

## Installation

```bash
cd essentials
npm install lucide-react @floating-ui/react
```

**ev-ui update:** No ev-ui version bump needed for these features. Icons and tooltips are implemented directly in the essentials app, not in the shared library (they are too specific to the visual polish milestone).

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Icons | `lucide-react` | `@heroicons/react` | Only 292 icons — insufficient coverage for civic metadata categories (judicial, compass, ballot) |
| Icons | `lucide-react` | `@phosphor-icons/react` | 16–18x bundle overhead from multi-weight abstraction; 0.1M vs 29.4M weekly downloads |
| Icons | `lucide-react` | `react-icons` (mega bundle) | react-icons does NOT tree-shake by default — imports entire icon families; known bundle bloat |
| Tooltips | `@floating-ui/react` | CSS `group-hover:` | No collision detection; not keyboard-accessible; no proper ARIA tooltip role |
| Tooltips | `@floating-ui/react` | `react-tooltip` | ~20kB vs ~7kB; less composable with Tailwind; floating-ui is the underlying engine react-tooltip itself uses |
| Tooltips | `@floating-ui/react` | Headless UI `Popover` | Headless UI Popover is click-activated by default; hover requires hacks; not the right primitive |
| Headshots | CSS `object-position: top` | `react-image-crop` | react-image-crop is an upload/editing tool, not a display fix |
| Headshots | CSS `object-position: top` | Browser Face Detection API | ~70% browser support; experimental in Firefox; not reliable for production |
| Tier colors | Tailwind CSS 4 `@theme` tokens | `hue-rotate()` filter | hue-rotate shifts ALL colors including photos unpredictably; semantic tokens give precise control |

---

## What NOT to Add

| Avoid | Why |
|-------|-----|
| `react-icons` | Does not tree-shake correctly — ships entire icon families; adds 100KB+ to bundle |
| `tippy.js` / `@tippyjs/react` | Heavy (~12kB); floating-ui is the modern replacement and is already more widely adopted |
| `react-tooltip` | Built on floating-ui internally; adding the wrapper adds weight without benefit when you control the tooltip component |
| `framer-motion` | Already have `@react-spring/web`; two animation libraries creates bundle bloat and API confusion |
| Any cropping library | The headshot problem is a display-side CSS fix, not a data problem. Fix `object-position` at the img element level |
| `clsx` or `classnames` | Tailwind CSS 4 does not need a class merger — `cn()` utility is a one-liner if needed: `const cn = (...c) => c.filter(Boolean).join(' ')` |

---

## Version Compatibility

| Package | Version | React 19 | Notes |
|---------|---------|-----------|-------|
| `lucide-react` | `1.7.0` | YES — explicit `^19.0.0` peer dep | Named imports tree-shaken by Vite |
| `@floating-ui/react` | `0.27.19` | YES — `>=17.0.0` peer dep | Does not use deprecated React APIs |
| Tailwind CSS | `^4.1.12` | N/A — CSS only | `@theme` directive is v4 feature; already installed |

---

## Sources

- [lucide-react npm registry](https://www.npmjs.com/package/lucide-react) — HIGH confidence; version 1.7.0, peer deps `^16.5.1 || ^17.0.0 || ^18.0.0 || ^19.0.0` confirmed via `npm view`
- [@floating-ui/react npm registry](https://www.npmjs.com/package/@floating-ui/react) — HIGH confidence; version 0.27.19, peer deps `>=17.0.0` confirmed via `npm view`
- [React Icon Libraries Bundle Size Benchmark — Medium/nkcroft](https://medium.nkcroft.com/the-hidden-bundle-cost-of-react-icons-why-lucide-wins-in-2026-1ddb74c1a86c) — MEDIUM confidence; 2026 benchmark; lucide Δ/source ratio ~1x vs phosphor 16–18x
- [Floating UI React Docs](https://floating-ui.com/docs/react) — HIGH confidence; official docs; `useHover`, `useFocus`, `useRole` patterns confirmed
- [Tailwind CSS v4 Theme Variables Docs](https://tailwindcss.com/docs/theme) — HIGH confidence; official docs; `@theme` directive generates CSS custom properties
- [Tailwind CSS filter hue-rotate docs](https://tailwindcss.com/docs/filter-hue-rotate) — HIGH confidence; official docs; confirmed hue-rotate applies to all element colors
- [Design Tokens That Scale in 2026 (Tailwind v4) — Mavik Labs](https://www.maviklabs.com/blog/design-tokens-tailwind-v4-2026) — MEDIUM confidence; practical OKLCH token pattern confirmed
- [Smart cropping with native browser Face Detection — IODigital](https://techhub.iodigital.com/articles/native-face-detection-cropping) — MEDIUM confidence; confirms CSS object-position + Face Detection API approach; Face Detection API browser support limitations noted
- [react-image-crop npm registry](https://www.npmjs.com/package/react-image-crop) — HIGH confidence; v11.0.10; described as "responsive image cropping tool" — confirms it is an editing tool, not display fix
- [essentials/package.json](../essentials/package.json) — HIGH confidence; current dep list verified; no icon or tooltip libraries present

---
*Stack research for: v2026.4.1 Essentials Visual Polish & Election Improvements*
*Researched: 2026-04-02*
