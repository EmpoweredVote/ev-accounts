# Phase 116: Quick Correctness Fixes - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 116-quick-correctness-fixes
**Areas discussed:** CORR-01 date fix scope, CORR-02 nav link audit, CORR-03 default tab intent, Release coordination

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| CORR-01 date fix scope | Is 'Election Central' = ElectionsView.jsx, or a different page? Is the wrong date coming from DB or hardcoded formatter? | ✓ |
| CORR-02 nav link audit | Which SiteHeader links are actually 404ing? Remove broken ones, fix targets, or replace with placeholders? | ✓ |
| CORR-03 default tab intent | Is 'default tab' the top-level Representatives/Elections toggle, or a tier filter? What does 'challengers' mean? | ✓ |
| Release coordination | Ship all three together via ev-ui auto-bump, or land essentials fixes first and ev-ui on its own cadence? | ✓ |

**User's choice:** All four areas selected (multiSelect).
**Notes:** None.

---

## CORR-01 Date Fix Scope

### Q1: Which page is 'Election Central'?

| Option | Description | Selected |
|--------|-------------|----------|
| ElectionsView.jsx (Elections tab) | The upcoming-elections view inside essentials Results page — what scout found. | ✓ |
| A different page | User specifies which page/component. | |
| Not sure — investigate | Grep wider to find what users call Election Central. | |

**User's choice:** ElectionsView.jsx (Elections tab)

### Q2: Where is the wrong date stored?

| Option | Description | Selected |
|--------|-------------|----------|
| In the DB (essentials.elections row) | Fix by updating the row's election_date. | |
| Hardcoded in frontend | Fix by editing the literal in ElectionsView.jsx. | |
| Not sure — I'll investigate | Query Supabase + grep for hardcoded dates. | ✓ |

**User's choice:** Not sure — investigate
**Claude investigation result:** Supabase `essentials.elections` has `2026 Indiana Primary` with `election_date = 2026-05-05` (correct). Wide grep across essentials, CompassV2, ev-ui, and empowered-vote-static found no hardcoded wrong date. ElectionsView.jsx uses timezone-safe formatter (`T12:00:00` local). The only `May 6, 2026` reference is a stale JSDoc comment example in `ElectionsView.jsx:29`, not production output.

### Q3: What should the fix approach be?

| Option | Description | Selected |
|--------|-------------|----------|
| On essentials.empowered.vote/results Elections tab | Check production, may be stale Render deploy. | |
| On a different empowered.vote page | User points at specific URL/screen. | |
| In a screenshot/notes — I need to look | User saw it during testing, needs help hunting. | |

**User's free-text choice:** "It was reported as wrong, but maybe its not"

### Q4: Approach if bug can't be located

| Option | Description | Selected |
|--------|-------------|----------|
| Investigation task first, then fix | Plan includes reproduce step, load each app, screenshot. | |
| Hardcode the date as a constant | Create shared ELECTION_DATE constant. | |
| Both — investigate + centralize | Find the bug AND refactor to a single constant. | |

**User's free-text choice:** "let's just call it done, a misflag"
**Notes:** CORR-01 closed as misflag. No code change. Close in VERIFICATION.md during execute phase.

---

## CORR-02 Nav Link Audit

### Q1: Marketing links (About Us, Volunteer, FAQ) that 404

| Option | Description | Selected |
|--------|-------------|----------|
| Remove them entirely | Drop About Us / Volunteer / FAQ from nav. Simplest, zero risk of future 404s. | ✓ |
| Point them to existing pages | Repoint to pages that do exist. | |
| Add the missing HTML pages | Create /about, /volunteer, /faq in empowered-vote-static. | |

**User's choice:** Remove them entirely

### Q2: Treasury Tracker and Empowered Badges (stale Netlify URLs)

| Option | Description | Selected |
|--------|-------------|----------|
| Point to Render subdomains now | treasurytracker.empowered.vote / badges.empowered.vote per CLAUDE.md. | |
| Remove from dropdown until deployed | Drop both until Render deployments confirmed. | |
| Remove Treasury only, keep Badges | Case-by-case verification. | |

**User's free-text choice:** "I have the new urls. treasurytracker.empowered.vote | badges.empowered.vote"
**Notes:** Both new URLs confirmed live by user. Update in place.

### Q3: Verify core app URLs (Compass, Find Representatives)?

| Option | Description | Selected |
|--------|-------------|----------|
| Live and correct — skip | User confirmed those two work. | ✓ |
| Verify as part of this fix | Plan includes smoke-test step. | |

**User's choice:** Live and correct — skip

---

## CORR-03 Default Tab Intent

### Q1: Current bug behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Top tab wrong — defaulting to Elections | Wrong default on first load. | |
| Appointed filter hides candidates | Elected/Appointed/All filter defaulting to 'Elected'. | |
| Candidates don't show in Representatives tab at all | Even with All filter, candidates only appear on Elections tab. | |
| Not sure — need to reproduce | Plan includes repro step. | |

**User's free-text choice:** "this one might be another misflag, it seems fine to me"
**Claude inspection result:** `Results.jsx` defaults are already inclusive — `activeView='representatives'`, `selectedFilter='All'`, `appointedFilter='All'`.

### Q2: Intent for 'all elected officials including challengers'

| Option | Description | Selected |
|--------|-------------|----------|
| Sitting officials + challengers side-by-side | Incumbents and their challengers in the same grid. | |
| Sitting officials + separate candidates section | Incumbents in main grid, candidates in secondary section. | |
| Just sitting officials — challengers in Elections tab | Keep challengers out of Representatives view. | ✓ |

**User's choice:** Just sitting officials — challengers live in Elections tab
**Notes:** CORR-03 closed as misflag. Current architecture already matches intent. No code change.

---

## Release Coordination

### Q1: Sequencing CORR-02 with CORR-01/03 verification

| Option | Description | Selected |
|--------|-------------|----------|
| Ship CORR-02 immediately, verify CORR-01/03 in parallel | Cut ev-ui patch today, smoke-test prod in parallel. | |
| Verify everything first, then ship one bundle | Confirm misflags before touching ev-ui. | |
| Ship CORR-02, mark CORR-01/03 closed as misflags now | Treat user report as sufficient, skip prod verification for CORR-01/03. | ✓ |

**User's choice:** Ship CORR-02, mark CORR-01/03 closed as misflags now

### Q2: ev-ui auto-bump rollout

| Option | Description | Selected |
|--------|-------------|----------|
| Standard auto-merge (patch, build-check gates) | Let pipeline run, build-check workflow gates each PR. | ✓ |
| Manual review each consumer PR | Disable auto-merge, review each by hand. | |

**User's choice:** Standard auto-merge (patch, build-check gates)

---

## Claude's Discretion

- Whether to also delete the stale `May 6, 2026` docstring in `ElectionsView.jsx:29` opportunistically.
- Exact ev-ui commit message and patch version number.

## Deferred Ideas

- Add /about, /volunteer, /faq pages to empowered-vote-static (future).
- Centralized ELECTION_DATE constant (future).
- Automated CI smoke test that HEAD-checks every SiteHeader nav href on release.
- Smoke-test dashboard pinging all consumer subdomains before auto-merge.
