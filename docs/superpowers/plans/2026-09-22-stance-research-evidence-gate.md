# Stance-Research Evidence Gate — Implementation Plan (Increment 1 of 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `/research-stances` unable to publish a stance that is uncited, unverifiable, party-inferred, scored against the wrong ladder, or out of scope for the office — and route everything that needs a human to the existing review queue instead of a chat prompt.

**Architecture:** Reconnect the stance verifier that was built in April but never wired into the skill (`scripts/verify-stance-research.ts` + `src/lib/researchVerifier.ts`, which proves each cited passage is really on the page). Add a deterministic pre-write gate (`scripts/stance-gate.ts`) for the checks the verifier does not do. Encode the publish decision as a pure, tested function (`decidePublish`). Source the question set and ladder wording from the OPEN season's pinned revisions instead of the frozen legacy table. Every step is a non-interactive script with explicit inputs, outputs and exit codes, so the pipeline can run on a schedule later (Increment 3).

**Tech Stack:** TypeScript (tsx) + vitest in `ev-accounts/backend`; Node `node:test` for the skill's own `.mjs` scripts; Postgres (Supabase prod, read via existing `backend/.env`); `csv-parse`.

## Why (verified 2026-09-22 review)

1. `build-and-check.mjs` checks only quote rows — a stance row with **no source passes**.
2. Nothing checks that a citation **supports** the claim; `check-stance-sources.mjs` says so in its header. 1,157 stances were already retired for this.
3. The skill reads ladder text from the frozen `inform.compass_stances`. **29 of the open season's 60** ladders differ from it.
4. It pulls topics by `is_live` (44) while the open season asks **60** questions; 1 live topic is not in the season, and one such row rolls back the whole push.
5. `audit-chair-evidence.mjs --csv` (instrument-naming gate) exists but is never run.
6. Jurisdiction resolution and rewrite mode query `offices.politician_id` / `is_current` — **both columns were dropped** (mig 1463). Those steps error.
7. The researcher agent hard-codes 36 topic ladders and an "inversion traps" table that coaches with party shortcuts ("Democrats who favor oversight score HIGHER…", "most blue-city officials score 1–2").
8. The verifier's own `--apply` still uses the pre-seasons bare-pair `INSERT` and resolves topics by `is_live`.
9. Four divergent copies of the skill and two of the agent exist; the workspace-root copy was ~7 weeks stale.

## Global Constraints

