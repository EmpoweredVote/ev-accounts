---
status: proposed
---

> **Design stage, 2026-08-21. Nothing implemented.** Decided in a grilling session against the live
> schema; every number below was read from prod, not estimated. The migrations named here are
> proposed slots in the `CA_` namespace (`CA_0011`–`CA_0014`), not applied work.
>
> **`CA_0011` and `CA_0012` written 2026-08-21**, not yet applied. Writing them settled four things
> this document had left open or wrong; all are recorded in **§11** and corrected in place above. The
> proposed slots also moved: `CA_0003`–`CA_0006` were already taken on other remote refs (the `CA_`
> namespace is at `CA_0010`), so this is `CA_0011`–`CA_0014`.
>
> **Amended same day**, after the reader-facing requirement was sharpened to *"a public record of all
> changes, like Wikipedia, but easier to see the differences"*. Three things moved: the public record
> now lists **every** revision rather than only milestone versions (§3, §9); `public_note` is therefore
> `NOT NULL` on every revision rather than only substantive ones (§6); and §9–§10 were added to
> specify the diff surface and the stale-answer notice. **No schema change was needed to support any of
> it** beyond widening that one constraint — snapshots and `rung_map` already carried it.

# Versioning compass topics, stances and questions

Compass content — a topic's framing, its question, and the five-rung stance ladder that gives every
seated chair its meaning — is currently **mutated in place with no history**. We decided to split
**identity from content**: the existing `compass_topics` row becomes immutable identity, and all
editable prose moves into an append-only revision table that carries its own reasoning and its own
rung mapping. The same shape is applied to `essentials.readrank_questions`. Prior revisions stay
*servable*, not merely archived, and a public record renders every one of them with the differences
marked.

## Why now

This is the second attempt. The first one shipped and was never used once.

**Migration 061 (2026-04-11) already built this.** `compass_topics.version`, `is_live` and
`went_live_at` exist. `UNIQUE (topic_key, version)` and the partial `UNIQUE (topic_key) WHERE is_live`
exist, so multi-version rows have been *legal* for four months. There is an `inform.topic_rewrites`
state machine, eight `SECURITY DEFINER` RPCs including an atomic `admin_publish_topic_rewrite`,
`backend/src/lib/topicRewriteService.ts`, `backend/src/routes/topicRewrites.ts`, and
`CompassV2/src/components/admin/TopicRewriteWorkflow.jsx` wired into `AdminDashboard`.

`inform.topic_rewrites` holds **0 rows**. `topic_rewrite_stance_proposals` holds **0 rows**.
`public.admin_audit_log` holds **0** compass content actions of any kind — 89 `view_account_detail`
and 75 `readrank_quote.select`, but not one `compass:stance:batch-update`. All 44 topics and 220
stances were authored by direct SQL and the import RPC.

Two causes, and the design below is shaped around both:

**1. The publish gate was arithmetically impossible.** `admin_approve_rewrite_framing` seeds one
proposal per politician holding an answer on the topic; `admin_mark_rewrite_publish_ready` refuses to
advance while any proposal is `pending`. Rewording one rung of `taxes` therefore required a human to
individually approve or reject **2,014 rows**. `abortion` 1,902, `climate-change` 1,900,
`healthcare` 1,795. Nobody was ever going to do that, so nobody did.

**2. One surface was built for two roles that are not the same people.**
`admin_create_topic_rewrite` requires typing `title`, `short_title`, `question_text` and a `stances`
JSONB blob into a web form. Our authors are engineers and agents working in SQL and generator
scripts — they would have to abandon their tooling to use it. Our reviewers are the holders of
the **`Compass Stance Editor`** role and are mostly non-technical — they were never going to write
SQL. The form fit neither, and both routed around it: authors to migrations, reviewers to a Google
Doc.

