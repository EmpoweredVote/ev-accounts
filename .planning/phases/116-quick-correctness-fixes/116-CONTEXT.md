# Phase 116: Quick Correctness Fixes - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix three voter-facing defects before the May 5, 2026 Indiana primary: wrong election date on Election Central, broken SiteHeader nav links, and wrong default Representatives tab.

After discussion, CORR-01 and CORR-03 were both determined to be probable misflags — code and data inspection showed correct behavior. The phase collapses to a single real fix (CORR-02, SiteHeader nav) plus closure notes for the two misflags.

</domain>

<decisions>
## Implementation Decisions

### CORR-01: Wrong Election Date (MISFLAG — close as no-op)
- **D-01:** No code change. Supabase `essentials.elections` row for `2026 Indiana Primary` already holds `election_date = 2026-05-05`. `ElectionsView.jsx` is fully data-driven via `election.election_date` with a timezone-safe `formatDate()` (parses as `T12:00:00` local). Wide grep across essentials, CompassV2, ev-ui, and empowered-vote-static turned up no hardcoded wrong date.
- **D-02:** The stale `/** Format election date: "May 6, 2026" */` JSDoc comment in `essentials/src/components/ElectionsView.jsx:29` is a docstring example, not a bug — leave it or fix it opportunistically, not required.
- **D-03:** Close CORR-01 as a misflag in VERIFICATION.md. No production smoke-test required (user accepted misflag classification explicitly).

### CORR-02: SiteHeader Nav Links (REAL FIX — ship via ev-ui)
- **D-04:** Remove these items entirely from `defaultNavItems` in `ev-ui/src/SiteHeader.jsx`:
  - `{ label: 'About Us', href: 'https://empowered.vote/about' }`
  - `{ label: 'Volunteer', href: 'https://empowered.vote/volunteer' }`
  - `{ label: 'FAQ', href: 'https://empowered.vote/faq' }`
  Reason: `empowered-vote-static/` only ships `index.html`, `donate.html`, `forms.html`, `404.html` — these three links 404.
- **D-05:** Update Features dropdown URLs:
  - Treasury Tracker: `https://ev-prototypes.netlify.app/treasury-tracker/dist` → `https://treasurytracker.empowered.vote`
  - Empowered Badges: `https://ev-prototypes.netlify.app/empowered-badges/dist` → `https://badges.empowered.vote`
- **D-06:** Leave these dropdown items unchanged (user confirmed live):
  - Political Compass → `https://compass.empowered.vote`
  - Find Representatives → `https://essentials.empowered.vote`
  - Read & Rank → `https://readrank.empowered.vote`
- **D-07:** Leave the Donate CTA unchanged (`https://empowered.vote/donate` → `donate.html` exists).
- **D-08:** Ship via standard ev-ui auto-bump pipeline: `npm version patch && git push origin main --follow-tags` in `ev-ui/`. Let the publish.yml workflow handle npm publish (OIDC) and repository_dispatch to CompassV2, essentials, read-rank, civic-spaces. Standard patch auto-merge — build-check gates each consumer PR, no manual review needed.
- **D-09:** No production smoke-test of the changed URLs is required before cutting the ev-ui release — user confirmed treasurytracker/badges/compass/essentials/readrank subdomains are live and correct.

### CORR-03: Default Representatives Tab (MISFLAG — close as no-op)
- **D-10:** No code change. Current defaults in `essentials/src/pages/Results.jsx` are already correct:
  - Top-level `activeView` defaults to `'representatives'` (line 181)
  - Tier filter `selectedFilter` defaults to `'All'` (line 247)
  - `appointedFilter` defaults to `'All'` (line 252)
- **D-11:** Intent confirmed: sitting officials only on the Representatives tab. Challengers/candidates belong in the Elections tab, not mixed into the main Representatives grid. Current architecture matches this intent — no change needed.
- **D-12:** Close CORR-03 as a misflag in VERIFICATION.md. No production reproduction required.

