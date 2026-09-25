# Codebook & Inter-Coder Reliability — P0 + P1 (shadow) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the foundation (P0) and the shadow coding pipeline (P1) described in
`docs/superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md`: three tool-less coder
sub-agents label code-snapshotted sources against the codebook, and code measures their agreement.
**Nothing this plan builds changes what gets published.**

**Architecture:**
- **Pure libraries** in `backend/scripts/lib/`, each unit-tested with vitest:
  - `reliability` — the α / Wilson / certification maths;
  - `coderLabel` — the label schema and validator;
  - `sourcesManifest` — the collector's output contract;
  - `snapshotSources` — excerpt windows and hashing;
  - `coderPrompt` — the coder input text;
  - `agreement` — unanimity per row;
  - `confirm` — the post-agreement checks.
- **Thin CLI scripts** in `backend/scripts/` do the I/O: files in the batch directory, and database
  reads and writes only behind `--apply`.
- **One additive migration** adds the four new tables and five review-row columns. It is NOT applied
  without the operator's explicit OK.
- The inline `/research-stances` session stays the collector. It dispatches the three coders with the
  Agent tool (`subagent_type: stance-coder`, which has the Write tool only).

**Tech Stack:** TypeScript (ESM, `.js` import suffixes), `tsx`, vitest (`backend/vitest.config.ts`),
`pg` via `backend/src/lib/db.ts` `pool`, PostgreSQL (Supabase). Claude Code sub-agents for the coders.

## Global Constraints

- **P1 is SHADOW.** `stancePublishPolicy.decidePublish` must return exactly what it returns today for
  every input. No task edits it. Coder output goes to `coding-report.json` and, with `--apply`, to
  `inform.stance_coder_labels` only. It never touches `inform.stance_research_review`,
  `politician_answers` or `politician_context`.
- **No production write without the operator's explicit OK in chat**, for each action: migration
  dry-run, migration apply, and any `--apply` run. Read-only SELECTs are fine.
- **Migration numbers come from the allocator, never from counting:**
  `npm run steward --prefix backend -- slot CA --purpose "..."`. The author is Chris Andrews, so the
  namespace is `CA`.
- **Migration house style:** idempotent (`IF NOT EXISTS`, guarded DDL), wrapped `BEGIN; … COMMIT;`,
  ending in a `DO $$ … $$` post-verify gate that `RAISE EXCEPTION`s on a wrong shape. Dry-run as
  `BEGIN; … ROLLBACK;` first, and confirm the rollback reverted.
- **New tables are default-deny RLS** (CTO decision 0015): `ENABLE ROW LEVEL SECURITY`, no policies,
  `REVOKE ALL … FROM anon, authenticated`.
- **Commit with an explicit pathspec:** `git commit -F <msg> -- <paths>`. Never `git add -A`.
- **Codebook version** in labels = `CODEBOOK_VERSION` in `coderLabel.ts` = the `**Version:**` line of
  `docs/codebook/stance-and-quote-codebook.md`. A test pins them equal.
- **Coders get the Write tool only.** No Read, Bash, WebFetch, WebSearch or MCP (ruling Q1,
  2026-09-25).
- **The collector writes no opinion into `sources.json`.** The keys `value`, `chair`, `reasoning`,
  `stance` and `proposed_value` are refused.
- **Excerpt-only storage for `news` and `pointer` sources**; full text for `public-record`,
  `own-site` and `transcript` (spec §5.4).
- **Statement cycle proxy** (spec §5.2, ruling Q4):
  - The earliest acceptable statement date = the current term's `term_start` (seated) or the race's
    `election_date` (candidate), minus `CAMPAIGN_LOOKBACK_DAYS = 548`.
  - This is an implementation proxy for "the current term, current campaign, or the campaign that
    seated them". The operator may change the constant.
- **Run tests from `backend/`:** `npx vitest run <path>`.
- ⚠ `npm run typecheck` skips `backend/scripts`. Vitest compiles what it imports, so every script's
  logic lives in a tested `lib/` module.

---

## File structure

| Path | Responsibility | Task |
|---|---|---|
| `backend/scripts/lib/reliability.ts` (+ `.test.ts`) | nominal α, Wilson bound, severe-error rule, certification rule | 1 |
| `backend/scripts/lib/coderLabel.ts` (+ `.test.ts`) | codebook enums, label types, validator, `passageAllowsChair`, version pin | 2 |
| `backend/migrations/CA_<slot>_codebook_reliability_schema.sql` | the 4 tables + review columns | 3 |
| `backend/scripts/lib/codebookAnnex.ts` (+ `.test.ts`), `backend/scripts/build-codebook-annex.ts` | annex skeleton from a served ladder | 4 |
| `backend/scripts/lib/sourcesManifest.ts` (+ `.test.ts`) | `sources.json` contract | 5 |
| `backend/scripts/lib/snapshotSources.ts` (+ `.test.ts`), `backend/scripts/snapshot-sources.ts` | fetch → snapshot records | 6 |
| `backend/scripts/lib/coderPrompt.ts` (+ `.test.ts`), `backend/scripts/build-coder-inputs.ts` | seat context + three coder prompts | 7 |
| `.claude/agents/stance-coder.md`, `backend/scripts/lib/stanceCoderAgent.test.ts` | the coder agent + tool guard | 8 |
| `backend/scripts/lib/agreement.ts` (+ `.test.ts`) | per-row unanimity | 9 |
| `backend/scripts/lib/confirm.ts` (+ `.test.ts`) | CONFIRM checks | 10 |
| `backend/scripts/lib/codingReport.ts` (+ `.test.ts`), `backend/scripts/code-stance-batch.ts` | batch report; `--apply` coder labels | 11 |
| `backend/scripts/reliability-report.ts`, `backend/package.json` | cross-batch M1 per stratum; npm scripts | 12 |
| `.claude/skills/research-stances/SKILL.md`, spec §7 | shadow procedure; first shadow run | 13 |

---

## P0 — Foundation

### Task 1: Reliability maths

**Files:**
- Create: `backend/scripts/lib/reliability.ts`
- Test: `backend/scripts/lib/reliability.test.ts`

**Interfaces:**
- Produces:
  - `type Category = string`
  - `type Unit = ReadonlyArray<Category | null>`
  - `alphaNominal(units: ReadonlyArray<Unit>): { alpha: number | null; pairableValues: number; units: number }`
  - `Z95`
  - `wilsonLowerBound(successes: number, n: number, z?: number): number`
  - `isSevereError(machine: number | null, gold: number | null, offAxis: boolean): boolean`
  - `CERT`
  - `interface StratumMeasures`
  - `certify(m: StratumMeasures): { certified: boolean; m3WilsonLow: number; reasons: string[] }`
  - `chairCategory(value: number | null): Category` (maps null → `'BLANK'`)

- [ ] **Step 1: Write the failing test (the positive controls come first)**

```ts
// backend/scripts/lib/reliability.test.ts
import { describe, it, expect } from 'vitest';
import { alphaNominal, wilsonLowerBound, isSevereError, certify, chairCategory, type Unit } from './reliability.js';

/** Coder-major matrix (rows = coders) → unit-major (rows = units), the shape alphaNominal takes. */
const byUnit = (coders: (string | null)[][]): Unit[] =>
  coders[0].map((_, u) => coders.map((c) => c[u]));
const n = null;

describe('alphaNominal — positive controls (spec §3.5: trust nothing until these pass)', () => {
  it('reproduces Krippendorff (2011) "Computing Krippendorff’s Alpha-Reliability", 4 observers × 12 units, nominal α = 0.743', () => {
    const s = (xs: (number | null)[]) => xs.map((x) => (x === null ? null : String(x)));
    const r = alphaNominal(byUnit([
      s([1, 2, 3, 3, 2, 1, 4, 1, 2, n, n, n]),
      s([1, 2, 3, 3, 2, 2, 4, 1, 2, 5, n, 3]),
      s([n, 3, 3, 3, 2, 3, 4, 2, 2, 5, 1, n]),
      s([1, 2, 3, 3, 2, 4, 4, 1, 2, 5, 1, n]),
    ]));
    expect(r.alpha).toBeCloseTo(0.743421052631579, 12);
    expect(r.pairableValues).toBe(40);
  });
  it('reproduces the 3-coder × 15-unit example with missing data, nominal α = 0.691', () => {
    const s = (xs: (number | null)[]) => xs.map((x) => (x === null ? null : String(x)));
    const r = alphaNominal(byUnit([
      s([n, n, n, n, n, 3, 4, 1, 2, 1, 1, 3, 3, n, 3]),
      s([1, n, 2, 1, 3, 3, 4, 3, n, n, n, n, n, n, n]),
      s([n, n, 2, 1, 3, 4, 4, n, 2, 1, 1, 3, 3, n, 4]),
    ]));
    expect(r.alpha).toBeCloseTo(0.691358024691358, 12);
    expect(r.pairableValues).toBe(26);
  });
});

describe('alphaNominal — edge cases', () => {
  it('is 1 for perfect agreement across more than one category', () => {
    expect(alphaNominal([['1', '1', '1'], ['4', '4', '4'], ['BLANK', 'BLANK', 'BLANK']]).alpha).toBe(1);
  });
  it('is null (undefined) when every value is the same category — no expected disagreement', () => {
    expect(alphaNominal([['2', '2', '2'], ['2', '2', '2']]).alpha).toBeNull();
  });
  it('ignores units with fewer than two values', () => {
    const r = alphaNominal([['1', null, null], ['1', '1', '1'], ['3', '3', '3']]);
    expect(r.units).toBe(2);
    expect(r.alpha).toBe(1);
  });
  it('treats BLANK as its own nominal category (a 1-vs-BLANK split is a disagreement)', () => {
    expect(alphaNominal([['1', 'BLANK'], ['4', '4'], ['BLANK', 'BLANK']]).alpha).toBeLessThan(1);
  });
});

describe('wilsonLowerBound — the scale in spec §3.3', () => {
  it('50/50 → 0.929 (passes 0.90)', () => expect(wilsonLowerBound(50, 50)).toBeCloseTo(0.92865, 4));
  it('49/50 → 0.895 (fails 0.90)', () => expect(wilsonLowerBound(49, 50)).toBeCloseTo(0.89505, 4));
  it('98/100 → 0.930 (passes)', () => expect(wilsonLowerBound(98, 100)).toBeCloseTo(0.92999, 4));
  it('n = 0 → 0', () => expect(wilsonLowerBound(0, 0)).toBe(0));
});

describe('isSevereError', () => {
  it('a seated chair where gold is BLANK is severe', () => expect(isSevereError(4, null, false)).toBe(true));
  it('opposite sides of the ladder are severe', () => expect(isSevereError(1, 5, false)).toBe(true));
  it('adjacent chairs on one side are an error but not severe', () => expect(isSevereError(4, 5, false)).toBe(false));
  it('the middle rung is never "the other side"', () => expect(isSevereError(3, 5, false)).toBe(false));
  it('on an off-axis topic every wrong chair is severe', () => expect(isSevereError(4, 5, true)).toBe(true));
  it('a machine BLANK is never severe (it never publishes)', () => expect(isSevereError(null, 3, false)).toBe(false));
  it('agreement is not an error', () => expect(isSevereError(2, 2, false)).toBe(false));
});

describe('certify — spec §3.3', () => {
  const ok = { goldN: 50, m1: 0.85, m2: 0.82, unanimousCorrect: 50, unanimousTotal: 50, severe: 0 };
  it('certifies when all four conditions hold', () => {
    const r = certify(ok);
    expect(r.certified).toBe(true);
    expect(r.reasons).toEqual([]);
  });
  it('names every failed condition', () => {
    const r = certify({ goldN: 49, m1: 0.79, m2: null, unanimousCorrect: 49, unanimousTotal: 50, severe: 1 });
    expect(r.certified).toBe(false);
    expect(r.reasons).toEqual(['gold-n 49 < 50', 'm1 0.790 < 0.80', 'm2 undefined', 'm3 wilson-low 0.895 < 0.90', 'm4 severe 1 > 0']);
  });
});

describe('chairCategory', () => {
  it('maps a blank to BLANK and a chair to its digit', () => {
    expect(chairCategory(null)).toBe('BLANK');
    expect(chairCategory(3)).toBe('3');
  });
});
```

- [ ] **Step 2: Run the test and confirm that it fails**

Run: `cd backend && npx vitest run scripts/lib/reliability.test.ts`
Expected: FAIL (`Cannot find module './reliability.js'`).

- [ ] **Step 3: Implement**

```ts
// backend/scripts/lib/reliability.ts
/**
 * reliability — Krippendorff's alpha (nominal, missing data allowed), the Wilson lower bound, the
 * severe-error rule and the stratum certification rule for the stance coders.
 * Spec: docs/superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md §3.
 *
 * Nominal, not ordinal: the five chairs are distinct stances, not a scale (CLAUDE.md), and BLANK is
 * a sixth category. Pure. 🔴 reliability.test.ts reproduces Krippendorff's published examples — do
 * not trust any stratum figure while that test is red.
 */
export type Category = string;
/** One unit (one row) = the value each coder gave it; null = no valid value from that coder. */
export type Unit = ReadonlyArray<Category | null>;

export interface AlphaResult {
  /** null = undefined: fewer than 2 pairable values, or no expected disagreement (one category). */
  alpha: number | null;
  pairableValues: number;
  units: number;
}

const SEP = '\u0000';

export function alphaNominal(units: ReadonlyArray<Unit>): AlphaResult {
  const o = new Map<string, number>(); // coincidence matrix o_ck, keyed `${c}${SEP}${k}`
  let n = 0;
  let used = 0;
  for (const u of units) {
    const vals = u.filter((v): v is Category => v !== null);
    const m = vals.length;
    if (m < 2) continue;
    used++;
    n += m;
    const cnt = new Map<Category, number>();
    for (const v of vals) cnt.set(v, (cnt.get(v) ?? 0) + 1);
    for (const [c, nc] of cnt) {
      for (const [k, nk] of cnt) {
        const pairs = nc * (c === k ? nk - 1 : nk);
        if (pairs === 0) continue;
        const key = `${c}${SEP}${k}`;
        o.set(key, (o.get(key) ?? 0) + pairs / (m - 1));
      }
    }
  }
  if (n < 2) return { alpha: null, pairableValues: n, units: used };
  const marg = new Map<Category, number>();
  let dO = 0;
  for (const [key, v] of o) {
    const [c, k] = key.split(SEP);
    marg.set(c, (marg.get(c) ?? 0) + v);
    if (c !== k) dO += v;
  }
  let dE = 0;
  for (const [c, a] of marg) for (const [k, b] of marg) if (c !== k) dE += a * b;
  dE /= n - 1;
  if (dE === 0) return { alpha: null, pairableValues: n, units: used };
  return { alpha: 1 - dO / dE, pairableValues: n, units: used };
}

export const Z95 = 1.959963984540054;

export function wilsonLowerBound(successes: number, n: number, z = Z95): number {
  if (n <= 0) return 0;
  const p = successes / n;
  const z2 = z * z;
  return (p + z2 / (2 * n) - z * Math.sqrt((p * (1 - p)) / n + z2 / (4 * n * n))) / (1 + z2 / n);
}

/**
 * Spec §3.1 M4. Severe = a seated chair where gold is BLANK, or a chair on the other side of the
 * ladder (1–2 vs 4–5; rung 3 is on neither side). On an off-axis topic "side" means nothing, so
 * every wrong chair is severe. A machine BLANK never publishes, so it is never severe.
 */
export function isSevereError(machine: number | null, gold: number | null, offAxis: boolean): boolean {
  if (machine === gold) return false;
  if (machine === null) return false;
  if (gold === null) return true;
  if (offAxis) return true;
  const side = (v: number) => (v <= 2 ? -1 : v >= 4 ? 1 : 0);
  return side(machine) !== 0 && side(gold) !== 0 && side(machine) !== side(gold);
}

export const CERT = { MIN_GOLD: 50, MIN_ALPHA: 0.8, MIN_WILSON_LOW: 0.9 } as const;

export interface StratumMeasures {
  /** Blind/audit gold items in the stratum, excluding codebook examples. */
  goldN: number;
  /** M1: α among the three coders. */
  m1: number | null;
  /** M2: α between coder consensus and blind gold. */
  m2: number | null;
  /** M3 inputs: unanimous rows whose chair equals gold, out of unanimous rows with gold. */
  unanimousCorrect: number;
  unanimousTotal: number;
  /** M4: severe errors among unanimous rows. */
  severe: number;
}

export function certify(m: StratumMeasures): { certified: boolean; m3WilsonLow: number; reasons: string[] } {
  const reasons: string[] = [];
  const m3 = wilsonLowerBound(m.unanimousCorrect, m.unanimousTotal);
  if (m.goldN < CERT.MIN_GOLD) reasons.push(`gold-n ${m.goldN} < ${CERT.MIN_GOLD}`);
  if (m.m1 === null) reasons.push('m1 undefined');
  else if (m.m1 < CERT.MIN_ALPHA) reasons.push(`m1 ${m.m1.toFixed(3)} < ${CERT.MIN_ALPHA.toFixed(2)}`);
  if (m.m2 === null) reasons.push('m2 undefined');
  else if (m.m2 < CERT.MIN_ALPHA) reasons.push(`m2 ${m.m2.toFixed(3)} < ${CERT.MIN_ALPHA.toFixed(2)}`);
  if (m3 < CERT.MIN_WILSON_LOW) reasons.push(`m3 wilson-low ${m3.toFixed(3)} < ${CERT.MIN_WILSON_LOW.toFixed(2)}`);
  if (m.severe > 0) reasons.push(`m4 severe ${m.severe} > 0`);
  return { certified: reasons.length === 0, m3WilsonLow: m3, reasons };
}

export const chairCategory = (value: number | null): Category => (value === null ? 'BLANK' : String(value));
```

