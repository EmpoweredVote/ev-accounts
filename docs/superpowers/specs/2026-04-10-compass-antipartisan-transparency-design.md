# Compass Antipartisan Transparency — Design Spec

**Date:** 2026-04-10
**Project:** CompassV2
**Status:** Draft for review

## Problem

Users taking the compass quiz and viewing their results run into confusion that undermines trust:

1. The shape of their radar chart can look scattered or "lopsided" even when they feel their answers were politically consistent. They have no way to know why.
2. The compass makes several intentional antipartisan design choices (randomized stance spectrum direction, no party affiliations, no red/blue coloring, topic selection criteria). Those choices are invisible — so users can't distinguish "deliberate design" from "bug."
3. Without a place to explain the philosophy, the compass reads as a neutral tool trying to be neutral, rather than a tool with an explicit antipartisan stance we stand behind.

We want to make the intentional design choices visible and give confused users a place to go before they conclude the tool is broken or biased.

## Goals

- Give users a single canonical page that explains the compass's antipartisan design choices in plain language.
- Surface that page at the two moments of highest confusion (taking the quiz; seeing the compass) without interrupting first-time user flow.
- Make the randomized-spectrum-direction mechanic concretely understandable via one purposeful visual.
- Keep the whole artifact lightweight — this is a transparency page, not a methodology whitepaper.

## Non-goals

- Methodology whitepaper covering how stances are written, how politician positions are sourced, or how the radar math works at code level.
- Changing the compass quiz mechanics, the radar chart rendering, or the randomization logic itself. This is a communication layer over existing behavior.
- Building a fully interactive explainer (e.g., live radar demos). Static visuals only.
- Localization beyond English for v1.

## User stories

- As a **first-time user** seeing my compass for the first time, I want a brief heads-up that my compass shape is not a partisan score, so I don't misread it and abandon the tool.
- As a **returning user** revisiting the quiz, I want a persistent "why is this order not what I expected?" affordance next to the stance options, so I can check the reasoning without digging through menus.
- As a **skeptical visitor** wondering what the compass stands for, I want a "How It Works" page reachable from the footer any time, so I can evaluate the project's philosophy on my own terms.

## Design overview

Three coordinated surfaces:

1. A new `/how-it-works` page with six short sections covering the antipartisan design choices.
2. One new step added to the existing 3-step intro coach-mark tour on `Compass.jsx` (becomes a 4-step tour), which summarizes the key idea and links to the page in a new tab.
3. Two persistent "?" info icons — one on `Quiz.jsx` near the stance options, one on `Compass.jsx` near the radar chart — each linking to the relevant anchor on `/how-it-works` in a new tab.

All three entry points open the page in a new tab (`target="_blank" rel="noopener"`) so users never lose their place in the quiz or on the compass.

## The page: `/how-it-works`

### Route and layout

- New React Router route: `/how-it-works`
- New page file: `CompassV2/src/pages/HowItWorks.jsx`
- Wired into the existing router in `src/App.jsx` (or wherever routes are currently declared)
- Layout: single centered column, max-width ~720px, reading-page style (not a dashboard)
- Uses the existing `Layout` component so nav/footer stay consistent
- Page title: **"How the Compass Works"**
- Subhead: *"Our approach to helping you think about politics without taking sides."*

### Section 1 — Why stances don't always run the same direction
**Anchor:** `#spectrum-direction`

> Most topics have a natural spectrum of policy positions — often something like more-government-intervention on one end and less on the other. We keep the stances in their spectrum order (so neighboring positions stay neighbors), but we **randomly flip the direction** each time. Sometimes the spectrum runs one way, sometimes the other.
>
> Why? Because consistently putting one "side" at the top — even if unintentional — quietly tells users which answers are the "default" or "first" ones. Flipping the direction breaks that signal without scrambling the stances into nonsense.

**Visual:** A small annotated diagram showing one topic's spectrum rendered twice — once with the arrow pointing left→right, once right→left — with the same user pick landing at different radii. Caption: *"Same answer, two possible orientations. That's why your compass shape isn't a partisan score."* Static SVG, no interactivity.

### Section 2 — Why your compass positions may look counterintuitive
**Anchor:** `#compass-positions`

> Because each topic's spectrum direction is randomly flipped, a position that's "far from the center" on one topic might be "close to the center" on another — even if they represent the same kind of policy view. The same liberal-leaning or conservative-leaning answer can land in very different spots depending on which way that topic's spectrum happened to be pointing.
>
> So if your compass shape looks scattered or lopsided, that's expected. The shape is a reflection of your specific answers combined with randomized spectrum directions — not a partisan score.

No visual — the diagram in Section 1 carries the load.

### Section 3 — We don't show parties or use red and blue
**Anchor:** `#no-parties-no-colors`

> We deliberately hide political party affiliation throughout the compass. We don't use red, blue, or any partisan color coding. The goal is to help you evaluate policy positions on their merits, not on which team they belong to.
>
> This isn't about pretending parties don't exist. It's about asking you to decide what you think before you see the label.

No visual.

### Section 4 — How we pick topics
**Anchor:** `#topic-selection`

> Topics are chosen for civic importance, not for balance theater. We don't artificially pair a "liberal topic" with a "conservative topic" to look even-handed. Many important issues don't even fit cleanly on a left–right axis.
>
> If a topic seems missing or unfairly framed, tell us. The topic list is meant to grow.

No visual.

### Section 5 — How to read the radar chart
**Anchor:** `#reading-the-radar`

> Each spoke is a topic. Your dot on that spoke shows which policy position you picked along that topic's spectrum. Distance from the center tells you where your answer sits on *that topic's* spectrum — but since we flip spectrum directions randomly, you can't compare distances across topics and read a left/right meaning into the overall shape.
>
> Use the compass to compare yourself with politicians topic by topic, not as a single "score."

