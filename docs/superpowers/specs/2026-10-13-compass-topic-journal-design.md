# Compass Topic Journal — design

**Date:** 2026-10-13
**Status:** proposed, awaiting review
**Repo:** EV-Accounts (`master`). The Compass renders it; Focused Communities will inherit it.

---

## 1. What this is

A per-topic, public, dated narrative of **why a compass question is the way it is** — written by
the EV team, in the voice of a Riot Games designer diary rather than a changelog.

Two kinds of entry:

- **`watching`** — written *before* anything changes. "Here is what we are seeing on Childcare
  and what we are thinking of doing about it." No revision exists yet.
- **`changed`** — written when an edit ships, and linked to the revision that made it.

The link between them is the point. A `watching` entry predicts; a `changed` entry settles it;
a reader can see that the team said what it was going to do and then did it. That is the whole
difference between a diary and release notes.

### Why it cannot be `public_note`

`inform.compass_topic_revisions.public_note` is the existing per-edit note, and it is the wrong
home for two independent reasons:

1. **It hangs off a revision.** A note about a change we are *considering* has no revision to
   hang on. There is no row to write it to. This is not an inconvenience; it is the reason the
   feature does not exist today.
2. **It is addressed to one person about one stranded answer.** It is shown through
   `RecalibrationPopover` to a user whose stored answer was flagged, and it says, in effect,
   "here is why *your* answer needs another look." The journal is addressed to everybody.

`public_note` stays exactly as it is. A `changed` journal entry may reference the same revision,
which lets the popover link through to the thread, but neither replaces the other.

### Why it is not `seasons.public_note` either

`inform.seasons` already carries a `public_note`, and all three seasons have one. That is the
season-level narrative slot and it stays. The journal is per-topic on purpose: Focused
Communities are one-per-topic, so a per-topic thread drops into FC unreshaped, and a season-wide
post has no question to attach to in the Compass.

### What it is explicitly NOT

**Not a forum.** No replies, no reactions, no moderation, no notifications. The Compass
*publishes*; Focused Communities will *host the conversation*. If a requirement arrives that
needs a reply, that requirement belongs to FC and not here. A reply column appearing in this
table is the signal that this decision has been lost.

---

## 2. Strategic context

Focused Communities is shelved until after the November 2026 election, at which point EV's focus
returns to Connect features (Civic Spaces, Focused Communities, Empowered Listening). FC is a
separate Supabase project (`Focused_Communities`), last commit 2026-05-07, and its own onboarding
doc is stale — it describes "21 live compass topics" against the 60 now promoted.

This content is FC-shaped. It is being built in accounts anyway, deliberately, because:

- The entries are only worth anything if they exist **before** Season 3 opens. Waiting for FC
  means the first season of the diary has nothing in it.
- Topics, revisions and seasons live in accounts. FC's own integration doc says FC *queries*
  accounts and does not replicate it, so accounts is where this belongs even in FC's own model.
- Building it here and having FC read it later costs one API consumer. Building it in FC later
  costs a cross-project migration plus a second copy of topic identity.

**The design constraint that follows:** every decision below is made so FC can adopt the table
as-is. Nothing about the schema may assume the Compass is the only reader.

---

## 3. Schema

```sql
CREATE TYPE inform.journal_kind        AS ENUM ('watching', 'changed');
CREATE TYPE inform.journal_attribution AS ENUM ('none', 'handle', 'real');
CREATE TYPE inform.journal_status      AS ENUM ('draft', 'published');

CREATE TABLE inform.compass_topic_journal (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id      uuid NOT NULL REFERENCES inform.compass_topics(id) ON DELETE CASCADE,
  season_id     uuid NOT NULL REFERENCES inform.seasons(id),
  kind          inform.journal_kind NOT NULL,

  title         text,
  body          text NOT NULL,

  -- NULL on 'watching'. Set when the edit this entry predicted actually ships.
  revision_id   uuid REFERENCES inform.compass_topic_revisions(id),
  -- The 'watching' entry this one settles. Self-referential, nullable, ONE hop only —
  -- a chain of entries each answering the last is a thread, which §1 rules out.
  answers_id    uuid REFERENCES inform.compass_topic_journal(id),

  author_id     uuid NOT NULL REFERENCES auth.users(id),
  attribution   inform.journal_attribution NOT NULL DEFAULT 'handle',

  status        inform.journal_status NOT NULL DEFAULT 'draft',
  published_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
```