- [ ] **Step 4: Run the test and confirm that it passes**

Run: `cd backend && npx vitest run scripts/lib/reliability.test.ts`
Expected: PASS, all tests.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(reliability): nominal Krippendorff alpha, Wilson bound, certification rule" -- backend/scripts/lib/reliability.ts backend/scripts/lib/reliability.test.ts
```

(Add the `Co-Authored-By` trailer to every commit message in this plan.)

---

### Task 2: Coder label schema and validator

**Files:**
- Create: `backend/scripts/lib/coderLabel.ts`
- Test: `backend/scripts/lib/coderLabel.test.ts`

**Interfaces:**
- Consumes: `normalizeText` from `backend/src/lib/researchVerifier.ts`.
- Produces:
  - `CODEBOOK_VERSION`
  - the enum arrays `V1_ATTRIBUTION`, `V2_RELEVANCE`, `V3_CLASS`, `V4_SHAPE`, `V5_TIME`,
    `BLANK_REASONS`, `V7_TIER`, `V7_FLAGS`, `V8_CODES`
  - the types `Passage`, `QuoteLabel`, `CoderRow`, `CoderLabelFile`, `ValidatedRow`, `ValidationResult`
  - `rowKey(r): string`
  - `passageAllowsChair(p: Passage): boolean`
  - `verbatimIn(snapshotText: string, span: string): boolean`
  - `validateCoderLabelFile(raw: unknown, ctx: { snapshotText: ReadonlyMap<string, string>; expectedSlot: number }): ValidationResult`

- [ ] **Step 1: Write the failing test**

```ts
// backend/scripts/lib/coderLabel.test.ts
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { CODEBOOK_VERSION, validateCoderLabelFile, passageAllowsChair, rowKey, type Passage, type CoderRow } from './coderLabel.js';

const SNAP = 'aaaaaaaa-0000-0000-0000-000000000001';
const snapshotText = new Map([[SNAP, 'The Senate voted 21-8 to override the veto of H.B. 11, which requires students to compete on teams matching their sex at birth.']]);
const passage = (over: Partial<Passage> = {}): Passage => ({
  snapshot_id: SNAP, v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record',
  v4_shape: 'chair-shaped', v5_time: 'in-term', date: '2022-03-25', instrument: 'H.B. 11 (2022)',
  provision_quote: 'requires students to compete on teams matching their sex at birth', note: '', ...over,
});
const row = (over: Partial<CoderRow> = {}): CoderRow => ({
  politician_id: 'p1', office_id: 'o1', topic_id: 't1', served_revision_id: 'r1',
  passages: [passage()], v6_value: 4, v6_blank_reason: null, rests_on: [SNAP],
  reasoning: 'Led the override of H.B. 11, whose text is the rung.', needs_source: [], quotes: [], ...over,
});
const file = (rows: CoderRow[], over: Record<string, unknown> = {}) => ({ codebook_version: CODEBOOK_VERSION, coder_slot: 1, rows, ...over });
const ctx = { snapshotText, expectedSlot: 1 };

describe('CODEBOOK_VERSION', () => {
  it('equals the **Version:** line of the codebook (drift guard)', () => {
    const md = readFileSync(fileURLToPath(new URL('../../../docs/codebook/stance-and-quote-codebook.md', import.meta.url)), 'utf8');
    expect(md).toMatch(new RegExp(`\\*\\*Version:\\*\\* ${CODEBOOK_VERSION.replace('.', '\\.')} `));
  });
});

describe('passageAllowsChair', () => {
  it('allows a chair-shaped, in-term, on-question own act', () => expect(passageAllowsChair(passage())).toBe(true));
  it.each([
    ['third-party characterization', { v1_attribution: 'third-party-characterization' }],
    ['adjacent', { v2_relevance: 'adjacent' }],
    ['not-evidence (scorecard)', { v3_class: 'not-evidence' }],
    ['multi-subject vote (vote ladder)', { v4_shape: 'multi-subject' }],
    ['procedural vote', { v4_shape: 'procedural' }],
    ['pre-seating', { v5_time: 'pre-seating' }],
  ] as const)('refuses %s', (_label, over) => expect(passageAllowsChair(passage(over as Partial<Passage>))).toBe(false));
});

describe('validateCoderLabelFile', () => {
  it('accepts a valid file', () => {
    const r = validateCoderLabelFile(file([row()]), ctx);
    expect(r.fileErrors).toEqual([]);
    expect(r.rows).toHaveLength(1);
    expect(r.rows[0].errors).toEqual([]);
    expect(r.rows[0].key).toBe(rowKey({ politician_id: 'p1', office_id: 'o1', topic_id: 't1' }));
  });
  it('refuses a wrong codebook version and a wrong slot at file level', () => {
    const r = validateCoderLabelFile(file([row()], { codebook_version: '0.1', coder_slot: 2 }), ctx);
    expect(r.fileErrors).toEqual([`codebook_version 0.1 != ${CODEBOOK_VERSION}`, 'coder_slot 2 != 1']);
  });
  it('refuses a non-object', () => {
    expect(validateCoderLabelFile('prose instead of JSON', ctx).fileErrors).toEqual(['not an object with a rows array']);
  });
  it('requires value null iff a blank reason is set', () => {
    const r = validateCoderLabelFile(file([row({ v6_value: null, v6_blank_reason: null })]), ctx);
    expect(r.rows[0].errors).toContain('v6: value is null but no blank reason');
    const r2 = validateCoderLabelFile(file([row({ v6_value: 4, v6_blank_reason: 'no-evidence' })]), ctx);
    expect(r2.rows[0].errors).toContain('v6: value and blank reason both set');
  });
  it('refuses an out-of-range or fractional chair', () => {
    expect(validateCoderLabelFile(file([row({ v6_value: 6 })]), ctx).rows[0].errors).toContain('v6: value 6 not an integer 1..5');
    expect(validateCoderLabelFile(file([row({ v6_value: 2.5 })]), ctx).rows[0].errors).toContain('v6: value 2.5 not an integer 1..5');
  });
  it('requires a numeric chair to rest on at least one passage that allows a chair', () => {
    expect(validateCoderLabelFile(file([row({ rests_on: [] })]), ctx).rows[0].errors).toContain('rests_on: empty for a numeric chair');
    const bad = row({ passages: [passage({ v4_shape: 'multi-subject' })] });
    expect(validateCoderLabelFile(file([bad]), ctx).rows[0].errors).toContain(`rests_on: ${SNAP} does not allow a chair (V1–V5)`);
  });
  it('refuses a cited snapshot that does not exist', () => {
    const ghost = 'aaaaaaaa-0000-0000-0000-00000000dead';
    const r = validateCoderLabelFile(file([row({ rests_on: [ghost], passages: [passage({ snapshot_id: ghost })] })]), ctx);
    expect(r.rows[0].errors).toContain(`passage: unknown snapshot ${ghost}`);
  });
  it('refuses a provision_quote that is not verbatim in its snapshot', () => {
    const r = validateCoderLabelFile(file([row({ passages: [passage({ provision_quote: 'bans all transgender athletes from all sport' })] })]), ctx);
    expect(r.rows[0].errors).toContain(`passage ${SNAP}: provision_quote not verbatim in snapshot`);
  });
  it('refuses a quote not verbatim in its snapshot, and an unknown V7 tier', () => {
    const q = { snapshot_id: SNAP, text: 'I will ban it all', v7_tier: 'strong', v7_flag: null, v8_quotable: true, v8_codes: [] };
    const errs = validateCoderLabelFile(file([row({ quotes: [q as never] })]), ctx).rows[0].errors;
    expect(errs).toContain('quote: text not verbatim in snapshot');
    expect(errs).toContain('quote: v7_tier strong not allowed');
  });
  it('lets a quotable quote carry only the non-gating non-differentiating-goal code', () => {
    const q = { snapshot_id: SNAP, text: 'override the veto', v7_tier: 'none', v7_flag: null, v8_quotable: true, v8_codes: ['is-attack'] };
    expect(validateCoderLabelFile(file([row({ quotes: [q] })]), ctx).rows[0].errors)
      .toContain('quote: v8_quotable true but gating codes present');
  });
  it('refuses an unknown enum value in a passage', () => {
    const errs = validateCoderLabelFile(file([row({ passages: [passage({ v3_class: 'statement' as never })] })]), ctx).rows[0].errors;
    expect(errs).toContain(`passage ${SNAP}: v3_class statement not allowed`);
  });
  it('validates rows independently — one bad row does not invalidate a good one', () => {
    const r = validateCoderLabelFile(file([row(), row({ topic_id: 't2', v6_value: 9 })]), ctx);
    expect(r.rows[0].errors).toEqual([]);
    expect(r.rows[1].errors.length).toBeGreaterThan(0);
  });
});
```

- [ ] **Step 2: Run the test and confirm that it fails**

Run: `cd backend && npx vitest run scripts/lib/coderLabel.test.ts`
Expected: FAIL (module not found).

- [ ] **Step 3: Implement**

```ts
// backend/scripts/lib/coderLabel.ts
/**
 * coderLabel — the contract for labels/coder-N.json (codebook Part E) and its validator.
 * Codebook: docs/codebook/stance-and-quote-codebook.md. Spec §1.4: a label that fails here makes
 * that coder MISSING for the row — which makes the row not unanimous, which sends it to a person.
 * Pure: no DB, no network. Verbatim checks use the verifier's own normalisation.
 */
import { normalizeText } from '../../src/lib/researchVerifier.js';

/** 🔴 Must equal the codebook's **Version:** line — coderLabel.test.ts pins it. */
export const CODEBOOK_VERSION = '0.2';

export const V1_ATTRIBUTION = ['own-words', 'own-act', 'third-party-characterization', 'namesake-unclear'] as const;
export const V2_RELEVANCE = ['on-question', 'adjacent', 'off'] as const;
export const V3_CLASS = ['record', 'statement-answer', 'statement-other', 'not-evidence'] as const;
export const V4_SHAPE = ['chair-shaped', 'direction-only', 'multi-subject', 'procedural', 'study-directive', 'near-unanimous', 'rhetorical', 'off-axis'] as const;
export const V5_TIME = ['in-term', 'pre-seating', 'superseded-by-later', 'undated'] as const;
export const BLANK_REASONS = ['no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable'] as const;
export const V7_TIER = ['lever', 'direction', 'none'] as const;
export const V7_FLAGS = ['lever-named', 'lever-unclear'] as const;
export const V8_CODES = ['not-forward', 'is-attack', 'off-question', 'misleading-verbatim', 'source-not-an-answer', 'deid-dishonest', 'non-differentiating-goal'] as const;
/** V8 codes that do not gate (PRINCIPLES.md: flag for a human, no blanket gate). */
const NON_GATING_V8 = new Set<string>(['non-differentiating-goal']);

export interface Passage {
  snapshot_id: string;
  v1_attribution: typeof V1_ATTRIBUTION[number];
  v2_relevance: typeof V2_RELEVANCE[number];
  v3_class: typeof V3_CLASS[number];
  v4_shape: typeof V4_SHAPE[number];
  v5_time: typeof V5_TIME[number];
  date: string | null;
  instrument: string | null;
  provision_quote: string | null;
  note?: string;
}
export interface QuoteLabel {
  snapshot_id: string;
  text: string;
  v7_tier: typeof V7_TIER[number];
  v7_flag: typeof V7_FLAGS[number] | null;
  v8_quotable: boolean;
  v8_codes: string[];
}
export interface CoderRow {
  politician_id: string;
  office_id: string;
  topic_id: string;
  served_revision_id: string;
  passages: Passage[];
  v6_value: number | null;
  v6_blank_reason: typeof BLANK_REASONS[number] | null;
  rests_on: string[];
  reasoning: string;
  needs_source: string[];
  quotes: QuoteLabel[];
}
export interface CoderLabelFile { codebook_version: string; coder_slot: number; rows: CoderRow[] }
export interface ValidatedRow { key: string; row: CoderRow | null; errors: string[] }
export interface ValidationResult { fileErrors: string[]; rows: ValidatedRow[] }

export const rowKey = (r: { politician_id: string; office_id: string; topic_id: string }): string =>
  `${r.politician_id}|${r.office_id}|${r.topic_id}`;

/** Codebook Part 0.3: a passage can support a chair only if V1–V5 all allow it. */
export function passageAllowsChair(p: Passage): boolean {
  return (p.v1_attribution === 'own-words' || p.v1_attribution === 'own-act')
    && p.v2_relevance === 'on-question'
    && p.v3_class !== 'not-evidence'
    && p.v4_shape === 'chair-shaped'
    && p.v5_time === 'in-term';
}

export const verbatimIn = (snapshotText: string, span: string): boolean => {
  const s = normalizeText(span);
  return s.length > 0 && normalizeText(snapshotText).includes(s);
};

const isObj = (x: unknown): x is Record<string, unknown> => typeof x === 'object' && x !== null && !Array.isArray(x);
const isStrArr = (x: unknown): x is string[] => Array.isArray(x) && x.every((v) => typeof v === 'string');
function enumErr(where: string, field: string, v: unknown, allowed: readonly string[]): string | null {
  return typeof v === 'string' && allowed.includes(v) ? null : `${where}: ${field} ${String(v)} not allowed`;
}

function validateRow(raw: unknown, snapshotText: ReadonlyMap<string, string>): ValidatedRow {
  const errors: string[] = [];
  if (!isObj(raw)) return { key: '?', row: null, errors: ['row: not an object'] };
  for (const k of ['politician_id', 'office_id', 'topic_id', 'served_revision_id', 'reasoning'] as const) {
    if (typeof raw[k] !== 'string' || (raw[k] as string).length === 0) errors.push(`row: ${k} missing`);
  }
  const key = errors.length ? '?' : rowKey(raw as unknown as CoderRow);
  const passages = Array.isArray(raw.passages) ? raw.passages : [];
  if (!Array.isArray(raw.passages)) errors.push('row: passages not an array');
  const byId = new Map<string, Passage>();
  for (const p of passages) {
    if (!isObj(p) || typeof p.snapshot_id !== 'string') { errors.push('passage: not an object with snapshot_id'); continue; }
    const where = `passage ${p.snapshot_id}`;
    const text = snapshotText.get(p.snapshot_id);
    if (text === undefined) errors.push(`passage: unknown snapshot ${p.snapshot_id}`);
    for (const [f, allowed] of [['v1_attribution', V1_ATTRIBUTION], ['v2_relevance', V2_RELEVANCE], ['v3_class', V3_CLASS], ['v4_shape', V4_SHAPE], ['v5_time', V5_TIME]] as const) {
      const e = enumErr(where, f, p[f], allowed);
      if (e) errors.push(e);
    }
    if (p.provision_quote !== null && p.provision_quote !== undefined) {
      if (typeof p.provision_quote !== 'string') errors.push(`${where}: provision_quote not a string`);
      else if (text !== undefined && !verbatimIn(text, p.provision_quote)) errors.push(`${where}: provision_quote not verbatim in snapshot`);
    }
    byId.set(p.snapshot_id, p as unknown as Passage);
  }
  const value = raw.v6_value;
  const reason = raw.v6_blank_reason;
  if (value === null || value === undefined) {
    if (reason === null || reason === undefined) errors.push('v6: value is null but no blank reason');
    else { const e = enumErr('v6', 'blank_reason', reason, BLANK_REASONS); if (e) errors.push(e); }
  } else {
    if (reason !== null && reason !== undefined) errors.push('v6: value and blank reason both set');
    if (typeof value !== 'number' || !Number.isInteger(value) || value < 1 || value > 5) errors.push(`v6: value ${String(value)} not an integer 1..5`);
  }
  const restsOn = isStrArr(raw.rests_on) ? raw.rests_on : [];
  if (!isStrArr(raw.rests_on)) errors.push('rests_on: not a string array');
  if (typeof value === 'number') {
    if (restsOn.length === 0) errors.push('rests_on: empty for a numeric chair');
    for (const id of restsOn) {
      const p = byId.get(id);
      if (!p) errors.push(`rests_on: ${id} is not a coded passage`);
      else if (!passageAllowsChair(p)) errors.push(`rests_on: ${id} does not allow a chair (V1–V5)`);
    }
  }
  if (!isStrArr(raw.needs_source)) errors.push('needs_source: not a string array');
  const quotes = Array.isArray(raw.quotes) ? raw.quotes : [];
  if (!Array.isArray(raw.quotes)) errors.push('quotes: not an array');
  for (const q of quotes) {
    if (!isObj(q) || typeof q.snapshot_id !== 'string' || typeof q.text !== 'string') { errors.push('quote: not an object with snapshot_id and text'); continue; }
    const text = snapshotText.get(q.snapshot_id);
    if (text === undefined) errors.push(`quote: unknown snapshot ${q.snapshot_id}`);
    else if (!verbatimIn(text, q.text)) errors.push('quote: text not verbatim in snapshot');
    const e = enumErr('quote', 'v7_tier', q.v7_tier, V7_TIER);
    if (e) errors.push(e);
    if (q.v7_flag !== null && q.v7_flag !== undefined) { const f = enumErr('quote', 'v7_flag', q.v7_flag, V7_FLAGS); if (f) errors.push(f); }
    const codes = isStrArr(q.v8_codes) ? q.v8_codes : [];
    if (!isStrArr(q.v8_codes)) errors.push('quote: v8_codes not a string array');
    for (const c of codes) if (!(V8_CODES as readonly string[]).includes(c)) errors.push(`quote: v8 code ${c} not allowed`);
    if (typeof q.v8_quotable !== 'boolean') errors.push('quote: v8_quotable not a boolean');
    else if (q.v8_quotable && codes.some((c) => !NON_GATING_V8.has(c))) errors.push('quote: v8_quotable true but gating codes present');
  }
  return { key, row: errors.length ? null : (raw as unknown as CoderRow), errors };
}

