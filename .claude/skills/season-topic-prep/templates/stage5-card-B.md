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
**B1. Record pass.**

{{#SCRIPT}}
```bash
npx tsx scripts/stage5/record-script.ts plan --config {{S}}/coder-config.json --rulings {{S}}/coder-rulings.md \
  --roster {{S}}/roster.tsv --ids {{S}}/batches/{{xx}}-ids.txt --unit state:{{xx}} --bill-table {{S}}/bill-table-{{xx}}.json \
  --sides {{SIDES}} --skip-rungs {{SKIP_RUNGS}} --name {{xx}}-rec --out {{S}}/record-briefs-{{xx}}
npx tsx scripts/stage5/coder-inputs.ts --config {{S}}/coder-config.json --rulings {{S}}/coder-rulings.md \
  --roster {{S}}/roster.tsv --ids {{S}}/record-briefs-{{xx}}/{{xx}}-rec-coder-ids.txt --unit state:{{xx}} --name {{xx}}-rec \
  --out {{S}}/record-briefs-{{xx}} --coded-dir {{S}}/record-coded --record-only --bill-table {{S}}/bill-table-{{xx}}.json
# wave (Opus), then split-codes.ts for each coded file into {{S}}/record-codes, then:
npx tsx scripts/stage5/record-script.ts adopt --out {{S}}/record-briefs-{{xx}} --name {{xx}}-rec --codes {{S}}/record-codes
```

The script codes the plain cases; Opus codes the rest and, blind, a standing check of the script's people.
🛑 `adopt` exit 4 = the check failed: no script code is released. Show the runner both codes (an unlisted stop) and
code every script person with Opus until the runner rules. Detail: README "Record pass by script".
{{/SCRIPT}}
{{^SCRIPT}}
The record pass by script is not approved for this topic. Opus codes everyone with a record:

```bash
npx tsx scripts/stage5/coder-inputs.ts --config {{S}}/coder-config.json --rulings {{S}}/coder-rulings.md \
  --roster {{S}}/roster.tsv --ids {{S}}/batches/{{xx}}-ids.txt --unit state:{{xx}} --name {{xx}}-rec \
  --out {{S}}/record-briefs-{{xx}} --coded-dir {{S}}/record-coded --record-only --bill-table {{S}}/bill-table-{{xx}}.json
# wave (Opus), then split-codes.ts for each coded file into {{S}}/record-codes
```
{{/SCRIPT}}

Keep `{{S}}/record-briefs-{{xx}}`: step B4 reads it.

**B2. Search list.**

```bash
python3 -I scripts/stage5/search_list.py plan --record-codes {{S}}/record-codes --roster {{S}}/batches/{{xx}}-roster.tsv \
  {{CONTROL_ARGS}} --out {{S}}/search-plan-{{xx}}
```

{{SEARCH_RULE}} `search.tsv` is the search target; write its count down.

**B3. Search and import.** One `source-collector` (Sonnet) per person in `search.tsv`, brief
`templates/BRIEF-stage5-find.md`, each writing `{{S}}/{{xx}}/find/<politician_id>.json`, in waves of at most 8.

```bash
npm run topic:stage5-find --prefix backend -- import --topic {{TOPIC}} --season draft --dir {{S}}/{{xx}}/find --roster {{S}}/roster.tsv
```

A refused file names the person and the problem: fix the file or brief that person again.

**B4. Re-code list.**

```bash
python3 -I scripts/stage5/search_list.py recode --record-codes {{S}}/record-codes --record-briefs {{S}}/record-briefs-{{xx}} \
  --out {{S}}/search-plan-{{xx}} --wave-dir {{S}}/waves/{{xx}}-search --codes {{S}}/codes --apply
```

`research-again-ids.txt`: search these once more (B3), import, run `recode` again. `recode-ids.txt`: only these are
coded again. Everyone else keeps the record-only code.

**B5. Second coding pass.** `coder-inputs.ts` as in B1 without `--record-only`, with
`--ids {{S}}/search-plan-{{xx}}/recode-ids.txt --name {{xx}}`, wave (Opus), then `split-codes.ts` into `{{S}}/codes`.

**B6. Adopt, and count what the search changed.**

```bash
python3 -I scripts/stage5/search_list.py adopt --record-codes {{S}}/record-codes --codes {{S}}/codes --out {{S}}/search-plan-{{xx}}
```

Exit 4 = a control person changed. `adopt` still adopts the groups that held and lists the failed group in
`reopened.tsv`: search and code those people (B3 to B5), run `adopt` again, and report it.
{{/SKIP}}
{{^SKIP}}
**B1 to B6. Search everyone, then code once.** No skip rule is approved for this topic, so every person in
`{{S}}/batches/{{xx}}-ids.txt` is searched and then coded once by Opus. Follow STAGE5 §3 ("Search, one unit at a
time") and §4 ("Code") as written, with two changes: searchers write to `{{S}}/{{xx}}/find/` and the import reads
only that folder; and every wave runs through `wave.py`. Do **not** use `search_list.py plan`: its skip rule needs
its own measurement and the runner's ruling for this topic (STAGE5 "Pilot rule").
{{/SKIP}}

**B7. Bills the searchers named.** List bill ids in the new findings that have no stored bill. Fill those on the
question; re-code only the people they touch.

**B8. Early check.**

```bash
npm run topic:stage5-report --prefix backend -- --topic {{TOPIC}} --research {{R}} --units state:{{xx}} \
  --notes-out {{S}}/{{xx}}/notes-{{xx}}.jsonl --out {{S}}/early-check-{{xx}}1.md --early
npm run topic:stage5-theme-prompt --prefix backend -- --topic {{TOPIC}} --season draft --notes {{S}}/{{xx}}/notes-{{xx}}.jsonl --out {{S}}/{{xx}}/theme-prompt.md
```

Theme pass as one Opus agent; run the report again with `--themes`. Exit 3: fix the failed codes first.
🛑 **Stop 2 only on exit 4** (doesn't fit over 1 in 5, or one theme over 1 in 10): show the split and the themes,
ask one question, recommend one answer. Detail: STAGE5 §5.

**B9. Write recipe.** Write `B/recipe.json`. Only the three `<…>` values need the hand-over's part 7
(`legiscan_args` is optional: leave the line out when the hand-over names none):

```json
{"stage5": "{{S}}", "topic": "{{TOPIC}}", "unit": "state:{{xx}}", "level": "state", "state": "{{XX}}",
 "roster": "{{S}}/roster.tsv", "codes": "{{S}}/codes", "saved_root": "{{SAVED_ROOT}}",
 "votes": "<votes mode>", "official_host": "<official hosts>", "max_urls": 20,
 "legiscan_args": "<extra flags>"}
```

```bash
python3 -I scripts/stage5/run_recipe.py {{S}}/write/{{xx}}-01
```

It stops for the quote check (one Opus wave, `templates/stage5-quote-check-prompt.md`), for a gate above 0 high,
and for held people. After a tool fix, replay steps 7 to 9 with `--replay`, never by hand. Roll-call cross-checks
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
