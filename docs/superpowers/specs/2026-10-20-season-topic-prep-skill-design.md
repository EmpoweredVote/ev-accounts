# Season topic prep skill — design

**Date:** 2026-10-20
**Status:** proposed, awaiting Chris Andrews' approval
**Owner:** Chris Andrews (topic owner, operator namespace `CA_`)
**Repo:** EV-Accounts. The skill lives at `.claude/skills/season-topic-prep/` (my call: shared with the team and
versioned, unlike the user-level `/standup` skill).

---

## 1. Why this exists

Every compass topic must be prepared before a new season goes live. The goal is two things at once:

1. The topic follows the rulebook (L1–L10, T1–T6) and the codebook, so a chair means the same thing everywhere.
2. The topic **seats as many politicians as the evidence honestly allows**.

Season 2 research has become stricter, which is mostly right, but some topics now seat as few as ~20% of the
people researched. A topic that seats that few is failing, even if every blank is "correct". There are three ways
to raise the rate, and they must be tried in this spirit, never by lowering the evidence standard:

- **find more sources** for the same people (the bill text, the roll call, the board minutes, their own words);
- **combine sources** (codebook E2 joint evidence) so partial evidence adds up;
- **adjust the rungs** when the wording itself blocks seats (compound clauses, absence clauses, no rung for a
  common position).

**Season 2 order was:** adjust topics → push live → research. Research then showed small wording changes would
have seated many more people, too late. **From Season 3 on, the order is:** audit → research at scale → find where
people get stuck → fix → push live. The long-run aim is to research each topic across every jurisdiction and level
where it applies before the season opens.

**The skill must state this purpose in its first lines.** The homelessness Stage 1 session (2026-10-20) loaded
brainstorming and asked "why homelessness now?"; Chris had to restate the purpose. A session started with this
skill must never need to ask.

## 2. What we learned from the pilots (evidence for the design)

Pilots so far: library books, school police, school budget (parked), curriculum (parked), equity programs,
homelessness (in progress). Full trails: `.planning/research/s3-*` (workspace root, local-only) and the side-session
notes. Main lessons:

- **Most blanks are sources and gates, not wording.** Season 2 local: 46% of 2,502 rows found nothing. Homelessness
  lost 14 rows only because bill or ordinance text was never fetched. Homelessness Stage 0a: 0 of 36 Season 2
  blanks were recoverable by a rung change.
- **Gates were found too late.** School police ran Stage 2, Stage 3 and Stage 3-C before seeing that 30 of 65 rows
  could never seat (consent agenda, chambers under 10% No, an off-version sponsor). A supplement census of action-item
  votes then took it from ~20% to 75%.
- **When wording is the problem, fixing it pays a lot.** Library 10 → 29 → 41 (with the small-body rule);
  homelessness 33 → 60 of 98.
- **The same rulings are re-argued per topic:** furthest act, small-body rule, single-subject scope, higher-law
  duty vs own choice, Stage 1 sampling rules, "a blank spoke is correct", companion bills count as two.
- **Validation below 95% caused rework** every time, usually from checklist gaps.
- **T4 (blind operator labels) was never completed** on any topic; revisions were applied with T4 open. It is too
  heavy for one person reading dense bills (§5.6).
- **Sources are not reused.** `inform.source_snapshots` is keyed by batch; no run reads another run's sources;
  rosters, session lists and term starts live in TSVs and are rebuilt per topic.
- **Portals block bulk fetching** (BoardDocs CloudFront 403 after bulk curl; legiscan behind Cloudflare; Municode
  403 to curl). Item-by-item fetching and the built-in browser work.
- **One session per stage plus relayed notes added overhead**, mostly status pings.
- **Seat rate is not measured anywhere** (no page, saved query or gate).

## 3. Goals, non-goals, anti-goals

**Goals**
1. One consistent, repeatable process per topic, from audit to revision, that any session can run.
2. Find the issues early: classify every blank before any rewording, and pre-screen gates in the census.
3. A standing rulebook so settled rulings are applied, not re-argued.
4. Replace T4 with a check Chris can actually do (§5.6).
5. Save every useful source in a fixed format so later topics, seasons and the national research reuse it.
6. Monday.com tracking on the standup skill's board, showing Chris and the team what is owed per topic, updated by the skill.
7. Measure seat rate per topic, per level, before and after.