export function validateCoderLabelFile(
  raw: unknown,
  ctx: { snapshotText: ReadonlyMap<string, string>; expectedSlot: number },
): ValidationResult {
  if (!isObj(raw) || !Array.isArray(raw.rows)) return { fileErrors: ['not an object with a rows array'], rows: [] };
  const fileErrors: string[] = [];
  if (raw.codebook_version !== CODEBOOK_VERSION) fileErrors.push(`codebook_version ${String(raw.codebook_version)} != ${CODEBOOK_VERSION}`);
  if (raw.coder_slot !== ctx.expectedSlot) fileErrors.push(`coder_slot ${String(raw.coder_slot)} != ${ctx.expectedSlot}`);
  return { fileErrors, rows: raw.rows.map((r) => validateRow(r, ctx.snapshotText)) };
}
```

- [ ] **Step 4: Run the test and confirm that it passes**

Run: `cd backend && npx vitest run scripts/lib/coderLabel.test.ts`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(codebook): coder label schema + validator, pinned to codebook version" -- backend/scripts/lib/coderLabel.ts backend/scripts/lib/coderLabel.test.ts
```

---

### Task 3: Schema migration (written and dry-run; applied only with an OK)

**Files:**
- Create: `backend/migrations/CA_<slot>_codebook_reliability_schema.sql`

**Interfaces:**
- Produces:
  - tables `inform.source_snapshots`, `inform.stance_coder_labels`, `inform.stance_gold_labels`,
    `inform.reliability_certifications`;
  - columns `inform.stance_research_review.{review_mode, codebook_version, unanimous, consensus_value, office_id}`.
- Tasks 6, 11 and 12 write or read these, **only behind `--apply` / after the apply**.

- [ ] **Step 1: Reserve the slot**

```bash
cd backend && git fetch origin && npm run steward -- slot CA --purpose "codebook reliability schema: source snapshots, coder labels, gold labels, certifications (spec 2026-09-25)"
```

Expected: prints `CA_NNNN`. Name the file with that number now. Every later reference in this task
uses it in place of `<slot>`.

- [ ] **Step 2: Write the migration**

```sql
-- backend/migrations/CA_<slot>_codebook_reliability_schema.sql
BEGIN;

-- ⚠ NOT APPLIED until the operator says so. Dry-run first inside BEGIN…ROLLBACK.
-- =============================================================================
-- CA_<slot>: codebook + inter-coder reliability schema
-- =============================================================================
-- Spec: docs/superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md §4.
--
--   source_snapshots           what the coders saw — full text for public records / own site /
--                              transcripts, excerpt windows only for news and pointers (§5.4)
--   stance_coder_labels        one row per coder per (batch, politician, office, topic)
--   stance_gold_labels         one row per HUMAN decision. APPEND-ONLY: the chair a person chose
--                              must not be rewritten by later answer writes (today it lives only in
--                              politician_answers, which later writes change — Moore/social-security
--                              was approved as 4 and reads 5 today). A correction is a new row with
--                              supersedes_id. Only excluded_from_cert and politician_id (duplicate-
--                              person merges) may be updated.
--   reliability_certifications one row per computation; never updated. decidePublish (P3) reads the
--                              newest row per key.
--
-- 🔴 Duplicate-person merge migrations must re-point politician_id on stance_coder_labels and
--    stance_gold_labels exactly as they do on stance_research_review.
-- Purely additive. RLS default-deny (CTO decision 0015): the API reads through the pool.
-- =============================================================================

CREATE TABLE IF NOT EXISTS inform.source_snapshots (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id        text NOT NULL,
  url             text NOT NULL,
  source_kind     text NOT NULL CHECK (source_kind IN ('public-record', 'own-site', 'news', 'pointer', 'transcript')),
  fetched_at      timestamptz NOT NULL DEFAULT now(),
  fetched_by      text NOT NULL CHECK (fetched_by IN ('code', 'human')),
  page_sha256     text NOT NULL CHECK (page_sha256 ~ '^[0-9a-f]{64}$'),
  snapshot_text   text NOT NULL CHECK (btrim(snapshot_text) <> ''),
  excerpt_only    boolean NOT NULL,
  UNIQUE (batch_id, url, page_sha256)
);

CREATE TABLE IF NOT EXISTS inform.stance_coder_labels (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id            text NOT NULL,
  review_id           uuid REFERENCES inform.stance_research_review(id),
  politician_id       uuid NOT NULL REFERENCES essentials.politicians(id),
  office_id           uuid NOT NULL REFERENCES essentials.offices(id),
  topic_id            uuid NOT NULL REFERENCES inform.compass_topics(id),
  season_id           uuid NOT NULL REFERENCES inform.seasons(id),
  served_revision_id  uuid NOT NULL REFERENCES inform.compass_topic_revisions(id),
  coder_slot          smallint NOT NULL CHECK (coder_slot BETWEEN 1 AND 4),
  is_diagnostic       boolean NOT NULL DEFAULT false,
  model               text NOT NULL,
  codebook_version    text NOT NULL,
  value               smallint CHECK (value BETWEEN 1 AND 5),
  blank_reason        text CHECK (blank_reason IN ('no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable')),
  rests_on            uuid[] NOT NULL DEFAULT '{}',
  source_codes        jsonb NOT NULL DEFAULT '[]',
  quote_codes         jsonb NOT NULL DEFAULT '[]',
  needs_source        jsonb NOT NULL DEFAULT '[]',
  valid               boolean NOT NULL,
  validation_errors   text[] NOT NULL DEFAULT '{}',
  label_sha256        text NOT NULL CHECK (label_sha256 ~ '^[0-9a-f]{64}$'),
  raw_output          jsonb,
  created_at          timestamptz NOT NULL DEFAULT now(),
  CHECK (NOT valid OR ((value IS NULL) = (blank_reason IS NOT NULL))),
  UNIQUE (batch_id, politician_id, office_id, topic_id, coder_slot)
);

CREATE TABLE IF NOT EXISTS inform.stance_gold_labels (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id           uuid NOT NULL REFERENCES inform.stance_research_review(id),
  politician_id       uuid NOT NULL REFERENCES essentials.politicians(id),
  office_id           uuid REFERENCES essentials.offices(id),
  topic_id            uuid NOT NULL REFERENCES inform.compass_topics(id),
  season_id           uuid NOT NULL REFERENCES inform.seasons(id),
  served_revision_id  uuid NOT NULL REFERENCES inform.compass_topic_revisions(id),
  mode                text NOT NULL CHECK (mode IN ('blind', 'standard', 'audit')),
  blind_value         smallint CHECK (blind_value BETWEEN 1 AND 5),
  blind_blank_reason  text CHECK (blind_blank_reason IN ('no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable')),
  blind_submitted_at  timestamptz,
  final_value         smallint CHECK (final_value BETWEEN 1 AND 5),
  final_blank_reason  text CHECK (final_blank_reason IN ('no-evidence', 'direction-only', 'adjacent-chairs', 'compound-partial', 'record-vs-statement-conflict', 'scope-unavailable')),
  source_judgments    jsonb NOT NULL DEFAULT '[]',
  reject_reason       text CHECK (reject_reason IN ('wrong-person', 'off-question', 'direction-only', 'adjacent-chairs', 'wrong-chair', 'source-fails', 'pre-seating', 'study-directive', 'near-unanimous', 'multi-subject', 'scope-unavailable', 'other')),
  reject_note         text,
  codebook_version    text NOT NULL,
  reviewer_id         uuid NOT NULL,
  created_at          timestamptz NOT NULL DEFAULT now(),
  excluded_from_cert  boolean NOT NULL DEFAULT false,
  supersedes_id       uuid REFERENCES inform.stance_gold_labels(id),
  -- A blind answer, once submitted, is a chair XOR a blank reason.
  CHECK (blind_submitted_at IS NULL OR ((blind_value IS NULL) = (blind_blank_reason IS NOT NULL))),
  CHECK (reject_reason IS DISTINCT FROM 'other' OR btrim(coalesce(reject_note, '')) <> '')
);

CREATE TABLE IF NOT EXISTS inform.reliability_certifications (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  level             text NOT NULL CHECK (level IN ('federal', 'state', 'local', 'school')),
  evidence_class    text NOT NULL CHECK (evidence_class IN ('record', 'statement-answer', 'statement-other')),
  topic_id          uuid REFERENCES inform.compass_topics(id),
  codebook_version  text NOT NULL,
  model_set         text[] NOT NULL,
  n                 integer NOT NULL,
  m1_alpha          numeric,
  m2_alpha          numeric,
  m3_wilson_low     numeric,
  m4_severe         integer NOT NULL,
  certified         boolean NOT NULL,
  reason            text[] NOT NULL DEFAULT '{}',
  computed_at       timestamptz NOT NULL DEFAULT now(),
  CHECK (NOT certified OR evidence_class <> 'statement-other')  -- ruling Q2: never certifies
);

ALTER TABLE inform.stance_research_review
  ADD COLUMN IF NOT EXISTS review_mode      text,
  ADD COLUMN IF NOT EXISTS codebook_version text,
  ADD COLUMN IF NOT EXISTS unanimous        boolean,
  ADD COLUMN IF NOT EXISTS consensus_value  smallint,
  ADD COLUMN IF NOT EXISTS office_id        uuid REFERENCES essentials.offices(id);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.stance_research_review'::regclass
                  AND conname = 'stance_research_review_review_mode_check') THEN
    ALTER TABLE inform.stance_research_review ADD CONSTRAINT stance_research_review_review_mode_check
      CHECK (review_mode IS NULL OR review_mode IN ('blind', 'standard', 'audit'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'inform.stance_research_review'::regclass
                  AND conname = 'stance_research_review_consensus_value_check') THEN
    ALTER TABLE inform.stance_research_review ADD CONSTRAINT stance_research_review_consensus_value_check
      CHECK (consensus_value IS NULL OR consensus_value BETWEEN 1 AND 5);
  END IF;
END $$;

-- Append-only guards.
CREATE OR REPLACE FUNCTION inform.gold_labels_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'stance_gold_labels is append-only: write a superseding row instead of deleting %', OLD.id;
  END IF;
  IF (to_jsonb(NEW) - 'excluded_from_cert' - 'politician_id') IS DISTINCT FROM (to_jsonb(OLD) - 'excluded_from_cert' - 'politician_id') THEN
    RAISE EXCEPTION 'stance_gold_labels is append-only: only excluded_from_cert and politician_id may change (row %)', OLD.id;
  END IF;
  RETURN NEW;
END $$;
DROP TRIGGER IF EXISTS gold_labels_append_only ON inform.stance_gold_labels;
CREATE TRIGGER gold_labels_append_only BEFORE UPDATE OR DELETE ON inform.stance_gold_labels
  FOR EACH ROW EXECUTE FUNCTION inform.gold_labels_append_only();

CREATE OR REPLACE FUNCTION inform.certifications_immutable() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'reliability_certifications rows are never changed: insert a new row (decertification is a new row)';
END $$;
DROP TRIGGER IF EXISTS certifications_immutable ON inform.reliability_certifications;
CREATE TRIGGER certifications_immutable BEFORE UPDATE OR DELETE ON inform.reliability_certifications
  FOR EACH ROW EXECUTE FUNCTION inform.certifications_immutable();

-- RLS default-deny.
ALTER TABLE inform.source_snapshots            ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.stance_coder_labels         ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.stance_gold_labels          ENABLE ROW LEVEL SECURITY;
ALTER TABLE inform.reliability_certifications  ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON inform.source_snapshots, inform.stance_coder_labels, inform.stance_gold_labels,
              inform.reliability_certifications FROM anon, authenticated;

COMMENT ON TABLE inform.stance_gold_labels IS
  'Human stance decisions (spec 2026-09-25 §4.3). APPEND-ONLY (trigger). Only mode IN (blind, audit) '
  'with blind_submitted_at set and NOT excluded_from_cert counts toward certification. '
  'Duplicate-person merges must re-point politician_id here.';
COMMENT ON TABLE inform.stance_coder_labels IS
  'One row per coder per (batch, politician, office, topic) (spec §4.2). coder_slot 4 = the '
  'diagnostic other-vendor coder (ruling Q6), never counted. Duplicate-person merges must re-point '
  'politician_id here.';
COMMENT ON TABLE inform.source_snapshots IS
  'What the coders saw (spec §1.2). news/pointer = excerpt windows only; page_sha256 hashes the '
  'fetched page text.';

DO $$
DECLARE v int;
BEGIN
  SELECT count(*) INTO v FROM pg_tables WHERE schemaname = 'inform' AND rowsecurity
     AND tablename IN ('source_snapshots', 'stance_coder_labels', 'stance_gold_labels', 'reliability_certifications');
  IF v <> 4 THEN RAISE EXCEPTION 'CA_<slot>: expected 4 new RLS-enabled tables, found %', v; END IF;
  SELECT count(*) INTO v FROM information_schema.columns
   WHERE table_schema = 'inform' AND table_name = 'stance_research_review'
     AND column_name IN ('review_mode', 'codebook_version', 'unanimous', 'consensus_value', 'office_id');
  IF v <> 5 THEN RAISE EXCEPTION 'CA_<slot>: expected 5 new review columns, found %', v; END IF;
  SELECT count(*) INTO v FROM pg_trigger
   WHERE tgname IN ('gold_labels_append_only', 'certifications_immutable') AND NOT tgisinternal;
  IF v <> 2 THEN RAISE EXCEPTION 'CA_<slot>: expected 2 append-only triggers, found %', v; END IF;
END $$;

COMMIT;
```

- [ ] **Step 3: Run the static guards**

```bash
cd backend && npm run check:migrations && npm run check:reservations && npm run check:occupancy
```

