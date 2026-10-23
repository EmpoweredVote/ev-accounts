# Compass spectrum labels — design

**Date:** 2026-10-21
**Status:** proposed, awaiting review. Nothing here is built: no migration reserved or applied, no UI change.
**Scope (Chris Andrews, 2026-10-21):** **store now, show later.** Build the columns, the backfill, the admin
inputs and the prep-skill changes. Do **not** show the spectrum to voters yet; §5 records where it would go so the
display is a small change when the team decides it is ready.
**Owner:** Chris Andrews. **Review needed:** Chris Cantrell — the seasons model (ADR 0005), per-season version
binding (ADR 0006) and `guidance` (CC_0231) are his; §2 changes how a revision row behaves under them, and §4/§5
record what the later display would do to the open season.
**Repo:** EV-Accounts (`master`), plus the compass frontend that renders the question and results.

---

## 1. What this is

Rule **L1** ("name the spectrum": one axis, two named poles) was adopted on 2026-10-08 with one limit: the poles
are stored internally and **not shown to voters**, because there is no column for them
(`2026-10-07-season3-ladder-evaluation.md`, rulings table). Today the poles live only as the first line of
`inform.compass_topic_revisions.rationale`:

```
L1 poles: require = "Schools must run equity programs"; ban = "Equity programs are banned in schools".
```

The Stage 4 template (`.claude/skills/season-topic-prep/templates/stage4-revision.sql`) checks only that
`rationale LIKE 'L1 poles: %'`.

During the voting-rights prep (2026-10-21) Chris Andrews asked for every topic's spectrum to be named explicitly,
because it will be listed on the site. He then set the scope: **store it now, so it can be shown when the team is
ready; do not show it yet.** The original L1 text in `2026-10-07-season3-design.md` §2 said "the poles are shown
to voters with the question"; the 2026-10-08 ruling kept them internal, partly for lack of a column. This note
adds the column (so "internal" becomes "stored in a real field" instead of "a line of prose"), the backfill and
the prep-skill changes, and plans the display for later.

Worked example (voting-rights, Stage 2, not yet applied):

| Field | Text |
|---|---|
| Axis | How much proof a person must show before their vote counts |
| Pole 1 (rung 1 end) | No proof of identity |
| Pole 5 (rung 5 end) | Documents that prove citizenship |

---

## 2. Schema

Three nullable columns on `inform.compass_topic_revisions`:

| Column | Type | Meaning |
|---|---|---|
| `axis_label` | `text` | The one axis, as a plain question-free phrase ("How much proof a person must show before their vote counts"). |
| `pole_1_label` | `text` | What the **rung 1** end of the axis means. |
| `pole_5_label` | `text` | What the **rung 5** end of the axis means. |

Named by rung number, not "left/right" or "low/high": the corpus has no fixed polarity (AI oversight and tariffs
run the other way; zoning, growth and deference are off-axis — see CLAUDE.md "Never assume polarity"). The pole
column says which end it labels, so no reader has to guess.

**Why on the revision, not on `compass_topics`.** Same reason as `guidance` (CC_0231 header): it is wording, and
wording follows the season's pinned revision (ADR 0006 Option Y). An axis on the topic row would ignore the pin,
so a season serving v3's ladder could show v5's poles. A re-axis is by definition a new version (change class
`substantive`, STAGE4-RECIPE §2), so the poles belong to the version.

**Constraints (same migration):**

- `CHECK ((axis_label IS NULL) = (pole_1_label IS NULL) AND (pole_1_label IS NULL) = (pole_5_label IS NULL))` —
  all three or none. A half-named spectrum is worse than none on screen.
