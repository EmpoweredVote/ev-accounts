# Phase 114 — UX Walkthrough Methodology

**Run date:** 2026-04-13
**Phase:** 114-ux-walkthrough

**Purpose:** Lock persona, address, environment, severity/type definitions, and antipartisan omissions BEFORE any walkthrough runs. This is the fairness mechanism — there is no separate peer-review checkpoint. Every gap entry in plans 02–06 must trace back to the definitions here. Mirrors Phase 113's `benchmark/METHODOLOGY.md` pattern: write the ruler first, then run the measurements.

---

## 1. Persona

Single primary persona:

> **A naive first-time Monroe County, IN voter with no prior knowledge of Empowered Vote or any competitor, entering each app cold.**

Per CONTEXT D-01: **"No student/rural personas in this phase — deferred."** If the Kirkwood walkthrough surfaces district-boundary or demographic-specific friction, Phase 115 may recommend a follow-on walkthrough phase with additional personas in a future milestone — but they are out of scope here.

---

## 2. Address

**`200 W Kirkwood Ave, Bloomington, IN 47404`**

Rationale: same address used by Phase 112's geofence smoke test and Phase 113's benchmark primary. Holding the input constant across three phases means any experience divergence is attributable to the product, not to input variance.

---

## 3. Environment

Walkthrough runs against **production**, not local dev, per CONTEXT D-03.

Live production URLs:

- **Essentials** — https://essentials.empowered.vote/
- **Compass** — https://compass.empowered.vote/
- **Read & Rank** — https://readrank.empowered.vote/
- **Treasury Tracker** — https://treasurytracker.empowered.vote/

> Unreleased-but-merged work is deliberately NOT credited. Phase 115's tiered report is about what must ship before May 5, and prod is the honest baseline.

---

## 4. Run Date

**2026-04-13**

---

## 5. Severity Definitions (per CONTEXT D-10)

Every gap is tagged on a 3-level severity axis:

| Severity | Definition |
|----------|------------|
| `blocker` | Voter cannot complete the flow, or the flow returns wrong info. |
| `confusing` | Voter can complete it, but the experience is unclear, mislabeled, or unexpectedly empty. |
| `minor` | Cosmetic, copy polish, nice-to-have. |

**Worked examples:**

- `blocker` — *"Address input on Essentials accepts `200 W Kirkwood Ave, Bloomington, IN 47404` but the Results page shows zero federal-tier politicians. Voter gets wrong info about who represents them."*
- `confusing` — *"Compass compare page shows a dual-overlay radar, but the second politician is labeled only by last name, with no office or district context. Voter can complete the comparison but can't tell which race the candidate is running in."*
- `minor` — *"Read & Rank landing page has inconsistent button padding between desktop and mobile breakpoints. Non-blocking, cosmetic polish."*

---

## 6. Type Definitions (per CONTEXT D-10)

Every gap is also tagged on an orthogonal 4-value type axis so Phase 115 can sort either way:

| Type | Definition |
|------|------------|
| `data` | The field exists in the UI but the DB row is missing or wrong. |
| `feature` | The UI itself is missing a capability a voter would expect. |
| `content` | Copy, framing, or labeling problem. |
| `ux-friction` | Flow, nav, state, or interaction friction. |

**Worked examples:**

- `data` — *"Essentials politician card for the Indiana House District 62 seat has an empty `bio_text` field — the UI renders the placeholder container but no biography. (baseline_ref: IN-HD-62 row in BALLOT-BASELINE-2026-05-05.md)"*
- `feature` — *"Compass has no way to filter the politician picker to only Monroe County contested May 5 races — voter must scroll the full state list."*
- `content` — *"Essentials labels the Election Central section `Elections` with no sub-heading explaining what a voter should do there — voter doesn't know the difference between Elections and Representatives."*
- `ux-friction` — *"Back button from Essentials politician profile returns to a blank results page, forcing the voter to re-enter their address."*

---

## 7. Gap Entry Schema (per CONTEXT D-11)

Each gap entry in `GAPS.md` MUST have these 8 required fields, in this order:

1. **`id`** — Stable gap ID in format `G-114-NNN`, zero-padded, **monotonic across the whole phase** (not per-app). Plan 114-07 validates monotonicity.
2. **`app`** — Enum: `essentials | compass | read-rank | treasury | cross-app`
3. **`screen`** — Screen label + production URL at time of walk.
4. **`description`** — One-line statement of the gap.
5. **`severity`** — Enum: `blocker | confusing | minor`
6. **`type`** — Enum: `data | feature | content | ux-friction`
7. **`evidence`** — Pointer to screenshot filename (relative path under `screenshots/{app}/`) OR short verbatim excerpt (console log, empty-state copy, etc.).
8. **`baseline_ref`** — REQUIRED when `type=data`, points to a specific row in `BALLOT-BASELINE-2026-05-05.md` so Phase 115 can count the gap against the denominator. `n/a` for non-data gaps.

