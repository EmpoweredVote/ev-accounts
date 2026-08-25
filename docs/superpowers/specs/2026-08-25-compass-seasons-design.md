---
status: proposed
---

> **Design stage, 2026-08-25. Nothing implemented.** Every number below was read from prod, not
> estimated. Builds directly on [ADR 0004](../../adr/0004-compass-content-versioning.md), whose
> revision machinery is **already applied** — `inform.compass_topic_revisions` holds 46 rows and
> `inform.compass_stance_revisions` holds 230.

# Compass seasons

Compass content is versioned. Compass **answers** are not. This spec closes that gap by making a
*season* the unit that binds the two: a season pins the exact ladder revision each question was
researched against, and every answer belongs to a season.

## The problem, stated precisely

`inform.politician_answers` is four columns and a two-part key:

```
politician_id · topic_id · value · write_in_text     PRIMARY KEY (politician_id, topic_id)
```

33,164 rows. **No timestamp, no editor, no revision reference, and no room for a second season.**
`inform.politician_context` has the same shape and the same key.

Two consequences follow, and both are live today.

**A ladder edit silently re-labels every answer indexing into it.** `politician_answers.value` is a
bare `numeric` position, not a reference to a stance. Rewrite rung 2 and all 333 rows seated at
`medicare/aid` chair 2 now assert something nobody wrote. The NC stance campaign surfaced six such
ladder defects (LEDGER, 2026-08-25); each is blocked on exactly this, because there is no safe way to
change the text.

**The politician half was left behind by ADR 0004.** The citizen half already has what is missing —
`inform.compass_responses` carries `created_at`, `updated_at`, `deleted_at` and
**`answered_revision_id`**, a foreign key to `compass_topic_revisions`. A voter's answer already
records the exact revision it was given against. A politician's does not.

Most of this spec is therefore not invention. It is bringing `politician_answers` up to what
`compass_responses` already does, and adding the season on top.

## Decisions

Settled in conversation on 2026-08-25. Each was a fork with real alternatives; the rejected ones are
recorded because they will be proposed again.

1. **Both seasons stay; the newest is current.** An answer becomes a dated record, like
   `essentials.office_terms`. Season 1's row is kept and queryable so "they moved from 4 to 2 between
   seasons" is answerable. *Rejected: replace in place, which loses change over time — most of why a
   season number is worth storing at all.*
2. **A season pins the revision.** Per question, a season records exactly which ladder revision was
   current when it opened. **This is the fix for the whole defect class**, at the root rather than one
   ladder at a time. *Rejected: season as a date range, under which a mid-season edit still re-labels
   answers made before it.*
3. **Nothing exists until it is researched.** No season-N row is created for a person until someone
   writes it. *Rejected: pre-created drafts and carry-forward-as-live, both of which put an unverified
   position in front of a voter wearing a current season number.*
4. **Question numbers are labels, not identity.** Identity is the topic's uuid and `topic_key`;
   seeding joins on identity and never on the number. A number lives on the season's question list.
   *Rejected: a global number on the topic, which ends at `477,344` or at blanks for new topics.*
5. **Politicians take one of the five. Citizens may say we are wrong.** A politician's value is a
   whole number 1 to 5, because what we source must match a stance we publish. A citizen keeps half
   steps and the out-of-range 0.5 / 5.5, which together with `write_in_text` are how a citizen tells
   us the five do not cover them.
6. **Citizens import, politicians do not.** A politician row is a claim we make about someone else and
   must be re-evidenced. A citizen row is the user's own opinion and only needs re-asking if what they
   relied on moved.

## Data model

### New — `inform.seasons`

| column | notes |
|---|---|
| `id` | uuid pk |
| `number` | int, **unique**, human-facing (season 1, season 2) |
| `name` | text, e.g. "2026 general" |
| `status` | enum `draft` / `open` / `closed` |
| `opened_at`, `closed_at` | timestamptz, null until the transition |
| `public_note` | text NOT NULL — why this season exists, in the ADR 0004 house style |