Meanwhile the corpus was quietly losing its history. `max(version)` is 2; six topics sit at v2
(`ai-regulation`, `deportation`, `healthcare`, `housing`, `immigration`, `taxes`, all April 2026).
There are 44 rows and 44 distinct `topic_key`s and all 44 are `is_live = true` — so **every v1 row was
deleted.** The prior framing of six live topics exists nowhere in the database.

And we already know what the Doc costs, because we already paid it.
`backend/scripts/gen-compass-topics-reference.mjs` exists because
`data/stance-research/compass-topics-reference.md` was a hand-maintained human-readable description of
the ladders — the same artifact the Doc is now. It drifted from `inform.compass_stances`, and because
every stance-research run reads it, the drift became **wrong voter-facing positions**:
`ai-regulation` was documented inverted, so nine legislators who had *written AI-safety law* were
seated at the laissez-faire end (migration 1729 fixed them). The polarity class took another ten rows
(1730). `judicial-government-deference` was also inverted. Three live topics were listed as
deprecated. The file's own conclusion — never hand-edit it again; edit the generator or the ladders
and re-run — is the rule this ADR generalises.

## Decision

### 1. Identity is separate from content

`inform.compass_topics` **keeps its existing `id`** and becomes immutable identity. This is the load-
bearing choice: 32,887 `politician_answers`, 33,541 `politician_context`, 184 `compass_responses`,
52 `compass_topic_categories`, 84 `compass_topic_roles`, 24 `compass_lens_topics`, 183
`politician_context_evidence` and 51 `stance_research_review` rows all FK that id. Because the id
never moves, **versioning content touches none of them.** Nothing is copied forward; there is no
32k-row publish step; the 2,014-proposal gate cannot be rebuilt because there is nothing to propose.

This is exactly what 061 got wrong. Its versions were whole new `compass_topics` rows, so every bump
stranded ~750–2,000 answers per topic and demanded a copy-forward.

### 2. A revision is a topic **and its whole ladder**, atomically

Ladders do **not** version independently, and neither do individual rungs. Per `CLAUDE.md`, "the five
options are five distinct stances along a spectrum" — a rung's meaning is **relational**, fixed by
contrast with its neighbours. Rewrite rung 3 from *moderately raise* to *significantly raise* and you
have changed what rung 4 means without editing rung 4. A rung versioned alone is a rung whose meaning
drifted silently.

It is also what readers need: "Housing v3" is legible; "(topic v2 × ladder v5)" is not.

Empirically they co-change anyway — 6 of 1,736 migrations touch compass content at all, and the one
that edits stances (`062`) also edits topics.

### 3. Two-level identity: public `version`, immutable `revision`

Every write appends a row. Nothing is ever `UPDATE`d.

- **`revision`** — monotonic, bumps on *every* write including a comma fix. This is what the serving
  layer pins and what an answer records.
- **`version`** — the **citable milestone**, bumps only when `change_class = 'substantive'`. This is
  what a reader cites: "Housing v3".

Both are public. The record lists **every revision**, Wikipedia-style; `version` groups them into
milestones so a reader has a stable thing to name. What the two-level numbering buys is not
concealment — it is the difference between a name and an entry in a log.

The alternative considered and rejected was in-place `UPDATE` for editorial fixes with versions only
for substantive change. It fails three ways: the version row stops being immutable, which is the only
reason a prior version is trustworthy to serve; "what did this user see" becomes unanswerable once two
readers both saw "v3"; and "is this substantive?" becomes an unlogged judgement made at write time —
the same discretion that produced 0 rows in `topic_rewrites` and deleted six v1 rows. Misclassifying
a substantive change as editorial under the accepted design costs a wrong label. Under the rejected
one it costs the data.

Storage is snapshots, never diffs. A stored diff cannot render a prior version without replaying the
chain; any diff is computable at read time. At 44 topics this is not a cost worth discussing.

### 4. Ladder changes declare a rung mapping, not a per-politician review

