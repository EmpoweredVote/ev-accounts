---
status: proposed
---

> **Design stage, 2026-08-24. Nothing implemented.** Decided in conversation while finalising ADR 0004.
> Every count below was read from prod.

# Seasons of compass questions

ADR 0004 answered *what did a question say, and when did it change*. It says nothing about **which
questions are asked, of whom, right now** — and that is a separate thing that changes on a different
clock. We decided to model it as **seasons**: a named, dated, jurisdiction-aware set of promoted
topics, with **one active season per jurisdiction** at a time.

Season 1 is the 44 topics live today. Season 2 will reuse some, add some, and retire some. Seasons
arrive irregularly — plausibly every six months, and more often around elections. Eventually a season
is **hyper-individualised**: Season 2 for Portland OR need not match Season 2 for Bedford IN.

## The two axes are orthogonal, and versions already did the hard half

| | Question it answers | Changes when |
|---|---|---|
| **Revision** (ADR 0004) | What did this topic *say*? | An editor rewords or reframes it |
| **Season** (this ADR) | Which topics are *asked*, of whom? | The team promotes a new set |

They compose without touching each other, and the reason is already built: **`answered_revision_id`
records the exact wording every answer was given against.** So a season references **topics**, not
revisions. It does not need to pin wording, because wording provenance lives on the answer. Pinning a
revision in the season would fuse the two axes back together and buy nothing.

Consequences that follow immediately:

- A topic can be in Season 1 and Season 2 with different wording — nothing special is required.
- A topic can be carried into Season 2 unchanged — also nothing special.
- Rewording a topic mid-season does not disturb season membership.
- A topic can exist, hold seated stances, and be in **no** active season. That is retirement.

## Why now

The 44 topics were chosen before several of them mattered and while others did not yet exist. There is
no Iran-war topic because there was no Iran war. There is no mechanism to retire a question that has
gone quiet, and `is_live = true` on all 44 rows is the only expression of "promoted" we have — a single
global boolean, which cannot say *promoted where*.

## Decision

### 1. A season is a base set plus per-jurisdiction adjustments

```sql
CREATE TABLE inform.compass_seasons (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key         TEXT NOT NULL UNIQUE,        -- 'season-1', 'season-2'
  name        TEXT NOT NULL,               -- reader-facing
  description TEXT,
  starts_at   TIMESTAMPTZ,                 -- NULL until published
  ends_at     TIMESTAMPTZ,                 -- NULL while open-ended
  status      inform.season_status NOT NULL DEFAULT 'draft',
  rationale   TEXT NOT NULL,               -- internal: why this set, why now
  public_note TEXT NOT NULL,               -- reader-facing: what changed this season
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE inform.compass_season_topics (
  season_id           UUID NOT NULL REFERENCES inform.compass_seasons(id) ON DELETE CASCADE,
  topic_id            UUID NOT NULL REFERENCES inform.compass_topics(id)  ON DELETE RESTRICT,
  -- NULL = the base set, applying everywhere in this season.
  -- A geoid = an adjustment for that jurisdiction only.
  jurisdiction_geoid  TEXT,
  disposition         inform.season_disposition NOT NULL DEFAULT 'include',  -- include | exclude
  note                TEXT,                -- why this place differs
  PRIMARY KEY (season_id, topic_id, COALESCE(jurisdiction_geoid, ''))
);
```

Resolution for a jurisdiction: **base includes, minus that jurisdiction's excludes, plus that
jurisdiction's includes.**

Rejected: **one season row per jurisdiction.** Conceptually simpler to read, but it multiplies rows by
jurisdiction count and makes "what changed in Season 2 *everywhere*" unanswerable without diffing
thousands of sets.

Rejected: **rules instead of lists** (include topics tagged X for district type Y). It scales without
enumerating and could subsume `compass_topic_roles`, but "what exactly does Bedford see" becomes a
computation rather than a fact — hard to review, and hard to explain to a voter who asks why they were
shown a question.

⚠️ **The known cost of the chosen shape** is that include/exclude resolution is a rule system, and rule
systems get confusing at the third exception. The base set must stay the overwhelmingly common case; if
per-jurisdiction rows start outnumbering base rows, that is the signal this was the wrong model.

### 2. One active season per jurisdiction

Enforced in the database, the same way `is_current` is enforced on revisions. "Which questions am I
being asked" must have exactly one answer per person.

