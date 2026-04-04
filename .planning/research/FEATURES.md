# Feature Landscape

**Domain:** Civic tech — Visual polish, icon metadata, tier color differentiation, compass-first cards, location browsing
**Researched:** 2026-04-02
**Confidence:** MEDIUM-HIGH (existing codebase fully inspected; domain UX patterns drawn from USWDS, NN/G, and civic tech analysis; icon library confirmed via Lucide docs)

---

## Context: What Already Exists

This is milestone v2026.4.1. The following are already shipped and not in scope:

- `PoliticianCard` (ev-ui) with horizontal/vertical variants, compass button, badge prop, initials avatar fallback
- `CategorySection` (ev-ui) with title pill, info tooltip, and external website link
- `CompassPreview` popover (essentials) — mini radar chart on hover/click with CTA mode
- `ElectionsView` — Election Central with tier-grouped races, countdown, candidate cards
- `SegmentedControl` — Elected/Appointed filter
- `LocationBrowser` — cascading State → Area Type → Area dropdowns feeding into the results page
- `Landing` page — single address input field with Google Maps Places autocomplete
- `Results` page — sticky sidebar, scroll-spy building swap, full tier grouping via `classify.js`
- `getSeatBallotStatus()` — ballot window detection based on `term_end` / `precision`
- `ballotStatus.js` — already computes whether a seat is on the ballot within the next year
- Lucide-style custom SVG compass icon (inline in ev-ui `PoliticianCard`)

The **new features** for v2026.4.1 are:
1. Icon-based metadata display (on ballot, compass available, branch type) replacing full-text badges
2. Tier-level hue/color differentiation (federal vs state vs local; city vs township vs county within local)
3. Compass-first card prototype — explore replacing photos with a mini radar on representative cards
4. Location-aware landing page — prominent pre-set location buttons (Monroe County IN, LA County CA)
5. Headshot crop validation and audit tooling (batch review/flag, not user-facing)
6. Remove "incumbent" marker from candidate cards on Election Central
7. Fix Ruben Marte name mismatch to link candidate to politician profile

---

## Table Stakes

Features users expect on a civic representative listing page. Missing these makes the product feel incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Visual distinction between government tiers | Users cannot assess relevance of an official without knowing whether they represent the city, state, or nation. All major civic directories (Ballotpedia, VOTE411, govtrack.us) use visual grouping by tier. | LOW | Tier labels already exist; work is adding a consistent hue or left-border accent per tier to reinforce scanability. |
| Icons for metadata cues | Dense text badges (e.g., "ON BALLOT", "COMPASS AVAILABLE") increase cognitive load on already-information-heavy listing pages. USWDS icon-list pattern establishes icon + text as the accessible standard for metadata. | MEDIUM | Icons must pair with accessible text (tooltip or sr-only label). Lucide React already in the ecosystem (lucide-dev confirms `landmark`, `vote`, `gavel`, `map-pin`, `compass` icons exist). |
| Clear coverage messaging on landing | Users in unsupported areas currently see no data and no explanation. "No results" without coverage context destroys trust. NN/G progressive disclosure research: show the most relevant information first, explain limits immediately. | LOW | Landing page currently has only an address input field. Add two explicit location buttons (Bloomington/Monroe County IN, LA County CA) and coverage footnote. |
| Accessible hover/tooltip for icon metadata | Color or icon alone cannot be the sole conveyor of meaning (WCAG 1.4.1). Supplementing icons with hover tooltips satisfies both accessibility and progressive disclosure. | LOW | Tooltip on icon hover: "This representative is on the ballot in the next 12 months." Pattern already exists in `CategorySection`'s info tooltip button. |

## Differentiators