`politician_answers.value` is a `numeric` **position**, not a stance reference — there is no
`stance_id` anywhere. So a ladder rewrite changes the meaning of every answer indexing into it, and
per `CLAUDE.md` polarity is not uniform (AI Oversight and Tariffs run inverted; Residential Zoning and
Growth Pace are off-axis entirely).

Each ladder revision therefore records an explicit `rung_map`: for each of the five rungs, `identity`,
a remap to a new rung, or `invalidated`. Answers are re-pointed mechanically where the map says
identity or remap, and flagged blank where it says invalidated — a blank spoke being the honest
outcome `CLAUDE.md` already prescribes. **That is five decisions per ladder change, not 2,014.**

### 5. Rollout: one current revision per topic, pinned per session

A partial unique index on `is_current` gives each topic exactly one current revision — the same trick
`is_live` uses today. `GET /api/compass/topics` returns each topic's `revision_id`; the client echoes
it back on every answer write and the server honours it for the remainder of that calibration. Staged
rollout is flipping the pointer at a chosen moment; in-flight users finish on the revision they
started. No cohort table, and no need for a durable anonymous identifier — which matters because
`/topics` is served anonymously through `supabaseAnon` and there is no session or attempt entity
anywhere in the schema today.

**Co-serving two revisions is permitted only when the rung mapping is identity**, enforced in the
database rather than by convention. The reason is hard: `compareWithPoliticians` joins
`compass_responses.topic_id` to `politician_answers.topic_id` and compares **raw rung numbers**.
Politicians are seated on exactly one ladder, and `CLAUDE.md` requires evidence describing *that
specific chair* — so we cannot seat 32,887 answers on two ladders at once. A cohort split across
different ladders would return a perfect match between answers to different questions, silently. That
is the defect class `CLAUDE.md` calls "an unevidenced claim expressed as a number."

So: framing prose (`title`, `short_title`, `question_text`) may be A/B tested with the ladder held
byte-identical. Ladders get a hard cutover.

`answered_revision_id` is added to `inform.compass_responses` (184 rows) and
`inform.compass_change_history` (1,818 rows), backfilled to each topic's revision 1. Without it, "you
answered this when the question read X" is unanswerable, no experiment is analysable, and a cutover
cannot distinguish stale answers from fresh ones.

### 6. Reasoning lives on the row, and there are two of them

`rationale TEXT NOT NULL` with a non-empty CHECK, authored by the proposer. A `NOT NULL` column is the
only version of "reasoning is captured" that cannot be skipped, and the reference-file incident is
proof that a separate document describing a row will drift from it. `review_ref` holds the URL of
wherever discussion happened.

A separate `compass_decisions` table was rejected: it can be empty while a revision is live, which is
precisely the `ORPHAN_CONTEXT` failure `CLAUDE.md` already fights on `politician_context`.

`rationale` is **internal and never served publicly.** A second field, `public_note TEXT NOT NULL`, is
the reader-facing summary of the change — an edit summary, in Wikipedia's sense.

Collapsing these into one field forces a choice between a self-censoring internal record and publishing
internal deliberation; *"the old rung 3 was polling as a dodge"* is a legitimate rationale and a
terrible public note.

`public_note` is required on **every** revision, not only substantive ones. This follows directly from
§9: if the public record lists every revision, an optional summary renders blank rows, which is the
known weakness of Wikipedia's optional edit summaries. At 44 topics and six content migrations in
1,736, a one-line summary per edit costs seconds.

### 7. Review: rendered diff and approve, in-app; discussion stays external

The reviewers are the four `Compass Stance Editor` holders and are mostly non-technical, so PR review
is out. But the Doc's failure is not that it's a Doc — it's that **the reviewed artifact is not the
artifact that ships**, which is what forces the hand-retyping step.

- **Authoring** stays where it demonstrably happens: the author's existing tooling (a `CA_` migration
  or a sync script) writes a `status = 'draft'` revision row.
