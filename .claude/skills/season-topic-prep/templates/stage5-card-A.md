# Session A card — {{TOPIC}}, {{STATE}} (`{{xx}}`) — set-up

Made {{DATE}} by `session_card.py` from `{{PROFILE}}`. **This card is the session's reading.** Do not read the skill
file, STAGE5.md, the runbook or the tools README from end to end: open only the section a step names.

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
- Report in plain English, result first.

## This legislature

{{#LEG}}
From `{{LEG_PATH}}` (facts about the legislature, shared by every topic):

{{LEG_SUMMARY}}
{{/LEG}}
{{^LEG}}
No legislature profile is on file for `{{xx}}` yet, so this session learns its hosts, vote layout and text marks
by hand and writes them down at hand-over (step A6).
{{/LEG}}

## Settled, do not ask again

{{SETTLED}}

## Runner stops in this session

| # | When | The runner decides |
|---|---|---|
| 0 | At the start | One standing yes for the state: set up, search, add sponsored bills, code, prepare the preview. |
| 1 | After the bill table | Every flagged bill and both-sides pattern, and the stub list. |

**Never wait for stop 1 inside this session.** Write the question sheet and the hand-over first (step A6), ask, and
apply the answers as the last act.

## Steps

**A0. Start.** Note the UTC start time. Take the lease:

```bash
npm run steward --prefix backend -- claim state:{{xx}} --label "{{LABEL}} {{STATE}}"
```

**A1 to A5 are one tool.** It runs the set-up in order and stops only where you are needed, with the reason and the
`--from` to resume with. Its header lists the eight steps; each one's full output is in `{{S}}/{{xx}}/setup/step-<n>.log`.
🔴 Never copy another state's script, prompt or brief by hand for a step it runs: that is how a copy kept another
state's words. Run it in the foreground, again after each stop:

```bash
python3 -I scripts/stage5/run_setup.py --profile {{PROFILE}} --state {{xx}} [--from N] [--seats <lower>,<upper>]
```

What stays yours, at its stops (exit 10: work for you; exit 4: the runner's material is ready; exit 2: a fault, or
a check that proved blind):

- **1 roster.** Read the lines the step names: check every `NAME-MATCH` by hand, and each close race and each
  sitting person dropped. A row the rules miss goes in `{{S}}/{{xx}}/scope-hints.json` (keys in `results_scope.py`'s
  header), with who decided and when; then `--from 1`. Leg B copies this roster over the shared one: never edit
  `roster.tsv` by hand. Detail: STAGE5 §1.
- **2 scan.** Pick the core set from contested floor votes by hand (`{{S}}/legiscan/core-bills-{{xx}}.json`). Detail:
  STAGE5 §3a.
- **3 link.** 🔴 A legislator with no `idmap.tsv` line has **no votes on file**, and nothing else says so. Add each
  line the step names by hand, on name **and chamber**; refuse a match from another state, and a namesake's record
  with `<people_id>\t-\t# refused: <why>`. A member seated after the newest dataset goes in
  `{{S}}/{{xx}}/no-legiscan-record.tsv` (`<politician_id>\t<reason>`), and on the stop 1 sheet.
- **4 sponsors.** Read the "re-file trim" line. A note for the triage agent about this state's titles goes in
  `{{S}}/{{xx}}/triage-note.md` before the step. Stubs go to stop 1.
- **5 texts.** The state's own text fetch, `{{S}}/legiscan/scripts/fetch_texts_{{xx}}.py`: write it if there is none
  (which version to read, and how new and struck words are marked, are this legislature's). Note both for the hand-over.
- **6 fill.** `{{S}}/legiscan/FILL-BRIEF-{{xx}}.md`, in this legislature's own words. On a miss, fix the fetch or the
  fill, never the check. The step plants one changed number itself and stops if the check passes it.
- **7 store.** 🔴 **A core bill with no readable text is settled here, not in session B** (Colorado: 66 people coded
  again). Where `robots.txt` allows the bill's page, save the legislature's own summary and merge it as
  `bill_merge.py`'s header says; `check` then wants its row flagged, and stop 1 asks if summaries may stand.
  After the pre-fill, every person it reports with no vote must be a non-legislator or in the no-record file.
- **8 table.** A state's note on how its texts mark changes goes in `{{S}}/{{xx}}/billtable-note.md` before the step.
  `check` must end at 0 problems. Then:

**A5. Flags and questions.** `{{S}}/bill-questions-{{xx}}.md` lists every flagged bill, every both-sides person, and
bills older than the data on disk. 🔴 **Each of those goes on the stop 1 sheet with its people** (hold them, drop
the rung, or build a path): a page the reader opens is not a vote the recipe can place (Oregon: 9 people held at
step 7). Settle each flag the rulings in `{{S}}/coder-rulings.md` settle. Write the rest as grouped questions, each
with the people it affects, in `{{S}}/{{xx}}/STOP1-QUESTIONS.md`. Detail: STAGE5 §3b.

🔴 **A flag is an open question: any text in it keeps that bill's people out of the record script.** Close each
one with `settle` (now for flags the rulings settle, after stop 1 for the rest); never write an answer into `flag`.
Then `check` must print `0 flagged`:

```bash
python3 -I scripts/stage5/bill_table.py settle {{S}}/bill-table-{{xx}}.json <bill id>...|--all --answer "<the ruling, or the runner's words>"
python3 -I scripts/stage5/bill_table.py check {{S}}/bill-table-{{xx}}.json --ids {{S}}/batches/{{xx}}-ids.txt
```

**A5b. Before asking: probe the write.** Two checks that otherwise surface in session B:

1. Can our reader open this legislature's roll-call pages? Read each host's `robots.txt` and fetch one roll-call
   page. If not, put "where do we read roll calls" on the stop 1 sheet. (A host the profile marks
   "blocked" needs no probe.)
2. Does every core-bill vote of an in-scope person carry a chamber, a date and a tally? List any without.

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
