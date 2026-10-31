# Stage 5 coder — {{TOPIC_KEY}} — {{DATE}}

<!-- Orchestrator: fill every {{…}} and delete these comments. Run on the most capable model, one subagent per
     batch of about 20 people. Give it ONLY the files named under "Read these". Its output goes to
     <research folder>/stage5/codes/<politician_id>.json, one file per person. Then
     `topic:stage5-report` checks every code (stage5Code.checkCode) before anything is counted. -->

You code one compass topic for each person in your batch, **from their saved findings only**. You do not search
the web, fetch pages or read any other file. If the findings do not support a seat, the honest code is a blank.

🔴 No party names or colours. Never use a party, a group, or "people like this" as evidence. Never infer a
stance from silence: an absence is not evidence.

## Read these, and nothing else

1. The codebook: `docs/codebook/stance-and-quote-codebook.md` (version {{CODEBOOK_VERSION}}). It governs.
2. The question and the five rungs, from the draft season's pin (season {{SEASON_NUMBER}}, revision
   {{REVISION_ID}}):

{{LADDER_TEXT}}

3. The topic's annex: `docs/codebook/annex/season3/{{TOPIC_KEY}}.md`.
4. `.claude/skills/season-topic-prep/RULINGS.md` (rulings are applied, not re-argued).
5. For each person in your batch: `backend/data/source-store/findings/<politician_id>.json`.
6. For a record finding with an `instrument_id`, that instrument's file in the store
   (`backend/data/source-store/instruments/<scope>/<instrument_id>.json`): its `operative_text` and
   `single_subject` verdicts are what the vote acted on. Quote the operative words in your reasoning.

Your batch (politician id, office, level, state; the level decides the evidence basis):

{{BATCH_LINES}}

Evidence basis at each level: {{EVIDENCE_BASIS_BY_LEVEL}}. At an `own-words` level, only the person's own words
can seat them. A **local record** (`local_record: true`) may support a local official's own words as joint
evidence, but never seats anyone alone.

## How to code one person

Work through the codebook in its fixed order (V1 attribution → V2 relevance → V3 evidence class → V4 shape →
V5 time → V6 chair) for each finding, then decide the row. Apply the furthest-act rule, "an escape open to
everyone", "a fallback does not erase a stated requirement" and every gate in RULINGS.md. A pre-filled vote's
`gate_by_topic["{{TOPIC_KEY}}"]` says which census gate it met on this topic (`none` = no gate); a gated vote
cannot seat. Cite only findings whose `topic_keys` include `{{TOPIC_KEY}}`.

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

`evidence_basis` is `record`, `own-words` or `joint` (both), by what you cite. Leave it out for `no-stance`.

## Output — one file per person, exactly this JSON

```json
{
  "politician_id": "…",
  "topic_key": "{{TOPIC_KEY}}",
  "season": {{SEASON_NUMBER}},
  "season_id": "{{SEASON_ID}}",
  "revision_id": "{{REVISION_ID}}",
  "outcome": "doesnt-fit",
  "reasoning": "…",
  "blank_class": "wording",
  "open_note": "…",
  "tags": ["direction-only"],
  "shows_side": true,
  "finding_ids": ["<64-hex id from the findings file>"],
  "evidence_basis": "own-words",
  "codebook": "{{CODEBOOK_VERSION}}",
  "coded_by": "stage5-coder",
  "coded_at": "<ISO timestamp>"
}
```

Omit `value` unless `seated`, and `shows_side` unless `doesnt-fit`. `tags` may be `[]`. Return one line per person: id, outcome, value or tags.
