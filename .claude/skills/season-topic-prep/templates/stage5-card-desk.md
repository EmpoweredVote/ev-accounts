# Desk card — {{TOPIC}}, {{STATE}} (`{{xx}}`)

Made {{DATE}} by `session_card.py` from `{{PROFILE}}`. **You are the desk.** The work of sessions A and B runs in
slim sessions that you start; you do very little, and that is the point. Every step you take re-reads this whole
session, so do not read the skill file, STAGE5.md, the runbook, the tools README, or the slim sessions' cards or
history. Read only what this card names.

- `S` = `{{S}}` · desk folder `D` = `{{DESK}}` · batch `B` = `{{S}}/write/{{xx}}-01`
- Tools run from `{{BACKEND}}` (its `.env` linked to the main checkout's; never print it).

## Your whole job

1. **Start a leg** in the background and wait for it to end:

```bash
python3 -I scripts/stage5/leg.py A --profile {{PROFILE}} --state {{xx}} --state-name "{{STATE}}"
```

2. **Read its last line** (the command prints it, and its exit code says the same):

| Exit | Last line | You do |
|---|---|---|
| 0 | `DONE A` or `DONE B` | Read `D/LOG-<leg>.md`. After A, start B (same command with `B`). After B, go to "After the run". |
| 10 | `STOP question <file>` | Show the runner that file's question, with its recommendation first. Send the answer back (below). |
| 11 | `STOP write <PREVIEW.md>` | Show the runner the preview. This is the write stop: see "The write". |
| 12 | `STOP blocked <why>` | Read the file it names. Fix what you can from here, or tell the runner plainly. Then resume. |
| 2 | no clear last line | Read `D/leg-<leg>.out.txt`. Resume with "End with one of the lines the rules list." |

3. **Send an answer back**: write the runner's words, exactly, to a file, and resume the same leg:

```bash
python3 -I scripts/stage5/leg.py A --profile {{PROFILE}} --state {{xx}} --state-name "{{STATE}}" --answer D/ANSWER-A-<n>.md
```

Never answer a question yourself, and never reword the runner's answer. A question about a bill or a rung is the
runner's. Ask with the options the question file gives.

## The write (only you do this, only on the runner's yes for this batch)

The slim session cannot write the database: its tools refuse. After `STOP write`:

1. Show `B/PREVIEW.md`. 🛑 Wait for the runner's yes **for this batch**.
2. On yes, from `{{BACKEND}}`:

```bash
zsh scripts/stage5/write-batch.sh {{S}} {{S}}/write/{{xx}}-01 {{TOPIC}} state:{{xx}} apply
```

   then the verifier and the read-back, with the exact commands `B/PREVIEW.md` lists under what it will run on yes.
   The counts must match the preview. Add them to the preview under "WRITTEN".
3. 🛑 A separate yes to approve. Then `approve-batch.ts` as the preview lists it, and the read-back again.
4. Resume leg B so it can finish: answer file "written and approved", or what the runner said instead.

## After the run

```bash
python3 -I scripts/stage5/close_state.py --profile {{PROFILE}} --state {{xx}} --batch {{xx}}-01 \
  $(python3 -I scripts/stage5/leg.py sessions --profile {{PROFILE}} --state {{xx}}) --session <this desk session's .jsonl>
```

Fill the rows `MEASURES.md` marks `__`. Tell the runner the result in plain English: what was written, what is
held, and every stop that was not a listed one. Open the pull request for the store files only when the runner
says so.

## Hard rules

- 🔴 The database is written only by you, only by the two commands above, each on the runner's own yes.
- Never name a political party. Report in plain English: result first, short sentences.
- Do not do a slim session's work for it. If a leg keeps failing on the same step, tell the runner.
