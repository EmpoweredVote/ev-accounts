---
phase: 116-quick-correctness-fixes
plan: 01
subsystem: ui
tags: [ev-ui, siteheader, nav, auto-bump, npm, render]

requires:
  - phase: 115-milestone-v2026.4.4-planning
    provides: GAP-REPORT.md and BACKLOG.md flagging CORR-01/02/03
provides:
  - ev-ui@0.4.1 patch with cleaned SiteHeader navigation
  - Removed 3 broken nav links (About Us, Volunteer, FAQ) from defaultNavItems
  - Updated Treasury Tracker + Empowered Badges Features dropdown URLs to Render subdomains
  - 116-VERIFICATION.md documenting CORR-01 + CORR-03 misflag closures and CORR-02 live-check log
affects: [future ev-ui releases, all 4 consumer apps consuming @empoweredvote/ev-ui]

tech-stack:
  added: []
  patterns:
    - "ev-ui auto-bump release: edit → npm version patch → push tag → OIDC publish → repository_dispatch fan-out → consumer auto-merge PRs → Render redeploy"
    - "Misflag closure: when triage finds the bug already fixed in code, document evidence in VERIFICATION.md instead of producing a no-op commit"

key-files:
  created:
    - .planning/phases/116-quick-correctness-fixes/116-VERIFICATION.md
    - .planning/phases/116-quick-correctness-fixes/116-01-SUMMARY.md
  modified:
    - ev-ui/src/SiteHeader.jsx

key-decisions:
  - "CORR-01 (election date) closed as misflag — Supabase row already 2026-05-05, ElectionsView.jsx fully data-driven with timezone-safe formatDate()"
  - "CORR-03 (Representatives default) closed as misflag — Results.jsx defaults already activeView='representatives', selectedFilter='All', appointedFilter='All'"
  - "CORR-02 fixed via ev-ui@0.4.1 patch + standard auto-bump pipeline rather than per-consumer hardcoded copies"
  - "Pre-release smoke test of new URLs skipped — user confirmed treasurytracker/badges/compass/essentials/readrank Render subdomains are live (D-09)"
  - "Live verification performed by inspecting production JS bundle on essentials.empowered.vote rather than browser screenshots — fast and grep-verifiable"

patterns-established:
  - "Live nav verification: curl the deployed JS bundle and grep for expected/forbidden strings to confirm a release reached production"
  - "Two-of-three Tier-1 voter-correctness flags can collapse to misflag closures when the planner does the deep code read first (saves a release cycle each)"

requirements-completed: [CORR-01, CORR-02, CORR-03]

duration: ~45min
completed: 2026-04-14
---

# Phase 116 Plan 01: Quick Correctness Fixes Summary

**Cleaned ev-ui SiteHeader nav (removed 3 broken links, fixed 2 stale dropdown URLs) and shipped via ev-ui@0.4.1 auto-bump pipeline; closed CORR-01 and CORR-03 as misflags after deep code reads confirmed both were already correct in production.**

## Performance

- **Duration:** ~45 min (across human-verify checkpoint pauses for the release pipeline)
- **Completed:** 2026-04-14
- **Tasks:** 4
- **Files modified:** 2 (SiteHeader.jsx, 116-VERIFICATION.md)

## Accomplishments

- **CORR-01 closed as misflag** with documented evidence: Supabase `essentials.elections` row for the 2026 Indiana Primary already holds `election_date = 2026-05-05`, and `ElectionsView.jsx` is fully data-driven with timezone-safe `formatDate()`. No code change needed.
- **CORR-03 closed as misflag** with documented evidence: `essentials/src/pages/Results.jsx` already defaults `activeView='representatives'`, `selectedFilter='All'`, and `appointedFilter='All'` — a fresh address search already lands on the Representatives tab showing all elected officials.
- **CORR-02 fixed in code** by editing `ev-ui/src/SiteHeader.jsx`:
  - Removed `About Us`, `Volunteer`, `FAQ` from `defaultNavItems` (all three pointed at 404 paths in the old empowered-vote-static site).
  - Updated Features dropdown: `Treasury Tracker` → `https://treasurytracker.empowered.vote`, `Empowered Badges` → `https://badges.empowered.vote` (replaced stale `ev-prototypes.netlify.app` URLs).
  - Left Political Compass, Find Representatives, Read & Rank, and the Donate CTA unchanged.