### Decisions inside that

**`season_id` is NOT NULL, and between seasons it is the draft season.** Season 3 exists today
with `status = 'draft'`, so there is always a season to point at: the open one during a season,
the one being prepared between them. This is what makes "between and during seasons" orderable —
`created_at` says when it was written, `season_id` says which season it concerns, and those are
not the same thing for a `watching` entry written in Season 2 about a Season 3 change.

**`revision_id` is nullable and that is the payoff, not a gap.** It is NULL on every `watching`
entry by definition. When the predicted edit ships, the `changed` entry carries the revision and
`answers_id` points back at the prediction. A constraint enforces the half that is knowable:

```sql
CONSTRAINT watching_has_no_revision CHECK (kind <> 'watching' OR revision_id IS NULL)
```

A `changed` entry *should* carry a revision but is not forced to — an edit can ship without
having been predicted, and a post-hoc note is still worth having.

**`published_at` is set only on publish**, and a trigger enforces that `status = 'published'`
implies `published_at IS NOT NULL`. Readers filter on status, never on the timestamp.

**No `updated_by`, no edit history, no soft delete in v1.** An entry is a short piece of prose
written by a handful of people. If it needs correcting, it is corrected. Versioning editorial
copy is what `compass_topic_revisions` already does for the thing that genuinely needs it.

### Indexes

```sql
CREATE INDEX ON inform.compass_topic_journal (topic_id, published_at DESC)
  WHERE status = 'published';
CREATE INDEX ON inform.compass_topic_journal (season_id);
CREATE INDEX ON inform.compass_topic_journal (revision_id) WHERE revision_id IS NOT NULL;
```

The partial index matches the only read the public API performs.

### RLS

Writes are service-role only, through the admin API below. Public reads go through the API, not
through PostgREST — consistent with how `compass_topic_revisions` is already served. RLS on,
with no anon policy, so a future accidental grant does not expose drafts.

---

## 4. Attribution — the one genuinely risky decision

Chris's ruling: entries will use a mixture of all three forms, **rarely unattributed**, with
handles encouraged so that handle use feels commonplace. Most EV staff, Chris and Chris Andrews
included, expect to hold Empowered accounts.

### 🔴 Context follows the PERSON, not the surface

An earlier draft of this spec asked whether the Compass is a Connect context or an Empower
context, and clamped every byline to a handle until that was answered. **That question was
malformed.** Chris's ruling, 2026-10-13:

> The Compass spans all three tiers. You don't need an account to use it. Connected means your
> compass attaches to you but stays **private** — we know who you are, we don't tell anyone
> without a very strong reason, and for almost everyone Connect should mean "use my handle".
> Empowered accounts must fully calibrate before they can empower, their compass is tied to
> their **real name**, and in place of privacy they prioritise **transparency** — anyone can
> extensively view the public compass of an Empowered account.

So a surface is not a context. The same page shows a handle for one author and a legal name for
another, because the two have made different undertakings.

**And this dissolves the hazard rather than managing it.** The risk was that a handle rendered in
one place and a real name in another would let anyone correlate the two. That risk is real for a
**Connected** author, whose default is privacy to the world. It does not exist for an
**Empowered** author, who has already published the link between their name and their activity —
that is what Empowered *means*. There is nothing left to leak.

**The resolver takes a ceiling from the author's tier and a preference from the row.** The tier
is a row's existence, never a column: `empower.empowered_profiles` with `is_active = true`.