Changeover is a pointer flip, and **in-flight calibrations finish on the season they started** — the
session-pinning mechanism built for revisions (ADR 0004 §5) generalises to seasons at no extra cost.

Rejected: **overlapping seasons with cohort assignment.** It would allow testing a season before full
release, but it hits the same trap as ladder A/B — two people's compasses become non-comparable, and
matching against politicians gets murkier because the topic *sets* differ, not just the wording.

### 3. Lenses stay, as presentation *within* a season

A season decides the promoted set. A **lens** is a short curated slice of it — "8 questions to start" —
and remains a distinct concept with a distinct job.

The three live lenses (`federal`, `judicial`, `local`, 8 topics each, auto-selected by
`auto_district_types`) keep working.

🔴 **The invariant that makes two tables safe:** a lens may only contain topics that are in the active
season **for that jurisdiction**. Otherwise a lens offers someone a calibration question that is not in
their promoted set — a question they can answer but that does not belong to their compass. This must be
a constraint or a checked gate, not a convention, because it is exactly the kind of drift that goes
unnoticed until a voter sees something odd.

Considered and not chosen: folding lenses into seasons entirely. A lens *is* the same shape of thing —
a named, curated, scoped subset — and the funnel baseline shows the lens system was used by roughly one
person, so the migration cost would have been near zero. Keeping them is a deliberate bet that
"promoted set" and "onboarding slice" are worth separating. If the invariant above proves annoying to
maintain, revisit this.

### 4. Answers record their season as well as their revision

Add `answered_season_id` to `inform.compass_responses`, alongside the existing `answered_revision_id`.

Two questions need it. "You calibrated in Season 1; Season 2 asks four new questions" is a prompt worth
showing, and it requires knowing which season the person answered under. And a compass rendered a year
later should be explainable as *the season it was built from*, not silently reinterpreted against the
current set.

🔴 **Retiring a topic must never delete answers.** Same rule as ADR 0004: a topic dropping out of the
active season stops it being *asked*; it does not unmake the fact that someone answered it, nor unseat
a politician's evidenced stance. Matching may still use those answers where both sides have one.

### 5. What seasons replace, and what they make redundant

| Today | Under seasons |
|---|---|
| `compass_topics.is_live` (true on all 44) | Redundant. "Promoted" becomes a function of (season, jurisdiction), not a global boolean. |
| `compass_topics.office_scope` | **Already dead** — NULL on all 44 rows, yet still selected in `getCompassTopics()`. Drop it. |
| `compass_topics.judicial_role` | Sparse (3 topics) and overlaps `compass_topic_roles.role_scope = 'judicial'`. Fold in. |
| `compass_topic_roles` (84 rows) | Keep for now. It answers "which office levels can answer this", which is a property of the topic, not of a season. Revisit if season membership makes it redundant. |
| `retired_at` on `compass_topics` | **Never applied** (ADR 0004's schema block promised it; `CA_0011` only created new tables). Probably never needed — retirement is season non-membership. |

⚠️ **`inform.compass_topics_live` assumes one global current revision per topic.** That view is the
compatibility surface ADR 0004 built for the read-path repoint (`CA_0013`, unwritten). Under seasons
"live" is parameterised by jurisdiction, so the view either gains arguments (becoming a function) or is
replaced. **Decide this before writing `CA_0013`** — repointing 13 files onto a view that seasons will
invalidate is wasted work done twice.

## Consequences

- **Season changeover is a content event with a public note**, like a revision. "Season 2 replaced these
  four questions and added these three, and here is why" is exactly the transparency surface ADR 0004
  §9 already established; seasons should appear in it.
- **The review workflow generalises.** A proposed season is a draft set awaiting approval, with the same
  gate, the same capacity recording, and the same "the reviewed thing is the published thing" property.
  It should reuse `compass_topic_revisions`' lifecycle rather than invent a parallel one.
- **`/compare` gets a new failure mode to think about.** Two users in different jurisdictions may hold
  answers to different topic sets. The intersection logic already handles missing answers, but the
  *reason* for absence now differs — never asked, versus asked and skipped — and those may deserve
  different treatment.
- **Deferred, not overlooked:** how a season is authored (the same tooling-writes-a-draft path, or
  something else); whether seasons need their own version numbering; how jurisdiction is resolved for a
  logged-out visitor; and whether a season can be scoped by anything other than geoid (district type,
  election cycle).
