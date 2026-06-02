# Phase 87: Stance Accuracy Audit + Agent Update — Pattern Map

**Mapped:** 2026-06-02
**Files analyzed:** 2 new/modified files
**Analogs found:** 2 / 2

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md` | planning artifact (markdown report) | batch (SQL query → markdown table) | `.planning/milestones/v2.2-MILESTONE-AUDIT.md` | role-match |
| `.claude/skills/research-stances/SKILL.md` | agent config (text edit — section replacement) | N/A (config file) | `.claude/skills/research-stances/SKILL.md` itself (self-replacement) | exact (surgical edit) |

---

## Pattern Assignments

### `.planning/phases/87-stance-accuracy-audit-agent-update/87-AUDIT-REPORT.md` (planning artifact, batch)

**Analog:** `.planning/milestones/v2.2-MILESTONE-AUDIT.md`

**Imports pattern** — None (Markdown file, no imports). The report is a standalone planning document written by running the audit SQL via Node.js + `pool.query()` and rendering results as Markdown tables.

**How to produce the report** — Use the Node.js script pattern from SKILL.md STEP 0 / STEP 4, adapted for a read-only audit query:

```bash
# Run via: cd C:/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "..."
# Import pool from ./src/lib/db.ts (compiled to ./src/lib/db.js at runtime)
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(SQL_STRING);
await pool.end();
```

Source: `C:\EV-Accounts\.claude\skills\research-stances\SKILL.md`, lines 27–40 (STEP 0 jurisdiction resolution block) and lines 200–219 (STEP 4a resolve IDs block). Both show the canonical `pool.query()` invocation pattern.

**Core audit SQL pattern** (from RESEARCH.md, validated live):

```sql
-- Audit SQL: 60% dominant-value flag with per-politician breakdown
-- Run via pool.query() — inform.* is NOT in PostgREST exposed schemas
-- Minimum stance count (15) is the tuning knob per CONTEXT.md D-09 / RESEARCH.md Pattern 2

WITH per_politician_totals AS (
  SELECT politician_id, COUNT(*) AS total_stances
  FROM inform.politician_answers
  GROUP BY politician_id
),
per_value_counts AS (
  SELECT politician_id, value, COUNT(*) AS cnt
  FROM inform.politician_answers
  WHERE value = ROUND(value)   -- exclude 63 half-value rows (1.5, 2.5, 3.5, 4.5)
  GROUP BY politician_id, value
),
per_politician_max AS (
  SELECT pvc.politician_id, MAX(pvc.cnt) AS max_cnt
  FROM per_value_counts pvc
  GROUP BY pvc.politician_id
),
flagged_politicians AS (
  SELECT
    pvc.politician_id,
    pvc.value AS dominant_value,
    pvc.cnt AS dominant_count,
    ppt.total_stances,
    ROUND(pvc.cnt::numeric / ppt.total_stances * 100) AS ratio_pct
  FROM per_value_counts pvc
  JOIN per_politician_totals ppt ON ppt.politician_id = pvc.politician_id
  JOIN per_politician_max ppm
    ON ppm.politician_id = pvc.politician_id AND ppm.max_cnt = pvc.cnt
  WHERE pvc.cnt::numeric / ppt.total_stances >= 0.60
    AND ppt.total_stances >= 15
)
SELECT
  p.full_name                      AS name,
  COALESCE(NULLIF(p.party, ''), 'Unknown') AS party,
  (SELECT o.title FROM essentials.offices o
   WHERE o.politician_id = p.id LIMIT 1) AS office,
  fp.total_stances                 AS stance_count,
  fp.dominant_count                AS flagged_count,
  fp.ratio_pct                     AS flag_ratio_pct,
  fp.dominant_value,
  (
    SELECT string_agg(t.topic_key, ', ' ORDER BY t.topic_key)
    FROM inform.politician_answers pa
    JOIN inform.compass_topics t ON t.id = pa.topic_id
    WHERE pa.politician_id = fp.politician_id
      AND pa.value = fp.dominant_value
  )                                AS flagged_topics