Expected: all green (the new file sits in the author's own reserved slot).

- [ ] **Step 4: Commit the file (NOT applied)**

```bash
git commit -m "feat(db): CA_<slot> codebook reliability schema (not applied)" -- backend/migrations/CA_<slot>_codebook_reliability_schema.sql
```

- [ ] **Step 5: 🛑 STOP — ask the operator for OK to dry-run on production**

After the OK: copy the file to the scratchpad with the final `COMMIT;` replaced by `ROLLBACK;`, and
run it with `psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f <copy>`. Then confirm that it reverted:

```sql
SELECT count(*) FROM pg_tables WHERE schemaname='inform' AND tablename='stance_gold_labels';  -- expect 0
```

- [ ] **Step 6: 🛑 STOP — ask the operator for OK to apply.** After the OK, apply the real file and
record the result in the commit/PR body. Tasks 6, 11 and 12 `--apply` paths need this. Their dry-run
paths do not.

---

### Task 4: Annex skeleton builder

**Files:**
- Create: `backend/scripts/lib/codebookAnnex.ts`, `backend/scripts/lib/codebookAnnex.test.ts`,
  `backend/scripts/build-codebook-annex.ts`

**Interfaces:**
- Consumes: a `topics.json` topic from `build-stance-topic-bundle.ts` (`topic_id`, `topic_key`,
  `served_revision_id`, `question_text`, `stances: {value:number; text:string}[]`, `roles`).
- Produces:
  - `interface AnnexTopic`
  - `renderAnnexSkeleton(t: AnnexTopic, season: string): string`
  - `annexPath(repoRoot: string, topicKey: string): string`

- [ ] **Step 1: Write the failing test**

```ts
// backend/scripts/lib/codebookAnnex.test.ts
import { describe, it, expect } from 'vitest';
import { renderAnnexSkeleton, annexPath } from './codebookAnnex.js';

const topic = {
  topic_id: 't1', topic_key: 'school-vouchers', served_revision_id: 'rev-9', question_text: 'How should vouchers work?',
  stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value} text` })),
  roles: [{ level: 'state' }, { level: 'federal' }],
};

describe('renderAnnexSkeleton', () => {
  const md = renderAnnexSkeleton(topic, 'Season 2');
  it('heads the file with the topic key, served revision and season', () =>
    expect(md.split('\n')[0]).toBe('# school-vouchers — served revision rev-9 (Season 2)'));
  it('quotes every rung verbatim, in order', () => {
    for (const v of [1, 2, 3, 4, 5]) expect(md).toContain(`${v}. "rung ${v} text"`);
    expect(md.indexOf('1. "rung 1')).toBeLessThan(md.indexOf('5. "rung 5'));
  });
  it('leaves orientation explicitly unset (stance-program P4 is owed) rather than guessing', () =>
    expect(md).toContain('Orientation: UNSET'));
  it('lists the role levels', () => expect(md).toContain('Levels with a role: federal, state'));
  it('marks every guidance field for a human to fill', () =>
    expect(md.match(/_fill: /g)?.length).toBe(5 * 4 + 1));
});

describe('annexPath', () => {
  it('lives under docs/codebook/annex', () =>
    expect(annexPath('/repo', 'school-vouchers')).toBe('/repo/docs/codebook/annex/school-vouchers.md'));
});
```

- [ ] **Step 2: Run the test and confirm that it fails**

Run: `cd backend && npx vitest run scripts/lib/codebookAnnex.test.ts`
Expected: FAIL (module not found).

- [ ] **Step 3: Implement the lib and the script**

```ts
// backend/scripts/lib/codebookAnnex.ts
/**
 * codebookAnnex — renders a per-topic annex SKELETON (codebook Part C) from the served ladder.
 * It copies the rung text verbatim and leaves every judgment field as `_fill:` for a person. It never
 * infers orientation or evidence guidance: those are rulings, not derivations (stance-program P4).
 */
import { join } from 'node:path';

export interface AnnexTopic {
  topic_id: string;
  topic_key: string;
  served_revision_id: string;
  question_text: string;
  stances: { value: number; text: string }[];
  roles?: { level: string }[];
}

export function renderAnnexSkeleton(t: AnnexTopic, season: string): string {
  const levels = [...new Set((t.roles ?? []).map((r) => r.level))].sort().join(', ') || 'none recorded';
  const rungs = [...t.stances].sort((a, b) => a.value - b.value).map((s) => [
    `${s.value}. "${s.text}"`,
    '   - Operative clauses: _fill: ',
    '   - Establishing evidence looks like: _fill: ',
    '   - Known chair-shaped instruments: _fill: ',
    '   - Commonly confused with: _fill: ',
  ].join('\n'));
  return [
    `# ${t.topic_key} — served revision ${t.served_revision_id} (${season})`,
    '',
    `Question: ${t.question_text}`,
    'Orientation: UNSET — standard | inverted | off-axis, set by a person (stance-program §12.3 P4 is owed).',
    `Levels with a role: ${levels}`,
    '',
    '## Rungs',
    '',
    ...rungs,
    '',
    '## Hard cases',
    '',
    '_fill: ',
    '',
  ].join('\n');
}

export const annexPath = (repoRoot: string, topicKey: string): string =>
  join(repoRoot, 'docs', 'codebook', 'annex', `${topicKey}.md`);
```

```ts
// backend/scripts/build-codebook-annex.ts
/**
 * build-codebook-annex.ts — writes docs/codebook/annex/<topic_key>.md skeletons for a batch's
 * topics.json. NEVER overwrites an existing annex (a person's guidance lives there).
 *   npx tsx scripts/build-codebook-annex.ts --dir data/stance-research/<batch> --season "Season 2"
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { renderAnnexSkeleton, annexPath, type AnnexTopic } from './lib/codebookAnnex.js';

const arg = (name: string): string | undefined => { const i = process.argv.indexOf(name); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir');
const season = arg('--season');
if (!dir || !season) { console.error('usage: --dir <batch dir> --season "<season name>"'); process.exit(2); }
const repoRoot = resolve(process.cwd(), '..');
const topics = JSON.parse(readFileSync(join(dir, 'topics.json'), 'utf8')) as AnnexTopic[];
let wrote = 0;
for (const t of topics) {
  const p = annexPath(repoRoot, t.topic_key);
  if (existsSync(p)) { console.log(`keep   ${p}`); continue; }
  mkdirSync(dirname(p), { recursive: true });
  writeFileSync(p, renderAnnexSkeleton(t, season));
  console.log(`wrote  ${p}`);
  wrote++;
}
console.log(`${wrote} new annex skeleton(s); ${topics.length - wrote} kept`);
```

- [ ] **Step 4: Run the test and confirm that it passes**

Run: `cd backend && npx vitest run scripts/lib/codebookAnnex.test.ts`
Expected: PASS.

- [ ] **Step 5: Move the existing `school-vouchers` example**

Move the example out of the codebook's Part C into `docs/codebook/annex/school-vouchers.md`. Keep
the template in Part C, and replace the example there with a link to the new file. Keep the
`**Version:**` line unchanged: this is a wording move, not a material change.

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(codebook): annex skeleton builder; move school-vouchers annex to its own file" -- backend/scripts/lib/codebookAnnex.ts backend/scripts/lib/codebookAnnex.test.ts backend/scripts/build-codebook-annex.ts docs/codebook/annex/school-vouchers.md docs/codebook/stance-and-quote-codebook.md
```

---

## P1 — Shadow coding

### Task 5: `sources.json` contract (the collector's output)

**Files:**
- Create: `backend/scripts/lib/sourcesManifest.ts`, `backend/scripts/lib/sourcesManifest.test.ts`

**Interfaces:**
- Produces:
  - `SOURCE_KINDS`
  - `type SourceKind`
  - `interface SourceEntry`
  - `interface SourcesManifest`
  - `FORBIDDEN_OPINION_KEYS`
  - `parseSourcesManifest(raw: unknown): { ok: true; manifest: SourcesManifest } | { ok: false; errors: string[] }`
  - `isExcerptOnly(kind: SourceKind): boolean`

- [ ] **Step 1: Write the failing test**

```ts
// backend/scripts/lib/sourcesManifest.test.ts
import { describe, it, expect } from 'vitest';
import { parseSourcesManifest, isExcerptOnly } from './sourcesManifest.js';

const entry = {
  url: 'https://le.utah.gov/~2022/bills/static/HB0011.html', source_kind: 'public-record',
  politician_id: 'p1', office_id: 'o1', topic_keys: ['trans-athletes'], instruments: ['H.B. 11 (2022)'],
  pointer_passages: ['requires students to compete on teams matching their sex at birth'], candidate_quotes: [],
};
const manifest = (sources: unknown[]) => ({ batch_id: '2026-09-26-adams', sources });

describe('parseSourcesManifest', () => {
  it('accepts a well-formed manifest', () => {
    const r = parseSourcesManifest(manifest([entry]));
    expect(r.ok).toBe(true);
  });
  it.each(['value', 'chair', 'reasoning', 'stance', 'proposed_value'])(
    'refuses the collector-opinion key %s (spec §1.1: the collector writes no opinion)', (k) => {
      const r = parseSourcesManifest(manifest([{ ...entry, [k]: 4 }]));
      expect(r).toEqual({ ok: false, errors: [`sources[0]: collector-opinion key "${k}" is not allowed`] });
    });
  it('refuses an unknown source kind and a URL without a path', () => {
    const r = parseSourcesManifest(manifest([{ ...entry, source_kind: 'blog', url: 'https://example.com' }]));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.errors).toEqual(['sources[0]: source_kind blog not allowed', 'sources[0]: url has no path']);
  });
  it('requires at least one anchor for an excerpt-only kind (news/pointer), else nothing can be excerpted', () => {
    const r = parseSourcesManifest(manifest([{ ...entry, source_kind: 'news', pointer_passages: [], candidate_quotes: [] }]));
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.errors).toEqual(['sources[0]: news source needs a pointer_passage or candidate_quote to excerpt around']);
  });
  it('accepts a human-saved page path', () => {
    expect(parseSourcesManifest(manifest([{ ...entry, human_saved_path: 'human-saved/hb11.html' }])).ok).toBe(true);
  });
});

describe('isExcerptOnly', () => {
  it('stores excerpts only for news and pointers (spec §5.4)', () => {
    expect(isExcerptOnly('news')).toBe(true);
    expect(isExcerptOnly('pointer')).toBe(true);
    expect(isExcerptOnly('public-record')).toBe(false);
    expect(isExcerptOnly('own-site')).toBe(false);
    expect(isExcerptOnly('transcript')).toBe(false);
  });
});
```

- [ ] **Step 2: Run the test and confirm that it fails**

Run: `cd backend && npx vitest run scripts/lib/sourcesManifest.test.ts` — expected FAIL.

- [ ] **Step 3: Implement**

```ts
// backend/scripts/lib/sourcesManifest.ts
/**
 * sourcesManifest — the collector's (inline /research-stances session's) output contract:
 * <batch>/sources.json. It lists WHERE evidence is, never WHAT it proves (spec §1.1): a chair or
 * reasoning key here would let the collector's opinion reach the coders, so it is refused.
 */
export const SOURCE_KINDS = ['public-record', 'own-site', 'news', 'pointer', 'transcript'] as const;
export type SourceKind = typeof SOURCE_KINDS[number];
export const FORBIDDEN_OPINION_KEYS = ['value', 'chair', 'reasoning', 'stance', 'proposed_value'] as const;

export interface SourceEntry {
  url: string;
  source_kind: SourceKind;
  politician_id: string;
  office_id: string;
  topic_keys: string[];
  instruments: string[];
  /** Text the collector saw on the page, used as excerpt anchors. Verbatim. */
  pointer_passages: string[];
  candidate_quotes: string[];
  /** Page saved by a person in a real browser (spec §5.4), relative to the batch dir. */
  human_saved_path?: string;
}
export interface SourcesManifest { batch_id: string; sources: SourceEntry[] }

export const isExcerptOnly = (k: SourceKind): boolean => k === 'news' || k === 'pointer';

const strArr = (x: unknown): x is string[] => Array.isArray(x) && x.every((v) => typeof v === 'string');

export function parseSourcesManifest(raw: unknown): { ok: true; manifest: SourcesManifest } | { ok: false; errors: string[] } {
  const errors: string[] = [];
  if (typeof raw !== 'object' || raw === null || !Array.isArray((raw as { sources?: unknown }).sources)) {
    return { ok: false, errors: ['not an object with a sources array'] };
  }
  const m = raw as { batch_id?: unknown; sources: unknown[] };
  if (typeof m.batch_id !== 'string' || !m.batch_id) errors.push('batch_id missing');
  m.sources.forEach((s, i) => {
    const at = `sources[${i}]`;
    if (typeof s !== 'object' || s === null) { errors.push(`${at}: not an object`); return; }
    const e = s as Record<string, unknown>;
    for (const k of FORBIDDEN_OPINION_KEYS) if (k in e) errors.push(`${at}: collector-opinion key "${k}" is not allowed`);
    if (!(SOURCE_KINDS as readonly unknown[]).includes(e.source_kind)) errors.push(`${at}: source_kind ${String(e.source_kind)} not allowed`);
    if (typeof e.url !== 'string') errors.push(`${at}: url missing`);
    else {
      try { const u = new URL(e.url); if (u.pathname === '/' || u.pathname === '') errors.push(`${at}: url has no path`); }
      catch { errors.push(`${at}: url not parseable`); }
    }
    for (const k of ['politician_id', 'office_id'] as const) if (typeof e[k] !== 'string' || !e[k]) errors.push(`${at}: ${k} missing`);
    for (const k of ['topic_keys', 'instruments', 'pointer_passages', 'candidate_quotes'] as const) if (!strArr(e[k])) errors.push(`${at}: ${k} not a string array`);
    if (e.human_saved_path !== undefined && typeof e.human_saved_path !== 'string') errors.push(`${at}: human_saved_path not a string`);
    if ((e.source_kind === 'news' || e.source_kind === 'pointer')
      && strArr(e.pointer_passages) && strArr(e.candidate_quotes)
      && e.pointer_passages.length + e.candidate_quotes.length === 0) {
      errors.push(`${at}: ${String(e.source_kind)} source needs a pointer_passage or candidate_quote to excerpt around`);
    }
  });
  return errors.length ? { ok: false, errors } : { ok: true, manifest: raw as SourcesManifest };
}
```

- [ ] **Step 4: Run the test and confirm that it passes** — `npx vitest run scripts/lib/sourcesManifest.test.ts`, expected PASS.

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(stance-coding): sources.json contract — the collector writes no opinion" -- backend/scripts/lib/sourcesManifest.ts backend/scripts/lib/sourcesManifest.test.ts
```

---

### Task 6: Snapshots

**Files:**
- Create: `backend/scripts/lib/snapshotSources.ts`, `backend/scripts/lib/snapshotSources.test.ts`,
  `backend/scripts/snapshot-sources.ts`

**Interfaces:**
- Consumes:
  - `SourceEntry`, `isExcerptOnly`, `parseSourcesManifest` (Task 5);
  - `normalizeText`, `createPageFetcher` (`backend/src/lib/researchVerifier.ts`);
  - `createVerificationFetchSession`, `htmlToText` (`backend/src/lib/verificationFetch.ts`).
- Produces:
  - `interface SnapshotRecord { snapshot_id; url; source_kind; fetched_by: 'code' | 'human'; ok: boolean; failure: string | null; page_sha256: string | null; snapshot_text: string | null; excerpt_only: boolean }`
  - `EXCERPT_CONTEXT_WORDS = 150`
  - `excerptWindows(text: string, anchors: string[], ctx?: number): string | null`
  - `buildSnapshot(args): SnapshotRecord`
  - the file `<batch>/snapshots.json`, containing `SnapshotRecord[]`.

- [ ] **Step 1: Write the failing test**

```ts
// backend/scripts/lib/snapshotSources.test.ts
import { describe, it, expect } from 'vitest';
import { excerptWindows, buildSnapshot } from './snapshotSources.js';
import type { SourceEntry } from './sourcesManifest.js';

const words = (n: number, w = 'filler') => Array.from({ length: n }, (_, i) => `${w}${i}`).join(' ');
const page = `${words(400, 'a')} The Senator said “we will repeal the fuel standard” today. ${words(400, 'b')}`;

describe('excerptWindows', () => {
  it('keeps the anchor plus context on both sides, in original case, and marks the cuts', () => {
    const x = excerptWindows(page, ['we will repeal the fuel standard'], 5)!;
    // anchor = tokens 403..408; 5 words either side → tokens 398..413
    expect(x).toBe('… a398 a399 The Senator said “we will repeal the fuel standard” today. b0 b1 b2 b3 …');
  });
  it('matches whole words only ("the" does not match "there")', () => {
    expect(excerptWindows('there fuel standard is here', ['the fuel standard'], 1)).toBeNull();
  });
  it('matches the anchor with the verifier normalisation (curly quotes, case)', () => {
    expect(excerptWindows(page, ['WE WILL REPEAL THE FUEL STANDARD'], 2)).toContain('repeal the fuel standard');
  });
  it('merges overlapping windows into one', () => {
    const x = excerptWindows(page, ['The Senator said', 'the fuel standard'], 3)!;
    expect(x.split(' … ').length).toBe(1);
  });
  it('returns null when no anchor is on the page (nothing can be excerpted → not codable)', () => {
    expect(excerptWindows(page, ['a sentence that is not there'], 5)).toBeNull();
  });
});

const entry = (over: Partial<SourceEntry> = {}): SourceEntry => ({
  url: 'https://news.example/story/1', source_kind: 'news', politician_id: 'p1', office_id: 'o1',
  topic_keys: ['fossil-fuels'], instruments: [], pointer_passages: ['we will repeal the fuel standard'], candidate_quotes: [], ...over,
});

describe('buildSnapshot', () => {
  const id = () => 'snap-1';
  it('stores excerpt windows only for a news source, and hashes the whole fetched page', () => {
    const s = buildSnapshot({ entry: entry(), fetchedText: page, failure: null, fetchedBy: 'code', newId: id });
    expect(s.ok).toBe(true);
    expect(s.excerpt_only).toBe(true);
    expect(s.snapshot_text!.length).toBeLessThan(page.length);
    expect(s.page_sha256).toMatch(/^[0-9a-f]{64}$/);
  });
  it('stores the full whitespace-collapsed text for a public record', () => {
    const s = buildSnapshot({ entry: entry({ source_kind: 'public-record' }), fetchedText: 'A   bill\n\ntext', failure: null, fetchedBy: 'code', newId: id });
    expect(s.snapshot_text).toBe('A bill text');
    expect(s.excerpt_only).toBe(false);
  });
  it('records a fetch failure as not codable', () => {
    const s = buildSnapshot({ entry: entry(), fetchedText: null, failure: 'robots_disallowed', fetchedBy: 'code', newId: id });
    expect(s).toMatchObject({ ok: false, failure: 'robots_disallowed', snapshot_text: null, page_sha256: null });
  });
  it('records a news page whose anchors are missing as not codable', () => {
    const s = buildSnapshot({ entry: entry({ pointer_passages: ['absent text here'] }), fetchedText: page, failure: null, fetchedBy: 'code', newId: id });
    expect(s).toMatchObject({ ok: false, failure: 'anchor-not-found' });
  });
});
```

