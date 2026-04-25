# Local Officials Topic Scoping — Design Spec

**Date:** 2026-04-10
**Projects:** ev-accounts (backend), CompassV2, essentials, ev-ui
**Status:** Draft for review

## Problem

The compass was designed around federal politics. Its 26 topics are mostly federally-framed (healthcare as single-payer vs ACA, housing as HUD funding, immigration as federal enforcement) and its comparison experience assumes politicians who take broad policy positions. This breaks down at every level below the U.S. House:

1. **Local officials have sparse records on federal topics.** Stance research on six Monroe County partially-covered politicians (2026-04-10 batch) produced 15 usable stances out of 82 attempts (18% hit rate). The vast majority of skips were local officials who have no authority over — and no public record on — federally-framed questions like tariffs, Ukraine support, or Medicare. Researchers correctly refused to guess from party affiliation.

2. **Some office types don't take policy positions at all.** County recorders, surveyors, auditors, and coroners run administrative offices. Retention-election judges evaluate candidates on track record, not campaign positions. The compass paradigm (1-5 topic stances) is the wrong frame for these offices entirely.

3. **The compass grid mixes all of these today** without any visible distinction. A voter looking up their address in Monroe County sees a senator (21 stances), a mayor (15 stances), a school board member (0 stances), and a recorder (0 stances) rendered identically — with sparse or empty radars that read as "broken," not "different kind of office."

4. **Users have no signal at compass-creation time** that their topic choices will affect how useful the compass is across different levels of government. A voter who picks 8 federal topics can't compare meaningfully against any local official, and the product doesn't explain why.

## Goals

- Make the compass paradigm meaningful across federal, state, and local offices by writing topics at a principle level that can be evidenced at any jurisdictional level.
- Give voters visible information about topic applicability when building their compass so they can make informed coverage choices.
- Handle offices where the compass paradigm doesn't fit (retention judges, pure administrators) with alternative card treatments instead of broken radars.
- Preserve all existing stance data — no deletions, no retroactive gating.
- Add a deep comparison view on politician profiles that goes beyond the 3–8 compass topics for users who want to explore further.
- Establish a safe workflow for rewriting existing topics that gates every rewrite on human review and explicitly re-evaluates existing stances under the new framing.

## Non-goals

- **Retention-judge record data** (sentencing patterns, published opinions, reversal rates, ABA ratings). Different data shape, different sourcing pipeline. Carved off as a separate future workstream.
- **Quote deidentification for read-rank.** Surfaced as a cross-cutting concern but scoped to a future spec focused on read-rank data flow.
- **Candidate-vs-politician data model cleanup.** `essentials.politicians` currently conflates sitting office-holders with active candidates. Real issue, tracked in memory, not in scope here.
- **Chamber naming cleanup.** "Council - At Large" mixes multiple cities and counties. Separate data-quality initiative.
- **Compass page tier toggle / self-reflection view.** Considered during brainstorming, cut because without render-time filtering it has nothing to do.
- **Bulk rewrite of all 26 existing topics.** Rewrites are paced through the review workflow, one topic at a time.

## Core principles (load-bearing decisions)

These decisions were aligned through brainstorming and any deviation changes the spec materially:

1. **The compass radar is stable.** The voter's picked 3–8 topics are the spokes on every radar, on every politician, everywhere. No tier-based filtering, no dynamic reshaping, no "narrow" compass variant.

2. **Tier flags are metadata, not gates.** Topic applicability flags (`applies_federal`, `applies_state`, `applies_local`) inform the voter at compass-creation time and drive a coverage-nudge callout. They do **not** gate data existence, stance research, radar rendering, or deep-view comparison. A mayor with a recorded position on tariffs keeps that stance in the database and it surfaces wherever mutual stances are shown.

3. **One compass per voter, one set of answers.** Not three compasses per level. Not user-configured full/narrow buckets. One set of answers, rendered identically against every politician.

4. **Office engagement level is separate from topic tier.** Whether a given office takes policy positions at all (`full` / `record_only` / `none`) is a property of the office itself, not of any topic. A judge who doesn't take policy positions gets a different card treatment regardless of which topics the voter picked.

5. **Topic rewrites gate on human review and re-evaluate existing stances.** Any change to a topic's framing invalidates the semantics of stances already attached to it. No rewrite ships without explicit review of every affected stance.

## Design overview

Five coordinated pieces of work:

