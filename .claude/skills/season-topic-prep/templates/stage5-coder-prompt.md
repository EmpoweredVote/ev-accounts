# Stage 5 coder — {{TOPIC_KEY}} — {{BATCH}} — {{DATE}}

<!-- Do not fill this by hand. `backend/scripts/stage5/coder-inputs.ts` fills every {{…}} slot from the run's
     coder config and rulings digest, writes the batch's compact findings file, and refuses to leave a slot
     unfilled. Run it on the most capable model, one subagent per batch of about 20 people. The coder writes ONE
     file; `backend/scripts/stage5/split-codes.ts` checks every code in it and writes `codes/<politician_id>.json`. -->

You code one compass topic for each person in your batch, **from their saved findings only**. You do not search
the web, fetch pages or read any other file. If the findings do not support a seat, the honest code is a blank.

🔴 No party names or colours. Never use a party, a group, or "people like this" as evidence. Never infer a
stance from silence: an absence is not evidence.

## Read these, and nothing else

1. The codebook: `{{REPO}}/docs/codebook/stance-and-quote-codebook.md` (version {{CODEBOOK_VERSION}}). It governs.
2. The question and the five rungs, from the draft season's pin (season {{SEASON_NUMBER}}, revision
   {{REVISION_ID}}):

{{LADDER_TEXT}}

3. The topic's annex: `{{REPO}}/docs/codebook/annex/season3/{{TOPIC_KEY}}.md`.
4. `{{REPO}}/.claude/skills/season-topic-prep/RULINGS.md` (rulings are applied, not re-argued), and the rulings
   and notes at the end of this brief.
5. Your batch's findings, all in one file: `{{FINDINGS_FILE}}`. Its `about` line says how it is laid out. It
   holds this topic's findings only, word for word from the source store, without the source-tracking fields.
6. For a record finding with an `instrument_id`, that instrument's file: the `bills` table in the findings file
   gives its path under `{{INSTRUMENTS_DIR}}/`. Its `operative_text` and `single_subject` verdicts are what the
   vote acted on. Quote the operative words in your reasoning. A bill with no `file` has no instrument in the
   store.

Your batch (politician id, office, level, state; the level decides the evidence basis):

{{BATCH_LINES}}

Evidence basis at each level: {{EVIDENCE_BASIS_BY_LEVEL}}. At an `own-words` level, only the person's own words
can seat them. A **local record** (`local_record: true`) may support a local official's own words as joint
evidence, but never seats anyone alone.

## How to code one person

Work through the codebook in its fixed order (V1 attribution → V2 relevance → V3 evidence class → V4 shape →
V5 time → V6 chair) for each finding, then decide the row. Apply the furthest-act rule, "an escape open to
everyone", "a fallback does not erase a stated requirement" and every gate in RULINGS.md. A pre-filled vote's
`gate` says which census gate it met on this topic (`none` = no gate); a gated vote cannot seat. Every
finding in your file is on this topic; cite them by `id`.

Give exactly one outcome:

- **`seated`** — the findings meet every clause of one rung (alone, or as joint evidence under V4.2). Give the
  `value` (1–5, halves allowed), the `reasoning` naming the act or words and the clauses they meet, and the
  `finding_ids` you rest on.
- **`no-stance`** — nothing on the topic after the search. The `reasoning` says what was searched (copy the
  places from the search entry). Cite no findings.
- **`doesnt-fit`** — there is on-topic evidence, but no rung holds it. Write the **`open_note`**: what the person
  said or did, and why no rung holds it, in your own words, two or three sentences. This note is what the theme
  pass reads, so be concrete. Add any of these tags that fit, several, or none:
  `between-rungs`, `related-question` (a possible other topic), `unnamed-position` (a position no rung names),
  `direction-only` (shows a side, not a rung), `other-level-lever`. Do not force a case into a tag.
  Also give the older `blank_class` as detail: `gate`, `wording`, `no-lever`, `off-question` or `nay-only`.
  And answer **`shows_side`**, true or false: does the evidence show which way the person leans on the question,
  even though no rung holds it ("people should show their voter ID", no kind named → true), or no side at all
  (an abstention, a line about a neighbouring question, current law described without a view → false)? It decides
  what voters see: a side is written as `direction-only`, no side as `no-evidence` (RULINGS.md "Mapping a blank to a
  V6 reason"). With the `direction-only` tag it must be true.

## The reasoning is read by voters

- **No labels.** Never write an annex, codebook-clause or ruling label (S3, Q2, C2, H12, R5-AZ…) in the
  reasoning. Write the rule in words ("removing a gun from a registration law is a rung 5 act").
- **Only this person's bills.** Name only bills that are in this person's findings. A ruling's example bill is
  not their record: state the rule in words instead.
- **Name a bill as voters would.** Write "SB 1176 (2026)" or "HB 2057 (2016)": chamber letters, number, year in
  brackets. Never write a store id (`MO-SB-1176-2026`): the gate cannot read it as a bill.
- **Quote marks are a promise.** Put them only round words copied exactly from a cited finding's `passage` or a
  cited bill's `operative_text` or title (or the rung text). Otherwise write without quote marks.
- **End a quote where the source ends it.** Do not add a full stop the source does not have, and do not drop
  words in the middle. If the source goes on past a comma, close the quote at the comma and put your own full
  stop outside the quote marks.

A check runs on every code as soon as your file is read, and sends back any code that breaks one of these
rules, or any rule above, with the reason.

## Output — ONE file for the whole batch

Write `{{CODED_FILE}}` once, when every person is coded, in exactly this shape:

```json
{
  "batch": "{{BATCH}}",
  "codes": [
    {
      "politician_id": "…",
      "outcome": "doesnt-fit",
      "reasoning": "…",
      "blank_class": "wording",
      "open_note": "…",
      "tags": ["direction-only"],
      "shows_side": true,
      "finding_ids": ["<64-hex id from the findings file>"]
    }
  ]
}
```

One entry per person in your batch. Give `value` only when `seated`; `blank_class`, `open_note`, `tags` and
`shows_side` only when `doesnt-fit`. Do not write `evidence_basis`, `coded_at`, the season or the revision: the
ingest sets them from your cited findings and the run. Return one line per person: id, outcome, value or tags.

## Rulings and notes for this batch

{{RULINGS}}
