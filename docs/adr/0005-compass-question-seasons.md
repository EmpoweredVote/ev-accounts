---
status: accepted
---

> **Rewritten 2026-08-27. The first version of this ADR designed a model that already existed.**
> It was written on 2026-08-24 against a schema snapshot that was already stale, at the end of a
> long session, and it proposed `inform.compass_seasons` and `inform.compass_season_topics` from
> scratch. Meanwhile PR #177 — *"feat(compass): season model for answers, plus two live data-loss
> fixes"* — had landed `inform.seasons` and `inform.season_questions` in the middle of that same
> session, and the session pulled the code repeatedly without noticing. Master moved from PR #145
> to #181 in that window, roughly 36 PRs by other people.
>
> This is the same failure ADR 0004 documents at length about migration 061: **designing something
> already shipped.** It is recorded here rather than quietly fixed, because the mistake is cheap to
> repeat and the cure is not cleverness — it is reading the database before writing about it.
>
> Every count below was read from prod on **2026-08-27** unless dated otherwise.

# Seasons of compass questions

ADR 0004 answered *what did a question say, and when did it change*. This ADR answers **which
questions are asked, of whom, right now** — a separate thing on a different clock.

Season 1 is the 44 topics live today. Season 2 will reuse some, add some, and retire some. Seasons
arrive irregularly — plausibly every six months, more often around elections. Eventually a season is
**hyper-individualised**: Season 2 for Portland OR need not match Season 2 for Bedford IN.

**The core of that is built.** The per-jurisdiction half is not. This document separates the two, so
that nobody designs the built half a second time.

---

## Part 1 — What is actually built

Shipped in PR #177: `CA_0017`, `CA_0018`, `CA_0019`, `CC_0002`, `CC_0003`, and
`backend/src/lib/seasonService.ts`. Read `seasonService.ts` first — it is short, and its comments
carry the reasoning that the rest of this section summarises.

### 1.1 The two tables

```
inform.seasons          id, number, name, status, opened_at, closed_at,
                        public_note, created_at, updated_at
inform.season_questions season_id, topic_id, topic_revision_id,
                        question_number, display_order
```

`status` is an enum `(draft, open, closed)`. A partial unique index `seasons_one_open` allows **at
most one open season**, and a `CHECK` (`seasons_dates_follow_status`) keeps the dates honest: a
draft has neither timestamp, an open season has `opened_at` and no `closed_at`, a closed season has
both.

`season_questions` is the question set: one row per topic, `PRIMARY KEY (season_id, topic_id)`, with
`question_number` and `display_order` unique within the season. `question_number` is a human-facing
label, **not identity** — seeding joins on `topic_id`.

Live: 1 season (Season 1, number 1), 44 question rows.

### 1.2 Answers carry their season and their pin

`season_id` and `topic_revision_id` are on `politician_answers`, `politician_context` and
`politician_context_evidence`. Both are `NOT NULL` on answers. All **33,164** answers are backfilled
to Season 1.

The primary key of `politician_answers` is now **`(politician_id, topic_id, season_id)`**. After
`CC_0002`, `(politician_id, topic_id)` is no longer unique in principle, and **any consumer joining
on the bare pair is wrong** — it fans out the moment a second season exists.
`npm run check:answer-seasons` is the gate; it passes today, RPCs included.

### 1.3 🔴 Season membership pins the revision — this ADR's first version said it should not

The original argued: a season references *topics*, not revisions, because `answered_revision_id`
already records wording provenance on the answer, so pinning "would fuse the two axes back together
and buy nothing."

**The shipped model pins `topic_revision_id` in `season_questions`, and it is right.** The reasoning,
from `seasonService.ts`:

> `topic_revision_id` comes from the season's pin, never from the caller and never from "whatever is
> current". That is the entire point of the pin: the answer records which ladder text it was an
> answer to.

Three things the original missed:

1. **It solved a different table.** `answered_revision_id` is on `inform.compass_responses` — the
   **voter** side. The politician side had no such column until `CA_0018`. The provenance it relied
   on did not exist where it was needed.
