# Stage 5 position summaries — {{TOPIC_KEY}} — {{DATE}}

<!-- Orchestrator: do not fill this by hand. `backend/scripts/stage5/summary-inputs.ts` fills every slot and exits 1
     if any {{…}} is left. Run each file as a fresh subagent on the most capable model, one file per agent. The
     agent reads this file only, and writes {{OUT_FILE}}. -->

You write a short, cited summary of what each person below has said or done on one topic: **{{TOPIC_NAME}}**.
The saved findings in this file are the only evidence. Do not read any other file. Do not search. Do not use
anything you remember about a person.

A summary is one short paragraph about the person, one to five sentences in all. It should read as a summary of
where the person stands on the topic, not as a list of bills. **Do not write citation numbers or brackets in the
text.** The tool numbers the sources and writes the reference list from the findings' own URLs.

## The shape

1. **Opening line (when the findings support one).** One sentence in plain words on the direction of the person's
   record or words: for example "Rick Williams has voted to loosen limits on guns in both chambers of the Georgia
   legislature." It carries no cites (`"lead": true`); it rests on every finding the rest of the summary cites, so it
   may say no more than those findings show together. For a **doesnt-fit** person it says the record runs more than
   one way and names both: "Her votes mostly widened where people may carry a gun, but she also voted for tougher
   penalties for juveniles with weapons." Leave it out when the findings are too thin to say a direction honestly.
2. **Then what they did, grouped by what it does.** Put acts of the same kind in one sentence, each as its own
   part with its own cites: "In the House, he voted to end the license requirement to carry a handgun, to honor carry
   licenses from more states and to allow license holders to carry on public college campuses." Say what each act
   does in plain words. **Do not name bill numbers in the text**; the references carry them. Name a bill only when a
   voter would know it by name (a named act such as the "Constitutional Carry Act" is fine).
3. **A vote is a vote, not a law.** Write "voted for a bill to repeal the silencer ban", never "voted for HB 1, which
   repealed the silencer ban", unless a finding shows the bill became law. A sponsor "sponsored a bill to …"; a bill
   that failed "would have …".

## Writing rules

1. Every part after the opening line carries at least one citation, and each cited finding supports that part.
2. Describe views and acts; never name a rung, a rung number or the ladder's wording.
3. Agree with the seat. For a seated person, nothing in the summary may point to the other side of the ladder
   (`sides`: {{SIDES}}). A two-sided record may be described as two-sided only if the person is not seated.
4. No inference from silence, party or office. No party names or colours.
5. Quantity words need support: "often", "consistently", "repeatedly" need at least three cited acts; "more than
   once" needs two. In the opening line, count every finding the summary cites.
6. Dates and offices as the evidence gives them; a statement made in another office or as a candidate says so.
7. Neutral tone: the words a news wire would use ("loosen", "tighten", "expand", "limit"), no adjectives of judgement.

Also: one sentence per entry (no sentence may hold a second sentence). A finding marked `act: yea` with
`against_bill: true` is a vote AGAINST the bill. A vote marked as gated (nearly everyone voted the same way) says
little about a position; do not lean on it. Use only `cites` ids that appear in that person's findings below. When
the findings support only one sentence, write one sentence and no opening line; do not pad.

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
      { "text": "Opening line in plain words, no brackets.", "lead": true },
      { "parts": [
          { "text": "In the House, he voted to end the license requirement to carry a handgun,", "cites": ["<finding id>"] },
          { "text": "to honor carry licenses from more states", "cites": ["<finding id>"] },
          { "text": "and to allow license holders to carry on college campuses.", "cites": ["<finding id>"] }
      ] },
      { "text": "A sentence about one act, no brackets.", "cites": ["<finding id>", "<finding id>"] }
    ]
  }
]
```

Reply with one line: the file path and the number of people written.
