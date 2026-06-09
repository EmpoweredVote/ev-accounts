---
name: research-stances
description: "Research politician stances on compass topics. Use when the user wants to research, look up, or generate stance data for politicians on Empowered Vote policy topics (national, state, and local city-level). Produces a reviewable CSV and optionally pushes approved stances to the database. Triggers on: 'research stances', 'look up stances', 'politician positions', 'stance data for', 'compass research'."
argument-hint: "\"Politician Name(s)\" [--topics topic1,topic2] "
---

# /research-stances — Politician Stance Research Orchestrator

You are running the **research-stances** skill. Your job is to research politician stances on existing Empowered Vote compass topics, produce a reviewable CSV, and optionally push approved data to the database.

---

## STEP 0 — Parse Input

Parse `$ARGUMENTS` for:
- **Politician names**: comma-separated list (e.g., `"Brad Sherman, Maxine Waters"`)
- **--topics**: optional comma-separated topic_keys to limit scope (defaults to all topics)

If `$ARGUMENTS` is empty, ask the user:
> "Which politician(s) would you like me to research? You can provide names (e.g., 'Brad Sherman, Maxine Waters') or a body (e.g., 'Bloomington City Council')."

### Jurisdiction Resolution

If the input looks like a legislative body (e.g., "Bloomington City Council", "California State Senate"), resolve it to individual politicians by querying the database:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT p.id, p.full_name,
         (SELECT o2.title FROM essentials.offices o2
          WHERE o2.politician_id = p.id LIMIT 1) AS title,
         c.name as chamber_name
  FROM essentials.politicians p
  JOIN essentials.chambers c ON c.name ILIKE '%' || \$1 || '%'
  WHERE EXISTS (
    SELECT 1 FROM essentials.offices o3
    WHERE o3.politician_id = p.id
  )
  ORDER BY p.full_name
\`, [process.argv[2]]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "SEARCH_TERM"
```

Replace `SEARCH_TERM` with the relevant part of the user's input (e.g., "City Council" for "Bloomington City Council").

If no results, tell the user and ask them to provide specific names instead.

### Topic Resolution

**ALWAYS fetch live topics AND their stance texts fresh from the DB before every research run. Never use a hardcoded list — the topic set grows over time.**

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT
    t.id, t.topic_key, t.title, t.question_text,
    json_agg(
      json_build_object('value', s.value, 'text', s.text)
      ORDER BY s.value
    ) AS stances
  FROM inform.compass_topics t
  JOIN inform.compass_stances s ON s.topic_id = t.id
  WHERE t.is_live = true
  GROUP BY t.id, t.topic_key, t.title, t.question_text
  ORDER BY t.topic_key
\`);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

Pass the **full output of this query** to each researcher agent prompt — including the stance texts for every value. Never hardcode. As of 2026-06-02 there are 44 live topics; this number will grow.

**Confirm before proceeding.** Show the user:
- List of politicians to research
- Topics in scope (all or filtered)
- Estimated scope (e.g., "3 politicians x 44 topics = up to 132 stance assessments")

---

## STEP 1 — Dispatch Research Agents

For each politician, dispatch a `politician-stance-researcher` agent using the Agent tool.

**Dispatch rules:**
- **Always dispatch ONE agent at a time.** Never run agents in parallel.
- Wait for each agent to complete and confirm the CSV was written before dispatching the next.
- Running parallel agents burns the WebSearch/Playwright rate limit quota instantly, producing no usable output.

**Agent prompt template:**

```
Research the political stances of [POLITICIAN_NAME] ([OFFICE/TITLE if known]).

[If --topics was specified:]
Only research these topics: [TOPIC_LIST]

[If --topics was NOT specified:]
Research all current policy topics.

FIVE-CHAIRS FRAMING — READ BEFORE ASSIGNING ANY VALUE:

Each compass topic has five pre-written stances — one per position on the spoke. These
aren't degree-of-agreement markers. They are five distinct, substantive positions a real
person could hold, defend in a conversation, and point to a policy that reflects it.