- **Review** is a purpose-built admin page that renders current-vs-draft for the topic and all five
  rungs **as prose** — never YAML, never SQL — alongside the required `rationale` and `rung_map`, with
  Approve / Request-changes gated on `Compass Stance Editor`.
- **The reviewed row is the row that goes live.** Approved bytes are published bytes. No transcription
  step exists to be got wrong.

Threaded in-app comments (`compass_revision_comments`) are a deliberate **later** addition, not a
prerequisite: `review_ref` links out to the Doc or Slack thread in the meantime. 061 proves comment
machinery is worthless if the authoring ergonomics are wrong, so the ergonomics land first.

Approval and publication are **separate transitions** with separate actors and timestamps
(`approved_by`/`approved_at`, `published_by`/`published_at`), so an approved ladder cutover can be held
until a chosen moment.

### 8. ReadRank questions: same machinery, different gate

`essentials.readrank_questions` — 2,431 rows across 304 races and 40 `topic_key`s — gets the identical
revision model. The split generalises cleanly: `readrank_questions.id` stays as identity (it is FK'd
by `essentials.quotes.question_id`), and `question_text` moves into revisions.

The **gate** does not generalise. Migrations `1810_la_mayor_econdev_question_split.sql` and
`1813_repoint_la_mayor_readrank_questions.sql` show these are bulk-rewritten by research passes; a
per-row editor approval across 2,431 questions is 061's blocking gate rebuilt at 40× scale, and it
would take the rest of this design down with it. So `requires_approval` is a property of the content
class: `true` for compass topic revisions (44 rows, voter-facing semantics that define 32,887 seated
chairs), `false` for readrank question revisions (publish on write, `rationale` still mandatory).

A bulk-approve escape hatch was rejected: it becomes the default path and the record then claims
review that did not happen, which is worse than no gate.

`readrank_questions` and `meetings.meeting_topics` (580 rows) join compass by **`topic_key`**, not
`topic_id`, so they are already version-agnostic and follow the current revision automatically. No
change needed on that edge.

### 9. The public record is a full revision log with rendered diffs

> Scoped here, built later. It is recorded now because it constrains nothing and confirms two earlier
> decisions — and because getting it wrong later would mean re-opening the schema.

**Requires no schema change.** Revisions are full snapshots, so a comparison between any two of them
is a pure function of stored text, computable at read time, between *any* pair rather than only
adjacent ones. Nothing about diffing needs to be persisted.

**`rung_map` does double duty.** "We removed this whole stance and replaced it" versus "we reworded
it" is a *semantic* distinction that a text differ cannot make — if every word changed, a rewrite and
a replacement are indistinguishable to it. `rung_map` already answers it: `invalidated` means
replaced, `identity` with changed text means reworded. So the map chooses the presentation mode:

- **Replaced rung** — render the old and new as whole blocks, old marked as removed.
- **Reworded rung** — inline token-level marking within the rung.
- **Unchanged rung** — no marking at all, so changes stand out against a quiet ladder.

That was not why we added `rung_map`, but it means the answer-repointing decision and the diff surface
share one source of truth instead of drifting apart.

**Highlight, not bold.** On a dark ground, extra font weight reads largely as extra brightness, so the
perceptual gap between regular and bold compresses. A background highlight does not depend on weight
and survives both themes.

🔴 **A highlight alone is colour-only signalling** — it fails for colourblind and low-vision readers
and vanishes entirely for a screen reader. Marked text must therefore be real `<ins>` / `<del>`
elements, which carry "insertion" and "deletion" to assistive technology for free, with the highlight
as the visual layer on top. Never the highlight alone.

**Deliberate divergence from the Wikipedia model:** we list every revision and every summary, but we
do **not** publish who made the edit. Wikipedia attributes; we do not. Four named individuals against
politically-charged framing decisions is a different risk than a pseudonymous encyclopedia editor, and
the trust signal here is the reasoning, not the name. `proposed_by` / `approved_by` stay internal.

