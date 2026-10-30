# Stage 5 — code everyone

Stage 5 runs after Stage 4 has pinned a revision into the draft season. It researches everyone the topic applies
to, once per season, saves what it finds by person and by subject, codes each person from those saved findings,
and reports how the rungs held. An early check stops the run if the rungs look wrong, while they can still be
fixed. The design and its reasons: `docs/superpowers/specs/2026-10-22-season-topic-prep-stage5-code-everyone-design.md`.
The rulings it rests on: [RULINGS.md](RULINGS.md) "Stage 5 rulings".

Output folder: `<research folder>/stage5/`. Every command takes absolute paths (SKILL.md "Running the CLIs").

## Hard rules

- 🔴 **No database write before the early check passes.** Findings and codes stay in the research folder and the
  source store until then, so a rung fix or a split leaves no draft-season rows to undo. After it passes, every
  batch is written on the runner's yes, one batch at a time.
- `--season draft` on every step. Stage 5 never researches or writes the open season.
- **Search each person once per topic per season.** Everyone on the roster gets an own-words search, including
  people a vote on file already places: a vote saves the record search, not the own-words search.
- **Searching and coding are separate passes.** The searcher saves what it finds and decides nothing; the coder
  reads only the saved findings.
- **Subagents.** Stage 5 runs searchers and coders as subagents, unlike research-stances STEP 1, because no one can
  research thousands of people inline. What keeps that safe: the searcher never codes, its files are validated
  on import, the coder reads only saved findings, every code passes `checkCode`, and every quote shown to voters is
  fetched again and checked by a separate agent (the quote check) before it can be stored.
- A local record (ordinance or resolution) may support a local official's own words; it never seats alone.
- No party names or colours anywhere. Never infer a stance from silence.

## Who is in scope, and the 2026 election

Sitting officials at every level the topic is asked at, and active candidates in upcoming races at those levels.
No one else. The general election is 2026-11-03:

- **Before the results:** research sitting officials who stay (seat not up, or running again) and every active
  candidate, so every winner is done when the results come in. Officials who are leaving (`leaving = yes`) get
  the pre-fill only, no open search.
- **After the results:** drop the losers (their candidacy is no longer live). Finish only the close races as they
  are called. Georgia and Louisiana runoffs stay active until December.
- `leaving = yes` only when the official's own seat has an upcoming race (before 2027) with live candidates on file
  and they are not one of them. `leaving = unknown` means the race data cannot say (no race on file for the seat,
  or no candidates loaded for it; 2026-10-22: Massachusetts has 200 state races on file and 4 candidates). Report
  the count; `unknown` gets the full search.

## Steps

### 1. Roster

```bash
npm run topic:stage5-roster --prefix backend -- --topic <key> --out <abs>/stage5/roster.tsv
```

It prints the counts per level, scope, leaving and state, and writes `roster.gaps.tsv` (active candidates with no
politician record, offices with no known level, levels the topic is not asked at). **Show the runner the counts
and the gaps before anything runs.**

### 2. Pre-fill from roll calls on file

Write `stage5/subjects.json`: each census instrument's subjects in plain words (`{ "IN-SB-483-2011": ["voter ID at
the polls"] }`), read from its title and operative text. Then:

```bash
npm run topic:stage5-prefill --prefix backend -- --topic <key> --research <abs topic folder> --subjects <abs>/stage5/subjects.json --dry-run
npm run topic:stage5-prefill --prefix backend -- --topic <key> --research <abs topic folder> --subjects <abs>/stage5/subjects.json
```

Members with no politician id land in `stage5/prefill/unmatched.json`. Match them with `npm run census:identity`
(official member lists, never surname alone), set the ids on the instruments, and run the pre-fill again; it adds
only what is new.

### 3. Search, one unit at a time

Order: **federal** as one batch; then **states one at a time**, the first two or three chosen to differ on the topic
(they are the early check); then the rest; then **local**; then candidates' remaining gaps.

```bash
npm run topic:stage5-find --prefix backend -- next --topic <key> --season draft --unit federal --size 20 --roster <abs>/stage5/roster.tsv --out <abs>/stage5/batches/federal-01.tsv
```

