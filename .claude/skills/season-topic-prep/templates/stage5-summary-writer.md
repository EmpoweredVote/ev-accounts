# Stage 5 position summaries — {{TOPIC_KEY}} — {{DATE}}

<!-- Orchestrator: do not fill this by hand. `backend/scripts/stage5/summary-inputs.ts` fills every slot and exits 1
     if any {{…}} is left. Run each file as a fresh subagent on the most capable model, one file per agent. The
     agent reads this file only, and writes {{OUT_FILE}}. -->

You write a short, cited summary of what each person below has said or done on one topic: **{{TOPIC_NAME}}**.
The saved findings in this file are the only evidence. Do not read any other file. Do not search. Do not use
anything you remember about a person.

A summary is two to five sentences of plain prose. Each sentence is its own entry in the output, with the ids of
the findings it rests on. **Do not write citation numbers or brackets in the text.** The tool numbers the sources
and writes the reference list from the findings' own URLs.

## Writing rules

1. Every sentence carries at least one citation, and each cited finding supports what the sentence says.
2. Describe views and acts; never name a rung, a rung number or the ladder's wording.
3. Agree with the seat. For a seated person, nothing in the summary may point to the other side of the ladder
   (`sides`: {{SIDES}}). A two-sided record may be described as two-sided only if the person is not seated.
4. No inference from silence, party or office. No party names or colours.
5. Quantity words need support: "often", "consistently", "repeatedly" need at least three cited acts; "more than
   once" needs two.
6. Dates and offices as the evidence gives them; a statement made in another office or as a candidate says so.
7. Neutral tone: the words a news wire would use, no adjectives of judgement.

Also: one sentence per entry (no sentence may hold a second sentence). Name a bill or act in the sentence when it
helps ("voted for SB 243"); that is allowed, never required. A finding marked `act: yea` with
`against_bill: true` is a vote AGAINST the bill. Use only `cites` ids that appear in that person's findings below.
When the findings give you fewer than two sentences you can support, write the sentences you can; do not pad.

## People

For a **seated** person the `seat` line says which side of the ladder they hold (`value`, and the sides above).
For a **doesnt-fit** person there is no seat: describe what the findings show, without saying a position fits or
does not fit. Findings marked `coder-cited` are the ones the coder relied on; you may cite any of the person's
findings.

{{PEOPLE}}

## Output

Write `{{OUT_FILE}}`: a JSON array with one object per person above, exactly this shape and nothing else.

```json
[
  {
    "politician_id": "<the person's id>",
    "topic_key": "{{TOPIC_KEY}}",
    "sentences": [
      { "text": "One sentence, no brackets.", "cites": ["<finding id>", "<finding id>"] }
    ]
  }
]
```

Reply with one line: the file path and the number of people written.
