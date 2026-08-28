---
status: proposed
---

> **Draft, 2026-08-28.** Written with Chris Andrews in a working session. It states a decided
> *behavior* and an undecided *implementation fork*. Nothing here is built yet. The override in
> §6 is deliberately designed-but-deferred. Read ADR 0004 (content versioning) and ADR 0005
> (seasons) first — this ADR sits directly on top of both and reuses their vocabulary without
> re-defining it.
>
> 🔴 Before implementing, re-read the read path against the live schema, the way ADR 0005's rewrite
> note insists. The claims below were assembled from three read-only passes on 2026-08-28; treat
> them as a map to re-verify, not as gospel.

# Per-season version binding

ADR 0004 answered *what did a question say, and when did it change* (`version`, `revision`,
`is_current`). ADR 0005 answered *which questions a season asks, of whom* (`season_questions`, the
per-topic pin). This ADR answers the question that falls between them:

**When a topic is revised, which season sees the new wording, and when?**

## 1. The problem

Today the wording a voter sees follows the **global `is_current` revision**, not the season. The
season pin (`season_questions.topic_revision_id`) records which revision a season *intends*, and the
promoted view even exposes it as `season_revision_id` for exactly this purpose — but the read path
ignores it and serves `is_current` (question text via `compass_topics_current`; stance text via the
legacy `compass_stances` table, or via `compass_stances_current` once PR #216 lands — either way,
keyed on `is_current`).

Two consequences follow, both bad for the intended workflow:

- **A season cannot carry its own version.** Publishing a revision changes the wording for whatever
  season is open *right now*, because "open" and "current" are the same global thing.
- **Assembling a future season is not isolated.** The goal is to pull revised topics into Season 2
  over days or weeks, open it when ready, and never disturb Season 1 in the meantime. The current
  model forces the version change and the season change to happen in one fragile instant (the
  "cutover"), because the only lever that changes displayed wording — publishing — is global.

## 2. The decided behavior

A season is bound to a topic's **major version**. It displays the **latest revision of that
version**. From this one rule, the behavior Chris specified falls out:

- **Minor updates** (`change_class` = `editorial` | `clarifying`, which do **not** bump `version`)
  become the latest revision of the current version, so a season bound to that version shows them
  **immediately**. This is "publish a minor fix to the current season."
- **Major revisions** (`change_class` = `substantive`, which **do** bump `version`) create a new
  version. A season bound to the old version does not see them. Only a **new season that binds the
  new version** shows them. This is "a major rewrite waits for a season change."
- **Manual override** — pushing a major revision into the *current* season on purpose — is a
  deliberate re-bind of the open season to the new version. **Designed in §6, deferred.**

The abortion revision in flight is the worked example: it is a `substantive` v2. Under this model it
is pinned into Season 2 while Season 2 is a draft, and it appears the moment Season 2 opens. Season 1
keeps showing v1 the entire time, with no cutover to orchestrate.

## 3. Resolve by version, not by pinned revision id

The pin is a single `topic_revision_id`. A minor update mints a **new** revision UUID, so a pin that
names one specific revision would go stale on every minor edit. Two ways out:

- **(a) Auto-advance the pin** on each minor publish. Rejected: it mutates `season_questions` on a
  frozen (open) season, fighting the `season_questions_pin_immutable` trigger, and it turns a minor
  content edit into a write against every open season's question set.
- **(b) Resolve by version (chosen).** The pin names the version's origin revision; display computes
  *the latest revision of that version* at read time:

  ```sql
  -- the revision a season bound to (topic T, version V) should display
  SELECT r.*
  FROM inform.compass_topic_revisions r
  WHERE r.topic_id = T
    AND r.version  = V
    AND r.status IN ('published','superseded')   -- was live at some point
  ORDER BY r.revision DESC
  LIMIT 1
  ```

  The pin stays put; the version is what is load-bearing. A minor publish adds a higher-`revision`
  row at the same `version`, and the query picks it up with no write to `season_questions`.

This makes **`version` the real unit a season binds**, with the pinned revision serving only to name
that version (and to stamp answers, per ADR 0005). Consider storing `version` on `season_questions`
directly at implementation time, so the resolver does not dereference the pin on every read.

## 4. The implementation fork (the one decision to confirm)

Both options deliver §2's behavior. They differ in **what enforces "a major revision does not leak
into the current season"** — a guarantee, or a discipline.

### Option X — keep `is_current`, guard the publish
Displayed wording keeps following `is_current` (PR #216's approach stands unchanged, capitalization
included). The invariant "`is_current` == the open season's version" is held by **never publishing a
revision of a version the open season does not bind**:
- Minor v(n) fix: propose (builds on `is_current`) → approve → publish → `is_current` advances within
  the same version → the open season shows it.