Think of them as five named chairs in a room. A politician's public record places them in
one of those chairs. Your job is to find which chair fits the documented evidence — not to
infer a chair from party affiliation or directional assumption.

The spoke has no correct end. Value=1 is not "conservative" and value=5 is not
"progressive" — the direction varies by topic. Read the written text at each value level
for this topic. Find sources that document this politician's position. Match the
documented record to the chair whose text fits.

When a voter matches a politician on a topic, the system must be able to say exactly why:
not "they both scored a 2 on Climate," but "they both support rapidly transitioning to
renewable energy and phasing out fossil fuels by 2030." That claim requires your value
assignment to be defensible with the specific written text — not just a directional
approximation.

Do NOT pick a value based on party expectation. Do NOT assume direction. For every stance
you record, ask: "Does this politician's documented position match the EXACT TEXT at this
value?" If not, pick a different value or skip the topic.

TOPIC SCALE REFERENCE — assign values by matching to exact stance text:
[PASTE THE FULL JSON OUTPUT FROM THE TOPIC RESOLUTION QUERY HERE — including id, topic_key, question_text, and the stances array with value+text for each of the 5 levels]

The topic_key in your CSV output MUST exactly match one of the topic_key values above.
Do NOT invent your own topic_key slugs.
Do NOT include any topic_key not in the above list — the list is fetched fresh each run.

City-level topics to SKIP for state/federal candidates (unless explicitly requested):
transportation-priorities, economic-development, homelessness-response, residential-zoning,
city-sanitation, local-immigration, rent-regulation, growth-and-development, local-environment,
public-safety-approach, jail-capacity, judicial-*

--output-file [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME].csv

TOOL RULE — CRITICAL:
- Use WebFetch ONLY. Never use WebSearch or Playwright — both share a rate-limited quota pool.
- Fetch URLs directly using the URL patterns in your agent definition (Ballotpedia, ontheissues.org, official pages, Wikipedia, CalMatters, LA Times).
- If a URL 404s, try the next pattern. Do not fall back to WebSearch.

Other rules:
- Skip any topic where you cannot find sufficient evidence
- Every source URL must be real and verifiable — only include URLs you actually fetched successfully
- Use the full 1-5 range; match to stance text, not political alignment
```

> **Orchestrator note:** When pasting the JSON output into the `TOPIC SCALE REFERENCE` placeholder above, format each topic entry as:
>
>     [topic_key] (id: [uuid])
>     Question: "[question_text]"
>       1 = "[stance text for value 1]"
>       2 = "[stance text for value 2]"
>       3 = "[stance text for value 3]"
>       4 = "[stance text for value 4]"
>       5 = "[stance text for value 5]"

Use `subagent_type: "politician-stance-researcher"` in the Agent tool call.

---

## STEP 2 — Collect and Merge Results

After all agents complete:

1. Read the CSV file(s) generated by the agents
2. If multiple agents wrote to the same file, verify no duplicate headers
3. If agents returned results in their response text instead of writing to file, manually compile into the CSV file using the Write tool
4. Count total stances collected vs. expected (politicians x topics)
5. The CSV now includes `quote_text` and `quote_deidentified` columns. Parse the CSV with a real RFC-4180 parser (`csv-parse/sync`), never by splitting on commas — quote columns contain commas and embedded quotes.

---

## STEP 3 — Present Approval Summary

Show the user a formatted summary table:

```
## Research Results: [BATCH_NAME]

| Politician | Topics Found | Topics Skipped |
|-----------|-------------|---------------|
| Name 1    | 19/21       | ai-regulation, redistricting |
| Name 2    | 21/21       | none |

### Stance Overview

| Politician | Topic | Value | Reasoning (preview) |
|-----------|-------|-------|-------------------|
| Name 1 | healthcare | 2 | "Cosponsored the Public Option..." |
| Name 1 | abortion | 1 | "Voted against every restrict..." |
| ...    | ...        | ... | ... |