- `CHECK (btrim(...) <> '')` on each — a blank is NULL, not `''` (unlike `guidance`, there is no "deliberately
  blank" state; a ladder with no nameable axis fails L1 and must be re-axed or retired).
- Length caps sized for a phone at 320 px (the primary mobile environment is the Facebook in-app browser at
  320 px): axis ≤ 90 chars, each pole ≤ 60 chars. **Open decision D4.** The three existing pole lines are 37–58
  chars.

**Immutability — write-once after approval.** `compass_topic_revisions_no_content_edits`
(`inform.compass_topic_revisions_immutable()`, CA_0011) lists the content columns that can never change. The new
columns join that rule with one exception:

- while `status = 'draft'`: freely editable (Stage 4 sets them on the draft row, like `guidance`);
- after approval: **NULL → value allowed once**; value → other value or → NULL refused with
  `IMMUTABLE_REVISION`.

Write-once is what makes the backfill (§3) possible on already-approved and published rows without opening a
general edit path. Changing a pole after that requires a new revision, which is correct: a pole that moves means
the axis moved.

**Inheritance on insert.** `propose_revision` (CA_0016) and the admin create path (CA_0026) insert with explicit
column lists, so new columns arrive NULL (the trap CC_0231 documents for `guidance`). A `BEFORE INSERT` trigger
copies the three labels from the topic's `is_current` revision **only when the new revision has the same
`version`** (a clarifying step keeps the axis). A new version gets nothing inherited: a re-axis that silently kept
the old poles would mislabel the ladder. The Stage 4 gate (§6) then refuses a new version with NULL labels.

**Grants and RLS.** No new object, so no new grant. Checked on prod 2026-10-21: `anon` and `authenticated` hold
table-level `SELECT` (new columns are covered), `ev_api` holds `INSERT/SELECT/UPDATE/DELETE`, RLS is on, and the
one read policy (`public read published`, status `published`/`superseded`) covers the new columns. Draft and
approved labels stay private until publish, same as the rest of the row. No `public` schema object is created.

**Slot.** `CA_` (Chris Andrews' namespace), from the allocator at build time:
`npm run steward --prefix backend -- slot CA --purpose "compass spectrum labels: axis/pole columns + backfill"`.
Not reserved yet — a reservation now would sit unused until this note is approved.

The migration follows house style: idempotent (`ADD COLUMN IF NOT EXISTS`, guarded `UPDATE`s), `COMMENT ON
COLUMN` for each column, and a closing `DO $$` post-verify gate; dry-run on prod inside `BEGIN … ROLLBACK` first.

---

## 3. Backfill

**What exists (prod, read 2026-10-21):**

| Season | Status | Questions | Pinned revisions with an `L1 poles:` line |
|---|---|---|---|
| 1 | closed | 44 | 0 |
| 2 | open | 60 | 0 |
| 3 | draft | 60 | 3 |

The three, all `approved` (parked), `is_current = false`, pinned only in Season 3:

| Topic | Revision id | Pole 1 | Pole 5 |
|---|---|---|---|
| education-equity-programs | `516800d5…` (rev 2) | Schools must run equity programs | Equity programs are banned in schools |
| education-library-books | `7bb64029…` (rev 2) | A challenge cannot remove or restrict a book | A challenge removes a book for all students with no review |
| education-school-police | `37728a13…` (rev 2) | No police officer is stationed in any school | A sworn police officer is placed in every school |

**No row has an axis label.** The `L1 poles:` format carries two short tags and two quoted poles, not an axis
(and the tags differ per topic: `require/ban`, `access/removal`, `none/every`). So the backfill can fill the poles
mechanically but every axis must be written by hand.

**Parse rule** for the poles: take the two double-quoted strings on line 1 in order; the first is the rung 1
end, the second the rung 5 end. Then a human check against rungs 1 and 5 of the same revision (the format does not
enforce order). The migration names the three revision ids and texts as literals, not a regex over prod — three
rows do not justify a parser, and literals make the post-verify gate exact.

**Drafted but not in the database** (local research, `~/Documents/GitHub/.planning/research/`):

- voting-rights — `s3-prep-voting-rights/stage2/drafts.md` (axis and poles above; Stage 3 disputes open).
- homelessness — `s3-pilot-homelessness-stage2/` (poles only).
- education-gender-identity — parked; poles in the EGI pilot drafts.

These go in through their own Stage 4 migrations, which (after §6) write the columns directly.

**Topics with no poles anywhere: the other 57 of the 60 Season 3 questions**, i.e. every Season 3 topic except
the three above. Of those, the 13 already re-pinned to a different revision for Season 3 (marked `*` below) and
the 44 still sharing their Season 2 revision are in the same position — none has a named spectrum.

> 2020-election, abortion\*, ai-regulation, border-security, campaign-finance, cannabis-policy, childcare,
> city-sanitation, civil-rights, climate-change, data-centers, defense-spending, deportation,
> economic-development, education-ai, education-charter-authorization, education-curriculum,
> education-gender-identity, fossil-fuels\*, growth-and-development, gun-policy\*, healthcare\*, homelessness,
> homelessness-response, housing, israel-military-aid, jail-capacity\*, judicial-access-to-justice,
> judicial-bail-pretrial, judicial-criminal-justice, judicial-government-deference, judicial-interpretation,
> judicial-police-accountability, judicial-prosecution-priorities, judicial-transparency, local-environment,
> local-immigration\*, medicare/aid, military-intervention, minimum-wage, misinformation,
> public-safety-approach\*, ranked-choice-voting, redistricting, religious-freedom, rent-regulation,
> residential-zoning\*, same-sex-marriage, school-vouchers, social-security, surveillance-technology\*, tariffs\*,
> taxes\*, trans-athletes\*, transportation-priorities\*, ukraine-support\*, voting-rights

`*` = Season 3 pins a different revision from Season 2.

Some of these cannot get an honest pole pair without a re-axis (the off-axis ladders named in CLAUDE.md:
residential-zoning, growth-and-development, judicial-government-deference; and `judicial-bail-pretrial`, whose
content is a deference ladder under a bail title). L1 says those get a re-axis, not a forced label.

**Proposed order:**

1. Migration A (schema + the three literal pole backfills; their axes as written by Chris Andrews before apply).
2. A labelling pass for the topics whose ladder already fits one axis: one sheet, axis + two poles per topic,
   checked against rungs 1 and 5, approved by Chris Andrews, applied in one `CA_` migration using the write-once
   path. Topics that fail go to the season-topic-prep queue as re-axis candidates.
3. Every later Stage 4 writes the columns itself (§6).

---

## 4. Seasons interaction

- **Pins never move.** Nothing here writes `inform.season_questions`. Labels are columns on a revision row; a
  season shows them because it already serves that row. No pin is moved for a label.
- **Closed Season 1.** Its 44 revisions are not touched. They stay unlabelled. When the season selector exists
  (Cantrell, 2026-10-08: "later, not S3"), a Season 1 view shows no spectrum line, and the UI must treat NULL as
  "do not render", never as an empty bar.
- **Open Season 2 — no visible change while labels are only stored.** 47 of Season 3's 60 pins are the *same
  revision row* Season 2 serves (only 13 were re-pinned), so labelling those rows writes onto rows the open season
  serves. While nothing renders the labels (this build), voters see no difference. The published labels are
  readable through the same public read rule as the rest of a published revision, but the site does not show them.
  🔴 **The day the display ships, this matters** (**decision D2, deferred to display time**): under ADR 0006
  Option Y the open season serves the latest published revision of its pinned version, so any labelled shared
  revision would appear in whatever season is open. Two ways to handle it then:
  - **(a) Accept it** — labels appear in the open season as soon as the display ships.
  - **(b) Gate the display by season** — the UI renders them only when the served season's `number` is at or
    above the first season whose labels were reviewed for display. Costs one season field on the topics payload.
  Writing labels through a new clarifying revision would not avoid this: a same-version revision is also picked up
  by the open season (ADR 0006 §3).
- **Draft Season 3.** The three approved pins get labels by write-once. They become publicly readable when the
  revisions publish, through the existing approved → published path; they are shown only once the display ships.
- **Answers and research.** No `politician_answers`, `politician_context` or `compass_responses` row is
  touched. The poles are not a new rung and cannot move a seat.

---

## 5. Where the site would show it — later, not in this build

**Nothing in this section is built now.** It records where the spectrum would go and what the display must get
right, so that showing it is a small, separate change once the team decides it is ready (decisions D2, D3, D8).
The only part of this section that is built now is the **admin** input in §5.2, because labels have to be
entered and reviewed somewhere.

Principle for the later display: the spectrum line is one row of three short texts, pole 1 at the rung 1 side and pole 5 at the rung 5
side, **same weight and same neutral colour on both ends** — no pillar colour, no red/blue, no arrow that implies
a "good" end (antipartisan rule). Rendered only when all three labels are present.

**A slot already exists and is empty.** `CompassV2/src/util/topic.js` `parseTensionTitle` splits `title` on a
colon into `{ name, poles }`, and Full Calibration renders `{topicName} · {poles}`
(`CompassV2/src/pages/FullCalibration.jsx` ~271, ~515). No promoted title contains a colon (CC_0231 header), so
`poles` is always null and the slot never renders. The new columns are the honest source for that slot; the
colon parse can then be retired.

**The pole ends must follow the ladder's on-screen order, not a fixed left/right.** Full Calibration sorts
stances `b.value - a.value` (rung 5 first), so "pole 1 on the left" would be wrong there. Each component places
`pole_1_label` next to rung 1 and `pole_5_label` next to rung 5, wherever they are drawn.

### 5.1 Placement

Surveyed 2026-10-21 (CompassV2 `9a63232`, essentials, ev-ui). Line numbers are approximate.

| Where | Files | What to show | Phase |
|---|---|---|---|
| Question screen (quiz) | `CompassV2/src/pages/Quiz.jsx` header ~606–630 and ~724 (question, tension subtitle, "?" link to `/how-it-works#spectrum-direction`) | Axis line + the two poles beside rungs 1 and 5 | 1 |
| Full Calibration | `CompassV2/src/pages/FullCalibration.jsx` ~265–273, ~515 (the empty `poles` slot) | Fill the slot from the columns | 1 |
| Calibration overlay | `CompassV2/src/components/CalibrationOverlay.jsx` header ~1872, stances ~1910 | As quiz | 1 |
| Topic browser ("per-topic page" today) | `CompassV2/src/components/LibraryDrawer.jsx` ~257, ~352 | Axis line under the title | 1 |
| Spectrum explainer | `CompassV2/src/pages/HowItWorks.jsx` ~50 (`#spectrum-direction`) | The listed spectra: one row per topic, axis + poles. This is the "listed on the site" page. | 1 |
| Compare with politicians | `CompassV2/src/components/ComparePanel.jsx` ~166–232 | Axis line under the question | 2 |
| Radar results | `ev-ui/src/RadarChartCore.jsx` spoke labels ~119–155, ~241–264 (`shortTitle`) | Not on the spoke (no room at 320 px); axis in the spoke's tooltip/tap detail | 2 |
| Essentials politician card | `ev-ui/src/StanceAccordion.jsx` ~277, ~456; `essentials/src/components/CompassCard.jsx` | Axis under the topic title in the accordion | 2 (ev-ui release + autobump) |

There is **no dedicated per-topic page** in either app. The nearest are the Library drawer and How It Works.
A real topic page (with the Topic Journal, `2026-10-13-compass-topic-journal-design.md`) is the natural long-term
home and is out of scope here.

⚠ `essentials/src/pages/Citations.jsx` and `getPoliticianCitations` (`compassService.ts` ~1240) read title text
from the frozen `inform.compass_topics` columns, not the served revision. They would not see the labels without
moving to `servedRevisionLateral`. That is an existing staleness, noted, not fixed here.

### 5.2 Read path (later) and admin (now)

**Read path — later.** In this build `/compass/topics` does not return the labels, so the public API's response
shape does not change and no frontend can render them by accident. When the display ships, the labels reach the
frontend through three explicit column lists, each of which silently drops a field it does
not name (the `guidance` failure documented in `compassService.ts`):

1. `servedRevisionLateral` SELECT — `backend/src/lib/seasonService.ts`.
2. `getPromotedTopics` SELECT and the `PromotedTopic` type — `backend/src/lib/compassService.ts`.
3. The per-category re-projection in `compassService.ts` (the "third explicit list" comment).

All three must name the new columns, and the compass smoke suite must assert a labelled topic returns them on
`/compass/topics` **and** on the calibration category list. The inform views (`compass_topics_current`,
`compass_topics_promoted`, …) also name their columns; the served path above does not read text through them, so
no view needs a `DROP`/`CREATE` for phase 1.

**Admin — now.** `admin/src/pages/admin/ProposeRevisionPage.tsx` needs three inputs; the save goes through
`compassRevisionService.ts` to `inform.admin_propose_topic_revision` (CA_0015/CA_0016), which takes no such
parameters. Two options: add three defaulted parameters to the RPC (re-emits a function Cantrell maintains), or
have the service `UPDATE` the draft row right after propose, the way Stage 4 sets `guidance`. The second keeps
the RPC untouched; recommended. `TopicRevisionReviewPage.tsx` field diffs should show the three fields so a
reviewer sees an axis change. The legacy CompassV2 admin (`TopicEditor.jsx`, `CreateTopic.jsx`) is not extended.

### 5.3 Relation to `guidance` (later)

`guidance` (CC_0231) is "editorial's one line on what this question asks you to tell apart", shown under the
question to everyone. The axis label is close to that job. **Open decision D3:** keep both (axis = the named
spectrum, guidance = optional extra gloss), or let the axis line replace guidance where both exist. This note
assumes both, with the spectrum row placed under guidance, because guidance is Cantrell's and live on all 60
questions.

---

## 6. Season-topic-prep skill changes

The skill lives on branch `docs/season-topic-prep-skill-design` (`.claude/skills/season-topic-prep/`).

**Stage 2 (drafter prompt, `templates/drafter-prompt.md` §1 "Shared design"):** replace "the L1 poles" with an
explicit block per draft:

```
Spectrum (stored; written to be shown to voters later):
  Axis:   <≤ 90 chars, no party, no degree words>
  Pole 1: <≤ 60 chars, the rung 1 end>
  Pole 5: <≤ 60 chars, the rung 5 end>
```

and add to the §4 rulebook check: the axis names one dimension, rung 1 sits at pole 1 and rung 5 at pole 5,
both poles are written in the same register (neither is a slogan or a straw man). The adversary prompt gets one
line: "would a supporter of each pole accept its label as fair?"

**Stage 4 (`templates/stage4-revision.sql`, `STAGE4-RECIPE.md` §2):**

- New placeholders `{{AXIS_LABEL}}`, `{{POLE_1_LABEL}}`, `{{POLE_5_LABEL}}`; set them on the draft row in step 1
  next to `guidance` (same `UPDATE … WHERE status = 'draft'`), before approve.
- Post-verify gate: replace `v_rat NOT LIKE 'L1 poles: %'` with an exact match on the three columns.
- The rationale's first line stays for one transition period (D5), then is dropped from the recipe.
- `revision.md` lists the three fields; the header comment block's "L1 POLES (stored internally as the first line
  of rationale, not shown to voters)" becomes "SPECTRUM (stored in axis_label/pole_1_label/pole_5_label; not
  shown to voters yet)".
- RULINGS.md: record the change to L1 (poles now stored in columns, with an axis; still not shown) with its date.

Labels are written now **as if voters will read them**: plain words, fair to both ends, within the length caps.
Writing them for internal use only and rewriting them at display time would double the work and re-open every
topic.

---

## 7. Open decisions for Chris Andrews

| # | Decision | Recommendation |
|---|---|---|
| D1 | Approve the three columns on the revision row, write-once after approval, inherit only within a version. | Yes. |
| D2 | *Deferred to display time.* When the display ships, the open season shows labels on shared revisions (a), or only reviewed seasons render them (b). | Decide with the display. Needs Cantrell's view. |
| D3 | *Deferred to display time.* Axis line beside `guidance`, or replacing it where both exist. | Decide with the display. Needs Cantrell's view. |
| D4 | Length caps: axis 90, pole 60 characters. | Yes; check against the 320 px layout before the migration. |
| D5 | Keep writing the `L1 poles:` rationale line during transition, or stop at once. | Stop once Migration A is applied; the column is the source. |
| D6 | Write the three missing axes for equity-programs, library-books, school-police. | Owed before Migration A. |
| D7 | Who writes labels for the other 57 topics, and do topics that fail L1 leave Season 3 or stay unlabelled. | One labelling sheet, Andrews approves; failing topics stay unlabelled and queue for re-axis. |
| D8 | *Deferred to display time.* When and where the spectrum row appears (§5.1). | Decide when the labels for the open season's topics are written and reviewed. |
| D9 | Record in the ladder-evaluation worksheet that the 2026-10-08 L1 ruling ("poles internal") now means "stored in columns, with an axis, not shown yet". | Yes, with today's date. |

**For Chris Cantrell (review before build):** §2 adds three columns to the content-immutability trigger with a
write-once exception and a same-version inheritance trigger (pattern of CC_0231). Storing has no visible effect on
any season. At display time, D2 decides what the open season shows and D3 touches `guidance`. ADR 0005 status is
`accepted`, ADR 0006 `proposed`; neither text needs to change for the storage build.

---

## 8. Not in scope

- Applying any migration, reserving a slot, or merging any UI change (this note).
- Showing the spectrum to voters anywhere, and returning it from `/compass/topics` (the storage build). §5 is the
  plan for that later change.
- Re-axing off-axis ladders (that is season-topic-prep work, per topic).