- Major v(n+1): proposed and approved but **left unpublished**, pinned to the draft next season.
  Opening that season publishes it in the same migration.
- Add a **publish guard**: `admin_publish_topic_revision` refuses a revision whose `version` differs
  from the open season's bound version, unless an explicit override flag is passed (§6).

*Cost:* the safety is procedural + one guard. Publishing is otherwise a normal action, so the guard
is the only thing standing between a stray publish and a disturbed live season. Least code: PR #216
lands as-is; add the guard and a season-open-publishes-pins step.

### Option Y — season-pin-driven read path (recommended)
The read path resolves displayed wording from the **open season's bound version** (§3 query),
ignoring `is_current` for season display. Publishing a major v(n+1) then *cannot* leak, because no
open season binds v(n+1) until its season opens — the guarantee is structural, not procedural.

*Cost:* larger change. `getCompassTopics` and the promoted view resolve display from the season's
version; `is_current` becomes a lineage marker (still used by non-season readers — essentials quote
wording, answerability). PR #216 is **reworked**: keep the capitalization and the move off the frozen
legacy table, but change the target from `compass_stances_current` (is_current) to the season's bound
version. `getPoliticianCitations` is subtler — a citation should show the stance text of the revision
the **answer was recorded against** (already season-stamped on the answer), which is neither
`is_current` nor necessarily the *current* pin; resolve it from the answer's `topic_revision_id`.

**Recommendation: Option Y.** It matches the design intent already latent in the promoted view (which
exposes `season_revision_id` precisely so a caller can render what the season asks), and it makes the
"majors wait" guarantee a property of the schema rather than a rule people must remember. The extra
code buys a safety that Chris asked for explicitly ("I don't want it to disturb Season 1").

> **DECIDED 2026-08-28: Option Y.** Chris chose the season-pin-driven read path. The rest of this ADR
> assumes Y. `is_current` becomes a lineage/answerability marker; the compass read path resolves
> displayed wording from the open season's bound version.

## 5. Answer stamping is unchanged

ADR 0005's answer model already does the right thing and needs no change: an answer carries
`(season_id, topic_id, topic_revision_id)`, so it is bound to the revision it was recorded against.
A season pinned to v1 stamps v1 answers; when v2 arrives with Season 2, its answers stamp v2. History
stays legible across the version boundary. This ADR only changes **display resolution**, never how
answers are written or what they mean.

## 6. The manual override — designed, DEFERRED (do not build yet)

Intent: push a major v(n+1) into the *currently open* season on purpose, without waiting for a season
change. Rare, deliberate, auditable.

Design (for whenever it is built):
- A single admin action `rebind_open_season_topic(topic_id, target_version, actor, reason)` that:
  1. Verifies the target version has an `approved`/`published` revision.
  2. Under Option X: publishes it and lets the guard's override flag through, recording `reason`.
     Under Option Y: updates the open season's bound version for that topic — the one sanctioned
     exception to `season_questions_pin_immutable`, gated to this function and logged.
  3. Writes an audit row (who, when, which topic, old→new version, reason).
- It must be a **named, logged, single-purpose** path, never a general "edit the pin" — the immutable
  pin is a feature, and the override is the explicit, recorded way to break it once.

Deferred because the season workflow that would call it (composing a season) is itself still
migration-only (§7), and there is no live demand yet. Designing it now keeps the read path and the
guard from assuming the open season's version can never move.

## 7. Tooling reality (context, not a decision)

There is **no admin UI for composing a season** (the earlier belief in an `/admin/seasons` page was
wrong — confirmed 2026-08-28). Seasons are created and their `season_questions` pinned **by hand in a
migration** (the `CA_0019` pattern). So "assembling Season 2" today means writing the pin rows in a
migration. A composition UI is real, separate work; this ADR does not depend on it, but the workflow
it describes is clumsy until that UI exists.

## 8. Consequences

- **Read path** changes (Option Y): `getCompassTopics`, `getPoliticianCitations`, and the promoted
  view resolve display from the season's bound version. `is_current` narrows to a lineage/answerability
  marker plus non-season readers.
- **PR #216 is on hold.** Its capitalization and its move off the frozen legacy table survive under
  both options; its *read target* is decided by §4. Do not merge it until this ADR is accepted.
- **Publish semantics** gain a season-awareness (a guard under X; a decoupling under Y). Either way,
  `admin_publish_topic_revision` stops being a purely global act.
- **`season_questions`** likely grows a `version` column (or the resolver derives version from the
  pin) — decide at implementation.
- **Non-season readers** (essentials quote wording via `compass_topics_current`) keep following
  `is_current`. Watch for divergence between "what the compass shows for a topic" and "what a quote
  card shows for the same topic" once seasons can hold a different version than `is_current`.

## 9. Implementation plan (once §4 is confirmed)