CSV saved to: `ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME].csv`
```

### Quote Overview (Read & Rank)

For every row with a non-blank `quote_text`, show:

| Politician | Topic | Quote (de-identified) | De-id OK? |
|-----------|-------|----------------------|-----------|
| Name 1 | healthcare | "..." | yes / NEEDS MANUAL DE-ID (blank) |

For each (politician, topic) that ALREADY has quote(s) in `essentials.quotes`, show the
existing de-identified quote vs the new one and ask which should be the Read & Rank pick
(`readrank_selected`). Default: keep the current selection.

Rows where `quote_text` is present but `quote_deidentified` is blank are recorded as
library quotes but are NOT eligible to be the Read & Rank pick.

Then ask:
> "Review the stances above. You can:
> 1. **Approve all** — push stances AND quotes to the database
> 2. **Reject specific rows** — tell me which politician/topic pairs to remove
> 3. **Edit values** — tell me which rows to change (e.g., 'change Sherman/healthcare to 3')
> 4. **Skip DB push** — keep the CSV only, don't write to database
>
> What would you like to do?"

---

## STEP 4 — Push to Database

For each approved row, push to the database in two steps:

### 4a. Resolve IDs

Look up `politician_id` and `topic_id`:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT p.id as politician_id, p.full_name,
         t.id as topic_id, t.title as topic_title
  FROM essentials.politicians p
  CROSS JOIN inform.compass_topics t
  WHERE (
    lower(p.full_name) = ANY(SELECT lower(n) FROM unnest(\$1::text[]) AS n)
    OR EXISTS (
      SELECT 1 FROM unnest(p.alternate_names) AS alt
      WHERE lower(alt) = ANY(SELECT lower(n) FROM unnest(\$1::text[]) AS n)
    )
  )
    AND t.is_live = true
  ORDER BY p.full_name, t.created_at
\`, [process.argv.slice(2)]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "Name1" "Name2"
```

If a politician name doesn't match any row in `essentials.politicians`, report it:
> "Could not find '[NAME]' in the politicians table. Their CSV data is preserved but won't be pushed to DB. You may need to create this politician first via the admin panel."

### 4b. Upsert answers and context

For each matched row, call the admin service functions via a script:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';

const stances = JSON.parse(process.argv[2]);

