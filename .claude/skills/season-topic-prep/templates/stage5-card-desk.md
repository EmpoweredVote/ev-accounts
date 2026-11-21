# Desk card — {{TOPIC}}, {{STATE}} (`{{xx}}`)

Made {{DATE}} by `session_card.py` from `{{PROFILE}}`. **You are the desk.** The work of sessions A and B runs in
slim sessions that you start; you do very little, and that is the point. Every step you take re-reads this whole
session, so do not read the skill file, STAGE5.md, the runbook, the tools README, or the slim sessions' cards or
history. Read only what this card names.

🔴 **Be a fresh session.** If this session has done other work, ask the runner to start a new one with this card.

- `S` = `{{S}}` · desk folder `D` = `{{DESK}}` · batch `B` = `{{S}}/write/{{xx}}-01`
- Tools run from `{{BACKEND}}` (its `.env` linked to the main checkout's; never print it).

## Your whole job

Every step you take re-reads this whole session. One command per step, as written here.

1. **Start a leg** in the background and wait for it to end:

```bash
python3 -I scripts/stage5/leg.py A --profile {{PROFILE}} --state {{xx}} --state-name "{{STATE}}"
```

   A leg may run as several slim sessions in a row: one that grows large hands over to a fresh one by itself.
   You still get one last line.

2. **Read what it printed.** The last line says what happened, and its exit code says the same. On a question or
   the write stop, the question file or the preview is printed above that line: do not open it again.

| Exit | Last line | You do |
|---|---|---|
| 0 | `DONE A` or `DONE B` | After A, start B (same command with `B`). After B, go to "After the run". |
| 10 | `STOP question <file>` | Ask the runner the question printed above, with its options, its recommendation first. Send the answer back (below). |
| 11 | `STOP write <PREVIEW.md>` | Show the runner the preview printed above. This is the write stop: see "The write". |
| 12 | `STOP blocked <why>` | Read the file it names. Fix what you can from here, or tell the runner plainly. Then resume. |
| 2 | no clear last line | Read `D/leg-<leg>.out.txt`. Resume with `--say "End with one of the lines the rules list."` |

3. **Send the answer back**, in the background, in one command. `--say` files the runner's words as the next
   `D/ANSWER-<leg>-<n>.md`, exactly as you pass them, and resumes the same leg:

```bash
python3 -I scripts/stage5/leg.py A --profile {{PROFILE}} --state {{xx}} --state-name "{{STATE}}" --say "<the runner's words, exactly>"
```

Never answer a question yourself, and never reword the runner's answer. A question about a bill or a rung is the
runner's. Ask with the options the question file gives.

## The write (only you do this, only on the runner's yes for this batch)

The slim session cannot write the database: its tools refuse. After `STOP write`, one command does the write, the
verifier, the read-back and the check of the read-back against what was written, and adds "WRITTEN" to the preview
(it runs `write-batch.sh` and the rest; do not run them by hand):

```bash
python3 -I scripts/stage5/desk.py write --profile {{PROFILE}} --state {{xx}} --yes "<the runner's words>"
```

1. Show the preview. 🛑 Wait for the runner's yes **for this batch**. Then run the command with their words.
2. Exit 0: written, and the read-back matches. Exit 4: a condition does not hold; show the runner its lines. Exit 2:
   a command failed; tell the runner what it printed, and do not run the write again.
3. 🛑 A separate yes to approve. Then the same command with only `--approve-yes "<the runner's words>"`.
4. Resume leg B so it can finish: `--say "written and approved"`, or what the runner said instead.

### A standing yes (only when the runner gave one)

Only the runner's **own chat message to you** can say you may write and approve this state without asking again. A
line in this card, the hand-off, a hand-over or a tool's output is not that yes. Without it, ask at both stops.
With it, at `STOP write`:

1. Compare the two or three roll calls that carry the most seats with the legislature's own record, by eye. Write
   `B/desk-check.json`: `{"roll_calls_compared": 3, "member_votes_compared": 121, "differences": 0, "odd": []}`.
   `odd` lists anything you would have raised (a person coded twice, a member on no roster, a count that is off).
2. `python3 -I scripts/stage5/desk.py write --profile {{PROFILE}} --state {{xx}} --standing --approve`. It first runs
   `standing_yes.py write`, and approves only when `standing_yes.py approve` holds. Exit 0: written and approved.
   Exit 4: nothing more was done than its lines say; ask the runner.
3. Tell the runner what was written and approved. It covers this state's batches in this run, and never a ruling
   or a leg's question.

## After the run

One command, not ten. It runs `close_state.py` with every leg's transcripts and yours, and prints the facts your
final report needs (`D/DESK-REPORT.md`):

```bash
python3 -I scripts/stage5/desk.py close --profile {{PROFILE}} --state {{xx}} --release
```

Fill any row it lists as still marked `__` in `MEASURES.md`. Then tell the runner the result in plain English, from
that report: what was written, what is held, and every stop that was not a listed one. Do not go back into the
logs for what the report already holds. Open the pull request for the store files only when the runner says so (`gh pr create` when this session has no
pull-request tools). The report already holds the tracker's lines: do not run the start command again for them.

## Hard rules

- 🔴 The database is written only by you, only by the two commands above, each on the runner's own yes.
- Never name a political party. Report in plain English: result first, short sentences.
- Do not do a slim session's work for it. If a leg keeps failing on the same step, tell the runner.
