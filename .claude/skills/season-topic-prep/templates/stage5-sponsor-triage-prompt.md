<!--
Stage 5 sponsor-cover triage (STAGE5.md "3a. Bill round one"). One Opus agent per state. Input: the candidates file
from `sponsor_cover.py --candidates`. Output: the triage file for `sponsor_cover.py --triage ... --write ...`.
-->
# Sponsor-cover triage: {{TOPIC_KEY}}, {{STATE}}

The keyword scan found the bills below. A roster member sponsored each one, and none is in the core set yet. Each
bill you keep costs a bill-text fill, and each one you drop may hide the only record a person has on this question.

The question is: {{QUESTION}}

Read `{{CANDIDATES}}` (a list of `bill_id`, year, number, title and sponsors). For each bill, mark:

- `"fill"` when the title could be about the question — and whenever you are unsure. A title is short; the bill
  text decides later.
- `"skip"` only when the title is plainly about something else (a tax credit for storage, hunting seasons, a
  court's name), with the keyword appearing by accident.

Write ONE file, `{{OUT}}`: `{"<bill_id>": "fill" | "skip", ...}`, with every bill_id in the candidates file. Then
reply with one line: how many fill, how many skip.