### 10. A user whose own answer is behind gets told, where they meet the topic

Also later work, but it is the reason `answered_revision_id` exists rather than a nice-to-have.

When a user's `answered_revision_id` is older than the topic's current revision, the topic shows an
inline notice: what changed, rendered as in §9, and a way to answer again. No email, no push.

**Only when the meaning moved.** Trigger on a `version` gap, not a `revision` gap — a comma fix must
never prompt anyone to revisit their position. This is the second thing the two-level numbering buys.

### 11. Decided while implementing CA_0011/CA_0012, not before

Three things this ADR left open or wrong, settled by writing the SQL. Recorded here because each one
is a decision, not a detail.

**`rung_map` has exactly one spelling.** This document originally offered
`identity | {"1":2,…} | invalidated`. Pinned to a single form: a JSONB object with exactly the keys
`'1'`–`'5'`, each value either an integer 1–5 or the string `"invalidated"`. An unchanged ladder is
written out in full as `{"1":1,…,"5":5}`. **There is no `identity` shorthand** — two spellings of one
fact is precisely how `compass-topics-reference.md` drifted. `NULL` means "no mapping applies" and is
legal only for revision 1 or a byte-identical ladder. Validated by
`inform.is_valid_rung_map()`, proved against 17 cases.

🔴 **The validator must use `CASE`, not a chain of `AND`s.** `jsonb_object_keys()` *raises* on a scalar,
so the type guard has to be evaluated before the key count. An `AND` chain happened to short-circuit
when tested against prod, but Postgres does not guarantee `AND` evaluation order, and the plan can
change once the expression is inlined into a `CHECK` over a populated column. `CASE` is documented to
evaluate in order. The migration carries this warning inline; do not "simplify" it.

**Drafts are not public.** This ADR said the record is anonymous-readable and did not say what happens
to unapproved rows. RLS reads are gated on `status IN ('published','superseded')`. `draft` and
`rejected` are withheld — publishing wording the team *refused* would misrepresent it as something we
considered saying.

**Immutability is enforced by trigger, not convention.** Content columns physically cannot be
`UPDATE`d; only `status` and `is_current` move. Append-only is the load-bearing property of the whole
design, and a convention will not hold it across future migrations written under time pressure — the
six deleted v1 rows are the evidence.

**The legacy tables are frozen for the transition.** Between `CA_0012` and `CA_0013`, both
`compass_topics` and the revision table hold `title`/`question_text`: two authoritative copies. An
in-place edit in that window would leave the revision stale, and `CA_0013`'s repoint would then
**silently revert published content to older text**. That is the worst available outcome of this
project. So content `UPDATE`s on `compass_topics`/`compass_stances` raise, pointing the author at the
new path. Safe to do abruptly precisely because `admin_audit_log` proves the in-place path has never
been used. `is_live`/`went_live_at`/`updated_at` stay editable so archiving a topic needs no exception.

### 11a. Corrected twice: the reviewer role has ZERO live holders

🔴 This ADR said "the four holders of the `Compass Stance Editor` role". I then corrected that to "one
holder". **Both were wrong.** The role has **no live holders at all.**

`public.user_roles` holds four grant rows for it. All four carry a `revoked_at` — granted and revoked on
2026-04-06/07, apparently while the role system itself was being tested. `public.get_user_roles(uid)`
filters revoked grants correctly, so `requireRole('compass_stance_editor')` currently admits **nobody**.

**Counting that table misleads twice over**, and both mistakes are easy:

1. **Rows are not people.** One user can hold several grants of the same role at different scopes.
2. **Rows include revoked history.** The table is append-only; a revoke sets a timestamp rather than
   deleting the row.

Use `get_user_roles(uid)`, or filter `revoked_at IS NULL`. `Campaign Manager` and
`Essentials Data Editor` are in the same state — zero live holders — which means
`routes/compassContributor.ts` and `routes/essentialsEditor.ts` are also currently unreachable. That is
pre-existing and out of scope here, but worth knowing before assuming any role-gated route has users.