2. **Provenance on the answer is written at answer time; the pin is decided at season-open time.**
   They differ whenever a ladder is reworded mid-season. Without the pin, two people answering "the
   same question" in one season answer different texts, and the season cannot say which it asked.
3. **A pin is a promise a season can keep; a per-answer stamp is only a record of what happened.**
   The pin makes "what was this season asking?" answerable without reading a single answer.

The cost the original correctly feared — two axes coupled — is real but small: publishing a revision
does not disturb a season, because the season keeps pointing at the old revision id. That is the
feature, not the coupling.

Today all 44 pins equal their topic's current revision, so the pin is a verified no-op. It stops
being one the first time a revision is published mid-season — which the open
`judicial-bail-pretrial` draft would do.

### 1.4 🔴 Answerability IS season-gated — this ADR's first version said it must not be

The original said, and ADR 0004 §12 agreed in red:

> Promotion decides what we ASK; it must never decide what may be RECORDED.

**The shipped model overrules this for writes, and enforces it in the schema.** `UPSERT_ANSWER_SQL`
sources its `INSERT` from `season_questions JOIN seasons … status = 'open'`, so a topic outside the
open season cannot receive an answer. That is not merely a query convention:

- `politician_answers.season_id` and `.topic_revision_id` are both `NOT NULL`.
- `politician_answers_pin_fkey` is a composite FK onto
  `season_questions(season_id, topic_id, topic_revision_id)`.

An answer to an unasked topic **has no pin and cannot be inserted.**

**The fear behind the original was already answered elsewhere.** "Retiring a topic must never delete
answers" holds absolutely — but it is a statement about *existing* answers, and it is satisfied by
reads, not by permissive writes. `seasonService.newestAnswerLateral` resolves the newest season in
which **this person** answered **this topic**. Reads follow the person; writes follow the calendar.
A Season 1 answer stays readable forever, no matter what Season 2 asks.

So the two questions the original ran together separate cleanly:

| | Season-dependent? | Enforced by |
|---|---|---|
| May an **existing** answer survive its topic leaving a season? | **No.** Untouched. | `newestAnswerLateral` |
| May a **new** answer be written outside the open season? | **Yes.** Refused. | `politician_answers_pin_fkey` |

The full correction is in [ADR 0004 §12](0004-compass-content-versioning.md), where the original red
paragraph is struck through rather than deleted.

### 1.5 Writes fail closed, and callers must check

`UPSERT_ANSWER_SQL` is one statement on purpose: reading the open season and then inserting would
leave a window in which the season closes between the two. Sourcing the `INSERT` from the join
closes it — **if no season is open, nothing is written and nothing errors.**

