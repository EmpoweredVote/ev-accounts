# Domain Pitfalls

**Domain:** Visual polish, icon systems, and tier hue differentiation on existing multi-app civic engagement platform
**Researched:** 2026-04-02
**Scope:** v2026.4.1 — icon system, tier colors, compass-first card, headshot fixes, election page polish

---

## Critical Pitfalls

Mistakes that require rewrites, break multiple apps simultaneously, or violate the antipartisan principle.

---

### Pitfall 1: ev-ui Change Breaks All Three Consumer Apps Simultaneously

**What goes wrong:** A change to `PoliticianCard`, `CategorySection`, or any shared component in ev-ui — even visually "safe" changes like adding a new prop or changing default styling — gets published and immediately breaks the visual contract in CompassV2, essentials, and EV-readrank. The apps do not pin to a specific minor version; they pull the latest published version when rebuilt. Cloudflare Pages rebuilds happen on every push to `main` per app.

**Why it happens:** ev-ui uses a single entry point (`src/index.js`) that barrel-exports everything. The tsup build configuration (`splitting: false`) bundles all components into one `index.js`/`index.mjs` — no per-component chunking. There is no tree-shaking at the library level. A changed internal layout in `PoliticianCard` ships alongside every other component. If the new `PoliticianCard` expects a `tierColor` prop that wasn't there before and existing call sites don't pass it, the card silently falls back to whatever the default is — which may render incorrectly across all pages that use it.

**Consequences:** Three apps broken at once. Rollback requires re-publishing the previous ev-ui version AND redeploying all three apps. Emergency fix path is slow: bump ev-ui version → rebuild → publish to GitHub npm → `npm update` in each consumer → push → wait for Cloudflare Pages build × 3.

**Prevention:**
- Treat `PoliticianCard` changes as a minor-version bump minimum, not a patch. If the visual contract changes in any way, bump minor.
- Add the new tier-color prop as **optional with a safe fallback** (no tier color = current behavior). Never make a new prop required if existing call sites won't pass it.
- Before publishing, manually verify the component renders correctly without the new prop (the null/fallback state).
- Test in essentials dev before publishing — it is the primary consumer.

**Detection:** Check that `essentials/src/components/ElectionsView.jsx` and `essentials/src/pages/Results.jsx` still render correctly without passing any new props. These two files call `PoliticianCard` the most.

**Phase:** Must be addressed in Phase 1 (icon system research and PoliticianCard changes) before any ev-ui publish.

---

### Pitfall 2: Tier Hue Differentiation Introduces Partisan Color Associations

**What goes wrong:** Using common political color associations — red/blue for party affiliations — even accidentally through tier hues, violates the antipartisan principle baked into the schema (antipartisan enforcement at schema and ingestion layers) and design system. The platform explicitly excludes party affiliation from all data display. If "state" tier gets blue and "federal" tier gets red, or if any hue system maps to recognizable political parties, it undermines user trust and the platform's core value.

**Why it happens:** The natural instinct when designing government-level differentiation is to reach for the US political color vocabulary (red = Republican = conservative, blue = Democrat = liberal). This is so deeply embedded in US civic visual culture that it happens unintentionally — a designer picks "government blue" for federal, "state red" for state-level, and the result reads as partisan even without intent.

**Consequences:** Perceived bias by users. Loss of trust. Contradicts the documented antipartisan principle. May require full visual redesign of tier system post-launch.

**Prevention:**
- Use the existing EV brand palette only: teal scale for civic/government, coral for action/elections, yellow for inform, skyblue for secondary differentiation. These are brand colors without partisan connotations.
- The `tokens.js` `colorScales` provides a full teal scale (050–950) and skyblue scale — use **lightness/shade variation within a single non-partisan hue** for tier differentiation rather than distinct hues per tier.
- A safe pattern: federal = teal-700 (darkest, most authoritative), state = teal-500 (mid-brand), local = teal-200 (lightest, most approachable). All teal, no partisan reads.
- Run any tier-color proposal past the antipartisan filter: "Could this hue be read as favoring one political party?" If yes, reject it.

**Detection:** Show the color palette to someone unfamiliar with the project. If they associate the hues with political parties, redesign before shipping.

**Phase:** Phase 1 (tier hue design decisions). Lock the palette before implementing — do not design it during implementation.

---