Features that go beyond what civic directories provide, fitting EV's mission of reducing information overload.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Compass-first card variant | No civic voter guide shows a policy-alignment radar chart inline on the listing page. Replaces or de-emphasizes headshots, which convey no policy signal, with a mini radar of the politician's positions. Creates immediate policy context before a user clicks through. | HIGH | Depends on: (1) politician having compass stances (503 CDN records covers photos but stance data is sparser), (2) user having a compass (guest users without compass get the "Take the Quiz" CTA mode). `CompassPreview` already implements both paths. The risk is high null-data rate — most local officials lack stances. Needs fallback card for no-data case. |
| Tier hue system with within-local sub-hues | Federal/State/Local differentiation is standard; going further to distinguish city vs township vs county within the Local tier is not offered anywhere. Reduces the visual blur when a user sees 30+ local officials. | MEDIUM | Three hue families: Federal (existing ev-muted-blue `#00657c` family), State (amber/warm tones), Local (split: city=green, township=purple, county=rust). Must remain accessible — color cannot be the only differentiator. Pair with tier label text. |
| Ballot-window icon on card (not just badge) | The existing "ON BALLOT" amber badge uses full-text in a corner position that competes with the headshot. An icon with tooltip reduces visual noise while preserving the signal. Users who need depth can hover; scanners see an unobtrusive icon. | LOW | `getSeatBallotStatus()` already returns `{ onBallot: true }`. Replace the amber badge with a Lucide `vote` icon (16px) with tooltip "Running in upcoming election." |
| Branch-type icon on card | No civic directory offers a branch-type icon (legislative/executive/judicial) on the listing card. Helps users mentally organize what their representatives do. | LOW | Three icons: `landmark` (legislative chambers), `crown` or `shield` (executive), `gavel` (judicial). Derive branch from `district_type`: `*_UPPER`/`*_LOWER` = legislative, `*_EXEC` = executive, `JUDICIAL` = judicial. Add as a 16px icon in the card metadata row with tooltip. |
| Prominent location shortcut buttons on landing | Users who don't know their exact address (or don't want to type it) hit friction immediately. Adding "Browse Monroe County, IN" and "Browse Los Angeles County, CA" buttons makes coverage obvious and lets users start exploring without typing. | LOW | `LocationBrowser` component already exists with the API endpoints; landing page just needs quick-access buttons that pre-fill the browse state. Not a new API call — just a UI shortcut wiring existing LocationBrowser to specific known geo_ids. |
| Headshot crop audit script | 503 CDN-hosted headshots have inconsistent framing — some are distant full-body shots, some cut off the top of the head, some show off-center subjects. An audit script that flags problematic crops saves manual review time for data volunteers. | MEDIUM (tooling, not user-facing) | Script approach: fetch each image URL, run heuristic checks (aspect ratio sanity, face detection via browser `face-detection` API or a lightweight npm package like `node-face-recognition`), output a CSV of flagged politician_ids + image URLs for manual review. No Supabase image transformation face detection — confirmed not available natively. |

## Anti-Features

Features to explicitly NOT build in this milestone.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Full tier color redesign of `CategorySection` titles | Changing the `CategorySection` component in ev-ui will affect all consumers (essentials, CompassV2). Scope creep risk is high. | Add tier hue as a prop or wrapper class in the essentials `Results.jsx` render, not inside ev-ui. |
| Party color coding | Directly violates the antipartisan mission. Party colors (red=Republican, blue=Democrat) are the most well-known partisan visual signals in the US. | Use tier hues (federal/state/local) and branch icons instead. |
| Automatic face-centered crop via Supabase Storage | Supabase Storage image transformations confirmed (as of 2025) to NOT support face detection/smart crop. Only cover/contain/fill modes available. | Flag problem headshots in audit script; re-crop and re-upload manually. |
| Animated tier badges or icon transitions | Motion on metadata icons distracts from content; adds complexity for negligible UX gain; can trigger `prefers-reduced-motion` violations. | Static icons with CSS hover state only. |
| Replace photos entirely on all cards | Too risky as a default — headshots provide identity recognition especially for well-known politicians (senators, governors). Photos remain for all politicians with good headshots. | Introduce compass-first card as an optional view toggle or only for politicians with no usable headshot. |
| Expanding CompassPreview into a full sidebar panel | Current popover model is already feature-complete. Expanding it into a persistent sidebar panel increases complexity and conflicts with the sticky sidebar already present in Results. | Keep CompassPreview as a popover. Full compass card is available on the profile page. |
| New icon library (Heroicons, Phosphor, etc.) | The project has no icon dependency currently — adding a large icon library for 3-4 icons is overshooting the need. Lucide React (~1KB per icon, tree-shakable) is appropriate if installing an external library; inline SVGs are fine for 2-3 icons. | Use Lucide React (already popular in Tailwind/Vite ecosystems) or inline SVG. Evaluate whether `lucide-react` should be a formal dependency of ev-ui vs essentials. |
| "Accessibility score" or "responsiveness score" labels per politician | Civic design research (NN/G, Center for Civic Design) consistently warns against aggregate scoring of elected officials — introduces editorial judgment into what should be factual presentation. | Show raw data: votes, stances, quotes. Let users form their own assessments. |

---