Brief one `source-collector` subagent per person with [templates/BRIEF-stage5-find.md](templates/BRIEF-stage5-find.md),
each writing `stage5/raw/find/<politician_id>.json`. Run them in parallel. Then import:

```bash
npm run topic:stage5-find --prefix backend -- import --topic <key> --season draft --dir <abs>/stage5/raw/find --roster <abs>/stage5/roster.tsv
```

A refused file names the person and the problem: fix the file or re-brief that person. **To resume after a stop,
import first, then run `next` again**: it lists only people with no search for this topic and season, so files
written but not imported would be listed again. Commit the store's
`findings/` with the stage PR (`npm run source-store --prefix backend -- validate` first).

### 4. Code

Run [templates/stage5-coder-prompt.md](templates/stage5-coder-prompt.md) on the most capable model, one subagent
per batch of about 20 people, writing `stage5/codes/<politician_id>.json`. The ladder text comes from
`npm run topic:ladder-lint --prefix backend -- --topic <key> --season draft`.

### 5. Early check (after federal and the first two or three states)

```bash
npm run topic:stage5-report --prefix backend -- --topic <key> --research <abs topic folder> --units federal,state:xx,state:yy --notes-out <abs>/stage5/notes.jsonl --out <abs>/stage5/early-check.md --early
```

Exit 3 means some codes failed their check: fix those first. Then run the theme pass,
[templates/stage5-theme-prompt.md](templates/stage5-theme-prompt.md), as a fresh subagent on `notes.jsonl`,
writing `stage5/themes.json`, and run the report again with `--themes <abs>/stage5/themes.json`.

**The bar (ruled 2026-10-22):** stop when "doesn't fit" is **more than 1 in 5** of the people with any on-topic
evidence, or when **any one theme holds more than 1 in 10** of them (exit 4). Doesn't-fit cases whose only record
is a No vote (`nay-only`) or a gated vote (`gate`) are reported apart and left out of both sides of both bars: no
rung change can seat them. A large unit may be checked on a **seeded sample** (record the seed and the draw before
drawing); the rest of the unit follows once the check passes. 🛑 Either way, show the runner the
split and the themes. On a stop, ask one question: fix the rungs first (back to Stage 2, or a split), or carry on.
Recommend one, with the cases that show why.

### 6. Full report

When every unit is coded, run the report without `--units` and without `--early`, to `stage5/report.md`, with a
fresh theme pass over all the notes. Add the plain recommendation: ship the rungs as they are, fix them (with the
cases), or split the topic. 📋 Monday step (SKILL.md), stage `5`.

### 7. Write and show (after the early check passes)

Once the early check passes, each batch goes through three steps: a quote check, a dry run, and a write after
the runner's yes. Voters see the result only when the draft season opens.

**First, once per topic, migration CA_0322.** It adds `inform.topic_research_outcomes` (the "we researched"
marker, kept apart from `value = 0`) and `inform.own_words_passages` (which can hold only a passage with a passed
quote check). 🛑 It needs two yeses from the runner: one for a `BEGIN … ROLLBACK` dry run, and one for the real apply.

**a. Quote check.** Run [templates/stage5-quote-check-prompt.md](templates/stage5-quote-check-prompt.md) as a
**separate** agent: never the searcher or the coder. Use one subagent per batch of about 20 findings. Check every
finding that a `doesnt-fit` code cites and that is own words or a local record. The agent fetches each page fresh
and appends one line per finding to `stage5/quote-checks.jsonl`. A passage **passes** only when:

- it is on the page word for word (only whitespace, quote marks and long dashes may differ);
- it is the person's own words (codebook V1);
- it is on the topic;
- a party is not its point (it does not call on voters to back or oppose a party);
- for a local record, the plain-words note voters see is a fair summary of the act.

