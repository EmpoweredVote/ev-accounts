# Phase 106: Tier Background Hues & Branch Icons - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-04
**Phase:** 106-tier-backgrounds-branch-icons
**Areas discussed:** Section backgrounds, Branch icon design, Transition feel, Card-on-background

---

## Section Backgrounds

### Background application style

| Option | Description | Selected |
|--------|-------------|----------|
| Full-width bands | Edge-to-edge background color bands per tier | |
| Left accent bar | Thick colored vertical bar on left edge, white background | |
| Header + subtle tint | Colored header bar + very faint section tint | ✓ (modified) |

**User's choice:** Faint tint as the background for the entire section — no separate solid header bar. Just a subtle tint across the whole section area.
**Notes:** User clarified they want only the faint tint, not the solid header bar shown in the preview.

### Tint distinction

| Option | Description | Selected |
|--------|-------------|----------|
| 3 distinct tints | Federal=teal-100 (darkest), State=teal-050, Local=white/near-white | ✓ |
| Keep current values | Federal=teal-100, State=teal-050, Local=teal-050 | |
| You decide | Claude picks values | |

**User's choice:** 3 distinct tints
**Notes:** Current tierColors has state and local at the same value — need to differentiate.

### Tint scope

| Option | Description | Selected |
|--------|-------------|----------|
| Tier level | One continuous tinted band per tier | ✓ |
| Category level | Each CategorySection gets its own tinted rectangle | |

**User's choice:** Tier level

---

## Branch Icon Design

### Icon style

| Option | Description | Selected |
|--------|-------------|----------|
| Classic symbols | Star/shield, landmark, scales | Partial |
| Building-based | All building silhouettes | |
| You decide | Claude picks | |

**User's choice:** Liked judicial (scales) immediately. Not sold on executive or legislative from classic set.
**Notes:** Led to follow-up questions for executive and legislative individually.

### Executive icon

| Option | Description | Selected |
|--------|-------------|----------|
| Briefcase | Administrator role | |
| Building with flag | Building silhouette + small flag | ✓ |
| User/person badge | Person silhouette | |
| Crown/seal | Circular seal or rosette | |

**User's choice:** Building with flag

### Legislative icon

| Option | Description | Selected |
|--------|-------------|----------|
| Keep landmark (current) | Rename existing SVG | |
| Scroll/document | Represents lawmaking | ✓ |
| Group/people | Multiple people silhouette | |
| Podium/lectern | Debate/floor speeches | |

**User's choice:** Scroll/document

### Icon API

| Option | Description | Selected |
|--------|-------------|----------|
| Single component with branch prop | BranchIcon accepts branch='executive'|'legislative'|'judicial' | ✓ |
| Three separate components | ExecutiveIcon, LegislativeIcon, JudicialIcon | |
| You decide | Claude picks | |

**User's choice:** Single component with branch prop

### Icon color

| Option | Description | Selected |
|--------|-------------|----------|
| Same color as other icons | Muted gray/teal, consistent with BallotIcon/CompassIcon | ✓ |
| Branch-specific colors | Different color per branch | |
| You decide | Claude picks | |

**User's choice:** Same color as other icons

### Tooltip text

| Option | Description | Selected |
|--------|-------------|----------|
| "Executive branch" / etc. | Simple branch name | ✓ |
| Include body name | "Executive branch — Office of the President" | |
| You decide | Claude picks | |

**User's choice:** Simple branch names

---

## Transition Feel

### Transition style

| Option | Description | Selected |
|--------|-------------|----------|
| Hard break | Clean edge between tier tints | ✓ |
| Gradient fade | Bottom of one tier fades into next | |
| Small gap/divider | Thin white gap or horizontal rule | |

**User's choice:** Hard break

### Tint width

| Option | Description | Selected |
|--------|-------------|----------|
| Edge-to-edge | Background extends to viewport edges | ✓ |
| Content-width only | Background stays within content container | |

**User's choice:** Edge-to-edge

---

## Card-on-Background

### Card treatment

| Option | Description | Selected |
|--------|-------------|----------|
| White cards with subtle shadow | Cards float on tinted band with drop shadow | ✓ |
| Borderless / transparent cards | Content sits directly on tint, no card boundary | |
| Keep current card style | No card styling changes | |

**User's choice:** White cards with subtle shadow

### Vertical padding

| Option | Description | Selected |
|--------|-------------|----------|
| Generous padding | Visible tint above/below card grid | |
| Minimal padding | Just enough separation | ✓ |
| You decide | Claude picks balanced padding | |

**User's choice:** Minimal padding

---

## Claude's Discretion

- Exact teal shade for local tier bg value
- SVG path details for 3 branch icons
- Shadow values for floating cards
- CSS approach for edge-to-edge backgrounds

## Deferred Ideas

None — discussion stayed within phase scope