- [ ] **Step 2: Run the test and confirm that it fails** — expected FAIL (module not found).

- [ ] **Step 3: Implement the lib**

```ts
// backend/scripts/lib/snapshotSources.ts
/**
 * snapshotSources — turns a fetched page into what the coders see (spec §1.2, §5.4).
 * news / pointer → excerpt windows around the collector's anchors only (quotation size, not copy
 * size); public-record / own-site / transcript → the full whitespace-collapsed text.
 * page_sha256 hashes the whole fetched page text so a later re-fetch can be compared.
 * Anchors are located with the verifier's normalisation, but the excerpt keeps the page's own case.
 */
import { createHash } from 'node:crypto';
import { normalizeText } from '../../src/lib/researchVerifier.js';
import { isExcerptOnly, type SourceEntry, type SourceKind } from './sourcesManifest.js';

export const EXCERPT_CONTEXT_WORDS = 150;

export interface SnapshotRecord {
  snapshot_id: string;
  url: string;
  source_kind: SourceKind;
  fetched_by: 'code' | 'human';
  ok: boolean;
  failure: string | null;
  page_sha256: string | null;
  snapshot_text: string | null;
  excerpt_only: boolean;
}

const collapse = (s: string) => s.replace(/\s+/g, ' ').trim();

export function excerptWindows(text: string, anchors: string[], ctx = EXCERPT_CONTEXT_WORDS): string | null {
  // A page token may carry punctuation around a word ("“we", "standard”", "today."): compare words
  // with edge punctuation stripped, and require EQUALITY so "the" never matches "there".
  const bare = (w: string) => normalizeText(w).replace(/^[^a-z0-9]+|[^a-z0-9]+$/g, '');
  const orig = collapse(text).split(' ');
  const norm = orig.map(bare);
  const spans: [number, number][] = [];
  for (const a of anchors) {
    const aw = collapse(a).split(' ').map(bare).filter(Boolean);
    if (!aw.length) continue;
    for (let i = 0; i + aw.length <= norm.length; i++) {
      let hit = true;
      for (let j = 0; j < aw.length; j++) {
        if (norm[i + j] !== aw[j]) { hit = false; break; }
      }
      if (hit) { spans.push([Math.max(0, i - ctx), Math.min(orig.length, i + aw.length + ctx)]); break; }
    }
  }
  if (!spans.length) return null;
  spans.sort((x, y) => x[0] - y[0]);
  const merged: [number, number][] = [];
  for (const s of spans) {
    const last = merged[merged.length - 1];
    if (last && s[0] <= last[1]) last[1] = Math.max(last[1], s[1]);
    else merged.push([s[0], s[1]]);
  }
  return merged
    .map(([a, b]) => `${a > 0 ? '… ' : ''}${orig.slice(a, b).join(' ')}${b < orig.length ? ' …' : ''}`)
    .join(' ')
    .replace(/ … … /g, ' … ');
}

export function buildSnapshot(args: {
  entry: SourceEntry;
  fetchedText: string | null;
  failure: string | null;
  fetchedBy: 'code' | 'human';
  newId: () => string;
}): SnapshotRecord {
  const { entry, fetchedText, failure, fetchedBy, newId } = args;
  const excerptOnly = isExcerptOnly(entry.source_kind);
  const base = { snapshot_id: newId(), url: entry.url, source_kind: entry.source_kind, fetched_by: fetchedBy, excerpt_only: excerptOnly };
  if (fetchedText === null) return { ...base, ok: false, failure: failure ?? 'fetch-failed', page_sha256: null, snapshot_text: null };
  const sha = createHash('sha256').update(fetchedText).digest('hex');
  const text = excerptOnly
    ? excerptWindows(fetchedText, [...entry.pointer_passages, ...entry.candidate_quotes])
    : collapse(fetchedText);
  if (!text) return { ...base, ok: false, failure: 'anchor-not-found', page_sha256: sha, snapshot_text: null };
  return { ...base, ok: true, failure: null, page_sha256: sha, snapshot_text: text };
}
```

- [ ] **Step 4: Run the test and confirm that it passes.**

If the exact-string test in `excerptWindows` shows an off-by-one against the `ctx` window, fix the
implementation, not the expected string. The expected string is the spec: 5 words of context on each
side, and `…` at each cut.

- [ ] **Step 5: Write the script**

```ts
// backend/scripts/snapshot-sources.ts
/**
 * snapshot-sources.ts — fetch every source in <batch>/sources.json through the verifier's fetch
 * ladder (HTTP → Wayback, robots respected), or read a human-saved page (spec §5.4), and write
 * <batch>/snapshots.json. --apply also inserts inform.source_snapshots (needs CA_<slot> applied and the
 * operator's OK). No LLM in the loop.
 *   npx tsx scripts/snapshot-sources.ts --dir data/stance-research/<batch> [--apply]
 * Exit 0 always writes the file; failures are listed and are not codable (spec §5.4).
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { randomUUID } from 'node:crypto';
import { parseSourcesManifest } from './lib/sourcesManifest.js';
import { buildSnapshot, type SnapshotRecord } from './lib/snapshotSources.js';
import { createPageFetcher } from '../src/lib/researchVerifier.js';
import { createVerificationFetchSession, htmlToText } from '../src/lib/verificationFetch.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir');
const APPLY = process.argv.includes('--apply');
if (!dir) { console.error('usage: --dir <batch dir> [--apply]'); process.exit(2); }

const parsed = parseSourcesManifest(JSON.parse(readFileSync(join(dir, 'sources.json'), 'utf8')));
if (!parsed.ok) { console.error(parsed.errors.join('\n')); process.exit(2); }
const { manifest } = parsed;

const session = createVerificationFetchSession();
const fetcher = createPageFetcher(session.fetch);
const out: SnapshotRecord[] = [];
for (const entry of manifest.sources) {
  if (entry.human_saved_path) {
    const html = readFileSync(join(dir, entry.human_saved_path), 'utf8');
    out.push(buildSnapshot({ entry, fetchedText: htmlToText(html), failure: null, fetchedBy: 'human', newId: randomUUID }));
    continue;
  }
  const r = await fetcher(entry.url);
  out.push(r.ok
    ? buildSnapshot({ entry, fetchedText: r.text, failure: null, fetchedBy: 'code', newId: randomUUID })
    : buildSnapshot({ entry, fetchedText: null, failure: r.reason, fetchedBy: 'code', newId: randomUUID }));
}
await session.close();
writeFileSync(join(dir, 'snapshots.json'), JSON.stringify(out, null, 2));
const bad = out.filter((s) => !s.ok);
console.log(`${out.length - bad.length}/${out.length} sources snapshotted → ${join(dir, 'snapshots.json')}`);
for (const s of bad) console.log(`  NOT CODABLE  ${s.failure}  ${s.url}${s.source_kind === 'public-record' || s.source_kind === 'own-site' ? '  → a person may save it in a browser (spec §5.4)' : ''}`);

if (APPLY) {
  const { pool } = await import('../src/lib/db.js');
  for (const s of out.filter((x) => x.ok)) {
    await pool.query(
      `INSERT INTO inform.source_snapshots (id, batch_id, url, source_kind, fetched_by, page_sha256, snapshot_text, excerpt_only)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8) ON CONFLICT (batch_id, url, page_sha256) DO NOTHING`,
      [s.snapshot_id, manifest.batch_id, s.url, s.source_kind, s.fetched_by, s.page_sha256, s.snapshot_text, s.excerpt_only]);
  }
  await pool.end();
  console.log('inserted into inform.source_snapshots');
}
```

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(stance-coding): snapshot sources — excerpt-only for news, full text for public records" -- backend/scripts/lib/snapshotSources.ts backend/scripts/lib/snapshotSources.test.ts backend/scripts/snapshot-sources.ts
```

---

### Task 7: Coder inputs (seat context and three prompts)

**Files:**
- Create: `backend/scripts/lib/coderPrompt.ts`, `backend/scripts/lib/coderPrompt.test.ts`,
  `backend/scripts/build-coder-inputs.ts`

**Interfaces:**
- Consumes:
  - `SnapshotRecord` (Task 6);
  - `CODEBOOK_VERSION` (Task 2);
  - `topics.json` / `politicians.json` from `build-stance-topic-bundle.ts`.
- Produces:
  - `interface SeatContext { politician_id; full_name; level: string | null; mode: 'seated' | 'candidate'; office_id; office_title; jurisdiction_names: string[]; term_start: string | null; start_precision: string | null; term_end: string | null; election_date: string | null }`
  - `interface PromptTopic { topic_id; topic_key; served_revision_id; question_text; stances: {value:number; text:string}[]; annexMd: string | null }`
  - `shuffleSeeded<T>(xs: readonly T[], seed: number): T[]`
  - `seedFor(batchId: string, slot: number): number`
  - `buildCoderPrompt(i: { codebookMd: string; seat: SeatContext; topics: PromptTopic[]; snapshots: SnapshotRecord[]; slot: 1 | 2 | 3; seed: number; labelPath: string }): string`
  - the files `<batch>/coding-context.json` (`{ batch_id, seat: SeatContext, topics: PromptTopic[] }`)
    and `<batch>/coder-inputs/coder-{1,2,3}.md`.

- [ ] **Step 1: Write the failing test**

```ts
// backend/scripts/lib/coderPrompt.test.ts
import { describe, it, expect } from 'vitest';
import { buildCoderPrompt, shuffleSeeded, seedFor, type SeatContext, type PromptTopic } from './coderPrompt.js';
import type { SnapshotRecord } from './snapshotSources.js';

const seat: SeatContext = {
  politician_id: 'p1', full_name: 'J. Stuart Adams', level: 'state', mode: 'seated', office_id: 'o1',
  office_title: 'State Senator', jurisdiction_names: ['Utah'], term_start: '2021-01-01', start_precision: 'day', term_end: null, election_date: null,
};
const topic: PromptTopic = {
  topic_id: 't1', topic_key: 'trans-athletes', served_revision_id: 'r1', question_text: 'Q?',
  stances: [1, 2, 3, 4, 5].map((value) => ({ value, text: `rung ${value}` })), annexMd: '# annex body',
};
const snap = (id: string, kind: SnapshotRecord['source_kind'] = 'public-record'): SnapshotRecord => ({
  snapshot_id: id, url: `https://x.gov/${id}`, source_kind: kind, fetched_by: 'code', ok: true, failure: null,
  page_sha256: 'f'.repeat(64), snapshot_text: `text of ${id}`, excerpt_only: false,
});
const snaps = ['s1', 's2', 's3', 's4', 's5'].map((s) => snap(s));
const build = (slot: 1 | 2 | 3, seed: number, snapshots = snaps) =>
  buildCoderPrompt({ codebookMd: '# CODEBOOK', seat, topics: [topic], snapshots, slot, seed, labelPath: `/b/labels/coder-${slot}.json` });

describe('shuffleSeeded / seedFor', () => {
  it('is deterministic per seed and a permutation', () => {
    expect(shuffleSeeded([1, 2, 3, 4, 5], 7)).toEqual(shuffleSeeded([1, 2, 3, 4, 5], 7));
    expect([...shuffleSeeded([1, 2, 3, 4, 5], 7)].sort()).toEqual([1, 2, 3, 4, 5]);
  });
  it('gives the three slots different seeds', () => {
    expect(new Set([1, 2, 3].map((s) => seedFor('batch-a', s))).size).toBe(3);
  });
});

describe('buildCoderPrompt', () => {
  it('contains the codebook, the annex, all five rungs, the seat and every codable snapshot id', () => {
    const p = build(1, 1);
    for (const s of ['# CODEBOOK', '# annex body', 'rung 1', 'rung 5', 'J. Stuart Adams', 'State Senator', 'Utah', 's1', 's5']) expect(p).toContain(s);
  });
  it('orders sources differently across the three slots (independence, spec §1.3)', () => {
    const order = (p: string) => [...p.matchAll(/snapshot_id: (s\d)/g)].map((m) => m[1]).join(',');
    const orders = new Set(([1, 2, 3] as const).map((s) => order(build(s, seedFor('b', s)))));
    expect(orders.size).toBeGreaterThan(1);
  });
  it('tags pointer sources so no chair can rest on them', () => {
    expect(build(1, 1, [snap('s9', 'pointer')])).toContain('source_kind: pointer (NOT evidence');
  });
  it('omits snapshots that are not codable', () => {
    const p = build(1, 1, [{ ...snap('dead'), ok: false, snapshot_text: null, failure: 'robots_disallowed' }]);
    expect(p).not.toContain('snapshot_id: dead');
  });
  it('names the exact output path, the slot, the codebook version, and forbids other tools', () => {
    const p = build(3, 1);
    expect(p).toContain('/b/labels/coder-3.json');
    expect(p).toContain('"coder_slot": 3');
    expect(p).toMatch(/Use only the Write tool/);
  });
  it('never mentions party', () => expect(build(1, 1)).not.toMatch(/\b(Republican|Democrat)/));
});
```

- [ ] **Step 2: Run the test and confirm that it fails** — expected FAIL.

- [ ] **Step 3: Implement the lib**

```ts
// backend/scripts/lib/coderPrompt.ts
/**
 * coderPrompt — the complete input for one tool-less stance coder (spec §1.3, ruling Q1).
 * Everything the coder may use is IN this text: codebook, annex, the served ladder, the seat, and
 * the snapshot passages. Nothing from the collector's own reading (research.csv) is passed. Source
 * order is shuffled per slot so the three coders do not share a primacy bias.
 */
import { createHash } from 'node:crypto';
import { CODEBOOK_VERSION } from './coderLabel.js';
import type { SnapshotRecord } from './snapshotSources.js';

export interface SeatContext {
  politician_id: string;
  full_name: string;
  level: string | null;
  mode: 'seated' | 'candidate';
  office_id: string;
  office_title: string;
  jurisdiction_names: string[];
  term_start: string | null;
  start_precision: string | null;
  term_end: string | null;
  election_date: string | null;
}
export interface PromptTopic {
  topic_id: string;
  topic_key: string;
  served_revision_id: string;
  question_text: string;
  stances: { value: number; text: string }[];
  annexMd: string | null;
}

