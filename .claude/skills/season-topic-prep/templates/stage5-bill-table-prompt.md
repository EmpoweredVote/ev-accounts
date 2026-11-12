<!--
Stage 5 bill table (STAGE5.md "3b. Bill table"). One Opus agent, once per state, after the last bill round and the
bill-text fill, before coding. Fill the {{SLOTS}} by hand or with run-stage5 (PR 3). Model: Opus. Never a cheaper
model: this is judgment, and every coder in the state reads its result.
Check the output with: python3 -I backend/scripts/stage5/bill_table.py check <OUT> --ids <roster ids>
-->
# Stage 5 bill table: {{TOPIC_KEY}}, {{STATE}}

You read each bill below once, and say which rung of the ladder a **Yes** on it supports. The coders then use your
table for every person in {{STATE}}, so a wrong row is wrong for everyone who voted on that bill. When you are not
sure, say so in `flag`: the runner answers flags before coding starts.

## The ladder

{{LADDER_TEXT}}

## Rulings that apply

{{RULINGS}}

## The bills

Each bill is one file: `{{BILLS_DIR}}/<ID>.json`, with `title` and `operative_text`. Read the operative text, not
only the title. The bills are:

{{BILL_IDS}}

## For each bill

- `rung`: the rung a Yes supports, 1 to {{RUNGS}}. Use `null` when a Yes supports no single rung: the bill only shows
  a direction, it is off the question, or it moves both ways at once.
- `deciding_words`: the words in the operative text that decide the rung, **copied exactly** (a checker looks for
  them in the text; join two separate passages with ` ... `). Leave it empty only for a `null` rung.
- `why`: one or two plain sentences a voter could follow. Name the rung's own words, not a ruling's label.
- `flag`: a question for the runner when a ruling does not settle the bill, or `""`. Ask it as a yes/no question
  with your best answer, e.g. "Cuts the permit fee only. Rung 4 under the 3 Nov ruling — confirm?"

Do not guess a rung to avoid a flag. A flag costs the runner one minute; a wrong row costs a re-code of everyone who
voted on that bill.

## Output

Write ONE file, `{{OUT}}`, and nothing else:

```json
{"topic_key": "{{TOPIC_KEY}}", "bills": {"<ID>": {"rung": 4, "deciding_words": "...", "why": "...", "flag": ""}}}
```

Every bill listed above must have a row. Then reply with one line: how many bills, how many `null`, how many flagged.
