---
name: compass-topic-builder
description: "Discover and create new compass topics with quality-checked stances. Use when the user wants to find new policy issues for a jurisdiction, create new compass topics, write stance scales, or expand the topic list beyond the current 21. Triggers on: 'new topic', 'new issue', 'discover issues', 'local issues', 'state issues', 'build topic', 'create stances', 'add compass topic'."
argument-hint: "\"Jurisdiction\" [--level local|state|federal] [--issue \"issue name\"] [--count N]"
---

# /compass-topic-builder — Compass Topic Discovery & Authoring

You are running the **compass-topic-builder** skill. Your job is to discover policy issues relevant to a jurisdiction or level of government, then craft complete compass topics with 5 quality-checked stances on a spectrum.

**Key principle:** Stances must be level-agnostic — broad enough that a city council member and a U.S. senator could both land somewhere on the same 5-point scale. Each stance must be a single, non-double-barreled policy position.

> **Related:** the `topic_key`/spectrum you build here is the shared unit between the Compass and
> Read & Rank quotes. See `essentials/docs/QUOTE-CURATION-PRINCIPLES.md` §7 (the quote↔stance
> coupling model — same topics, not necessarily the same axis).

---

## STEP 0 — Parse Input

Parse `$ARGUMENTS` for:
- **Jurisdiction**: positional argument (e.g., `"Bloomington, IN"`, `"California"`)
- **--level**: `local`, `state`, or `federal` (optional; inferred from jurisdiction if possible)
- **--issue**: a specific issue to skip discovery and go straight to authoring (optional)
- **--count**: how many issues to discover (optional; default 5)

If `$ARGUMENTS` is empty, ask:
> "What jurisdiction or issue would you like to explore? Examples:
> - A place: `'Bloomington, IN' --level local`
> - A state: `'California' --level state`
> - A specific issue: `--issue 'water infrastructure'`"

---

## STEP 1 — Load Existing Topics (Always)

Before discovery or authoring, fetch the current compass topics so you can deduplicate:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`
  SELECT t.id, t.title, t.short_title,
         array_agg(DISTINCT tr.role_scope) as role_scopes
  FROM inform.compass_topics t
  LEFT JOIN inform.compass_topic_roles tr ON tr.topic_id = t.id
  WHERE t.is_live = true
  GROUP BY t.id, t.title, t.short_title
  ORDER BY t.created_at
\`);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

Store these in memory for deduplication in later steps.

Also fetch existing categories:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query('SELECT id, title FROM inform.compass_categories ORDER BY title');
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

---

## STEP 2 — Issue Discovery

**Skip this step if `--issue` was provided.** Jump to STEP 3 with the provided issue.

### 2a. Research the jurisdiction

Use **WebSearch** to research policy issues in the jurisdiction. Run these searches:

1. `"[Jurisdiction] city council agenda 2025 2026 issues"` (for local)
2. `"[Jurisdiction] ballot measures 2025 2026"`
3. `"[Jurisdiction] local politics issues voters care about"`
4. `"[Jurisdiction] [state] legislature bills 2025 2026"` (for state)
5. `"[Jurisdiction] community concerns policy debate"`

For each promising result, use **WebFetch** to read the page content.

### 2b. Identify candidate issues

From your research, compile a list of potential issues. For each issue, evaluate:

1. **Voter relevance**: Do voters in this jurisdiction care about it?
2. **Policy lever**: Do politicians at this level have any control over it, even indirect?
   - Direct: city council sets zoning policy → zoning is a local issue
   - Indirect: city council can set ICE cooperation policy → immigration has a local lever
3. **Distinctness**: Is this meaningfully different from the existing compass topics?

### 2c. Deduplicate against existing topics

For each candidate issue, check against the existing topics you loaded in STEP 1:
- **Exact overlap**: "Healthcare costs" overlaps with existing "healthcare" topic → **skip** and note it
- **Local variant**: "City ICE cooperation" is a local variant of existing "deportation" topic → **flag** as a potential variant, but still worth discussing since the policy lever is different
- **New**: No existing topic covers this → **include**

### 2d. Present candidates

Show the user a ranked list:

```
## Discovered Issues for [Jurisdiction]