- Party is never stored and never used as evidence or reasoning (antipartisan model).
- Topics and ladder wording come ONLY from the open season: `inform.season_questions` (status `'open'`) → `compass_topic_revisions` → `compass_stance_revisions`. Never `inform.compass_stances`, never `is_live`.
- A value already present in the open season — **including a 0 (blank)** — is never changed without a human. It goes to the review queue.
- **Two evidence classes** (operator decision 2026-09-22): `record` evidence must name an instrument per `NAMES_INSTRUMENT` (`backend/scripts/lib/chair-evidence-patterns.mjs`) — **never widen that regex**. `statement` evidence (the person's own words) is allowed only with a verified verbatim snippet and goes to human review in this increment.
- Snippets: verbatim from the fetched page, ≥ `MIN_SNIPPET_WORDS` (25) words, politician's name within `NAME_PROXIMITY_CHARS` (500) — the verifier's existing rules.
- Stance writes go ONLY through `UPSERT_ANSWER_SQL` / `UPSERT_CONTEXT_SQL` + `assertWritten` from `backend/src/lib/seasonService.ts`.
- No production writes anywhere in this plan's verification. Dry-runs only. No schema change, so no migration.
- Commit with an explicit pathspec: `git commit -F <msg> -- <paths>`. Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Run backend commands from `ev-accounts/.claude/worktrees/<this worktree>/backend`.

## File Structure

| File | Status | Responsibility |
|---|---|---|
| `backend/src/lib/topicApplicability.ts` | Create | Topic→office-level applicability and district→level mapping. One source of truth, shared by the API and the gate. |
| `backend/src/lib/topicApplicability.test.ts` | Create | Pins the applicability rules, including the judicial fallback. |
| `backend/src/lib/compassService.ts` | Modify | `getCompassTopics` uses `appliesFromRoles` (behaviour unchanged). |
| `backend/scripts/build-stance-topic-bundle.ts` | Create | Writes `topics.json` (open-season questions + pinned ladders + applicability) and `politicians.json` (people + office level); prints the prompt reference per level. |
| `backend/scripts/lib/stanceGate.ts` | Create | Pure stance-row checks the snippet verifier does not do. |
| `backend/scripts/lib/stanceGate.test.ts` | Create | Positive controls: every check fires on its planted defect; refusals refuse. |
| `backend/scripts/stance-gate.ts` | Create | CLI: reads a batch dir, writes `gate-findings.json` + `stances.csv`, exit codes. |
| `backend/scripts/lib/stancePublishPolicy.ts` | Create | Pure `decidePublish`: auto-push / unchanged / review / re-research. |
| `backend/scripts/lib/stancePublishPolicy.test.ts` | Create | Every branch and its precedence. |
| `backend/src/lib/researchEvidenceService.ts` | Modify | Extract season-aware `writeVerifiedStance`; `resolveResearchReview` calls it. |
| `backend/src/lib/researchEvidenceService.test.ts` | Modify | Tests for `writeVerifiedStance`. |
| `backend/scripts/verify-stance-research.ts` | Modify | Open-season topics, gate + policy routing, season-aware writes, `--editor-id`, `publish-report.json`. |
| `.claude/skills/research-stances/SKILL.md` | Modify | New pipeline; drop dead queries; evidence contract; rewrite-mode warning. |
| `.claude/agents/politician-stance-researcher.md` | Modify | Remove hard-coded ladders and party-shortcut table; evidence contract; two output files. |

**Batch directory** (`backend/data/stance-research/<batch>/`): `topics.json`, `politicians.json` (Task 2) · `research.csv`, `evidence.csv` (agent) · `gate-findings.json`, `stances.csv` (Task 4) · `publish-report.json` (Task 7).

---

### Task 1: Worktree setup + shared applicability rules

**Files:**
- Create: `backend/src/lib/topicApplicability.ts`
- Create: `backend/src/lib/topicApplicability.test.ts`
- Modify: `backend/src/lib/compassService.ts` (the per-topic `applies_*` block inside `getCompassTopics`, ~lines 262–282)

**Interfaces:**
- Produces: `type Level = 'federal'|'state'|'local'|'judicial'`; `interface TopicApplicability { applies_federal; applies_state; applies_local; applies_judicial: boolean }`; `appliesFromRoles(roles: {role_scope: string}[]): TopicApplicability`; `appliesToLevel(t: TopicApplicability, level: Level): boolean`; `levelForDistrict(districtType: string | null, isJudicial: boolean | null): Level | null`.

- [ ] **Step 1: Bootstrap the worktree** (it has no `node_modules` and no `.env`)

```bash
cd backend && npm ci
cp /Users/chrisandrews/Documents/GitHub/ev-accounts/backend/.env ./.env
git check-ignore .env   # MUST print ".env" — if it prints nothing, delete ./.env and stop
```

- [ ] **Step 2: Baseline — confirm the parts being reused are green before touching anything**

Run: `npx vitest run src/lib/researchVerifier.test.ts src/lib/verificationFetch.test.ts src/lib/researchEvidenceService.test.ts scripts/lib/chair-evidence-patterns.test.ts`
Expected: all PASS. If anything fails, stop and report — do not build on a red baseline.

- [ ] **Step 3: Write the failing test** — `backend/src/lib/topicApplicability.test.ts`

```ts
import { describe, it, expect } from 'vitest';
import { appliesFromRoles, appliesToLevel, levelForDistrict } from './topicApplicability.js';

describe('appliesFromRoles', () => {
  it('treats a topic with no role rows as cross-cutting — but never judicial', () => {
    expect(appliesFromRoles([])).toEqual({
      applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false,
    });
  });
  it('limits a topic to exactly its listed scopes', () => {
    expect(appliesFromRoles([{ role_scope: 'local' }])).toEqual({
      applies_federal: false, applies_state: false, applies_local: true, applies_judicial: false,
    });
    expect(appliesFromRoles([{ role_scope: 'judicial' }]).applies_judicial).toBe(true);
  });
});

describe('appliesToLevel', () => {
  it('reads the matching flag', () => {
    const local = appliesFromRoles([{ role_scope: 'local' }]);
    expect(appliesToLevel(local, 'local')).toBe(true);
    expect(appliesToLevel(local, 'state')).toBe(false);
  });
});

describe('levelForDistrict', () => {
  it.each([
    ['NATIONAL_LOWER', false, 'federal'], ['NATIONAL_UPPER', false, 'federal'],
    ['STATE_EXEC', false, 'state'], ['STATE_LOWER', false, 'state'],
    ['COUNTY', false, 'local'], ['LOCAL', false, 'local'], ['SCHOOL', false, 'local'],
    ['JUDICIAL', true, 'judicial'], ['COUNTY', true, 'judicial'],
  ] as const)('%s (judicial=%s) -> %s', (t, j, want) => {
    expect(levelForDistrict(t, j)).toBe(want);
  });
  it('returns null for a type it has never seen, so scope is reported unknown rather than guessed', () => {
    expect(levelForDistrict('SOMETHING_NEW', false)).toBeNull();
    expect(levelForDistrict(null, null)).toBeNull();
  });
});
```

- [ ] **Step 4: Run it to verify it fails**

Run: `npx vitest run src/lib/topicApplicability.test.ts`
Expected: FAIL — `Cannot find module './topicApplicability.js'`.

- [ ] **Step 5: Implement** — `backend/src/lib/topicApplicability.ts`

```ts
/**
 * Which office levels a compass topic applies to, and which level an office sits at.
 *
 * One source of truth for the rule compassService applies at the API boundary and the
 * stance-research gate applies before a batch is written. CLAUDE.md: "a ladder is only
 * valid at a level where its rungs are things an officeholder there can actually do."
 * Extracted from compassService.getCompassTopics with behaviour unchanged.
 */
export type Level = 'federal' | 'state' | 'local' | 'judicial';

export interface TopicRoleRow { role_scope: string }

export interface TopicApplicability {
  applies_federal: boolean;
  applies_state: boolean;
  applies_local: boolean;
  applies_judicial: boolean;
}

/** A topic with no role rows is cross-cutting for federal/state/local — but NEVER judicial. */
export function appliesFromRoles(roles: TopicRoleRow[]): TopicApplicability {
  const has = roles.length > 0;
  const any = (scope: string) => roles.some((r) => r.role_scope === scope);
  return {
    applies_federal: has ? any('federal') : true,
    applies_state: has ? any('state') : true,
    applies_local: has ? any('local') : true,
    // CRITICAL: fallback is false — cross-cutting topics must not appear on judicial profiles.
    applies_judicial: has ? any('judicial') : false,
  };
}

export function appliesToLevel(t: TopicApplicability, level: Level): boolean {
  if (level === 'federal') return t.applies_federal;
  if (level === 'state') return t.applies_state;
  if (level === 'local') return t.applies_local;
  return t.applies_judicial;
}

const LOCAL_TYPES = new Set(['COUNTY', 'LOCAL', 'LOCAL_EXEC', 'SCHOOL', 'CITY', 'TOWNSHIP']);

/** Office level from the office's district. null for an unseen type — never a guess. */
export function levelForDistrict(districtType: string | null, isJudicial: boolean | null): Level | null {
  if (isJudicial || districtType === 'JUDICIAL') return 'judicial';
  if (!districtType) return null;
  if (districtType.startsWith('NATIONAL_')) return 'federal';
  if (districtType.startsWith('STATE_')) return 'state';
  if (LOCAL_TYPES.has(districtType)) return 'local';
  return null;
}
```

- [ ] **Step 6: Run it to verify it passes**

Run: `npx vitest run src/lib/topicApplicability.test.ts`
Expected: PASS.

- [ ] **Step 7: Point `getCompassTopics` at the shared rule**

In `backend/src/lib/compassService.ts` add `import { appliesFromRoles } from './topicApplicability.js';` with the other imports, then replace the block that starts `// Normalize tier rows into three booleans at the API boundary.` and ends with the `applies_judicial` ternary with:

```ts
    // Tier rules live in topicApplicability.ts — shared with the stance-research gate.
    const { applies_federal, applies_state, applies_local, applies_judicial } = appliesFromRoles(topicRoles);
```

Leave the `return { ...topic, applies_federal, applies_state, applies_local, applies_judicial, ... }` untouched.

- [ ] **Step 8: Prove behaviour is unchanged**

Run: `npx vitest run src/lib/compassService.test.ts src/lib/topicApplicability.test.ts && npm run typecheck`
Expected: PASS, and typecheck clean.

- [ ] **Step 9: Commit**

```bash
printf 'refactor(compass): extract topic applicability rules for reuse\n\nOne source of truth for which office levels a topic applies to, shared by\ngetCompassTopics and the upcoming stance-research gate. Behaviour unchanged.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t1.txt
git add -- src/lib/topicApplicability.ts src/lib/topicApplicability.test.ts src/lib/compassService.ts
git commit -F /tmp/t1.txt -- src/lib/topicApplicability.ts src/lib/topicApplicability.test.ts src/lib/compassService.ts
```

---

### Task 2: Open-season topic bundle builder

**Files:**
- Create: `backend/scripts/build-stance-topic-bundle.ts`

**Interfaces:**
- Consumes: `appliesFromRoles`, `appliesToLevel`, `levelForDistrict`, `Level` (Task 1); `pool` from `src/lib/db.js`.
- Produces: `<dir>/topics.json` = `BundleTopic[]` = `{ topic_id, topic_key, topic_revision_id, question_number, title, question_text, stances: {value, text}[5], applies_federal, applies_state, applies_local, applies_judicial }`; `<dir>/politicians.json` = `BundlePolitician[]` = `{ full_name, politician_id, level: Level | null, race_id: string | null }`. Stdout: one `TOPIC SCALE REFERENCE (<level>)` block per level present.

- [ ] **Step 1: Implement** — `backend/scripts/build-stance-topic-bundle.ts`

```ts
/**
 * build-stance-topic-bundle.ts — the exact question set a stance-research batch is scored against.
 *
 * 🔴 Reads the OPEN season's pinned ladder revisions (season_questions -> compass_topic_revisions
 * -> compass_stance_revisions), NEVER the frozen legacy inform.compass_stances. On 2026-09-22,
 * 29 of the open season's 60 ladders differed from the legacy text: a researcher shown the legacy
 * text scores against a sentence the stored answer is not an answer to.
 *
 * Usage (from backend/):
 *   npx tsx scripts/build-stance-topic-bundle.ts --dir data/stance-research/<batch> \
 *     [--race <race_id> ...] [--politician <uuid>:<federal|state|local|judicial> ...]
 * Writes <dir>/topics.json and <dir>/politicians.json, then prints one TOPIC SCALE REFERENCE
 * block per office level present — paste the matching block into each researcher prompt.
 * Exit: 0 ok, 1 no open season / malformed ladder, 2 usage.
 */
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pool } from '../src/lib/db.js';
import {
  appliesFromRoles, appliesToLevel, levelForDistrict, type Level,
} from '../src/lib/topicApplicability.js';

const LEVELS: Level[] = ['federal', 'state', 'local', 'judicial'];
function opts(name: string): string[] {
  const out: string[] = [];
  process.argv.forEach((a, i) => { if (a === name && process.argv[i + 1]) out.push(process.argv[i + 1]); });
  return out;
}
const DIR = opts('--dir')[0];
const RACES = opts('--race');
const MANUAL = opts('--politician');
if (!DIR || (!RACES.length && !MANUAL.length)) {
  console.error('usage: build-stance-topic-bundle.ts --dir <batch> [--race <id> ...] [--politician <uuid>:<level> ...]');
  process.exit(2);
}

const { rows: raw } = await pool.query(`
  SELECT t.id::text AS topic_id, t.topic_key, sq.topic_revision_id::text AS topic_revision_id,
         sq.question_number, tr.title, tr.question_text,
         (SELECT json_agg(json_build_object('value', sr.value, 'text', sr.text) ORDER BY sr.value)
            FROM inform.compass_stance_revisions sr
           WHERE sr.topic_revision_id = sq.topic_revision_id) AS stances,
         (SELECT coalesce(json_agg(json_build_object('role_scope', r.role_scope)), '[]'::json)
            FROM inform.compass_topic_roles r WHERE r.topic_id = t.id) AS roles
    FROM inform.season_questions sq
    JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
    JOIN inform.compass_topics t ON t.id = sq.topic_id
    JOIN inform.compass_topic_revisions tr ON tr.id = sq.topic_revision_id
   ORDER BY sq.question_number`);
if (!raw.length) {
  console.error('ERROR: no open season, or it has no season_questions — refusing to write an empty bundle');
  await pool.end();
  process.exit(1);
}
const topics = raw.map(({ roles, ...t }) => {
  if (!Array.isArray(t.stances) || t.stances.length !== 5) {
    console.error(`ERROR: ${t.topic_key} has ${t.stances?.length ?? 0} rungs, expected 5`);
    process.exit(1);
  }
  return { ...t, ...appliesFromRoles(roles) };
});

type Pol = { full_name: string; politician_id: string; level: Level | null; race_id: string | null };
const politicians: Pol[] = [];
if (RACES.length) {
  const { rows } = await pool.query(`
    SELECT DISTINCT ON (p.id) p.full_name, p.id::text AS politician_id, r.id::text AS race_id,
           d.district_type, d.is_judicial
      FROM essentials.race_candidates rc
      JOIN essentials.races r ON r.id = rc.race_id
      JOIN essentials.offices o ON o.id = r.office_id
      LEFT JOIN essentials.districts d ON d.id = o.district_id
      JOIN essentials.politicians p ON p.id = rc.politician_id
     WHERE r.id = ANY($1::uuid[])
     ORDER BY p.id, r.id`, [RACES]);
  for (const r of rows) {
    politicians.push({ full_name: r.full_name, politician_id: r.politician_id, race_id: r.race_id,
      level: levelForDistrict(r.district_type, r.is_judicial) });
  }
  const { rows: [{ n }] } = await pool.query(
    `SELECT count(*)::int AS n FROM essentials.race_candidates
      WHERE race_id = ANY($1::uuid[]) AND politician_id IS NULL`, [RACES]);
  if (n) console.log(`note: ${n} candidate(s) on these races have no politician record and were skipped — they cannot hold a stance`);
}
for (const m of MANUAL) {
  const [id, lvl] = m.split(':');
  if (!LEVELS.includes(lvl as Level)) { console.error(`ERROR: --politician ${m}: level must be one of ${LEVELS.join('|')}`); process.exit(2); }
  const { rows } = await pool.query('SELECT full_name FROM essentials.politicians WHERE id = $1', [id]);
  if (!rows.length) { console.error(`ERROR: politician ${id} not found`); process.exit(2); }
  politicians.push({ full_name: rows[0].full_name, politician_id: id, level: lvl as Level, race_id: null });
}
await pool.end();

mkdirSync(DIR, { recursive: true });
writeFileSync(join(DIR, 'topics.json'), JSON.stringify(topics, null, 2));
writeFileSync(join(DIR, 'politicians.json'), JSON.stringify(politicians, null, 2));
console.log(`wrote ${topics.length} open-season topics and ${politicians.length} politician(s) to ${DIR}`);

for (const level of LEVELS) {
  if (!politicians.some((p) => p.level === level)) continue;
  const inScope = topics.filter((t) => appliesToLevel(t, level));
  console.log(`\n===== TOPIC SCALE REFERENCE (${level}) — ${inScope.length} topics =====`);
  for (const t of inScope) {
    console.log(`\n${t.topic_key} (id: ${t.topic_id}, revision: ${t.topic_revision_id})`);
    console.log(`Question: "${t.question_text}"`);
    for (const s of t.stances) console.log(`  ${s.value} = "${s.text}"`);
  }
}
const unknown = politicians.filter((p) => !p.level);
if (unknown.length) console.log(`\n⚠ level unknown (scope cannot be checked): ${unknown.map((p) => p.full_name).join(', ')}`);
```

- [ ] **Step 2: Positive control — run it against a real Monroe race**

```bash
RACE=$(npx tsx -e "import {pool} from './src/lib/db.js'; const {rows}=await pool.query(\"SELECT r.id::text FROM essentials.races r JOIN essentials.offices o ON o.id=r.office_id JOIN essentials.districts d ON d.id=o.district_id WHERE r.election_id='21190350-91e3-4c2c-938d-9cf8f4ac9d5c' AND d.geo_id='18061'\"); console.log(rows[0].id); await pool.end();")
npx tsx scripts/build-stance-topic-bundle.ts --dir /tmp/bundle-check --race "$RACE" | head -20
```

Expected: `wrote 60 open-season topics and 1 politician(s)` (Matt Pierce, IN House 61) and a `TOPIC SCALE REFERENCE (state)` block.

- [ ] **Step 3: Positive control — the bundle carries the season's wording, not the legacy table's**

```bash
npx tsx -e "
import { readFileSync } from 'node:fs'; import { pool } from './src/lib/db.js';
const topics = JSON.parse(readFileSync('/tmp/bundle-check/topics.json','utf8'));
const { rows: [c] } = await pool.query(\"SELECT count(*)::int n FROM inform.season_questions sq JOIN inform.seasons s ON s.id=sq.season_id AND s.status='open'\");
console.log('topics', topics.length, 'open-season questions', c.n, topics.length === c.n ? 'OK' : 'MISMATCH');
let differs = 0;
for (const t of topics) {
  const { rows } = await pool.query('SELECT value, text FROM inform.compass_stances WHERE topic_id=\$1 ORDER BY value', [t.topic_id]);
  if (rows.some((r, i) => r.text !== t.stances[i]?.text)) differs++;
}
console.log('bundle ladders that differ from legacy compass_stances:', differs, '(expect ~29 on 2026-09-22 — proves the bundle is NOT the legacy text)');
await pool.end();"
```

Expected: `OK`, and a non-zero `differs` count. If `differs` is 0, the bundle may be reading the legacy table — stop and investigate.

- [ ] **Step 4: Typecheck and commit**

```bash
npm run typecheck
printf 'feat(stance-research): build the batch question set from the open season\n\nWrites topics.json (pinned ladder revisions + applicability) and politicians.json\n(office level from the race district). Replaces the skill'"'"'s is_live/compass_stances\nquery, which showed 29 of 60 Season-2 ladders in stale wording.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t2.txt
git add -- scripts/build-stance-topic-bundle.ts
git commit -F /tmp/t2.txt -- scripts/build-stance-topic-bundle.ts
```

---

### Task 3: Stance gate — pure checks

**Files:**
- Create: `backend/scripts/lib/stanceGate.ts`
- Create: `backend/scripts/lib/stanceGate.test.ts`

**Interfaces:**
- Consumes: `NAMES_INSTRUMENT` (`./chair-evidence-patterns.mjs`); `MIN_SNIPPET_WORDS`, `normalizeText`, `EvidenceRow`, `StanceRow` (`../../src/lib/researchVerifier.js`); `appliesToLevel`, `Level`, `TopicApplicability` (Task 1).
- Produces: `ResearchRow`, `BundleTopic`, `BundlePolitician`, `GateCheckId`, `GateFinding = { full_name, topic_key, check_id: GateCheckId, severity: 'high'|'medium', what }`; `PARTY_NAMES`, `PARTY_PHRASES`; `checkStanceRow(row, ctx)`; `checkBatch(rows, topics, politicians, evidence): GateFinding[]`; `toStanceRows(rows, politicians): StanceRow[]`.

- [ ] **Step 1: Write the failing test** — `backend/scripts/lib/stanceGate.test.ts`

```ts
import { describe, it, expect } from 'vitest';
import { checkStanceRow, checkBatch, toStanceRows, PARTY_NAMES,
  type ResearchRow, type BundleTopic, type BundlePolitician } from './stanceGate.js';

const SNIP = 'Representative Jane Doe voted yes on House Bill 1001 in 2025 because she believes every '
  + 'Hoosier family deserves affordable coverage and lower prescription costs at the pharmacy counter today';
const topic = (topic_key: string, scope: Partial<BundleTopic>): BundleTopic => ({
  topic_id: `id-${topic_key}`, topic_key, topic_revision_id: `rev-${topic_key}`, question_number: 1,
  title: topic_key, question_text: '?', stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value}` })),
  applies_federal: true, applies_state: true, applies_local: true, applies_judicial: false, ...scope,
});
const HEALTH = topic('healthcare', { applies_local: false });
const RENT = topic('rent-regulation', { applies_federal: false, applies_state: false });
const JANE: BundlePolitician = { full_name: 'Jane Doe', politician_id: 'p1', level: 'state', race_id: 'r1' };
const good: ResearchRow = {
  full_name: 'Jane Doe', topic_key: 'healthcare', value: 2, evidence_type: 'record',
  reasoning: 'Voted YES on HB 1001 (2025), which expands the public option.', source_urls: ['https://a.gov/x'],
};
const ev = [{ full_name: 'Jane Doe', topic_key: 'healthcare', source_url: 'https://a.gov/x', snippet: SNIP, snippet_index: 0 }];
const ids = (row: ResearchRow, o: { topic?: BundleTopic | undefined; politician?: BundlePolitician | undefined; evidence?: typeof ev } = {}) =>
  checkStanceRow(row, {
    topic: 'topic' in o ? o.topic : HEALTH,
    politician: 'politician' in o ? o.politician : JANE,
    evidence: o.evidence ?? ev,
  }).map((f) => f.check_id).sort();