### New — `inform.season_questions`

The season's question set **is** this table's membership.

| column | notes |
|---|---|
| `season_id`, `topic_id` | composite pk |
| `topic_revision_id` | FK `compass_topic_revisions(id)` — **the pin** |
| `question_number` | int, unique within a season, a label |
| `display_order` | int, unique within a season, presentation only |

A season adding a topic (a new issue arises) or dropping one (it stopped mattering) is a row present
or absent. **Retirement needs no separate state**, and a retired topic's answers stay queryable in the
season that had them.

### Changed — `inform.politician_answers` and `inform.politician_context`

Both gain `season_id`, `topic_revision_id`, `editor_id` (FK `users(id)`, matching
`compass_topic_revisions.proposed_by`), `created_at`, `updated_at`.

**Primary key becomes `(politician_id, topic_id, season_id)`.**

`politician_answers.value` tightens to a whole number 1 to 5. The existing pair of CHECKs currently
combines to *1 to 5 in half steps*, so `4.5` is legal for a politician today — contrary to decision 5.
**Zero of the 33,164 rows use a half step**, so the tightening is free and safe. `compass_responses`
is left exactly as it is: its `0.5`–`5.5` half-step CHECK is the citizen signal, not a defect.

### Not changed

`compass_topics` gains nothing. That is deliberate — see decision 4.

## Season lifecycle

A season is **drafted**, then **opened**, then **closed**.

Opening pins, per question, whichever revision is current at that instant. **After opening, a pin
never moves.** A ladder correction opens a new revision, which the *next* season picks up. An edit
therefore cannot re-label a stored answer, ever.

Answers may be written only against an `open` season, and only for a question in that season's set.

## Seeding — politicians

Seeding is a **read**, never a write. When researching person P on question Q in season N, the tool
shows season N-1's value, reasoning and sources for the same `(politician_id, topic_id)`, with the
source URLs re-checked for rot. The researcher always writes a new row carrying their own `editor_id`.

The seed carries a flag that governs how it may be used:

| condition | seed state | meaning |
|---|---|---|
| season N and N-1 pin the **same** revision | **fresh** | a starting point; confirm or change it |
| the pins **differ** | **stale** | the ladder moved; this needs new research, not a confirm |

The five rungs may shuffle within 1-5 between seasons. When they do, the pin differs, the seed is
stale, and a confirm is refused. *An evolved question needs new research* becomes enforced rather than
remembered.

## Import — citizens

The opposite rule, for the opposite reason. Driven by the revision's `rung_map`.

**Import the user's answer when the rung they chose and its immediate neighbours all map `identity`.**
Otherwise ask again.

The neighbours are in the test because a rung's meaning is partly relative: if a user picked 4 and
rung 5 was rewritten underneath them, their 4 now sits on a different scale even though its own text
did not change.

**An imported answer is disclosed to the user as imported**, at the point they meet the topic. It is
their opinion carried forward, not a fresh statement, and it must not be presented as one.

## Guards

- **A politician value must be a whole number 1 to 5.** CHECK, replacing the half-step pair.
- **An answer's `topic_revision_id` must be the one its season pinned** for that topic. A composite
  FK to `season_questions (season_id, topic_id, topic_revision_id)` enforces it in the schema, so a
  row cannot cite a ladder its season never used. ⚠ That FK needs a target: add
  `UNIQUE (season_id, topic_id, topic_revision_id)` on `season_questions` alongside its
  `(season_id, topic_id)` primary key, or the reference will not compile.
- **A season's pins are immutable once open.** Trigger, refusing UPDATE of `topic_revision_id` on a
  `season_questions` row whose season is not `draft`.
- **Question-number drift is warned, never enforced.** A check script reports any question whose
  number changed from the previous season while its `topic_id` stayed the same. Best practice, per
  decision 4 — the machinery must not depend on it.

