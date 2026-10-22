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
evidence, or when **any one theme holds more than 1 in 10** of them (exit 4). 🛑 Either way, show the runner the
split and the themes. On a stop, ask one question: fix the rungs first (back to Stage 2, or a split), or carry on.
Recommend one, with the cases that show why.

### 6. Full report

When every unit is coded, run the report without `--units` and without `--early`, to `stage5/report.md`, with a
fresh theme pass over all the notes. Add the plain recommendation: ship the rungs as they are, fix them (with the
cases), or split the topic. 📋 Monday step (SKILL.md), stage `5`.

### 7. Write and show (after the early check passes)

Built separately (plan Phase B): the quote check, the two tables for research outcomes and shown passages, the
writer and the voter-facing rows. Seats and blanks still go through the research-stances pipeline with
`--season draft`, so the stance gate and the pre-write `audit-chair-evidence.mjs` check still run. Seats placed
on own words alone keep the `statement-evidence` hold until the topic's blind check passes (RULINGS.md "Own-words
seats: the hold ends after a blind check").
