---
name: season-topic-prep
description: "Prepare one compass topic for the next season, from audit to an applied Season revision: measure the seat rate, classify every blank, pick the Source or Wording path, run Stages 0–4 (census with gate pre-screen, frozen test set, blind drafts, seatability test with the adversarial check, revision package), save every source to the shared store, and post each stage's status to the topic's Monday Story. Triggers on: 'prep a topic', 'season prep', 'topic prep', 'topic audit', 'seat rate', 'Stage 0a', 'Stage 0', 'Stage 1', 'Stage 2', 'Stage 3', 'Stage 4', 'Stage 0–4'."
argument-hint: "<topic_key> [stage]"
---

# /season-topic-prep — prepare one compass topic for the next season

## Purpose

Every compass topic must be prepared before a new season goes live, so that it follows the rulebook (L1–L10, T1–T6) and the codebook **and seats as many politicians as the evidence honestly allows**. Some topics now seat only about 20% of the people researched, and a topic that seats that few is failing even when every blank is correct. Raise the rate in three ways only, never by lowering the evidence standard: find more sources for the same people, combine sources (codebook E2 joint evidence), and adjust the rungs where the wording itself blocks seats. From Season 3 on the order is audit → research at scale → find where people get stuck → fix → push live, because Season 2 changed wording first and learned too late that small changes would have seated many more people. This skill runs that order for one topic, from audit to an applied Season revision, so you never need to ask why the topic is being prepared.

## When to use

- The runner names a topic to prepare, audit or fix, or asks for its seat rate.
- The runner names a stage (0a, 0, 1, 2, 3, 4) of a topic already in progress. Read that topic's research folder
  and its latest Monday update, then continue from the first stage whose output file is missing.

The design and its reasons: `docs/superpowers/specs/2026-10-20-season-topic-prep-skill-design.md`.

## Before every stage

1. Read [RULINGS.md](RULINGS.md). A ruling there is applied, not re-argued.
2. Read the codebook `docs/codebook/stance-and-quote-codebook.md`. It wins over this skill. Record its version in
   the stage's output file.
