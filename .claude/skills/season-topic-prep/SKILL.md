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
3. The rulebook as **ruled** is the tables in `docs/superpowers/specs/2026-10-07-season3-ladder-evaluation.md`
   ("Rulebook rulings" for L1–L10, "Evidence rules, seatability test" for E1, E2 and T1–T6). Read those first.
   `docs/superpowers/specs/2026-10-07-season3-design.md` §2–§4 is the **proposal** they ruled on: where the two
   differ, the ruling wins (for example L10 is five rungs always, with no fewer-rung exception, and E1 lets a
   co-sponsorship seat a chair alone). T4 is replaced by the adversarial check
   ([ADVERSARIAL-CHECK.md](ADVERSARIAL-CHECK.md)).

## Hard rules

- 🔴 **No database write, revision row, migration or `--season draft` batch without the runner's explicit yes.**
  Read-only `SELECT`s are fine. Never print `DATABASE_URL`.
- Never seat by presuming what a source does not say. An absence read into silence is not evidence. A blank spoke
  is correct.
- An item used to write a ladder never counts toward that ladder's test (exposure). List it in `EXCLUDE.txt`.
- Never ask the runner to read a whole bill. Ask about one quoted sentence (see "How to ask for a ruling").
- No party names and no partisan colours, anywhere.
- Fetching manners: one item at a time for meeting and bill portals; no scripted bulk requests and no loops;
  respect robots and terms. One `curl` of one known document URL (then `pdftotext`, or `pdftoppm` to read
  strike-through) is fine when the fetch tool returns a binary PDF or an iframe. A blocked portal is a gap, never
  "none". Record it in the store's `dead-ends.jsonl`.
- **Dry mode** (a run limited to research, or a test run of this skill): Stages 0a–3 and the Stage 4 package are
  offline. The first write anywhere outside the research folder is the slot reservation (Stage 4 step 3), so a dry
  run stops at yes #1. Write the source store as a staging copy (`--root <research folder>/<stage>/store-staging`)
  and merge it into the repo store later with `npm run source-store --prefix backend -- merge --from <abs dir>`.
- 🔴 **Keep files that name people or instruments out of the session scratchpad.** A subagent's scratchpad is the
  session's scratchpad, so a blind drafter that writes a helper there "touches" those files and is void. Keep
  named working files in the research folder.

## Settings

- **Settings file:** [config.json](config.json) (committed). It holds the Monday board, group, column ids, status
  labels, the research root and the source-store path. Nothing in this skill reads another person's files.
- **Overrides by environment variable:** `EV_MONDAY_USER_ID` (your Monday user id, used as the Story owner) and
  `EV_RESEARCH_ROOT` (your research root). Without them, the owner is the Monday user the connector is signed in as,
  and the research root is `~/Documents/GitHub/.planning/research`. The Story owner is the runner, the person
  running this skill (Chris Andrews by default).
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
  `backend/`, so 🔴 **every file path you pass (`--research`, `--research-only`, `--rows-out`, `--out`, `--transcript`,
  `--cwd`, `--forbid`) must be absolute.**

| What | Command |
|---|---|
| Seat rate (read-only) | `npm run topic:seat-rate --prefix backend -- --topic <key> [--season open\|draft\|<uuid>] [--research <abs dir>] [--research-only <abs dir>] [--rows-out <abs file>] [--json]` |
| Rung lint (read-only) | `npm run topic:ladder-lint --prefix backend -- --topic <key> [--season open\|draft\|<uuid>]` |
| Blindness check | `npm run topic:blindness-check --prefix backend -- --transcript <abs jsonl> --forbid <abs path> [--forbid …] --out <abs file> [--cwd <abs dir>]` |
| Store check | `npm run source-store --prefix backend -- validate [--root <abs dir>]` |
| Store merge (staging copy into the repo store) | `npm run source-store --prefix backend -- merge --from <abs dir>` |
| Topic list hash for a single-subject verdict | `npm run source-store --prefix backend -- topic-list-hash --season open\|draft\|<uuid>` |
| Read-only query (one SQL file, inside `BEGIN READ ONLY … ROLLBACK`) | `npm run db:ro --prefix backend -- --file <abs .sql> [--json]` |
| Identity check (roll-call names to roster people) | `npm run census:identity --prefix backend -- --rollcalls <abs json> --sessions <abs json> --roster <abs tsv> --out <abs json>` |

