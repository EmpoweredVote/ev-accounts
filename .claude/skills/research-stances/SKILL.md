---
name: research-stances
description: "Research politician stances on compass topics. Use when the user wants to research, look up, or generate stance data for politicians on Empowered Vote policy topics (national, state, and local city-level). Produces a reviewable CSV and optionally pushes approved stances to the database. Triggers on: 'research stances', 'look up stances', 'politician positions', 'stance data for', 'compass research'."
argument-hint: "\"Politician Name(s)\" [--topics topic1,topic2] "
---

# /research-stances — Politician Stance Research Orchestrator

You are running the **research-stances** skill. Your job is to research politician stances on existing Empowered Vote compass topics, produce a reviewable CSV, and optionally push approved data to the database.

> **Related:** if this work involves candidate *quotes* (for Read & Rank / Compass / Essentials),
> follow the curation principles in `../on-the-record/.claude/skills/audit-quotes/CHECKS.md` (the
> checks + the §4 judgment rules — the working rulebook) and
> `../on-the-record/.claude/skills/publish-quotes/EDITORIAL.md` (editing/de-id mechanics), and hand
> quotes off to the `audit-quotes` skill before they go live (see STEP 4). The canonical source is
> the on-the-record corpus, docs/quote-curation/PRINCIPLES.md (sibling checkout:
> ../on-the-record/docs/quote-curation/PRINCIPLES.md) — read it alongside CHECKS.md §4 as the
> rulebook.

> **Quotes are pushed as DRAFTS, then audited, then promoted.** This skill never sets a quote live
> in the same step it inserts it. The flow is: research → pre-push QA → insert as drafts
> (`readrank_selected=false`) → `audit-quotes --include-drafts` → promote the Read & Rank picks to
> live only once the audit is clean (STEP 4).

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

## STEP 0.5 — On the Record Source Discovery (tier-1 sources)

**Do this BEFORE any web research.** On the Record (the sibling transcript platform) already holds
speaker-attributed transcripts for many races — debates, forums, and news interviews. These are the
**strongest** stance/quote source we have (verbatim, timestamped, attributed to the candidate) and
they are what the `audit-quotes` source check verifies against. Skipping them was a real failure: a
prior CA-Governor run used WebFetch/Ballotpedia only and missed **18 of 21** available OTR sources.

If the politicians belong to a race, resolve the `race_id` and pull the transcripts first:

```bash
# Resolve the race_id from the candidate names (skip if the user already gave you a --race id)
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT rc.race_id::text, r.position_name, count(*)::int AS n_candidates
  FROM essentials.race_candidates rc
  JOIN essentials.races r ON r.id = rc.race_id
  JOIN essentials.politicians p ON p.id = rc.politician_id
  WHERE lower(p.full_name) = ANY(SELECT lower(n) FROM unnest(\$1::text[]) AS n)
  GROUP BY rc.race_id, r.position_name ORDER BY n_candidates DESC
\`, [process.argv.slice(2)]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "Name1" "Name2"
```

Then extract every candidate's speaker-attributed turns across the race's OTR sources:

```bash
node ev-accounts/.claude/skills/research-stances/scripts/extract-otr.mjs \
  --race <race_id> --names "Full Name 1,Full Name 2"
# writes one markdown file per candidate to
#   ev-accounts/backend/data/stance-research/otr-transcripts/<race_id>/<candidate>.md
# each source section is headed with its YouTube URL + OTR page URL (use these as source_url_1)
```

**Always pass `--names` with the candidates' DB `full_name`s.** Debate transcripts tag turns with a
`politicianSlug`, but news-interview transcripts attribute by `speakerName` only (slug is null) — and
those are often the majority of a race's sources. `--names` matches on speaker name (token-subset, so
"Karen Bass" matches the transcript's "Karen Ruth Bass"), which covers both. Without it the tool only
finds debate turns and silently misses every interview.