1. **Data model additions** — topic tier flags, topic office scope, office engagement level.
2. **Compass builder UX** — tier badges on topics in CompassV2's topic picker.
3. **Essentials coverage callout** — non-blocking banner on results pages when voter's compass has poor tier coverage relative to what's shown.
4. **Politician profile deep comparison view** — new ev-ui component surfacing all mutual stances beyond the 3–8 compass topics, with an embedded "expand your compass" calibration nudge.
5. **Topic rewrite workflow** — staging → review → stance re-evaluation loop → versioned publish.

Each piece is scoped to one or two files and can be built incrementally. The data model additions unblock everything else and should land first.

## Data model changes (ev-accounts backend)

### Topic tier flags

`inform.compass_topic_roles` already exists with columns `topic_id`, `role_scope`, `is_required`. It is empty in the data, but the application code is already wired to consume it: `compassService.getCompassTopics()` queries this table and attaches a `roles` array to every topic in its response, and `compassService.getCompassCompleteness()` accepts a `roleScope` parameter. The scaffolding exists but is unused.

**Approach: repurpose the existing table.** Adopt `compass_topic_roles` as the canonical home for tier flags, with each topic getting one row per applicable tier. A topic that applies at all three levels gets three rows; a federal-only topic gets one row.

Migration:
```sql
-- Constrain role_scope to the three tier values
ALTER TABLE inform.compass_topic_roles
  ADD CONSTRAINT chk_role_scope_tier
  CHECK (role_scope IN ('federal', 'state', 'local'));

-- Prevent duplicate (topic, tier) pairs
ALTER TABLE inform.compass_topic_roles
  ADD CONSTRAINT uq_compass_topic_roles_topic_scope
  UNIQUE (topic_id, role_scope);
```

**`is_required` is preserved but unused.** The column stays in place to avoid breaking the existing SELECT in `compassService`. It carries no semantic meaning under this design. Backfill scripts do not populate it. A future spec may repurpose it (e.g., "primary tier for this topic") or drop it.

**API shape at the boundary.** Consumers (CompassV2 topic picker, essentials coverage callout) need a clean `{ applies_federal, applies_state, applies_local }` shape per topic, not an array of raw rows. The service layer normalizes the rows into three booleans at the API boundary:

```typescript
// In compassService.getCompassTopics() response shape, per topic:
{
  id, title, short_title, question_text, is_live, version,
  applies_federal: boolean,   // derived from rows where role_scope='federal'
  applies_state: boolean,
  applies_local: boolean,
  // Existing fields preserved for backward compat:
  roles: [...],               // raw rows, unchanged
  stances: [...],
  categories: [...],
}
```

**Default for unpopulated topics.** Any topic with no rows in `compass_topic_roles` is treated as `applies_federal=true, applies_state=true, applies_local=true` (all tiers) at the API layer. This keeps existing topics working identically until the backfill runs, and lets newly-created topics default to "applies everywhere" unless they're explicitly scoped.

The audit pass (see "Audit of existing topics" below) backfills one row per (topic, tier) pair based on the audit table.

### Why this deviates from the originally recommended approach

An earlier draft of this spec recommended dropping `compass_topic_roles` and adding `applies_federal/state/local` bool columns directly to `compass_topics`. That recommendation was made without fully inspecting the service layer and would have broken `getCompassTopics` at runtime. The current approach (repurpose) preserves the existing scaffolding, adds no new tables, and produces the same API shape at the boundary.

### Topic office scope

Optional metadata field for topics that are primarily relevant to specific office types (e.g., bail reform for contested-election judges, curriculum oversight for school board members). Reuses the existing `district_type` enum values.

```sql
ALTER TABLE inform.compass_topics
  ADD COLUMN office_scope TEXT[] NULL;
```

`NULL` means "cross-cutting topic relevant to any policy-making office." Populated array identifies office types where the topic is *primarily* relevant. Example values:
- `NULL` — housing, homelessness, civil-rights, climate (cross-cutting)
- `['SCHOOL']` — curriculum policy, book restrictions, school discipline
- `['JUDICIAL']` — cash bail reform, sentencing alternatives, specialty courts

**Enforcement: informational only, not a render gate.** Consistent with core principle #2, `office_scope` never filters compass radar rendering. Its purposes are:

1. **Compass builder organization.** The topic picker can group or label specialized topics (e.g., a "Judicial issues" section) so voters discover them intentionally rather than stumbling into an unfamiliar topic.
2. **Research prioritization.** Stance research agents use `office_scope` to decide where to actively look for politicians' positions (e.g., don't hunt a mayor's take on cash bail reform).
3. **Future per-office recommendations.** If we later add an "Expand your compass for this politician" feature that suggests topics specific to the office being viewed, `office_scope` drives the recommendation.

