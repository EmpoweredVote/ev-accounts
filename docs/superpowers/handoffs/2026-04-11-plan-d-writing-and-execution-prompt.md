# Plan D — Writing and Execution Prompt

**Use this prompt to start a fresh session dedicated to Plan D.**

Plan D has a spec section but no implementation plan document yet. This session will write the plan AND then execute it (or pause between planning and execution if context runs low).

Copy everything below the separator into the new conversation.

---

Write and execute Plan D — the topic rewrite workflow for Empowered Vote. The design spec is at `docs/superpowers/specs/2026-04-10-local-officials-topic-scoping-design.md`, section titled **"Topic rewrite workflow"** (around line 240). Start by reading that section in full, then invoke `superpowers:writing-plans` to produce an implementation plan at `docs/superpowers/plans/2026-04-11-plan-d-topic-rewrite-workflow.md`. After the plan is written and committed, invoke `superpowers:subagent-driven-development` to execute it.

## What Plan D is

An admin-facing workflow for rewriting existing compass topic framings safely. Rewriting a topic's `question_text` or stance scale invalidates the semantics of every existing stance attached to it, so the workflow enforces two human review gates:

1. **Framing gate** — Chris reviews the new question text + stance scale descriptions before any stance data is touched
2. **Re-evaluation gate** — for each politician with an existing stance on the topic, Chris sees old framing + old value + old reasoning side-by-side with new framing + proposed new value (agent-generated) + new reasoning, and approves/adjusts/rejects per stance

Only after all stance re-evaluations are approved does the new topic version go live.

## What's already built (don't rebuild)

- `inform.compass_topics` already has `version`, `is_live`, `went_live_at` columns. Versioning primitives exist.
- `inform.compass_topics.topic_key` is stable across versions — use it as the join key if needed.
- `inform.compass_stances` already has stance scale descriptions per topic.
- `inform.politician_answers` already stores `(politician_id, topic_id, value)` tuples.
- `inform.politician_context` already stores `(politician_id, topic_id, reasoning, sources)`.
- Admin UI infrastructure already exists in CompassV2 under `CompassV2/src/components/admin/` including `TopicEditor.jsx`, `AttachAnswers.jsx`, `CreateTopic.jsx`, `AdminDashboard.jsx`, `TopicAccordion.jsx`, `TopicAdminPanel.jsx`. Read these to understand the existing admin patterns before designing new ones.

## What Plan D needs to deliver (from the spec)

1. A **workflow state machine** for topic rewrites: `draft` → `pending_framing_review` → `re_evaluation_queue` → `publish_ready` → `published`
2. **Backend RPCs / endpoints** that stage new versions, identify affected stances, and do the atomic publish
3. **A staging table or fields** to hold proposed new stance values per `(politician_id, new_topic_id)` until the re-evaluation gate passes
4. **An admin UI** for each gate — probably extending the existing admin dashboard, not building a new one. The UI can be rough for v1 (per the spec: "V1 can be rough — a CLI tool or a basic admin page is fine")
5. **Agent-assisted re-evaluation** — when stances need re-scoring under new framing, the existing `research-stances` skill (or something similar) should be reusable for proposing new values

## What's explicitly OUT of scope

- **No actual topic rewrites in this plan.** Plan D builds the *machinery*; actually rewriting healthcare/taxes/immigration is a separate operational task that runs through the workflow later.
- **No bulk rewrites.** The spec says "rewrites are paced through the review workflow, one topic at a time."
- **No voter-facing changes.** This is admin-facing plumbing.
- **No touching already-published topic versions** — append-only.

## Pre-planning considerations

As you design the plan, think about:

1. **Where does the workflow state live?** Options: a new `inform.topic_rewrites` staging table; a status column on `compass_topics`; a dedicated event/audit log. The current `compass_topic_roles` had unused scaffolding repurposed in Plan A — maybe there's similar abandoned scaffolding here. Check before designing.

2. **How do agents propose new stance values?** The existing `politician-stance-researcher` agent (at `.claude/skills/research-stances/`) produces structured stance proposals. That agent could be reused for re-evaluation if given the old stance + new framing as input. Worth investigating whether to extend it or build fresh.

3. **How does "atomic publish" actually work?** `compass_topics` has `is_live` and `version` columns. Publishing probably means flipping `is_live=true` on the new version while flipping `is_live=false` on the old version, plus updating `politician_answers.topic_id` references (or using `topic_key` as the effective join key). Pick one and document it clearly.

4. **How rough can v1 be?** Chris said "V1 can be rough — a CLI tool or a basic admin page is fine." Don't over-engineer the admin UI. A functional `TopicRewriteWorkflow.jsx` page that reuses existing admin patterns is probably enough.

5. **Human gates enforcement.** Both review gates are process decisions Chris makes. The system should make it impossible to skip them, but they don't have to be complex. A status column that only moves forward via explicit approval RPCs is fine.

## Pre-execution verification

Before dispatching any subagent for execution, verify:

- `inform.compass_topics` has `version`, `is_live`, `went_live_at` columns (query `information_schema.columns`)
- `compass_topic_roles`, `compass_stances`, `politician_answers`, `politician_context` all exist and have the expected shapes
- The existing admin dashboard at `CompassV2/src/components/admin/AdminDashboard.jsx` is routable and accessible
- A safe way to run against the dev database exists, OR Chris has authorized running against prod (Plan A and C ran against prod because the dev DB isn't in active use — default to prod unless told otherwise)

## Known gotchas from earlier sessions

1. **Nested git repos.** Monorepo at `/Users/chrisandrews/Documents/GitHub/` and inner repos (`ev-accounts`, `ev-ui`, `CompassV2`, `essentials`) are all separate. Backend changes commit to `ev-accounts/master`. The monorepo branch is for specs/plans only.

2. **Prod DB password was echoed in an earlier session.** Never echo `DATABASE_URL`. Extract project ID only: `echo "$DATABASE_URL" | sed -E 's|.*postgres\.([a-z0-9]+):.*|\1|'`.

3. **npm publish→dispatch race.** If Plan D adds ev-ui components and releases, the auto-bump in consumer repos may fail with `npm ETARGET`. Fall back to manual `npm install` in the affected consumer.

4. **Verify target pages before editing.** Don't edit a file just because its name matches a concept. Navigate to the deployed page via Playwright, confirm you're editing what voters see, THEN write the edit.

5. **Migration numbering.** The next available backend migration number is 061 (or whatever is higher than the latest in `ev-accounts/backend/migrations/`). Check before creating a new migration file.

## Authorization granted (matches earlier sessions)

- OK to apply migrations directly to production (dev DB not in active use)
- OK to publish new ev-ui versions if needed
- OK to push directly to any repo's main/master branch
- Pause for review if the plan grows beyond ~15 tasks or touches anything not covered by the spec's "Topic rewrite workflow" section

## Pause option

If after writing the plan the context window is already tight (say >60%), **stop and report the plan is ready for a separate execution session.** Plan writing alone produces a committed `.md` file that can be executed cleanly in a fresh session. Don't push through to execution if it risks hitting the auto-compression threshold mid-task.

## Success criteria

Plan D is complete when:
1. A plan document exists at `docs/superpowers/plans/2026-04-11-plan-d-topic-rewrite-workflow.md` covering all spec requirements with bite-sized TDD-style tasks
2. (If executed) The workflow state machine is implemented with both human review gates wired up
3. (If executed) Chris can run a test rewrite end-to-end on one topic without any stance data being silently invalidated
4. No voter-facing pages change behavior — this is admin-only infrastructure

Report back when the plan is written, when execution is complete, or when blocked.