| author tier | `none` | `handle` | `real` |
|---|---|---|---|
| **Connected** | team byline | `display_name` | **clamped to `display_name`** |
| **Empowered** | team byline | `display_name` | legal name |

An Inform author does not appear in that table because an Inform account cannot publish — the
write routes are admin-gated, and `requireInform` is exclusive rather than a floor.

A Connected author's `real` is clamped **always and everywhere**, not pending a decision — their
tier is the undertaking, and privacy is its default. An Empowered author's `real` renders as
written, on every surface including FC.

Still true, and still the reason this works: **never store a rendered name.** The row holds
`author_id` and a preference. Both the tier and the display name are resolved at render time, so
a staff member who empowers, demotes, or changes their handle does not leave stale bylines
behind. A missing or empty `display_name` falls back to the team byline rather than to an id or
an empty byline.

---

## 5. Write path — admin API

Alongside `backend/src/routes/compassRevisions.ts`, because a journal entry is an editorial
artifact of the same family and the same people write both.

```
POST   /api/admin/compass/topics/:topicId/journal      create a draft
PATCH  /api/admin/compass/journal/:id                  edit a draft, or re-edit a published entry
POST   /api/admin/compass/journal/:id/publish          draft -> published, stamps published_at
DELETE /api/admin/compass/journal/:id                  drafts only; a published entry is edited
```

Admin-gated the way the existing `/api/admin/compass/*` routes are. `author_id` comes from the
authenticated actor and is never accepted from the request body.

`season_id` defaults, when omitted, to the open season, falling back to the draft season when
none is open. Explicit beats implicit, so the body may always name one.

**Seeding the first entries.** The 19 reviewed topic-note rewrites and whatever Chris Andrews
returns from the guidance review are the natural first content, but they are `public_note`
material, not journal entries. The first journal entries should be written fresh as Season 3 is
prepared — that is the point of `watching`.

---

## 6. Read path — public API, shared with FC

```
GET /api/compass/topics/:topicId/journal   published entries for one topic, newest first
GET /api/compass/journal?season=<number>   published entries across topics, for a season view
```

Public, `optionalAuth`, no personalisation, identical for every caller, cacheable — the same
shape as `/compass/topic-stats`. Each entry returns:

```ts
{
  id, topicId, kind, title, body,
  season: { number, name },
  revisionId: string | null,
  answersId: string | null,
  author: { label: string },   // already resolved per this surface's context rule
  publishedAt: string
}
```

**`author` ships as a resolved label, not an id or a preference.** The resolution rule is a
server concern, and a client that received the preference could get the clamp wrong. FC calling
the same endpoint gets a label resolved under FC's rule.

**Drafts never leave the admin routes.**

---

## 7. How the Compass renders it

Read-only. No composer, ever.

The ⓘ on a calibration question opens the topic's thread: entries newest first, each with its
season, kind and byline. A `changed` entry that carries a `revision_id` matching the flag the
reader holds is marked as the one that affected their answer.

**This fixes a live defect.** Today the ⓘ appears only while a recalibration flag is outstanding,
because the only note available is keyed to the flag. Measured 2026-10-13: answering a flagged
question clears its flag, and the note becomes permanently unreachable — Chris answered 20
questions that morning and lost access to their notes in the process. A journal is attached to
the **question**, not to the reader's flag, so the ⓘ can show on any topic with published
entries regardless of flag state. This is what Chris originally asked for:

> eventually, we will put those 'i' anytime you would read the question — outside of your initial
> compass construction

**The initial-build exclusion still holds.** A first-time voter sees no ⓘ. Today that happens by
accident, because a flag requires a prior answer; with a journal it must be deliberate, since
entries exist independent of the reader. The rule: **suppress the journal ⓘ on any topic the
reader has not answered yet.**