1. ~~Confirm Option X vs Y~~ — **done, Option Y (2026-08-28).**
2. **Nail the schema**: read `CA_0015` (lifecycle), `CA_0017` (season_questions), `CA_0021`
   (promoted view) against prod; decide whether `season_questions` stores `version`.
3. **Read-path change** (Y) or **publish guard** (X), behind the existing tests plus new ones:
   a season bound to v1 shows a v1 minor immediately; a published v2 does not appear until a season
   binds it.
4. **Rework PR #216** to the chosen target; keep capitalization.
5. **Season-open publishes pins** (X) — the season-open migration publishes each pinned revision.
6. **Defer** the §6 override; leave the seam for it.
7. **Verify read-only against prod** the way §0's note demands before and after.

## 10.5. Step-1 findings (schema re-verification, 2026-08-28, read-only vs prod)

- **`season_questions` has no `version` column** — pin is `topic_revision_id` only (`CA_0017:71-83`).
  The resolver can derive the version by joining the pinned revision. Storing `version` explicitly is
  optional; decide when building. The pin-immutability trigger is `season_pin_is_immutable`
  (`CC_0002:186-201`): blocks changing `topic_revision_id` on any non-`draft` season — this is the
  trigger the §6 override must gate through.
- **No minor updates exist yet.** Every one of the 78 revisions is `change_class = substantive`; zero
  `editorial`/`clarifying`. No `(topic, version)` has ever had more than one live revision. So the
  "minor flows into the current season" path is entirely **new, unexercised** ground — build it with
  tests that stand it up from nothing, not against existing data.
- 🔴 **A live pin/version divergence already exists.** Season 1 pins **`judicial-bail-pretrial` at
  v1**, but that topic's `is_current` is **v2**. Under today's is_current read path, Season 1 voters
  are **already being shown v2** for a topic Season 1 pinned at v1 — the exact defect this ADR fixes,
  live in prod. Consequences: (a) Option Y is **not a pure no-op on deploy** — it will switch that
  topic's Season 1 display from v2 back to the pinned v1; (b) if that v2 was *meant* to be live in
  Season 1, the correct remedy is to re-bind Season 1's pin to v2 — which is the §6 **override**, the
  thing we deferred. So this one topic may force the override sooner, or a one-off migration. **Decide
  before shipping Option Y.**
  > **RESOLVED 2026-08-28 (Chris):** that v2 was staged for **Season 2**, not Season 1. So Option Y's
  > revert of Season 1 to the pinned v1 is correct and desired — it fixes a live error, no override
  > needed for Season 1. Follow-up: Season 2's pin for `judicial-bail-pretrial` must bind **v2** (a
  > composition task, not part of the read-path change). This topic becomes the resolver's live test:
  > its pinned v1 is `superseded`, so the §3 query (`status IN ('published','superseded')`) must
  > return it.

## 10.6. Resolver refinement + the abortion composition task (2026-08-28)

- **A version is displayable only once it has a `published` or `superseded` revision.** The §3 query
  returns nothing for a version whose only revision is `approved`/`draft`. Consequence: the abortion v2
  (revision 4) is currently `approved` and **unpublished**, so even after Season 2's pin moves to it,
  Season 2 would render blank for abortion until that revision is **published**. So opening a season
  must **publish its pinned revisions** (or they are published beforehand).
- **Under Option Y, publishing a major is safe w.r.t. the live season.** Publishing abortion v2 makes
  it `is_current` and supersedes v1, but Season 1 — which binds v1 — keeps showing v1 (its pinned
  version), because display follows the pin's version, not `is_current`. So the old "never publish
  while Season 1 is open" rule dissolves under Y. (This is already the live reality for
  `judicial-bail-pretrial`: v2 is published while Season 1 correctly should show v1.)
- ⚠ **Tension to handle: `propose` builds on `is_current`.** Once abortion v2 is `is_current`, a new
  minor fix proposes on top of v2, not v1 — so a minor fix aimed at the *live* (v1) season becomes
  awkward. Acceptable for now (minors to a superseded live version are rare), but the build should
  decide whether `is_current` should track the **open season's** version rather than the newest
  publish. Flag, do not silently accept.
- **Season 2 abortion pin (composition task):** Season 2 currently pins abortion at v1; move it to
  revision 4 (v2) once we compose Season 2. Season 2 is `draft`, so the pin is mutable. Not part of
  the read-path build.

## 10. Open questions

- **§4: Option X or Y.** The one blocking decision.
- Does `season_questions` store `version`, or derive it from the pinned revision at read time?
- Under Y, confirm `getPoliticianCitations` resolves stance text from the **answer's** stamped
  revision, not the current pin.
- Non-season readers vs season readers divergence (§8) — acceptable, or reconcile?