---

## 8. Intentional Omissions — Antipartisan (per CONTEXT D-14)

> **The following absences are INTENTIONAL per EV's antipartisan principle and MUST NOT be logged as gaps in any walkthrough:**

- Missing **party labels** (D / R / I) on candidate cards, search results, or profile pages.
- Missing **endorsement lists** (newspaper endorsements, political committee endorsements, advocacy-group endorsements).
- Missing **interest-group ratings** (NRA scores, Sierra Club scores, Chamber of Commerce ratings, any third-party advocacy scorecard).

> If a walkthrough task logs one of these as a gap, it is a methodology violation and must be removed during Plan 114-07 aggregation.

This mirrors Phase 113's fairness framing (benchmark D-10) — the ruler declares what is NOT on the ruler so scoring stays consistent across apps.

---

## 9. "Done" Criteria Per App

Each walkthrough plan is complete only when its per-app criteria are exercised. Empty / error / back-nav states count toward "done."

### Essentials (UX-01, Plan 114-02)
1. Address entered at `/`
2. Results hierarchy reviewed (federal / state / local tiers)
3. Election Central section viewed
4. At least one representative card opened
5. At least one candidate profile opened — **incumbent AND challenger** if both present
6. Legislative activity sections surveyed (committees, bills, votes, CompassCard, Read & Rank verdict badges under StanceAccordion)
7. Empty / error / back-nav states probed

### Compass (UX-02, Plan 114-03)
1. Guest entry at `/`
2. Onboarding screens walked
3. Topic selection
4. Full quiz run
5. Compare page reached
6. Politician picker filtered to Monroe County candidates
7. Dual-overlay radar rendered vs at least one Monroe County candidate

Framing question (per D-06): *"Can a Monroe County voter meaningfully use Compass to compare candidates in the May 5 contested races?"*

### Read & Rank (UX-03, Plan 114-04)
1. Landing page
2. Candidate filter by Monroe County / by race
3. At least one quote evaluation
4. Verdict flow-back to Essentials attempted (guest path via URL fragment)

Framing question (per D-07): *"Are there enough sourced quotes for Monroe County primary candidates for the tool to be useful, and does candidate filtering actually surface them?"*

### Treasury (UX-04, Plan 114-05)
**Relevance check FIRST, per D-08:**
- **Step 1:** Does Treasury have ANY Monroe County or Bloomington budget data?
- **Step 2a:** If YES → full walkthrough (landing → municipality select → budget categories → line items → budget-vs-actual).
- **Step 2b:** If NO → log **one** top-level gap (`"Treasury has no Monroe/Bloomington data — not useful in Monroe election context"`) and STOP. Do NOT pad with an empty-state narrative — the absence itself is the finding.

### Cross-app (D-09, Plan 114-06)
Stitching-level pass, run AFTER per-app walks are complete so the voter has context:
1. SiteHeader cross-app nav (auth state + destinations)
2. Essentials politician profile → CompassCard hand-off
3. Essentials politician profile → Read & Rank verdict badges under StanceAccordion
4. Compass politician picker → candidate records
5. Any Essentials → Treasury hand-off (if one exists)

Cross-app friction is logged with `app=cross-app`.

---

## 10. Execution Method (per CONTEXT D-04)

**Primary:** `plugin_playwright` MCP tools drive the apps:
- `mcp__plugin_playwright_playwright__browser_navigate`
- `mcp__plugin_playwright_playwright__browser_snapshot`
- `mcp__plugin_playwright_playwright__browser_take_screenshot`
- `mcp__plugin_playwright_playwright__browser_click`
- `mcp__plugin_playwright_playwright__browser_fill_form`

**Fallback (same hybrid rule as Phase 113 D-01):** Where Playwright cannot complete a step (auth wall, Google Maps Places picker behavior, captcha, client-only interactions), the walker writes a short "human leg" with:
- Exact URL
- Exact form values
- What to screenshot

…pauses, and resumes on paste-back.

---

## 11. Output Artifacts (per CONTEXT D-12, D-13)

All artifacts live under `.planning/research/ux-walkthrough/`, mirroring Phase 113's `.planning/research/benchmark/` layout so Phase 115 can read both with a single directory walk.

```
.planning/research/ux-walkthrough/
  METHODOLOGY.md          # This file
  essentials.md           # Plan 114-02 narrative + inline gap references
  compass.md              # Plan 114-03
  read-rank.md            # Plan 114-04
  treasury.md             # Plan 114-05 — relevance check + conditional walkthrough
  cross-app.md            # Plan 114-06 integration pass
  GAPS.md                 # FLAT aggregated list of ALL G-114-* entries (Phase 115's primary input)
  gaps.csv                # Machine-readable mirror of GAPS.md
  screenshots/
    essentials/
    compass/
    read-rank/
    treasury/
    cross-app/
```

---

*Written 2026-04-13 before any walkthrough session. Locks the ruler for Plans 114-02 through 114-07.*
