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

- No database write in session A. Read-only queries only.
- Opus decides every judgment (core bills, name matches, the bill table). Sonnet reads bill text and nothing else.
- Never name a political party, anywhere. Never infer a stance from silence.
- Own worktree; commit with an explicit pathspec; scan staged changes for secrets first.
- One folder per state for anything a tool writes in bulk: `{{S}}/{{xx}}/…`. Never import from a folder that holds
  other states' files.
- A stop that is not listed below is a finding: write down what caused it.
- Report to the runner in plain English: result first, short sentences, terms defined.

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

**A2. Bills.**

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

**A3. Bill texts.** Fetch texts, then fill them with Sonnet agents as a `wave.py` wave (the newest
`FILL-BRIEF*.md` under `{{S}}/legiscan/` is the model). Check the fills' quotes, with a planted control. Write down
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

`check` must end at 0 problems; watch it catch a planted fault once. Settle each flag from the rulings already in
`{{S}}/coder-rulings.md` where you can. Write the rest as grouped questions, each with the people it affects, in
`{{S}}/{{xx}}/STOP1-QUESTIONS.md`. Detail: STAGE5 §3b.

**A5b. Before asking: probe the write.** Two checks that otherwise surface in session B:

1. Can our reader open this legislature's roll-call pages? Read each host's `robots.txt` and fetch one roll-call
   page. If not, put "where do we read roll calls" on the stop 1 sheet.
2. Does every core-bill vote of an in-scope person carry a chamber, a date and a tally? List any that does not.

**A6. Hand-over, then stop 1.** Write `{{S}}/{{xx}}/HANDOVER-A.md` (ten parts, below). 🛑 **Stop 1:** show the
questions and the stub list. On the answers: write each one word for word under `## {{STATE}} notes {state:{{xx}}}`
in `{{S}}/coder-rulings.md`, naming every person a ruling is about; add a `per_vote` entry to a bill-table row when
a ruling reads one vote differently from the row; run `check` again; add the answers to the hand-over. Commit the
store files by pathspec. Then close out:

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
7. Legislature quirks for the write: hosts, votes mode, session numbering, how texts mark changes, known gaps, and
   the result of the two probes in A5b.
8. Open items.
9. Checks passed.
10. Session B's card: `{{CARD_B}}`.