### Pitfall 3: buildTitleAndSubtitle() Logic Diverges Between ev-ui and essentials

**What goes wrong:** `buildTitleAndSubtitle()` exists in two places: `ev-ui/src/PoliticianProfile.jsx` and `essentials/src/pages/Results.jsx`. The essentials version is more sophisticated — it includes `qualifyLocalTitle()`, `simplifyForBody()`, and `splitByBodyName()` which handle local government specifics. A visual redesign that touches how titles/subtitles are displayed on cards may motivate updating one version and not the other, causing permanent divergence.

**Why it happens:** The CLAUDE.md documents this explicitly: "changes to district/title display must be applied in both places." But during fast visual iteration — especially when adding icons next to titles or changing subtitle styling — it is easy to modify the component you are looking at and forget the duplicate.

**Consequences:** Representatives page and profile pages display different title formats for the same politician. Local government titles that needed `qualifyLocalTitle()` stop being qualified correctly on whichever version gets missed.

**Prevention:**
- Do not touch `buildTitleAndSubtitle()` logic during this milestone unless fixing a documented bug.
- If a display change requires modifying title formatting, update both files in the same commit and include a comment referencing the other file.
- Any icon added next to the title should use absolute/overlay positioning rather than reflowing the title text — avoid layout changes that force title logic changes.

**Detection:** Compare the subtitle of a local government politician (e.g., "Ellettsville Town Council") between the representatives list card and the profile page header. They should match. If they diverge, the functions have drifted.

**Phase:** Applies across all phases. Flag this as a mandatory dual-edit check whenever title display code is touched.

---

## Moderate Pitfalls

Mistakes that require rework of a specific feature but do not cascade to all apps.

---

### Pitfall 4: Icon System Bloats ev-ui Bundle for All Consumers

**What goes wrong:** Adding a third-party icon library (react-icons, lucide-react, etc.) as a dependency to ev-ui, then importing icons throughout multiple components, adds the entire icon library to every consumer's bundle — even if that consumer only uses one or two icons. With `splitting: false` in tsup.config.js, ev-ui builds as a single bundle. A 200KB icon library becomes 200KB added to every page of every app.

**Why it happens:** ev-ui's tsup config has `splitting: false` — all components bundle together without per-component chunking. Named imports from a barrel export do not tree-shake at the library level; tree-shaking happens in the consuming app's bundler (Vite), but only if the library ships proper ESM with `sideEffects: false` in package.json. ev-ui's current package.json does not declare `sideEffects: false`.

**Consequences:** Cloudflare Pages bundle size grows for CompassV2, essentials, and EV-readrank. Core Web Vitals degradation. Unnecessary load time added for pages that do not use icons at all.

**Prevention:**
- Preferred approach: inline SVG icons as React components directly in `PoliticianCard.jsx` and `CategorySection.jsx`. The existing compass icon in `PoliticianCard.jsx` (lines 168-205) already uses this pattern and works well. Add 3-5 more inline SVGs the same way.
- If a library is required for scale, use Lucide React with individual named imports (`import { Building2 } from 'lucide-react'`), which tree-shakes correctly in Vite consumers. Measure bundle impact before committing.
- Never do `import * as Icons from 'lucide-react'` or add a library to ev-ui's `dependencies` that ships as CJS-only.
- Add `"sideEffects": false` to ev-ui's package.json whenever adding new icons to enable consumer tree-shaking.

**Detection:** Run `npm run build` in essentials and check the Vite bundle output for large icon library chunks. Icon library chunks should not appear as large standalone artifacts separate from the component code.

**Phase:** Phase 1 (icon system selection). Decide the approach before writing any icon code.

---

### Pitfall 5: Tier Color Uses Color as the Sole Visual Differentiator (WCAG 1.4.1 Failure)

**What goes wrong:** Using subtle hue tinting (e.g., a faint background wash on the card header or colored border-left) to differentiate federal/state/local tiers without a secondary non-color cue. Color cannot be the **only** visual signal that conveys meaning. If tier is communicated only through background tint, colorblind users cannot distinguish tiers.

**Why it happens:** Designers reach for color as an elegant tier differentiator. The `tokens.js` file includes WCAG contrast notes warning that coral (3.14:1), light blue (2.49:1), and yellow (1.46:1) fail on white for body text. A faint background tint is even lower contrast than the brand colors at full opacity. The W3C explicitly states: if a non-color cue only appears on hover, it is still a failure.

