---
name: compass-topic-builder
description: "Discover and create new compass topics with quality-checked stances. Use when the user wants to find new policy issues for a jurisdiction, create new compass topics, write stance scales, or expand the topic list. Triggers on: 'new topic', 'new issue', 'discover issues', 'local issues', 'state issues', 'build topic', 'create stances', 'add compass topic'."
argument-hint: "\"Jurisdiction\" [--level local|state|federal] [--issue \"issue name\"] [--count N]"
---

# /compass-topic-builder — Compass Topic Discovery & Authoring

You are running the **compass-topic-builder** skill. Your job is to discover policy issues relevant to a jurisdiction or level of government, then craft complete compass topics with 5 quality-checked stances on a spectrum.

**Key principle:** Stances must be level-agnostic — broad enough that a city council member and a U.S. senator could both land somewhere on the same 5-point scale. Each stance must be a single, non-double-barreled policy position.

> **Related:** the `topic_key`/spectrum you build here is the shared unit between the Compass and
> Read & Rank quotes. See the quote↔stance coupling model — same topics, not necessarily the same
> axis — at `docs/quote-curation/PRINCIPLES.md#coupling-model` in the on-the-record corpus
> (resolves to `../on-the-record/docs/quote-curation/PRINCIPLES.md` from a sibling checkout).

---

## READ THIS FIRST — the model has changed

**Topics are versioned, and they go live through Seasons.** Do not push content straight to a
live topic.

- **Revision model (ADR 0004).** A topic's content lives in `inform.compass_topic_revisions` +
  `compass_stance_revisions`, not just the legacy `compass_topics`/`compass_stances` tables. Editing
  an existing topic = **propose a new revision** (`inform.admin_propose_topic_revision`) →
  **approve** → **publish**. Never hand-edit the legacy tables (the admin "Topics panel" that does
  is the thing to avoid). The immutability trigger blocks editing a revision in place, so to change
  a draft you **reject it and propose a fresh one**.
- **Seasons (ADR 0005/0006, "Model Q").** The live compass serves the **open season's bound
  version** of each topic, not the global "current" one. A **major** (substantive) rewrite is
  **staged into the next draft season** (`admin_season_pin_revision`) and goes live only when that
  season **opens** (`admin_open_season` publishes staged approved revisions). A **minor**
  (editorial/clarifying) edit flows into the current season on publish. So: for a real rewrite,
  **approve — do not publish** — then stage into Season N+1.
- **Display capitalizes the first letter** at the read boundary (voter + admin review). Corpus
  convention was lowercase-verb-first; recent topics are stored **capitalized**. Match the
  surrounding topics or ask.
- **`topic_key` is load-bearing and frozen.** `essentials.quotes` joins on it. Renaming a topic's
  display name is fine (revise `short_title`); the `topic_key` must **not** change or you orphan its
  quotes. So a rename is a **revision**, never a new topic.

### Revise vs. split vs. new topic — decide before authoring

- **Revise** an existing topic when it's the same issue reworded/reframed (keeps `topic_key`,
  quotes, and seated answers via an identity rung_map). A rename is always a revision.
- **Split** when one topic secretly measures two independent axes (e.g. Climate → Clean Energy +
  Fossil Fuels; Immigration → Legal Immigration + Border Security). Keep one as a revision of the
  original (preserves its quotes); the other becomes a new topic.
- **New topic** only for a genuinely new issue with no existing home. New topics **orphan no
  existing quotes** (there are none) but must be created through the full revision model — see
  STEP 4b (the legacy `admin_create_topic_with_stances` creates **no revision** and is insufficient).

---

## DESIGN PRINCIPLES — how to build an axis that a citizen can actually choose from

The five stances are five **distinct chairs** a politician sits in, ordered along **one axis**.
These are the failure modes to hunt for (learned the hard way across abortion, public safety,
climate/energy, immigration):

1. **One axis only.** If chair 1 measures funding and chair 2 measures who-responds, they're not two
   points on a line — they're two lines. Pick the single axis the whole scale varies along and hold
   it for all five rungs.
2. **No effort-dials.** "significantly / moderately / a little / none," "some/most/all" — that's one
   position said five ways, and a citizen can't feel the difference. Anchor each rung in a **distinct
   real policy model/posture** (who does what), not a magnitude notch. *Exception:* a genuine
   magnitude axis (e.g. abortion's gestational limit) is fine **if** each rung is a concrete,
   recognizable threshold, not a vague quantifier.
3. **No double-barrels — three kinds:**
   - two independent positions joined by "and" (someone could hold one, not the other);
   - an **off-axis limb** — a broadly-agreeable extra that doesn't discriminate between chairs (police
     "better pay & equipment" on a centrality axis; "remove environmental restrictions" on a
     production axis);
   - **belief vs. policy mixing** — a topic named for a belief ("Climate Change → is it real?") but
     scored on policy. Measure policy; rename the topic if the name invites the belief axis.