- **ev-ui@0.4.1 published** via the standard auto-bump release pipeline (OIDC trusted publishing → npm + `repository_dispatch` → 4 consumer auto-merge PRs → Render redeploy). Confirmed by user at the Task 3 checkpoint.
- **Live nav verified on production** — fetched `https://essentials.empowered.vote/assets/index-HNbP8zih.js` and grep-confirmed the new Render subdomain strings are present and the 3 deleted nav items + `ev-prototypes.netlify.app` strings are absent.

## Task Commits

1. **Task 1: Create 116-VERIFICATION.md with CORR-01 and CORR-03 misflag closures** — `50ad7e4` (docs)
2. **Task 2: Edit ev-ui/src/SiteHeader.jsx — delete 3 nav items and update 2 dropdown URLs** — `e7fff1a` in ev-ui repo (fix)
3. **Task 3: Cut ev-ui patch release via auto-bump pipeline** — `cb078ad` in ev-ui repo + tag `v0.4.1` (chore: npm version patch)
4. **Task 4: Post-merge verification on essentials.empowered.vote and update VERIFICATION.md** — `3dcadf6` (docs)

_Note: Task 2 and Task 3 commits live in the `ev-ui` repo (separate from this main workspace repo); Task 1 and Task 4 commits live on `feat/compass-how-it-works` here._

## Files Created/Modified

- `.planning/phases/116-quick-correctness-fixes/116-VERIFICATION.md` — Misflag closures for CORR-01 + CORR-03 and CORR-02 live-check log
- `ev-ui/src/SiteHeader.jsx` — Cleaned `defaultNavItems` (Features dropdown only) and corrected Features dropdown URLs to Render subdomains
- `.planning/phases/116-quick-correctness-fixes/116-01-SUMMARY.md` — This file

## Decisions Made

All 14 implementation decisions (D-01 through D-14) were pre-locked in `116-CONTEXT.md`. Plan executed verbatim. Highlights:

- **D-01/D-02/D-03:** CORR-01 closed as misflag — election date is correct in Supabase and `ElectionsView.jsx` is data-driven; the stale JSDoc example "May 6, 2026" at line 29 is a docstring, not a runtime value, left as-is.
- **D-04:** Delete About Us / Volunteer / FAQ from `defaultNavItems` (all three 404 in `empowered-vote-static`).
- **D-05:** Replace stale Netlify URLs with Render subdomains for Treasury Tracker and Empowered Badges.
- **D-06/D-07:** Keep Compass, Essentials, Read & Rank, and Donate untouched.
- **D-08/D-09:** Use the standard ev-ui auto-bump pipeline — no pre-release smoke test of the new URLs (user confirmed Render subdomains are live).
- **D-10/D-11/D-12:** CORR-03 closed as misflag — Results.jsx defaults are already correct; sitting officials only on Representatives tab is intentional architecture.
- **D-13/D-14:** Patch version bump (not minor); post-deploy verification on essentials.empowered.vote required.

## Deviations from Plan

None — plan executed exactly as written. All 14 pre-locked decisions held, no Rule 1/2/3 auto-fixes were needed, no Rule 4 architectural escalations.

## Issues Encountered

None. The two human-verify checkpoints (Task 3 release pipeline, Task 4 live nav verification) were the planned synchronization points, not problems.

## User Setup Required

None — no environment variables, no dashboard configuration, no external services touched. Pure UI nav config change.

## Next Phase Readiness

- **CORR-01, CORR-02, CORR-03 all closed.** Tier 1 Quick Correctness section of v2026.4.4 milestone is complete.
- **ev-ui auto-bump pipeline confirmed working end-to-end** — useful baseline for the next ev-ui patch in this milestone (likely Phase 117).
- **No blockers** for the next phase in the v2026.4.4 Indiana Primary Fix Wave.

## Self-Check: PASSED

- `116-VERIFICATION.md` exists with `CORR-01: MISFLAG`, `CORR-03: MISFLAG`, and the filled-in `CORR-02: Verification Log`
- Commit `50ad7e4` (Task 1) found in `git log --oneline`
- Commit `3dcadf6` (Task 4) found in `git log --oneline`
- ev-ui commits `e7fff1a` (Task 2) and `cb078ad` (Task 3, tag `v0.4.1`) confirmed in `ev-ui/` repo log
- Live `essentials.empowered.vote` JS bundle contains all 5 expected Features dropdown subdomains + `empowered.vote/donate`, and contains zero references to `About Us`, `Volunteer`, `FAQ`, or `ev-prototypes.netlify.app`

---
*Phase: 116-quick-correctness-fixes*
*Completed: 2026-04-14*