| # | Issue | Why It Matters Here | Closest Existing Topic | Policy Lever |
|---|-------|--------------------|-----------------------|-------------|
| 1 | Annexation Policy | Bloomington is debating annexing... | none | City council votes on annexation |
| 2 | Short-Term Rentals | Airbnb regulation is contentious... | housing (related) | City zoning ordinance |
| 3 | Public Transit Funding | Bus service cuts proposed... | none | City budget allocation |
| ... | ... | ... | ... | ... |
```

> "Which issues would you like me to develop into full compass topics? Enter the numbers (e.g., '1, 3') or 'all'."

---

## STEP 3 — Stance Authoring

For each selected issue (or the `--issue` provided directly):

### 3a. Draft topic metadata

Create:
- `title`: descriptive title (e.g., "Short-Term Rental Regulation")
- `short_title`: abbreviated form (e.g., "Short-Term Rentals")
- `question_text`: framed as an open-ended question (NOT yes/no). Examples: "How should government regulate short-term rental properties like Airbnb?", "What role should vouchers and school choice play in the public education system?", "What legal framework should govern abortion access?" — never use statement stems like "The government should..."
- `topic_key`: **MUST equal `lower(replace(short_title, ' ', '-'))`** — e.g., short_title "Short-Term Rentals" → topic_key `short-term-rentals`. This is critical: `essentials.quotes` joins on `topic_key`, so any mismatch silently hides quotes from ReadRank.
- `levels`: which jurisdiction levels this applies to — array from `["federal", "state", "local"]`

### 3b. Draft 5 stances

Write 5 stances on a spectrum:
- **Value 1** = most progressive/interventionist position
- **Value 2** = moderate-progressive position
- **Value 3** = centrist/balanced position
- **Value 4** = moderate-conservative position
- **Value 5** = most conservative/hands-off position

**Follow the pattern of existing stances.** Each stance should:
- Start with a verb or action phrase
- Be one sentence (two max if absolutely necessary)
- Be specific enough to be meaningful but broad enough to apply at any government level
- NOT reference a specific level of government (no "federal law", "state mandate", "city ordinance")

### 3c. Run Quality Gates

Run these three checks on every stance. Report results honestly.

#### Quality Gate 1: Double-Barrel Check

For each of the 5 stances, ask: **"Does this stance contain two independent policy positions that someone could agree with one but not the other?"**

| Stance | Verdict | Reasoning |
|--------|---------|-----------|
| Value 1: "..." | PASS / FAIL / BORDERLINE | Why |
| Value 2: "..." | PASS / FAIL / BORDERLINE | Why |
| ... | ... | ... |

- **FAIL** means the stance MUST be rewritten before presenting to the user. Split or simplify.
- **BORDERLINE** means flag it for the user's judgment. Explain the tension.
- **PASS** means the stance is a single policy position. Good.

If any stance FAILS, rewrite it and re-check before proceeding.

#### Quality Gate 2: Spectrum Coherence

Check:
- [ ] Stances 1 and 5 are genuine opposites (not just different intensities of the same direction)
- [ ] Stance 3 is a defensible middle ground (not vague filler like "balance competing interests")
- [ ] Progression from 1→5 is logically smooth (no jumps or reversals)
- [ ] Each stance is meaningfully different from its neighbors (no redundancy)

If any check fails, revise the stances.

#### Quality Gate 3: Level-Agnostic Language

Check each stance for government-level-specific language:
- [ ] No references to "federal", "state", "city", "county" in stance text
- [ ] No references to specific bodies ("Congress", "state legislature", "city council")
- [ ] Uses universal verbs: "ban", "require", "fund", "allow", "regulate", "prohibit"

If any stance uses level-specific language, rewrite it.

### 3d. Present for review

Show the complete topic:

```
## Proposed Topic: [Title]

**Question:** [question_text]
**Key:** `[topic_key]`
**Levels:** [federal] [state] [local]