A voter who has picked a `['JUDICIAL']`-scoped topic as part of their compass will see it rendered on every politician's radar, just like any other compass topic. Non-judges simply won't have a stance on it, so the spoke is sparse — same as any other topic the politician hasn't addressed.

### Office policy engagement level

Enum on `essentials.chambers` (not `offices` — the engagement level is a property of the office *type*, not of an individual seat):

```sql
CREATE TYPE essentials.policy_engagement_level AS ENUM ('full', 'record_only', 'none');

ALTER TABLE essentials.chambers
  ADD COLUMN policy_engagement_level essentials.policy_engagement_level NOT NULL DEFAULT 'full';
```

Default `full` preserves current behavior. Backfill pass sets non-full values for known administrative and retention offices:

| Level | Examples |
|---|---|
| `full` | Mayors, city/county councils, school boards, sheriffs, prosecutors, state legislators, governors, federal legislators, federal/state executives |
| `record_only` | Retention-election judges (appellate, Indiana Court of Appeals, Indiana Supreme Court) |
| `none` | County recorders, surveyors, auditors, coroners, clerks (administrative offices with no policy role) |

Contested-election judges (Monroe County Circuit Court divisions) are `full` — they run campaigns and may legitimately have stances on criminal-justice topics. The compass will be sparse for them against most voters, and that's honest signal, not a bug.

## Compass builder UX (CompassV2)

### Tier badges on topic cards

When users are browsing topics to add to their compass (the topic picker / library view), each topic card shows a small tier badge indicating applicability:

- `Federal · State · Local` (applies at all three)
- `Federal only`
- `Federal · State`
- `State · Local`
- `Local only` (rare — possibly local-specific issues)

Badge is a small inline pill near the topic title, visually similar to existing category tags but using a distinct color from the category system to avoid confusion.

Badge copy is shown but **has no behavioral effect**. It's purely informational so voters can make informed compass-composition choices.

### Coverage hint in the compass builder

A small status line in the compass builder summarizes tier coverage of the current selection:

> *"Your compass: 8 topics · 6 Federal · 4 State · 3 Local"*