### Release Coordination
- **D-13:** Phase 116 ships as a single ev-ui patch release. Essentials/CompassV2/read-rank/civic-spaces get their SiteHeader nav updated transitively via the auto-bump pipeline. No direct edits to consumer repos.
- **D-14:** Verification: after the auto-bump PRs merge and Render redeploys, manually load at least one consumer (essentials.empowered.vote) and confirm the nav no longer shows About Us/Volunteer/FAQ and the Features dropdown points at the new subdomains.

### Claude's Discretion
- Whether to also delete the stale `May 6, 2026` docstring comment in `ElectionsView.jsx:29` opportunistically (cosmetic, unrelated to the fix).
- Exact ev-ui commit message and patch version number.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase-defining docs
- `.planning/ROADMAP.md` §Phase 116 — Goal, requirements, success criteria
- `.planning/REQUIREMENTS.md` §Tier 1 Quick Correctness — CORR-01, CORR-02, CORR-03 definitions

### ev-ui release pipeline
- `ev-ui/README-AUTOBUMP.md` — Full auto-bump pipeline (npm publish, repository_dispatch, consumer auto-merge, Render redeploy)
- `ev-ui/.github/workflows/publish.yml` — Publish workflow triggered on tag push

### Files to edit
- `ev-ui/src/SiteHeader.jsx` — All CORR-02 changes land here (defaultNavItems, Features dropdown URLs)

### Files inspected (no edit required)
- `essentials/src/components/ElectionsView.jsx` — CORR-01 investigation target, data-driven, no bug found
- `essentials/src/pages/Results.jsx` — CORR-03 investigation target, defaults already correct
- `empowered-vote-static/` — Confirmed only `index.html`, `donate.html`, `forms.html`, `404.html` exist

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ev-ui/src/SiteHeader.jsx` — Single source of truth for nav across all consumer apps. `defaultNavItems` and `defaultCtaButton` are exported alongside the default export.
- ev-ui auto-bump pipeline (`publish.yml` + consumer `ev-ui-bump.yml`) — Handles cross-repo propagation automatically.

### Established Patterns
- Nav URL changes must land in `ev-ui`, never in consumer repos directly — keeps all apps in sync.
- Election dates flow from `essentials.elections.election_date` (Supabase) → `ElectionsView.jsx` via `formatDate(dateStr + 'T12:00:00')` → localized string. Timezone-safe.
- Representatives view uses three independent filters: top tab (`activeView`), tier (`selectedFilter`), and elected/appointed (`appointedFilter`). All default to the most inclusive option.

### Integration Points
- Only ev-ui is touched for this phase. Consumer repos (CompassV2, essentials, read-rank, civic-spaces) pick up the change via the auto-bump dispatch flow.

</code_context>

<specifics>
## Specific Ideas

- Treasury Tracker and Empowered Badges both resolve to Render-hosted subdomains per `CLAUDE.md` infra table: `treasurytracker.empowered.vote` and `badges.empowered.vote`.
- Per `CLAUDE.md` Infrastructure section, all frontends moved from Cloudflare Pages to Render as of 2026-04-06 — hence the stale `ev-prototypes.netlify.app` URLs.
- Release path is deliberately the standard patch flow, not emergency/manual, because the build-check workflow on each consumer adequately gates the nav-only diff.

</specifics>

<deferred>
## Deferred Ideas

- **Add /about, /volunteer, /faq pages to empowered-vote-static** — user chose to remove the nav links rather than add the pages. Adding the missing static pages remains a future option, not in Phase 116 scope.
- **Centralized ELECTION_DATE constant** — proposed as "both investigate + centralize" but skipped because CORR-01 was a misflag. Worth revisiting later if multiple surfaces start needing a single election-date source of truth.
- **Automated tests for SiteHeader link resolution** — e.g., a CI smoke test that HEAD-checks every nav href. Out of Tier 1 scope but would prevent this class of bug.
- **Smoke-test dashboard for consumer subdomains** — pings compass/essentials/readrank/treasurytracker/badges on every ev-ui release to confirm 200 OK before auto-merge. Bigger effort.

</deferred>

---

*Phase: 116-quick-correctness-fixes*
*Context gathered: 2026-04-14*