4. **Label poles by real held positions, not strawmen.** "Open borders" and literal "abolish the
   police" are attack labels almost nobody holds — a chair no one sits in is dead weight. Use the
   real left/right pole (e.g. "civil, not criminal — a hearing for everyone").
5. **Ground rungs in reality.** Each chair should seat real politicians with real legislation/actions
   (a research pass earns this). If you can't name who sits in a chair, it's invented.
6. **Watch for cross-topic overlap.** Before adding or revising, check the existing topics — two that
   measure nearly the same thing (Climate/Fossil, the two Homelessness topics) should be split-clean
   or merged, not left redundant.
7. **Neutral, open question** that names the axis (not "fund **and** operate…" — itself a
   double-barrel). Prefer "What approach should…", "How should the government handle…".

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

First **name the single axis** (per the DESIGN PRINCIPLES above), then write 5 distinct chairs along
it. Value 1 → 5 runs from one pole to the other:
- **Value 1** = most interventionist / most government action *on this axis*
- **Value 5** = the opposite pole (hands-off, or the other direction)
- ⚠ Polarity is **not** universal — some ladders run the other way (AI Oversight, Tariffs), and some
  are off-axis (Residential Zoning, Growth Pace). Decide the axis and its poles deliberately; don't
  assume "1 = progressive."

Each stance should:
- Be **one chair on the one axis** — a distinct real position, not an effort-dial notch (re-read the
  DESIGN PRINCIPLES: no dials, no double-barrels, no off-axis limbs, no strawman poles).
- Ideally seat a **real politician/bill** — a research pass (WebSearch) grounds the rungs in reality.
- Start with a verb; be one sentence (two max).
- Be broad enough to apply at any government level (no "federal law", "city ordinance").
- **Capitalize the first letter** to match recent topics (display capitalizes anyway, but store it
  capitalized).

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

### 4b. Create the topic in the database (as a versioned migration)

🔴 **A new topic MUST be created through the full revision model.** The legacy
`inform.admin_create_topic_with_stances` RPC writes only `compass_topics` + legacy `compass_stances`
and creates **no `compass_topic_revisions`** — a topic made that way is invisible to the Option Y
season read path and cannot be pinned into a season. Do **not** use it.

**Canonical path — call `inform.admin_create_topic_with_revision` from a migration.** CA_0026 (applied
to prod 2026-08-28) added a `SECURITY DEFINER` RPC that bootstraps a topic across **all five layers
atomically** in one call — identity row, legacy 1..5 ladder, the founding v1 published/current
revision, its five stance revisions, and the role scopes. You **no longer hand-write the layers**;
you call the RPC. House style still applies: create a **numbered migration** —
`backend/migrations/CA_NNNN_<slug>.sql` (your namespace; run `git fetch origin` then
`npm run check:migrations` for the next free slot), idempotent, ending in a `DO $$…$$` post-verify
gate, dry-run `BEGIN; … ROLLBACK;` against prod before applying. **Worked example:
`backend/migrations/CA_0027_2020_election_topic.sql`.**

The RPC signature:

```sql
inform.admin_create_topic_with_revision(
  p_title         text,     -- e.g. '2020 Presidential Election'
  p_question_text text,     -- open-ended question
  p_short_title   text,     -- e.g. '2020 Election'  ->  topic_key '2020-election'
  p_is_live       boolean,  -- false = staged (shows on no voter surface until a Season pins it)
  p_stances       jsonb,    -- exactly 5 rungs: [{"value":1,"text":"…"}, …], values 1–5, capitalized
  p_actor_id      uuid,     -- author users.id, or NULL
  p_role_scopes   jsonb     -- ['federal','state','local']; NULL defaults to federal+state+local
) RETURNS jsonb             -- created topic id at  result->'topic'->>'id'
```

Call it **guarded by `IF NOT EXISTS` on `topic_key`** so a re-run is a no-op — the RPC raises
`DUPLICATE_TOPIC_KEY` when the key already exists, so an unguarded re-run aborts the migration:

