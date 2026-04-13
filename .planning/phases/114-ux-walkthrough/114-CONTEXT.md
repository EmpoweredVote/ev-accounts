# Phase 114: UX Walkthrough - Context

**Gathered:** 2026-04-12
**Status:** Ready for planning

<domain>
## Phase Boundary

Walk a first-time Monroe County IN voter through each live Empowered Vote app (Essentials, Compass, Read & Rank, Treasury) and document the experience screen-by-screen, logging every gap, missing piece, and confusing moment as a structured, classified entry that Phase 115 can synthesize into a tiered gap report. Output is research artifacts only — no code changes, no DB changes, no frontend changes. The walkthrough runs against production (live `*.empowered.vote` domains), uses a single primary persona at `200 W Kirkwood Ave, Bloomington, IN 47404`, and covers the cross-app links that stitch the apps together.

</domain>

<decisions>
## Implementation Decisions

### Persona & Journey Depth
- **D-01:** Single primary persona — a naive first-time Monroe County voter entering at `200 W Kirkwood Ave, Bloomington, IN 47404`. Same address as Phase 112's geofence smoke test and Phase 113's benchmark primary, so divergences are attributable to the product and not input variance. No student/rural personas in this phase — if those journeys expose distinct gaps, note them as deferred for a future walkthrough phase.
- **D-02:** Every screen the voter can naturally reach from entry to a "done" state is walked — not just key decision screens. The phase goal explicitly says "reviewing each screen (results, election central, representative cards, candidate profiles)" — take that literally. Mid-flow friction (empty states, loading states, error states, back-button behavior) is in scope.

### Execution Method & Environment
- **D-03:** Walkthrough runs against **production** — the live `empowered.vote` / `essentials.empowered.vote` / `compass.empowered.vote` / `readrank.empowered.vote` / `treasurytracker.empowered.vote` domains. Rationale: Phase 115 produces a tiered gap report for what must ship **before** the May 5 primary, so the honest baseline is what a voter sees today in prod. Unreleased-but-merged work is deliberately *not* credited.
- **D-04:** Execution method inherits Phase 113's pattern: `plugin_playwright` MCP tools drive the apps (`browser_navigate`, `browser_snapshot`, `browser_take_screenshot`, `browser_click`, `browser_fill_form`). Where Playwright can't complete a step (auth wall, Google Maps Places picker behavior, captcha, client-only interactions), Claude writes a short "human leg" with exact URL, form values, and what to screenshot, pauses, and resumes on paste-back. Same hybrid rule as 113 D-01.

### Scope Per App
- **D-05:** **Essentials** — full walkthrough (UX-01). Address entry → results hierarchy (federal/state/local tiers) → Election Central → representative cards → candidate profile pages (incumbent branch + challenger branch) → legislative activity sections (committees, bills, votes, CompassCard, Read & Rank verdict badges) → back-navigation and empty/error states. Cross-check each race against `BALLOT-BASELINE-2026-05-05.md` and `AUDIT-REPORT-112.md` to distinguish "voter-facing gap" from "already-known DB gap."
- **D-06:** **Compass** — full walkthrough (UX-02) framed as "can a Monroe County voter meaningfully use Compass to compare candidates in the May 5 contested races?" Guest-first entry → onboarding → topic selection → quiz → compare page → politician picker with Monroe County candidate filtering → dual-overlay radar vs a Monroe candidate. Stance data availability is audited per race in the baseline, not as a generic catalog count.
- **D-07:** **Read & Rank** — full walkthrough (UX-03) framed as "are there enough sourced quotes for Monroe County primary candidates for the tool to be useful, and does candidate filtering actually surface them?" Landing → candidate filter (by county / by race) → quote evaluation → verdict flow-back to Essentials (URL fragment for guests, server-side for logged-in). Coverage measured against the baseline candidate list, not against the full universe.
- **D-08:** **Treasury** — relevance-check-first, walkthrough-conditional (UX-04). Step 1: is there ANY Monroe County or Bloomington budget data in the treasury schema / treasurytracker app? Step 2: if yes, full walkthrough; if no, log one top-level gap ("Treasury has no Monroe/Bloomington data — not useful in Monroe election context") and stop. The absence itself is the finding.
- **D-09:** **Cross-app integration pass** — one additional short pass that follows the key stitching links: SiteHeader cross-app nav (auth state + destinations), politician profile → CompassCard, politician profile → Read & Rank verdict badges under StanceAccordion, Compass politician picker → candidate records, and any Essentials → Treasury hand-off if one exists. Logged in its own `cross-app.md` file. Does NOT merge the apps into a single continuous journey — each app is still evaluated independently against UX-01..04 first.

