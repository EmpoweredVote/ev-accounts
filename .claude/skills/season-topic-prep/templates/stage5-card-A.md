# Session A card — {{TOPIC}}, {{STATE}} (`{{xx}}`) — set-up

Made {{DATE}} by `session_card.py` from `{{PROFILE}}`. **This card is the session's reading.** Do not read the skill
file, STAGE5.md, the runbook or the tools README from end to end: open only the section a step names. Each of those
reads is carried on every later step of the session.

- `R` = `{{R}}`
- `S` = `{{S}}`
- `L` = `{{S}}/legiscan`
- Tools run from `{{BACKEND}}` (its `.env` linked to the main checkout's; never print it).
- Full text when a step says so: `{{SKILL}}/STAGE5.md` (cited as "STAGE5 §n") and
  `{{BACKEND}}/scripts/stage5/README.md` ("README").
- Templates: `{{SKILL}}/templates/`.
- This session ends with `{{S}}/{{xx}}/HANDOVER-A.md` and the runner's answers at stop 1. Session B is a separate
  fresh session; its card is `{{CARD_B}}`.

## Hard rules

- No database write in session A: read-only queries.
- Opus decides every judgment (core bills, name matches, the bill table). Sonnet only reads bill text.
- Never name a political party. Never infer a stance from silence.
- Own worktree; scan staged changes for secrets; commit by `--pathspec-from-file`; confirm with `git log -1 --stat`.
- One folder per state for anything a tool writes in bulk: `{{S}}/{{xx}}/…`. Never import from a folder that holds
  other states' files.
- A stop that is not listed below is a finding: write down what caused it.
- Report in plain English: result first, short sentences.

## This legislature

{{#LEG}}
From `{{LEG_PATH}}` (facts about the legislature, shared by every topic):

{{LEG_SUMMARY}}
{{/LEG}}
{{^LEG}}
No legislature profile is on file for `{{xx}}` yet, so this session learns its hosts, vote layout and text marks
by hand. Session A writes them down at hand-over (`legislature.py new {{xx}} --name "{{STATE}}"`).
{{/LEG}}

## Settled, do not ask again

{{SETTLED}}

## Runner stops in this session

| # | When | The runner decides |
|---|---|---|
| 0 | At the start | One standing yes for the state: set up, search, add sponsored bills, code, prepare the preview. |
| 1 | After the bill table | Every flagged bill and both-sides pattern, and the stub list. |

**Never wait for stop 1 inside this session.** Write the question sheet and the hand-over first (step A6), ask, and
apply the answers as the last act. A long wait in a large session is charged in full when it ends.

## Steps

**A0. Start.** Note the UTC start time. Take the lease:

```bash
npm run steward --prefix backend -- claim state:{{xx}} --label "{{LABEL}} {{STATE}}"
```

**A1. Results check and roster.** Drop people who lost or are leaving; keep close races apart; check each new
winner's level against the race's district type. Rebuild the roster with `topic:stage5-roster` so it has the
`office` column (a blank office blocks the record pass). Save `{{S}}/batches/{{xx}}-ids.txt` and a scoped roster
`{{S}}/batches/{{xx}}-roster.tsv` (only this state's in-scope rows). Worked example: the newest
`results_scope_*.py` under `{{S}}/*/scripts/`. Detail: STAGE5 §1.
Leg B copies this roster over the shared one (`roster_sync.py`): never edit `roster.tsv` by hand.

**A2. Bills.**

Open States data: run `openstates/coverage.py <extract dir>` first; exit 1 names sessions with no roll calls.

```bash
python3 -I scripts/stage5/scan_bills.py {{S}}/legiscan/ds {{XX}} {{S}}/legiscan/bills-{{xx}}.json --topic {{TOPIC}}
```

Pick the core set from contested floor votes by hand (`core-bills-{{xx}}.json`). Then sponsor cover with the scoped
roster, so names match inside this state only:

```bash
python3 -I scripts/stage5/sponsor_cover.py {{S}}/legiscan/bills-{{xx}}.json --state {{XX}} --roster {{S}}/batches/{{xx}}-roster.tsv \
  --core {{S}}/legiscan/core-bills-{{xx}}.json --ds {{S}}/legiscan/ds --idmap {{S}}/legiscan/idmap.tsv --since {{SINCE}} \
  --candidates {{S}}/sponsor-candidates-{{xx}}.json
```

Title triage: one Opus agent, `templates/stage5-sponsor-triage-prompt.md` (fill its ladder slots from the coder
config), as a one-row `wave.py` wave, into `{{S}}/sponsor-triage-{{xx}}.json`. Then the same `sponsor_cover.py`
command with `--triage {{S}}/sponsor-triage-{{xx}}.json --write {{S}}/legiscan/core-bills-{{xx}}.json`. Read its
"re-file trim" line. Stubs go to `core-bills-{{xx}}.stubs.json` for stop 1. Detail: STAGE5 §3a.

Check every `idmap.tsv` line you add against the person's name **and chamber**. Refuse a match from another state.

🔴 Then the link check, before any skeleton or vote is built. A legislator with no `idmap.tsv` line has **no votes on
file**, and nothing else says so (Kentucky: six members, two written as blanks that their record would have seated):

```bash
python3 -I scripts/stage5/link_check.py --state {{XX}} --roster {{S}}/batches/{{xx}}-roster.tsv --ds {{S}}/legiscan/ds --idmap {{S}}/legiscan/idmap.tsv --add
```

Exit 1 names each unlinked member beside the people who may be the same person. Add the line by hand, run it
again, and go on only at exit 0. A member seated after the newest dataset
goes in `--no-record {{S}}/{{xx}}/no-legiscan-record.tsv` (`<politician_id>\t<reason>`); list those people on the
stop 1 sheet. After A4, every person the pre-fill reports with no vote must be a non-legislator or in that file.

**A3. Bill texts.** Shared scripts, never a copy of another state's (usage in each header): `bill_skeletons.py`,
the state's own text fetch, `bill_fill_wave.py` (a `wave.py` wave; the newest `FILL-BRIEF*.md` is the model), then
`bill_merge.py`. Check the fills' quotes, and watch a planted wrong quote fail once:

```bash
python3 -I scripts/stage5/check_fill_quotes.py --fills {{S}}/legiscan/fill --texts {{S}}/legiscan/texts --state {{xx}} --flag <the fill brief's on-topic key>
```
 Write down
for the hand-over how this legislature marks new and struck words, how its roll calls name motions, and its hosts.

**A4. Store and pre-fill.** Merge into the store; `npm run source-store --prefix backend -- validate`; then

```bash
npm run topic:stage5-prefill --prefix backend -- --topic {{TOPIC}} --research {{R}} --subjects {{S}}/subjects.json --units state:{{xx}}
```

**A5. Bill table.** Build the prompts (the bills are the ids the fill merge kept, as a JSON list or one per line; a
state's own note on how its texts mark changes goes in `--note-file`), run them as an Opus wave, then join the parts:

```bash
python3 -I scripts/stage5/stage5_prompts.py bill-table --profile {{PROFILE}} --state {{xx}} --state-name "{{STATE}}" --bills <ids file> --parts 3
python3 -I scripts/stage5/wave.py {{S}}/waves/{{xx}}-billtable/jobs.tsv --out {{S}}/waves/{{xx}}-billtable/out --add-dir {{R}} --add-dir {{WT}}
```

Then:

```bash
python3 -I scripts/stage5/bill_table.py check {{S}}/bill-table-{{xx}}.json --ids {{S}}/batches/{{xx}}-ids.txt
python3 -I scripts/stage5/bill_table.py questions {{S}}/bill-table-{{xx}}.json --ids {{S}}/batches/{{xx}}-ids.txt --out {{S}}/bill-questions-{{xx}}.md
```

`check` must end at 0 problems; watch it catch a planted fault once. `questions` also lists bills older than the
data on disk: do its check. Settle each flag from the rulings already in
`{{S}}/coder-rulings.md` where you can. Write the rest as grouped questions, each with the people it affects, in
`{{S}}/{{xx}}/STOP1-QUESTIONS.md`. Detail: STAGE5 §3b.

🔴 **A flag is an open question: any text in it keeps that bill's people out of the record script.** Close each
one with `settle` (now for flags the rulings settle, after stop 1 for the rest); never write an answer into `flag`.
Then `check` must print `0 flagged`:

```bash
python3 -I scripts/stage5/bill_table.py settle {{S}}/bill-table-{{xx}}.json <bill id>...|--all --answer "<the ruling, or the runner's words>"
```

**A5b. Before asking: probe the write.** Two checks that otherwise surface in session B:

1. Can our reader open this legislature's roll-call pages? Read each host's `robots.txt` and fetch one roll-call
   page. If not, put "where do we read roll calls" on the stop 1 sheet. (A host the profile above already marks
   "blocked" needs no probe; one marked "not checked", or a profile verified long ago, does.)
2. Does every core-bill vote of an in-scope person carry a chamber, a date and a tally? List any that does not.

**A6. Hand-over, then stop 1.** Write `{{S}}/{{xx}}/HANDOVER-A.md` (ten parts, below). 🛑 **Stop 1:** show the
questions and the stub list. On the answers: write each one word for word under `## {{STATE}} notes {state:{{xx}}}`
in `{{S}}/coder-rulings.md`, naming every person a ruling is about; add a `per_vote` entry with `votes` (date, chamber, rung of each) to a bill-table
row when a ruling reads a vote differently; run `check` again; add the answers to the hand-over. Then write down what this session learned about the legislature, for
every later topic: edit `{{LEG_PATH}}` (or start it with `python3 -I scripts/stage5/legislature.py new {{xx}} --name "{{STATE}}"`),
set `verified` to today, and run `python3 -I scripts/stage5/legislature.py check {{xx}}`. Facts about the legislature
only: no topic, no rung, no person. Commit it with the store files, by pathspec. Then close out:

```bash
python3 -I scripts/stage5/close_state.py --profile {{PROFILE}} --state {{xx}} --session <this session's .jsonl> --leg A
```

## HANDOVER-A.md — ten parts, one page

1. Header: state, topic, season id, revision id, codebook; start and end (UTC); lease and expiry; worktree, branch,
   commits.
2. Usage: this session's transcript path and every wave folder it ran.
3. Roster: counts by scope, people leaving, close races, the two files of step A1.
4. Bills, with counts: scanned, core, sponsor candidates, triage fill / stub / skip, re-file trim, final core,
   texts filled and missing.
5. Name fixes: each `idmap.tsv` line added, and each match refused.
6. Bill table: path, `check` result, flagged, settled by earlier rulings, the runner's answers word for word with
   the date, every `per_vote` entry, the stub list and the answer to it.
7. Legislature quirks: "see `{{LEG_PATH}}`", plus only what is new or changed since it was verified, and the result
   of the two probes in A5b.
8. Open items.
9. Checks passed.
10. Session B's card: `{{CARD_B}}`.
