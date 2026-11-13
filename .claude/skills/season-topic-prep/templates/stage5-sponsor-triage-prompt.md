<!--
Stage 5 sponsor-cover triage (STAGE5.md "3a. Bill round one"). One Opus agent per state. Input: the candidates file
from `sponsor_cover.py --candidates`. Output: the triage file for `sponsor_cover.py --triage ... --write ...`.
Round three (2026-11-13): the third answer, "stub". `sponsor_cover.py` turns a "stub" back into "fill" for any bill a
roster member voted on, and lists the rest for the runner.
{{RUNG_ACTS}} and {{NO_RUNG_KINDS}} are per topic, written from the ladder and the topic's rulings. Gun-policy (2026-11-13):
  RUNG_ACTS: it could change who may buy, have or carry a gun, where or how; ban or allow a type of firearm, magazine
    or part; or add or remove a permit, licence, check, waiting period, registration or order that takes guns away
  NO_RUNG_KINDS: a rule for dealers' or makers' business (inspections, security, signs, record-keeping, fees they
    collect), a tax or insurance rule, a storage rule, a report, study, office, grant or training programme, a notice
    or information duty, police or other officers' own weapons, the sentence for a crime committed with a gun, how
    police destroy or return guns, or court procedure for people the law already bars
-->
# Sponsor-cover triage: {{TOPIC_KEY}}, {{STATE}}

The keyword scan found the bills below. A roster member sponsored each one, and none is in the core set yet. Each
bill you mark "fill" costs a bill-text read, and each one you do not may hide the only record a person has on this
question.

The question is: {{QUESTION}}

The rungs a bill can support:

{{LADDER_TEXT}}

Read `{{CANDIDATES}}` (a list of `bill_id`, year, number, `title`, `desc` (the state's own summary line, often only
the code sections amended), sponsors, and `floor_voters`: how many roster members voted on it on the floor). For
each bill, mark exactly one of:

- `"fill"` when the bill could put a person on one of the rungs above: {{RUNG_ACTS}}. **Mark "fill" whenever you are unsure.** A bare title
  ("Firearms.", "Weapons.") or a summary that only lists code sections tells you nothing: that is "fill".
- `"stub"` only when the title or summary shows plainly that the bill is on the topic but can carry no rung: {{NO_RUNG_KINDS}}. A stub is not read; it is listed for the
  runner, and a record on it cannot seat anyone.
- `"skip"` only when the title is plainly about something else (a tax credit for storage, hunting seasons, a
  court's name), with the keyword appearing by accident.

Judge each bill on its own title and summary. Do not look anything up, and do not guess from the sponsor.

Write ONE file, `{{OUT}}`: `{"<bill_id>": "fill" | "stub" | "skip", ...}`, with every bill_id in the candidates
file. Then reply with one line: how many fill, how many stub, how many skip.