```sql
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM inform.compass_topics WHERE topic_key = '<topic-key>') THEN
    PERFORM inform.admin_create_topic_with_revision(
      '<Title>', '<Open-ended question?>', '<Short Title>', false,
      '[{"value":1,"text":"…"}, {"value":2,"text":"…"}, {"value":3,"text":"…"},
        {"value":4,"text":"…"}, {"value":5,"text":"…"}]'::jsonb,
      NULL, '["federal","state","local"]'::jsonb
    );
    RAISE NOTICE 'CA_NNNN: created topic <topic-key>';
  ELSE
    RAISE NOTICE 'CA_NNNN: topic <topic-key> already present — create skipped';
  END IF;
END $$;
```

What the RPC writes and the rules it enforces (so your post-verify gate knows what to assert):

1. **`inform.compass_topics`** — identity row. `topic_key` is derived **and frozen** as
   `lower(replace(short_title,' ','-'))` (load-bearing: `essentials.quotes` joins on it). `is_live`
   defaults to `false`; it does **not** gate the season read path.
2. **`inform.compass_stances`** (legacy ladder, values 1–5) — parity only; not read by the season
   path. The RPC enforces **exactly 5 rungs, values 1–5 distinct, non-empty text** (`BAD_LADDER`
   otherwise).
3. **The v1 revision** in `inform.compass_topic_revisions`: `revision=1, version=1,
   change_class='substantive', status='published', is_current=true, rung_map=NULL`,
   `published_at=now()`, `approved_by/at` NULL. Published+current is required so a season can pin it;
   it still shows nowhere until pinned.
4. **The five rungs** in `inform.compass_stance_revisions` (values 1–5; capitalize the text to match
   recent topics).
5. **Role scopes** in `inform.compass_topic_roles` — from `p_role_scopes`, values ∈
   `('federal','state','local','judicial')` **ONLY** (NOT `us_congress`/`president`/`city_council`).
   Federal-only = `'["federal"]'`. `NULL`/empty defaults to federal+state+local (never judicial).

⚠ **The founding revision's `rationale` and `public_note` are auto-generated** — a generic "founding
revision (v1)" summary, since a v1 needs no hand-written edit summary and the create UI passes none.
The RPC has **no argument** for the real design rationale, so **put it in the migration's SQL
comments**. `CA_0027` is the model: a long header comment records the axis, the polarity choice, the
four rung thresholds, who seats each rung (a grounding pass), and why the topic departs from
convention — everything a later maintainer would otherwise have to re-derive.

Post-verify gate asserts: exactly one published/current v1 revision (`rung_map` NULL); 5 distinct
stance-revision values; 5 legacy stances; the expected role rows; `topic_key` correct; and the topic
is **not** in `inform.compass_topics_promoted` (nothing pins it yet). CA_0027's gate is the template.

**Fallback — hand-writing the five layers.** Before the RPC existed, a topic migration wrote all five
layers by hand; `backend/migrations/CA_0025_border_security_topic.sql` is that older worked example.
You should not need it now — the RPC does the same inserts and enforces the invariants for you — but
CA_0025 documents exactly what each layer contains if you ever must diverge from what the RPC does.

**Then, separately, when composing the season:** pin it in with the CA_0022 RPCs —
`admin_season_add_topic(season_id, topic_id, actor)` on the draft Season N+1, and it goes live when
`admin_open_season` runs.

> ⚠ **Editing an EXISTING topic is different — do NOT create a new topic.** Propose a revision:
> `inform.admin_propose_topic_revision(topic_key, actor, change_class, title, short_title, question,
> stances_jsonb, rationale, public_note, review_ref, rung_map)`. If a draft already exists, reject it
> first (`admin_reject_topic_revision`) — one open revision per topic. Use an identity rung_map
> (`{"1":1,…,"5":5}`) when the five rungs stay in place and are only reworded. Then **approve**; for a
> **major** change **do not publish** — stage into the next season (`admin_season_pin_revision`) and
> let `admin_open_season` publish it at the season boundary.

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
> It shows on no voter surface yet. It goes live by being **pinned into the next season** and that
> season opening — not by toggling `is_live`. (`is_live` does not gate the season read path.)"

If there are more topics to author from the discovery list, loop back to STEP 3 for the next one.

---

## ERROR HANDLING

- If WebSearch returns no useful results for a jurisdiction, tell the user and suggest they provide a specific issue instead
- If the database query fails, save the JSON draft anyway — it's the source of truth
- If a topic_key conflicts with an existing topic, append a number (e.g., `housing-2`) and flag it
- Never lose draft data — the JSON file is written before any DB operation