### 11b. Approval admits admins as well as editors, and records which

Because of the above, gating approval on the role alone would have shipped a review queue that no
account on the platform could open — reachable from an admin dashboard, and rejecting every admin who
clicked it.

`requireCompassReviewer` therefore admits **either** a live `compass_stance_editor` **or** a member of
`public.admin_users` (two people: the two who would actually review). The role is checked first, so
someone holding both is recorded as an editor rather than flattened into an admin.

**The capacity is recorded, not discarded.** Every approve, reject and publish writes
`capacity: 'editor' | 'admin'` into its `admin_audit_log` details. Approving compass content is an
**editorial** judgement; admin access is a **technical** privilege. Collapsing the two would make an
admin's sign-off indistinguishable from an editor's in the record — and conflating an editorial role
with a technical one is the exact mistake that left migration 061 unused for four months. Admin is the
path that keeps the workflow usable; `compass_stance_editor` remains the intended one, and the record
will show which was used every time.

This also strengthens §7's rejection of an "author cannot approve their own draft" constraint. With one
holder it would deadlock often; with zero it is unimplementable.

## Schema shape

```sql
-- ── Identity (existing table, columns REMOVED) ────────────────────────────────
-- inform.compass_topics keeps: id, topic_key, office_scope, fc_community_slug,
--   judicial_role, created_at.  Gains: retired_at TIMESTAMPTZ.
--   LOSES to revisions: title, short_title, question_text, version, is_live,
--   is_active (GENERATED, must be dropped with is_live), went_live_at, updated_at.
-- The id does NOT change. No FK anywhere is touched.

CREATE TYPE inform.change_class AS ENUM ('editorial', 'clarifying', 'substantive');
CREATE TYPE inform.revision_status AS ENUM ('draft', 'approved', 'published', 'superseded', 'rejected');

CREATE TABLE inform.compass_topic_revisions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id        UUID NOT NULL REFERENCES inform.compass_topics(id) ON DELETE RESTRICT,

  revision        INT  NOT NULL,             -- immutable, bumps on EVERY write
  version         INT  NOT NULL,             -- public, bumps only on 'substantive'
  change_class    inform.change_class NOT NULL,

  title           TEXT NOT NULL,
  short_title     TEXT,
  question_text   TEXT NOT NULL,

  rationale       TEXT NOT NULL CHECK (btrim(rationale) <> ''),   -- internal, never served
  public_note     TEXT NOT NULL CHECK (btrim(public_note) <> ''), -- reader-facing edit summary
  review_ref      TEXT,                                          -- Doc / Slack / PR URL

  -- Exactly keys '1'..'5'; each value an int 1-5 or the string "invalidated".
  -- An unchanged ladder is written in full: {"1":1,...,"5":5}. No shorthand (§11).
  -- NULL only for revision 1, or a ladder byte-identical to its predecessor.
  rung_map        JSONB CHECK (inform.is_valid_rung_map(rung_map)),

  status          inform.revision_status NOT NULL DEFAULT 'draft',
  is_current      BOOLEAN NOT NULL DEFAULT false,

  proposed_by     UUID REFERENCES public.users(id),
  proposed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  approved_by     UUID REFERENCES public.users(id),
  approved_at     TIMESTAMPTZ,
  published_by    UUID REFERENCES public.users(id),
  published_at    TIMESTAMPTZ,

  UNIQUE (topic_id, revision),
  CHECK (NOT is_current OR status = 'published'),          -- a draft is never served
  CHECK (status NOT IN ('published','superseded') OR published_at IS NOT NULL)
);

-- RLS: public reads see published history only; drafts and rejects are withheld (§11).
ALTER TABLE inform.compass_topic_revisions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "compass_topic_revisions: public read published"
  ON inform.compass_topic_revisions FOR SELECT TO anon, authenticated
  USING (status IN ('published', 'superseded'));

-- Exactly one current revision per topic — the same trick is_live uses today.
CREATE UNIQUE INDEX compass_topic_revisions_one_current
  ON inform.compass_topic_revisions (topic_id) WHERE is_current;

-- The ladder. Nothing FKs inform.compass_stances today (verified), so this is free.
CREATE TABLE inform.compass_stance_revisions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_revision_id    UUID NOT NULL REFERENCES inform.compass_topic_revisions(id) ON DELETE CASCADE,
  value                INT  NOT NULL CHECK (value BETWEEN 1 AND 5),
  text                 TEXT NOT NULL,
  description          TEXT,
  supporting_points    TEXT[] NOT NULL DEFAULT '{}',
  example_perspectives TEXT[] NOT NULL DEFAULT '{}',
  UNIQUE (topic_revision_id, value)
);

-- Answer provenance.
ALTER TABLE inform.compass_responses
  ADD COLUMN answered_revision_id UUID REFERENCES inform.compass_topic_revisions(id);
ALTER TABLE inform.compass_change_history
  ADD COLUMN answered_revision_id UUID REFERENCES inform.compass_topic_revisions(id);

-- Compat view reproducing TODAY's exact column shape, so the ~13 backend files
-- that read compass_topics migrate with a one-line change.
CREATE VIEW inform.compass_topics_live AS
SELECT t.id, t.topic_key, r.title, r.short_title, r.question_text,
       true AS is_live, true AS is_active, r.version, r.published_at AS went_live_at,
       t.office_scope, t.fc_community_slug, t.judicial_role,
       r.id AS revision_id, r.revision
FROM inform.compass_topics t
JOIN inform.compass_topic_revisions r ON r.topic_id = t.id AND r.is_current
WHERE t.retired_at IS NULL;

CREATE VIEW inform.compass_stances_live AS
SELECT s.*, r.topic_id
FROM inform.compass_stance_revisions s
JOIN inform.compass_topic_revisions r ON r.id = s.topic_revision_id AND r.is_current;
```