`--research <dir>` joins `<dir>/rows.tsv` onto the database rows. `--research-only <dir>` uses `rows.tsv` alone
(for a frozen test set). Every file path passed to `db:ro` and `census:identity` must be absolute too.

**`rows.tsv` columns** (tab-separated, this header exactly): `politician_id`, `office_id`, `level`, `value`,
`blank_reason`, `blank_class`, `record_kind`, `gate`. `level` is federal, state, local, judicial or school.
`value` is empty, 0 (blank) or 1–5 (halves allowed). `blank_class` is `source-gap`, `gate`, `wording`, `no-lever`,
`off-question` or `nay-only` (Stage 0a step 3). `record_kind` is `vote-yes`, `vote-no`, `sponsor`, `author`,
`own-words` or `none`; it describes the person's **on-question** record, so a Yea on a question this ladder no
longer asks is `none` (ruling, RULINGS.md "Off-question records"). `gate` is empty or one of
`multi-subject`, `consent`, `higher-law-duty`, `near-unanimous`, `off-version-sponsor`, `pre-seating`,
`study-directive`.

**`gates.tsv` columns** (tab-separated): `instrument_id`, `vote_date`, `body`, `motion`, `kind` (action-item,
consent, en-bloc, roll-call, sponsor), `yes`, `no`, `absent`, `body_size`, `own_motion`, `higher_law_duty`,
`multi_subject`, `gate`, `note`. `gate` is the first gate that applies, by the rules in
`backend/scripts/lib/gatePrescreen.ts`; empty means the record can seat.

## The path decision (Stage 0a decides it)

Read the rows **in this order**; the first that applies decides.

| # | What Stage 0a finds | Path |
|---|---|---|
| 1 | The rungs mix two objects that real laws regulate apart (the restructure check, step 7) | 🛑 Ask the runner: keep the topic, or split or merge it. A split follows "Splitting or merging a topic" below. |
| 2 | A **real** lint hit (one that survives the reading in step 5) on a rung that holds seats or would hold the commonest record | **Wording path**: full Stages 0–4, whatever the blank split. A real hit on an empty rung only: note it and go on to row 3. |
| 3 | Many `off-question` blanks (a quarter or more of the classified blanks) | 🛑 Ask the runner for a question-scope ruling: keep the question (those rows stay blank) or widen it (a material rewrite, Wording path). |
| 4 | Most blanks are **wording** | **Wording path**: full Stages 0–4. |
| 5 | Most blanks are **gates** | Run the Stage 0 census first, to find gate-free records (action-item votes, divided roll calls). No wording work before it. Then re-measure with the census rows classified: if wording blanks now hold the majority, continue on the **Wording path** (Stage 1 on); otherwise take the **Source path**. |
| 6 | Most blanks are **source gaps** | **Source path**: targeted collection plus joint evidence, then re-measure. No rewording. |
| 7 | The topic has no history | Wording path's census, to get a baseline. |

"Most" means one class holds more than half of the classified blanks; `nay-only` and `off-question` rows count in
the total but are never the majority a path is chosen for (no collection and no rung change on this question seats
them). "Lint fails" always means a real hit after reading, never a raw hit. When no row decides, or the result is
otherwise unclear, 🛑 **ask the runner to rule the path** (one question, with your recommendation).

## Stage 0a — audit and diagnose

1. Read the served revision in the open and the draft season, and every existing row for the topic:
   `inform.politician_answers`, `politician_context`, `stance_research_review`, `stance_coder_labels`, gold labels.
   The served rung text is `inform.compass_stance_revisions` joined on the season's
   `season_questions.topic_revision_id` (`topic:ladder-lint` prints it); `inform.compass_stances` still holds
   Season 1's text, so never read the ladder from there. Run the queries with `npm run db:ro`.
   - **Coder labels with no answer row** (shadow runs) are lever evidence: report them in `diagnosis.md` by kind,
     never in `rows.tsv`, and list the people as exposure candidates for Stage 1 (`EXCLUDE.txt`).
   - **List every instrument the live ladder or its annex names.** Their records are exposed (RULINGS.md
     "Exposure"), so the census knows before it spends fetches on them.