## Migration path

Slots: **take the number last**, per `CLAUDE.md`. `CA_0013` and `CA_0014` are **reserved by ADR 0004**
for its repoint and cleanup phase, so seasons start at the next genuinely free `CA_` slot (`CA_0017`
at the time of writing; re-verify with `npm run check:migrations` after `git fetch`).

1. **Structure.** Create `seasons` and `season_questions`. Add the new columns to both answer tables
   as nullable. No key change yet.
2. **Backfill season 1.** Insert season 1 (`closed`). Populate `season_questions` from all 44 live
   topics, pinning each to its current revision, numbering them in the present display order.
   Set every existing answer and context row to season 1 and its topic's current revision.
   ⚠ **`editor_id` for the backfill is unresolved.** `public.users` holds 21 rows and carries only
   `display_name` — no email. The one candidate is `chrisandrewsedu`
   (`854fbc06-40fc-458d-b523-20ef8e5ad1b2`), and that is **not proof**: attributing 33,164 rows to the
   wrong person is precisely the failure the roster rules exist to prevent. Confirm the id before
   step 2 runs, or backfill `editor_id` NULL and make it `NOT NULL` only for rows written after this
   lands. 33,164 answer rows, one statement.
3. **Constrain.** Make the new columns `NOT NULL`, swap the primary keys, add the composite FK, tighten
   the politician value CHECK, add the immutability trigger.
4. **Read path.** Update the API to select the newest season in which a person has an answer, and to
   return the "last reviewed in season N" notice when that is not the current season.

Each migration is idempotent and ends with a `DO $$ ... $$` post-verify gate that `RAISE EXCEPTION`s
on a wrong count, per house style. Step 3 is the only irreversible one; dry-run it against prod inside
`BEGIN; ... ROLLBACK;` and confirm the revert before committing.

## Consequences

**Every reader must now ask for a season.** Any query joining `politician_answers` on
`(politician_id, topic_id)` alone will fan out once season 2 exists. This is the single largest risk in
the change, and step 3 is where it bites. `backend/src/lib/` consumers, the essentials read path, the
stance gates and `push-nc-stances.mjs` all need the season added before step 3 lands, not after.

**Coverage will appear to drop when season 2 opens**, because decision 3 means no season-2 row exists
until researched. That is the honest reading of the state, and the "last reviewed in season N" notice
is what keeps it legible rather than alarming.

**The six ladder defects become fixable.** They stop being "edit live text and hope" and become a
revision plus a season boundary.

## Non-goals, and what is deliberately deferred

- **Community-authored lenses and topics.** Local communities will soon author their own. That will
  make question numbering unique per season *per lens* and give topics an owner. Not built here; the
  design avoids the one thing that would have blocked it — a global number on the topic.
- **Telemetry-driven revision.** Deciding a revision from voter behaviour ("rung 3 was rarely picked;
  the write-ins cluster between 4 and 5") is the right mechanism and the reason `write_in_text` and the
  out-of-range half steps matter. But `compass_responses` holds **184 rows from 8 users**. The loop
  should be built; the first seasons will still be edited on judgement.
- **Mid-season correction of a ladder.** Out of scope. A correction opens a revision that the next
  season picks up.
- **ReadRank questions.** ADR 0004 §8 covers them with the same machinery. Seasons for ReadRank are a
  separate decision.

## Open before implementation

1. **Whose `editor_id` does the season 1 backfill carry?** See step 2. Do not guess it.
2. **Does `editor_id` become `NOT NULL`?** It cannot be, if the backfill leaves it null. Either resolve
   (1) or accept a nullable column meaning "written before provenance existed" — which is honest, and
   is what the 33,164 legacy rows actually are.
3. **Which consumers join on `(politician_id, topic_id)` today?** They must all take a season before
   step 3 swaps the primary key. This needs an audit, not an assumption; it is the change's largest
   risk.