describe('checkStanceRow — clean rows', () => {
  it('passes a record row that names its instrument and backs its source with a snippet', () => {
    expect(ids(good)).toEqual([]);
  });
  it('sends a clean statement row to human review and flags nothing else', () => {
    expect(ids({ ...good, evidence_type: 'statement', reasoning: 'Said at the 2026 forum she backs a public option.' }))
      .toEqual(['statement-needs-review']);
  });
  it('does not gate an explicit insufficient-evidence row (value null)', () => {
    expect(ids({ ...good, value: null, source_urls: [] })).toEqual([]);
  });
});

describe('checkStanceRow — every planted defect is caught (positive controls)', () => {
  it.each([
    ['value-out-of-range', { value: 7 }],
    ['no-source', { source_urls: [] }],
    ['evidence-type-invalid', { evidence_type: 'vibes' }],
    ['record-no-instrument', { reasoning: 'She is a strong supporter of expanding coverage.' }],
    ['party-inference', { reasoning: 'Voted YES on HB 1001; as a Republican she follows the caucus.' }],
  ] as const)('%s', (want, patch) => {
    expect(ids({ ...good, ...patch })).toContain(want);
  });
  it('source-without-snippet', () => {
    expect(ids({ ...good, source_urls: ['https://a.gov/x', 'https://b.gov/y'] })).toEqual(['source-without-snippet']);
  });
  it('snippet-too-short', () => {
    expect(ids(good, { evidence: [{ ...ev[0], snippet: 'Jane Doe voted yes on HB 1001.' }] })).toEqual(['snippet-too-short']);
  });
  it('topic-not-in-season', () => {
    expect(ids({ ...good, topic_key: 'no-such-topic' }, { topic: undefined })).toEqual(['topic-not-in-season']);
  });
  it('topic-out-of-scope', () => {
    expect(ids({ ...good, topic_key: 'rent-regulation' }, { topic: RENT, evidence: [] })).toContain('topic-out-of-scope');
  });
  it('level-unknown is a review signal, not a block', () => {
    const f = checkStanceRow(good, { topic: HEALTH, politician: { ...JANE, level: null }, evidence: ev });
    expect(f).toEqual([expect.objectContaining({ check_id: 'level-unknown', severity: 'medium' })]);
  });
  it('unknown-politician', () => {
    expect(ids(good, { politician: undefined })).toContain('unknown-politician');
  });
});

describe('refusals still refuse', () => {
  it('lower-case "democratic process" is not a party tell', () => {
    expect(PARTY_NAMES.test('protects the democratic process')).toBe(false);
    expect(ids({ ...good, reasoning: 'Voted YES on HB 1001 to protect the democratic process.' })).toEqual([]);
  });
});

