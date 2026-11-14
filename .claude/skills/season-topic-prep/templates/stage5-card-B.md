# Session B card — {{TOPIC}}, {{STATE}} (`{{xx}}`) — run

Made {{DATE}} by `session_card.py` from `{{PROFILE}}`. **This card and `{{S}}/{{xx}}/HANDOVER-A.md` are the
session's reading.** Do not read the skill file, STAGE5.md, the runbook or the tools README from end to end, and do
not read session A's history: open only the section a step names.

- `R` = `{{R}}`
- `S` = `{{S}}`
- `B` = `{{S}}/write/{{xx}}-01` (the batch)
- Tools run from `{{BACKEND}}` (its `.env` linked to the main checkout's; never print it).
- Full text when a step says so: `{{SKILL}}/STAGE5.md` ("STAGE5 §n") and
  `{{BACKEND}}/scripts/stage5/README.md` ("README").
- Every wave runs through `wave.py`: `python3 -I scripts/stage5/wave.py <jobs.tsv> --out {{S}}/waves/{{xx}}-<name> --add-dir {{R}} --add-dir {{WT}}`.

## Hard rules

- 🔴 The only database writes are the batch write (stop 3) and the approval (stop 4), each on the runner's own yes
  for this batch. `--season draft` on every step. No migration.
- 🔴 Opus is the coder for every judgment. Searchers save what they find and decide nothing. A coder reads only
  saved findings.
- 🔴 Never show a coder its first code, the script's code, or which people are a check or a control.
- 🔴 A code that fails a check is never fixed by hand: it goes back to a coder.
- Never name a political party. Never infer a stance from silence. A local record never seats alone.
- Import search files only from this state's own folder, `{{S}}/{{xx}}/find`. Never from a shared one.
- Anything already written for a person stays, even if they later lose.
- A stop that is not listed below is a finding: write down what caused it.
- Report to the runner in plain English: result first, short sentences, terms defined.

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
| 2 | After the early check, only if it finds a problem | Fix the rungs first, or carry on. |
| 3 | After `PREVIEW.md` | Write, for this batch. |
| 4 | After the write and read-back | Approve. |

## Steps

**B0. Start.** Note the UTC start time. Read the hand-over. Re-take the lease if it lapsed.

{{#SKIP}}
**B1 to B8 in one command.** Run it in the background; it wakes you only at a stop.

```bash
python3 -I scripts/stage5/run_state.py --profile {{PROFILE}} --state {{xx}}
```

| Step | Does |
|---|---|
| 1 record | {{#SCRIPT}}The script codes the plain cases (`--sides {{SIDES}} --skip-rungs {{SKIP_RUNGS}}`); Opus codes the rest and, blind, a standing check of the script's people.{{/SCRIPT}}{{^SCRIPT}}Opus codes everyone with a record (the record pass by script is not approved for this topic).{{/SCRIPT}} |
| 2 plan | `search_list.py plan {{CONTROL_ARGS}}`. {{SEARCH_RULE}} |
| 3 search | One Sonnet searcher per person in `search.tsv`, each writing `{{S}}/{{xx}}/find/<id>.json`; then the import, from that folder only. |
| 4 recode | Only people with a new finding are coded again. A search that read none of the person's own pages is run once more. |
| 5 code | Second coding pass (Opus), blind. |
| 6 adopt | Checks each control apart, adopts the skipped codes, counts what the search changed. |
| 7 check | Early check report, theme pass, report again. |

Every search brief carries the state's search note: the legislature profile's, unless you write a different one
for this run to `{{S}}/{{xx}}/search-note.md` (for example "sponsorships and floor votes come from the bulk bill
data: skip the legislature's own lists").

When it stops, it prints why and the `--from N` to resume with. Read `{{S}}/{{xx}}/run/step-N.log`.

- **Exit 4 at step 1:** the standing check failed. No script code was released. 🛑 Show the runner both codes
  (an unlisted stop). Until the runner rules, Opus codes every script person.
- **Exit 10, codes sent back:** code those people again with one command, then resume. Never fix a code by hand,
  and never write a send-back prompt by hand: the round builds a brief that holds only those people.

```bash
python3 -I scripts/stage5/run_state.py --profile {{PROFILE}} --state {{xx}} --round sb1
```

  A new name for each round (`sb2`, …). After a ruling, code the people it touches the same way:
  `--round r2 --ids <file of ids> --why <file: one or two sentences>`. Old codes are kept in
  `{{S}}/{{xx}}/codes-before-<name>/`.
- **Exit 10, search files refused:** fix each file or brief that person again, import the folder again, resume.
- **Exit 4 at step 6:** a control person changed. `reopened.tsv` lists the group to search and code after all.
  Report it.
- **Exit 4 at step 7:** 🛑 **stop 2.** Doesn't fit is over 1 in 5, or one theme is over 1 in 10. Show the split and
  the themes, ask one question, recommend one answer. Detail: STAGE5 §5.
- **Exit 2:** a command failed. Fix the cause; do not work around the step by hand.

Each step's own commands, if you must run one alone: `run_state.py … --print`. Write down the search target (the
count of `search.tsv`) and each stop that is not on the list above.
{{/SKIP}}
{{^SKIP}}
**B1 to B6. Search everyone, then code once.** No skip rule is approved for this topic, so every person in
`{{S}}/batches/{{xx}}-ids.txt` is searched and then coded once by Opus. Follow STAGE5 §3 ("Search, one unit at a
time") and §4 ("Code") as written, with two changes: searchers write to `{{S}}/{{xx}}/find/` and the import reads
only that folder; and every wave runs through `wave.py`. Do **not** use `search_list.py plan`: its skip rule needs
its own measurement and the runner's ruling for this topic (STAGE5 "Pilot rule").
{{/SKIP}}

**B7. Bills the searchers named.** List bill ids in the new findings that have no stored bill. Fill those on the
question; re-code only the people they touch (`run_state.py … --round <name> --ids <file>`).

**B8. Early check.**

```bash
npm run topic:stage5-report --prefix backend -- --topic {{TOPIC}} --research {{R}} --units state:{{xx}} \
  --notes-out {{S}}/{{xx}}/notes-{{xx}}.jsonl --out {{S}}/early-check-{{xx}}1.md --early
npm run topic:stage5-theme-prompt --prefix backend -- --topic {{TOPIC}} --season draft --notes {{S}}/{{xx}}/notes-{{xx}}.jsonl --out {{S}}/{{xx}}/theme-prompt.md
```

Theme pass as one Opus agent; run the report again with `--themes`. Exit 3: fix the failed codes first.
🛑 **Stop 2 only on exit 4** (doesn't fit over 1 in 5, or one theme over 1 in 10): show the split and the themes,
ask one question, recommend one answer. Detail: STAGE5 §5.

{{#LEG}}
**B9. Write recipe.** Write `B/recipe.json` exactly as below (the votes mode and hosts come from the legislature
profile; change one only if the hand-over's part 7 says it changed):

```json
{"stage5": "{{S}}", "topic": "{{TOPIC}}", "unit": "state:{{xx}}", "level": "state", "state": "{{XX}}",
 "roster": "{{S}}/roster.tsv", "codes": "{{S}}/codes", "saved_root": "{{SAVED_ROOT}}",
 "votes": "{{RECIPE_VOTES}}", "official_host": "{{RECIPE_HOSTS}}", "max_urls": 20{{RECIPE_LEGISCAN}}}
```
{{/LEG}}
{{^LEG}}
**B9. Write recipe.** Write `B/recipe.json`. Only the three `<…>` values need the hand-over's part 7
(`legiscan_args` is optional: leave the line out when the hand-over names none):

```json
{"stage5": "{{S}}", "topic": "{{TOPIC}}", "unit": "state:{{xx}}", "level": "state", "state": "{{XX}}",
 "roster": "{{S}}/roster.tsv", "codes": "{{S}}/codes", "saved_root": "{{SAVED_ROOT}}",
 "votes": "<votes mode>", "official_host": "<official hosts>", "max_urls": 20,
 "legiscan_args": "<extra flags>"}
```
{{/LEG}}

```bash
python3 -I scripts/stage5/run_recipe.py {{S}}/write/{{xx}}-01
```

It stops for the quote check, for a gate above 0 high, and for held people. The quote check is three commands:

```bash
python3 -I scripts/stage5/stage5_prompts.py quote-check --profile {{PROFILE}} --batch {{S}}/write/{{xx}}-01 --dry-run {{S}}/write/{{xx}}-01/dry-run-0.txt
python3 -I scripts/stage5/wave.py {{S}}/write/{{xx}}-01/qc/jobs.tsv --out {{S}}/waves/{{xx}}-qc --add-dir {{R}} --add-dir {{WT}}
npx tsx scripts/stage5/quote-check-validate.ts {{S}}/write/{{xx}}-01 {{S}}
```

Then resume the recipe with `--from 2`. After a tool fix, replay steps 7 to 9 with `--replay`, never by hand. Roll-call cross-checks
must show 0 disagree; a vote that cannot be placed holds its person, it is never guessed. Count each gate run and
each hand fix. Detail: STAGE5 §7 "The recipe, in order".

**B10. Preview.** Write `B/PREVIEW.md` (STAGE5 §7 step 13). 🛑 **Stop 3.**

**B11. Write, read back, approve.** On yes: `write-batch.sh {{S}} {{S}}/write/{{xx}}-01 {{TOPIC}} state:{{xx}} apply`,
the verifier with `--apply`, `readback.ts`. Counts must match the preview. 🛑 **Stop 4**, then `approve-batch.ts`
and read back again. Skip own-words seats at approval unless this topic's blind check has passed
(STAGE5 §8). Detail: STAGE5 §7 steps 14 and 15.

**B12. Close out, as the session's last act.**

```bash
python3 -I scripts/stage5/close_state.py --profile {{PROFILE}} --state {{xx}} \
  --session <session A .jsonl> --session <this session's .jsonl> --batch {{xx}}-01
```

It writes the usage file, the search effect, `{{S}}/{{xx}}/MEASURES.md` and a hand-over skeleton. Fill the rows it
marks `__` (gate runs, runner stops and their causes), commit the findings by pathspec, and end the session. Open
the PR from a fresh, small session.