**Visual:** A small annotated static radar reference image. Callouts label: "each spoke = a topic," "dot = your pick," and "distance within one spoke is meaningful; comparing distances across spokes is not." Static image, not a live `RadarChartCore` instance.

### Section 6 — Our antipartisan commitment
**Anchor:** `#our-commitment`

> The Empowered Vote Compass exists to help you think, not to tell you what to think. We don't boost parties, we don't encode partisan assumptions into the visuals, and we try to be transparent about every design choice that could tilt the result.
>
> We're not perfect — bias creeps in. If something on the compass feels skewed or off, we want to hear about it. Transparency is our best defense against the biases we haven't noticed yet.

No visual.

### Page styling

- Manrope font (project default)
- Section headers: `ev-muted-blue`, medium weight
- Body text: standard gray (reuse existing prose color)
- Links: `ev-muted-blue`, hover `ev-coral`
- Adequate vertical rhythm between sections; anchor IDs on each `<section>` element
- Total page length: ~400–600 words + two visuals
- Page scrolls smoothly to anchor when landed on via hash

## Entry point 1: Footer link

Add **"How It Works"** to the existing footer, alongside current links. Evergreen, persistent, low salience. Plain text link, no icon.

## Entry point 2: Onboarding coach mark (new tour step)

The existing 3-step intro tour on `Compass.jsx` becomes a **4-step tour**. One new step is added, targeting the compass/radar area:

- **Target:** the radar chart element (same or adjacent to an existing tour target)
- **Step label:** updated to reflect "N of 4" across all steps
- **Copy:**
  > "Your positions may look scattered — that's intentional. We randomize stance spectrum direction and don't encode left/right on the chart, so the shape isn't a partisan score. *[Want the full story? →]*"
- **Link behavior:** The "Want the full story?" link opens `/how-it-works#compass-positions` in a **new tab** (`target="_blank" rel="noopener"`). The tour itself does not advance or dismiss when the link is clicked — the user can continue the tour normally after reading.
- **Placement in tour:** Insert as the final step (step 4) so it serves as the "now that you've seen everything, here's the philosophy" capstone. Can be adjusted during implementation if a different position reads better.
- **Persistence:** Uses the existing `useCoachMark` localStorage mechanism — shows once per user, dismissed along with the rest of the tour.

The copy is written so that a user who **doesn't click** the link still walks away with the key idea ("shape isn't a partisan score").

## Entry point 3: Persistent "?" info icons

Two small info icons, each a circled "?" using `lucide-react`'s `HelpCircle` at 16px, muted gray with hover state `ev-muted-blue`.

### Icon A — On `Quiz.jsx`

- **Placement:** Near the stance options header, on the line that introduces the stance choices
- **Hover tooltip:** "Why is the spectrum order not fixed?"
- **Click behavior:** Opens `/how-it-works#spectrum-direction` in a new tab
- **`aria-label`:** "Why is the stance spectrum order not fixed? Opens explanation in a new tab."

### Icon B — On `Compass.jsx`

- **Placement:** Near the radar chart title or controls, adjacent to the chart area
- **Hover tooltip:** "How do I read this?"
- **Click behavior:** Opens `/how-it-works#compass-positions` in a new tab
- **`aria-label`:** "How to read the compass. Opens explanation in a new tab."

Both icons are **always visible** (not one-time, not dismissible) — confusion can happen on any visit, not just the first.

## Accessibility

- All three "?" icons (Quiz, Compass, plus any on the page itself) have descriptive `aria-label`s that mention "opens in a new tab" where applicable
- Coach-mark link has a visible focus ring and is keyboard-reachable within the tooltip
- All anchor links on `/how-it-works` work via keyboard navigation
- Static visuals have descriptive alt text that conveys the concept, not just the shapes
- Page uses semantic `<section>` elements with H2 headings for each section

## Copy tone guidelines

- First person plural ("we")
- Plain, confident, non-defensive — this is a statement of values, not a disclaimer
- Short sentences, no academic hedging
- No "some might say" / "critics argue" / "it's complicated" filler
- Scannable — users who bounce after reading only the headers should still get the point

## Out of scope for this spec

- Copyediting pass on final section text (the copy above is a working draft; final wording can be polished during implementation or after)
- Redesign of the existing tour steps
- Any changes to the randomization logic in the quiz or radar chart rendering
- Mobile-specific layout tweaks beyond "it should look reasonable on narrow viewports"
- Analytics tracking for page visits or icon clicks (can be added later if needed)

## Open questions

None blocking. Potential follow-ups after launch:

- Should the coach mark's "Want the full story?" link eventually jump to a specific section other than `#compass-positions`?
- Does the "?" icon on `Quiz.jsx` belong at the top of the page or inline next to each topic? (Leaning top-of-page for simplicity; revisit after first use.)

## Affected files (expected)

- **New:** `CompassV2/src/pages/HowItWorks.jsx`
- **New:** Two static SVG visuals (spectrum-direction diagram, annotated radar reference) — location TBD, likely `CompassV2/src/assets/`
- **Modified:** Router declaration (wherever routes live — `src/App.jsx` or equivalent) to add `/how-it-works`
- **Modified:** `CompassV2/src/components/Layout.jsx` (or wherever the footer lives) to add the "How It Works" link
- **Modified:** `CompassV2/src/pages/Compass.jsx` — add new tour step (step 4 of 4), add "?" icon near radar
- **Modified:** `CompassV2/src/pages/Quiz.jsx` — add "?" icon near stance options header

No backend changes. No database changes. No `ev-ui` changes.