**Consequences:** WCAG 1.4.1 (Use of Color) violation. Civic users who are colorblind cannot distinguish government tiers.

**Prevention:**
- Every tier indicator must have a second non-color differentiator: a text label ("Federal," "State," "Local") or a distinct icon shape, in addition to any color tint.
- Never rely on border-left color or background tint alone. Pair color with shape or text.
- Use the accessible text alternatives from `tokens.js` when any tier text must be readable: teal (`#00657C` at 6.66:1) is the only brand color that passes AA on white without a darkened variant.
- Test with browser devtools grayscale filter — the tiers must still be visually distinct in grayscale.

**Detection:** Apply `filter: grayscale(100%)` via browser devtools to the representatives page. All tier sections must still be distinguishable without color.

**Phase:** Phase 2 (tier hue implementation). Verify accessibility before publishing ev-ui changes.

---

### Pitfall 6: Hover-Only Icon Tooltips Are Inaccessible on Touch Devices

**What goes wrong:** The plan calls for "small subtle icons replacing badges (on ballot, compass available, branch type) with hover details." If the hover tooltip is the only way to understand what an icon means, mobile users (who cannot hover) and keyboard users get an incomplete experience. `CategorySection.jsx` already has a tooltip implemented via `onMouseEnter`/`onMouseLeave` — this pattern works on desktop but provides no feedback on mobile.

**Why it happens:** Hover-first UI patterns are designed on desktop and assumed acceptable for "subtle" indicators. The design goal of "small subtle icons" implies the text label is secondary — but on mobile the icon text is the only meaning available, so it must be accessible without hover.

**Consequences:** Mobile users (likely the majority of civic voters checking their reps on a phone) see icons with no explanation. WCAG 1.4.13 requires hover-triggered content to be dismissible, hoverable, and persistent — but the right fix is ensuring meaning does not require hover at all.

**Prevention:**
- Icons must be self-evident or paired with a visible label below/beside them in the default state.
- For truly icon-only indicators, add `aria-label` and visually-hidden text so screen readers announce the meaning.
- Tooltips should supplement detail ("On ballot: May 6, 2026 Primary") not provide the primary label. The label must be visible without interaction.
- The existing `CategorySection.jsx` tooltip already handles `onFocus`/`onBlur` for keyboard — use it as the baseline pattern.

**Detection:** Test on a real iPhone with Safari. All icon meanings should be clear without tapping or hovering.

**Phase:** Phase 2 (icon implementation). Design the icon+label pairing before coding, not after.

---

### Pitfall 7: Removing "Incumbent" Marker Without Accidentally Removing is_incumbent Branching Logic

**What goes wrong:** The milestone calls for removing the "incumbent" marker from candidate cards. The incumbent/challenger branching in `CandidateProfile.jsx` uses the `is_incumbent` flag to decide whether to render the full politician profile (with CompassCard, legislative data, etc.) or the minimal challenger view. Removing the visual badge does not remove this branching — but if a developer misunderstands the scope and removes the `is_incumbent` prop pass-through as part of the "remove incumbent marker" task, the entire CandidateProfile page breaks.

**Why it happens:** "Remove the incumbent marker" sounds like a simple badge deletion. The word "marker" is ambiguous — it could mean the badge, the prop, or the branching logic. Without explicit scope boundaries, a developer touching `PoliticianCard.jsx` might remove the `badge` prop from the call site in `ElectionsView.jsx` (correct), then continue and remove `is_incumbent` from `CandidateProfile.jsx` routing (incorrect).

**Consequences:** All challenger candidate profiles render with the full legislator template (404 on legislative data fetches, empty CompassCard, broken layout), or all incumbent profiles render as minimal challenger views, hiding their full data.

**Prevention:**
- Explicitly scope the task: "Remove the 'INCUMBENT' badge text from the PoliticianCard `badge` prop passed in ElectionsView.jsx. Do NOT touch CandidateProfile.jsx is_incumbent branching logic."
- Add a comment to `CandidateProfile.jsx` at the `is_incumbent` branch: `// is_incumbent drives full/minimal profile routing — badge display removed in v2026.4.1 but this logic stays`.

**Detection:** After removing the badge, verify that navigating to an incumbent candidate profile still shows the full legislator profile with CompassCard and legislative sections.

