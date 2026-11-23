# Stage 5 summary check — {{TOPIC_KEY}} — {{PERSON}}

<!-- Orchestrator: do not fill this by hand. `checkerPrompt()` in `backend/scripts/stage5/summary-inputs.ts` fills
     every slot and refuses an unfilled {{…}}. The checker is never the writer. It reads this file only. Outside
     models (GPT, Gemini) get the same file and the same output format; no database, no `.env`, no other files. -->

You check one summary of what a person has said or done on **{{TOPIC_NAME}}**. You see the summary as it will be
shown, the full text of every finding it cites (placed under the sentence that cites it), and the person's outcome.
Nothing else is evidence. Do not search. Do not use anything you remember about the person.

## The summary, as shown

{{SUMMARY}}

References (the number in brackets is the position in this list):

{{REFERENCES}}

## The person's outcome

{{OUTCOME}}

## Facts a script read from the findings

Code read these from the findings below. They are exact: use them, do not work them out again.

{{FACTS}}

## The evidence, sentence by sentence

Under each sentence are the findings its markers name, and under each finding the stored text of its bill (what the
bill does; describe a bill from this, not from its title alone). A bill's text is printed once per sentence.

{{FINDINGS}}

## What to check, per sentence

Judge each sentence on its own. A sentence may have a marker after each of its parts: each part must be supported
by the findings its own marker names (the number in a marker is the reference number; `cites findings` maps each
number to its finding). The **opening line**, if there is one, has no marker: judge it against every finding the
summary cites, taken together. A sentence **fails** if any of these is true:

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
8. A gated vote (one nearly everyone cast the same way, or on a bill that covers several subjects) is described as
   showing a position it does not show, such as support for the bill's gun part.
9. A sentence says a bill did something as law ("which repealed", "which created") when no cited finding shows it
   became law. "Voted for a bill to repeal …" is fine, and needs no note that the bill did not become law.
10. A bill is described in a way its title and bill text do not support: it says something the text does not say,
    states the bill's reach wrongly (a ban on "government lists" when the bill bars lists kept by anyone), adds a
    condition the bill does not have, or names the wrong people covered; or it is described only by its subject ("a
    bill relating to firearms", "a bill on guns"); or by a part that is not about guns. A short description may
    leave out exceptions, exemptions, minor details and other groups the bill also covers, as long as what it says is
    true; that alone is not a fail.
11. The opening line names a lean that a finding showing a direction contradicts; counts a gated vote toward the
    lean; says "mostly" without a clear majority of the findings that show a direction; or names one direction when
    those findings point both ways. A lean may be stated in general words ("voted to loosen limits on guns") without
    covering every act, and a finding that shows no direction neither supports nor blocks it. Whether a record is
    mixed depends on the findings, not on the seat: a doesnt-fit person whose findings point one way may lean that way.

Use the script's facts for two checks, and apply them the same way every time:
- **Gated votes.** A gated vote shows no position on guns. For each marker whose facts say "Every finding cited for
  this marker is gated":
  - `multi-subject`: the sentence fails unless it describes the whole bill, naming its other subjects as well as its
    gun part ("a public-safety bill that covered permitless carry, school safety and spending"). Describing it by
    its gun part alone fails.
  - `near-unanimous`: saying the person voted for the bill, described from its text, is fine. It fails only if the
    sentence calls the vote support, backing or a position.
  - Either kind never counts toward the lean in the opening line (rule 11): the facts list the markers the lean may
    not rest on.
  A marker with "A non-gated finding on the same bill is also cited" (for example a sponsorship) does not fail for
  being gated, and may count toward the lean.
- **Sponsored or voted.** If the sentence says the person sponsored, co-sponsored, authored or introduced the bill
  behind a marker, that marker's facts must show a sponsorship; if it says the person voted, they must show a vote.
  "Co-sponsored and voted for" needs both, for every marker the words cover.

Check each bill description piece by piece, and show the pieces before you judge. For each marker that cites a bill,
add one entry to the sentence's `support` list: `ref` (the marker number) and `pieces`. Split what the sentence says
the bill does into its pieces: the action (bar, require, let, repeal ...), who it applies to, what it covers, and
every condition or limit the sentence states (when, where, which kind, unless). For each piece give `words` (the
sentence's words), `quote` (the exact words of that finding's title or bill text that show this piece, copied, not
paraphrased) and `shown` (true or false). If the text does not show a piece, or shows something different (the
sentence says "in schools" and the text says "in schools and on any other public property"; the sentence says the
bill "bans" a thing and the text "requires a permit for" it), set `quote` to the nearest words or null and
`shown` to false. A piece with `shown` false fails the sentence. Do not fill a gap from what you know about the
bill or the law it amends. When a marker cites two bills, each bill must show every piece. This is only about what
the sentence says: pieces of the bill that the sentence leaves out are judged by rule 10 and are usually fine.

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
  "sentences": [ { "index": 0, "support": [ { "ref": 1, "pieces": [ { "words": "...", "quote": "...", "shown": true } ] } ], "verdict": "pass", "reason": "..." } ],
  "verdict": "pass"
}
```

Path to write your JSON to: {{OUT_FILE}}