2. Measure the seat rate now: `npm run topic:seat-rate --prefix backend -- --topic <key> --season open`, then
   `--season draft`. Note overall, per level and per rung. Answers whose politician holds no current office
   (candidates, former holders the compass still shows) are dropped from the rate with one line ("no current
   office: N"); `--rows-out` lists them in `rows.skipped.tsv`. Report them apart in `diagnosis.md` (for example
   "109 answers, 9 with no current office, 7 seats").
3. Classify **every** blank into one class: **source gap** (no evidence, or the deciding text was never fetched);
   **gate** (consent agenda, near-unanimous, higher-law duty, multi-subject, off-version sponsor, pre-seating);
   **wording** (compound-partial, absence or degree clause, a Yea or sponsorship that shows a side but no rung,
   nested rungs); **no lever** (the level cannot act; own words only); **off-question** (a real own act or own
   words on a question this ladder no longer asks, codebook V2 `adjacent` or `off`); **nay-only** (the only
   on-question record is a No vote, or a pause or keep vote no rung states: it shows a side for ever, so no
   wording change seats it; `record_kind` = `vote-no`). Write `stage0a/rows.tsv`. Start it with
   `npm run topic:seat-rate --prefix backend -- --topic <key> --season open --rows-out <absolute path>/stage0a/rows.tsv`
   (use `--season draft` instead when the draft season holds the rows you classify): one row per database answer,
   with `blank_class` filled from the stored blank reason where one maps (`direction-only` never does: read the
   record and choose `wording` or `nay-only`), `record_kind` = `none` and `gate` empty. Then fill `blank_class`,
   `record_kind` and `gate` by hand for every row. It refuses to overwrite an existing file; copy the untouched
   starter to `rows.starter.tsv` before you edit.
   - **Where the reason lives.** The stored reason comes from `stance_research_review`. Rows blanked by a repair
     migration have no review row: their reason is prose in `politician_context.reasoning`, and the earliest
     season's context row holds the original evidence. `--rows-out` writes both (first 300 characters) to
     `rows.reasons.tsv` beside `rows.tsv`.
   - Names and notes go in sidecars (`rows.reasons.tsv`, `rows.skipped.tsv`, a `row-notes.tsv` of your own). All of
     them are forbidden to drafters, like `rows.tsv`.
4. Re-run the seat rate with `--research <absolute path to stage0a>` for the class breakdown and the affirmative
   rate (T1 definition). When fewer than 10 rows are affirmative, the report says so: make the overall rate the
   headline and say why (with only seated rows affirmative, the affirmative rate reads 100% and means nothing).
   **Then check every seated row** against every clause of its rung (codebook V4.2): a seat that rests on one of a
   rung's two clauses is at risk in the adversarial check. Count the seats at risk; they are losses a rung change
   could protect, and they decide whether the Source path's freeze of the rungs is safe.
5. Lint the current rungs: `npm run topic:ladder-lint --prefix backend -- --topic <key> --season draft` (and
   `--season open` if the pins differ). Check L1–L10 and the T6 stated-act rule by reading. The lint prints raw
   hits; read each. Known false positives: a "without" that names who a fallback is for ("voters without one"),
   an "every <object>" that is the object itself, an "and" inside one object list. Also compare each rung with the
   annex's operative clauses: a rung that states two or more of them is an L6 check by hand, whatever the lint
   says.
   Read the topic's Season 2 annex lines on single-subject too: a line such as "an omnibus election bill that
   includes an ID clause → multi-subject" predates codebook 0.5, under which a bill is multi-subject only when a part
   is evidence for **another served topic**. Flag such a line for the Season 3 annex before the census pre-screen,
   because it decides the commonest state records (voting-rights CA_0318 replaced its line this way).
6. Pick the path (the table above, in order). Write `stage0a/diagnosis.md`: headline first, counts, the seats at
   risk, the losses a rung change could recover, the path and why. Describe losses by kind; name no person and no
   instrument, because a Stage 2 drafter may read this file. Names go in the sidecars, which are forbidden to
   drafters; a ruling question to the runner may name them, because the drafter never reads it.