/** mulberry32 — small, deterministic, good enough for ordering. */
function rng(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
export function shuffleSeeded<T>(xs: readonly T[], seed: number): T[] {
  const out = [...xs];
  const r = rng(seed);
  for (let i = out.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [out[i], out[j]] = [out[j], out[i]]; }
  return out;
}
export const seedFor = (batchId: string, slot: number): number =>
  createHash('sha256').update(`${batchId}#${slot}`).digest().readUInt32BE(0);

const KIND_NOTE: Record<SnapshotRecord['source_kind'], string> = {
  'public-record': 'public-record',
  'own-site': "own-site (the person's own site or account)",
  news: 'news (excerpt only)',
  pointer: 'pointer (NOT evidence — you may not rest a chair on it; use it only to name a needs_source)',
  transcript: 'transcript',
};

export function buildCoderPrompt(i: {
  codebookMd: string; seat: SeatContext; topics: PromptTopic[]; snapshots: SnapshotRecord[];
  slot: 1 | 2 | 3; seed: number; labelPath: string;
}): string {
  const codable = shuffleSeeded(i.snapshots.filter((s) => s.ok && s.snapshot_text), i.seed);
  const s = i.seat;
  const topics = i.topics.map((t) => [
    `### topic_key: ${t.topic_key}`,
    `topic_id: ${t.topic_id}  served_revision_id: ${t.served_revision_id}`,
    `Question: ${t.question_text}`,
    ...[...t.stances].sort((a, b) => a.value - b.value).map((r) => `  ${r.value}. ${r.text}`),
    '',
    t.annexMd ? `#### Annex\n\n${t.annexMd}` : '#### Annex\n\n(no annex for this topic yet — apply the codebook alone)',
  ].join('\n')).join('\n\n');
  const sources = codable.map((x) => [
    `---`,
    `snapshot_id: ${x.snapshot_id}`,
    `source_kind: ${KIND_NOTE[x.source_kind]}`,
    `url: ${x.url}`,
    '',
    x.snapshot_text,
  ].join('\n')).join('\n\n');
  return [
    `You are stance coder ${i.slot}. You code evidence against the codebook below. You do not search,`,
    'fetch or verify anything: every source you may use is in this message, and code checks your',
    'labels afterwards. If the evidence a row needs is named but not included here, put it in',
    'needs_source instead of guessing.',
    '',
    `Use only the Write tool, exactly once, to write ${i.labelPath}. Write JSON only, matching`,
    `codebook Part E, with "codebook_version": "${CODEBOOK_VERSION}" and "coder_slot": ${i.slot}. One row per`,
    'topic below. Every quoted string you write must be copied exactly from a source below.',
    '',
    '## Codebook',
    '',
    i.codebookMd,
    '',
    '## The person',
    '',
    `politician_id: ${s.politician_id}  office_id: ${s.office_id}`,
    `${s.full_name} — ${s.office_title}, ${s.jurisdiction_names.join(' / ') || 'jurisdiction unknown'} (${s.mode}, level: ${s.level ?? 'unknown'})`,
    s.mode === 'seated'
      ? `Current term: ${s.term_start ?? 'unknown'} (precision: ${s.start_precision ?? 'unknown'}) to ${s.term_end ?? 'present'}`
      : `Candidate in the election of ${s.election_date ?? 'unknown date'}`,
    '',
    '## Topics (served ladder text — code against these words only)',
    '',
    topics,
    '',
    '## Sources',
    '',
    sources || '(no codable sources — every row is BLANK no-evidence, with needs_source where you can name one)',
  ].join('\n');
}
```

- [ ] **Step 4: Run the test and confirm that it passes.**

- [ ] **Step 5: Write the script**

```ts
// backend/scripts/build-coder-inputs.ts
/**
 * build-coder-inputs.ts — writes <batch>/coding-context.json and <batch>/coder-inputs/coder-{1,2,3}.md
 * for ONE politician (one politician per run, ruling 2026-09-23). Reads the DB (read-only) for the
 * seat: a seated person via office_current_holder, a candidate via their race.
 * 🔴 A politician-rooted office_current_holder join can return several offices (CLAUDE.md) — pass
 * --office when it does; the script refuses to guess.
 *   npx tsx scripts/build-coder-inputs.ts --dir <batch> --politician <uuid> [--office <uuid>]
 */
import 'dotenv/config';
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { createHash } from 'node:crypto';
import { pool } from '../src/lib/db.js';
import { buildCoderPrompt, seedFor, type SeatContext, type PromptTopic } from './lib/coderPrompt.js';
import { annexPath } from './lib/codebookAnnex.js';
import type { SnapshotRecord } from './lib/snapshotSources.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir'); const politicianId = arg('--politician'); const officeArg = arg('--office');
if (!dir || !politicianId) { console.error('usage: --dir <batch> --politician <uuid> [--office <uuid>]'); process.exit(2); }
const repoRoot = resolve(process.cwd(), '..');

const politicians = JSON.parse(readFileSync(join(dir, 'politicians.json'), 'utf8')) as { full_name: string; politician_id: string; level: string | null; race_id: string | null }[];
const pol = politicians.find((p) => p.politician_id === politicianId);
if (!pol) { console.error(`politician ${politicianId} not in ${dir}/politicians.json`); process.exit(2); }

let seat: SeatContext;
const held = await pool.query(
  `SELECT och.office_id::text, o.title, o.representing_state, o.representing_city,
          och.term_start::text, och.term_end::text,
          (SELECT ot.start_precision FROM essentials.office_terms ot
            WHERE ot.office_id = och.office_id AND ot.politician_id = och.politician_id
            ORDER BY ot.term_start DESC NULLS LAST LIMIT 1) AS start_precision
     FROM essentials.office_current_holder och JOIN essentials.offices o ON o.id = och.office_id
    WHERE och.politician_id = $1`, [politicianId]);
const heldRows = officeArg ? held.rows.filter((r) => r.office_id === officeArg) : held.rows;
if (heldRows.length > 1) {
  console.error(`politician holds ${heldRows.length} offices — pass --office one of: ${heldRows.map((r) => `${r.office_id} (${r.title})`).join(', ')}`);
  process.exit(2);
}
if (heldRows.length === 1) {
  const r = heldRows[0];
  seat = { politician_id: politicianId, full_name: pol.full_name, level: pol.level, mode: 'seated', office_id: r.office_id, office_title: r.title,
    jurisdiction_names: [r.representing_state, r.representing_city].filter(Boolean), term_start: r.term_start, start_precision: r.start_precision, term_end: r.term_end, election_date: null };
} else if (pol.race_id) {
  const race = await pool.query(
    `SELECT r.office_id::text, o.title, o.representing_state, o.representing_city, e.election_date::text
       FROM essentials.races r JOIN essentials.offices o ON o.id = r.office_id JOIN essentials.elections e ON e.id = r.election_id
      WHERE r.id = $1`, [pol.race_id]);
  if (race.rowCount !== 1) { console.error(`race ${pol.race_id} not found`); process.exit(2); }
  const r = race.rows[0];
  seat = { politician_id: politicianId, full_name: pol.full_name, level: pol.level, mode: 'candidate', office_id: r.office_id, office_title: r.title,
    jurisdiction_names: [r.representing_state, r.representing_city].filter(Boolean), term_start: null, start_precision: null, term_end: null, election_date: r.election_date };
} else { console.error('no current seat and no race — cannot establish the office being coded'); process.exit(2); }
await pool.end();

const topicsRaw = JSON.parse(readFileSync(join(dir, 'topics.json'), 'utf8')) as Omit<PromptTopic, 'annexMd'>[];
const topics: PromptTopic[] = topicsRaw.map((t) => {
  const p = annexPath(repoRoot, t.topic_key);
  return { topic_id: t.topic_id, topic_key: t.topic_key, served_revision_id: t.served_revision_id, question_text: t.question_text, stances: t.stances,
    annexMd: existsSync(p) ? readFileSync(p, 'utf8') : null };
});
const snapshots = JSON.parse(readFileSync(join(dir, 'snapshots.json'), 'utf8')) as SnapshotRecord[];
const codebookMd = readFileSync(join(repoRoot, 'docs', 'codebook', 'stance-and-quote-codebook.md'), 'utf8');
const batchId = dir.split('/').filter(Boolean).pop()!;

writeFileSync(join(dir, 'coding-context.json'), JSON.stringify({ batch_id: batchId, seat, topics }, null, 2));
mkdirSync(join(dir, 'coder-inputs'), { recursive: true });
mkdirSync(join(dir, 'labels'), { recursive: true });
for (const slot of [1, 2, 3] as const) {
  const labelPath = resolve(dir, 'labels', `coder-${slot}.json`);
  const text = buildCoderPrompt({ codebookMd, seat, topics, snapshots, slot, seed: seedFor(batchId, slot), labelPath });
  const p = join(dir, 'coder-inputs', `coder-${slot}.md`);
  writeFileSync(p, text);
  console.log(`${p}  sha256 ${createHash('sha256').update(text).digest('hex').slice(0, 12)}  (${text.length} chars)`);
}
```

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(stance-coding): seat context + three shuffled coder prompts" -- backend/scripts/lib/coderPrompt.ts backend/scripts/lib/coderPrompt.test.ts backend/scripts/build-coder-inputs.ts
```

---

### Task 8: The `stance-coder` agent and its tool guard

**Files:**
- Create: `.claude/agents/stance-coder.md`, `backend/scripts/lib/stanceCoderAgent.test.ts`

**Interfaces:**
- Produces: the sub-agent type `stance-coder` for the Agent tool. Task 13 dispatches it.

- [ ] **Step 1: Write the failing guard test**

```ts
// backend/scripts/lib/stanceCoderAgent.test.ts
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const md = readFileSync(fileURLToPath(new URL('../../../.claude/agents/stance-coder.md', import.meta.url)), 'utf8');
const front = md.split('---')[1];

describe('stance-coder agent (ruling Q1, 2026-09-25)', () => {
  it('is named stance-coder', () => expect(front).toMatch(/^name: stance-coder$/m));
  it('has exactly the Write tool — no Read, Bash, WebFetch, WebSearch or MCP', () =>
    expect(front).toMatch(/^tools: Write$/m));
});
```

- [ ] **Step 2: Run it and confirm that it fails** — expected FAIL (ENOENT).

- [ ] **Step 3: Write the agent**

```markdown
---
name: stance-coder
description: "Tool-less stance coder for /research-stances shadow coding (spec 2026-09-25). Dispatched three times per politician with the full contents of <batch>/coder-inputs/coder-N.md as its prompt. It labels only what is in its prompt and writes one JSON file. Never dispatch it for research."
tools: Write
color: yellow
---

You are a stance coder. Your prompt contains everything you may use: the codebook, the topic
annexes, the served ladder text, the person, and the source passages.

- Do not try to search, fetch, open or verify anything. You have no tool for it, and code verifies
  your labels afterwards.
- Follow the codebook exactly, in its decision order (V1 → V6, then V7 → V8).
- A BLANK is a correct answer. When the evidence you need is named but missing, put it in
  `needs_source`.
- Every string you quote must be copied exactly from a source passage in your prompt.
- Write your labels with the Write tool, once, to the path your prompt names, as JSON only. Then stop.
```

- [ ] **Step 4: Run it and confirm that it passes.**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(stance-coding): stance-coder agent (Write only) + tool guard test" -- .claude/agents/stance-coder.md backend/scripts/lib/stanceCoderAgent.test.ts
```

---

### Task 9: Per-row agreement

**Files:**
- Create: `backend/scripts/lib/agreement.ts`, `backend/scripts/lib/agreement.test.ts`

**Interfaces:**
- Produces:
  - `interface CoderRowLabel { slot: number; valid: boolean; value: number | null; blank_reason: string | null; rests_on: string[]; needs_source: string[] }`
  - `type AgreementOutcome`
  - `agree(labels: CoderRowLabel[], expectedSlots?: number[]): AgreementOutcome`
  - `consensusSlot(labels: CoderRowLabel[], value: number): number` (the agreeing slot with the smallest `rests_on`)

- [ ] **Step 1: Write the failing test**

```ts
// backend/scripts/lib/agreement.test.ts
import { describe, it, expect } from 'vitest';
import { agree, consensusSlot, type CoderRowLabel } from './agreement.js';

const L = (slot: number, value: number | null, rests_on: string[] = ['a'], over: Partial<CoderRowLabel> = {}): CoderRowLabel =>
  ({ slot, valid: true, value, blank_reason: value === null ? 'no-evidence' : null, rests_on, needs_source: [], ...over });

describe('agree (spec §1.5, §5.5)', () => {
  it('unanimous chair with a shared source', () =>
    expect(agree([L(1, 4, ['a', 'b']), L(2, 4, ['a']), L(3, 4, ['a', 'c'])])).toEqual({ kind: 'unanimous-chair', value: 4, shared_sources: ['a'] }));
  it('same chair on disjoint sources is NOT unanimous', () =>
    expect(agree([L(1, 4, ['a']), L(2, 4, ['b']), L(3, 4, ['a'])])).toEqual({ kind: 'disjoint-sources', value: 4 }));
  it('unanimous blank needs the same reason', () => {
    expect(agree([L(1, null), L(2, null), L(3, null)])).toEqual({ kind: 'unanimous-blank', reason: 'no-evidence' });
    expect(agree([L(1, null), L(2, null, [], { blank_reason: 'direction-only' }), L(3, null)]).kind).toBe('split');
  });
  it('a split names every coder value', () =>
    expect(agree([L(1, 4), L(2, 5), L(3, 4)])).toEqual({ kind: 'split', values: [4, 5, 4] }));
  it('an invalid or absent coder makes the row coder-missing, even when the other two agree', () => {
    expect(agree([L(1, 4), L(2, 4), L(3, 4, ['a'], { valid: false })])).toEqual({ kind: 'coder-missing', missing: [3] });
    expect(agree([L(1, 4), L(2, 4)])).toEqual({ kind: 'coder-missing', missing: [3] });
  });
  it('any source request holds the row, before any agreement is read', () =>
    expect(agree([L(1, 4), L(2, 4, ['a'], { needs_source: ['roll call'] }), L(3, 4)])).toEqual({ kind: 'needs-source', requests: ['roll call'] }));
});

describe('consensusSlot', () => {
  it('picks the agreeing coder with the tightest basis', () =>
    expect(consensusSlot([L(1, 4, ['a', 'b']), L(2, 4, ['a']), L(3, 5, [])], 4)).toBe(2));
});
```

- [ ] **Step 2: Run it and confirm that it fails.**

- [ ] **Step 3: Implement**

```ts
// backend/scripts/lib/agreement.ts
/**
 * agreement — is a row unanimous? (spec §1.5, §5.5). Unanimous means all three coders valid, the
 * same chair (or the same BLANK reason), AND at least one snapshot all three rest on. Anything else
 * goes to a person. Order matters: a missing coder or a source request is decided before values
 * are compared, because neither is an agreement about the evidence the row will finally have.
 */
export interface CoderRowLabel {
  slot: number;
  valid: boolean;
  value: number | null;
  blank_reason: string | null;
  rests_on: string[];
  needs_source: string[];
}
export type AgreementOutcome =
  | { kind: 'unanimous-chair'; value: number; shared_sources: string[] }
  | { kind: 'unanimous-blank'; reason: string }
  | { kind: 'disjoint-sources'; value: number }
  | { kind: 'split'; values: (number | null)[] }
  | { kind: 'coder-missing'; missing: number[] }
  | { kind: 'needs-source'; requests: string[] };

export function agree(labels: CoderRowLabel[], expectedSlots: number[] = [1, 2, 3]): AgreementOutcome {
  const bySlot = new Map(labels.map((l) => [l.slot, l]));
  const missing = expectedSlots.filter((s) => !bySlot.get(s)?.valid);
  if (missing.length) return { kind: 'coder-missing', missing };
  const ls = expectedSlots.map((s) => bySlot.get(s)!);
  const requests = [...new Set(ls.flatMap((l) => l.needs_source))];
  if (requests.length) return { kind: 'needs-source', requests };
  const values = ls.map((l) => l.value);
  if (new Set(values).size > 1) return { kind: 'split', values };
  if (values[0] === null) {
    const reasons = new Set(ls.map((l) => l.blank_reason));
    return reasons.size === 1 ? { kind: 'unanimous-blank', reason: ls[0].blank_reason! } : { kind: 'split', values };
  }
  const shared = ls.slice(1).reduce((acc, l) => acc.filter((id) => l.rests_on.includes(id)), [...ls[0].rests_on]);
  return shared.length
    ? { kind: 'unanimous-chair', value: values[0], shared_sources: shared.sort() }
    : { kind: 'disjoint-sources', value: values[0] };
}

export function consensusSlot(labels: CoderRowLabel[], value: number): number {
  return labels
    .filter((l) => l.valid && l.value === value)
    .sort((a, b) => a.rests_on.length - b.rests_on.length || a.slot - b.slot)[0].slot;
}
```

- [ ] **Step 4: Run it and confirm that it passes.**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(stance-coding): per-row agreement (chair + shared source)" -- backend/scripts/lib/agreement.ts backend/scripts/lib/agreement.test.ts
```

---

### Task 10: CONFIRM checks

**Files:**
- Create: `backend/scripts/lib/confirm.ts`, `backend/scripts/lib/confirm.test.ts`

**Interfaces:**
- Consumes: `SeatContext` (Task 7), `Passage` and `verbatimIn` (Task 2).
- Produces:
  - `CAMPAIGN_LOOKBACK_DAYS = 548`
  - `type ConfirmFinding = 'identity-not-in-snapshot' | 'dates-imprecise' | 'record-before-term' | 'statement-out-of-cycle' | 'undated-evidence' | 'provision-missing' | 'revision-drift'`
  - `earliestStatementDate(seat: SeatContext): string | null`
  - `confirmRow(i: { seat: SeatContext; restsOnPassages: Passage[]; snapshotText: ReadonlyMap<string, string>; rowServedRevisionId: string; bundleServedRevisionId: string }): ConfirmFinding[]`