`essentials.readrank_question_revisions` mirrors this exactly, minus `rung_map` (no ladder), with
`requires_approval = false` on the class.

**Naming note.** `inform.compass_change_history` already exists and is *user answer* history (1,818
rows), unrelated to content. The new tables are deliberately `*_revisions` to avoid the collision.

## Migration path

`CA_` is its own slot namespace (`CA_1849` and `1849` are different slots). Global numbering is at 1848. `git fetch origin` before reading either — the check scans
every remote-tracking ref.

1. **`CA_0011`** — create the revision tables, enums and indexes. No data movement. Non-breaking.
2. **`CA_0012`** — backfill all 44 topics from the current rows as `revision = 1`, `is_current = true`,
   `status = 'published'`, `change_class = 'substantive'` (founding content, not an edit),
   `rung_map = NULL`, with a `rationale` recording that the original reasoning was never captured. Copy
   the 220 ladder rows. Stamp `answered_revision_id` on every `compass_responses` and
   `compass_change_history` row. Create both compat views. Arm the legacy freeze (§11).
   🔴 **CLEAN SLATE: all 44 topics are `version = 1`, `revision = 1`.** Decided 2026-08-21. Six topics
   carry `version = 2` in the legacy column and their v1 content was deleted in April; that content is
   **not recoverable and we are not reconstructing it.** This ADR went back and forth here: the first
   draft said version 1, an intermediate draft carried the legacy 2 forward, and the final decision is
   version 1 for everything. The record begins now; only revisions written *after* this migration carry
   history.
   `public_note` is therefore **uniform across all 44** — *"First tracked version of this topic."* That
   is true of every one and asserts nothing about what came before; it is not a claim that a topic has
   never changed. The fact that six of them *were* edited pre-tracking is preserved in `rationale`,
   which is internal and never served, so the team keeps the knowledge without a version-2 signal
   reaching readers. The backfill must not invent prior wording under any circumstances.
   Accepted consequence: until `CA_0013` drops `compass_topics.version`, that column reads 2 for those
   six while the revision reads 1. Nothing reads the revision `version` until the repoint, and
   `CA_0013` removes the disagreement by deleting the older of the two.
   🔴 **Assert invariants, not literal counts.** `compass_change_history` went from 1,818 to 1,819 rows
   during the hour this ADR was drafted. The gate asserts "nothing left `NULL`" and "revision text
   equals source text", never a hardcoded number.
