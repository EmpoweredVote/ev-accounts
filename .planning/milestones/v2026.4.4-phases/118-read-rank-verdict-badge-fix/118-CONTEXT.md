# Phase 118: Read & Rank Verdict Badge Fix - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Diagnose why existing DB verdicts (10 Pierce quotes) are not rendering as badges on
politician profile pages in production, land a minimal fix, and capture a brief root
cause note in the fix PR. Scope is limited to the verdict badge render path — not a
broader Read & Rank feature rework (that belongs to later phases).

**In scope:**
- Investigation across DB → `/compass/verdicts` API → `CompassContext` → `CompassCard`
  prop wiring → `ev-ui/StanceAccordion` render → CSS
- Code fix in whichever layer the root cause lands (ev-ui, essentials, backend, or data)
- Production verification on the Pierce test URL(s)

**Out of scope:**
- Read & Rank location filter (Phase 119)
- Cross-app loop polish (Phase 122)
- Any verdict feature expansion beyond "badges render when data exists"

</domain>

<decisions>
## Implementation Decisions

### Reproduction & Baseline
- **D-01:** Reproduce **on production first** (essentials.empowered.vote) — RR-01 is
  phrased "in production", and prod is the fastest source of truth for "is it still broken".
- **D-02:** Test **both authed and guest paths** — it is not known which path the
  10 Pierce verdicts live on, so each path must be verified independently before
  assuming the other works.
- **D-03:** Two candidate Pierce test URLs (user unsure which is the intended profile
  surface for RR-01):
  - Candidate URL: `https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa`
  - Politician URL: `https://essentials.empowered.vote/politician/72dd5219-490f-48bb-986e-183a6098d602`
  Research/plan step should inspect both, identify which one the 10 quotes attach to,
  and treat that as the primary RR-01 verification surface (verify the other for parity).
- **D-04:** No known-good baseline — use `git log` / ev-ui npm version history if
  needed to find the last version where the verdict render path was intact.

### Investigation Scope
- **D-05:** **Hypothesis-first** investigation — start with the most likely culprit
  (e.g. ev-ui version mismatch, prop wiring drift, CSS opacity/visibility regression,
  or API response shape change) rather than a full top-to-bottom trace. Escalate to
  layer-by-layer bisection only if the hypothesis fails.
- **D-06:** Likely hypotheses to consider, in rough priority order:
  1. `ev-ui` version on essentials older than the StanceAccordion revision that
     introduced `verdictsByQuote` rendering (check `essentials/package.json`)
  2. `CompassCard.jsx` not passing `verdictsByQuote` for the non-authed render branch
     (two `StanceAccordion` call sites at `CompassCard.jsx:321` and `:415`)
  3. `fetchUserVerdicts()` / `loadGuestVerdicts()` returning `{}` when they should
     return keyed verdicts (shape or quote_id mismatch)
  4. Backend `/compass/verdicts` not returning Pierce rows for the tested account
  5. CSS/display regression on the verdict badge in `StanceAccordion.jsx`
- **D-07:** **Follow through after finding the first cause** — once a break is found
  and fixed, verify the remaining suspect layers are NOT also broken. Explicitly
  rule out compounding regressions before declaring the phase done.
- **D-08:** **No time budget** — quality of the fix and confidence in the RCA matter
  more than speed. Take the time the investigation needs.
- **D-09:** RR-02 deliverable = a **brief root cause note in the fix PR description**
  (not a standalone RCA doc, not a full 5-whys). Required content: what broke, which
  layer, commit that introduced it (if identifiable), one-line fix summary.

### Fix Blast Radius
- **D-10:** All four layers are in-scope for code changes: `ev-ui/StanceAccordion`,
  `essentials` wiring (`CompassCard.jsx`, `CompassContext.jsx`, `lib/compass.js`),
  backend `/compass/verdicts` route/service, and DB/data repair on the Pierce rows
  if the data itself is malformed. Fix lands in whichever layer the root cause is in.
- **D-11:** If the fix lands in `ev-ui`, ship via the **standard auto-bump pipeline**
  (`npm version patch` → git tag → GitHub Action → OIDC publish → repository_dispatch →
  consumer auto-merge on patch). No manual consumer cherry-picks.
- **D-12:** An ev-ui bump propagates to **all 4 consumers** (CompassV2, essentials,
  read-rank, civic-spaces) — do not attempt to scope the bump to essentials only.

### Verification & Sign-off
- **D-13:** RR-01 proof = **visual confirmation on the production Pierce profile
  URL**. Screenshot or DOM evidence of ≥1 verdict badge rendering on the identified
  Pierce profile at essentials.empowered.vote is sufficient. No automated test is
  required for this phase.
- **D-14:** Verification happens **in production only** — local dev is fine for
  development iteration, but the final proof must come from essentials.empowered.vote
  after the Render deploy completes.
- **D-15:** Verify **both authed and guest paths** render verdicts once the fix is
  deployed, regardless of which path Pierce lives on — prevents a second regression
  from shipping undetected.
- **D-16:** **User does final sign-off** — user opens the Pierce URL and confirms
  badges are visible before RR-01 is marked complete.

### Claude's Discretion
- Exact diagnostic commands, SQL queries, and component inspection steps used during
  the hypothesis-first investigation.