await pool.query('BEGIN');
try {
  for (const s of stances) {
    // Upsert politician answer
    await pool.query(\`
      INSERT INTO inform.politician_answers (politician_id, topic_id, value)
      VALUES (\$1, \$2, \$3)
      ON CONFLICT (politician_id, topic_id)
      DO UPDATE SET value = EXCLUDED.value
    \`, [s.politician_id, s.topic_id, s.value]);

    // Upsert politician context (reasoning + sources)
    const sources = [s.source_url_1, s.source_url_2, s.source_url_3].filter(Boolean);
    await pool.query(\`
      INSERT INTO inform.politician_context (politician_id, topic_id, reasoning, sources)
      VALUES (\$1, \$2, \$3, \$4)
      ON CONFLICT (politician_id, topic_id)
      DO UPDATE SET reasoning = EXCLUDED.reasoning, sources = EXCLUDED.sources
    \`, [s.politician_id, s.topic_id, s.reasoning, sources]);
  }
  await pool.query('COMMIT');
  console.log('Done: ' + stances.length + ' stances upserted');
} catch (err) {
  await pool.query('ROLLBACK');
  console.error('Rolled back due to error:', err.message);
  process.exit(1);
}
await pool.end();
" '[JSON_ARRAY_OF_RESOLVED_STANCES]'
```

### 4d. Push quotes to essentials.quotes (Read & Rank)

For each approved, name-resolved row, build a quote object:

```
{
  politician_id, topic_key,            // topic_key lowercased
  quote_text, quote_deidentified,      // from the CSV; may be blank
  source_url,                          // first non-blank source_url_1..3, else null
  full_name,                           // carried through for the leak-check
  make_selected                        // boolean decided at STEP 3 (true for the chosen RR pick)
}
```

Only include objects whose `quote_text` is non-blank. Then run:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const quotes = JSON.parse(process.argv[2]);
let inserted = 0, dupes = 0, selected = 0; const leaks = [];
await pool.query('BEGIN');
try {
  for (const x of quotes) {
    const tk = x.topic_key.toLowerCase();
    const { rows: dup } = await pool.query(
      'SELECT id FROM essentials.quotes WHERE politician_id=\$1 AND lower(topic_key)=\$2 AND quote_text=\$3',
      [x.politician_id, tk, x.quote_text]
    );
    let quoteId;
    if (dup.length) { quoteId = dup[0].id; dupes++; }
    else {
      const sourceName = x.source_url ? (()=>{ try { return new URL(x.source_url).hostname; } catch { return null; } })() : null;
      const { rows: ins } = await pool.query(
        'INSERT INTO essentials.quotes (politician_id, topic_key, quote_text, deidentified_text, source_url, source_name) VALUES (\$1,\$2,\$3,\$4,\$5,\$6) RETURNING id',
        [x.politician_id, tk, x.quote_text, x.quote_deidentified || null, x.source_url || null, sourceName]
      );
      quoteId = ins[0].id; inserted++;
    }
    if (x.make_selected) {
      if (!x.quote_deidentified) { leaks.push(x.politician_id + '/' + tk + ': no de-id text, cannot select'); continue; }
      const surname = (x.full_name || '').trim().split(/\s+/).pop();
      if (surname && new RegExp('\\\\b' + surname.replace(/[.*+?^\${}()|[\\]\\\\]/g,'\\\\\$&') + '\\\\b','i').test(x.quote_deidentified)) {
        leaks.push(x.politician_id + '/' + tk + ': surname leak, not selected'); continue;
      }
      await pool.query('UPDATE essentials.quotes SET readrank_selected=false WHERE politician_id=\$1 AND lower(topic_key)=\$2', [x.politician_id, tk]);
      await pool.query('UPDATE essentials.quotes SET readrank_selected=true WHERE id=\$1', [quoteId]);
      selected++;
    }
  }
  await pool.query('COMMIT');
  console.log(JSON.stringify({ inserted, dupes, selected, leaks }, null, 2));
} catch (e) { await pool.query('ROLLBACK'); console.error('Rolled back:', e.message); process.exit(1); }
await pool.end();
" '[JSON_ARRAY_OF_QUOTE_OBJECTS]'
```

The `full_name` field is required on each object for the surname leak-check; carry it
through from the resolved row.

### 4c. Report results

After DB push:
> "Pushed [N] stances to the database for [politician names].
> - [N] politician_answers upserted
> - [N] politician_context entries with reasoning and sources
> - CSV preserved at: [file path]
>
> Skipped: [list any unmatched politicians or rejected rows]
>
> Quotes: [inserted] inserted, [dupes] already present, [selected] set as the Read & Rank pick.
> Held back (no de-id / surname leak): [leaks list]
> Reminder: a race becomes playable in Read & Rank only when ≥2 candidates in it each have
> a readrank_selected de-identified quote on a live topic."

---

## ERROR HANDLING

- If an agent fails or times out, report which politician failed and offer to retry just that one
- If the CSV file can't be written, fall back to showing results in conversation and offer to retry the file write
- If DB push fails for a specific row, report the error, skip that row, and continue with the rest
- Never lose data — the CSV is the source of truth; DB push is additive

---

# REWRITE RE-EVALUATION MODE (`--rewrite-id`)

When `$ARGUMENTS` includes `--rewrite-id <uuid>`, the skill runs in a
different mode that feeds the Plan D topic rewrite workflow
(`inform.topic_rewrites` / `inform.topic_rewrite_stance_proposals`)
instead of pushing directly to live data.

In this mode, the skill:

1. Skips the normal politician-name input — the politician list
   comes from `topic_rewrite_stance_proposals` rows already seeded
   for the rewrite.
2. Fetches BOTH the old and new topic framing and passes them to
   the agent so each politician gets re-scored under the new scale.
3. Pushes proposed values to `admin_upsert_stance_proposal` instead
   of direct inserts on `politician_context`.
4. Auto-approves each proposal via `admin_approve_stance_proposal`
   (the workflow's human gate is intentionally bypassed by
   auto-approval — the audit trail in `topic_rewrites` provides
   rollback safety).
5. Skips the STEP 3 approval summary prompt (nothing to approve —
   everything auto-approves).

## STEP 0 (rewrite mode) — Parse and fetch rewrite detail

Parse `$ARGUMENTS` for `--rewrite-id <uuid>`. If present, switch to
rewrite mode and IGNORE the politician-name and `--topics` args.

Fetch the rewrite detail including old and new framing, plus the
pending proposals queue:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const rewriteId = process.argv[2];
const { rows: detail } = await pool.query(\`
  SELECT r.*,
         ot.title AS old_title, ot.question_text AS old_question_text, ot.version AS old_version,
         nt.title AS new_title, nt.question_text AS new_question_text, nt.version AS new_version
  FROM inform.topic_rewrites r
  JOIN inform.compass_topics ot ON ot.id = r.old_topic_id
  JOIN inform.compass_topics nt ON nt.id = r.new_topic_id
  WHERE r.id = \$1
\`, [rewriteId]);
const { rows: oldStances } = await pool.query(
  'SELECT value, text FROM inform.compass_stances WHERE topic_id=\$1 ORDER BY value',
  [detail[0].old_topic_id]
);
const { rows: newStances } = await pool.query(
  'SELECT value, text FROM inform.compass_stances WHERE topic_id=\$1 ORDER BY value',
  [detail[0].new_topic_id]
);
const { rows: proposals } = await pool.query(\`
  SELECT p.politician_id, p.old_value, p.old_reasoning, p.old_sources, p.status,
         pol.full_name, o.title AS office_title, c.name AS chamber_name
  FROM inform.topic_rewrite_stance_proposals p
  JOIN essentials.politicians pol ON pol.id = p.politician_id
  LEFT JOIN essentials.offices o ON o.politician_id = pol.id AND o.is_current = true
  LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
  WHERE p.rewrite_id = \$1 AND p.status = 'pending'
  ORDER BY pol.full_name
\`, [rewriteId]);
console.log(JSON.stringify({ rewrite: detail[0], oldStances, newStances, proposals }, null, 2));
await pool.end();
" -- "REWRITE_ID_HERE"
```

Confirm with the user before dispatching agents:
- Topic being rewritten (`topic_key` and old→new version)
- New framing (title, question_text, 5 stance texts)
- Old framing for context
- Count of politicians to re-evaluate (= count of pending proposals)
- Estimated scope ("~30 politicians × 1 topic = 30 re-evaluations")

## STEP 1 (rewrite mode) — Dispatch re-evaluation agents

For each politician with a pending proposal (batch size 3–5 per
agent to keep context manageable), dispatch a
`politician-stance-researcher` agent.

**Dispatch prompt template for re-evaluation:**

```
You are running in REWRITE RE-EVALUATION MODE.

A compass topic has been rewritten with new framing. You need to
re-score each listed politician's stance under the new scale. Their
old stance under the old scale is provided as context — use it to
understand their position, then map that position onto the new scale.

## Topic key
[TOPIC_KEY, e.g. ai-regulation]

## OLD framing (what the politician was originally scored against)
Question: [old_question_text]
Stance scale:
  1 = [old_stance_1]
  2 = [old_stance_2]
  3 = [old_stance_3]
  4 = [old_stance_4]
  5 = [old_stance_5]

## NEW framing (what you're scoring against now)
Question: [new_question_text]
Stance scale:
  1 = [new_stance_1]
  2 = [new_stance_2]
  3 = [new_stance_3]
  4 = [new_stance_4]
  5 = [new_stance_5]

## Politicians to re-evaluate

For each politician below, you have their prior stance, prior
reasoning, and prior sources. Your task is to produce a NEW value,
NEW reasoning, and NEW sources under the new scale.

[For each politician in the batch, include:]
### [full_name] ([office_title], [chamber_name])
- Prior value under old scale: [old_value]
- Prior reasoning: [old_reasoning]
- Prior sources: [old_sources joined]

## Instructions

- Prefer mapping the prior evidence onto the new scale — that's the
  fastest path when the new framing is a generalization or
  reframing of the old one.
- Only do fresh research if the new framing asks about something the
  old research didn't cover (e.g., new framing includes a dimension
  the old scale ignored). Note in reasoning when you added evidence.
- Your new reasoning MUST explicitly reference the new scale. Write
  as if explaining to someone looking at the new question/stances
  for the first time. Do not reference the old scale.
- If a politician's position genuinely spans two new stances, pick
  the better match and note the ambiguity in reasoning.
- If you cannot score a politician under the new framing with
  available evidence, output value=null and note in reasoning why.
  Do NOT guess.

## Output format

For each politician, produce one CSV row:

full_name,politician_id,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3

Write to --output-file [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/YYYY-MM-DD-rewrite-[TOPIC_KEY].csv

Important: The politician_id column is new in this mode — include
the UUID from the batch input for each row.
```

## STEP 2 (rewrite mode) — Collect results (same as normal mode)

Same as STEP 2 in normal mode, just with politician_id column.

## STEP 3 (rewrite mode) — SKIPPED

No approval prompt. In rewrite mode, the workflow auto-approves
every proposal. The audit trail lives in the `topic_rewrites` table
and every change is reversible (old topic row stays with
is_live=false for easy rollback).

## STEP 4 (rewrite mode) — Push proposals + auto-approve

For each re-evaluated row, call TWO RPCs in sequence:

### 4a. Upsert the proposal

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const rewriteId = process.argv[2];
const stances = JSON.parse(process.argv[3]);
for (const s of stances) {
  if (s.value === null || s.value === undefined) {
    console.log('SKIP ' + s.full_name + ': no value (insufficient evidence)');
    continue;
  }
  const sources = [s.source_url_1, s.source_url_2, s.source_url_3].filter(Boolean);
  // Upsert via the RPC (SECURITY DEFINER handles schema access)
  await pool.query(\`
    SELECT inform.admin_upsert_stance_proposal(\$1::uuid, \$2::uuid, \$3::numeric, \$4::text, \$5::text[])
  \`, [rewriteId, s.politician_id, s.value, s.reasoning, sources]);
  console.log('UPSERT ' + s.full_name + ' value=' + s.value);
}
await pool.end();
" -- "REWRITE_ID" '[JSON_ARRAY]'
```

### 4b. Auto-approve each proposal

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const rewriteId = process.argv[2];
const actorId = process.argv[3];  // user id running the rewrite
const politicianIds = JSON.parse(process.argv[4]);
for (const pid of politicianIds) {
  try {
    await pool.query(\`
      SELECT inform.admin_approve_stance_proposal(\$1::uuid, \$2::uuid, \$3::uuid, \$4::text)
    \`, [rewriteId, pid, actorId, 'auto-approved by research-stances rewrite mode']);
    console.log('APPROVE ' + pid);
  } catch (e) {
    console.log('SKIP ' + pid + ': ' + e.message);
  }
}
await pool.end();
" -- "REWRITE_ID" "ACTOR_USER_ID" '[JSON_POLITICIAN_IDS]'
```

Note on `actorId`: this is a Supabase user id needed by the RPC for
audit logging. The orchestrator (not the skill) supplies it — use
the same id that created the rewrite.

### 4c. Report results

```
## Rewrite re-evaluation complete: [topic_key]

- Rewrite ID: [uuid]
- Politicians re-evaluated: [N]
- Proposals approved: [N]
- Skipped (insufficient evidence): [list]

The rewrite is now ready for publish_ready + publish. The
orchestrator will run `admin_mark_rewrite_publish_ready` and
`admin_publish_topic_rewrite` to complete the workflow.
```

The skill stops here in rewrite mode. The orchestrating
conversation (not the skill itself) is responsible for calling
`admin_mark_rewrite_publish_ready` + `admin_publish_topic_rewrite`
afterward — that way the human/AI running the rewrite can inspect
the proposals table between auto-approval and publish if desired,
even though the normal path is to publish immediately.
