# The adversarial check (Stage 3; replaces T4)

## Why

T4 asked the runner to label bill-based rows blind, from dense legal text where one clause changes the answer. That
is expert work, and it was never completed on any topic. Its purpose was an independent check on a misreading that
the coders and the act checklist might share, because they come from the same model family. The adversarial check
keeps that purpose and drops the blind labelling.

## 1. The adversarial checker

An independent **subagent**, started with [templates/adversary-prompt.md](templates/adversary-prompt.md). It gets:
the frozen texts, the winning ladder with its annex lines and rulings, the codebook, and the list of rows to attack.
It does not get the act checklist, the coders' reasoning or the validators' labels; it reads the source itself.

Rows to attack: **every seated row**, plus a sample of blanks (at least 10, or all blanks if fewer; draw them by a
seed written in `stage3/preregistration.json`).

For each row it tries to prove the chair wrong. It hunts for the clause that:
- moves the row to another rung;
- makes the evidence direction-only (a side shown, no rung stated);
- makes the instrument multi-subject under the season's served topic list;
- gates the vote (consent, near-unanimous, higher-law duty, off-version sponsor);
- or, for a blank, seats it after all.

It reports **each attack** with the deciding sentence quoted verbatim, the rung it argues for, and why. Agreement is
not the output; a row with no attack is listed only by id. Output: `stage3/adversary/attacks.json`.

## 2. Disputes to the runner as plain questions

You (the orchestrator) read each attack against the source. An attack that fails on the text (the quote does not
say what the attack claims, or a ruling in RULINGS.md settles it) is closed with a one-line reason in
`stage3/disputes.md`. The closed attacks and their reasons are also listed in the one-page summary of
`stage3/results.md`, so the runner can see what was tried and why it failed. Each attack that **survives** becomes one dispute, in this format:

```markdown
### D1 — <person or row id> · <instrument id> · chair <n> → <n or blank>

**Deciding sentence:** "<the one sentence, verbatim>" (<section>, <source URL>)

**What it does, in plain words:** <one or two sentences>

**Reading A (chair stands):** <one sentence>
**Reading B (attack holds):** <one sentence>

**Recommend:** A or B, because <reason>. Rows affected: <n>.

**Ruling:** _(runner, date)_
```

No full bill and no blind labelling. Expect 0–3 disputes per topic. Ask them one at a time, as in SKILL.md "How to
ask for a ruling".

## 3. The gate

**Stage 3 passes only when every dispute is ruled.** Re-score T1 with the rulings applied and report it beside the
first score. When a ruling generalises beyond this topic, propose it as a RULINGS.md line.

## 4. The expert queue

Every **seated** row that rests on a bill or ordinance goes into `stage3/expert-queue.json` for future
political-science reviewers. Shape (one object per row):

```json
[
  {
    "politician_id": "<uuid>",
    "instrument_id": "WA-ESSB-5044-2021",
    "chair": 1,
    "deciding_quote": "<the sentence the chair rests on, verbatim>"
  }
]
```

Count it in the Monday update (`expertQueue`). The revision's rationale states honestly that expert review is owed
and how many rows are queued.

## T4 items on the Blind Gold Desk

The T4 items already posted (`t4lib`, `t4pol`, `t4eq`) are **retired from the gate**. Nothing waits on them. They stay
on the Gold Desk as optional expert-queue items; a label there is welcome but never required.