`extract-otr.mjs` uses the OTR public API only (no DB): `/api/people` (candidate names),
`/api/meetings` (the race's sources via `raceIds`), and paginated
`/api/meetings/{id}/transcript?page=N` (segments carry `speakerName` + `politicianSlug`). It prints
`OTR_SOURCES=<n> OTR_CANDIDATES=<n>` at the end.

- If `OTR_SOURCES=0`, the race isn't on the platform yet — fall back to web research (STEP 1 tiers).
- Pass each candidate's transcript file path into that candidate's research-agent prompt as the
  **tier-1 source** (below). The agent should draw verbatim quotes from it first, and only use
  WebFetch for topics the transcripts don't cover.
- Not a race (e.g. a single official)? Skip this step and go straight to web research.

---

## STEP 1 — Dispatch Research Agents

For each politician, dispatch a `politician-stance-researcher` agent using the Agent tool.

**Dispatch rules:**
- **Always dispatch ONE agent at a time.** Never run agents in parallel.
- Wait for each agent to complete and confirm the CSV was written before dispatching the next.
- Running parallel agents burns the WebSearch/Playwright rate limit quota instantly, producing no usable output.

**Inject the canonical curation rules (do not paraphrase them here).** Run

```bash
node .claude/skills/research-stances/scripts/extract-canonical-rules.mjs gates deid note
```

and paste its output into the sub-agent prompt below at the three `INJECT:` markers (`gates`, `deid`,
`note`). These rules come from the on-the-record corpus (sibling checkout; canonical home
`on-the-record/docs/quote-curation/PRINCIPLES.md` and its mechanics files) — never restate them from
memory. If the extractor errors, the on-the-record checkout is missing: **STOP** and resolve that, do
not fall back to a remembered summary.

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

TOPIC PRIORITY BY OFFICE LEVEL (attempt ALL topics; prioritize by level; skip only on no evidence):
Research every topic in scope — do NOT hard-skip a topic just because of the office level. But lead
with the topics that match this office's level and spend proportionally more effort there:
- City office (mayor, city council): lead with the city-level topics (transportation-priorities,
  economic-development, homelessness-response, residential-zoning, city-sanitation, local-immigration,
  rent-regulation, growth-and-development, local-environment, public-safety-approach, jail-capacity)
  and citywide issues (homelessness, housing). Still check the state/federal topics — a mayor often
  has a public record on climate, civil-rights, immigration, etc.
- State/federal office: lead with the statewide/national topics; the city-level topics rarely apply,
  but still check any where the candidate has a documented position.
Skip a topic ONLY when you genuinely cannot find sufficient evidence — never skip by assumption.

--output-file [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME].csv

TIER-1 SOURCE — READ THIS FIRST:
[If an OTR transcript file was produced in STEP 0.5, include:]
Your PRIMARY source is this On the Record transcript file (verbatim, timestamped, attributed to
this candidate across the race's debates/forums/interviews):
  [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/otr-transcripts/<race_id>/<candidate>.md
Read it with the Read tool and draw your quotes from it FIRST. Every quote you take from it is
already verified to the source — cite that source's YouTube URL (shown in the file's section
header) as source_url_1. Only use WebFetch for topics the transcript does not cover.

TOOL RULE:
- Prefer the OTR transcript file above (Read tool) — it is the strongest, pre-verified source.
- For anything it doesn't cover, use WebFetch ONLY. Never use WebSearch or Playwright — both share a
  rate-limited quota pool. Fetch URLs directly using the patterns in your agent definition
  (Ballotpedia, ontheissues.org, official pages, Wikipedia, CalMatters, LA Times). If a URL 404s, try
  the next pattern. Do not fall back to WebSearch.

CSV OUTPUT — columns (RFC-4180; wrap any field with commas in double quotes, double embedded quotes):
  full_name,topic_key,value,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified,editor_note
- editor_note: REQUIRED for every row with a quote_text; essentials.quotes requires it and the audit
  hard-fails without it — see EDITOR NOTE RULE below for what it must contain.

QUOTE-SELECTION GATES + RANKING QUESTION + DIFFERENTIATION:
[INJECT: gates]

DE-IDENTIFICATION CONTRACT:
[INJECT: deid]

EDITOR NOTE RULE:
[INJECT: note]

Other rules:
- Skip any topic where you cannot find sufficient evidence
- Every source URL must be real and verifiable — only include URLs you actually fetched successfully
  (OTR YouTube URLs from the transcript file count as verified)
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
5. The CSV includes `quote_text`, `quote_deidentified`, and `editor_note` columns. Parse the CSV with a real RFC-4180 parser (`csv-parse/sync`), never by splitting on commas — these columns contain commas and embedded quotes. Verify every row that has a `quote_text` also has a non-blank `editor_note` (the DB requires it and the audit hard-fails without it); if any are missing, draft them before STEP 4 or send the row back.

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

### Value-Change Guard (diff proposed vs. existing)

**Before pushing any stance value, diff it against what's already in the DB.** Changing a value that
was already curated is a bigger deal than filling in a blank one — a prior run pushed a
party-inferred value change (Hilton redistricting 4→2) that should have been held for a human. Pull
the current values and compare:

🔴 **DIFF AGAINST THE OPEN SEASON, NOT AGAINST EVERY SEASON.** The push in step 4c writes into the
open season, and its `ON CONFLICT` replaces that season's row. So "what am I about to overwrite?" is
a question about the open season alone. Without the `status = 'open'` join this query returns **one
row per season per topic** the moment Season 2 exists — the same politician and topic listed twice
with different values, which makes the guard that exists to prevent silent overwrites ambiguous
exactly when it matters.

`prior_value` is shown alongside, and it is **context, not the thing you are overwriting**: it is
what this person last said in an *earlier* season. A row with a blank `existing_value` and a filled
`prior_value` is a NEW answer for this season, not a change — treat it as NEW.

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT p.full_name, t.topic_key,
         open_a.value  AS existing_value,   -- the row step 4c will overwrite
         prior.value   AS prior_value,      -- what they last said, earlier season
         prior.number  AS prior_season
  FROM essentials.politicians p
  CROSS JOIN inform.compass_topics t
  LEFT JOIN LATERAL (
    SELECT a.value
      FROM inform.politician_answers a
      JOIN inform.seasons s ON s.id = a.season_id AND s.status = 'open'
     WHERE a.politician_id = p.id AND a.topic_id = t.id
  ) open_a ON true
  LEFT JOIN LATERAL (
    -- Newest answered season that is NOT the open one. LATERAL … LIMIT 1, never
    -- a plain join: joining on (politician_id, topic_id) returns a row per
    -- season and fans the result out.
    SELECT a.value, s.number
      FROM inform.politician_answers a
      JOIN inform.seasons s ON s.id = a.season_id AND s.status <> 'open'
     WHERE a.politician_id = p.id AND a.topic_id = t.id
     ORDER BY s.number DESC
     LIMIT 1
  ) prior ON true
  WHERE lower(p.full_name) = ANY(SELECT lower(n) FROM unnest(\$1::text[]) AS n)
    AND (open_a.value IS NOT NULL OR prior.value IS NOT NULL)
  ORDER BY p.full_name, t.topic_key
\`, [process.argv.slice(2)]);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
" -- "Name1" "Name2"
```

Show the user a diff table and split the rows into three buckets:

| Politician | Topic | Existing | Proposed | Bucket |
|---|---|---|---|---|
| Name | topic | (none) | 3 | **NEW** — safe to push with approval |
| Name | topic | 2 | 2 | unchanged — no-op |
| Name | topic | 4 | 2 | **CHANGE — HOLD for explicit sign-off** |

- **NEW** (no existing value): push with the normal approval.
- **unchanged**: no-op, skip the write.
- **CHANGE** (existing ≠ proposed): do **NOT** push automatically. List each one with the CSV
  reasoning and its supporting quote, and get explicit per-row sign-off. If the change was inferred
  from party rather than a documented quote, flag it as such.

**The public summary MUST move with the value.** `politician_context.reasoning` is the "here's how we
got to this value" blurb shown on the candidate's **Essentials profile** and the **Compass** — it is
public-facing. Whenever you push a value (NEW or CHANGE), you MUST write/replace the reasoning so it
justifies the value being stored, in plain language a voter can trust. Never change a value and leave
a stale reasoning that describes the old position, and never leave the reasoning blank. After any
value CHANGE, re-read the stored reasoning and confirm it (a) describes the new value's position and
(b) doesn't still argue the old one — a value/summary mismatch is a trust defect, not a cosmetic one.
(This mirrors the quote↔value coupling check: the summary is coupled to the value just as the quote is.)

### Quote Overview (Read & Rank)

For every row with a non-blank `quote_text`, show:

| Politician | Topic | Quote (de-identified) | Gates | De-id OK? |
|-----------|-------|----------------------|-------|-----------|
| Name 1 | healthcare | "..." | fwd ✓ / on-q ✓ / not-attack ✓ | yes / NEEDS MANUAL DE-ID (blank) |

**Gates** = the three quote-selection gates from STEP 1 (forward-not-record, on-question,
position-not-personal-attack). Any quote that fails a gate should be dropped as a quote (the stance
value can still push from the record); flag it rather than pushing it. **De-id OK?** = passed the
de-identification contract (no surname / partisan tell / self-ID leak, honest `…`/`[bracket]`
marking). Run `scripts/build-and-check.mjs` (STEP 4a) to catch the mechanical de-id/note failures
before you get here.

For each (politician, topic) that ALREADY has quote(s) in `essentials.quotes`, show the
existing de-identified quote vs the new one and ask which should be the Read & Rank pick
(`readrank_selected`). Default: keep the current selection.

Rows where `quote_text` is present but `quote_deidentified` is blank are recorded as
library quotes but are NOT eligible to be the Read & Rank pick.

Then ask:
> "Review the stances above. Note: approved quotes are pushed as **drafts** and only promoted to
> live after the quote audit is clean (STEP 4). You can:
> 1. **Approve all** — run the pre-push QA, then push stances + quotes as drafts, audit, and promote picks
> 2. **Reject specific rows** — tell me which politician/topic pairs to remove
> 3. **Edit values** — tell me which rows to change (e.g., 'change Sherman/healthcare to 3')
> 4. **Skip DB push** — keep the CSV only, don't write to database
>
> What would you like to do?"

---

## STEP 4 — QA → Push as Drafts → Audit → Promote

Quotes go through a pipeline, never a single write. The order is: **(4a)** pre-push QA over the CSV,
**(4b–4d)** push approved stances + quotes as **drafts**, **(4e)** hand off to the `audit-quotes`
skill, **(4f)** promote the Read & Rank picks to live only once the audit is clean.

### 4a. Pre-push QA (before any write)

**(i) Mechanical + bundle.** Run the checker over the CSV — it builds the audit context bundle
(topics → quotes with stance + editor_note + de-id) and runs the deterministic checks
(note-missing, note-section-ref, note-too-long, deid-missing, trailing-ellipsis, partisan-tell,
invalid-source, unquotable-source, scorecard-source, pointer-only-source, stance-label). There is no
campaign-site URL check: a campaign page is judged on how directly it answers the question, not on
its medium, so that call belongs to the judgment pass below (`source-not-an-answer`).

```bash
cd ev-accounts/backend && node ../.claude/skills/research-stances/scripts/build-and-check.mjs \
  --csv data/stance-research/YYYY-MM-DD-[BATCH_NAME].csv
# prints "MECHANICAL FINDINGS: N (high=.. medium=.. low=..)" and writes <csv>.bundle.json
# exits non-zero if any high-severity finding remains.
```

Fix every **high** finding in the CSV (write the missing `editor_note`, de-identify honestly, strip
the trailing ellipsis, neutralize the partisan tell, re-source an aggregator / quiz / scorecard row to
the original) and re-run until it's clean. A `pointer-only-source` row (VOTE411 / thevoterguide.org)
cannot be cited at all — LWV terms bar reproducing it — so re-source the position to the candidate's
own materials, or drop the quote if VOTE411 is the only place it appears. Do not push a CSV with
high-severity mechanical findings.

**(ii) Judgment sub-agent.** Dispatch one `Agent`-tool sub-agent per candidate (or per race) using
the **audit-quotes CHECKS.md §4 judgment prompt** (`../on-the-record/.claude/skills/audit-quotes/CHECKS.md`),
passing the `<csv>.bundle.json` produced above. It returns a JSON array of judgment findings
(`not-forward`, `is-attack`, `off-question`, `question-override`, `deid-dishonest`,
`note-not-self-contained`, `source-summary`, `coupling-in-tension`, `non-differentiating-goal`,
`source-not-an-answer`, `misleading-verbatim`). Resolve them:
- `not-forward` / `off-question` / `is-attack` → drop the quote (keep the stance value from the
  record); a `coupling-in-tension` → surface to the user with the value-change guard.
- `question-override` → should not fire here: this bundle carries only the Compass question, never
  a per-race override. If it does, surface it to the user; overrides are checked in the 4e audit.
- `deid-dishonest` / `note-not-self-contained` → fix the CSV field, re-run 4a(i), and continue.
- `source-summary` → replace the bullet or paraphrase with a sentence the candidate actually wrote
  in that source. If the source has none, drop the quote.
- `misleading-verbatim` → restore the qualifier or context the trim removed, or drop the quote if
  no trim of the passage reads true on the blind card. Being verbatim does not excuse it.
- `non-differentiating-goal` → surface to the user. The quote names a goal, a target or a
  direction but no means, so do not promote it to live (4f) unless the user affirms it carries a
  real distinguishing position.
- `source-not-an-answer` → look for a more direct answer (a questionnaire or interview answer to
  this question). If none exists, keep the quote: a curator-extracted quote may be all a candidate
  has, and that is honest presence, not a defect.
Only quotes that clear both passes proceed to the push.

### 4b. Resolve IDs

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

### 4c. Upsert answers and context

Push values only for the **NEW** and **explicitly-approved CHANGE** rows from the STEP 3
value-change guard — never silently overwrite an already-curated value. The upsert below writes the
answer (`value`) and the context (`reasoning` + `sources`) **together** — this is deliberate:
`reasoning` is the public "here's why" summary on the Essentials profile and Compass, so it must
never lag the value. Confirm every row you push has a non-blank reasoning that matches its value
before running the script. For each matched row, call the admin service functions:

🔴 **A STANCE IS WRITTEN INTO A SEASON. DO NOT HAND-ROLL THIS SQL.** An answer records a rung *of a
specific ladder text*, so `inform.politician_answers` carries a `season_id` and a
`topic_revision_id`, both `NOT NULL`, and `politician_answers_pin_fkey` requires the pair to match a
row in the open season's question set. Import the shared write shape from `seasonService` — it
resolves the open season and that season's pinned revision **in the same statement**, so the season
cannot close between reading it and writing.

⚠️ **The block below replaced a bare `INSERT … (politician_id, topic_id, value)` that had worked for
a year.** After the season model shipped, that INSERT failed against prod with
`23502: null value in column "season_id" … violates not-null constraint` — both for the answer and
for the context. It failed loudly and rolled back, so nothing was corrupted, but this whole step was
dead until 2026-08-27. Its `ON CONFLICT (politician_id, topic_id)` was a second, quieter bug: the
primary key is now `(politician_id, topic_id, season_id)`, and the bare pair still resolves only
because a temporary scaffolding index is up. That index is dropped before Season 2 opens, and the
old form then fails with `42P10`. **If you find yourself writing either of those, stop.**

🔴 **`assertWritten` IS NOT OPTIONAL.** The upsert sources its `INSERT` from
`season_questions JOIN seasons … status = 'open'`. If no season is open, the SELECT yields no rows,
**nothing is written, and nothing raises.** A push that skips the row-count check reports success
having saved nothing. `assertWritten` turns that silence into an error naming which of the two causes
it was — no open season, or this topic is not in the open season's question set.

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
import {
  UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL, assertWritten,
} from './src/lib/seasonService.js';

const stances = JSON.parse(process.argv[2]);

// The editor of record for this push. NULL is allowed by the schema, but a
// stance with no attributable editor is a row nobody can be asked about later.
// Pass the admin user id doing the research.
const editorId = process.env.EV_EDITOR_ID ?? null;

await pool.query('BEGIN');
try {
  for (const s of stances) {
    // Season-aware upsert. The pin comes from the season, never from us.
    // Param order: politician_id, topic_id, value, editor_id.
    const ans = await pool.query(UPSERT_ANSWER_SQL,
      [s.politician_id, s.topic_id, s.value, editorId]);
    await assertWritten(ans.rowCount ?? 0, s.topic_id);

    // Answer and context are written together on purpose — reasoning is the
    // public 'here's why' and must never lag the value.
    // Param order: politician_id, topic_id, reasoning, sources, editor_id.
    const sources = [s.source_url_1, s.source_url_2, s.source_url_3].filter(Boolean);
    const ctx = await pool.query(UPSERT_CONTEXT_SQL,
      [s.politician_id, s.topic_id, s.reasoning, sources, editorId]);
    await assertWritten(ctx.rowCount ?? 0, s.topic_id);
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

**Which season did this land in?** Whichever one is open. Today that is Season 1, so new research
sits alongside the pre-seasons corpus with nothing in the row distinguishing the two. When Season 2
opens, work pushed before the changeover stays in Season 1 and **remains readable** — reads follow
the person, not the calendar — while new pushes go to Season 2. A politician researched in Season 1
but not in Season 2 still shows their Season 1 stances. See
[`docs/adr/0005-compass-question-seasons.md`](../../../docs/adr/0005-compass-question-seasons.md).

⚠️ **`backend/scripts/apply-*-stances.ts` are NOT templates.** Around 158 of them still contain the
old bare-pair upsert. They already ran, so they are harmless where they sit — but copying one gives
you the broken form above. Copy from this block instead.

### 4d. Push quotes to essentials.quotes — as DRAFTS

Every quote is inserted with `readrank_selected=false` and its `editor_note`. **Nothing is promoted
to live here** — promotion happens in 4f, after the audit. For each approved, name-resolved,
gate-passing row build a quote object:

```
{
  politician_id, topic_key,            // topic_key lowercased
  quote_text, quote_deidentified,      // from the CSV; deid may be blank (library-only quote)
  editor_note,                         // REQUIRED — from the CSV; QA at 4a guarantees it's present
  source_url,                          // first non-blank source_url_1..3, else null
  full_name                            // carried through for the pre-select leak-check at 4f
}
```

Only include objects whose `quote_text` is non-blank. Then run:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const quotes = JSON.parse(process.argv[2]);
let inserted = 0, dupes = 0; const missingNote = [];
await pool.query('BEGIN');
try {
  for (const x of quotes) {
    const tk = x.topic_key.toLowerCase();
    if (!x.editor_note || !x.editor_note.trim()) { missingNote.push(x.full_name + '/' + tk); continue; }
    const { rows: dup } = await pool.query(
      'SELECT id FROM essentials.quotes WHERE politician_id=\$1 AND lower(topic_key)=\$2 AND quote_text=\$3',
      [x.politician_id, tk, x.quote_text]
    );
    if (dup.length) { dupes++; continue; }
    const sourceName = x.source_url ? (()=>{ try { return new URL(x.source_url).hostname; } catch { return null; } })() : null;
    await pool.query(
      'INSERT INTO essentials.quotes (politician_id, topic_key, quote_text, deidentified_text, source_url, source_name, editor_note, readrank_selected) VALUES (\$1,\$2,\$3,\$4,\$5,\$6,\$7,false)',
      [x.politician_id, tk, x.quote_text, x.quote_deidentified || null, x.source_url || null, sourceName, x.editor_note]
    );
    inserted++;
  }
  await pool.query('COMMIT');
  console.log(JSON.stringify({ inserted, dupes, missingNote }, null, 2));
} catch (e) { await pool.query('ROLLBACK'); console.error('Rolled back:', e.message); process.exit(1); }
await pool.end();
" '[JSON_ARRAY_OF_QUOTE_OBJECTS]'
```

If `missingNote` is non-empty, those rows were skipped — write their editor_note and re-run.

### 4e. Hand off to the audit-quotes skill

With the drafts in place, run the real quote audit (it adds YouTube source-verification against the
ingested OTR transcripts — the check the mechanical pass can't do):

```bash
cd ../on-the-record/.claude/skills/audit-quotes && \
  ../../../.venv/bin/python -m scripts.audit --race <race_id> --include-drafts
```

Then run the judgment fan-out and portfolio pass per the `audit-quotes` SKILL.md, and resolve
residual findings with `scripts/apply_fixes.py fixes.json` (dry-run first, show the diff, `--commit`
only after the user OKs). Never auto-apply `decision-required` findings — list them for the user.
A `source-unverified` finding usually means the quote is **mis-sourced** (wrong `source_url`); hunt
the true OTR source and re-cite it rather than dropping a genuine quote.

### 4f. Promote the Read & Rank picks to live (only after the audit is clean)

For each topic where a candidate should have a live pick, promote exactly one quote — but only once
4e is clean. Each promotion must pass a final leak-check on `deidentified_text` (no surname, no
partisan tell, no self-ID) and replaces any currently-selected quote on that topic:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const picks = JSON.parse(process.argv[2]);  // [{ id, full_name }]
let selected = 0; const leaks = [];
const PARTISAN = /\\\\b(Democrat|Democrats|Democratic|Republican|Republicans|GOP|MAGA)\\\\b/;
const SELFID = /\\\\b(as governor|as attorney general|as senator|when I was|my administration|I'm a legal|only person here)\\\\b/i;
await pool.query('BEGIN');
try {
  for (const p of picks) {
    const { rows } = await pool.query('SELECT politician_id::text, lower(topic_key) tk, deidentified_text d FROM essentials.quotes WHERE id=\$1', [p.id]);
    if (!rows.length) { leaks.push(p.id + ': not found'); continue; }
    const { politician_id, tk, d } = rows[0];
    if (!d) { leaks.push(p.id + ': no de-id text'); continue; }
    const surname = (p.full_name || '').trim().split(/\\\\s+/).pop();
    const surnameHit = surname && new RegExp('\\\\\\\\b' + surname.replace(/[.*+?^\${}()|[\\]\\\\]/g,'\\\\\\\\\$&') + '\\\\\\\\b','i').test(d);
    if (surnameHit || PARTISAN.test(d) || SELFID.test(d)) { leaks.push(p.id + ': leak in de-id, not promoted'); continue; }
    await pool.query('UPDATE essentials.quotes SET readrank_selected=false WHERE politician_id=\$1 AND lower(topic_key)=\$2', [politician_id, tk]);
    await pool.query('UPDATE essentials.quotes SET readrank_selected=true WHERE id=\$1', [p.id]);
    selected++;
  }
  await pool.query('COMMIT');
  console.log(JSON.stringify({ selected, leaks }, null, 2));
} catch (e) { await pool.query('ROLLBACK'); console.error('Rolled back:', e.message); process.exit(1); }
await pool.end();
" '[JSON_ARRAY_OF_PICKS]'
```

### 4g. Report results

After the pipeline:
> "Pushed [N] stances and [N] quote drafts for [politician names].
> - [N] politician_answers upserted (NEW + approved changes only; [M] held for sign-off)
> - [N] politician_context entries with reasoning and sources
> - Quotes: [inserted] inserted as drafts, [dupes] already present
> - Audit: [clean / residual findings resolved via apply_fixes]
> - Promoted to live: [selected] Read & Rank pick(s); held back (de-id leak): [leaks list]
> - CSV preserved at: [file path]
>
> Reminder: a race becomes playable in Read & Rank only when ≥2 candidates in it each have a
> readrank_selected de-identified quote on a live topic."

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