- [ ] **Step 1: Write the failing test**

```ts
// backend/scripts/lib/confirm.test.ts
import { describe, it, expect } from 'vitest';
import { confirmRow, earliestStatementDate } from './confirm.js';
import type { SeatContext } from './coderPrompt.js';
import type { Passage } from './coderLabel.js';

const seat: SeatContext = {
  politician_id: 'p', full_name: 'J. Stuart Adams', level: 'state', mode: 'seated', office_id: 'o', office_title: 'State Senator',
  jurisdiction_names: ['Utah'], term_start: '2021-01-01', start_precision: 'day', term_end: null, election_date: null,
};
const text = new Map([['s1', 'Utah Senate President J. Stuart Adams led the override; the bill requires students to compete on teams matching their sex at birth.']]);
const P = (over: Partial<Passage> = {}): Passage => ({
  snapshot_id: 's1', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record', v4_shape: 'chair-shaped',
  v5_time: 'in-term', date: '2022-03-25', instrument: 'H.B. 11', provision_quote: 'requires students to compete on teams matching their sex at birth', ...over,
});
const run = (over: Partial<Parameters<typeof confirmRow>[0]> = {}) =>
  confirmRow({ seat, restsOnPassages: [P()], snapshotText: text, rowServedRevisionId: 'r1', bundleServedRevisionId: 'r1', ...over });

describe('earliestStatementDate (ruling Q4 proxy)', () => {
  it('seated: current term start minus 548 days', () => expect(earliestStatementDate(seat)).toBe('2019-07-03'));
  it('candidate: election date minus 548 days', () =>
    expect(earliestStatementDate({ ...seat, mode: 'candidate', term_start: null, election_date: '2026-11-03' })).toBe('2025-05-04'));
  it('unknown start → null', () => expect(earliestStatementDate({ ...seat, term_start: null })).toBeNull());
});

describe('confirmRow (spec §1.6)', () => {
  it('passes a clean in-term record with its provision on the page', () => expect(run()).toEqual([]));
  it('flags a snapshot that names neither the jurisdiction nor the office (namesake guard)', () =>
    expect(run({ snapshotText: new Map([['s1', 'Adams led the override; the bill requires students to compete on teams matching their sex at birth.']]) }))
      .toContain('identity-not-in-snapshot'));
  it('flags a record dated before the current term', () => expect(run({ restsOnPassages: [P({ date: '2019-02-01' })] })).toContain('record-before-term'));
  it('flags imprecise term dates rather than guessing (§4.10)', () =>
    expect(run({ seat: { ...seat, start_precision: 'year' }, restsOnPassages: [P({ date: '2021-03-01' })] })).toContain('dates-imprecise'));
  it('flags a statement older than the cycle window', () =>
    expect(run({ restsOnPassages: [P({ v3_class: 'statement-answer', date: '2018-05-01', provision_quote: null })] })).toContain('statement-out-of-cycle'));
  it('flags undated evidence', () => expect(run({ restsOnPassages: [P({ date: null })] })).toContain('undated-evidence'));
  it('flags a vote without its provision text on the page (vote ladder)', () =>
    expect(run({ restsOnPassages: [P({ provision_quote: null })] })).toContain('provision-missing'));
  it('flags a served-revision mismatch', () => expect(run({ rowServedRevisionId: 'r0' })).toContain('revision-drift'));
});
```

- [ ] **Step 2: Run it and confirm that it fails.**

- [ ] **Step 3: Implement**

```ts
// backend/scripts/lib/confirm.ts
/**
 * confirm — phase-1 CONFIRM (spec §1.6): code-only checks after the coders agree. Any finding
 * sends the row to a person. Identity guards against namesakes; dates guard pre-seating (§4.10)
 * and the statement cycle (ruling Q4); the vote ladder requires the operative provision on the page.
 * 🟡 CAMPAIGN_LOOKBACK_DAYS is an implementation PROXY for "the current term, the current campaign,
 * or the campaign that seated them" — the operator may change it.
 */
import { normalizeText } from '../../src/lib/researchVerifier.js';
import { verbatimIn, type Passage } from './coderLabel.js';
import type { SeatContext } from './coderPrompt.js';

export const CAMPAIGN_LOOKBACK_DAYS = 548;
export type ConfirmFinding =
  | 'identity-not-in-snapshot' | 'dates-imprecise' | 'record-before-term' | 'statement-out-of-cycle'
  | 'undated-evidence' | 'provision-missing' | 'revision-drift';

const minusDays = (iso: string, days: number): string => {
  const d = new Date(`${iso.slice(0, 10)}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - days);
  return d.toISOString().slice(0, 10);
};

export function earliestStatementDate(seat: SeatContext): string | null {
  const anchor = seat.mode === 'seated' ? seat.term_start : seat.election_date;
  return anchor ? minusDays(anchor, CAMPAIGN_LOOKBACK_DAYS) : null;
}

/** A coder date may be YYYY, YYYY-MM or YYYY-MM-DD; compare on its earliest possible day. */
const floorDate = (d: string): string => (d.length === 4 ? `${d}-01-01` : d.length === 7 ? `${d}-01` : d.slice(0, 10));

export function confirmRow(i: {
  seat: SeatContext;
  restsOnPassages: Passage[];
  snapshotText: ReadonlyMap<string, string>;
  rowServedRevisionId: string;
  bundleServedRevisionId: string;
}): ConfirmFinding[] {
  const out = new Set<ConfirmFinding>();
  const names = [...i.seat.jurisdiction_names, i.seat.office_title].map((n) => normalizeText(n)).filter(Boolean);
  const identityOk = i.restsOnPassages.some((p) => {
    const t = normalizeText(i.snapshotText.get(p.snapshot_id) ?? '');
    return names.some((n) => t.includes(n));
  });
  if (!identityOk) out.add('identity-not-in-snapshot');
  const cycleStart = earliestStatementDate(i.seat);
  for (const p of i.restsOnPassages) {
    if (!p.date) { out.add('undated-evidence'); continue; }
    const d = floorDate(p.date);
    if (p.v3_class === 'record') {
      if (i.seat.mode === 'seated') {
        if (!i.seat.term_start || i.seat.start_precision !== 'day') out.add('dates-imprecise');
        else if (d < i.seat.term_start) out.add('record-before-term');
      }
      if (!p.provision_quote || !verbatimIn(i.snapshotText.get(p.snapshot_id) ?? '', p.provision_quote)) out.add('provision-missing');
    } else {
      if (!cycleStart) out.add('dates-imprecise');
      else if (d < cycleStart) out.add('statement-out-of-cycle');
    }
  }
  if (i.rowServedRevisionId !== i.bundleServedRevisionId) out.add('revision-drift');
  return [...out];
}
```

⚠ `record-before-term` compares with the **current** term only. A multi-term incumbent's vote from an
earlier term of the same office therefore goes to review. That is conservative on purpose (fail
closed), and P3 can widen it to the continuous tenure.

- [ ] **Step 4: Run it and confirm that it passes.**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(stance-coding): CONFIRM — identity, dates, statement cycle, provision, revision" -- backend/scripts/lib/confirm.ts backend/scripts/lib/confirm.test.ts
```

---

### Task 11: The batch coding report (shadow)

**Files:**
- Create: `backend/scripts/lib/codingReport.ts`, `backend/scripts/lib/codingReport.test.ts`,
  `backend/scripts/code-stance-batch.ts`

**Interfaces:**
- Consumes: Tasks 1, 2, 7, 9 and 10.
- Produces:
  - `EVIDENCE_CLASS_ORDER`
  - `weakestClass(passages: Passage[]): 'record' | 'statement-answer' | 'statement-other'`
  - `interface RowReport { key; topic_key; outcome: AgreementOutcome; confirm: ConfirmFinding[]; stratum: { level: string | null; evidence_class: string | null }; shadow: 'would-publish-if-certified' | 'would-review'; shadow_reasons: string[] }`
  - `buildCodingReport(i: { context: { batch_id: string; seat: SeatContext; topics: PromptTopic[] }; files: Map<number, unknown>; snapshotText: ReadonlyMap<string, string> }): { rows: RowReport[]; m1: { alpha: number | null; units: number }; needsSource: { key: string; requests: string[] }[]; validity: { slot: number; fileErrors: string[]; rowErrors: number }[] }`
  - the files `<batch>/coding-report.json` and `<batch>/needs-source.json`.

- [ ] **Step 1: Write the failing test**

```ts
// backend/scripts/lib/codingReport.test.ts
import { describe, it, expect } from 'vitest';
import { buildCodingReport, weakestClass } from './codingReport.js';
import { CODEBOOK_VERSION, type CoderRow, type Passage } from './coderLabel.js';
import type { SeatContext, PromptTopic } from './coderPrompt.js';

const seat: SeatContext = { politician_id: 'p1', full_name: 'J. Stuart Adams', level: 'state', mode: 'seated', office_id: 'o1', office_title: 'State Senator',
  jurisdiction_names: ['Utah'], term_start: '2021-01-01', start_precision: 'day', term_end: null, election_date: null };
const topics: PromptTopic[] = ['t1', 't2'].map((id) => ({ topic_id: id, topic_key: `k-${id}`, served_revision_id: 'r1', question_text: 'Q', stances: [], annexMd: null }));
const snapshotText = new Map([['s1', 'Utah Senate: the bill requires students to compete on teams matching their sex at birth.']]);
const P: Passage = { snapshot_id: 's1', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record', v4_shape: 'chair-shaped',
  v5_time: 'in-term', date: '2022-03-25', instrument: 'H.B. 11', provision_quote: 'requires students to compete on teams matching their sex at birth' };
const row = (topic_id: string, v: number | null): CoderRow => ({ politician_id: 'p1', office_id: 'o1', topic_id, served_revision_id: 'r1',
  passages: [P], v6_value: v, v6_blank_reason: v === null ? 'no-evidence' : null, rests_on: v === null ? [] : ['s1'], reasoning: 'r', needs_source: [], quotes: [] });
const file = (slot: number, rows: CoderRow[]) => ({ codebook_version: CODEBOOK_VERSION, coder_slot: slot, rows });
const context = { batch_id: 'b', seat, topics };

describe('weakestClass', () => {
  it('takes the weakest class present (spec §3.2)', () => {
    expect(weakestClass([P, { ...P, v3_class: 'statement-answer' }])).toBe('statement-answer');
    expect(weakestClass([P])).toBe('record');
  });
});

describe('buildCodingReport', () => {
  it('reports a unanimous, confirmed row as would-publish-if-certified, and a split as would-review', () => {
    const files = new Map<number, unknown>([
      [1, file(1, [row('t1', 4), row('t2', 2)])],
      [2, file(2, [row('t1', 4), row('t2', 3)])],
      [3, file(3, [row('t1', 4), row('t2', 2)])],
    ]);
    const r = buildCodingReport({ context, files, snapshotText });
    const t1 = r.rows.find((x) => x.topic_key === 'k-t1')!;
    const t2 = r.rows.find((x) => x.topic_key === 'k-t2')!;
    expect(t1.shadow).toBe('would-publish-if-certified');
    expect(t1.stratum).toEqual({ level: 'state', evidence_class: 'record' });
    expect(t2.shadow).toBe('would-review');
    expect(t2.shadow_reasons).toContain('coder-split');
    expect(r.m1.units).toBe(2);
    expect(r.m1.alpha).toBeLessThan(1);
  });
  it('treats a missing coder file as coder-missing for every row', () => {
    const files = new Map<number, unknown>([[1, file(1, [row('t1', 4), row('t2', 4)])], [2, file(2, [row('t1', 4), row('t2', 4)])]]);
    const r = buildCodingReport({ context, files, snapshotText });
    expect(r.rows.every((x) => x.shadow_reasons.includes('coder-missing'))).toBe(true);
  });
  it('never marks a statement-other row publishable (ruling Q2)', () => {
    const so = { ...row('t1', 4), passages: [{ ...P, v3_class: 'statement-other' as const, provision_quote: null }] };
    const files = new Map<number, unknown>([1, 2, 3].map((s) => [s, file(s, [so, row('t2', null)])]));
    const t1 = buildCodingReport({ context, files, snapshotText }).rows.find((x) => x.topic_key === 'k-t1')!;
    expect(t1.shadow).toBe('would-review');
    expect(t1.shadow_reasons).toContain('statement-other');
  });
  it('collects needs-source requests', () => {
    const ns = { ...row('t1', null), needs_source: ['Clerk roll call, H.R. 28'] };
    const files = new Map<number, unknown>([1, 2, 3].map((s) => [s, file(s, [ns, row('t2', null)])]));
    expect(buildCodingReport({ context, files, snapshotText }).needsSource).toEqual([{ key: 'p1|o1|t1', requests: ['Clerk roll call, H.R. 28'] }]);
  });
});
```

- [ ] **Step 2: Run it and confirm that it fails.**

- [ ] **Step 3: Implement the lib**

```ts
// backend/scripts/lib/codingReport.ts
/**
 * codingReport — the SHADOW verdict for one politician's batch (spec §7 P1). It computes what the
 * P3 pipeline would do, and changes nothing: decidePublish is not consulted and not altered.
 * `would-publish-if-certified` still needs a certified stratum, which does not exist in P1.
 */
import { alphaNominal, chairCategory, type Unit } from './reliability.js';
import { validateCoderLabelFile, rowKey, type Passage, type CoderRow } from './coderLabel.js';
import { agree, consensusSlot, type AgreementOutcome, type CoderRowLabel } from './agreement.js';
import { confirmRow, type ConfirmFinding } from './confirm.js';
import type { SeatContext, PromptTopic } from './coderPrompt.js';

export const EVIDENCE_CLASS_ORDER = ['statement-other', 'statement-answer', 'record'] as const; // weakest first
export function weakestClass(passages: Passage[]): 'record' | 'statement-answer' | 'statement-other' {
  for (const c of EVIDENCE_CLASS_ORDER) if (passages.some((p) => p.v3_class === c)) return c;
  return 'statement-other';
}

export interface RowReport {
  key: string;
  topic_key: string;
  outcome: AgreementOutcome;
  confirm: ConfirmFinding[];
  stratum: { level: string | null; evidence_class: string | null };
  shadow: 'would-publish-if-certified' | 'would-review';
  shadow_reasons: string[];
}

export function buildCodingReport(i: {
  context: { batch_id: string; seat: SeatContext; topics: PromptTopic[] };
  files: Map<number, unknown>;
  snapshotText: ReadonlyMap<string, string>;
}) {
  const { seat, topics } = i.context;
  const validity: { slot: number; fileErrors: string[]; rowErrors: number }[] = [];
  const bySlot = new Map<number, Map<string, { row: CoderRow | null; valid: boolean }>>();
  for (const slot of [1, 2, 3]) {
    const raw = i.files.get(slot);
    const rows = new Map<string, { row: CoderRow | null; valid: boolean }>();
    if (raw === undefined) { validity.push({ slot, fileErrors: ['file missing'], rowErrors: 0 }); bySlot.set(slot, rows); continue; }
    const v = validateCoderLabelFile(raw, { snapshotText: i.snapshotText, expectedSlot: slot });
    validity.push({ slot, fileErrors: v.fileErrors, rowErrors: v.rows.filter((r) => r.errors.length).length });
    for (const r of v.rows) rows.set(r.key, { row: r.row, valid: v.fileErrors.length === 0 && r.errors.length === 0 });
    bySlot.set(slot, rows);
  }
  const units: Unit[] = [];
  const needsSource: { key: string; requests: string[] }[] = [];
  const rows: RowReport[] = topics.map((t) => {
    const key = rowKey({ politician_id: seat.politician_id, office_id: seat.office_id, topic_id: t.topic_id });
    const labels: CoderRowLabel[] = [];
    const rowsBySlot = new Map<number, CoderRow>();
    for (const slot of [1, 2, 3]) {
      const got = bySlot.get(slot)!.get(key);
      if (!got) continue;
      if (got.row) rowsBySlot.set(slot, got.row);
      labels.push({ slot, valid: got.valid, value: got.row?.v6_value ?? null, blank_reason: got.row?.v6_blank_reason ?? null,
        rests_on: got.row?.rests_on ?? [], needs_source: got.row?.needs_source ?? [] });
    }
    units.push([1, 2, 3].map((s) => { const l = labels.find((x) => x.slot === s); return l?.valid ? chairCategory(l.value) : null; }));
    const outcome = agree(labels);
    const reasons: string[] = [];
    let confirm: ConfirmFinding[] = [];
    let evidenceClass: string | null = null;
    if (outcome.kind === 'needs-source') { reasons.push('needs-source'); needsSource.push({ key, requests: outcome.requests }); }
    else if (outcome.kind === 'coder-missing') reasons.push('coder-missing');
    else if (outcome.kind === 'split' || outcome.kind === 'disjoint-sources') reasons.push('coder-split');
    else if (outcome.kind === 'unanimous-blank') reasons.push('unanimous-blank-no-write');
    else {
      const cRow = rowsBySlot.get(consensusSlot(labels, outcome.value))!;
      const restsOn = cRow.passages.filter((p) => outcome.shared_sources.includes(p.snapshot_id));
      evidenceClass = weakestClass(restsOn);
      confirm = confirmRow({ seat, restsOnPassages: restsOn, snapshotText: i.snapshotText, rowServedRevisionId: cRow.served_revision_id, bundleServedRevisionId: t.served_revision_id });
      if (confirm.length) reasons.push('confirm-failed');
      if (evidenceClass === 'statement-other') reasons.push('statement-other');
    }
    const publishable = outcome.kind === 'unanimous-chair' && reasons.length === 0;
    return { key, topic_key: t.topic_key, outcome, confirm, stratum: { level: seat.level, evidence_class: evidenceClass },
      shadow: publishable ? 'would-publish-if-certified' : 'would-review', shadow_reasons: reasons };
  });
  const a = alphaNominal(units);
  return { rows, m1: { alpha: a.alpha, units: a.units }, needsSource, validity };
}
```