describe('checkBatch / toStanceRows', () => {
  it('matches rows to topics, people and evidence by name (case-insensitive)', () => {
    const f = checkBatch([{ ...good, full_name: 'jane doe' }], [HEALTH], [JANE], ev);
    expect(f).toEqual([]);
  });
  it('carries the bundle politician_id into verifier rows', () => {
    expect(toStanceRows([good], [JANE])).toEqual([
      { full_name: 'Jane Doe', politician_id: 'p1', topic_key: 'healthcare', value: 2, reasoning: good.reasoning },
    ]);
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npx vitest run scripts/lib/stanceGate.test.ts`
Expected: FAIL — `Cannot find module './stanceGate.js'`.

- [ ] **Step 3: Implement** — `backend/scripts/lib/stanceGate.ts`

```ts
/**
 * stanceGate — deterministic checks on the STANCE side of a research batch.
 *
 * The snippet verifier (src/lib/researchVerifier.ts) proves a quoted passage is really on the
 * cited page. It does not ask whether a row cites anything at all, whether the evidence can tell
 * ONE chair from its neighbour, whether party stood in for evidence, or whether the topic is a
 * question this season asks of this office. Those are these checks. Pure — no DB, no network —
 * so every rule, and every refusal, is pinned by stanceGate.test.ts.
 *
 * Two evidence classes (operator decision 2026-09-22):
 *   record    — something done in office. Must name the instrument (NAMES_INSTRUMENT). The
 *               regex is NOT widened here: a separate lane, not a looser gate.
 *   statement — the person's own words. No instrument to name, so it goes to human review.
 */
import { NAMES_INSTRUMENT } from './chair-evidence-patterns.mjs';
import {
  MIN_SNIPPET_WORDS, normalizeText, type EvidenceRow, type StanceRow,
} from '../../src/lib/researchVerifier.js';
import { appliesToLevel, type Level, type TopicApplicability } from '../../src/lib/topicApplicability.js';

export interface ResearchRow {
  full_name: string;
  topic_key: string;
  value: number | null;
  reasoning: string;
  evidence_type: string;
  source_urls: string[];
}
export interface BundleTopic extends TopicApplicability {
  topic_id: string;
  topic_key: string;
  topic_revision_id: string;
  question_number: number;
  title: string;
  question_text: string;
  stances: { value: number; text: string }[];
}
export interface BundlePolitician { full_name: string; politician_id: string; level: Level | null; race_id: string | null }
export type GateCheckId =
  | 'unknown-politician' | 'value-out-of-range' | 'topic-not-in-season' | 'topic-out-of-scope'
  | 'level-unknown' | 'no-source' | 'source-without-snippet' | 'snippet-too-short'
  | 'evidence-type-invalid' | 'record-no-instrument' | 'statement-needs-review' | 'party-inference';
export interface GateFinding {
  full_name: string; topic_key: string; check_id: GateCheckId; severity: 'high' | 'medium'; what: string;
}

/** Capitalised party names only: "the democratic process" is not a party tell; "Democratic nominee" is. */
export const PARTY_NAMES = /\b(Democrats?|Democratic|Republicans?|GOP|Libertarians?|Lincoln Party|Green Party)\b/;
export const PARTY_PHRASES =
  /\b(party (?:line|platform|affiliation|position)|as an? (?:conservative|liberal|progressive)|consistent with (?:her|his|their) party)\b/i;

const wordCount = (s: string) => normalizeText(s).split(' ').filter(Boolean).length;

export function checkStanceRow(
  row: ResearchRow,
  ctx: { topic: BundleTopic | undefined; politician: BundlePolitician | undefined; evidence: EvidenceRow[] },
): GateFinding[] {
  const out: GateFinding[] = [];
  const add = (check_id: GateCheckId, severity: 'high' | 'medium', what: string) =>
    out.push({ full_name: row.full_name, topic_key: row.topic_key, check_id, severity, what });

  // value=null is the researcher's explicit "insufficient evidence": nothing proposed, nothing to gate.
  if (row.value === null) return out;

  if (!ctx.politician) add('unknown-politician', 'high', `${row.full_name} is not in politicians.json — rebuild the bundle with this person`);
  if (!Number.isInteger(row.value) || row.value < 1 || row.value > 5) add('value-out-of-range', 'high', `value ${row.value} is not an integer 1-5`);

  if (!ctx.topic) {
    add('topic-not-in-season', 'high', `${row.topic_key} is not a question the open season asks — it cannot be written`);
  } else if (ctx.politician) {
    if (!ctx.politician.level) add('level-unknown', 'medium', `office level unknown for ${row.full_name}; scope not checked`);
    else if (!appliesToLevel(ctx.topic, ctx.politician.level)) add('topic-out-of-scope', 'high', `${row.topic_key} does not apply at the ${ctx.politician.level} level`);
  }

  if (row.source_urls.length === 0) add('no-source', 'high', 'no source URL');
  for (const url of row.source_urls) {
    const forUrl = ctx.evidence.filter((e) => e.source_url === url);
    if (forUrl.length === 0) add('source-without-snippet', 'high', `no evidence.csv snippet for ${url}`);
    for (const e of forUrl) {
      const n = wordCount(e.snippet);
      if (n < MIN_SNIPPET_WORDS) add('snippet-too-short', 'high', `snippet ${e.snippet_index} for ${url} has ${n} words (< ${MIN_SNIPPET_WORDS})`);
    }
  }

  if (row.evidence_type === 'record') {
    if (!NAMES_INSTRUMENT.test(row.reasoning)) add('record-no-instrument', 'high', 'record evidence must name the bill, act, ordinance or recorded vote');
  } else if (row.evidence_type === 'statement') {
    add('statement-needs-review', 'medium', "statement evidence (the person's own words) goes to human review");
  } else {
    add('evidence-type-invalid', 'high', `evidence_type "${row.evidence_type}" must be record or statement`);
  }

  if (PARTY_NAMES.test(row.reasoning) || PARTY_PHRASES.test(row.reasoning)) {
    add('party-inference', 'high', 'reasoning names a party or partisan frame — party is never evidence');
  }
  return out;
}

export function checkBatch(
  rows: ResearchRow[], topics: BundleTopic[], politicians: BundlePolitician[], evidence: EvidenceRow[],
): GateFinding[] {
  const topicByKey = new Map(topics.map((t) => [t.topic_key, t]));
  const polByName = new Map(politicians.map((p) => [p.full_name.toLowerCase(), p]));
  return rows.flatMap((r) => checkStanceRow(r, {
    topic: topicByKey.get(r.topic_key),
    politician: polByName.get(r.full_name.toLowerCase()),
    evidence: evidence.filter((e) => e.full_name.toLowerCase() === r.full_name.toLowerCase() && e.topic_key === r.topic_key),
  }));
}

export function toStanceRows(rows: ResearchRow[], politicians: BundlePolitician[]): StanceRow[] {
  const polByName = new Map(politicians.map((p) => [p.full_name.toLowerCase(), p]));
  return rows.map((r) => ({
    full_name: r.full_name,
    politician_id: polByName.get(r.full_name.toLowerCase())?.politician_id ?? '',
    topic_key: r.topic_key,
    value: r.value,
    reasoning: r.reasoning,
  }));
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `npx vitest run scripts/lib/stanceGate.test.ts`
Expected: PASS (all cases).

- [ ] **Step 5: Typecheck** — `npm run typecheck`. If it reports TS7016 ("could not find a declaration file for module './chair-evidence-patterns.mjs'"), create `backend/scripts/lib/chair-evidence-patterns.d.mts`:

```ts
export declare const NAMES_INSTRUMENT: RegExp;
export declare const INSTRUMENT_SRC: RegExp;
```

and re-run until clean. (Skip this file if typecheck is already clean.)

- [ ] **Step 6: Commit**

```bash
printf 'feat(stance-research): deterministic stance-row gate\n\nCatches what the snippet verifier cannot: uncited rows, sources with no\nverbatim snippet, record evidence naming no instrument, party inference,\ntopics outside the open season or the office'"'"'s scope. Statement evidence is\nrouted to human review (two-class rule, 2026-09-22). Pure and fully tested.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t3.txt
git add -- scripts/lib/stanceGate.ts scripts/lib/stanceGate.test.ts $(ls scripts/lib/chair-evidence-patterns.d.mts 2>/dev/null)
git commit -F /tmp/t3.txt -- scripts/lib/stanceGate.ts scripts/lib/stanceGate.test.ts $(ls scripts/lib/chair-evidence-patterns.d.mts 2>/dev/null)
```

---

### Task 4: Stance gate CLI

**Files:**
- Create: `backend/scripts/stance-gate.ts`

**Interfaces:**
- Consumes: `checkBatch`, `toStanceRows`, `ResearchRow`, `BundleTopic`, `BundlePolitician` (Task 3); `parseEvidenceCsv`, `writeStancesCsv` (`src/lib/stanceResearchCsv.js`).
- Produces: `<dir>/gate-findings.json` = `{ findings: GateFinding[], summary: { rows: number, high: number, medium: number, by_check: Record<string, number> } }`; `<dir>/stances.csv` (verifier input). Exit 0 clean · 1 high findings · 2 usage/unreadable.

- [ ] **Step 1: Implement** — `backend/scripts/stance-gate.ts`

```ts
/**
 * stance-gate.ts — deterministic pre-write gate for a stance-research batch. No network, no DB.
 *
 * Reads <dir>/research.csv, evidence.csv, topics.json, politicians.json (see
 * build-stance-topic-bundle.ts). Writes gate-findings.json and stances.csv (the input
 * verify-stance-research.ts expects).
 *
 *   npx tsx scripts/stance-gate.ts --dir data/stance-research/<batch>
 * Exit: 0 clean, 1 high-severity findings (fix research.csv/evidence.csv and re-run), 2 usage.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { parseEvidenceCsv, writeStancesCsv } from '../src/lib/stanceResearchCsv.js';
import { checkBatch, toStanceRows, type ResearchRow, type BundleTopic, type BundlePolitician } from './lib/stanceGate.js';

const i = process.argv.indexOf('--dir');
const DIR = i !== -1 ? process.argv[i + 1] : undefined;
if (!DIR) { console.error('usage: stance-gate.ts --dir <batch>'); process.exit(2); }
for (const f of ['research.csv', 'topics.json', 'politicians.json']) {
  if (!existsSync(join(DIR, f))) { console.error(`ERROR: ${join(DIR, f)} not found`); process.exit(2); }
}

const records = parse(readFileSync(join(DIR, 'research.csv'), 'utf8'),
  { columns: true, skip_empty_lines: true, relax_column_count: true }) as Record<string, string>[];
const research: ResearchRow[] = records
  .map((r) => ({
    full_name: (r.full_name ?? '').trim(),
    topic_key: (r.topic_key ?? '').trim(),
    value: r.value && r.value.trim() !== '' ? Number(r.value) : null,
    reasoning: r.reasoning ?? '',
    evidence_type: (r.evidence_type ?? '').trim(),
    source_urls: [r.source_url_1, r.source_url_2, r.source_url_3].map((s) => (s ?? '').trim()).filter(Boolean),
  }))
  .filter((r) => r.full_name);
// Positive-control rule (CLAUDE.md): a detector that parsed nothing must not report "clean".
if (research.length === 0) {
  console.error('REFUSING VERDICT: parsed 0 research rows from research.csv — an empty parse is not a clean batch');
  process.exit(2);
}
const evidence = existsSync(join(DIR, 'evidence.csv')) ? parseEvidenceCsv(readFileSync(join(DIR, 'evidence.csv'), 'utf8')) : [];
const topics: BundleTopic[] = JSON.parse(readFileSync(join(DIR, 'topics.json'), 'utf8'));
const politicians: BundlePolitician[] = JSON.parse(readFileSync(join(DIR, 'politicians.json'), 'utf8'));

const findings = checkBatch(research, topics, politicians, evidence);
const by_check: Record<string, number> = {};
for (const f of findings) by_check[f.check_id] = (by_check[f.check_id] ?? 0) + 1;
const summary = {
  rows: research.length,
  high: findings.filter((f) => f.severity === 'high').length,
  medium: findings.filter((f) => f.severity === 'medium').length,
  by_check,
};
writeFileSync(join(DIR, 'gate-findings.json'), JSON.stringify({ findings, summary }, null, 2));
writeFileSync(join(DIR, 'stances.csv'), writeStancesCsv(toStanceRows(research, politicians)));

console.log(`stance-gate: ${summary.rows} rows · high=${summary.high} medium=${summary.medium} · evidence rows=${evidence.length}`);
for (const f of findings) console.log(`  ${f.severity.padEnd(6)} ${f.check_id.padEnd(24)} ${f.full_name} / ${f.topic_key}: ${f.what}`);
process.exit(summary.high > 0 ? 1 : 0);
```

- [ ] **Step 2: Positive control — the empty-parse guard refuses**

```bash
mkdir -p /tmp/gate-empty && cp /tmp/bundle-check/*.json /tmp/gate-empty/ && printf 'full_name,topic_key,value\n' > /tmp/gate-empty/research.csv
npx tsx scripts/stance-gate.ts --dir /tmp/gate-empty; echo "exit=$?"
```

Expected: `REFUSING VERDICT: parsed 0 research rows` and `exit=2`.

- [ ] **Step 3: Typecheck and commit**

```bash
npm run typecheck
printf 'feat(stance-research): stance-gate CLI with exit codes\n\nNon-interactive so the pipeline can later run on a schedule. Refuses a verdict\non an empty parse (positive-control rule).\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t4.txt
git add -- scripts/stance-gate.ts
git commit -F /tmp/t4.txt -- scripts/stance-gate.ts
```

---

### Task 5: Publish policy

**Files:**
- Create: `backend/scripts/lib/stancePublishPolicy.ts`
- Create: `backend/scripts/lib/stancePublishPolicy.test.ts`

**Interfaces:**
- Consumes: `GateFinding` (Task 3).
- Produces: `decidePublish(input: PolicyInput): Decision` where `PolicyInput = { proposedValue: number; verifiedSourceCount: number; threshold: number; gateFindings: GateFinding[]; politicianResolved: boolean; existingOpenSeasonValue: number | null }` and `Decision = {action:'auto-push'} | {action:'unchanged'} | {action:'review'; reasons: ReviewReason[]} | {action:'re-research'; reasons: ReReason[]}`; `ReviewReason = 'unresolved-politician'|'statement-evidence'|'gate-medium'|'value-change'`; `ReReason = 'gate-high'|'below-threshold'`.

- [ ] **Step 1: Write the failing test** — `backend/scripts/lib/stancePublishPolicy.test.ts`

```ts
import { describe, it, expect } from 'vitest';
import { decidePublish, type PolicyInput } from './stancePublishPolicy.js';
import type { GateFinding } from './stanceGate.js';

const f = (check_id: GateFinding['check_id'], severity: GateFinding['severity']): GateFinding =>
  ({ full_name: 'Jane Doe', topic_key: 'healthcare', check_id, severity, what: '' });
const base: PolicyInput = {
  proposedValue: 2, verifiedSourceCount: 1, threshold: 1, gateFindings: [],
  politicianResolved: true, existingOpenSeasonValue: null,
};

describe('decidePublish', () => {
  it('auto-pushes only a clean, verified, NEW record row', () => {
    expect(decidePublish(base)).toEqual({ action: 'auto-push' });
  });
  it('routes an unresolved politician to review first', () => {
    expect(decidePublish({ ...base, politicianResolved: false, gateFindings: [f('no-source', 'high')] }))
      .toEqual({ action: 'review', reasons: ['unresolved-politician'] });
  });
  it('sends any high gate finding back to research — before the verifier count is even considered', () => {
    expect(decidePublish({ ...base, verifiedSourceCount: 0, gateFindings: [f('party-inference', 'high')] }))
      .toEqual({ action: 're-research', reasons: ['gate-high'] });
  });
  it('sends an unverified row back to research', () => {
    expect(decidePublish({ ...base, verifiedSourceCount: 0 })).toEqual({ action: 're-research', reasons: ['below-threshold'] });
  });
  it('treats a matching open-season value as a no-op', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 2 })).toEqual({ action: 'unchanged' });
  });
  it('never changes an existing open-season value without a human', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 4 })).toEqual({ action: 'review', reasons: ['value-change'] });
  });
  it('treats an editor blank (0) as an existing value — re-seating it is an editor call', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 0 })).toEqual({ action: 'review', reasons: ['value-change'] });
  });
  it('queues statement evidence for review, accumulating other reasons', () => {
    expect(decidePublish({ ...base, existingOpenSeasonValue: 5,
      gateFindings: [f('statement-needs-review', 'medium'), f('level-unknown', 'medium')] }))
      .toEqual({ action: 'review', reasons: ['statement-evidence', 'gate-medium', 'value-change'] });
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npx vitest run scripts/lib/stancePublishPolicy.test.ts`
Expected: FAIL — `Cannot find module './stancePublishPolicy.js'`.

- [ ] **Step 3: Implement** — `backend/scripts/lib/stancePublishPolicy.ts`

```ts
/**
 * stancePublishPolicy — the one place that decides whether a researched stance may be written
 * without a human. Pure and tested, so an unattended (scheduled) run makes exactly the decision
 * an interactive one does.
 *
 * Only a NEW, record-evidenced, gate-clean, page-verified row auto-publishes. Everything else is
 * either sent back to research (defective) or queued for a person (inform.stance_research_review).
 */
import type { GateFinding } from './stanceGate.js';

export type ReviewReason = 'unresolved-politician' | 'statement-evidence' | 'gate-medium' | 'value-change';
export type ReReason = 'gate-high' | 'below-threshold';
export type Decision =
  | { action: 'auto-push' }
  | { action: 'unchanged' }
  | { action: 'review'; reasons: ReviewReason[] }
  | { action: 're-research'; reasons: ReReason[] };

export interface PolicyInput {
  proposedValue: number;
  verifiedSourceCount: number;
  threshold: number;
  gateFindings: GateFinding[];
  politicianResolved: boolean;
  /** Value already stored in the OPEN season; null = none. A 0 is an editor's blank and counts. */
  existingOpenSeasonValue: number | null;
}

export function decidePublish(i: PolicyInput): Decision {
  if (!i.politicianResolved) return { action: 'review', reasons: ['unresolved-politician'] };
  if (i.gateFindings.some((f) => f.severity === 'high')) return { action: 're-research', reasons: ['gate-high'] };
  if (i.verifiedSourceCount < i.threshold) return { action: 're-research', reasons: ['below-threshold'] };
  if (i.existingOpenSeasonValue !== null && i.existingOpenSeasonValue === i.proposedValue) return { action: 'unchanged' };

  const reasons: ReviewReason[] = [];
  if (i.gateFindings.some((f) => f.check_id === 'statement-needs-review')) reasons.push('statement-evidence');
  if (i.gateFindings.some((f) => f.severity === 'medium' && f.check_id !== 'statement-needs-review')) reasons.push('gate-medium');
  // 🔴 A value already in the open season is never changed without a human — including a 0 (blank).
  if (i.existingOpenSeasonValue !== null) reasons.push('value-change');
  return reasons.length ? { action: 'review', reasons } : { action: 'auto-push' };
}
```

- [ ] **Step 4: Run it to verify it passes**

Run: `npx vitest run scripts/lib/stancePublishPolicy.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
printf 'feat(stance-research): pure publish policy for researched stances\n\nOnly a new, record-evidenced, gate-clean, verified row auto-publishes; changes\n(including re-seating a blank), statement evidence and flagged rows go to the\nreview queue. Encoded in code so a scheduled run decides exactly as a person would.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t5.txt
git add -- scripts/lib/stancePublishPolicy.ts scripts/lib/stancePublishPolicy.test.ts
git commit -F /tmp/t5.txt -- scripts/lib/stancePublishPolicy.ts scripts/lib/stancePublishPolicy.test.ts
```

---

### Task 6: One season-aware stance write

**Files:**
- Modify: `backend/src/lib/researchEvidenceService.ts` (`resolveResearchReview`, ~lines 195–240)
- Modify: `backend/src/lib/researchEvidenceService.test.ts`

**Interfaces:**
- Produces: `writeVerifiedStance(args: { politicianId: string; topicId: string; value: number; reasoning: string; sources: string[]; editorId: string | null }): Promise<void>` — throws (via `assertWritten`) if the open season wrote nothing.

- [ ] **Step 1: Write the failing test** — append to `backend/src/lib/researchEvidenceService.test.ts`

```ts
describe('writeVerifiedStance', () => {
  it('writes the answer then the context through the season-aware SQL, in param order', async () => {
    const { writeVerifiedStance } = await import('./researchEvidenceService.js');
    const { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL } = await import('./seasonService.js');
    const before = mockQuery.mock.calls.length;
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 1 }).mockResolvedValueOnce({ rows: [], rowCount: 1 });
    await writeVerifiedStance({ politicianId: 'p', topicId: 't', value: 3, reasoning: 'r', sources: ['u'], editorId: 'e' });
    const calls = mockQuery.mock.calls.slice(before);
    expect(calls[0]).toEqual([UPSERT_ANSWER_SQL, ['p', 't', 3, 'e']]);
    expect(calls[1]).toEqual([UPSERT_CONTEXT_SQL, ['p', 't', 'r', ['u'], 'e']]);
  });
  it('refuses to report success when the open season wrote nothing', async () => {
    const { writeVerifiedStance } = await import('./researchEvidenceService.js');
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });
    await expect(writeVerifiedStance({ politicianId: 'p', topicId: 't', value: 3, reasoning: 'r', sources: [], editorId: null }))
      .rejects.toThrow();
  });
});
```

- [ ] **Step 2: Run it to verify it fails**

Run: `npx vitest run src/lib/researchEvidenceService.test.ts`
Expected: FAIL — `writeVerifiedStance is not a function`.

- [ ] **Step 3: Implement** — in `backend/src/lib/researchEvidenceService.ts`, add above `resolveResearchReview`:

```ts
/**
 * Write one stance (answer + its public "why") into the OPEN season. The only stance write path
 * for research: verify-stance-research --apply and the review queue both call this.
 * Answer and context are written together on purpose — reasoning must never lag the value.
 * Throws if the open season wrote nothing (no open season, or topic not in its question set).
 */
export async function writeVerifiedStance(args: {
  politicianId: string; topicId: string; value: number; reasoning: string; sources: string[]; editorId: string | null;
}): Promise<void> {
  // Dynamic imports: a static import pulls db.js in before this file's tests install their mock.
  const { pool } = await import('./db.js');
  const { UPSERT_ANSWER_SQL, UPSERT_CONTEXT_SQL, assertWritten } = await import('./seasonService.js');
  const ans = await pool.query(UPSERT_ANSWER_SQL, [args.politicianId, args.topicId, args.value, args.editorId]);
  await assertWritten(ans.rowCount ?? 0, args.topicId);
  const ctx = await pool.query(UPSERT_CONTEXT_SQL,
    [args.politicianId, args.topicId, args.reasoning, args.sources, args.editorId]);
  await assertWritten(ctx.rowCount ?? 0, args.topicId);
}
```

Then in `resolveResearchReview`, replace everything from the comment `// Imported dynamically, like db.js above and for the same reason:` through `await assertWritten(ctx.rowCount ?? 0, row.topicId);` with:

```ts
  await writeVerifiedStance({
    politicianId: row.politicianId, topicId: row.topicId, value: finalValue,
    reasoning: finalReasoning, sources: allSources, editorId: resolvedBy,
  });
```

- [ ] **Step 4: Run it to verify it passes**

Run: `npx vitest run src/lib/researchEvidenceService.test.ts && npm run typecheck`
Expected: PASS (new and existing tests), typecheck clean.

- [ ] **Step 5: Commit**

```bash
printf 'refactor(stance-research): single season-aware writeVerifiedStance\n\nExtracted from resolveResearchReview so verify-stance-research --apply can stop\nusing its pre-seasons bare-pair INSERT.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t6.txt
git add -- src/lib/researchEvidenceService.ts src/lib/researchEvidenceService.test.ts
git commit -F /tmp/t6.txt -- src/lib/researchEvidenceService.ts src/lib/researchEvidenceService.test.ts
```

---

### Task 7: Rewire `verify-stance-research.ts`

**Files:**
- Modify: `backend/scripts/verify-stance-research.ts`

**Interfaces:**
- Consumes: `decidePublish`, `Decision` (Task 5); `GateFinding` (Task 3); `writeVerifiedStance` (Task 6); `OPEN_SEASON_ANSWER_SQL` (`src/lib/seasonService.js`, returns `topic_id, value, write_in_text` for `$1 = politician_id` in the open season).
- Produces: `<dir>/publish-report.json` = `{ full_name, topic_key, value, action, reasons, verified_sources, failed_urls }[]`. New flag `--editor-id <uuid>` (or env `EV_EDITOR_ID`), **required with `--apply`**. Requires `<dir>/gate-findings.json`.

- [ ] **Step 1: Header + args.** Replace the header sentence `fetches each cited URL with headless Chromium` with `fetches each cited URL through the tiered fetch ladder (HTTP → Wayback; src/lib/verificationFetch.ts)`, and add to the usage block ` [--editor-id <uuid>]` plus the line ` * Requires <dir>/gate-findings.json from scripts/stance-gate.ts.`. Add imports:

Change line 23 `import { readFileSync, existsSync } from 'node:fs';` to `import { readFileSync, existsSync, writeFileSync } from 'node:fs';` (one import per module — lint), and add:

```ts
import { writeVerifiedStance } from '../src/lib/researchEvidenceService.js';
import { OPEN_SEASON_ANSWER_SQL } from '../src/lib/seasonService.js';
import { decidePublish, type Decision } from './lib/stancePublishPolicy.js';
import type { GateFinding } from './lib/stanceGate.js';
```

After `const RE_RESEARCHED = ...` add:

```ts
const EDITOR_ID = opt('--editor-id', process.env.EV_EDITOR_ID) ?? null;
if (APPLY && !EDITOR_ID) {
  console.error('ERROR: --apply needs --editor-id <admin user uuid> (or EV_EDITOR_ID) — a stance nobody authored is a row nobody can be asked about');
  process.exit(2);
}
const gatePath = join(DIR, 'gate-findings.json');
if (!existsSync(gatePath)) {
  console.error(`ERROR: ${gatePath} not found — run scripts/stance-gate.ts --dir ${DIR} first`);
  process.exit(2);
}
const gateByKey = new Map<string, GateFinding[]>();
for (const f of (JSON.parse(readFileSync(gatePath, 'utf8')).findings as GateFinding[])) {
  const k = `${f.full_name.toLowerCase()} ${f.topic_key}`;
  gateByKey.set(k, [...(gateByKey.get(k) ?? []), f]);
}
```

- [ ] **Step 2: Topic resolution from the open season.** Replace the `topicRows` query (`SELECT id AS topic_id, topic_key FROM inform.compass_topics WHERE is_live = true`) with:

```ts
// 🔴 The open season's question set — not is_live. A stance can only be written to a
// question the open season asks; is_live and the season's set disagreed on 2026-09-22.
const { rows: topicRows } = await pool.query<{ topic_id: string; topic_key: string }>(
  `SELECT t.id AS topic_id, t.topic_key
     FROM inform.season_questions sq
     JOIN inform.seasons s ON s.id = sq.season_id AND s.status = 'open'
     JOIN inform.compass_topics t ON t.id = sq.topic_id`,
);
```

Also change the comment `// Tiered fetch ladder (HTTP → headless Chromium → Wayback), reusing one browser` to `// Tiered fetch ladder (HTTP → Wayback). No LLM in the loop.`

- [ ] **Step 3: Decide every scored row.** Directly after `await fetchSession.close();`, replace the `reResearch` / `unresolved` / `failedUrls` block and the whole `// ---- report` section with:

```ts
const failedUrls = (row: VerifiedRow) => row.failedSources.map((s) => s.url);

// Existing OPEN-season values — the thing a write would replace.
const existing = new Map<string, number>();
for (const pid of new Set([...idByName.values()].filter((v): v is string => Boolean(v)))) {
  const { rows } = await pool.query<{ topic_id: string; value: string }>(OPEN_SEASON_ANSWER_SQL, [pid]);
  for (const r of rows) existing.set(`${pid} ${r.topic_id}`, Number(r.value));
}

type Decided = { row: VerifiedRow; pid: string | null; tid: string | null; decision: Decision };
const decided: Decided[] = [...pushable, ...needsReResearch].map((row) => {
  const pid = idByName.get(row.stance.full_name) ?? null;
  const tid = topicIdByKey.get(row.stance.topic_key) ?? null;
  const ex = pid && tid ? existing.get(`${pid} ${tid}`) : undefined;
  const decision = decidePublish({
    proposedValue: row.stance.value as number,
    verifiedSourceCount: row.verifiedSources.length,
    threshold: THRESHOLD,
    gateFindings: gateByKey.get(`${row.stance.full_name.toLowerCase()} ${row.stance.topic_key}`) ?? [],
    politicianResolved: Boolean(pid),
    existingOpenSeasonValue: ex === undefined ? null : ex,
  });
  return { row, pid, tid, decision };
});
const bucket = (a: Decision['action']) => decided.filter((d) => d.decision.action === a);
const reasonsOf = (d: Decided): string[] => ('reasons' in d.decision ? [...d.decision.reasons] : []);

writeFileSync(join(DIR, 'publish-report.json'), JSON.stringify(decided.map((d) => ({
  full_name: d.row.stance.full_name, topic_key: d.row.stance.topic_key, value: d.row.stance.value,
  action: d.decision.action, reasons: reasonsOf(d),
  verified_sources: d.row.verifiedSources.map((s) => s.url), failed_urls: failedUrls(d.row),
})), null, 2));

console.log(`\n=== verify-stance-research — batch "${BATCH_ID}" (threshold ${THRESHOLD}) ===`);
console.log(`stance rows: ${allStances.length} (${stanceRows.length} scored, ${nullRows.length} value=null skipped) | evidence rows: ${evidenceRows.length}`);
console.log(`AUTO-PUSH: ${bucket('auto-push').length}  UNCHANGED: ${bucket('unchanged').length}  REVIEW: ${bucket('review').length}  RE-RESEARCH: ${bucket('re-research').length}`);
for (const d of decided) {
  const s = d.row.stance;
  console.log(`  ${d.decision.action.toUpperCase().padEnd(11)} ${s.full_name}\t${s.topic_key}\tvalue=${s.value}\tverified=${d.row.verifiedSources.length}`
    + (reasonsOf(d).length ? `\t[${reasonsOf(d).join(', ')}]` : '')
    + (d.decision.action === 're-research' ? `\texclude-urls=${failedUrls(d.row).join(',') || '(none)'}` : ''));
}
if (nullRows.length) {
  console.log('\n--- value=null (skipped; not pushed, not queued) ---');
  for (const s of nullRows) console.log(`  SKIP\t${s.full_name}\t${s.topic_key}`);
}
console.log(`\nwrote ${join(DIR, 'publish-report.json')}`);
```

- [ ] **Step 4: Apply through the policy.** Replace the two write loops (`for (const row of pushable) { ... }` and `for (const row of [...reResearch, ...unresolved]) { ... }`) with:

```ts
for (const d of bucket('auto-push')) {
  const { row, pid, tid } = d;
  try {
    await writeVerifiedStance({
      politicianId: pid!, topicId: tid!, value: row.stance.value as number,
      reasoning: row.stance.reasoning, sources: row.verifiedSources.map((s) => s.url), editorId: EDITOR_ID,
    });
    const evRows = buildEvidenceRowsForInsert({ row, politicianId: pid!, topicId: tid!, batchId: BATCH_ID });
    await accumulateEvidence(evRows);
    pushed++; evidenceWritten += evRows.length; pushedPoliticianIds.add(pid!);
    console.log(`  PUSHED ${row.stance.full_name}/${row.stance.topic_key} value=${row.stance.value} (${evRows.length} snippets)`);
  } catch (e: any) {
    errors.push(`PUSH ${row.stance.full_name}/${row.stance.topic_key}: ${e.message}`);
  }
}

// Review rows and below-threshold rows go to the human queue. Gate-high rows are NOT written:
// the research itself is defective — fix research.csv / evidence.csv and re-run.
const queued = decided.filter((d) => d.decision.action === 'review'
  || (d.decision.action === 're-research' && reasonsOf(d).includes('below-threshold')));
for (const { row, pid, tid } of queued) {
  try {
    await upsertReviewRow(buildReviewRowForInsert({
      row, politicianId: pid, topicId: pid ? tid : null, batchId: BATCH_ID,
      threshold: THRESHOLD, reResearchAttempted: RE_RESEARCHED,
    }));
    reviewed++;
    console.log(`  REVIEW ${row.stance.full_name}/${row.stance.topic_key}`);
    if (pid && tid && row.verifiedSources.length > 0) {
      const evRows = buildEvidenceRowsForInsert({ row, politicianId: pid, topicId: tid, batchId: BATCH_ID });
      await accumulateEvidence(evRows);
      evidenceWritten += evRows.length;
    }
  } catch (e: any) {
    errors.push(`REVIEW ${row.stance.full_name}/${row.stance.topic_key}: ${e.message}`);
  }
}
```

Keep the existing `last_stances_researched_at` stamp, `SUMMARY`, error printing and `pool.end()` unchanged. Delete the now-unused `reResearch` / `unresolved` variables if any reference remains.

- [ ] **Step 5: Verify** — `npm run typecheck && npm run lint && npx vitest run scripts/lib src/lib/researchEvidenceService.test.ts`
Expected: all clean. (The script's end-to-end behaviour is proven in Task 10.)

- [ ] **Step 6: Commit**

```bash
printf 'fix(stance-research): verifier writes through the season model and the publish policy\n\nOpen-season topic set instead of is_live; gate findings + existing open-season\nvalues feed decidePublish; auto-push via writeVerifiedStance (replaces the\npre-seasons bare-pair INSERT); review/below-threshold to the review queue;\n--editor-id required for --apply; publish-report.json for review and scheduling.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t7.txt
git add -- scripts/verify-stance-research.ts
git commit -F /tmp/t7.txt -- scripts/verify-stance-research.ts
```

---

### Task 8: Rewrite the skill around the pipeline

**Files:**
- Modify: `.claude/skills/research-stances/SKILL.md`

Make these edits (anchors are exact existing text):

- [ ] **Step 1: Canonical-copy + pipeline note.** Directly after the blockquote that ends `…only once the audit is clean (STEP 4).`, insert:

```markdown
> 🔴 **ONE CANONICAL COPY.** This skill and `.claude/agents/politician-stance-researcher.md` live in
> the ev-accounts repo. Older copies at the workspace root and in `.agents/` were up to three months
> stale (2026-09-22). If you are reading this anywhere else, stop and use the ev-accounts copy.
>
> **The stance pipeline, one line:** `build-stance-topic-bundle` → researcher agent →
> `stance-gate` → `verify-stance-research` (dry-run) → human review → `verify-stance-research --apply`.
> Every step is a non-interactive script with exit codes, so the same pipeline can later run on a
> schedule. Human decisions go to the review queue (`inform.stance_research_review`), not the chat.
```

- [ ] **Step 2: Jurisdiction resolution.** Replace the SQL inside the first `node --import tsx -e` block under `### Jurisdiction Resolution` (it references `o2.politician_id` / `o3.politician_id`, both dropped in mig 1463) with:

```sql
  SELECT DISTINCT ON (p.id) p.id, p.full_name, o.title, c.name AS chamber_name
    FROM essentials.office_current_holder och
    JOIN essentials.offices o ON o.id = och.office_id
    JOIN essentials.chambers c ON c.id = o.chamber_id
    JOIN essentials.politicians p ON p.id = och.politician_id
   WHERE c.name ILIKE '%' || \$1 || '%'
   ORDER BY p.id, o.title
```

and add below the block: `DISTINCT ON (p.id) is required — a politician-rooted join fans out for anyone holding two offices (CLAUDE.md).`

- [ ] **Step 3: Topic resolution.** Replace the whole `### Topic Resolution` section (heading through the paragraph ending `…this number will grow.`) with:

```markdown
### Topic Resolution — the open season's questions, per office level

**Never query `inform.compass_stances` or `is_live`.** The open season pins a specific ladder
revision per question; on 2026-09-22, 29 of Season 2's 60 ladders differed from the frozen legacy
text, and `is_live` returned 44 topics against the season's 60. Build the batch bundle instead:

​```bash
cd ev-accounts/backend && set -a && source .env && set +a
npx tsx scripts/build-stance-topic-bundle.ts --dir data/stance-research/<YYYY-MM-DD-batch> \
  --race <race_id> [--race <race_id> ...]          # candidates on these races
  # or, for officeholders not on a race:  --politician <uuid>:<federal|state|local|judicial>
​```

It writes `topics.json` + `politicians.json` into the batch dir and prints one
`TOPIC SCALE REFERENCE (<level>)` block per office level — already filtered to the topics that
apply at that level (`compass_topic_roles`). Paste the block matching each politician's level
into that politician's prompt. A politician printed under `level unknown` needs a person to set
the level (`--politician <uuid>:<level>`) before research.
```

(Remove the zero-width space `​` from before the inner code fences when pasting — it is only there to keep this plan's markdown valid.)

- [ ] **Step 4: Confirm-before-proceeding scope line.** In the same area, change `Estimated scope (e.g., "3 politicians x 44 topics = up to 132 stance assessments")` to `Estimated scope from the bundle (politicians × in-scope topics for each one's level)`.

- [ ] **Step 5: Agent prompt — output and evidence contract.** In the `**Agent prompt template:**` block:
  - Replace `--output-file [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME].csv` with `--output-dir [ABSOLUTE_PATH]/ev-accounts/backend/data/stance-research/YYYY-MM-DD-[BATCH_NAME]`.
  - Replace `[PASTE THE FULL JSON OUTPUT FROM THE TOPIC RESOLUTION QUERY HERE — including id, topic_key, question_text, and the stances array with value+text for each of the 5 levels]` with `[PASTE THE TOPIC SCALE REFERENCE BLOCK FOR THIS POLITICIAN'S LEVEL, printed by build-stance-topic-bundle.ts]`.
  - Replace the whole `TOPIC PRIORITY BY OFFICE LEVEL …` paragraph (through `Skip a topic ONLY when you genuinely cannot find sufficient evidence — never skip by assumption.`) with: `The TOPIC SCALE REFERENCE is already filtered to the questions this season asks of this office. Research only those; skip a topic when you cannot find evidence for a specific chair.`
  - Replace the `CSV OUTPUT — columns …` line and its `editor_note` bullet with:

```
TWO OUTPUT FILES, both in --output-dir (RFC-4180; quote any field containing commas; double embedded quotes):
1) research.csv:
   full_name,topic_key,value,evidence_type,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified,editor_note
   - editor_note: REQUIRED for every row with a quote_text (see EDITOR NOTE RULE).
2) evidence.csv:
   full_name,topic_key,source_url,snippet,snippet_index

EVIDENCE CONTRACT — every stance row must be provable from the page it cites:
- evidence_type = "record" when the stance rests on something the person DID in office (a bill, act,
  ordinance, recorded vote); "statement" when it rests on their own words (questionnaire, debate,
  forum, interview, campaign platform). A challenger with no record uses "statement".
- record rows: the reasoning MUST name the instrument, e.g. "Voted YES on HB 1001 (2025)".
- For EVERY source_url_N in research.csv, write at least one evidence.csv row whose snippet is a
  VERBATIM passage of at least 25 words, copied from that page as you fetched it, that shows the
  position and names this person (or sits within a few sentences of their name). Copy — never retype,
  trim to fit, or summarise. A source you cannot back with a verbatim snippet does not go in the row.
- The evidence must describe THIS chair, not just a direction. If it only shows which side the person
  is on and two or three chairs sit on that side, leave the value blank. "The least extreme chair the
  evidence allows" is a tiebreaker, not evidence.
- Never name a party, a party label, or a party-typical position in reasoning. Party is never evidence.
```

  - In `Other rules:`, replace the bullet `- Every source URL must be real and verifiable — only include URLs you actually fetched successfully` with `- Every source URL must be one you fetched successfully and backed in evidence.csv (OTR YouTube URLs from the transcript file count; their snippet is the transcript passage).`

- [ ] **Step 6: STEP 2.** Replace item 1 `Read the CSV file(s) generated by the agents` with `Read research.csv and evidence.csv from the batch dir`, and item 5's first sentence `The CSV includes …` so it starts `research.csv includes …`.

- [ ] **Step 7: STEP 3 value-change guard.** Replace the paragraph block from `### Value-Change Guard (diff proposed vs. existing)` through the three-bucket list ending `…flag it as such.` with:

```markdown
### Value-Change Guard — enforced in code

`verify-stance-research.ts` diffs every proposed value against the **open season** and applies
`decidePublish` (`backend/scripts/lib/stancePublishPolicy.ts`): a row already holding a value in
the open season — including a 0 (an editor's blank) — is **never** written automatically; it goes to
the review queue with reason `value-change`. Read the buckets from `publish-report.json`:

| action | meaning |
|---|---|
| `auto-push` | new, record-evidenced, gate-clean, verified — written on `--apply` |
| `unchanged` | same value already in the open season — skipped |
| `review` | queued for a person: `statement-evidence`, `value-change`, `gate-medium`, `unresolved-politician` |
| `re-research` | `gate-high` (defective — fix and re-run, not written) or `below-threshold` (unverified — queued) |
```

Keep the following paragraph `**The public summary MUST move with the value.** …` unchanged.

- [ ] **Step 8: STEP 4a.** Replace the `**(i) Mechanical + bundle.**` code block and its first sentence with:

```markdown
**(i) Stance gate, snippet verification, quote mechanics — in this order.**

​```bash
cd ev-accounts/backend && set -a && source .env && set +a
B=data/stance-research/YYYY-MM-DD-[BATCH_NAME]
npx tsx scripts/stance-gate.ts --dir $B              # exit 1 = high findings: fix research.csv/evidence.csv, re-run
npx tsx scripts/verify-stance-research.ts --dir $B   # dry-run: fetches every source, writes $B/publish-report.json
node ../.claude/skills/research-stances/scripts/build-and-check.mjs --csv $B/research.csv   # quotes
​```
```

Keep `Fix every **high** finding …` and the `**(ii) Judgment sub-agent.**` paragraph.

- [ ] **Step 9: STEP 4c.** Replace everything from the heading `### 4c. Upsert answers and context` through the paragraph ending `…Copy from this block instead.` with:

```markdown
### 4c. Write stances (and their verified snippets) through the verifier

​```bash
cd ev-accounts/backend && set -a && source .env && set +a
npx tsx scripts/verify-stance-research.ts --dir data/stance-research/YYYY-MM-DD-[BATCH_NAME] \
  --apply --editor-id <your admin user uuid>
​```

`auto-push` rows are written with `writeVerifiedStance` (season-aware: `UPSERT_ANSWER_SQL` +
`UPSERT_CONTEXT_SQL` + `assertWritten`) together with their verified snippets in
`politician_context_evidence`; `review` and `below-threshold` rows go to `stance_research_review`
for resolution in the admin review queue; `gate-high` rows are not written.

**Which season?** Whichever is open — check with
`SELECT number FROM inform.seasons WHERE status = 'open'`. Do not trust a season number written in a
doc; this one said "Season 1" for a month after Season 2 opened.

⚠️ **Never hand-roll a stance INSERT**, and never copy `backend/scripts/apply-*-stances.ts` — ~158 of
them carry the pre-seasons bare-pair upsert, which fails (`23502`) or silently writes nothing.
```

- [ ] **Step 10: Rewrite mode.** Directly under the heading `# REWRITE RE-EVALUATION MODE (`--rewrite-id`)`, insert:

```markdown
> 🔴 **DO NOT USE UNTIL REDESIGNED (2026-09-22).** This mode auto-approves every proposal with no
> human gate, and tells the researcher to map old evidence onto the new scale — CLAUDE.md requires a
> material rewrite to be **re-audited against the new wording** ("a bill citation proves direction,
> not magnitude"). It also bypasses the evidence gate above. Re-audit rewritten topics with the
> normal pipeline instead.
```

In its STEP 0 SQL, replace `LEFT JOIN essentials.offices o ON o.politician_id = pol.id AND o.is_current = true` and the following `LEFT JOIN essentials.chambers c ON c.id = o.chamber_id` with:

```sql
  LEFT JOIN LATERAL (
    SELECT o.title, c.name AS chamber_name
      FROM essentials.office_current_holder och
      JOIN essentials.offices o ON o.id = och.office_id
      LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
     WHERE och.politician_id = pol.id
     ORDER BY o.title LIMIT 1
  ) oc ON true
```

and change `o.title AS office_title, c.name AS chamber_name` in its SELECT to `oc.title AS office_title, oc.chamber_name`.

- [ ] **Step 11: Check for leftovers**

```bash
cd .. && grep -nE "compass_stances|is_live|politician_id = p\.id|is_current|Today that is Season 1|--output-file" .claude/skills/research-stances/SKILL.md
```

Expected: no matches except inside the warnings you just wrote (which say *not* to use them). Fix any other hit.

- [ ] **Step 12: Commit**

```bash
printf 'docs(research-stances): drive the skill through the evidence pipeline\n\nBundle from the open season; two output files with a verbatim-evidence contract\nand record/statement evidence classes; stance-gate + verifier before any write;\nwrites via verify-stance-research --apply. Removes the dropped-column queries and\nthe stale Season-1 text; fences off rewrite mode until redesigned.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t8.txt
git add -- .claude/skills/research-stances/SKILL.md
git commit -F /tmp/t8.txt -- .claude/skills/research-stances/SKILL.md
```

---

### Task 9: Rewrite the researcher agent's rules

**Files:**
- Modify: `.claude/agents/politician-stance-researcher.md`

- [ ] **Step 1: Frontmatter.** In `description:`, replace `across the 21 defined policy topics` with `across the compass topics supplied in the dispatch prompt`.

- [ ] **Step 2: Remove the hard-coded ladders.** Replace everything from the line `## POLICY TOPICS AND SCALES` up to (not including) `## RESEARCH METHODOLOGY` with:

```markdown
## POLICY TOPICS AND SCALES

The topics and their five chair texts are supplied in your dispatch prompt as the TOPIC SCALE
REFERENCE, fetched from the season that is open **right now** and filtered to this office's level.
**Never use a remembered, cached, or hard-coded ladder** — ladders are re-worded between seasons, and
an answer scored against old wording is an answer to a question nobody is asking.
```

- [ ] **Step 3: Source verification.** Replace the `### Source Verification` block (its heading and four bullets) with:

```markdown
### Source Verification
- **Every source must be backed by a verbatim snippet in evidence.csv** — a passage of at least 25
  words, copied from the page exactly as you fetched it, that shows the position and names this person.
  The pipeline re-fetches every page and rejects any snippet that is not on it.
- Never fabricate or reconstruct a URL. If you did not fetch it successfully, it does not go in the row.
- Prefer primary sources: legislature and roll-call pages, council minutes, the candidate's own site or
  questionnaire, debate/forum transcripts.
```

- [ ] **Step 4: Stance assessment.** In `### Stance Assessment`, replace the bullet `- **Actions over words** — A vote or signed bill outweighs a campaign promise.` with:

```markdown
- **Two evidence classes.** `record` = something done in office (bill, act, ordinance, recorded vote) —
  name it in the reasoning. `statement` = the person's own words (questionnaire, debate, forum,
  interview, platform) — the only evidence most challengers have, and valid when it describes a chair.
  When both exist and conflict, the record wins and the reasoning says so.
```

- [ ] **Step 5: Replace the inversion-traps table.** Replace everything from `### Scale Direction — Inversion Traps (MANDATORY self-check before returning any value)` through the line `- **SKIP a topic entirely** if you cannot find sufficient evidence. Do not guess.` with:

```markdown
### Reading the ladder (MANDATORY before returning any value)

There is **no** universal direction. Value 1 is not "liberal" and value 5 is not "conservative"; some
ladders are not left-right at all. For every value you return:
1. Read all five chair texts for THIS topic in the TOPIC SCALE REFERENCE.
2. Find the chair whose **words** the evidence matches — not the side you expect this kind of
   politician to be on.
3. **Never use party, a party label, or "what people like them usually think" to choose or adjust a
   value.** That is inference, not evidence, and the pipeline rejects reasoning that does it.
4. If the evidence shows only a direction and two or three chairs sit on that side, leave the value blank.
- **SKIP a topic entirely** if you cannot find evidence for a specific chair. Do not guess.
```

- [ ] **Step 6: Reasoning quality.** In `### Reasoning Quality`, replace the bullet `- Reference specific actions: bills sponsored, votes cast, executive orders, public statements.` with `- Name the evidence: the bill/ordinance/vote (record), or where and when they said it (statement).` and replace `Bad reasoning: "Likely moderate on this issue based on party affiliation." (no evidence)` with `Bad reasoning: "Likely moderate on this issue based on party affiliation." (party is never evidence — rejected by the pipeline)`.

- [ ] **Step 7: Output format.** Replace the `## OUTPUT FORMAT` section's column line and bullets (from `When asked to produce CSV output` through `Group all rows for a single politician together. No BOM character. Clean header row.`) with:

```markdown
Write TWO files (RFC-4180; wrap fields containing commas in double quotes; double embedded quotes).

**research.csv**
​```
full_name,topic_key,value,evidence_type,reasoning,source_url_1,source_url_2,source_url_3,quote_text,quote_deidentified,editor_note
​```
- `topic_key`: exactly a key from the TOPIC SCALE REFERENCE.
- `value`: integer 1-5, or blank when evidence is insufficient for a specific chair.
- `evidence_type`: `record` or `statement` (see Stance Assessment).
- `reasoning`: 1-3 sentences naming the evidence. Never mention party.
- `source_url_1..3`: only URLs you fetched AND backed in evidence.csv.
- `quote_text`, `quote_deidentified`, `editor_note`: unchanged rules (Quotes, gates, de-identification below).

**evidence.csv**
​```
full_name,topic_key,source_url,snippet,snippet_index
​```
- One row per supporting passage; at least one per source URL. `snippet` is verbatim, ≥ 25 words,
  and names or sits beside this person. `snippet_index` counts from 0 per (full_name, topic_key, source_url).

Group rows for one politician together. No BOM. Clean header rows.
```

(Remove the zero-width spaces before the inner fences when pasting.)

- [ ] **Step 8: File output.** Replace the first paragraph of `## FILE OUTPUT` with: `When your dispatch prompt includes --output-dir <path>, write research.csv and evidence.csv into that directory with the Write tool, each with its header row. If a file exists, append rows without repeating the header.`

- [ ] **Step 9: Self-audit.** In `## WORKFLOW` step 7, add these sub-bullets:

```markdown
   - every source URL in research.csv has at least one ≥25-word verbatim snippet in evidence.csv
   - every `record` row's reasoning names its instrument; no reasoning mentions a party
   - every value matches a chair's **words**, not a direction
```

- [ ] **Step 10: Check for leftovers**

```bash
grep -nE "21 defined|Inversion Traps|Democrats who|Republicans (who|opposing)|blue-city|conservative judges|--output-file" .claude/agents/politician-stance-researcher.md
```

Expected: no matches. Fix any hit.

- [ ] **Step 11: Commit**

```bash
printf 'docs(stance-researcher): evidence contract; drop hard-coded ladders and party shortcuts\n\nThe agent carried 36 hard-coded Season-1 ladders and an inversion table that\ncoached with party heuristics. It now reads the ladder supplied from the open\nseason, classifies evidence as record/statement, and backs every source with a\nverbatim snippet in evidence.csv.\n\nCo-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>\n' > /tmp/t9.txt
git add -- .claude/agents/politician-stance-researcher.md
git commit -F /tmp/t9.txt -- .claude/agents/politician-stance-researcher.md
```

---

### Task 10: End-to-end positive control (dry-run, no writes)

Prove the whole chain catches planted defects on a real politician before trusting it on Monroe.

**Files:** none committed. Work in `/tmp/gate-control/`.

- [ ] **Step 1: Bundle for Matt Pierce (IN House 61)** — reuse `/tmp/bundle-check/` from Task 2 (`cp -r /tmp/bundle-check /tmp/gate-control`), and note his `politician_id` from `politicians.json`.

- [ ] **Step 2: Find a real passage.** List topics he has **no** open-season answer for, and his existing cited pages:

```bash
npx tsx -e "
import { pool } from './src/lib/db.js'; import { OPEN_SEASON_ANSWER_SQL } from './src/lib/seasonService.js';
import { readFileSync } from 'node:fs';
const [p] = JSON.parse(readFileSync('/tmp/gate-control/politicians.json','utf8'));
const { rows: have } = await pool.query(OPEN_SEASON_ANSWER_SQL, [p.politician_id]);
const topics = JSON.parse(readFileSync('/tmp/gate-control/topics.json','utf8')).filter(t => t.applies_state);
console.log('state topics with NO open-season answer:', topics.filter(t => !have.some(h => h.topic_id === t.topic_id)).map(t => t.topic_key).slice(0, 10));
const { rows } = await pool.query('SELECT DISTINCT unnest(sources) u FROM inform.politician_context WHERE politician_id=\$1 LIMIT 10', [p.politician_id]);
console.log(rows.map(r => r.u)); await pool.end();"
```

Fetch one returned URL with the pipeline's own fetcher and copy a ≥30-word passage that names Pierce:

```bash
npx tsx -e "import { fetchForVerification } from './src/lib/verificationFetch.js'; const t = await fetchForVerification(process.argv[1]); const i = t.indexOf('Pierce'); console.log(t.slice(Math.max(0,i-400), i+600));" '<URL>'
```

If the page has no passage naming him, try the next URL. Record the chosen `URL`, the verbatim `PASSAGE`, and one in-scope `TOPIC` he has no open-season answer for.

- [ ] **Step 3: Plant six rows.** Write `/tmp/gate-control/research.csv` and `/tmp/gate-control/evidence.csv` with these intents (use the real `URL`/`PASSAGE`/`TOPIC`; pick any other in-scope topics for rows 3–5 and any `applies_local`-only topic for row 6):

| # | intent | research.csv | evidence.csv | expected |
|---|---|---|---|---|
| 1 | GOOD record | TOPIC, value 3, `record`, reasoning naming a real bill he voted on, source URL | PASSAGE | `auto-push` |
| 2 | FABRICATED snippet | another topic, `record`, names a bill, source URL | an invented 30-word sentence NOT on the page | `re-research [below-threshold]` |
| 3 | NO SOURCE | `record`, names a bill, no source URL | — | gate `no-source` → `re-research [gate-high]` |
| 4 | PARTY | `record`, reasoning includes "as a Democrat", source URL | PASSAGE | gate `party-inference` → `re-research [gate-high]` |
| 5 | STATEMENT | `statement`, source URL | PASSAGE | `review [statement-evidence]` |
| 6 | OUT OF SCOPE | a local-only topic, `record`, source URL | PASSAGE | gate `topic-out-of-scope` → `re-research [gate-high]` |

- [ ] **Step 4: Gate.** Run `npx tsx scripts/stance-gate.ts --dir /tmp/gate-control; echo exit=$?`
Expected: `exit=1`; high findings exactly for rows 3, 4, 6; `statement-needs-review` medium for row 5; nothing for rows 1–2.

- [ ] **Step 5: Verify (dry-run only — never `--apply` here).** Run `npx tsx scripts/verify-stance-research.ts --dir /tmp/gate-control`
Expected: `publish-report.json` actions match the table's last column. If row 1 is not `auto-push`, or row 2 is anything other than `re-research`, **stop**: a detector that passes a fabricated snippet or fails a real one is not ready.

- [ ] **Step 6: Record the result** in the PR description (counts per action). Delete `/tmp/gate-control` and `/tmp/bundle-check`.

---

### Task 11: Remove the stale local copies (outside the repo)

Operator-approved 2026-09-22. Touches only the local workspace; nothing is committed.

- [ ] **Step 1: Refuse to touch a tracked file.** The workspace root is itself a checkout:

```bash
cd /Users/chrisandrews/Documents/GitHub
for p in .claude/skills/research-stances .agents/skills/research-stances .claude/agents/politician-stance-researcher.md; do
  if git ls-files --error-unmatch "$p" >/dev/null 2>&1 || [ -n "$(git ls-files "$p")" ]; then echo "TRACKED: $p"; else echo "untracked: $p"; fi
done
```

For any `TRACKED` path, **stop and report to the operator** — replacing a tracked file with a symlink shows as a change in the root checkout and could conflict on its next pull. Only continue for `untracked` paths.

- [ ] **Step 2: Back up and link (untracked paths only)**

```bash
cd /Users/chrisandrews/Documents/GitHub
SRC=/Users/chrisandrews/Documents/GitHub/ev-accounts/.claude
for pair in ".claude/skills/research-stances:$SRC/skills/research-stances" \
            ".agents/skills/research-stances:$SRC/skills/research-stances" \
            ".claude/agents/politician-stance-researcher.md:$SRC/agents/politician-stance-researcher.md"; do
  p=${pair%%:*}; t=${pair#*:}
  [ -L "$p" ] && { echo "already linked: $p"; continue; }
  mv "$p" "$p.bak-2026-09-22" && ln -s "$t" "$p" && echo "linked: $p -> $t"
done
```

- [ ] **Step 3: Verify** — `ls -l .claude/skills/research-stances .agents/skills/research-stances .claude/agents/politician-stance-researcher.md` shows three symlinks into `ev-accounts/.claude/…`. Note for the operator: they serve whatever the main `ev-accounts` checkout has — today a WIP branch — and pick up this work once that checkout includes master.

---

### Task 12: Full verification and PR

- [ ] **Step 1: Everything green**

```bash
cd backend
npm run test:unit && npm run typecheck && npm run lint
cd .. && node --test .claude/skills/research-stances/scripts/tests/
npm run check:occupancy --prefix backend
```

Expected: all pass. The `node --test` run may need `OTR_ROOT=<path to on-the-record>` if the sibling checkout is not at the default path — set it, do not skip the test.

- [ ] **Step 2: Push and open the PR** (base `master`), with the Task 10 control results and a Follow-ons section pointing at Plans 2 and 3 below. End the description with `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.

---

## Follow-on plans (not in this increment)

**Plan 2 — Local chair-fit classifier (Layer 3).** For each verified snippet, score it against all five rung texts with a local natural-language-inference model, e.g. a DeBERTa-v3 NLI cross-encoder run in Node through `transformers.js` (ONNX), so there is no API and no data leaves the machine. It flags `contradicts`, `unrelated` and `direction-only` (top two rungs on the same side too close to call). Uncertain or disagreeing rows escalate to a Claude sub-agent, then a person. Choose the model and thresholds from **measured** precision on a labeled set. That set comes from the human review decisions this increment produces. Jev (TypeSafe.ai: `choice`/`score`/`noul` questions with calibrated confidence, `TYPESAFE_API_KEY`, sends excerpts to an outside service) is an optional benchmark, not a dependency.

**Plan 3 — Scheduled refresh.** A scheduled Claude Code routine selects politicians who are new, stale (`politicians.last_stances_researched_at`), or affected by a newly opened season. It runs the bundle → research → gate → verify pipeline and applies `decidePublish`, so only safe new rows publish unattended. Everything else lands in the review queue. It needs: a review-reason column on `stance_research_review` (today reasons live only in `publish-report.json`), a service editor identity for `--editor-id`, a digest or alert for the queue, and a rate-limit budget for research.