A passage that only mentions a party passes with each party label bracketed out: the check writes `shown_text`, the
passage with each label replaced by a word from the fixed list ("[…]", "[some lawmakers]", "[some officials]",
"[some voters]", "[some states]", "[others]"). The exact words stay stored; voters see `shown_text`, with the source
link under it. The writer refuses a `shown_text` that changes anything but party labels (`bracketEditProblem`,
`backend/src/lib/partyLabels.ts`) or still has a label (RULINGS.md "Party labels never reach a reader").
Each check also records the sha256 of the exact text voters will see (`shown_text` when there is one), so text
edited later has no check.
Run the check again every time you write a batch. The newest check for a finding wins, and a check made before
the code was made never counts. Each line's `at` is an ISO timestamp with a time zone.

**b. Dry run.**

```bash
npm run topic:stage5-write --prefix backend -- --topic <key> --research <abs topic folder> --season draft --units federal,state:xx --csv-out <abs>/stage5/write/<batch>/research.csv
```

It reads the database only to find the draft season. It fetches each own-words passage's page again and keeps the
passage only when it is there word for word, whatever the quote check said. A page that is not HTML (a PDF) or will
not load keeps the quote check's word and is listed under **not re-checked on the page**. It prints:

- the outcome rows by type, and the passages it would store;
- **not in research.csv**: blanks whose detail fits no single codebook V6 reason. Add those rows by hand.
- **refused**: codes that fail `checkCode` (`code`), and passages kept off the page (`passage`): no passed check,
  text changed since its check, a party label left in what voters would see (or a `shown_text` that is not a
  clean bracket edit), or a local record with none of their own words beside it. The
  person's outcome row is still written for a refused passage.

It also writes `research.csv` for the seats and blanks. Run that file through the research-stances pipeline with
`--season draft`: `stance-gate.ts`, then the pre-write `audit-chair-evidence.mjs --csv`, then
`verify-stance-research.ts`. A seat placed on own words alone is `statement` evidence, so it keeps the
`statement-evidence` hold until the topic's blind check passes (step 8).

**c. Write.** 🛑 Show the runner the dry-run counts and the refused list. After their yes **for this batch**, run
the same command with `--apply` and without `--csv-out`. It writes the outcomes and passages in one transaction.
It refuses to run while any code is refused: fix those codes and dry-run again first, or an earlier write for
those people would stay live. Running it again for the
same people replaces their outcome and their passages. It refuses any season but the draft one.

**What voters see when the season opens.** The profile reads
`GET /api/compass/politicians/:id/research-states` (and the candidate route). It shows:

- **No stance found:** "We researched {name} and found no public stance on {topic}." and the research date.
- **Own words:** the checked passages under "In their own words — not a position on the scale", each with its
  source and date. A local record appears in plain words.
- **Seated:** the topic shows as today. A seat in the same or a newer season hides the research state.

### 8. Blind check for own-words seats (after coding, per topic)

A seat placed on own words alone keeps the `statement-evidence` hold until a blind check on that topic agrees with
the coder at the Stage 3 bar (RULINGS.md "Own-words seats: the hold ends after a blind check").

1. **Draw the sample.** List the topic's own-words-only seats: codes with outcome `seated` and
   `evidence_basis: own-words`. Hash a seed and record it in `stage5/blind-check/seed.txt` before you draw, as in
   Stage 1. Then draw at least 30, or every one if there are fewer. Record the drawn ids in the same file.
2. **Code blind.** Run separate blind validators: fresh subagents on the most capable model that never saw the
   codes. Each gets only:
   - the codebook;
   - the pinned ladder (`topic:ladder-lint --season draft`);
   - the topic's annex and RULINGS.md;
   - each sampled person's findings file.

   Use the coder prompt, with the person's code removed. Write `stage5/blind-check/<politician_id>.json`.
3. **Compare.** A case agrees when both give the same rung, or both leave it blank. Agreement is agreeing cases
   divided by sampled cases. Write `stage5/blind-check/result.md` with the count and every miss, each with both
   readings and the findings cited.
4. **Decide.** At **95% or more**, open one PR that releases the hold for this topic and updates CLAUDE.md's
   "separate reliability stratum" rule (ruling 2b). Below 95%, the hold stays. Report the misses to the runner and
   recommend what to fix: the coder prompt, the annex, or the rungs.