7. **Restructure check.** Do the rungs mix two objects that real laws regulate apart (for example ID to vote and
   proof to register)? Count the people with records on each and on both. If many records sit on one object only,
   say so in the diagnosis; it is path row 1.
8. 🛑 Path ruling, only when the table does not decide. 📋 Monday step.

## Splitting or merging a topic

A split (or merge) is a runner's ruling, asked as one question with the restructure check's counts. Bring: the
people with records on each object and on both, the rungs each new topic would keep, and what moves. A split
reopens, for **each** new topic: its own Stage 0a–4; a reissued frozen set (items move to the topic whose object
they act on; an item on both is in both); the rulings that named the old topic (re-read each, re-ask any whose
scope changes); and the single-subject readings, because a law with operative parts on both new topics becomes
multi-subject for each while both are served. Write the comparison in `<stage>/split-analysis/`. Nothing in the
database changes until each new topic reaches its own Stage 4.

## Source path (instead of Stages 1–4)

1. Read the store first (as Stage 0, step 1). For each source-gap row, collect the missing record or the person's
   own words with collectors briefed from [templates/BRIEF-census-local.md](templates/BRIEF-census-local.md) or [templates/BRIEF-census-state.md](templates/BRIEF-census-state.md), aimed at the named
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
   `essentials.districts.state` is mixed case (upper for Congress and statewide offices, lower for legislative
   districts), so filter on `upper(d.state)`.
   - **For a state or federal lever the unit is the law, not the roster** (thousands of legislators). List
     candidate laws first, from the annex, the shadow coder labels and one search pass; keep the states whose
     legislature is in the roster; give each collector a list of named bills.
3. Brief collectors with [templates/BRIEF-census-local.md](templates/BRIEF-census-local.md) (boards and councils)
   or [templates/BRIEF-census-state.md](templates/BRIEF-census-state.md) (state laws and Congress); fill every
   `{{…}}`. Run each as a general-purpose subagent given that brief (use the `source-collector` agent type if it is
   installed), each writing one JSON file into `stage0/raw/`.
4. Match records to roster people. 🔴 **Identity check before any gate result**: confirm each person on the
   official session list or minutes for that vote date, never by surname alone.
   - The database cannot say who sat in a chamber years ago (`term_start` is often unknown). **Fetch the official
     member list for each chamber and session you will count** (one collector, one list at a time) and save it in
     the store's `jurisdictions/` rosters.
   - Run `npm run census:identity` (rules in `backend/scripts/lib/identityMatch.ts`): printed name → one session
     member → one roster person with the same surname **and** first name. A name that fits two people stays
     unlinked. Run prime sponsors and authors through it too.
5. **Gate pre-screen per record**, before it counts: tally and body size, consent or action item, higher-law duty,
   single-subject under the season's served topic list (record its `topic_list_hash` from
   `source-store topic-list-hash`), and sponsor version. Write `stage0/gates.tsv`. Gated records are listed, not
   counted. Companion bills count as two records. 🔴 **A record counts only once its operative text (or amendment
   text) has been read** (RULINGS.md "Census — a record needs its operative text"); a title is a lead.
   **One record per instrument per chamber** (its final vote; a veto override is the enacting vote), plus each floor
   amendment voted on its own (RULINGS.md "Census — what one record is").
6. **Save every source to the store** (instruments with every vote and their sponsors, jurisdictions, dead ends;
   person files only for own words, sponsorships and term dates, since a roll-call vote lives on the instrument).
   Run `npm run source-store --prefix backend -- validate`.