- How to instrument the authed vs guest paths for comparison (logging, devtools,
  scripted API calls — any approach that surfaces the break).
- Choice of which Pierce URL (candidate vs politician) becomes the canonical RR-01
  verification surface, based on which one has the 10 quotes attached.
- Whether to add a defensive assertion or dev-mode warning when `verdictsByQuote`
  is empty but stance rows exist, as a follow-up preventive measure.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap & Requirements
- `.planning/ROADMAP.md` §"Phase 118" — phase goal and success criteria
- `.planning/REQUIREMENTS.md` RR-01, RR-02 — acceptance criteria

### Verdict Render Path (code)
- `ev-ui/src/StanceAccordion.jsx` — consumes `verdictsByQuote` prop; render logic at
  lines 329–395 (verdict icons keyed by `quote.id`)
- `essentials/src/components/CompassCard.jsx` §321, §415 — two `StanceAccordion`
  call sites, both pass `verdictsByQuote={verdicts}`
- `essentials/src/contexts/CompassContext.jsx` §149–161 — verdict priority:
  API > fragment > localStorage > empty
- `essentials/src/lib/compass.js` §237 `loadGuestVerdicts`, §262 `fetchUserVerdicts`
  — guest/authed verdict sources; shape is `{ [quote_id]: 'agreed' | 'disagreed' }`

### Backend
- `ev-accounts/backend/src/lib/compassService.ts` — compass topics/answers/verdicts
  business logic (primary service layer)
- `ev-accounts/backend` routes under `/api/compass/*` — verdicts endpoint lives here

### Release Pipeline (if ev-ui fix is needed)
- `ev-ui/README-AUTOBUMP.md` — full auto-bump pipeline docs (release flow,
  repository_dispatch, consumer auto-merge)
- `ev-ui/.github/workflows/publish.yml` — OIDC publish + dispatch
- `essentials/.github/workflows/ev-ui-bump.yml` — consumer auto-merge workflow

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`StanceAccordion` (ev-ui)** — already has a working `verdictsByQuote` render
  branch (added previously, per the `verdictsByTopic` DEPRECATED comment). Fix is
  almost certainly NOT "build the render" but "restore the data path to it".
- **`fetchUserVerdicts()` / `loadGuestVerdicts()`** — helpers exist and return the
  correct `{ [quote_id]: verdict }` shape. Check whether they are being called and
  whether the returned map has the expected keys for the Pierce test account.
- **Auto-bump pipeline** — mature enough that an ev-ui patch release costs one
  `npm version patch` push; no manual coordination across consumers.

### Established Patterns
- **`verdictsByTopic` is DEPRECATED** — comment at `StanceAccordion.jsx:31` says so.
  Only `verdictsByQuote` is rendered today. Any code still passing `verdictsByTopic`
  is a dead-end and should not be "fixed" in isolation.
- **Verdict priority chain** — `CompassContext` loads verdicts with explicit priority
  (authed API → fragment → localStorage → empty). A bug in any link of that chain
  collapses verdicts to `{}` silently.
- **Two call sites in `CompassCard.jsx`** — both must be inspected. A fix applied
  to only one call site would half-fix the symptom.

### Integration Points
- `CompassCard` is where essentials connects to `ev-ui` — prop drift between the
  two repos is the highest-leverage suspect.
- `/api/compass/verdicts` is the authed entry point; a guest user never hits it.
- The quote IDs keyed in `verdictsByQuote` must match the `quote.id` values on the
  stance rows inside `StanceAccordion` — an ID drift (e.g. string vs UUID, casing,
  or a Read & Rank schema change) would silently blank all badges.

</code_context>

<specifics>
## Specific Ideas

- Pierce test URLs (user-provided, unsure which is canonical):
  - `https://essentials.empowered.vote/candidate/7e768cda-38f3-4511-ad7c-c8e877c5abfa`
  - `https://essentials.empowered.vote/politician/72dd5219-490f-48bb-986e-183a6098d602`
- Expected state: 10 Pierce quotes in the DB should surface as verdict badges for
  accounts/guests who have cast verdicts on them.
- RR-02 lists 4 candidate root cause categories explicitly: "CSS, prop wiring,
  ev-ui version mismatch, or feature flag". Investigation should resolve which one.

</specifics>

<deferred>
## Deferred Ideas

- **Automated regression test for verdict badge render** — nice-to-have, not
  required for RR-01. Could become a follow-up phase if badges regress again.
- **Dev-mode warning when `verdictsByQuote` is empty but stance rows exist** —
  preventive measure to catch a silent regression faster next time. Out of scope
  for the bugfix itself; capture as a todo if it comes up during implementation.
- **Read & Rank location filter** — Phase 119 owns this. Do not touch during 118.
- **Cross-app Compass → Read & Rank → Essentials state relay polish** — Phase 122
  (explicitly depends on 118 landing first).

</deferred>

<next_steps>
## Next Steps

1. `/gsd-plan-phase 118` — generate the phase plan using these decisions.
2. Planner should start from the hypothesis-first investigation (D-05, D-06) and
   only fall back to full-layer bisection if the top hypotheses all clear.
3. Verification plan must cover both authed and guest paths on production (D-15).

</next_steps>