That rule is evaluated client-side against the answers the page already holds, which covers
guests as well as signed-in users — a guest's answers live in `localStorage` and never reach the
server, so a server-side check would hide the thread from every guest forever. The Compass
already merges both sources for the recalibration flags; the same `answers` map decides this.

---

## 8. How FC adopts it later

No migration. FC calls `GET /api/compass/topics/:topicId/journal` for the community anchored to
that topic and renders the entries as thread openers, newest first. Replies, reactions and tier
gating are FC's own tables, keyed to the journal entry's `id`.

The accounts side gains nothing FC-specific. If FC never ships, nothing here is wasted.

---

## 9. Out of scope for v1

- Replies, reactions, notifications — FC's job, by the rule in §1.
- Markdown or any rich text in `body`. Plain text, rendered as paragraphs.
- Entry edit history.
- Season-level entries. `seasons.public_note` already exists for that.
- Backfilling existing `public_note` content into the journal. Those notes are addressed to
  flagged users and would read as a diary written in the wrong voice.

---

## 9a. Sequencing

Two phases, and the first is shippable alone:

1. **Accounts** — migration, admin write routes, public read routes, tests. Usable immediately
   through the API, and the entries can be written while phase 2 is still being built.
2. **Compass** — the ⓘ, the thread view, the initial-build suppression, smoke coverage.

Phase 1 is the half FC inherits, so it is the half worth getting right. Phase 2 is a rendering
change to one page.

---

## 10. Decisions still open

1. ~~Is the Compass a Connect context or an Empower context?~~ **Answered 2026-10-13 and the
   question was malformed** — the Compass spans all three tiers and context follows the author,
   not the surface. See §4. No v1 clamp remains.

1a. 🔴 **FC's integration doc contradicts §4, and someone must reconcile it when FC wakes.**
   That doc (2026-04-15) says: *"Their legal name is public in Empower contexts, but Focused
   Communities is a Connect context — still show `display_name` only."* Under §4 an Empowered
   author's real name renders everywhere, FC included.

   Both can be right, and the likely reconciliation is an asymmetry FC should decide
   deliberately: a **journal entry** is EV's editorial voice opening a thread, while a **reply**
   is peer discussion. Pseudonymising every reply keeps discussion from becoming named authority
   against anonymous citizens; pseudonymising the EV byline on its own diary entry serves nobody.
   If FC instead rules that everything in FC is pseudonymous, the resolver takes an FC-specific
   ceiling and this spec does not change — which is the point of resolving at render time.

   Flagged rather than decided here: FC is shelved, and this is FC's call to make.
2. **Does an unpublished `watching` entry ever become public?** Proposed: no — `watching` entries
   are published deliberately like any other, and a prediction that was never published is just
   a draft.
3. **Who besides Chris can publish?** Proposed: whoever `requireAuth` + `requireAdmin` already
   admits, which is how every `/api/admin/compass/*` route is gated today. No new role, and no
   per-topic ownership. Worth confirming that "any admin may publish a diary entry under their
   own byline" is the intent, since the byline makes this less anonymous than other admin work.

---

## 11. Testing

| | |
|---|---|
| Unit | the attribution resolver: a **Connected** author's `real` clamps to `display_name`, an **Empowered** author's does not, and an empty `display_name` falls back to the team byline |
| Unit | the resolver reads tier from `empower.empowered_profiles` existence, never from a column — the trap in [[reference-account-tiers]] |
| Unit | `watching` entries reject a `revision_id` (the CHECK, asserted through the service) |
| Unit | read endpoints exclude drafts — asserted on the query, not only on a fixture |
| Guard | a static test that the journal table has no `parent_id`/`reply_to` column, and that nothing follows `answers_id` more than one hop, with the §1 reasoning in the failure message |
| Smoke | the ⓘ opens a thread on a topic with entries, and is absent for a reader with no stored answer |

The guard in row four is the one that matters in a year. Everything else here is ordinary.