7. Gate: at least **10 seatable, gate-free, lever-level records** attributable to roster people (a school record
   needs 3 or more named voters seated on the vote date). A FAIL with a clear reason ("every school act is Yes") is
   a valid result: the topic is parked or reshaped, not forced. Write the result in `stage0/census.md`, with this
   required line: **"Season rows reached: N of M; affirmative: K"** (the topic's own rows the records reach). For a
   state or federal topic the gate is easy to pass (one congressional vote covers hundreds of people); this line is
   what Stage 1 needs.
8. 🛑 Each ruling the census raises (one question each). 📋 Monday step.

## Stage 1 — frozen test set (Wording path)

1. Draw the test set by the standing sampling rules in [RULINGS.md](RULINGS.md). Write the draw script and its
   seed, hash them in `stage1/draw-prereg.txt`, and only then run the draw.
2. Collect operative text and prime sponsors with [templates/BRIEF-stage1.md](templates/BRIEF-stage1.md).
   **Save every source to the store.**
3. List exposed items (gold rows used to write any ladder, items named in drafts or memory notes) in
   `stage1/EXCLUDE.txt`.
4. Freeze: SHA-256 of every file in `stage1/FROZEN.md` (`shasum -a 256`), with counts by level and act, and the
   judgment calls you made. **Generate the counts table and the overlap line from the files** (a small script);
   never type them, because FROZEN.md is itself hashed and a wrong count can then only be fixed in a supplement.
   From here, nothing is edited; a later item goes in a labelled supplement.
5. 🛑 The judgment calls, each as a ruling. An overrule reissues the set as v1b, never an edit. 📋 Monday step.

## Stage 2 — blind drafts

1. Start the blind drafter as a **subagent** with [templates/drafter-prompt.md](templates/drafter-prompt.md). It
   writes `stage2/drafts.md`: the control (live revision, copied), then two drafts that differ in one place only,
   each rung checked against L1–L10 and T6, with annex lines, evidence-by-level tables, a named risk list and open
   questions with recommendations, and the axis name and the two poles (`axis`, `pole_1`, `pole_5`). Fill
   `{{ALLOWED_SEARCH_ROOTS}}` alongside `{{FORBIDDEN_PATHS}}`, and `{{DRAFTER_SCRATCH}}` with
   `<research folder>/stage2/tools/` (create it first; it holds nothing named). `--cwd` on the blindness check only
   affects how relative paths resolve and does not make a pathless search safe.
2. When it finishes, run the blindness check on its transcript
   (`~/.claude/projects/<project-key>/<session-id>/subagents/agent-<agentId>.jsonl`), with every forbidden path from
   the prompt as a `--forbid`, and `--out <absolute path>/stage2/blindness-check.txt`. Exit 0 = PASS. Exit 1 = a
   forbidden read: **the draft is void**; delete it and start a fresh drafter. Exit 3 = no evidence: find the right
   transcript; a draft with no PASS is not used. Exit 2 = fix the flags and re-run.
3. 🛑 Each open question in `drafts.md`, one at a time. Record the answers in its "Rulings" section. 📋 Monday step.

## Stage 3 — seatability test and adversarial check

1. Verify the freeze: `shasum -a 256 -c` against `stage1/FROZEN.md`. Any mismatch stops the stage.
2. **Pre-register before any label** (`stage3/preregistration.json`, hashed): T3 pairs (10, among items that can
   seat), the validation sample, the winner and tie rule, default readings, variants, and the T1 unit rule:
   **pooled T1 counts each (person, record) once**, so a person in both the draw and an earlier season's stratum for
   the same record is one item. Note that items on one instrument share a chair, so the validation sample's
   agreement is item-weighted (16 items may be 13 instrument readings); say how many instrument readings it holds.
3. **Before scoring, list every instrument whose act is `unresolved`** (a section unread, a page blocked, a
   marked-up PDF whose strike-through the text extraction lost; render it with `pdftoppm` and read the image).
   Fetch or rule each first: a missing source can decide the winner. Record the first-pass and final scores both.
   Then the one-pass act checklist per instrument, with verbatim quotes. Map acts to every ladder × variant ×
   codebook version. Apply the gates.
4. Score: **T1** ≥ 60% of affirmative records, on ungated rows, at lever levels that acted (own words reported
   apart, no regression against the control); **T3** 10 of 10 pre-registered pairs; **T5** cost reported (seats and
   voter answers that move); **T6** 0 lint hits (or a written reason per hit). Write `stage3/rows.tsv` for the
   leading draft and check it with `topic:seat-rate --research-only <absolute path to stage3>`.
   **If no draft passes every bar**, report which bar fails and why, and 🛑 ask the runner: accept the leading draft
   with a written reason, or write a further draft from the Stage 3 lesson on the same frozen set (RULINGS.md "A
   third draft after Stage 3"; no new test set is needed).
5. Blind validation: separate validator subagents code the sample from the codebook, ladder, annex, the
   **pre-registered default readings** and the frozen texts only (ruling, RULINGS.md "Validators get the default
   readings"). Bar ≥ 95%. **Below 95%, stop:** find the checklist gap that explains the misses, fix it, re-code and
   re-validate. If one checklist entry does not explain the misses, run full holistic coding of the set instead of
   the checklist (spec §5.4), then validate again.
6. **Adversarial check** (replaces T4): follow [ADVERSARIAL-CHECK.md](ADVERSARIAL-CHECK.md) with
   [templates/adversary-prompt.md](templates/adversary-prompt.md). It writes `stage3/disputes.md` and
   `stage3/expert-queue.json`. Read every closure against the **winning draft's own annex lines** for that rung, and
   have a second subagent review the closed-attack table before Stage 3 passes.
   After every ruling that rewords a rung, check the axis name and poles against rungs 1 and 5 again.
7. Write `stage3/results.md`: a one-page summary first (table of T1, T3, T5, T6, validation; winner; rulings owed;
   disputes; the closed attacks with their one-line reasons), then method and detail.
8. 🛑 Each ruling and each dispute. **Stage 3 passes only when every dispute is ruled.** 📋 Monday step.

## Stage 4 — revision package and apply

Follow [STAGE4-RECIPE.md](STAGE4-RECIPE.md) and [templates/stage4-revision.sql](templates/stage4-revision.sql).
It writes `stage4/README.md` (package, approvals owed, progress log) and `stage4/revision.md`.

🛑 Stops, each a separate yes: the package (text, rung map, rationale, public note, annex lines); applying the
migration on production; merging the PR. Then re-audit the carried seats (recipe step 9), propose RULINGS.md lines
for any ruling that generalises (same PR), and 📋 Monday step with stage `done` and the revision id. The seat rate is
re-measured only after Season 3 research has run on the topic; at apply, `--season draft` prints "no rows".

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
   (`get_board_items_page` with a `name contains_text "<topic_key>"` filter; do not use `searchTerm`, which returns
   at most 20 items and can miss the Story). **If it is missing, create it** (`create_item`) with Epic =
   `Season 3 topic prep`, Pillar = `Inform`, Owner = your Monday user id, Status = the printed status (step 2).
2. Build the text with `formatUpdate` from `backend/scripts/lib/topicPrepUpdate.ts`:

   ```bash
   (cd backend && TOPIC_PREP_STATE='{"topicKey":"<key>","stage":"0a","path":"wording","seatRateBefore":0.2,"seatRateAfter":null,"blockedOn":"ruling","nextStep":"…","owed":["…"],"disputesOpen":0,"expertQueue":0,"researchFolder":"<abs path>"}' \
     npx tsx -e "import('./scripts/lib/topicPrepUpdate.ts').then(m => { const s = JSON.parse(process.env.TOPIC_PREP_STATE); console.log(m.statusLabel(s)); console.log(m.formatUpdateHtml(s)); })")
   ```

   `stage` is `0a`, `0`, `1`, `2`, `3`, `4`, `done` or `parked`; `blockedOn` is `ruling`, `sources`, `dispute` or
   `nothing`. Owed items (rulings, disputes, sources to fetch) go in `owed`. `path` and the rates may be `null`
   before the path ruling (printed as —). `seatRateBefore` and `seatRateAfter`
   are the **affirmative-record seat rate** (T1) from `topic:seat-rate` when a research file was joined
   (`--research` or `--research-only`), and the **overall seat rate** otherwise. Use the same kind for both when
   you can. When a reader could not tell which (for example the two come from different kinds, or this is the
   first update), say which in `nextStep` ("rates are affirmative-record" or "rates are overall").
3. Post the text as an update on the Story (`create_update`; it takes HTML, which `formatUpdateHtml` prints). Set Status to the first printed line
   (`change_item_column_values`): `In Progress`, `Blocked` or `Done`.
4. 🔴 Never create or edit subitems (they are `/standup`'s day-slices). Never write to the private My Sprints board
   (`18426889128`). Never touch board-relation columns.
5. **No Monday access?** Print the update you would have posted, say so in one line, and carry on.
