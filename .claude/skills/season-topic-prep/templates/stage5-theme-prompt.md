# Stage 5 theme pass — {{TOPIC_KEY}} — {{DATE}}

<!-- Orchestrator: fill every {{…}} and delete these comments. Make the notes file with
     `topic:stage5-report … --notes-out <abs notes.jsonl>`. Run this as a fresh subagent on the most capable model,
     separate from the coders. Give it the notes file and the ladder only. It writes
     <research folder>/stage5/themes.json; then re-run `topic:stage5-report … --themes <that file>`. -->

You read every "doesn't fit" note from Stage 5 on one topic and find the themes in them. A note says what a person
said or did on the topic and why none of the five rungs holds it. The notes are the evidence; nothing else is.

Do not read any other file. Do not search. No party names or colours, and no judgement of any person.

## The question and the five rungs

{{LADDER_TEXT}}

## The notes

`{{NOTES_FILE}}` — one JSON object per line: `politician_id`, `level`, `state`, the coder's `tags`, `blank_class`,
and the `open_note`.

## What to do

1. Read every note. The coder's tags are hints, not categories: **group by what the notes say**, and name each
   group in plain words a voter would understand (for example "backs voter ID but names no rule", "talks about
   mail ballots only", "a rule about which level decides"). Do not start from a list of reasons.
2. A note may sit in one theme only. A note that fits no theme stays unthemed; do not force it.
3. For each theme, say what it points at:
   - `rung-change` — a rung's wording leaves out a common, real position or act;
   - `new-topic` — a related but different question, worth its own topic;
   - `nothing` — a correct blank (a vote no rung can hold, a gate, a level with no lever).
4. Write a two- or three-sentence summary per theme, quoting no names.

## Output — `themes.json`, exactly this shape

```json
{
  "at": "<ISO timestamp>",
  "read_notes": 0,
  "themes": [
    { "name": "…", "points_at": "rung-change", "politician_ids": ["…"], "summary": "…" }
  ]
}
```

`read_notes` is how many notes you read. Return one line per theme: name, count, points at.