### Gap Classification
- **D-10:** Every gap is tagged on two orthogonal axes so Phase 115 can sort either way:
  - **Severity:** `blocker` (voter can't complete the flow or the flow returns wrong info) | `confusing` (voter can complete it but the experience is unclear, mislabeled, or unexpectedly empty) | `minor` (cosmetic, copy polish, nice-to-have)
  - **Type:** `data` (the field exists in the UI but the DB row is missing or wrong) | `feature` (the UI itself is missing a capability a voter would expect) | `content` (copy, framing, or labeling problem) | `ux-friction` (flow, nav, state, or interaction friction)
- **D-11:** Each gap entry has these required fields:
  - `id` — stable gap ID `G-114-NNN` (zero-padded, monotonic across the whole phase, not per-app) so Phase 115 can cite back.
  - `app` — one of `essentials | compass | read-rank | treasury | cross-app`
  - `screen` — screen label + URL (production URL at time of walk)
  - `description` — one-line statement of the gap
  - `severity` — one of `blocker | confusing | minor`
  - `type` — one of `data | feature | content | ux-friction`
  - `evidence` — pointer to the screenshot filename (relative path under `screenshots/{app}/`) OR a short verbatim excerpt (console log, empty state copy, etc.)
  - `baseline_ref` — optional: if the gap is about missing data, reference the specific baseline race/candidate from `BALLOT-BASELINE-2026-05-05.md` so Phase 115 can count it.

### Output Structure & Location
- **D-12:** All artifacts live under `.planning/research/ux-walkthrough/`, consistent with Phase 113's `.planning/research/benchmark/` layout so Phase 115 reads both with one directory walk.
- **D-13:** File layout:
  ```
  .planning/research/ux-walkthrough/
    METHODOLOGY.md          # Address, persona, environment (prod), date run, severity/type definitions, what "done" means per app
    essentials.md           # Full screen-by-screen narrative + inline gap references
    compass.md
    read-rank.md
    treasury.md             # Relevance check result + conditional walkthrough
    cross-app.md            # Integration pass — SiteHeader, profile→compass, profile→readrank, etc.
    GAPS.md                 # FLAT aggregated list of ALL G-114-* entries with all required fields — this is Phase 115's primary input
    gaps.csv                # Machine-readable mirror of GAPS.md (same column convention as 113's matrix.csv)
    screenshots/
      essentials/
      compass/
      read-rank/
      treasury/
      cross-app/
  ```
- **D-14:** `METHODOLOGY.md` is written BEFORE the walkthroughs start and opens the output. Mirrors 113 D-10's fairness framing: documents the exact address, the persona, the environment (prod), the date, the severity/type definitions with worked examples, and an explicit "intentional omissions" section (antipartisan — no party labels, no endorsements, no interest-group ratings) so Phase 115 does not misclassify those as data gaps.

### Claude's Discretion
- Exact screen ordering within each app walkthrough (bounded by D-02 "every reachable screen")
- Screenshot filenames and count per screen
- Narrative depth per screen (where to linger vs summarize)
- Whether `gaps.csv` is a direct mirror of `GAPS.md` or a normalized long-form table (same latitude as 113 D-05)
- Exact set of cross-app links to follow in `cross-app.md` (bounded by D-09 — must cover SiteHeader, profile→CompassCard, profile→Read&Rank verdict badges)
- How to handle ambiguous severity calls — document the call inline in `GAPS.md` with a one-line reason

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before researching or planning.**

### Phase 112 Outputs (the baseline denominator)
- `.planning/research/BALLOT-BASELINE-2026-05-05.md` — Authoritative Monroe County May 5, 2026 primary race and candidate list. Every `data` gap in this phase must tie back to a specific row here so Phase 115 can count it.
- `.planning/research/AUDIT-REPORT-112.md` — EV's measured DB coverage against the baseline. Used to distinguish "voter-facing gap" from "already-audited DB gap" during the Essentials walkthrough.
- `.planning/phases/112-data-completeness-audit/112-CONTEXT.md` — Prior phase's decision patterns (markdown + CSV output, structured fields per entry).

### Phase 113 Outputs (the pattern template)
- `.planning/research/benchmark/METHODOLOGY.md` — Template for 114's `METHODOLOGY.md` (address, environment, scoring definitions, intentional omissions).
- `.planning/research/benchmark/MATRIX.md` + `matrix.csv` — Pattern for `GAPS.md` + `gaps.csv` pairing.
- `.planning/phases/113-competitive-benchmarking/113-CONTEXT.md` — Playwright-first + human fallback execution pattern (D-01), fairness framing (D-10), same primary address (D-08).

### Requirements
- `.planning/REQUIREMENTS.md` — UX-01 through UX-04 definitions (per-app walkthrough requirements) + GAP-01..03 (what Phase 115 will do with this output).

### Project Principles
- `.planning/PROJECT.md` — Antipartisan principle (no party labels, endorsements, interest-group ratings) — drives D-14's intentional omissions section.
- `CLAUDE.md` (workspace root) — App descriptions and production URLs for each of the four apps.

### Tooling
- `plugin_playwright` MCP tools (`browser_navigate`, `browser_snapshot`, `browser_take_screenshot`, `browser_click`, `browser_fill_form`) — primary execution path per D-04.

### Live Production Entry Points (per D-03)
- Essentials — https://essentials.empowered.vote/
- Compass — https://compass.empowered.vote/
- Read & Rank — https://readrank.empowered.vote/
- Treasury Tracker — https://treasurytracker.empowered.vote/
- Backend API — https://api.empowered.vote/

### Codebase Orientation (for interpreting observed behavior)
- `.planning/codebase/STRUCTURE.md`, `.planning/codebase/STACK.md`, `.planning/codebase/CONVENTIONS.md` — Workspace layout so walker can tie a UI observation to the owning project.
- `essentials/src/pages/Results.jsx` — Address search + progressive loading + tier classification (what Essentials renders after address entry).
- `essentials/src/pages/Profile.jsx` + `ev-ui/src/PoliticianProfile.jsx` — Politician profile rendering, CompassCard integration, Read & Rank verdict badges under StanceAccordion.
- `ev-accounts/backend/src/lib/essentialsService.ts` — Geofence resolution (the backend path that produces the Essentials results for a given address).

</canonical_refs>

<code_context>
## Existing Code Insights

This is a research/documentation phase walking production — no application code is produced. The "code" is:
- `plugin_playwright` MCP tool invocations (no persistent scripts required — one-shot browser sessions per app)
- Markdown + CSV artifact generation under `.planning/research/ux-walkthrough/`

### Reusable Patterns from Phases 112 and 113
- Markdown + CSV pairing (`GAPS.md` ↔ `gaps.csv`, mirrors 113's `MATRIX.md` ↔ `matrix.csv`)
- Per-dimension structured output Phase 115 can mechanically read
- Research artifacts co-located under `.planning/research/` for single-directory cross-phase consumption
- METHODOLOGY.md written first as the fairness/framing anchor
- Same primary address across 112, 113, 114 — controlled comparison

### Not Applicable
- No DB queries — this phase reads the UI, not the DB. Phase 112's audit report is the DB side; Phase 114 is the voter's side.
- No backend routes, no frontend changes, no new dependencies.
- No Playwright scripts committed to the repo — all Playwright calls are ephemeral MCP tool invocations inside the walkthrough session.

### Relevant Orientation Points (for tying UI observations back to code)
- Essentials tier classification lives in `essentials/src/lib/classify.js` — useful if a voter-side "why is this in the wrong tier?" gap shows up.
- Politician profile dual-render (incumbent full profile vs challenger minimal view) in `ev-ui/src/PoliticianProfile.jsx` — relevant for UX-01's candidate profile screens.
- Cross-app verdict flow: Read & Rank → Essentials via URL fragment (guest) or server-side (logged-in) — relevant for D-09 cross-app pass.

</code_context>

<specifics>
## Specific Ideas

- Primary address is `200 W Kirkwood Ave, Bloomington, IN 47404` — same as Phase 112 geofence smoke test and Phase 113 benchmark primary, so any experience divergence is attributable to the product and not input variance.
- Environment is **production**, not local dev. Unreleased-but-merged work is deliberately not credited — Phase 115's tiered report is about what must ship before May 5, and prod is the honest baseline.
- Gap IDs are monotonic across the whole phase (`G-114-001`, `G-114-002`, …) — not per-app — so Phase 115 can reference any gap without collision.
- Every `data`-type gap must reference a specific row in `BALLOT-BASELINE-2026-05-05.md` via the `baseline_ref` field, so Phase 115 can count coverage.
- Antipartisan omissions (no party labels, no endorsements, no interest-group ratings) are documented in `METHODOLOGY.md` as intentional, not logged as gaps in any app.
- Treasury is a special case: a relevance check gates a conditional walkthrough. Absence of Monroe/Bloomington budget data is itself the finding — document it as one top-level gap and stop walking, don't pad with an empty-state narrative.

</specifics>

<deferred>
## Deferred Ideas

- **Additional personas (IU student, rural township voter).** Considered during discussion, intentionally deferred — a single primary persona keeps this phase comparable to 112/113 and bounded in scope. If the Kirkwood walkthrough exposes district-boundary or demographic-specific friction, Phase 115 can recommend a follow-on walkthrough phase with additional personas in a future milestone.
- **Local dev vs production diff pass.** The "prod primary + local dev deltas noted" option was rejected for this phase to keep scope tight. If Phase 115 discovers that fixes have landed on main but not deployed, that becomes a deploy-cadence concern, not a UX-walkthrough scope item.
- **Fully integrated single-session voter journey.** Rejected in favor of "each app independent + one cross-app pass" — easier to map findings back to the per-app UX-01..04 requirements and easier for Phase 115 to Tier 1/Tier 2 sort. A fully stitched journey audit is a candidate for a future milestone once Tier 1 gaps are closed.

</deferred>

---

*Phase: 114-ux-walkthrough*
*Context gathered: 2026-04-12*
