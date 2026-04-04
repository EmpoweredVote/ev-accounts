# Phase 102: ev-ui Foundation + Quick Wins - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-03
**Phase:** 102-ev-ui-foundation-quick-wins
**Areas discussed:** Icon system approach, Headshot cropping strategy, tierColors token design, Ruben Marte fix approach

---

## Icon System Approach

### Q1: How should ev-ui export the icon set?

| Option | Description | Selected |
|--------|-------------|----------|
| Inline SVG components | Each icon is a React component exported from icons.js. Matches SocialLinks.jsx pattern. | ✓ |
| Raw SVG path data | Export path strings and viewBox data, consumers build `<svg>` themselves. | |
| Re-export from lucide-react | Thin wrappers around lucide-react icons. Can't go in ev-ui due to tsup splitting:false. | |

**User's choice:** Inline SVG components
**Notes:** Selected with preview showing `BallotIcon({ size, color })` pattern.

### Q2: Where should SVG path data come from?

| Option | Description | Selected |
|--------|-------------|----------|
| Research best-fit from Lucide | Find matching Lucide icons, copy SVG paths (MIT license). No runtime dependency. | ✓ |
| Custom-draw EV-specific icons | Design original SVGs. Higher fidelity but more effort. | |
| You decide | Claude picks best source per icon. | |

**User's choice:** Research best-fit from Lucide

### Q3: Shared wrapper component?

| Option | Description | Selected |
|--------|-------------|----------|
| Standalone icons only | Each icon self-contained with size/color props. Simpler for 3 icons. | ✓ |
| Shared wrapper in ev-ui | `<MetadataIcon>` wrapper handling sizing, aria-label, spacing. | |

**User's choice:** Standalone icons only

---

## Headshot Cropping Strategy

### Q1: Default headshot cropping behavior?

| Option | Description | Selected |
|--------|-------------|----------|
| Top-biased: 'center 20%' | Shifts crop window upward for face visibility. | ✓ |
| Per-image focal point | imageFocalPoint prop for individual tuning. | |
| Both: default + override prop | Ship 'center 20%' as default, expose imageFocalPoint for override. | |

**User's choice:** Top-biased: 'center 20%'
**Notes:** Selected with preview showing `objectPosition: 'center 20%'` addition.

### Q2: Optional imageFocalPoint prop anyway?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes, optional prop with default | Success criteria mentions this prop. Costs nothing as optional. | ✓ |
| No, just hardcode | Simpler. Add prop later if needed. | |

**User's choice:** Yes, optional prop with 'center 20%' default

### Q3: Apply to PoliticianProfile too?

| Option | Description | Selected |
|--------|-------------|----------|
| Both Card and Profile | Consistent behavior across both image display points. | ✓ |
| Card only for now | Profile images larger, may crop differently. | |

**User's choice:** Both Card and Profile

---

## tierColors Token Design

### Q1: How should tierColors be structured?

| Option | Description | Selected |
|--------|-------------|----------|
| Semantic map referencing colorScales | tierColors object mapping to existing teal scale values. | ✓ |
| Flat color values | Hardcoded hex values without referencing colorScales. | |
| You decide | Claude picks structure fitting existing patterns. | |

**User's choice:** Semantic map referencing colorScales
**Notes:** Selected with preview showing `{ federal: { bg: colorScales.teal['100'], ... } }`.

### Q2: Tier prop type on CategorySection?

| Option | Description | Selected |
|--------|-------------|----------|
| String key | Accepts tier='federal', ev-ui looks up colors internally. | ✓ |
| Full color object | Consumer passes tierColors object directly. | |

**User's choice:** String key

### Q3: Local tier hue — yellow or teal-200?

| Option | Description | Selected |
|--------|-------------|----------|
| Yellow for local | Warm yellow creates clear visual separation. | |
| Teal-200 for local | Keeps all tiers in same teal family. Subtler differentiation via shade. | ✓ |
| You decide based on contrast | Claude evaluates WCAG contrast and picks. | |

**User's choice:** Teal-200 for local
**Notes:** Overrides STATE.md suggestion of "teal-200 or yellow" — user explicitly chose teal-200 for consistent hue family.

---

## Ruben Marte Fix Approach

### Q1: How to fix the name mismatch?

| Option | Description | Selected |
|--------|-------------|----------|
| SQL data fix only | Fix seed SQL typo, run migration to correct name + link politician_id. | |
| Code-level accent normalization | Add Unicode normalization to candidate matching. Broader but problem is SQL typo. | |
| Both: fix data + add normalization | Fix immediate data issue AND add accent-safe matching for future imports. | ✓ |

**User's choice:** Both: fix data + add normalization

---

## Claude's Discretion

- Exact Lucide icon choices for ballot/compass/branch
- Whether tierColors includes sub-tier keys
- Migration script format

## Deferred Ideas

None — discussion stayed within phase scope