3. The rulebook is in `docs/superpowers/specs/2026-10-07-season3-design.md` §2 (L1–L10) and §4 (T1–T6), with the
   rulings in `docs/superpowers/specs/2026-10-07-season3-ladder-evaluation.md` ("Rulebook rulings" and "Evidence
   rules, seatability test"). T4 is replaced by the adversarial check ([ADVERSARIAL-CHECK.md](ADVERSARIAL-CHECK.md)).

## Hard rules

- 🔴 **No database write, revision row, migration or `--season draft` batch without the runner's explicit yes.**
  Read-only `SELECT`s are fine. Never print `DATABASE_URL`.
- Never seat by presuming what a source does not say. An absence read into silence is not evidence. A blank spoke
  is correct.
- An item used to write a ladder never counts toward that ladder's test (exposure). List it in `EXCLUDE.txt`.
- Never ask the runner to read a whole bill. Ask about one quoted sentence (see "How to ask for a ruling").
- No party names and no partisan colours, anywhere.
- Fetching manners: one item at a time for meeting and bill portals; no scripted bulk requests; respect robots and
  terms. A blocked portal is a gap, never "none". Record it in the store's `dead-ends.jsonl`.

## Settings

- **Settings file:** [config.json](config.json) (committed). It holds the Monday board, group, column ids, status
  labels, the research root and the source-store path. Nothing in this skill reads another person's files.
- **Overrides by environment variable:** `EV_MONDAY_USER_ID` (your Monday user id, used as the Story owner) and
  `EV_RESEARCH_ROOT` (your research root). Without them, the owner is the Monday user the connector is signed in as,
  and the research root is `~/Documents/GitHub/.planning/research`.
- **Research folder:** `<research root>/s3-prep-<topic_key>/`, with one subfolder per stage (`stage0a/`, `stage0/`,
  `stage1/`, `stage2/`, `stage3/`, `stage4/`). It is local and never pushed.
  🔴 **Before creating any folder, look for an existing trail.** Search the research root for `s3-pilot-*`,
  `s3-census-*` and `s3-prep-*` folders whose name contains the topic key or its short name (for example
  `s3-pilot-homelessness-stage0a` … `-stage3`, `s3-pilot-school-police-stage4`, `s3-pilot-equity-programs/stage1/`,
  `s3-census-education-school-police-supplement2`). If any exist, show them to the runner with the stage outputs
  you found in each (mapped to this skill's file names), and 🛑 ask which trail to continue. Continue there, in its
  own folder names. **Never start a second trail for a topic.** Create `s3-prep-<topic_key>/` only when none exists.
- **Source store:** `backend/data/source-store/` in the repo, committed with each stage's PR. See
  [SOURCE-STORE.md](SOURCE-STORE.md).
- **Repo changes** (store files, migrations, annexes, codebook lines, RULINGS.md lines) go through your own
  ev-accounts worktree, a branch and a PR. Commit with an explicit pathspec only.
- **Database:** your own `backend/.env`. In a worktree the CLIs below borrow the main checkout's `.env`.
- **Migration slots:** `npm run steward --prefix backend -- slot <CA|CC> --purpose "…"`, in **your own** namespace
  (`CA_` = Chris Andrews, `CC_` = Chris Cantrell). Never infer it from a first name; ask if you do not know who you
  are working for.
- **Running the CLIs:** from the repo root, as `npm run <name> --prefix backend -- …`. npm switches into
  `backend/`, so 🔴 **every file path you pass (`--research`, `--research-only`, `--out`, `--transcript`, `--cwd`,
  `--forbid`) must be absolute.**

| What | Command |
|---|---|
| Seat rate (read-only) | `npm run topic:seat-rate --prefix backend -- --topic <key> [--season open\|draft\|<uuid>] [--research <abs dir>] [--research-only <abs dir>] [--json]` |
| Rung lint (read-only) | `npm run topic:ladder-lint --prefix backend -- --topic <key> [--season open\|draft\|<uuid>]` |
| Blindness check | `npm run topic:blindness-check --prefix backend -- --transcript <abs jsonl> --forbid <abs path> [--forbid …] --out <abs file> [--cwd <abs dir>]` |
| Store check | `npm run source-store --prefix backend -- validate` |

`--research <dir>` joins `<dir>/rows.tsv` onto the database rows. `--research-only <dir>` uses `rows.tsv` alone
(for a frozen test set).

**`rows.tsv` columns** (tab-separated, this header exactly): `politician_id`, `office_id`, `level`, `value`,
`blank_reason`, `blank_class`, `record_kind`, `gate`. `level` is federal, state, local, judicial or school.
`value` is empty, 0 (blank) or 1–5 (halves allowed). `blank_class` is `source-gap`, `gate`, `wording` or `no-lever`.
`record_kind` is `vote-yes`, `vote-no`, `sponsor`, `author`, `own-words` or `none`. `gate` is empty or one of
`multi-subject`, `consent`, `higher-law-duty`, `near-unanimous`, `off-version-sponsor`, `pre-seating`,
`study-directive`.

**`gates.tsv` columns** (tab-separated): `instrument_id`, `vote_date`, `body`, `motion`, `kind` (action-item,
consent, en-bloc, roll-call, sponsor), `yes`, `no`, `absent`, `body_size`, `own_motion`, `higher_law_duty`,
`multi_subject`, `gate`, `note`. `gate` is the first gate that applies, by the rules in
`backend/scripts/lib/gatePrescreen.ts`; empty means the record can seat.

## The path decision (Stage 0a decides it)

| What Stage 0a finds | Path |
|---|---|
| Most blanks are **source gaps** | **Source path**: targeted collection plus joint evidence, then re-measure. No rewording. |
| Most blanks are **gates** | Run the Stage 0 census first, to find gate-free records (action-item votes, divided roll calls). No wording work before it. Then re-measure with the census rows classified: if wording blanks now hold the majority, continue on the **Wording path** (Stage 1 on); otherwise take the **Source path**. |
| Most blanks are **wording**, or the rung lint fails | **Wording path**: full Stages 0–4. |
| The topic has no history | Wording path's census, to get a baseline. |

"Most" means one class holds more than half of the classified blanks. When no class does, or the result is
otherwise unclear, 🛑 **ask the runner to rule the path** (one question, with your recommendation).

## Stage 0a — audit and diagnose

1. Read the served revision in the open and the draft season, and every existing row for the topic:
   `inform.politician_answers`, `politician_context`, `stance_research_review`, `stance_coder_labels`, gold labels.
2. Measure the seat rate now: `npm run topic:seat-rate --prefix backend -- --topic <key> --season open`, then
   `--season draft`. Note overall, per level and per rung.
3. Classify **every** blank into one class: **source gap** (no evidence, or the deciding text was never fetched);
   **gate** (consent agenda, near-unanimous, higher-law duty, multi-subject, off-version sponsor, pre-seating);
   **wording** (compound-partial, absence or degree clause, side shown but no rung, nested rungs); **no lever** (the
   level cannot act; own words only). Write `stage0a/rows.tsv`.
4. Re-run the seat rate with `--research <absolute path to stage0a>` for the class breakdown and the affirmative
   rate (T1 definition).
5. Lint the current rungs: `npm run topic:ladder-lint --prefix backend -- --topic <key> --season draft` (and
   `--season open` if the pins differ). Check L1–L10 and the T6 stated-act rule by reading.
6. Pick the path. Write `stage0a/diagnosis.md`: headline first, counts, the losses a rung change could recover,
   the path and why. Describe losses by kind; name no person and no instrument, because a Stage 2 drafter may read
   this file. `rows.tsv` is forbidden to drafters.
7. 🛑 Path ruling, only when the split is unclear. 📋 Monday step.

## Source path (instead of Stages 1–4)

1. Read the store first (as Stage 0, step 1). For each source-gap row, collect the missing record or the person's
   own words with collectors briefed from [templates/BRIEF-census.md](templates/BRIEF-census.md), aimed at the named
   people. **Save every source to the store.**
2. Look for joint evidence (codebook V4.2, E2): independent sources that together meet every clause of one rung.
3. Hand coding to the research-stances pipeline with `--season draft`, against the topic's current Season 3 pin.
   🛑 **One yes per coding batch.** Batches run only once Stage 0a has chosen the Source path, which means the
   rungs are final for this season. In the question, say that rows written now pin the current Season 3 revision:
   a later rewording cannot re-pin the topic while Season 3 holds answers on it. If a wording problem shows up after
   draft rows exist, stop and 🛑 ask the runner one question: withdraw the draft rows (so the topic can be re-pinned
   this season), or defer the rewording to the next season. Recommend one.
4. Rows go through the existing review queue. Re-measure with `topic:seat-rate --season draft --research …`.
5. 📋 Monday step (stage `done`, or `0a` again if a wording problem showed up).

## Stage 0 — census, with a gate pre-screen

1. **Read the store first:** `jurisdictions/` (portals, rosters, session lists, higher-law duties), `instruments/`
   (bills and votes already found), `people/` (sources and term dates) and `dead-ends.jsonl`. Collect only what is
   missing.
2. Roster from `essentials.office_terms` (read-only), for every level that holds a lever on the topic.
3. Brief collectors with [templates/BRIEF-census.md](templates/BRIEF-census.md) (fill every `{{…}}`). Run them as
   subagents (the `source-collector` agent type), each writing one JSON file into `stage0/raw/`.
4. Match records to roster people. 🔴 **Identity check before any gate result**: confirm each person on the
   official session list or minutes for that vote date, never by surname alone.
5. **Gate pre-screen per record**, before it counts: tally and body size, consent or action item, higher-law duty,
   single-subject under the season's served topic list, and sponsor version. Write `stage0/gates.tsv`. Gated
   records are listed, not counted. Companion bills count as two records.
6. **Save every source to the store** (instruments with every vote, people, jurisdictions, dead ends). Run
   `npm run source-store --prefix backend -- validate`.
7. Gate: at least **10 seatable, gate-free, lever-level records** attributable to roster people (a school record
   needs 3 or more named voters seated on the vote date). A FAIL with a clear reason ("every school act is Yes") is
   a valid result: the topic is parked or reshaped, not forced. Write the result in `stage0/census.md`.
8. 🛑 Each ruling the census raises (one question each). 📋 Monday step.

## Stage 1 — frozen test set (Wording path)

1. Draw the test set by the standing sampling rules in [RULINGS.md](RULINGS.md). Write the draw script and its
   seed, hash them in `stage1/draw-prereg.txt`, and only then run the draw.
2. Collect operative text and prime sponsors with [templates/BRIEF-stage1.md](templates/BRIEF-stage1.md).
   **Save every source to the store.**
3. List exposed items (gold rows used to write any ladder, items named in drafts or memory notes) in
   `stage1/EXCLUDE.txt`.
4. Freeze: SHA-256 of every file in `stage1/FROZEN.md` (`shasum -a 256`), with counts by level and act, and the
   judgment calls you made. From here, nothing is edited; a later item goes in a labelled supplement.
5. 🛑 The judgment calls, each as a ruling. An overrule reissues the set as v1b, never an edit. 📋 Monday step.

## Stage 2 — blind drafts

1. Start the blind drafter as a **subagent** with [templates/drafter-prompt.md](templates/drafter-prompt.md). It
   writes `stage2/drafts.md`: the control (live revision, copied), then two drafts that differ in one place only,
   each rung checked against L1–L10 and T6, with annex lines, evidence-by-level tables, a named risk list and open
   questions with recommendations.
2. When it finishes, run the blindness check on its transcript
   (`~/.claude/projects/<project-key>/<session-id>/subagents/agent-<agentId>.jsonl`), with every forbidden path from
   the prompt as a `--forbid`, and `--out <absolute path>/stage2/blindness-check.txt`. Exit 0 = PASS. Exit 1 = a
   forbidden read: **the draft is void**; delete it and start a fresh drafter. Exit 3 = no evidence: find the right
   transcript; a draft with no PASS is not used. Exit 2 = fix the flags and re-run.
3. 🛑 Each open question in `drafts.md`, one at a time. Record the answers in its "Rulings" section. 📋 Monday step.

## Stage 3 — seatability test and adversarial check

1. Verify the freeze: `shasum -a 256 -c` against `stage1/FROZEN.md`. Any mismatch stops the stage.
2. **Pre-register before any label** (`stage3/preregistration.json`, hashed): T3 pairs (10, among items that can
   seat), the validation sample, the winner and tie rule, default readings, and variants.
3. One-pass act checklist per instrument, with verbatim quotes. Map acts to every ladder × variant × codebook
   version. Apply the gates.
4. Score: **T1** ≥ 60% of affirmative records, on ungated rows, at lever levels that acted (own words reported
   apart, no regression against the control); **T3** 10 of 10 pre-registered pairs; **T5** cost reported (seats and
   voter answers that move); **T6** 0 lint hits (or a written reason per hit). Write `stage3/rows.tsv` for the
   leading draft and check it with `topic:seat-rate --research-only <absolute path to stage3>`.
5. Blind validation: separate validator subagents code the sample from the codebook, ladder, annex and frozen texts
   only. Bar ≥ 95%. **Below 95%, stop:** find the checklist gap that explains the misses, fix it, re-code and
   re-validate. If one checklist entry does not explain the misses, run full holistic coding of the set instead of
   the checklist (spec §5.4), then validate again.
6. **Adversarial check** (replaces T4): follow [ADVERSARIAL-CHECK.md](ADVERSARIAL-CHECK.md) with
   [templates/adversary-prompt.md](templates/adversary-prompt.md). It writes `stage3/disputes.md` and
   `stage3/expert-queue.json`.
7. Write `stage3/results.md`: a one-page summary first (table of T1, T3, T5, T6, validation; winner; rulings owed;
   disputes; the closed attacks with their one-line reasons), then method and detail.
8. 🛑 Each ruling and each dispute. **Stage 3 passes only when every dispute is ruled.** 📋 Monday step.

## Stage 4 — revision package and apply

Follow [STAGE4-RECIPE.md](STAGE4-RECIPE.md) and [templates/stage4-revision.sql](templates/stage4-revision.sql).
It writes `stage4/README.md` (package, approvals owed, progress log) and `stage4/revision.md`.

🛑 Stops, each a separate yes: the package (text, rung map, rationale, public note, annex lines); applying the
migration on production; merging the PR. Then re-measure (`topic:seat-rate --season draft`), propose RULINGS.md lines
for any ruling that generalises (same PR), and 📋 Monday step with stage `done` and the revision id.

## How to ask for a ruling

One plain question per ruling, each with a recommendation. Never a batch of options with no view.

> **Q3 — Does a separate part on colleges make the bill multi-subject?**
> The bill's section 4 says: "…" (one quoted sentence). In plain words: it sets rules for colleges, not schools.
> Reading A: it is a separate subject, so the vote cannot seat. Reading B: it is part of the same subject.
> **Recommend A**, because … . Cost: 6 rows stay blank.

Ask, then wait. Record the answer, the date and the runner's name in the stage file's "Rulings" section. If it
generalises beyond this topic, propose a line for RULINGS.md in the next PR; if it does not, it goes in the topic's
Season annex.

## Monday step (end of every stage)

The topic's **Story** on the Backlog board (ids in [config.json](config.json)) shows Chris and the team where the
topic stands. The latest update is the status.

1. Find the Story named `S3 topic prep — <topic_key>` in group `group_mm46qn8m` of board `18417210762`
   (`get_board_items_page`). **If it is missing, create it** (`create_item`) with Epic = `Season 3 topic prep`,
   Pillar = `Inform`, Owner = your Monday user id, Status = `In Progress`.
2. Build the text with `formatUpdate` from `backend/scripts/lib/topicPrepUpdate.ts`:

   ```bash
   (cd backend && TOPIC_PREP_STATE='{"topicKey":"<key>","stage":"0a","path":"wording","seatRateBefore":0.2,"seatRateAfter":null,"blockedOn":"ruling","nextStep":"…","owed":["…"],"disputesOpen":0,"expertQueue":0,"researchFolder":"<abs path>"}' \
     npx tsx -e "import('./scripts/lib/topicPrepUpdate.ts').then(m => { const s = JSON.parse(process.env.TOPIC_PREP_STATE); console.log(m.statusLabel(s)); console.log(m.formatUpdate(s)); })")
   ```

   `stage` is `0a`, `0`, `1`, `2`, `3`, `4`, `done` or `parked`; `blockedOn` is `ruling`, `sources`, `dispute` or
   `nothing`. Owed items (rulings, disputes, sources to fetch) go in `owed`.
3. Post the text as an update on the Story (`create_update`). Set Status to the first printed line
   (`change_item_column_values`): `In Progress`, `Blocked` or `Done`.
4. 🔴 Never create or edit subitems (they are `/standup`'s day-slices). Never write to the private My Sprints board
   (`18426889128`). Never touch board-relation columns.
5. **No Monday access?** Print the update you would have posted, say so in one line, and carry on.
