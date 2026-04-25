# Plan C Execution Prompt

**Use this prompt to start a fresh session dedicated to executing Plan C.**

Copy everything below the separator into the new conversation.

---

Execute Plan C from `docs/superpowers/plans/2026-04-11-plan-c-essentials-coverage-and-deep-comparison.md` using `superpowers:subagent-driven-development`. Invoke that skill first, then dispatch subagents per task.

## Context you need

**Plans A and B are already deployed to production.** Do not redo any of that work.

- **Plan A** (ev-accounts backend tier flag data foundation) is live on `api.empowered.vote`. Migration 059 applied. `inform.compass_topic_roles` populated with 64 rows. `essentials.chambers.policy_engagement_level` backfilled (68 none, 17 record_only, rest full). Both `getCompassTopics` and `getCompassCategories` normalize tier flags into `applies_federal/state/local` booleans on nested topics.
- **Plan B** (ev-ui TopicTierBadge + CompassV2 integration) is live. `@empoweredvote/ev-ui@0.3.0` published to npm with `TopicTierBadge` using Lucide-style SVG icons (Landmark/Building2/Home). CompassV2's `CalibrationOverlay.jsx` and `Library.jsx` consume it.

**Pre-execution verification already done for Plan C:**
- `policy_engagement_level` is exposed at the **top level** of `/api/essentials/politicians/:id` responses. Verified with Kerry Thomson (`full`), Nicole Bolden (`none`), Geoffrey Bradley (`full`).
- `is_judicial` is **NOT** on the API response. Plan C uses `pol.district_type === 'JUDICIAL' || pol.district_type === 'NATIONAL_JUDICIAL'` for judge detection instead. This fix is already in the plan (commit `cbe6779`).
- ev-ui's existing `tokens.js` has `tierColors`, `fonts`, `fontWeights`, `fontSizes`, `spacing`, `borderRadius` — all tokens Plan C's new components depend on.
- essentials `CompassContext` already exposes `allTopics` (with tier flags from Plan A), `selectedTopics`, `politicianIdsWithStances`, `userAnswers`.

**The target files are verified via code reading + live Playwright inspection:**
- `essentials/src/pages/Results.jsx` (1011 lines) — uses `PoliticianCard` from ev-ui, has an "All / Local / State / Federal" filter sidebar with state variable likely named `selectedFilter`
- `essentials/src/components/CompassCard.jsx` (417 lines) — already handles three render states (has-user-compass, guest, zero-overlap); already uses `StanceAccordion` from ev-ui as the deep view
- `essentials/src/pages/Profile.jsx` (185 lines) — renders `PoliticianProfile` from ev-ui + local `CompassCard`

**Critical instruction:** Before editing any file, verify it matches what the plan expects. Read it first. This rule exists because an earlier Plan B session edited `BuildCompass.jsx` when it should have edited `CalibrationOverlay.jsx`, costing a full debugging cycle. Plan C's Tasks 7-9 each have explicit "read the current file and confirm" steps.

## Authorization granted

- OK to publish `@empoweredvote/ev-ui@0.4.0` (Task 5). Auto-bump PRs will open in all 4 consumer repos — fine for all to receive the bump even though only essentials uses the new exports.
- OK to push directly to `essentials@main` (Task 11) without a PR gate.
- OK to deploy to production via Render auto-deploy on push.
- Nicole Bolden and Geoffrey Bradley profiles get the explicit engagement-level treatment (administrative office note, judge record note respectively).

## Execution model

Use **subagent-driven-development**. Dispatch a fresh subagent per task. Two-stage review per task (spec compliance, then code quality), except trivial file-creation tasks where the content is exact and verification is self-evident — those can skip formal review.

For visual verification tasks (Task 10, Task 12), **you (the controller)** drive Playwright directly — don't dispatch a subagent for that. Inject guest compass state into localStorage, navigate to the four test URLs, screenshot each one, and confirm the expected elements render.

## Test fixtures

Known politician IDs for verification:
- Kerry Thomson (mayor, full, has stances): `1c6dbdaf-e110-48d3-9b88-27f911d9521f`
- Nicole Bolden (city clerk, none): `4d20abb8-b05a-444c-883d-03eb4b43d166`
- Geoffrey J. Bradley (circuit judge, full, no stance research): `999a9d38-9894-45f0-80c7-228880089699`

Known test address for results page: `200 W 6th St, Bloomington, IN 47404`

## Known issues to avoid repeating

1. **npm publish→dispatch race.** Plan B's v0.3.0 release hit this: auto-bump fired before npm registry propagated the new version, causing the bump PR to fail. Plan C Task 6 has an explicit fallback to manual `npm install`. Don't waste time debugging — just fall back.
2. **Nested git repos.** The monorepo at `/Users/chrisandrews/Documents/GitHub/` and the inner repos (ev-accounts, ev-ui, CompassV2, essentials) are all separate git repos. When committing backend changes, commit to the inner repo's branch (e.g., `ev-accounts/master`). The monorepo branch is for specs/plans, not code. Plan A's first attempt failed because commits went to the monorepo branch instead of ev-accounts master.
3. **Prod DB password was echoed in an earlier session.** Do not echo `DATABASE_URL` in any subagent output. Extract only the project ID if confirmation is needed. The safety pattern: `echo "$DATABASE_URL" | sed -E 's|.*postgres\.([a-z0-9]+):.*|\1|'`.
4. **Do not commit untracked `.claude/agent-memory/politician-stance-researcher/stance_*.md` files** in ev-accounts — they're research skill output, not code.

## Outstanding items not in Plan C's scope but worth being aware of

- **Deploy verification of CompassV2 `9d9174a`** was never done in the original session. The user intended to check `compass.empowered.vote/library` themselves. If you notice issues with Library rendering during Plan C's essentials work, check that commit first.
- **Prod DB password rotation** is still a good idea since it was logged earlier. Not blocking Plan C.

## Success criteria

Plan C is complete when:
1. `@empoweredvote/ev-ui@0.4.0` is published on npm with `CompassCoverageCallout`, `ExpandCompassNudge`, `computeTierCoverage` exports
2. `essentials.empowered.vote/results` with a federal-only compass shows coverage callouts for state + local tiers
3. Kerry Thomson's profile shows an "Expand your compass — N more topics available" nudge below the StanceAccordion
4. Nicole Bolden's profile shows "This is an administrative office — no compass comparison applies" in place of a compass section
5. Geoffrey Bradley's profile shows "Judges are typically evaluated on record" in place of a compass section
6. All four visual states verified via Playwright on the deployed site (not just localhost)

Report back when complete or when blocked.