FROM flagged_politicians fp
JOIN essentials.politicians p ON p.id = fp.politician_id
ORDER BY fp.ratio_pct DESC, fp.total_stances DESC;
```

**Report structure pattern** (copy from `v2.2-MILESTONE-AUDIT.md`):

Frontmatter YAML block at top → prose header section → Markdown table sections per tier → appendix sections for secondary data.

Example from `C:\EV-Accounts\.planning\milestones\v2.2-MILESTONE-AUDIT.md`, lines 1–18:
```markdown
---
milestone: v2.2
audited: 2026-05-10
status: passed
---

# Milestone v2.2: TIGER District Geofencing — Audit Report

**Audited:** 2026-05-10
**Phases:** ...
```

**Required table columns** (from CONTEXT.md D-06):
```markdown
| name | party | office | stance_count | flagged_count | priority_tier | flagged_topics |
```

**Three-tier section structure** (from CONTEXT.md D-07):
1. `confirmed-inversion` — 8 pre-seeded entries (not SQL-derived)
2. `borderline` — SQL output, cross-party suspicious patterns (R dominant ≤2, D dominant ≥4; uniform-neutral dominant=3 at high ratio; OR any ≥90% single value)
3. `likely-correct` — SQL output, same-party natural patterns (D dominant=1-2, R dominant=4-5)

**Pre-seeded confirmed-inversion rows** (from CONTEXT.md `<specifics>`):

| name | party | office | stance_count | flagged_count | priority_tier | flagged_topics |
|------|-------|--------|-------------|--------------|--------------|----------------|
| Jeff Gonzalez | R | CA Assembly | 21 | multi-value (43% @1 + 38% @2) | confirmed-inversion | (all topics at values 1-2) |
| Roger Niello | R | CA State Sen. | 14 | 9 | confirmed-inversion | (11 flagged topics) |
| Angie Nixon | D | FL Senate cand. | 11 | 10 | confirmed-inversion | (every topic at value=4) |
| Alex Vindman | D | FL Senate cand. | 11 | 9 | confirmed-inversion | abortion, religious-freedom + others |
| Tim Grayson | D | CA State Sen. | 13 | 9 | confirmed-inversion | civil-rights, climate, ssm + others |
| Ashley Hinson | R | IA Senate cand. | 11 | 9 | confirmed-inversion | abortion, climate, immigration + others |
| Derek Dooley | R | GA Senate cand. | 10 | 9 | confirmed-inversion | (dominant value=2 pattern) |
| Adam Hinojosa | D (check) | TX? | 6 | 6 | confirmed-inversion | values look Republican |

**Known-correct cases that must appear as reviewed and confirmed** (CONTEXT.md D-07 / STATE.md):
- Collins, Murkowski, Tillis, Young, Capito: `same-sex-marriage=2` — voted for Respect for Marriage Act
- Gary VanDeaver (R-TX): `school-vouchers=2` — voted against TX voucher bills

**Error handling note:** The `essentials.offices` table has NO `is_current` column (RESEARCH.md Pitfall 3). Use `LIMIT 1` subquery, not a join on `is_current = true`.

---

### `.claude/skills/research-stances/SKILL.md` (agent config, surgical text replacement)

**Analog:** The file itself — this is a single-section replacement within an existing 518-line config.

**Target section to replace** — lines 101–106 of `C:\EV-Accounts\.claude\skills\research-stances\SKILL.md`:

```
SCALE RULE — CRITICAL — READ BEFORE ASSIGNING ANY VALUE:
The value you assign (1–5) MUST match the written stance text for that value in the DB.
Do NOT treat 1 as "oppose" or 5 as "support" — the direction varies by topic.
Do NOT use party affiliation as a shortcut.
For every stance you record, ask: "Does this politician's documented position match the
EXACT TEXT at this value?" If not, pick a different value.
```

**Replacement block** (verbatim from CONTEXT.md D-02 / RESEARCH.md Pattern 5):

```
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
```

**Surrounding context to preserve** — The replacement sits between two adjacent blocks in the STEP 1 agent prompt template:

- ABOVE the replaced block (lines 90–100): the dispatch rules and `Research the political stances of...` opening lines
- BELOW the replaced block (lines 108–140): `TOPIC SCALE REFERENCE — assign values by matching to exact stance text:` section through the end of the agent prompt template

Both surrounding blocks must be preserved exactly. The only change is the 6-line `SCALE RULE` block replaced by the ~20-line `FIVE-CHAIRS FRAMING` block.

**Validation after edit** (from RESEARCH.md Validation Architecture):
- `grep "SCALE RULE" .claude/skills/research-stances/SKILL.md` must return 0 results
- `grep "five chairs\|five named chairs" .claude/skills/research-stances/SKILL.md` must return matches

---

## Shared Patterns

### pool.query() for All inform.* Access
**Source:** `C:\EV-Accounts\backend\src\lib\db.ts` (the pool export), plus established pattern documented throughout RESEARCH.md and CONTEXT.md
**Apply to:** The audit script / query runner for the AUDIT-REPORT deliverable
**Critical rule:** `inform.politician_answers` and `inform.compass_topics` are NOT in PostgREST's exposed schema list. Every read must go through `pool.query()`, never `supabaseAdmin.schema('inform')`.

```typescript
// C:\EV-Accounts\backend\src\lib\db.ts lines 8-16
export const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 10,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10_000,
  ssl: { rejectUnauthorized: false },
});
```

### Node.js Script Invocation Pattern
**Source:** `C:\EV-Accounts\.claude\skills\research-stances\SKILL.md` — repeated throughout STEP 0, STEP 4a, and rewrite mode STEP 0
**Apply to:** Any script that runs the audit SQL
```bash
cd C:/EV-Accounts/backend && set -a && source .env && set +a && node --import tsx -e "
import { pool } from './src/lib/db.js';
const { rows } = await pool.query(\`...\`);
console.log(JSON.stringify(rows, null, 2));
await pool.end();
"
```

### Planning Document Frontmatter Convention
**Source:** `C:\EV-Accounts\.planning\milestones\v2.2-MILESTONE-AUDIT.md` lines 1–18
**Apply to:** `87-AUDIT-REPORT.md` header
YAML frontmatter block (`---`) → H1 title → bold metadata lines → horizontal rule → H2 sections

---

## No Analog Found

All deliverables in Phase 87 have clear analogs:

| File | Reason |
|------|--------|
| `87-AUDIT-REPORT.md` | Planning document with table structure — analogous to milestone audit reports |
| `SKILL.md` (edit) | Self-referential: the file being edited is its own analog; the replacement text is defined verbatim in CONTEXT.md |

There are no files without analogs in this phase.

---

## Metadata

**Analog search scope:** `.planning/milestones/`, `.claude/skills/research-stances/`, `backend/src/lib/`
**Files scanned:** 4 (SKILL.md, db.ts, v2.2-MILESTONE-AUDIT.md, CONTEXT.md + RESEARCH.md as primary inputs)
**Pattern extraction date:** 2026-06-02

**Key constraints carried forward to planner:**
1. `inform.*` access = `pool.query()` only, no PostgREST
2. `essentials.offices` has no `is_current` column — use `LIMIT 1` subquery
3. SKILL.md edit = replace lines 101–106 only; preserve all surrounding content at lines 107+
4. The 8 confirmed inversions are PRE-SEEDED, not SQL-derived — Adam Hinojosa (6 stances) is below any reasonable SQL minimum-stance filter and must be added manually
5. 60% + 15-stance minimum = 247 flagged (recommended threshold per RESEARCH.md)