3. **`CA_0013`** — 🔴 **first** `DROP` the two freeze triggers from `CA_0012`: they are
   `UPDATE OF <column>` triggers holding references to the very columns this step removes, and
   `DROP COLUMN` will not step over a dependent trigger. **Then** repoint the ~13 backend files to
   `compass_topics_live` / `compass_stances_live`,
   then drop `title`, `short_title`, `question_text`, `version`, `is_live`, `is_active`, `went_live_at`
   from `inform.compass_topics`. `is_active` is `GENERATED ALWAYS AS (is_live)` and must be dropped
   with it. **Ship the repoint before the drop**, in that order, in a shared-blast-radius schema.
4. **`CA_0014`** — the same split for `essentials.readrank_questions` (2,431 rows), keeping its `id` so
   `essentials.quotes.question_id` is untouched.
5. Then, and only then, drop the superseded 061 machinery: `inform.topic_rewrites`,
   `topic_rewrite_stance_proposals`, the eight RPCs, `topicRewriteService.ts`, `routes/topicRewrites.ts`
   and `TopicRewriteWorkflow.jsx`. Both tables are empty, so this loses nothing.

Every migration idempotent, with a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s on a wrong
count, dry-run against prod under `BEGIN; ... ROLLBACK;` first. House style.

## Consequences

- **Full history, and it is servable.** Immutable snapshots mean any prior revision can be rendered or
  served, which is the actual requirement — not an audit log.
- **The public record is anonymous-readable and lists every revision** — date, `public_note`, and a
  rendered diff against any other revision, with substantive ones marked as milestone versions. It
  deliberately omits `proposed_by`/`approved_by`. It fits how `/topics` is already served (anon,
  public-read RLS).
- **`public_note` is now on the critical path of every write.** A `NOT NULL` reader-facing summary is a
  real obligation on authors and on any script that writes a revision. A migration or generator that
  writes revisions must supply one, and "n/a" defeats the point — this is the one place where the
  design depends on discipline rather than a constraint, because the constraint can only check that the
  field is non-empty, not that it is useful.
- **Ladder A/B testing is now impossible by construction.** That is intended. Framing-prose A/B stays
  available.
- **Two write paths still exist** for revision rows: `CA_` migrations and the admin draft flow. They
  are both append-only against the same table, which is safe, but there is no single authority on
  *ordering*, and this repo has no `schema_migrations` table and no runner. Watch for it.
- **`data/stance-research/compass-topics-reference.md` must be regenerated from the current revision**
  and its `--check` extended, or it drifts again — and that drift is a voter-facing error, not a docs
  bug. Migrations 1729 and 1730 are the receipts.
- **Deferred, explicitly, not overlooked:** the public diff record and the stale-answer notice (§9,
  §10) are specified but unbuilt — they need no schema beyond what is above, which is why they are
  recorded here rather than left to be rediscovered; in-app threaded comments; adding `stance_id` to
  `politician_answers` to make rung meaning structural rather than positional (the real fix for §4, at
  the cost of a 32,887-row backfill and a read-path change in every consumer).
- **Closed, not deferred:** reconstructing the six deleted v1 revisions from git. Decided against on
  2026-08-21 — the backfill records them as the first tracked version and says so in `public_note`.