| Value | Stance | Double-Barrel | Coherence | Level-Agnostic |
|-------|--------|--------------|-----------|---------------|
| 1 | [text] | PASS | OK | OK |
| 2 | [text] | PASS | OK | OK |
| 3 | [text] | PASS | OK | OK |
| 4 | [text] | BORDERLINE: [note] | OK | OK |
| 5 | [text] | PASS | OK | OK |
```

> "Review the topic above. You can:
> 1. **Approve** — save the draft and optionally push to database
> 2. **Edit** — tell me which stances to revise
> 3. **Reject** — skip this topic
>
> What would you like to do?"

---

## STEP 4 — Save Output

### 4a. Save JSON draft

Write the approved topic to `ev-accounts/backend/data/topic-drafts/YYYY-MM-DD-<topic-key>.json`:

```json
{
  "topic_key": "<topic-key>",
  "title": "<title>",
  "short_title": "<short_title>",
  "question_text": "<open-ended question, e.g. 'How should government regulate short-term rental properties?'>",
  "levels": ["state", "local"],
  "stances": [
    { "value": 1, "text": "..." },
    { "value": 2, "text": "..." },
    { "value": 3, "text": "..." },
    { "value": 4, "text": "..." },
    { "value": 5, "text": "..." }
  ],
  "discovery": {
    "jurisdiction": "<jurisdiction or null>",
    "level": "<level>",
    "policy_lever": "<description of policy lever>",
    "closest_existing_topic": "<topic_key or null>",
    "sources": ["<url1>", "<url2>"]
  },
  "quality_checks": {
    "double_barrel": "pass",
    "spectrum_coherence": "pass",
    "level_agnostic": "pass"
  }
}
```

### 4b. Optional DB push

Ask the user:
> "Would you like to push this topic to the database as a **draft** (is_live: false)? You can promote it to live later via the admin panel."

If yes, create the topic via database:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';

const topic = JSON.parse(process.argv[2]);

// Create topic with stances via RPC
const { rows: [created] } = await pool.query(\`
  SELECT inform.admin_create_topic_with_stances(
    \$1::text, \$2::text, \$3::text, false, \$4::jsonb
  ) as result
\`, [topic.title, topic.question_text, topic.short_title, JSON.stringify(topic.stances)]);

const topicId = created.result.topic.id;
console.log('Created topic:', topicId);

// Set topic_key explicitly (trigger auto-derives from short_title if blank,
// but we set it explicitly to match what quotes use)
await pool.query(\`
  UPDATE inform.compass_topics SET topic_key = \$1 WHERE id = \$2
\`, [topic.topic_key, topicId]);

// Insert compass_topic_roles for each level
// role_scope holds the LEVEL itself. The real values in production are
// 'federal', 'state', 'local' and 'judicial' (verified 2026-08-28) — office
// names like 'city_council' are NOT role scopes; a topic published with one
// never appears on that scale, and nothing errors.
const levelMap = {
  'federal': ['federal'],
  'state': ['state'],
  'local': ['local'],
  'judicial': ['judicial']
};

for (const level of topic.levels) {
  for (const roleScope of levelMap[level]) {
    await pool.query(\`
      INSERT INTO inform.compass_topic_roles (topic_id, role_scope, is_required)
      VALUES (\$1, \$2, true)
      ON CONFLICT DO NOTHING
    \`, [topicId, roleScope]);
  }
}

console.log('Assigned role scopes:', topic.levels);
await pool.end();
" '<JSON>'
```

### 4c. Suggest categories

Based on the topic content and the existing categories loaded in STEP 1, suggest which categories fit:

> "This topic might fit in these existing categories: [list]. Would you like to assign it, or create a new category?"

If assigning:

```bash
cd ev-accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
await pool.query(\`
  INSERT INTO inform.compass_topic_categories (topic_id, category_id)
  VALUES (\$1, \$2)
  ON CONFLICT DO NOTHING
\`, [process.argv[2], process.argv[3]]);
console.log('Category assigned');
await pool.end();
" "TOPIC_ID" "CATEGORY_ID"
```

### 4d. Report results

> "Topic '[title]' saved:
> - JSON draft: `ev-accounts/backend/data/topic-drafts/YYYY-MM-DD-<topic-key>.json`
> - Database: [created as draft / skipped]
> - Levels: [federal, state, local]
> - Categories: [assigned / none]
>
> To make it live, toggle `is_live` in the admin panel."

If there are more topics to author from the discovery list, loop back to STEP 3 for the next one.

---

## ERROR HANDLING

- If WebSearch returns no useful results for a jurisdiction, tell the user and suggest they provide a specific issue instead
- If the database query fails, save the JSON draft anyway — it's the source of truth
- If a topic_key conflicts with an existing topic, append a number (e.g., `housing-2`) and flag it
- Never lose draft data — the JSON file is written before any DB operation