**Phase:** Phase 1 (election page changes). Scope this task explicitly before implementation.

---

### Pitfall 8: Compass-First Card Prototype Mutates the Shared PoliticianCard Contract

**What goes wrong:** The "compass-first card prototype (real reps, explore removing photos from results)" implies a significant visual departure from `PoliticianCard`. If the prototype is built by directly modifying `PoliticianCard` in ev-ui rather than creating a new component, it changes the shared component for all pages. The existing `PoliticianCard` with a headshot photo is used on elections, representatives, candidate profiles, and compass compare pages.

**Why it happens:** The path of least resistance is to add a `compassFirst` variant to `PoliticianCard` (it already has `horizontal | vertical` variants). But "explore removing photos" means the new variant has fundamentally different layout assumptions that are hard to express cleanly as a third variant without significant conditional complexity in the component.

**Consequences:** A prototype that becomes hard to undo. ev-ui complexity increases. The existing photo variant may visually regress if the shared style object is modified to accommodate the new variant's different sizing assumptions.

**Prevention:**
- Build the compass-first card as a **new component** in essentials: `CompassFirstCard.jsx` (local component, not in ev-ui). Treat it as a throw-away prototype.
- Only migrate it to ev-ui if the prototype is validated and intended to replace `PoliticianCard` in production.
- Do not add a third variant to `PoliticianCard` until the design is finalized and the prototype decision is made.

**Detection:** After implementing the prototype, verify that `ElectionsView.jsx` and all existing `PoliticianCard` usage still renders identically to before.

**Phase:** Phase 3 (compass-first prototype). Start as a local component, not an ev-ui change.

---

## Minor Pitfalls

Mistakes that cause visual glitches or minor rework but do not break functionality.

---

### Pitfall 9: Headshot Cropping Fix Applied to CDN Images Instead of CSS object-position

**What goes wrong:** The headshot cropping audit may reveal that some headshots look bad because the source is portrait-oriented with space above the head, or a wide landscape image. The impulse is to re-download and re-upload all affected CDN images with a different crop. This creates unnecessary data migration work and risks losing original images.

**Why it happens:** Cropping feels like an image-editing task, not a CSS task.

**Prevention:**
- Use CSS first: `object-fit: cover; object-position: top center` on the `<img>` element covers ~90% of bad headshot crops with one line.
- `PoliticianCard.jsx` already uses `objectFit: 'cover'` with no `objectPosition` set — adding `objectPosition: 'top'` to `styles.image` is a one-line change.
- Only re-upload images if the source image itself is fundamentally broken (corrupted, wrong person, or so poorly framed that CSS cannot salvage it).

**Detection:** After adding `object-position: top`, scan known bad-crop politicians. If faces are still cut off, those specific images may need `object-position: center 20%` or re-upload.

**Phase:** Phase 2 (headshot audit). CSS fix first, image re-upload as last resort.

---

### Pitfall 10: Tailwind Classes in essentials Cannot Override ev-ui Inline Styles

**What goes wrong:** essentials uses Tailwind CSS 4; ev-ui components use JavaScript inline style objects referencing `tokens.js`. When building tier hue differentiation, a developer writes Tailwind classes on a container wrapping an ev-ui component, expecting to style the tier indicator — but ev-ui's inline styles have the highest CSS specificity and silently win over Tailwind utility classes on the same element.

**Why it happens:** ev-ui `CategorySection` and `PoliticianCard` apply styles via JavaScript style objects, which become inline `style=""` attributes in the DOM. Inline styles cannot be overridden by external class-based styles without `!important`. You cannot override ev-ui component internal styles with Tailwind classes from essentials.

**Consequences:** Tier color tinting appears to have no effect, or requires `!important` hacks that create long-term maintenance debt.

**Prevention:**
- Use the `style` prop that `CategorySection` already accepts: `<CategorySection style={{ borderLeftColor: tierColor }}>`. This merges correctly with the component's internal styles.
- If a tier-color prop is needed in `PoliticianCard`, add it as an explicit named prop (e.g., `tierAccent`) that the component internally applies — do not rely on consumers wrapping with Tailwind classes.
- Never use `!important` to override ev-ui component internals.

**Detection:** Open DevTools and inspect the element. If a style appears in the `style=""` attribute it is from ev-ui inline styles and cannot be overridden by Tailwind from outside the component.