**Non-goals (this project)**
- The database source-and-bill library. That is **project 2**, designed next; it will import what this skill saves
  (§5.7). This project fixes the file format only.
- National-scale coding runs. The skill prepares a topic and proves the ladder; the wide research uses the existing
  research-stances / coder pipeline.
- Changing the codebook's evidence standard.

**Anti-goals (failure even if it "works")**
- Seats gained by presuming what a source does not say (e.g. reading an absence into silence; Season 2 pricing
  showed this would contradict 9 gold rulings).
- Ladders fitted to the test set (exposure). An item used to write a ladder never counts toward its test.
- Any database write, revision row, migration, or `--season draft` push without Chris's explicit yes.
- Asking Chris to read whole bills.
- Partisan framing (antipartisan principle: never show parties or partisan colours).

## 4. Constraints

- **Codebook governs.** `docs/codebook/stance-and-quote-codebook.md` (0.6 today) wins over the skill. The skill reads
  the current version at run time and records it.
- **Planning output is local-only.** Research folders live in `~/Documents/GitHub/.planning/research/` (a never-pushed
  checkout). Repo changes (migrations, annexes, codebook lines, the skill) go through an ev-accounts worktree, a
  branch and a PR.
- **Blindness and freezing rules stay** (§5.4, §5.5): blind drafter, SHA-256 freeze, pre-registration before labels,
  labelled supplements instead of edits.
- **Fetching manners:** item-by-item for portals; no bulk scripted requests; respect robots and terms (e.g. Digital
  Democracy forbids automated access); a blocked portal is a gap, never "none".
- **Migration slots** come from `node backend/scripts/steward.mjs slot CA --purpose …` (main clone holds `.env`).
- **Chris's reporting style** for chat: plain English, result first.

## 5. The process

One session runs a topic end to end (orchestrator). It starts side sessions only where independence requires it:
the **blind drafter** (Stage 2) and the **adversarial checker** (Stage 3). Each stage ends by writing its result file,
updating the topic's Monday Story, and stopping for any ruling Chris owes. Rulings are asked as one plain question each with a
recommendation (the format Chris has accepted throughout the pilots).

### 5.0 Audit and diagnose (new; generalises homelessness "Stage 0a")

Inputs: topic key; the served revision in the open and draft seasons; all existing rows for the topic
(`inform.politician_answers`, `politician_context`, `stance_research_review`, `stance_coder_labels`, gold labels).

1. **Measure seat rate** now: overall, per level, affirmative-record rows only (T1 definition), and per rung.
2. **Classify every blank** into one of:
   - **source gap** — no evidence found, or the deciding text was never fetched;
   - **gate** — consent agenda, near-unanimous, higher-law duty, multi-subject, off-version sponsor, pre-seating;
   - **wording** — compound-partial, absence or degree clause, side shown but no rung, nested rungs;
   - **no lever** — the level cannot act; own words only.
3. **Rulebook lint** of the current rungs (L1–L10, T6).
4. **Pick the path** and write `stage0a/diagnosis.md`:
   - mostly source gaps → **Source path**: targeted collection plus joint evidence, then re-measure. No rewording.
   - mostly gates → the census must find gate-free records (action-item votes, divided roll calls) before any
     wording work.
   - mostly wording, or the lint fails → **Wording path**: full Stages 0–4.
   - A topic with no history runs the Wording path's census to get a baseline.

Chris rules on the path only when the split is unclear.

### 5.1 Stage 0 — census, with a gate pre-screen

As in the pilots (roster from `essentials.office_terms`; collectors; match; judge; identity check), plus:
- **Gate pre-screen per record** before it counts: tally (and body size), consent vs action item, higher-law duty,
  single-subject under the current served topic list, sponsor version. Gated records are listed, not counted.
- **Identity check before the gate result** (official session lists), never surname-only.
- **Reuse first:** read the source store (§5.7) for rosters, session lists, term starts and instruments already
  found, then collect only what is missing.