🔴 **Zero rows is not success.** Every caller must use `assertWritten`, which distinguishes the two
causes (no open season / topic not in this season's set). All **seven** call sites do:
`researchEvidenceService` (×2), `stagingService`, `adminService`, `compassContributor` (×3).

`DELETE_ANSWER_OPEN_SEASON_SQL` is deliberately scoped to the open season. Unconstrained, that
`DELETE` would remove the person's answer in **every** season — destroying a closed season's record,
the one thing seasons exist to prevent.

### 1.6 The rollout is sequenced, and it is not finished

`CC_0002` left two scaffolding unique indexes up **on purpose**:
`politician_answers_legacy_pair_scaffold` and `politician_context_legacy_pair_scaffold`. Both are
live. While they are up, the database **physically cannot hold a second season** — which is an
interlock, not an oversight. The documented order is:

1. Deploy the season-aware code. ✅ merged in PR #177
2. Migrate the five RPCs. ✅ `CC_0003`, all five verified season-aware in prod
3. **Drop the scaffolding indexes.** ← not done
4. **Open Season 2.** ← not done
5. **Add the closed-season immutability trigger.** ← not done

Step 5 matters and is easy to forget: nothing at the schema level currently stops a write into a
*closed* season. Today the write paths cannot do it, because they only ever target the open one. A
direct write could.

---

## Part 2 — The live problem this created, and what to do about it

> **Resolved 2026-08-27 by `CA_0020` — see §2.1. This section describes the state from 2026-08-26
> to 2026-08-27 and is kept because the failure is worth understanding, not because it is current.**

**Season 1 was `closed` and no season was `open`.** By §1.5 that means every compass write path
refused. Verified at the time: the five RPCs raised `NO_OPEN_SEASON` / `NO_OPEN_SEASON_FOR_TOPIC`,
and every `backend/src` write path threw from `assertWritten`.

**The data stayed safe and the refusals were clean. But compass writing was down for a day.** That
was not a defect in `seasonService` — its own comment says so plainly — it was the honest state of
the data. It became an outage rather than a handover because step 3 above never happened, so Season
2 could not follow Season 1 as `CA_0019` assumed it would.

⚠️ **The lesson, which outlives the incident.** A migration that leaves the system in a state only
the *next* migration makes usable has created a deadline, not a handover — and nothing in the repo
records that deadline or notices when it passes. `CA_0019` closed Season 1 on the reasonable
assumption that Season 2 was days away. No mechanism existed to notice that it was not.

### 2.1 Decision: reopen Season 1 rather than rush Season 2 (`CA_0020`, applied)

> ✅ **Applied to production 2026-08-27.** Season 1 is `open`; 44 topics are writable; the 33,164
> answers and 33,818 context rows are unchanged; both scaffolding indexes are still up, so Season 2
> stays blocked by design. The write path was proved restored, not assumed: the real
> `UPSERT_ANSWER_SQL` shape affected 1 row in a rolled-back probe, having affected zero before.
> **The outage described above is over.**


Set Season 1 back to `open`. This **supersedes a deliberate decision in `CA_0019`**, which created
it closed because "it is a record of what already happened, not an invitation to write more into
it." That reasoning was sound on its own assumption — that Season 2 would open shortly. It did not.

Opening Season 2 instead would also fix the outage, and it is where we are going. It was rejected
*for now* because it changes two things at once: it turns the season model on **and** exercises the
changeover, and it requires step 3, which `CC_0002` calls irreversible. Reopening Season 1 changes
**one** thing, against a question set already known to be correct, and is reversible by setting the
status back.

⚠️ **The accepted cost.** Season 1 stops being a sealed record. New answers land beside the 33,164
backfilled ones with nothing in the row to tell them apart. `CA_0020` rewrites the season's
`public_note` in the same statement, because that note is reader-facing and currently claims "every
answer written up to 2026-08-25 is recorded here" — false the moment anyone writes. The
editor-of-record attribution is untouched: `editor_id` is per row.

### 2.2 A season refusal is not an internal error

The HTTP write paths turned `assertWritten`'s message into a generic **500 `INTERNAL_ERROR`**,
putting the one sentence that says what to do into a server log the operator cannot read. Fixed:
`assertWritten` now throws a typed `SeasonWriteError` carrying `reason` and `topicId`, and
`compassContributor` answers **409** with the message. 409 rather than 400 — the request is well
formed; the server's state is what conflicts.

---

## Part 3 — What is genuinely new and not yet built

`season_questions` has no column for any of this. None of it is a re-design of Part 1.

### 3.1 Per-jurisdiction variation

> "Season 2 for Portland OR might look different than Season 2 for Bedford IN."

**Decided: one base set per season, plus per-jurisdiction adjustments.**

```sql
ALTER TABLE inform.season_questions
  ADD COLUMN jurisdiction_geoid TEXT,        -- NULL = the base set, applies everywhere
  ADD COLUMN disposition inform.season_disposition NOT NULL DEFAULT 'include',
  ADD COLUMN note TEXT;                      -- why this place differs
-- PK becomes (season_id, topic_id, COALESCE(jurisdiction_geoid, ''))
```

Resolution: **base includes, minus that jurisdiction's excludes, plus that jurisdiction's includes.**

**Rejected: one season row per jurisdiction.** Simpler to read, but it multiplies rows by
jurisdiction count and makes "what changed in Season 2 *everywhere*" unanswerable without diffing
thousands of sets.

**Rejected: rules instead of lists** (include topics tagged X for district type Y). It scales
without enumerating, but "what exactly does Bedford see" becomes a computation rather than a fact —
hard to review, and hard to explain to a voter who asks why they were shown a question.

⚠️ **The known cost.** Include/exclude resolution is a rule system, and rule systems get confusing at
the third exception. The base set must stay the overwhelmingly common case; if per-jurisdiction rows
start outnumbering base rows, that is the signal this was the wrong model.

🔴 **The pin must survive this change.** Whatever shape the columns take, every resolved row must
still carry a `topic_revision_id`, and `politician_answers_pin_fkey` must still find it. A
per-jurisdiction include that omits the pin would reintroduce exactly the unpinned answer §1.3
exists to prevent.

### 3.2 Per-season, per-jurisdiction lens membership

> "As part of seasons, we would select which topics are in each lens."

Live today: `inform.compass_lenses` (3 rows — `federal`, `judicial`, `local`) and
`compass_lens_topics` (8 topics each), auto-selected by `auto_district_types`. **Neither has a
season or jurisdiction dimension.**

**Decided: lens membership is curated per season AND per jurisdiction**, taking the same shape as
season membership.

🔴 **RESOLUTION ORDER, and it is the whole ballgame.** Two include/exclude layers now stack, so the
order must be written down rather than inferred:

1. Resolve the **season** for the jurisdiction: base includes − local excludes + local includes.
2. Resolve the **lens** for the jurisdiction: lens base − local excludes + local includes.
3. **Intersect.** The lens set is `lens_resolved ∩ season_resolved`.

**The season always wins.** A lens must never promote a question the season excluded for that place,
or the lens becomes a back door around the promoted set.

🔴 **A lens-level include naming a season-excluded topic is a contradiction, not an input to be
silently resolved.** Step 3 would swallow it — the topic simply vanishes — and the curator would
never learn their instruction did nothing. That case must be **reported**, by a check or an admin
warning, not absorbed.

⚠️ **Accepted cost.** Chosen over per-season-only lens membership, which would have had one layer
instead of two. Consequences to watch: a lens can resolve to fewer than 8 topics, so nothing
downstream may assume a fixed count; and "why did Bedford get this question" now requires reading two
layers plus an intersection. If lens overrides become routine rather than exceptional, collapse this
back to per-season-only.

### 3.3 The voter side is not season-aware at all

**Newly identified 2026-08-27, and not on anyone's list.** The shipped model touched only the
politician side. `inform.compass_responses` has `answered_revision_id` and **no season column**.

The first version of this ADR proposed `answered_season_id` there, and that proposal stands
unbuilt. Two questions need it. "You calibrated in Season 1; Season 2 asks four new questions" is a
prompt worth showing, and it requires knowing which season the person answered under. And a compass
rendered a year later should be explainable as *the season it was built from*, rather than silently
reinterpreted against the current set.

⚠️ Do not assume the politician-side design ports over unchanged. A voter is not researched by an
editor, so the failure modes differ, and `compass_responses` has a soft-delete (`deleted_at`) that
`politician_answers` does not.

### 3.4 Retiring a topic must never delete answers

🔴 Unchanged, and now enforced by construction — see §1.4. A topic dropping out of the active season
stops it being *asked*. It does not unmake the fact that someone answered it, nor unseat a
politician's evidenced stance. Matching may still use those answers where both sides have one.

### 3.5 One active season per jurisdiction

Today's `seasons_one_open` index enforces one open season **globally**, which is the correct
constraint while seasons have no jurisdiction dimension. Once §3.1 lands, "one active season per
jurisdiction" replaces it, and the index must change with it — a global partial unique index cannot
express a per-jurisdiction rule.

In-flight calibrations should finish on the season they started, reusing the session-pinning
mechanism ADR 0004 §5 built for revisions.

**Rejected: overlapping seasons with cohort assignment.** It would allow testing a season before
full release, but it hits the same trap as ladder A/B — two people's compasses become
non-comparable, and matching gets murkier because the topic *sets* differ, not just the wording.

---

## Part 4 — The views, and the read path

### 4.1 `CA_0013` was applied but never recorded

All four views it created are live in prod. Its migration file existed **only** on the unmerged
branch `wip/ca0013-repoint` — so prod carried four objects with no source anywhere on master.
Landed on master 2026-08-27, marked as applied. `CA_0017`'s header claim that "CA_0013 and CA_0014
stay unused" is false and should not be trusted.

All four were read by **zero** callers.

### 4.2 Decision on each view (`CA_0021`, applied)

> ✅ **Applied to production 2026-08-27.** `compass_topics_promoted` returns the open season's 44
> topics; `compass_topics_answerable` is gone; the content views are untouched at 44 and 220.
>
> ⚠️ **It took two applies, and the reason is worth keeping.** The first apply recreated the view
> with `ev_api`'s privileges intact — those come from `ALTER DEFAULT PRIVILEGES` — but **silently
> lost the `anon` and `authenticated` SELECT grants** that `CA_0013` had granted explicitly.
> **`DROP VIEW` takes the grants with it and nothing warns you.** Nothing read the view yet, so
> nothing broke; but the compass reference reads go out over PostgREST as `anon`, so the first
> caller repointed onto it would have hit a permission error that looked like a code bug. Caught by
> reading `information_schema.role_table_grants` back after applying — not by the migration's own
> gate, which passed. The gate now asserts all three roles can `SELECT`, verified by mutation, and
> the migration re-applied clean. **A post-verify gate that only counts rows will not notice that
> the rows are unreadable by the roles that matter.**


| View | Decision | Why |
|---|---|---|
| `compass_topics_current` | **Keep** | Content. Season-independent. Correct as built. |
| `compass_stances_current` | **Keep** | Same. |
| `compass_topics_promoted` | **Redefine** against the open season's question set | Right name, wrong authority — `is_live` can never notice a season dropping a topic. |
| `compass_topics_answerable` | **Drop, do not replace** | Filters nothing, *and* names a rule the shipped model overrules. See ADR 0004 §12. |

`is_live` is **not** dropped and `CA_0021` does not touch it. The admin Topics page reads and writes
it as a live archive/unarchive toggle, and there is no equivalent on `compass_topic_revisions`. It
stops being the *authority* on promotion; it does not stop existing. Retiring it needs that control
replaced first.

The redefined `compass_topics_promoted` is **not yet jurisdiction-aware** — §3.1 is what makes it so,
and only its `WHERE` has to change.

🔴 **`CA_0021` refuses to install if no season is open.** Its post-verify gate raises when the
redefined view returns 0 rows, naming `CA_0020` as the fix. A promoted view that silently returns
nothing is exactly the failure the gate exists to prevent, and a view cannot raise on an empty
result at read time — so it is caught at install time instead.

### 4.3 The read-path repoint: what shipped and what is deferred

⚠️ **Branch `wip/ca0013-repoint` (`db390b33`) must not be merged.** It was written before seasons
were discovered. It is a source of ideas, not a diff.

**A correction to the record**, because it changes the fix: the WIP does **not** bypass the season
gate, as was first reported. The gate is structural (§1.4) and the repointed line is a *pre-flight
validator*, not the write. What the WIP actually does is **desynchronise the validator from the
write**: today both mean "all 44 topics", so it is a no-op; after a season drops a topic, the
validator passes and the write throws. The user-facing failure degrades from a clean 422 naming the
bad topic ids into an exception from deeper down. That is a real defect, and a different one.

**Shipped now — the content repoint.** Text sources moved to `compass_topics_current` /
`compass_stances_current` in `readrankService` (×3), `routes/essentials.ts`, `topicsService` (×2),
`meetingsService` and `compassStatsService`.

The value is not cosmetic. `CA_0012` froze `compass_topics`' own text columns, so **publishing a
revision currently changes nothing a user sees.** This repoint is what makes the review workflow
reach the UI. Verified as a no-op against prod before shipping: 0 title, short_title and
question_text drift across all 44 topics, 0 text drift across all 220 stances.

🔴 **The pattern, and it matters.** ADR 0004 §12 classified these readers as pure content. They are
not — several carry an `is_live` kill switch, and `compassStatsService` *returns* `is_live` in its
response. So the repoint **moves only the text source** and adds `compass_topics_current` as a
second join; every existing filter keeps reading `compass_topics`. `compass_topics_current` has no
`is_live` column, so moving a kill switch onto it would not error — **it would silently delete the
condition** and resurrect retired topics into a voter-facing surface. Three regression tests in
`readrankService.test.ts` guard this, and were confirmed to fail when the switch is removed.

**Shipped — the promotion repoint.** `getCompassTopics` and `getCompassCategories` now resolve their
topic set through one shared `getPromotedTopics()`, reading `compass_topics_promoted`. `is_live` is
no longer the filter. It is still *selected*, because it remains in the endpoint's response
contract; so is `office_scope`, which is dead (NULL on all 44) but whose removal is an API change
that belongs in its own commit.

Proved equivalent against prod before shipping: same 44 topics, 0 membership difference, 0 text
difference, and the 52 category/topic pairs unchanged.

🔴 **`getPromotedTopics()` throws on an empty result instead of returning `[]`.** This is the guard
that makes the repoint safe. The old query could only return nothing if someone had un-lived all 44
topics by hand; this one returns nothing whenever no season is open — a state that really happened,
for a day. `[]` would render an empty compass to every voter and report success. A view cannot raise
on an empty read, so the caller must.

⚠️ **The categories query could no longer use a PostgREST embed.** It selected
`compass_topics!inner(…)` filtered on `is_live`. Embedding is inferred from a foreign key, and
`compass_topics_promoted` is a view with none — so the join rows are now fetched alone and the topic
body comes from the promoted set by id. That also fixed a second latent problem there: the embedded
columns came from `compass_topics`, whose text `CA_0012` froze, so **that endpoint could never have
shown a published revision.**

⚠️ **Found while verifying: the topic order was already unstable.** Both the old and new queries
order by `created_at`, which holds only **28 distinct values across 44 topics** — two timestamps
cover 10 and 8 rows. Postgres does not promise an order for ties, so those 18 topics could come back
differently between requests. Pre-existing, not introduced here, and fixed with a `topic_key`
tiebreaker; with it the new ordering matches the old exactly.

`display_order` — the season's own ordering — was **deliberately not adopted.** `CA_0019` seeded it
as `row_number() OVER (ORDER BY topic_key)`, and 43 of 44 positions differ from what voters see
today. Switching is a product decision, not a side effect of a repoint.

**Shipped — the write validators.** `compassContributor`'s pre-flight now asks the same question the
write asks. It checked `is_live = true`, which is promotion state and not the write gate at all; the
two agreed only because all 44 topics are both live and in Season 1.

The gate is defined **once**, as `WRITABLE_TOPIC_IDS_SQL` in `seasonService`, immediately beside
`UPSERT_ANSWER_SQL` and sharing its `season_questions JOIN seasons … status='open'` clause. A test
asserts both statements contain that same join, so tidying one breaks the build.

⚠️ **It deliberately does not read `compass_topics_promoted`.** That view additionally inner-joins
`compass_topics_current`, so a topic in the open season that lacked a current revision would be
absent from the view while remaining perfectly writable — a validator rejecting a write the database
would accept. The view answers *what do we ASK*; the pre-flight answers *what may be RECORDED*.

Three consequences worth naming:

- **A no-open-season refusal is no longer reported as "your topic ids are invalid."** Rejecting every
  id because the server has no open season is not a caller error, and saying so sends them to debug a
  correct request. `writableTopicIds` throws `SeasonWriteError` for that case, which the route
  answers as 409; genuine per-topic problems stay 422 and name the ids.
- **The single-write path returned 404 and now returns 422.** The topic is not missing — it exists and
  may hold answers from an earlier season. What is absent is *this season's question about it*.
- **The sources endpoint had no pre-flight at all**, relying on `assertWritten` firing mid-loop — and
  that loop has no transaction, so a refusal on the fourth source left the first three written. It now
  checks every topic before writing anything. ⚠️ This does **not** make the loop atomic; any other
  mid-loop failure still leaves earlier rows written. That wants a transaction and is untouched here.

Verified identical on today's data: the pre-flight and the old `is_live` check both accept all 44
topics, 0 difference. A unit test pins the divergence that arrives with Season 2 — a topic dropped
from the season is not writable even though it is still `is_live`, still exists, and still holds
Season 1 answers.

**Shipped — `validateTopicIds`.** It gates a **voter's** topic selection (`selected_topic_ids`), so it
asks a *promotion* question — "do we ask this?" — and now reads the promoted set instead of
`is_live`. Same defect class as the pre-flight, opposite answer: **these two must not be merged.**
`writableTopicIds` asks what may be *recorded*; `validateTopicIds` asks what may be *selected*. They
agree on 44 topics today and diverge the first time a season retires a topic that still holds
answers.

🔴 **It derives from `getPromotedTopics()` rather than running its own query.** A voter must be
allowed to select exactly what `getCompassTopics` offered them; two queries answering that from
different places is how a UI ends up showing a topic the save endpoint then rejects. Sharing the
resolver makes that impossible rather than merely unlikely, and it inherits the empty-set guard.

That guard matters here more than anywhere. With no open season the promoted set is empty, so a naive
check reports **every id the voter submitted as invalid** — telling them their perfectly good
selection is wrong when the server is the thing misconfigured. `getPromotedTopics` now throws a typed
`NoPromotedTopicsError` carrying a `code`, and both routes map it to **503**: the request was fine,
the service cannot serve it. `PUT /compass/selected-topics` returned 500 for this; the Connect import
route returned 500 too.

The 422 message also changed. It said topics were "invalid or not live"; a topic can exist, be
perfectly live, and simply not be one this season asks.

⚠️ **`connectService.validateCompassVersions` was deliberately left alone.** It validates an
**import**, and an imported calibration may legitimately name a topic we no longer ask. It stays
permissive on the content view. Folding it into the season would reject exactly the historical
calibrations it exists to accept.

---

## Consequences

- **Season changeover is a content event with a public note**, like a revision. Seasons should appear
  in the transparency surface ADR 0004 §9 established.
- **The review workflow generalises.** A proposed season is a draft set awaiting approval, with the
  same gate and the same "the reviewed thing is the published thing" property. It should reuse
  `compass_topic_revisions`' lifecycle rather than invent a parallel one.
- **`/compare` gets a new failure mode.** Two users in different jurisdictions may hold answers to
  different topic sets. The intersection logic already handles missing answers, but the *reason* for
  absence now differs — never asked, versus asked and skipped — and those may deserve different
  treatment.
- **`compass_topics.office_scope` is dead** — NULL on all 44 rows, yet still selected in
  `getCompassTopics()`. Drop it. Unrelated to seasons; noticed while reading.
- **`retired_at` on `compass_topics` was never applied.** ADR 0004's schema block promised it;
  `CA_0011` did not create it. Not needed — retirement is season non-membership.
- **Deferred, explicitly, not overlooked:** how a season is authored; whether seasons need their own
  version numbering; how jurisdiction is resolved for a logged-out visitor; and whether a season can
  be scoped by anything other than geoid (district type, election cycle).

## What the first version of this ADR got right

Worth keeping, because most of it survived contact with the shipped model: the two-axis framing
(revision = what it said, season = what is asked); one active season at a time; retirement as season
non-membership rather than a `retired_at` column; per-jurisdiction adjustment layered on a base set,
with both alternatives rejected for stated reasons; the lens resolution order and the rule that a
contradiction must be reported rather than absorbed; and the observation that `is_live` is a single
global boolean that cannot say *promoted where*.

**What it got wrong was not the design. It was not checking whether the design already existed.**