## Feature Dependencies

```
Icon-based metadata on PoliticianCard
    └──requires──> Lucide icons or inline SVG (low effort — no external dependency currently)
    └──requires──> getSeatBallotStatus() result passed to card (already computed in Results.jsx)
    └──requires──> district_type passed to card (already in politician data)
    └──uses──> tooltip pattern already in CategorySection (copy pattern, don't share component)

Tier hue differentiation
    └──requires──> tier classification (already done by classify.js — returns { tier, group })
    └──requires──> CSS design token additions (Federal/State/Local hue variables)
    └──should NOT require──> ev-ui PoliticianCard changes (apply hue as wrapper in Results.jsx)

Compass-first card
    └──requires──> CompassPreview popover (ALREADY BUILT)
    └──requires──> politician compass stances (sparse for local officials — fallback required)
    └──requires──> user compass data (guest/no-compass path already handled by CompassPreview CTA mode)
    └──risk──> High null rate for local officials makes this a limited-reach feature without more stance data
    └──suggests──> Only activate compass-first view for politicians with confirmed stance data

Location buttons on Landing
    └──requires──> LocationBrowser component (ALREADY BUILT)
    └──requires──> known geo_id + mtfcc values for Monroe County IN and LA County CA
    └──does NOT require──> any new API endpoints (browse/by-area already handles it)

Headshot audit tooling
    └──requires──> Supabase storage URL list (already in essentials.politician_images table)
    └──requires──> Node.js script with image fetch + face-detection heuristics
    └──does NOT require──> any frontend changes
    └──outputs──> CSV of flagged records for manual review + re-upload

Remove "incumbent" from candidate cards (Election Central)
    └──requires──> Remove badge={pol.is_incumbent ? 'Incumbent' : undefined} from ElectionsView
    └──rationale──> Incumbent labels on the election page imply incumbency advantage; EV's antipartisan
                    mission requires equal visual treatment of all candidates on the ballot

Fix Ruben Marte link
    └──requires──> Data investigation: find matching politician_id in essentials.politicians
    └──requires──> Update candidate record to link to correct politician_id
    └──is NOT a code change──> data fix only
```

---

## MVP Recommendation

### Build in this milestone

1. **Icon metadata row on PoliticianCard** — ballot-window icon (`vote`), compass-available icon (existing custom SVG), branch icon (`landmark`/`gavel`/crown). Three icons max, all with tooltips. Wire into `Results.jsx` using already-computed `getSeatBallotStatus()` and `district_type`. (Complexity: LOW)

2. **Tier hue differentiation** — Left-border accent or section header background tint per tier (Federal/State/Local). Within Local, add sub-tiers via group classification already returned by `classify.js`. Apply in `Results.jsx` wrappers, not in ev-ui. (Complexity: LOW-MEDIUM)

3. **Location buttons on Landing page** — Add "Browse Monroe County, IN" and "Browse Los Angeles County, CA" as pill buttons that bypass the address input and call the existing `LocationBrowser` browse flow. Add a one-line coverage note: "Currently covering Monroe County, IN and Los Angeles County, CA." (Complexity: LOW)

4. **Remove "incumbent" marker from Election Central candidate cards** — One-line change in `ElectionsView.jsx`. (Complexity: LOW)

5. **Fix Ruben Marte link** — Data investigation + SQL update. (Complexity: LOW — data fix)

6. **Headshot audit script** — Node.js script, output CSV. Run once; not user-facing. (Complexity: MEDIUM — tooling)

### Defer

- **Compass-first card** — HIGH effort, HIGH null-data risk. Defer until stance data coverage for local officials improves. Can be prototyped as an opt-in toggle.
- **Re-cropping flagged headshots** — Depends on audit output. Manual effort; schedule for after audit script runs.
- **Full ev-ui PoliticianCard redesign** — Any changes to ev-ui require a version bump and coordinated updates across essentials, CompassV2, ReadRank. Keep ev-ui stable; do visual polish in essentials-local wrappers first.

---

## Complexity Notes on Icon Library Decision

Lucide React is the recommended choice if adding an external icon dependency:

- `lucide-react` v0.474+ — tree-shakable, ~1KB per icon imported, TypeScript-first, MIT license
- Relevant icons confirmed available: `landmark` (government building/legislative), `gavel` (judicial), `vote` (ballot), `map-pin` (location), `map-pin-house`, `building` (executive offices)
- No `compass` icon exists in Lucide for the EV compass metaphor — the custom SVG radar chart icon in ev-ui should remain custom
- Installation: `npm install lucide-react` in `essentials/`; do NOT add to ev-ui until there's a clear case for multiple consumers needing the same icon