- Gate: at least 10 seatable, gate-free, lever-level records attributable to roster people (school records need 3+
  named voters seated on the vote date). A FAIL with a clear reason (e.g. "every school act is Yes") is a valid
  result: the topic is parked or reshaped, not forced.

### 5.2 Stage 1 — frozen test set

Standing sampling rules apply (§6). SHA-256 freeze (`FROZEN.md`), `EXCLUDE.txt` for exposed items, pre-registered
draws. Judgment calls listed for Chris; an overrule reissues as v1b.

### 5.3 Stage 2 — blind drafts

A side session drafts; it never opens Stage 1, census folders, side notes, shadow runs or named memory notes.
Control + two drafts that differ in one place only. Each rung checked against L1–L10 and T6, with annex lines,
evidence-by-level tables and a named risk list. Open questions go to Chris with recommendations.

### 5.4 Stage 3 — seatability test

As in the pilots: verify hashes; pre-register (T3 pairs, validation sample, winner and tie rule, default readings,
variants); one-pass act checklist with verbatim quotes; map to every ladder × variant × codebook version; T1 (≥ 60%
of affirmative records, ungated rows, lever levels that acted), T3 (10/10 pre-registered pairs), T5 (cost reported),
T6 (0 lint hits); blind validation ≥ 95%. **T4 is replaced** (§5.6).

### 5.5 Stage 4 — revision package and apply