**Phase:** Applies across all phases where tier color is added to ev-ui components.

---

### Pitfall 11: New Icons Added to ev-ui Without Recording Them in the Design System

**What goes wrong:** New icons added to ev-ui for this milestone (on-ballot indicator, compass-available indicator, branch-type indicator) are implemented as inline SVG React components but never documented in the Penpot design system. Future design work does not know these icons exist in the codebase, leading to inconsistent icon choices in future milestones.

**Why it happens:** The dev-to-design sync is optional and easily skipped under time pressure. The `sync-penpot` script exists (`npm run sync-penpot`) but only syncs tokens, not icon components.

**Prevention:**
- After finalizing new icons, add a comment block in the component file naming each icon and its intended usage context.
- If inline SVGs stay in `PoliticianCard.jsx`, note: `// Icon: CompassAvailableIcon — shown when onCompassClick prop is present`.
- Add icon names and usage to the next Penpot design system update.

**Detection:** After shipping, confirm a designer starting fresh can identify all icon assets used across the platform without reading source code.

**Phase:** Phase 1 wrap-up, before publishing ev-ui changes.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Icon system selection | Bundle bloat from icon library added to ev-ui | Use inline SVG components (follow existing PoliticianCard compass icon pattern) — 4-5 icons do not need a library |
| Tier hue design | Inadvertent partisan color associations | Use teal lightness scale only; run antipartisan color check before implementation |
| PoliticianCard tier-color prop | Breaking all three consumer apps | Add as optional prop with safe null/undefined fallback; test without prop first |
| Removing "incumbent" badge | Accidentally removing is_incumbent branching in CandidateProfile | Scope task to badge text removal only; add code comment to CandidateProfile branching |
| Compass-first card prototype | Mutating shared PoliticianCard contract | Build as local CompassFirstCard.jsx in essentials, not as ev-ui variant |
| Headshot cropping audit | Re-uploading 503 images unnecessarily | CSS object-position fix first; re-upload only for fundamentally broken source images |
| Icon tooltips | Hover-only meaning inaccessible on mobile | Pair every icon with visible text label or aria-label; tooltip provides detail, not the primary label |
| buildTitleAndSubtitle() | Logic drift between ev-ui and essentials copies | Dual-edit policy: any touch to title logic updates both files in same commit |
| ev-ui publish | Consumers pulling latest, breaking builds | Bump version consciously; verify optional-prop fallback renders safely before publish |
| Tier color contrast | Faint tints failing WCAG 1.4.1 | Verify with grayscale filter; always pair color with shape or text label |
| Tailwind + inline style conflict | Consumer Tailwind classes silently losing to ev-ui inline styles | Use ev-ui's `style` prop pass-through or add explicit named props; never rely on external class overrides |

---

## Sources

- WCAG 1.4.1 Use of Color: [W3C Understanding SC 1.4.1](https://www.w3.org/WAI/WCAG21/Understanding/use-of-color.html)
- WCAG 1.4.13 Content on Hover or Focus: [W3C](https://www.w3.org/WAI/WCAG21/Understanding/content-on-hover-or-focus.html)
- Color-only failure, hover cue still fails: [W3C F73](https://www.w3.org/TR/WCAG20-TECHS/F73.html)
- Icon tooltip accessibility: [Accessibly Blog](https://accessiblyapp.com/blog/tooltip-accessibility/)
- tsup tree-shaking guide: [dorshinar.me](https://dorshinar.me/posts/treeshaking-with-tsup)
- Lucide React bundle benchmarks: [CodeToDeploy/Medium](https://medium.com/codetodeploy/the-hidden-bundle-cost-of-react-icons-why-lucide-wins-in-2026-1ddb74c1a86c)
- Component library versioning pitfalls: [Antler Digital](https://antler.digital/blog/best-practices-for-component-versioning-in-react)
- USWDS color design for civic apps: [USWDS Color Overview](https://designsystem.digital.gov/design-tokens/color/overview/)
- ev-ui tokens: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/tokens.js`
- ev-ui PoliticianCard: `/Users/chrisandrews/Documents/GitHub/ev-ui/src/PoliticianCard.jsx`
- ev-ui tsup config: `/Users/chrisandrews/Documents/GitHub/ev-ui/tsup.config.js`
- Antipartisan principle: project MEMORY.md (feedback_antipartisan.md)
