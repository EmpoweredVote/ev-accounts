
---

# You are running this card as a slim session

Nobody is watching this session and nobody can answer you while it runs. A desk session started you; it reads your
last line when you end, speaks to the runner, and starts you again with the answer. These rules come before
anything in the card above.

## The database

🔴 **You never write the database.** Not the batch write, not the verifier with `--apply`, not the approval, not
any `INSERT`, `UPDATE`, `DELETE` or migration, by any tool or by hand. The Stage 5 write tools refuse you (exit 5,
`STAGE5_NO_DB_WRITE`); do not look for a way round that, and do not change that setting. Reading is fine.
When the card reaches a write or an approval, stop and hand it to the desk (below).

## When you need the runner

You cannot ask. So at every 🛑 stop on the card, at any stop the card does not list, and any time you would
otherwise guess at a ruling:

1. Finish and save everything that does not depend on the answer.
2. Write the question to `{{DESK}}/QUESTION-{{LEG}}-<n>.md` (n = 1, 2, …): what you found, the one decision
   needed, the options, the one you recommend and why, and what you will do on each answer. Plain English, result
   first, short sentences, terms defined. Never name a party.
3. End your turn. Your **last line** must be exactly one of:

```
STOP question {{DESK}}/QUESTION-{{LEG}}-<n>.md
STOP write {{S}}/write/{{xx}}-01/PREVIEW.md
STOP approve {{S}}/write/{{xx}}-01/PREVIEW.md
STOP blocked <one line: what failed and the file to read>
DONE {{LEG}}
```

`STOP write` is for the preview (the desk runs the write and the read-back on the runner's yes). `STOP approve`
is not yours to use: the desk approves after its own read-back. `STOP blocked` is for a fault you cannot work
through; say what you tried. `DONE` only when every step of this card is finished and its hand-over is written.

When you are started again, the first lines give the runner's answer word for word. Record it where the card
says rulings go, then carry on from where you stopped. Do not repeat finished steps.

## While you work

- Keep `{{DESK}}/LOG-{{LEG}}.md`: one line per step finished, with its count or result. The desk reads it instead
  of your history. Write down every stop that is not on the card's list, and what caused it.
- Long commands (waves, `run_state.py`, `run_recipe.py`, fetches) run in the foreground: you have nothing else to
  do while they run, and a background job outlives nothing here.
- Close-out: run `close_state.py` only if the card tells this leg to. The desk adds its own transcript.
- Commit by explicit pathspec in this worktree when the card says to commit. Never push, never open a pull request.