- [ ] **Step 4: Run it and confirm that it passes.**

- [ ] **Step 5: Write the script**

```ts
// backend/scripts/code-stance-batch.ts
/**
 * code-stance-batch.ts — SHADOW coding report for one politician's batch (spec §7 P1).
 * Reads coding-context.json, snapshots.json and labels/coder-{1,2,3}.json; writes coding-report.json
 * and needs-source.json. Changes NOTHING that is published. --apply stores the labels in
 * inform.stance_coder_labels (needs CA_<slot> applied and the operator's OK).
 *   npx tsx scripts/code-stance-batch.ts --dir <batch> --season-id <uuid> --models "opus,sonnet,sonnet" [--apply]
 */
import 'dotenv/config';
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { createHash } from 'node:crypto';
import { buildCodingReport } from './lib/codingReport.js';
import { validateCoderLabelFile, CODEBOOK_VERSION } from './lib/coderLabel.js';
import type { SnapshotRecord } from './lib/snapshotSources.js';

const arg = (n: string) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : undefined; };
const dir = arg('--dir'); const seasonId = arg('--season-id'); const models = (arg('--models') ?? '').split(',');
const APPLY = process.argv.includes('--apply');
if (!dir || !seasonId || models.length !== 3) { console.error('usage: --dir <batch> --season-id <uuid> --models "m1,m2,m3" [--apply]'); process.exit(2); }

const context = JSON.parse(readFileSync(join(dir, 'coding-context.json'), 'utf8'));
const snapshots = JSON.parse(readFileSync(join(dir, 'snapshots.json'), 'utf8')) as SnapshotRecord[];
const snapshotText = new Map(snapshots.filter((s) => s.ok && s.snapshot_text).map((s) => [s.snapshot_id, s.snapshot_text!]));
const files = new Map<number, unknown>();
const rawText = new Map<number, string>();
for (const slot of [1, 2, 3]) {
  const p = join(dir, 'labels', `coder-${slot}.json`);
  if (!existsSync(p)) continue;
  const t = readFileSync(p, 'utf8');
  rawText.set(slot, t);
  try { files.set(slot, JSON.parse(t)); } catch { files.set(slot, t); } // prose → invalid, not a crash
}
const report = buildCodingReport({ context, files, snapshotText });
writeFileSync(join(dir, 'coding-report.json'), JSON.stringify({ codebook_version: CODEBOOK_VERSION, models, ...report }, null, 2));
writeFileSync(join(dir, 'needs-source.json'), JSON.stringify(report.needsSource, null, 2));

console.log(`M1 (batch) alpha = ${report.m1.alpha === null ? 'undefined' : report.m1.alpha.toFixed(3)} over ${report.m1.units} rows`);
for (const v of report.validity) console.log(`coder ${v.slot}: ${v.fileErrors.length ? v.fileErrors.join('; ') : 'file ok'}, ${v.rowErrors} invalid row(s)`);
for (const r of report.rows) console.log(`${r.shadow.padEnd(27)} ${r.topic_key.padEnd(28)} ${r.outcome.kind}${r.shadow_reasons.length ? `  [${r.shadow_reasons.join(', ')}]` : ''}`);
if (report.needsSource.length) console.log(`\n${report.needsSource.length} row(s) request sources → ${join(dir, 'needs-source.json')} (collector fetches, then re-snapshot and re-code all three)`);

if (APPLY) {
  const { pool } = await import('../src/lib/db.js');
  for (const slot of [1, 2, 3]) {
    const raw = files.get(slot);
    if (raw === undefined) continue;
    const v = validateCoderLabelFile(raw, { snapshotText, expectedSlot: slot });
    const sha = createHash('sha256').update(rawText.get(slot)!).digest('hex');
    // validateCoderLabelFile returns one entry per raw row, in order — so index aligns them, and an
    // INVALID row is still stored (valid=false, with its errors): an invalid label is data (spec §5.5).
    const rawRows = ((raw as { rows?: unknown[] }).rows ?? []) as Record<string, any>[];
    for (let idx = 0; idx < v.rows.length; idx++) {
      const r = v.rows[idx];
      const row = rawRows[idx];
      if (r.key === '?' || !row) continue; // no identifiable (politician, office, topic) — nothing to key it on
      const valid = v.fileErrors.length === 0 && r.errors.length === 0;
      await pool.query(
        `INSERT INTO inform.stance_coder_labels (batch_id, politician_id, office_id, topic_id, season_id, served_revision_id, coder_slot, model,
            codebook_version, value, blank_reason, rests_on, source_codes, quote_codes, needs_source, valid, validation_errors, label_sha256, raw_output)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19)
         ON CONFLICT (batch_id, politician_id, office_id, topic_id, coder_slot) DO NOTHING`,
        [context.batch_id, row.politician_id, row.office_id, row.topic_id, seasonId, row.served_revision_id, slot, models[slot - 1], CODEBOOK_VERSION,
         valid ? row.v6_value : null, valid ? row.v6_blank_reason : null, valid ? row.rests_on : [], JSON.stringify(row.passages ?? []),
         JSON.stringify(row.quotes ?? []), JSON.stringify(row.needs_source ?? []), valid, [...v.fileErrors, ...r.errors], sha, row]);
    }
  }
  await pool.end();
  console.log('stored coder labels in inform.stance_coder_labels (shadow; nothing published)');
}
```

⚠ Run `snapshot-sources.ts --apply` for the same batch before this `--apply`, because `rests_on`
holds `source_snapshots.id` values. There is no foreign key on the array, so a skipped snapshot
insert would leave labels that point at nothing. If `snapshot-sources.ts` is re-run on the same
directory, the new ids replace the old ones in `snapshots.json`, so the coders must code again as
well.

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(stance-coding): shadow coding report per batch; --apply stores coder labels" -- backend/scripts/lib/codingReport.ts backend/scripts/lib/codingReport.test.ts backend/scripts/code-stance-batch.ts
```

---

### Task 12: Cross-batch reliability report and npm scripts

**Files:**
- Create: `backend/scripts/reliability-report.ts`
- Modify: `backend/package.json` (the `scripts` block)

**Interfaces:**
- Consumes: `alphaNominal`, `chairCategory` (Task 1); the rows of `inform.stance_coder_labels`.
- Produces:
  - `npm run coding:snapshot`, `coding:inputs`, `coding:report`, `reliability:report`;
  - the stdout table `level × evidence_class → n rows, M1`.
  - M2–M4 print as `n/a (no gold until P2)`.

- [ ] **Step 1: Write the script**

```ts
// backend/scripts/reliability-report.ts
/**
 * reliability-report.ts — M1 (coder-vs-coder α, nominal) per stratum across every batch stored in
 * inform.stance_coder_labels (spec §3.1). Read-only. M2–M4 need blind gold, which starts in P2.
 * A row's stratum = the weakest evidence class any valid coder rested its chair on (spec §3.2).
 *   npx tsx scripts/reliability-report.ts [--codebook 0.2]
 */
import 'dotenv/config';
import { pool } from '../src/lib/db.js';
import { alphaNominal, chairCategory, type Unit } from './lib/reliability.js';
import { CODEBOOK_VERSION } from './lib/coderLabel.js';

const i = process.argv.indexOf('--codebook');
const version = i > 0 ? process.argv[i + 1] : CODEBOOK_VERSION;
const { rows } = await pool.query(
  `SELECT l.batch_id, l.politician_id, l.office_id, l.topic_id, l.coder_slot, l.valid, l.value, l.rests_on, l.source_codes,
          (SELECT string_agg(DISTINCT r.level, ',') FROM inform.compass_topic_roles r WHERE r.topic_id = l.topic_id) AS levels
     FROM inform.stance_coder_labels l
    WHERE l.codebook_version = $1 AND NOT l.is_diagnostic AND l.coder_slot BETWEEN 1 AND 3`, [version]);
await pool.end();

const order = ['statement-other', 'statement-answer', 'record']; // weakest first
const units = new Map<string, { level: string; classes: Set<string>; values: (string | null)[] }>();
for (const r of rows) {
  const key = `${r.batch_id}|${r.politician_id}|${r.office_id}|${r.topic_id}`;
  const u = units.get(key) ?? { level: String(r.levels ?? 'unknown'), classes: new Set<string>(), values: [null, null, null] };
  u.values[r.coder_slot - 1] = r.valid ? chairCategory(r.value) : null;
  if (r.valid) {
    for (const p of r.source_codes as { snapshot_id: string; v3_class: string }[]) {
      if ((r.rests_on as string[]).includes(p.snapshot_id)) u.classes.add(p.v3_class);
    }
  }
  units.set(key, u);
}
// A unit's stratum = the weakest class ANY coder rested on; 'blank' when no coder seated a chair.
const stratumOf = (u: { level: string; classes: Set<string> }) => `${u.level} × ${order.find((c) => u.classes.has(c)) ?? 'blank'}`;
const byStratum = new Map<string, Unit[]>();
for (const u of units.values()) byStratum.set(stratumOf(u), [...(byStratum.get(stratumOf(u)) ?? []), u.values]);
console.log(`codebook ${version} — ${units.size} coded rows\n`);
console.log('stratum'.padEnd(40), 'rows'.padStart(6), 'M1 α'.padStart(8), '  M2–M4');
for (const [s, us] of [...byStratum].sort()) {
  const a = alphaNominal(us);
  console.log(s.padEnd(40), String(us.length).padStart(6), (a.alpha === null ? 'undef' : a.alpha.toFixed(3)).padStart(8), '  n/a (no gold until P2)');
}
const all = alphaNominal([...units.values()].map((u) => u.values));
console.log(`\nall strata: M1 α = ${all.alpha === null ? 'undef' : all.alpha.toFixed(3)} (target ≥ 0.80, spec §3.3)`);
```

⚠ `compass_topic_roles.level` gives the topic's levels, not the person's. For one person the right
level is the bundle's `politician.level`. P1 accepts the topic-roles proxy for this *report only*.
The P2 plan should store `level` on `stance_coder_labels`. Record this in the P1 findings (Task 13).

- [ ] **Step 2: Add the npm scripts** in `backend/package.json`, next to `"check:stance-sources"`:

```json
    "coding:snapshot": "tsx scripts/snapshot-sources.ts",
    "coding:inputs": "tsx scripts/build-coder-inputs.ts",
    "coding:report": "tsx scripts/code-stance-batch.ts",
    "reliability:report": "tsx scripts/reliability-report.ts",
```

- [ ] **Step 3: Run the whole new unit suite**

Run:

```bash
cd backend && npx vitest run scripts/lib/reliability.test.ts scripts/lib/coderLabel.test.ts scripts/lib/codebookAnnex.test.ts scripts/lib/sourcesManifest.test.ts scripts/lib/snapshotSources.test.ts scripts/lib/coderPrompt.test.ts scripts/lib/stanceCoderAgent.test.ts scripts/lib/agreement.test.ts scripts/lib/confirm.test.ts scripts/lib/codingReport.test.ts scripts/lib/stancePublishPolicy.test.ts
```

Expected: all PASS. `stancePublishPolicy.test.ts` must pass **unchanged**, which proves that P1 did
not move a publish decision.

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(stance-coding): cross-batch M1 reliability report + npm scripts" -- backend/scripts/reliability-report.ts backend/package.json
```

---

### Task 13: The shadow procedure in the skill, and the first shadow run

**Files:**
- Modify: `.claude/skills/research-stances/SKILL.md`. Add a section after the verify step, headed
  `## SHADOW CODING (P1, spec 2026-09-25) — measures, publishes nothing`.
- Modify: `docs/superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md`:
  - §7, P1 row: "the review page shows the coder split" moves to P2;
  - §4.1: the column names are `page_sha256` / `snapshot_text`.
- Create: `docs/superpowers/specs/2026-09-25-codebook-p1-findings.md` (after the run).

- [ ] **Step 1: Add the skill section** (the text below goes in verbatim)

````markdown
## SHADOW CODING (P1, spec 2026-09-25) — measures, publishes nothing

Run AFTER the normal pipeline for the same politician. It does not change what the verify step
queues. Its only outputs are `coding-report.json` and, with the operator's OK, rows in
`inform.stance_coder_labels`.

1. **Collect.** While researching, also write `<batch>/sources.json` (the
   `backend/scripts/lib/sourcesManifest.ts` contract): every source you read, with its `source_kind`,
   instruments and verbatim anchor passages. **No `value`, chair or reasoning keys** — the parser
   refuses them. For a public-record or own-site page that automation cannot fetch, save it from a
   real browser into `<batch>/human-saved/` and set `human_saved_path`. **Never do this for news**
   (spec §5.4).
2. `npm run coding:snapshot --prefix backend -- --dir <batch>` → `snapshots.json`. Read the NOT CODABLE
   lines.
3. `npm run coding:inputs --prefix backend -- --dir <batch> --politician <uuid> [--office <uuid>]`
   → `coder-inputs/coder-{1,2,3}.md`.
4. **Dispatch three coders in ONE message** (parallel Agent calls), `subagent_type: "stance-coder"`:
   - slot 1 with `model: "opus"`, slots 2 and 3 with `model: "sonnet"`;
   - each call's `prompt` = the **exact** contents of `coder-inputs/coder-N.md`. Do not edit,
     summarise or add to it; the file hash printed in step 3 is the record of what was sent.
   - Do not read the coders' files and "fix" them. An invalid label is data (`coder-missing`).
5. `npm run coding:report --prefix backend -- --dir <batch> --season-id <open season uuid> --models "opus,sonnet,sonnet"`.
6. If `needs-source.json` is non-empty: fetch those sources (you are the only role with tools), add
   them to `sources.json`, and repeat from step 2 — **all three coders again**. After two rounds with
   no new snapshot, stop (spec §1.3).
7. `--apply` on steps 2 and 5 **only with the operator's explicit OK**, and only after CA_<slot> is
   applied.
````

- [ ] **Step 2: Edit the spec** as listed under **Files**, and commit both docs:

```bash
git commit -m "docs(research-stances): P1 shadow coding procedure; spec notes P1 review display moves to P2" -- .claude/skills/research-stances/SKILL.md docs/superpowers/specs/2026-09-25-stance-quote-codebook-reliability-design.md
```

- [ ] **Step 3: 🛑 First shadow run — operator-driven.**
  - Ask the operator to choose one politician with a recent `/research-stances` batch (suggestion:
    a state legislator with record evidence, so the federal/state record stratum is exercised).
  - Run steps 1–5 of the new section without `--apply`.
  - Positive control (spec §6.1): before trusting a `coder-missing` result, hand-edit a **copy** of one
    label file into a known-valid form and confirm that the report accepts it.

- [ ] **Step 4: Write the findings** in `docs/superpowers/specs/2026-09-25-codebook-p1-findings.md`:
  - M1 for the batch;
  - the invalid-label rate per model;
  - which codebook variables split most (from `coding-report.json`);
  - `needs_source` rounds;
  - the Task 12 level-proxy note;
  - any codebook wording the coders misread. Each misreading becomes a **MINOR** codebook edit, or a
    **MAJOR** one if a rule changed.

Commit:

```bash
git commit -m "docs(codebook): P1 first shadow run findings" -- docs/superpowers/specs/2026-09-25-codebook-p1-findings.md
```

**P1 exit criterion (spec §7):** M1 ≥ 0.80 across all strata over at least 30 coded rows from at
least 5 politicians. Below that, the codebook needs work before P2 gold would mean anything.