Alternative: inline SVG for 3-4 icons avoids a new dependency entirely. Acceptable given small icon count for this milestone.

**Recommendation:** Use inline SVG for the 3 branch-type icons and ballot icon in this milestone. Add `lucide-react` as a formal essentials dependency only if icon usage grows to 6+ in a future milestone.

---

## Information Density Patterns from Research

### What civic apps get wrong (confirmed from USWDS docs, NN/G, GOV.UK case study)

- **Text badges compete with headshots.** When text badges appear over or near a headshot image, visual complexity spikes. The GOV.UK bank holiday redesign case study shows that presenting the most relevant signal (next date/event) as the primary element and deprioritizing less-needed info reduces cognitive load measurably.
- **Tier labels buried in category headers are missed.** Users scan card content, not section headers. Inline tier signals on each card (icon, border, hue) outperform section-header-only labeling.
- **Full-text status labels ("ON BALLOT", "COMPASS AVAILABLE") are verbose.** An icon with tooltip is standard accessible practice (USWDS icon-list component: `aria-hidden="true"` on icon, meaning conveyed by adjacent text or tooltip). The icon alone communicates to sighted users; the tooltip satisfies accessibility.

### Tier hue design constraint

WCAG 1.4.1 requires that color not be the sole means of conveying information. The tier hue system must pair color with at least one other visual differentiator (text label, icon, or border weight). The existing `CategorySection` title pill already provides the text label — the hue is additive, not substitutive.

Accessible hue selection: use EV design tokens as anchors:
- Federal: `ev-muted-blue` (#00657c) — already the primary brand color; use as-is for federal tier
- State: amber/gold family (near `ev-yellow` #fed12e) — warm tone distinguishes from teal
- Local: split within-local by sub-group; green family for city/municipal, neutral/gray for township, rust/orange for county

---

## Sources

- Codebase: `essentials/src/components/PoliticianCard.jsx` — current badge pattern (text, absolute position) (HIGH confidence)
- Codebase: `ev-ui/src/PoliticianCard.jsx` — full ev-ui card implementation, badge/compassButton props (HIGH confidence)
- Codebase: `essentials/src/lib/classify.js` — full tier/group classification already available (HIGH confidence)
- Codebase: `essentials/src/utils/ballotStatus.js` — ballot window computation already available (HIGH confidence)
- Codebase: `essentials/src/components/LocationBrowser.jsx` — browse API already wired (HIGH confidence)
- Codebase: `essentials/src/pages/Landing.jsx` — current landing page is address-only, no location buttons (HIGH confidence)
- Codebase: `essentials/src/components/CompassPreview.jsx` — CompassPreview CTA mode and radar chart mode both implemented (HIGH confidence)
- [Lucide — landmark icon](https://lucide.dev/icons/landmark) — tagged as government, institution, capitol (HIGH confidence — confirmed exists)
- [Lucide — vote icon](https://lucide.dev/icons/vote) — tagged as ballot, political (HIGH confidence — confirmed exists)
- [Lucide — gavel icon](https://lucide.dev/icons/gavel) — tagged as justice, law, court (HIGH confidence — confirmed exists)
- [Lucide React npm](https://www.npmjs.com/package/lucide-react) — tree-shakable, 30M+ weekly downloads, actively maintained (HIGH confidence)
- [USWDS Icon List component](https://designsystem.digital.gov/components/icon-list/) — icon + adjacent text as accessible metadata pattern, `aria-hidden` on decorative icons (MEDIUM confidence — confirmed via search, not fetched directly)
- [WCAG 1.4.1 Use of Color](https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html) — color must be supplemented by other visual distinction (HIGH confidence)
- [NN/G: Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/) — tooltip-on-icon as progressive disclosure for secondary metadata (HIGH confidence)
- [Supabase Storage Image Transformations](https://supabase.com/docs/guides/storage/serving/image-transformations) — confirmed: no face detection / smart crop; cover/contain/fill only (HIGH confidence)
- [GOV.UK bank holiday redesign case study](https://civicdesign.org/) — progressive disclosure and information hierarchy in government UI (MEDIUM confidence — referenced via civic design search; not fetched directly)

---

*Feature research for: v2026.4.1 Essentials Visual Polish & Election Improvements*
*Researched: 2026-04-02*