The CA_0314 recipe (`.planning/research/s3-pilot-equity-programs/stage4/`, merged as EmpoweredVote/ev-accounts#1053):
offline package (revision fields, rationale with L1 poles first, public note, rung map keyed by **old** rung with
`"invalidated"` allowed, Season 3 annex, codebook line if owed) → on Chris's yes: reserve slot → worktree + PR →
prod dry run (body twice inside BEGIN, forced rollback via RAISE) → apply on a second explicit yes → record the
revision id → merge → confirm the steward slot is `written`. Known traps to encode: `guidance` is not a propose
parameter (set it on the draft row before approve); season question counts in the gate must be re-read.

### 5.6 The adversarial check (replaces T4)

Why: T4 asked Chris to label bill-based rows blind, from dense legal text where one clause changes the answer. That
is expert work; it was never completed on any topic. Its purpose was an independent check on a misreading that the
coders and the checklist (same model family) might share.

Replacement:
1. **Adversarial checker** (independent side session): for every seated row and a sample of blanks, read the source
   and try to prove the chair wrong — hunt for the clause that moves the rung, makes it direction-only, multi-subject,
   or gated. It reports each attack with the deciding sentence quoted. Agreement is not the output; failed attacks are.
2. **Disputes to Chris as plain questions.** Each surviving attack becomes one question: the deciding sentence, a
   plain-English explanation of what it does, the two readings, and a recommendation. No full bill, no blind labelling.
   Expect 0–3 per topic.
3. **Gate:** Stage 3 passes only when every dispute is ruled. The ruled answers feed the standing rulebook when they
   generalise.
4. **Expert queue:** every seated row that rests on a bill or ordinance is listed in `stage3/expert-queue.json` (and
   counted in the Monday update) for future political-science reviewers. Revisions state honestly that expert review is
   owed.

Existing T4 items on the Blind Gold Desk (t4lib, t4pol, t4eq) are retired from the gate; they stay available as
optional expert-queue items.

### 5.7 Source capture (fixed format; project 2 imports it)

Every stage saves what it finds into a **source store** (location: §9 item 6, `backend/data/source-store/` in the
repo), in addition to the per-stage folders:

- `instruments/<jurisdiction>/<instrument-id>.json` — one bill, ordinance, policy or resolution: official URL(s),
  version (as filed / enrolled), operative text or a saved copy path, single-subject verdict per served topic list
  (with season and codebook version), higher-law duty notes, and **every vote**: date, body, motion, action item vs
  consent, tally, and per-member Yea/Nay/absent with person ids where matched.
- `people/<politician-id>.json` — sources found for the person (own words and records), with topic keys and whether
  each was useful, plus term dates found.
- `jurisdictions/<scope>.json` — portals and how to fetch them (works / blocked / needs browser), roster and session
  list sources, standing higher-law duties per topic.
- `dead-ends.jsonl` — what was searched and found nothing, or was blocked, with date, so nobody repeats it.

Each file records who fetched it, when, how (WebFetch, curl, browser, OCR), and the SHA-256 of any saved copy.
Hand-saved sources keep the existing rule (source and method on the first line; Chris's OK). The exact JSON schema is
the builder's to write, but it must carry those fields and use stable ids (politician UUIDs; jurisdiction scopes in
the steward form `state:`, `county:`, `place:`; instrument ids such as `WA-ESSB-5044-2021`).

### 5.8 Measuring seat rate

A read-only script (builder's choice of location under `backend/scripts/`) reports, per topic and per level: rows,
seated, blank by reason class (§5.0), affirmative-record seat rate, and per-rung counts, for the open season and the
draft season. The skill runs it at Stage 0a and after Stage 4 (or after a Source-path run) and writes the numbers to
Monday.

## 6. Standing rulebook

A file the skill reads before every stage: `.claude/skills/season-topic-prep/RULINGS.md`. It holds rulings that apply
across topics, each with date, source and scope:

- furthest act (library Q2, 2026-10-15; confirmed for equity Q5);
- small-body rule (codebook 0.6);
- single-subject test (codebook 0.5) plus any topic-scoped readings (equity R1) listed as **topic-scoped, not general**;
- higher-law duty vs own choice (library, police U1/S1, equity G4, homelessness);
- gating: consent and near-unanimous never seat; pooled T1 judged on ungated rows (Q6, 2026-10-19);
- census: companion bills count as two records; the identity check is mandatory;
- Stage 1 sampling: one row per board member; absent = no row, abstention = row; sponsors plus a seeded 2 Yea / 2 Nay
  draw per chamber; records only; cross-topic overlap allowed and flagged;
- "a blank spoke is correct"; a pause or keep vote with no rung is direction-only;
- revisions are applied without expert review, which is queued (§5.6).

When Chris rules something new that generalises, the skill proposes a line for this file in the same PR as the
revision. Topic-specific readings go in the topic's Season annex, not here.

## 7. The Monday.com board

Chris owns the topics; Monday is his tracker and the team's status view. **It uses the board the `/standup` skill
already uses** (Chris, 2026-10-20), so topic prep shows up beside his other work and in his sprints. A future artifact
may replace it.

- **Board:** the public **Backlog** board `18417210762`, group **Empowered Compass** `group_mm46qn8m`. Ids and API
  rules were taken from `~/.claude/skills/standup/SKILL.md` and `monday-map.json` and are copied into the skill's
  `config.json` (§9 item 6), so teammates without the standup skill can run it.
- **One Story per topic**, named `S3 topic prep — <topic_key>`, with Epic (`text_mm46npw7`) = `Season 3 topic prep`
  so the set can be filtered, Pillar = Inform, Owner = Chris. Status (`color_mm468pe2`) follows the board's existing
  labels (to do / working / blocked / done).
- **Stage, path, seat rate, blocker and next step** are written at the end of every stage as a **Monday update**
  (comment) on the Story, in a fixed short format, plus the research folder path. The latest update is the status.
- **Subitems stay the standup's day-slices.** The topic-prep skill never creates or edits subitems; `/standup` records
  the days Chris works on a topic as usual. Owed items (rulings, disputes, sources to fetch) are listed in the update,
  not as subitems.
- **Never write to the private My Sprints board** (`18426889128`); sprint planning stays with `/standup --plan`.
- **API traps that apply** (from the standup skill): `board_relation` writes replace the whole list; relation and
  mirror columns read as null without typed fragments. The topic-prep skill writes only Story fields and updates, so
  it does not touch relations.
- Seed Stories for the current topics: library books (done, revision applied), equity programs (done), school police
  (Stage 4 next), homelessness (Stage 3), school budget, curriculum, gender identity (parked).

## 8. Skill shape

- `SKILL.md`: purpose first (§1), when to use, the path decision, stage checklists, stop points for Chris, the
  Monday update at each stage end.
- `RULINGS.md` (§6), `STAGE4-RECIPE.md` (§5.5 with the SQL skeleton from CA_0314), `ADVERSARIAL-CHECK.md` (§5.6
  prompts), `SOURCE-STORE.md` (§5.7 schema), templates for BRIEFs (census, Stage 1 collection) taken from the equity
  and police briefs.
- Scripts the builder may add: seat-rate report (§5.8), gate pre-screen helpers, store read/write helpers.

## 9. Settled after the builder check (Claude's calls, check while reading)

1. **Where blank classes and gate verdicts live.** Stage 0a and Stage 0 write them per row to the research folder
   (`stage0a/rows.tsv`, `stage0/gates.tsv`, columns fixed by the skill). The seat-rate script reads counts from the
   database and, when given a research folder, joins these files for the class breakdown. **No migration in this
   project**; a database home for them belongs to project 2.
2. **How the Source path re-measures.** The skill collects and saves sources, then hands coding to the existing
   research-stances / coder pipeline with `--season draft` against the topic's current Season 3 pin. Starting a coding
   batch needs **one yes from Chris per batch**; rows then go through the existing review queue as today. The ban in §3
   is on writes without that yes, not on draft research itself. National-scale research is the same hand-off at a
   larger size.
3. **Topics already in progress.** Homelessness Stage 3 is the first real run of the adversarial check (§5.6) in place
   of T4. School police Stage 4 goes ahead on the CA_0314 recipe with no T4 gate. Both get seed Stories.
4. **Filling the source store from the pilots.** The plan includes a one-time import of what the pilots already hold
   in structured form (instruments, tallies and member votes, rosters, session lists, term starts, blocked portals).
   Free-text notes are not converted.
5. **Blind drafter and adversarial checker.** They run as **subagents** (no session relay). Blindness is checked, not
   trusted: after the drafter finishes, the orchestrator scans the subagent's transcript for any read of a forbidden
   path (Stage 1, census folders, side notes, shadow runs, named memory notes) and records the result in
   `stage2/blindness-check.txt`. Any hit voids the draft and it is redone.

6. **Who can run it** _(Chris, 2026-10-20: mainly Chris, but available to the team)_. So the skill carries no
   personal paths or ids in its logic:
   - **Settings file** `.claude/skills/season-topic-prep/config.json` (committed): Monday board, group and column ids
     (copied once from the standup map, not read from `~/.claude/skills/standup/` at run time), the research root, and
     the source-store path. The runner's own Monday user id and research root can be overridden by environment
     variables (`EV_MONDAY_USER_ID`, `EV_RESEARCH_ROOT`).
   - **Research folders** default to `~/Documents/GitHub/.planning/research/` and are created if missing. The pilot
     trails stay on Chris's machine; everything a run needs from them lives in `RULINGS.md`, `STAGE4-RECIPE.md` and
     the BRIEF templates.
   - **Source store is shared now:** its JSON files live in the repo at `backend/data/source-store/` (same layout as
     §5.7) and are committed with each stage's PR, like the coverage YAML. Large saved copies (PDFs, page captures)
     stay in the runner's research folder and are referenced by SHA-256. This replaces the local-only location in
     §5.7; project 2 later moves the store into the database.
   - **Database and slots** use the runner's own `backend/.env` and the steward allocator in their own namespace
     (`CA_` for Chris Andrews, `CC_` for Chris Cantrell; never inferred from a first name).
   - **No Monday access** → the skill prints the update it would have posted and carries on.

## 10. Decided vs left to the builder

**Decided (by Chris):** the skill should be usable by the team, though Chris will mostly run it; consistent process for every topic; audit and diagnose first; pre-stage research before a
season goes live; save sources for reuse; Monday.com for tracking now, on the standup skill's Backlog board; T4 replaced by the adversarial check with
disputes only, plus an expert queue; skill first, database library second.

**My calls (Claude), check while reading:** skill lives in the ev-accounts repo; one orchestrating session per topic
with subagents for the blind drafter and adversarial checker (§9 item 5); source-store JSON committed in the repo
(§9 item 6); the four blank classes; the path rule in §5.0; Stage details as Monday updates rather than new board columns or subitems.

**Left to the builder:** JSON schemas within §5.7's required fields; script names and locations; exact checklist
wording; how prompts for the drafter and checker are templated.
