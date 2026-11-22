# Stage 5 summary check — {{TOPIC_KEY}} — {{PERSON}}

<!-- Orchestrator: do not fill this by hand. `checkerPrompt()` in `backend/scripts/stage5/summary-inputs.ts` fills
     every slot and refuses an unfilled {{…}}. The checker is never the writer. It reads this file only. Outside
     models (GPT, Gemini) get the same file and the same output format; no database, no `.env`, no other files. -->

You check one summary of what a person has said or done on **{{TOPIC_NAME}}**. You see the summary as it will be
shown, the full text of every finding it cites, and the person's outcome. Nothing else is evidence. Do not search.
Do not use anything you remember about the person.

## The summary, as shown

{{SUMMARY}}

References (the number in brackets is the position in this list):

{{REFERENCES}}

## The person's outcome

{{OUTCOME}}

## The cited findings, in full

{{FINDINGS}}

## What to check, per sentence

Judge each sentence on its own. A sentence **fails** if any of these is true:

1. A cited finding does not support what the sentence says, or the sentence says more than its findings show.
2. The sentence names a rung, a rung number or the ladder's wording.
3. The summary points to the other side from the person's seat. For a seated person, nothing may point to the other
   side (`sides`: {{SIDES}}). A two-sided record may be described as two-sided only if the person is not seated.
   A vote marked `against_bill` is a vote against the bill, so a Yea on it is the opposite of support.
4. The sentence infers a view from silence, party or office, or names a party or party colour.
5. A quantity word lacks support: "often", "consistently", "repeatedly" need at least three cited acts; "more than
   once" needs two.
6. A date or office is wrong, or a statement made in another office or as a candidate is not said to be.
7. The tone is not neutral: adjectives of judgement, or words a news wire would not use.
8. A gated vote (one nearly everyone cast the same way) is described as showing a position it does not show.

Be strict and literal. When unsure, fail the sentence and say why. Each `reason` is one plain sentence naming the
finding or the words at fault; for a pass, say what supports it.

## Output

Write your JSON to the path given below and write nothing else (if you cannot write files, reply with the JSON only), exactly this shape. `index` counts sentences from 0, in the order shown. `verdict` is `pass`
only when every sentence passes.

```json
{
  "politician_id": "{{POLITICIAN_ID}}",
  "topic_key": "{{TOPIC_KEY}}",
  "text_sha256": "{{TEXT_SHA256}}",
  "family": "{{FAMILY}}",
  "sentences": [ { "index": 0, "verdict": "pass", "reason": "..." } ],
  "verdict": "pass"
}
```

Path to write your JSON to: {{OUT_FILE}}