(Topics can apply at multiple tiers, so the numbers don't sum to 8.)

No blocking validation. No forced minimum per tier. Just information.

### Implementation notes

- Tier badges: new small component in ev-ui (`<TopicTierBadge topic={topic} />`), consumed by CompassV2's existing topic picker.
- Coverage hint: inline in the compass builder page (`BuildCompass.jsx`), derives from the current topic selection.
- Backend change: existing compass topic endpoints return the three bool columns as part of the topic payload. No new endpoints.

## Essentials coverage callout

### When it shows

On essentials results pages (address lookup → list of politicians), detect whether the voter's compass has poor tier coverage relative to the results being shown:

- Results page is scoped to an address, which produces a mix of federal, state, and local officials.
- For each tier present in the results, count how many of the voter's compass topics apply at that tier.
- If any tier has fewer than 3 applicable topics AND that tier has officials in the current results, show the callout for that tier.

Example conditions:
- Voter's compass has 8 topics, all federal-only. Results include 3 federal officials, 15 state, 40 local. → Callout shows for state and local.
- Voter's compass has 5 federal + 5 state + 3 local topics. All tiers have ≥3. → No callout.
- Voter's compass has 8 federal + 4 state + 2 local topics. → Callout shows for local only.

### What it says

Non-blocking banner above the results grid (or above the tier group when it's a tier-specific callout):

> **Your compass doesn't cover [tier] issues well.**
> Your 8-topic compass has [N] topics that apply to [tier] officials. Add a few more [tier]-applicable topics to get better comparisons with [city/state/federal] representatives.
> **[Add topics →]**

Click-through takes the voter to CompassV2's topic picker, pre-filtered to topics tagged with the appropriate tier that the voter hasn't already selected.

### What it doesn't do

- It does not reshape the radar.
- It does not hide or filter politicians.
- It does not alter the existing cards.
- It does not replace the existing "build your compass" callout that shows on politician profiles when the voter has no compass yet.

### Implementation notes

- New ev-ui component: `<CompassCoverageCallout tier="local" topicsCovered={2} />`.
- Dismissable per-session (state in localStorage with the tier as the key), so a voter who's seen it doesn't get nagged every navigation.
- Lives on the essentials Results page between the tier header and the card grid.

## Politician profile deep comparison view

The core UX problem: a voter with 8 mostly-federal topics looking at Kerry Thomson sees mostly empty spokes and no useful information. The deep comparison view is the safety net.

### Structure

New section on `essentials/src/pages/Profile.jsx` below the compass radar area, rendered via a new ev-ui component `<DeepComparisonView politician={politician} userAnswers={userAnswers} />`.

Logic:

1. Pull all topics where both the voter has an answer and the politician has a stance (this is a superset of the voter's 3–8 compass topics).
2. Group into buckets by agreement level:
   - **Agree** — stance values within 1 unit of each other
   - **Partially agree** — within 2 units
   - **Disagree** — 3+ units apart
3. Render each group as an expandable list showing the topic, the voter's answer, the politician's stance, and the politician's reasoning excerpt.

### The calibration nudge inside the deep view

At the bottom of the deep view, surface a calibration prompt:

> **Want a richer comparison?**
> [Politician name] has stances on [N] issues you haven't answered yet. Expand your compass to see where you stand on all of them.
> **[Expand compass →]**

Where `N` is the count of topics with a politician stance but no voter answer. Click-through to CompassV2 calibration flow, pre-filtered to exactly those topics, with a backlink to the current essentials profile.

If `N` is zero (voter has answered every topic the politician has a stance on), hide the nudge.

### Distinction from the existing "build your compass" callout

| Surface | Existing callout | New calibration nudge |
|---|---|---|
| Where | Profile page compass section | Profile page deep view section |
| When | Voter has no compass yet | Voter has compass but politician has stances on topics voter hasn't answered |
| Copy | "Calibrate your compass to compare" | "Expand your compass — [N] more topics available" |
| Target | Full calibration flow from start | Calibration pre-filtered to the N unanswered topics |

The existing callout continues working unchanged. The new nudge is additive.

### Implementation notes

- New ev-ui component: `<DeepComparisonView />`.
- Requires a new backend endpoint (or extension of existing profile endpoint) that returns all politician stances, not just the compass-topic stances. Probably `/api/essentials/politicians/:id/stances` already exists — verify during implementation.
- Voter's answers already available via `CompassContext`.
- The agreement-level thresholds (1/2/3 units) are a starting point and may need tuning after first user testing.

## Topic rewrite workflow

Rewriting an existing topic's question text or stance scale is a high-risk operation: existing stances were researched and scored against the old framing, and may no longer be valid under the new one. This workflow enforces a safety loop.

### Preconditions

- A topic has been identified as a rewrite candidate via audit (see "Audit of existing topics" below).
- A draft rewrite (new `title`, `short_title`, `question_text`, stance-scale descriptions) has been prepared.

### Workflow states

1. **Draft** — new version is being composed. Not visible to users. Not compared against.
2. **Pending review** — draft is complete, waiting for human (Chris) approval on the new framing.
3. **Re-evaluation queue** — framing approved; system has identified every politician with an existing stance on the topic and is re-evaluating each one under the new framing. Each re-evaluation lands in a per-stance review queue.
4. **Publish-ready** — all stance re-evaluations have been reviewed and accepted.
5. **Published** — new version is live, old version is archived (still queryable via version history but not rendered).

### Mechanics

- `compass_topics` already has `version`, `is_live`, `went_live_at` columns — use them.
- A rewrite creates a new row in `compass_topics` with the same `topic_key` and `version = old_version + 1`, initially `is_live = false`.
- Stance re-evaluation uses a new table or a staging field to hold proposed new `value` per `(politician_id, topic_id_new)` tuple until approved.
- Publish step atomically: set new version's `is_live = true` and old version's `is_live = false`; `politician_answers.topic_id` foreign keys update to the new topic id (or we use `topic_key` as the join key and allow multiple topic rows per key with one live at a time).

### Human gates

Two explicit approval points:

1. **Framing gate.** Chris reviews the rewritten question text and stance scale descriptions. Approves, rejects with notes, or requests changes. Nothing happens to stance data until this gate passes.
2. **Re-evaluation gate.** For each politician with an existing stance, Chris sees side-by-side: old framing + old value + old reasoning vs. new framing + proposed new value (generated by agent) + new reasoning. Approves, adjusts, or rejects per stance.

### Scope of this spec

The workflow design is in scope. Building the admin UI for executing the workflow is *implementation*, tracked in the plan that follows this spec. V1 can be rough — a CLI tool or a basic admin page is fine. The point is that no rewrites ship without the review gates.

## Audit of existing topics

Not a code change — a deliverable from implementation. Produce a document that evaluates each of the current 26 topics against these questions:

1. Is the current framing principle-level (works at any jurisdictional level) or program-level (assumes a specific level's policy levers)?
2. Which tier flags should it have (`federal`, `state`, `local`, combinations)?
3. Should it have an `office_scope` restriction?
4. Does it need a rewrite? If yes, flag it as a rewrite candidate but do not rewrite as part of this project — rewrites go through the workflow above.

Initial guess based on prior brainstorming (subject to the audit, not final):

| Topic | Rewrite? | Tier flags |
|---|---|---|
| healthcare | Rewrite (currently federally framed around single-payer) | F, S, L |
| abortion | Keep (principle-level) | F, S |
| tariffs | Keep | F only |
| taxes | Rewrite | F, S, L |
| same-sex-marriage | Keep | F, S, L |
| religious-freedom | Keep | F, S, L |
| trans-athletes | Keep | F, S, L |
| ukraine-support | Keep | F only |
| medicare/aid | Keep | F only |
| fossil-fuels | Keep | F, S, L |
| voting-rights | Keep | F, S, L |
| deportation | Keep | F, S, L |
| social-security | Keep | F only |
| ai-regulation | Rewrite | F, S |
| climate-change | Keep | F, S, L |
| civil-rights | Keep | F, S, L |
| housing | Keep | F, S, L |
| campaign-finance | Keep | F, S, L |
| immigration | Rewrite | F, S, L |
| misinformation | Keep | F, S, L |
| redistricting | Keep | F, S |
| school-vouchers | Keep | F, S, L |
| data-centers | Keep | F, S, L |
| homelessness | Keep | F, S, L |
| childcare | Keep | F, S, L |
| jail-capacity | Keep | S, L |

Audit output becomes the input to tier-flag backfill (one script pass) and the rewrite queue (one topic at a time through the workflow).

## User stories

- As a **voter building my compass**, I want to see which tiers of government each topic applies to, so I can pick a set that will be useful across my federal, state, and local politicians.
- As a **voter looking up my address**, if my compass doesn't cover local issues well, I want a clear prompt telling me so and offering a quick way to fix it, so my local comparisons aren't frustrating dead ends.
- As a **voter viewing a mayor's profile**, I want to see agreement information that goes beyond my 3–8 compass topics, so I can get a meaningful comparison even if the compass doesn't match the mayor's record perfectly.
- As a **voter viewing a retention judge's profile**, I want the page to acknowledge that "compass-style comparison doesn't apply to this office" rather than showing a broken empty radar, so I understand what kind of decision I'm being asked to make.
- As a **voter viewing a county recorder's profile**, I want to see a bio and basic role info without being asked to take a compass position on an administrative office, so the experience matches the nature of the office.
- As the **platform operator (Chris)**, I want every topic rewrite to go through an explicit review loop that includes re-evaluating every existing stance, so topic changes don't silently invalidate historical data.

## Open questions

1. **Where exactly does the coverage-nudge callout dismiss state live?** localStorage is fine for anonymous users but should persist per-account for logged-in users. Decide during implementation — probably `localStorage` for v1, DB-backed later.
2. **Agreement-level thresholds in the deep view** (1/2/3 units) are placeholders. Validate with real data before shipping.
3. **Retention-judge card treatment.** Spec commits to `record_only` as an enum value, but the actual card visual design (what goes in the "record" section when we don't yet have record data) needs a placeholder that's honest about the lack of data. A temporary "Retention election · no compass data yet" card treatment is acceptable for v1.
4. **Contested-election judges in Indiana.** Verify with Indiana-specific sources which judicial offices are contested vs. retention before backfilling `policy_engagement_level`. Circuit court judges in Monroe County appear to be contested first-term elections then retention; this needs confirmation.
5. **Does the existing `/api/essentials/politicians/:id` endpoint already return all stances, or just compass-topic stances?** Verify during implementation. If not, add a new endpoint or extend the existing one.

## Success criteria

- A voter whose compass is mostly federal can look up their Monroe County address, see a coverage nudge for local topics, click through to add local-applicable topics, and return to a results page with meaningfully populated local radars.
- A retention judge profile renders a distinct card treatment without a broken radar, and the voter understands why.
- A county recorder profile renders a bio-level card without a compass section, and the voter understands why.
- Chris can run a topic rewrite end-to-end through the workflow (draft → framing review → stance re-evaluation → publish) for one test topic without any stance data being silently invalidated.
- `inform.compass_topics` has populated tier flags for all 26 existing topics.
- `essentials.chambers.policy_engagement_level` is populated for all current Monroe County offices, validated against real office types.
- The deep comparison view surfaces at least one politician where the voter would disagree-but-not-see-it with their current 8-topic compass, proving it adds value beyond the radar.
