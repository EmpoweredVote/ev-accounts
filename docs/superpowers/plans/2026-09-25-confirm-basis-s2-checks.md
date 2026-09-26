# CONFIRM record basis (D1) + Season 2 checks — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make CONFIRM judge a vote/sponsorship record as one basis across its pages (defect D1), and add
Cantrell's Season 2 checks: a vote needs a vote page, near-unanimous votes, surname collisions, one
instrument per basis, Season 1 citations as collector leads, and a fresh/stale seed flag.

**Architecture:**
- **Coders** copy facts verbatim into new label fields (`actor_quote`, `tally_quote`, `record_kind`),
  under codebook **0.3**.
- **A new pure lib, `recordBasis.ts`**, checks a record group: it parses the tally, finds the actor,
  detects collisions and compares instruments.
- **`confirm.ts`** routes record passages through it and keeps the per-passage checks for statements.
- **A read-only script** writes `s1-leads.json` for the collector. `codingReport` adds a seed flag
  from it.

**Tech Stack:** TypeScript ESM (`.js` suffixes), vitest, `tsx`, `pg` via `backend/src/lib/db.ts`.

**Spec:** `docs/superpowers/specs/2026-09-25-confirm-basis-and-s2-checks-design.md`.

## Global Constraints

- **P1 stays SHADOW.** Do not import or change `backend/scripts/lib/stancePublishPolicy.ts`.
  `stancePublishPolicy.test.ts` must pass unchanged.
- **No DB writes.** The scripts are read-only. No `--apply`.
- **Codebook version.** `CODEBOOK_VERSION` in `coderLabel.ts` = `'0.3'` = the codebook's
  `**Version:**` line (a test pins them).
- **The three new Passage fields are OPTIONAL in the TypeScript type** (so existing fixtures compile),
  but the **validator requires** `record_kind` and `actor_quote` on every `v3_class = 'record'`
  passage, and `tally_quote` when `record_kind = 'vote'`.
- **Near-unanimous** means `noes / (ayes + noes) < 0.10`.
- **Fail closed.** A tally that cannot be parsed gives `tally-unreadable`, never a pass.
- **Commits:** explicit pathspec only, and end every message with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Tests:** run from `backend/` with `npx vitest run <paths>`.

---

## File structure

| Path | Responsibility | Task |
|---|---|---|
| `backend/scripts/lib/coderLabel.ts` (+test) | 0.3 fields, types, validator rules | 1 |
| `docs/codebook/stance-and-quote-codebook.md`, `docs/codebook/annex/school-vouchers.md` | 0.3 text, Synonyms line | 1 |
| `backend/scripts/lib/recordBasis.ts` (+test) | tally parse, actor/collision, one record group's findings | 2 |
| `backend/scripts/lib/confirm.ts` (+test), `backend/scripts/lib/codingReport.test.ts` | route record groups through recordBasis | 3 |
| `backend/scripts/lib/s1Leads.ts` (+test), `backend/scripts/build-s1-leads.ts`, `backend/scripts/lib/codingReport.ts`, `backend/scripts/code-stance-batch.ts` | Season 1 leads + fresh/stale seed flag | 4 |
| `.claude/skills/research-stances/SKILL.md` | shadow procedure: leads, synonyms, `claude-ev -p` dispatch | 5 |
| `backend/data/stance-research/2026-09-25-shadow-{yoder,durazo}/`, `docs/superpowers/specs/2026-09-25-codebook-p1-findings.md` | re-code under 0.3, compare | 6 |

---

### Task 1: Codebook 0.3 — new record fields and their validation

**Files:**
- Modify: `backend/scripts/lib/coderLabel.ts`, `backend/scripts/lib/coderLabel.test.ts`
- Modify: `docs/codebook/stance-and-quote-codebook.md`, `docs/codebook/annex/school-vouchers.md`

**Interfaces:**
- Produces:
  - `RECORD_KIND = ['vote','sponsor','author','other-act'] as const`
  - `Passage` gains the optional fields `record_kind?: typeof RECORD_KIND[number] | null`,
    `actor_quote?: string | null`, `tally_quote?: string | null`
  - `CODEBOOK_VERSION = '0.3'`

- [ ] **Step 1: Write the failing tests.** Append to `coderLabel.test.ts`, inside the existing
  `describe('validateCoderLabelFile', …)` block or as a new block. It reuses the file's
  `SNAP`, `snapshotText`, `passage`, `row`, `file`, `ctx` helpers.
  - First update the file's `passage()` default: add `record_kind: 'vote'`,
    `actor_quote: 'The Senate voted 21-8 to override the veto of H.B. 11'` and
    `tally_quote: 'voted 21-8'`. All three are verbatim in the fixture text
    `'The Senate voted 21-8 to override the veto of H.B. 11, which requires …'`, so existing tests stay
    valid.
  - The existing `accepts a valid file` test must still pass.

```ts
describe('0.3 record fields', () => {
  it('requires record_kind and actor_quote on a record passage', () => {
    const r = validateCoderLabelFile(file([row({ passages: [passage({ record_kind: undefined, actor_quote: undefined })] })]), ctx);
    expect(r.rows[0].errors).toEqual(expect.arrayContaining([
      `passage ${SNAP}: record_kind required for a record`,
      `passage ${SNAP}: actor_quote required for a record`,
    ]));
  });
  it('requires tally_quote when record_kind is vote', () => {
    const r = validateCoderLabelFile(file([row({ passages: [passage({ tally_quote: null })] })]), ctx);
    expect(r.rows[0].errors).toContain(`passage ${SNAP}: tally_quote required for a vote`);
  });
  it('does not require tally_quote for a sponsorship', () => {
    const r = validateCoderLabelFile(file([row({ passages: [passage({ record_kind: 'sponsor', tally_quote: null })] })]), ctx);
    expect(r.rows[0].errors).toEqual([]);
  });
  it('refuses an actor_quote or tally_quote that is not verbatim', () => {
    const r = validateCoderLabelFile(file([row({ passages: [passage({ actor_quote: 'Yoder voted aye', tally_quote: 'Ayes 40 Noes 0' })] })]), ctx);
    expect(r.rows[0].errors).toEqual(expect.arrayContaining([
      `passage ${SNAP}: actor_quote not verbatim in snapshot`,
      `passage ${SNAP}: tally_quote not verbatim in snapshot`,
    ]));
  });
  it('refuses an unknown record_kind', () => {
    const r = validateCoderLabelFile(file([row({ passages: [passage({ record_kind: 'cosponsor' as never })] })]), ctx);
    expect(r.rows[0].errors).toContain(`passage ${SNAP}: record_kind cosponsor not allowed`);
  });
  it('asks nothing new of a statement passage', () => {
    const p = passage({ v3_class: 'statement-other', record_kind: undefined, actor_quote: undefined, tally_quote: undefined });
    expect(validateCoderLabelFile(file([row({ passages: [p] })]), ctx).rows[0].errors).toEqual([]);
  });
});
```

- [ ] **Step 2: Run and confirm that it FAILS.**
  Run: `cd backend && npx vitest run scripts/lib/coderLabel.test.ts`.

- [ ] **Step 3: Implement** in `coderLabel.ts`.
  - Set `CODEBOOK_VERSION = '0.3'`.
  - Add `RECORD_KIND` and the three optional `Passage` fields.
  - In `validateRow`'s passage loop, right after the `provision_quote` block, add:

```ts
    if (p.v3_class === 'record') {
      if (p.record_kind === null || p.record_kind === undefined) errors.push(`${where}: record_kind required for a record`);
      else { const e = enumErr(where, 'record_kind', p.record_kind, RECORD_KIND); if (e) errors.push(e); }
      if (typeof p.actor_quote !== 'string' || !p.actor_quote) errors.push(`${where}: actor_quote required for a record`);
      if (p.record_kind === 'vote' && (typeof p.tally_quote !== 'string' || !p.tally_quote)) errors.push(`${where}: tally_quote required for a vote`);
    }
    for (const f of ['actor_quote', 'tally_quote'] as const) {
      const v = p[f];
      if (v === null || v === undefined) continue;
      if (typeof v !== 'string') errors.push(`${where}: ${f} not a string`);
      else if (text !== undefined && !verbatimIn(text, v)) errors.push(`${where}: ${f} not verbatim in snapshot`);
    }
```

- [ ] **Step 4: Update the codebook text** (`docs/codebook/stance-and-quote-codebook.md`):
  - **`**Version:**` line.** Replace `0.2 (DRAFT, 2026-09-25). It carries rulings Q1–Q9 (design spec
    §9.1).` with `0.3 (DRAFT, 2026-09-25). It carries rulings Q1–Q9 (design spec §9.1) and the record
    fields (confirm-basis spec).`. Keep the rest of that line.
  - **Under V3 Rules,** add a bullet "**Record fields (0.3).**" with three sub-bullets:
    - `record_kind` is one of `vote` / `sponsor` / `author` / `other-act`.
    - `actor_quote` is the words, verbatim, showing this person acted: the Aye/No list segment that
      contains the surname, or the author/sponsor line. If two members on the page share the surname,
      include the initial or first name (for example `Walker G`, or `Watson, R.`).
    - `tally_quote` is the vote count text, verbatim (for example `Ayes Count 29 Noes Count 8`).
      It is required for a vote.
  - **In V3,** add one sentence: "`instrument` names the bill and the session (for example
    `SB 1174 (2023-2024)`); every page of one record must name the same instrument."
  - **Under V4.1,** add one bullet: "A vote whose `tally_quote` shows fewer than 10% No is
    `near-unanimous` and cannot carry the chair alone; a claimed vote with no vote page (for example a
    bill that died in committee) is not a vote."
  - **In Part C's template,** add the line `Synonyms: statute or program names the state uses for this
    topic (e.g. "Medical Assistance Program" for Medicaid in Maryland)`.
  - **In Part E's schema,** add `"record_kind"`, `"actor_quote"`, `"tally_quote"` to the passage object,
    and add their invariants to the list under it.
- [ ] **Step 5: Update `docs/codebook/annex/school-vouchers.md`.** After the **Levels** paragraph, add:
  `**Synonyms:** "education savings account" (ESA), "scholarship", "tax-credit scholarship",
  "Choice Scholarship" (Indiana), "Utah Fits All".`
- [ ] **Step 6: Run and confirm that it PASSES.**
  Run: `cd backend && npx vitest run scripts/lib/coderLabel.test.ts scripts/lib/codingReport.test.ts scripts/lib/disagreementDigest.test.ts`.
  The version-pin test checks the new `**Version:** 0.3 ` line. If a `codingReport` fixture now fails
  because its record passage lacks the fields, note it; Task 3 updates that fixture. Do not change the
  fixture here.
- [ ] **Step 7: Commit.**

```bash
git add -- backend/scripts/lib/coderLabel.ts backend/scripts/lib/coderLabel.test.ts docs/codebook/stance-and-quote-codebook.md docs/codebook/annex/school-vouchers.md
git commit -m "feat(codebook): 0.3 — record_kind, actor_quote, tally_quote on record passages" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -- backend/scripts/lib/coderLabel.ts backend/scripts/lib/coderLabel.test.ts docs/codebook/stance-and-quote-codebook.md docs/codebook/annex/school-vouchers.md
```

---

### Task 2: `recordBasis.ts` — judge one record group

**Files:**
- Create: `backend/scripts/lib/recordBasis.ts`, `backend/scripts/lib/recordBasis.test.ts`

**Interfaces:**
- Consumes: `Passage`, `verbatimIn` (`coderLabel.ts`); `normalizeText` (`../../src/lib/researchVerifier.js`).
- Produces:
  - `parseTally(q: string): { ayes: number; noes: number } | null`
  - `isNearUnanimous(t: { ayes: number; noes: number }): boolean`
  - `instrumentKey(s: string | null | undefined): string | null`
  - `type RecordFinding = 'person-not-in-snapshot' | 'provision-missing' | 'instrument-mismatch' | 'vote-not-evidenced' | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision'`
  - `checkRecordGroup(i: { passages: Passage[]; snapshotText: ReadonlyMap<string, string>; fullName: string }): { findings: RecordFinding[]; actorPassages: Passage[] }`

- [ ] **Step 1: Write the failing test.** The fixtures are real snapshot text from the two shadow
  batches.

```ts
// backend/scripts/lib/recordBasis.test.ts
import { describe, it, expect } from 'vitest';
import { parseTally, isNearUnanimous, instrumentKey, checkRecordGroup } from './recordBasis.js';
import type { Passage } from './coderLabel.js';

// CA leginfo votes page for SB 1174 (Senate floor block) and the bill text — shadow-durazo batch.
const VOTES = 'Bill Votes - SB-1174 Elections: voter identification. (2023-2024) California Legislative Information || Date 05/21/24 Result (PASS) Location Senate Floor Ayes Count 30 Noes Count 8 NVR Count 2 Motion Senate 3rd Reading SB1174 Min et al. Ayes Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo, Eggman, Glazer Noes Dahle, Grove, Jones NVR Allen, Alvarado-Gil';
const BILL = 'SB-1174 Elections: voter identification. (2023-2024) A local government shall not enact or enforce any charter provision, ordinance, or regulation requiring a person to present identification for the purpose of voting or submitting a ballot at any polling place, vote center, or other location where ballots are cast or submitted, unless required by state or federal law.';
// IN Senate roll call 334 (HB 1041) — shadow-yoder batch.
const RC334 = 'Roll Call 334: Bill Passed HB 1041 - Donato - 3rd Reading Yea 42 Student eligibility in interscholastic sports. Nay 6 Excused 2 Not Voting 0 Y EA - 42 Alting Walker G Walker K Young N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder';
const text = new Map([['v', VOTES], ['b', BILL], ['r', RC334]]);

const P = (over: Partial<Passage>): Passage => ({ snapshot_id: 'v', v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record',
  v4_shape: 'chair-shaped', v5_time: 'in-term', date: '2024-05-21', instrument: 'SB 1174 (2023-2024)', provision_quote: null,
  record_kind: 'vote', actor_quote: 'Ayes Archuleta, Ashby, Atkins, Becker, Blakespear, Bradford, Caballero, Cortese, Dodd, Durazo', tally_quote: 'Ayes Count 30 Noes Count 8', ...over });
const billPage = P({ snapshot_id: 'b', record_kind: 'vote', actor_quote: null, tally_quote: null,
  provision_quote: 'A local government shall not enact or enforce any charter provision, ordinance, or regulation requiring a person to present identification for the purpose of voting' });

describe('parseTally', () => {
  it.each([
    ['Ayes Count 30 Noes Count 8', { ayes: 30, noes: 8 }],
    ['Yea 42 Student eligibility in interscholastic sports. Nay 6', { ayes: 42, noes: 6 }],
    ['Yeas: 96 Nays: 41', { ayes: 96, noes: 41 }],
  ])('%s', (q, t) => expect(parseTally(q)).toEqual(t));
  it('returns null when a count is missing (fail closed)', () => expect(parseTally('Bill Passed')).toBeNull());
  it('does not read "Not Voting" as No', () => expect(parseTally('Yea 42 Not Voting 0')).toBeNull());
});

describe('isNearUnanimous', () => {
  it('40–0 is near-unanimous', () => expect(isNearUnanimous({ ayes: 40, noes: 0 })).toBe(true));
  it('30–8 is divided', () => expect(isNearUnanimous({ ayes: 30, noes: 8 })).toBe(false));
  it('42–6 is divided (12.5% No)', () => expect(isNearUnanimous({ ayes: 42, noes: 6 })).toBe(false));
  it('46–5 is near-unanimous (9.8% No)', () => expect(isNearUnanimous({ ayes: 46, noes: 5 })).toBe(true));
});

describe('instrumentKey', () => {
  it('normalises spacing, case and punctuation', () => {
    expect(instrumentKey('SB 1174 (2023-2024)')).toBe(instrumentKey('sb1174 (2023–2024)'));
    expect(instrumentKey('H.B. 11 (2022)')).toBe('hb11(2022)');
  });
  it('null for an empty instrument', () => expect(instrumentKey(null)).toBeNull());
});

describe('checkRecordGroup (D1: one basis across pages)', () => {
  it('passes a vote page + bill text pair on one instrument', () => {
    const r = checkRecordGroup({ passages: [P({}), billPage], snapshotText: text, fullName: 'Maria Elena Durazo' });
    expect(r.findings).toEqual([]);
    expect(r.actorPassages.map((p) => p.snapshot_id)).toEqual(['v']);
  });
  it('a claimed vote with only the bill text is not a vote (dead-bill case)', () =>
    expect(checkRecordGroup({ passages: [billPage], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings)
      .toEqual(expect.arrayContaining(['vote-not-evidenced', 'person-not-in-snapshot'])));
  it('requires the provision somewhere in the group', () =>
    expect(checkRecordGroup({ passages: [P({})], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings).toEqual(['provision-missing']));
  it('flags pages about different instruments', () =>
    expect(checkRecordGroup({ passages: [P({}), { ...billPage, instrument: 'SB 57 (2025-2026)' }], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings)
      .toContain('instrument-mismatch'));
  it('flags an actor_quote that does not name the person', () =>
    expect(checkRecordGroup({ passages: [P({ actor_quote: 'Noes Dahle, Grove, Jones' }), billPage], snapshotText: text, fullName: 'Maria Elena Durazo' }).findings)
      .toContain('person-not-in-snapshot'));
  it('flags a near-unanimous vote', () => {
    const t40 = new Map([...text, ['u', 'Ayes Count 40 Noes Count 0 Ayes Allen, Durazo, Wiener']]);
    const u = P({ snapshot_id: 'u', actor_quote: 'Ayes Allen, Durazo, Wiener', tally_quote: 'Ayes Count 40 Noes Count 0' });
    expect(checkRecordGroup({ passages: [u, billPage], snapshotText: t40, fullName: 'Maria Elena Durazo' }).findings).toEqual(['near-unanimous-vote']);
  });
  it('flags an unreadable tally', () =>
    expect(checkRecordGroup({ passages: [P({ tally_quote: 'Result (PASS)' }), billPage], snapshotText: new Map([...text, ['v', VOTES + ' Result (PASS)']]), fullName: 'Maria Elena Durazo' }).findings)
      .toContain('tally-unreadable'));
  it('IN roll call: Yoder is the actor and the 42–6 tally is divided', () => {
    const rc = P({ snapshot_id: 'r', instrument: 'HB 1041 (2025)', actor_quote: 'N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder',
      tally_quote: 'Yea 42 Student eligibility in interscholastic sports. Nay 6', provision_quote: null });
    const bill = { ...rc, snapshot_id: 'r', actor_quote: null, tally_quote: null, provision_quote: 'Student eligibility in interscholastic sports' };
    expect(checkRecordGroup({ passages: [rc, bill], snapshotText: text, fullName: 'Shelli Yoder' }).findings).toEqual([]);
  });
  it('flags a surname shared on the page unless the actor_quote carries the initial', () => {
    const w = P({ snapshot_id: 'r', instrument: 'HB 1041 (2025)', actor_quote: 'Walker', tally_quote: 'Yea 42 Student eligibility in interscholastic sports. Nay 6', provision_quote: 'Student eligibility in interscholastic sports' });
    expect(checkRecordGroup({ passages: [w], snapshotText: text, fullName: 'Greg Walker' }).findings).toContain('name-collision');
    expect(checkRecordGroup({ passages: [{ ...w, actor_quote: 'Walker G' }], snapshotText: text, fullName: 'Greg Walker' }).findings).not.toContain('name-collision');
  });
});
```

- [ ] **Step 2: Run and confirm that it FAILS** (module not found).

- [ ] **Step 3: Implement**

```ts
// backend/scripts/lib/recordBasis.ts
/**
 * recordBasis — CONFIRM for a RECORD basis (confirm-basis spec §2, defect D1). A vote is usually two
 * pages: a vote page that names the person but has no bill text, and the bill text that has the
 * provision but names no voters. So a record is judged as one GROUP of passages on one instrument:
 * one passage must show the person acting (actor_quote), some passage must carry the provision, and
 * a vote must come from a vote page with a readable, divided tally. The coders copy each fact
 * verbatim (codebook 0.3); code only checks and reads it. Fail closed: anything unreadable is a finding.
 */
import { normalizeText } from '../../src/lib/researchVerifier.js';
import { verbatimIn, type Passage } from './coderLabel.js';

export type RecordFinding =
  | 'person-not-in-snapshot' | 'provision-missing' | 'instrument-mismatch' | 'vote-not-evidenced'
  | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision';

export function parseTally(q: string): { ayes: number; noes: number } | null {
  const s = q.replace(/\s+/g, ' ');
  const ay = /\b(?:ayes|aye|yeas|yea)\b(?:\s+count)?\s*[:\-]?\s*(\d+)/i.exec(s);
  const no = /\b(?:noes|nays|nay|no)\b(?:\s+count)?\s*[:\-]?\s*(\d+)/i.exec(s);
  return ay && no ? { ayes: Number(ay[1]), noes: Number(no[1]) } : null;
}

export const isNearUnanimous = (t: { ayes: number; noes: number }): boolean =>
  t.ayes + t.noes > 0 && t.noes / (t.ayes + t.noes) < 0.1;

export function instrumentKey(s: string | null | undefined): string | null {
  if (!s || !s.trim()) return null;
  return s.toLowerCase().replace(/[–—]/g, '-').replace(/[\s.]/g, '');
}

const words = (s: string) => normalizeText(s).replace(/[^a-z0-9\s-]/g, ' ').split(/\s+/).filter(Boolean);
const lastNameOf = (full: string) => {
  const t = full.trim().split(/\s+/).filter((x) => !/^(jr|sr|ii|iii|iv)\.?$/i.test(x));
  return normalizeText(t[t.length - 1] ?? '');
};
const firstNameOf = (full: string) => normalizeText(full.trim().split(/\s+/)[0] ?? '');

export function checkRecordGroup(i: { passages: Passage[]; snapshotText: ReadonlyMap<string, string>; fullName: string }):
  { findings: RecordFinding[]; actorPassages: Passage[] } {
  const out = new Set<RecordFinding>();
  const last = lastNameOf(i.fullName);
  const first = firstNameOf(i.fullName);
  const textOf = (p: Passage) => i.snapshotText.get(p.snapshot_id) ?? '';

  // One instrument for the whole group.
  const keys = new Set(i.passages.map((p) => instrumentKey(p.instrument)));
  if (keys.size !== 1 || keys.has(null)) out.add('instrument-mismatch');

  // The actor: a verbatim actor_quote that names the person.
  const actorPassages = i.passages.filter((p) => p.actor_quote && verbatimIn(textOf(p), p.actor_quote) && words(p.actor_quote).includes(last));
  if (actorPassages.length === 0) out.add('person-not-in-snapshot');

  // A surname two members share on the page needs the first name or initial beside it.
  for (const p of actorPassages) {
    const pageCount = words(textOf(p)).filter((w) => w === last).length;
    if (pageCount < 2) continue;
    const aq = words(p.actor_quote!);
    const idx = aq.map((w, k) => (w === last ? k : -1)).filter((k) => k >= 0);
    const qualified = idx.some((k) => [aq[k - 1], aq[k + 1]].some((n) => n === first || n === first[0]));
    if (!qualified) out.add('name-collision');
  }

  // The provision is verbatim on some page of the group.
  if (!i.passages.some((p) => p.provision_quote && verbatimIn(textOf(p), p.provision_quote))) out.add('provision-missing');

  // A vote must come from a vote page, with a readable and divided tally.
  if (i.passages.some((p) => p.record_kind === 'vote')) {
    const votePages = actorPassages.filter((p) => p.record_kind === 'vote');
    if (votePages.length === 0) out.add('vote-not-evidenced');
    for (const p of votePages) {
      const t = p.tally_quote && verbatimIn(textOf(p), p.tally_quote) ? parseTally(p.tally_quote) : null;
      if (!t) out.add('tally-unreadable');
      else if (isNearUnanimous(t)) out.add('near-unanimous-vote');
    }
  }
  return { findings: [...out], actorPassages };
}
```

- [ ] **Step 4: Run and confirm that it PASSES.** If a regex boundary case fails, fix the implementation,
  not the fixture. The fixtures are real page text.
- [ ] **Step 5: Commit.**

```bash
git add -- backend/scripts/lib/recordBasis.ts backend/scripts/lib/recordBasis.test.ts
git commit -m "feat(confirm): recordBasis — judge a vote/sponsorship record as one group (D1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -- backend/scripts/lib/recordBasis.ts backend/scripts/lib/recordBasis.test.ts
```

---

### Task 3: Route record passages in `confirmRow` through `recordBasis`

**Files:**
- Modify: `backend/scripts/lib/confirm.ts`, `backend/scripts/lib/confirm.test.ts`,
  `backend/scripts/lib/codingReport.test.ts`

**Interfaces:**
- Consumes: `checkRecordGroup`, `instrumentKey` (Task 2).
- Produces:
  - `ConfirmFinding` gains `'instrument-mismatch' | 'vote-not-evidenced' | 'tally-unreadable' | 'near-unanimous-vote' | 'name-collision'`.
  - The `confirmRow` signature does not change.

- [ ] **Step 1: Write the failing tests.** Add to `confirm.test.ts`, reusing its `seat`, `P`, `run` and
  `text` helpers, and extending `text` with a vote page and a bill page:

```ts
describe('record groups (D1)', () => {
  const t2 = new Map([...text,
    ['vote', 'Utah State Senate roll call. Ayes Count 21 Noes Count 8 Ayes Adams, Bramble, Cullimore. Noes Riebe'],
    ['bill', 'H.B. 11 (2022). The bill requires students to compete on teams matching their sex at birth.']]);
  const vote = P({ snapshot_id: 'vote', instrument: 'H.B. 11 (2022)', record_kind: 'vote', provision_quote: null,
    actor_quote: 'Ayes Adams, Bramble, Cullimore', tally_quote: 'Ayes Count 21 Noes Count 8' });
  const bill = P({ snapshot_id: 'bill', instrument: 'H.B. 11 (2022)', record_kind: 'vote', actor_quote: null, tally_quote: null,
    provision_quote: 'requires students to compete on teams matching their sex at birth', date: '2022-03-25' });
  const kinds = new Map([['vote', 'public-record'], ['bill', 'public-record']]);
  it('a vote page + bill text pair passes (no person/provision findings on the bill page)', () =>
    expect(run({ restsOnPassages: [vote, bill], snapshotText: t2, sourceKind: kinds })).toEqual([]));
  it('the bill page alone is not a vote', () =>
    expect(run({ restsOnPassages: [bill], snapshotText: t2, sourceKind: kinds })).toEqual(expect.arrayContaining(['vote-not-evidenced'])));
  it('record-before-term uses the actor (vote) date, not the bill-text date', () =>
    expect(run({ restsOnPassages: [vote, { ...bill, date: '2019-01-01' }], snapshotText: t2, sourceKind: kinds })).not.toContain('record-before-term'));
});
```

  Then **update the existing fixtures**, so that each record passage in them is a valid 0.3 record:
  - In `confirm.test.ts`, the default `P()` becomes `record_kind: 'other-act'` and
    `actor_quote: 'J. Stuart Adams led the override'`. That text is verbatim in the default snapshot,
    `'… President J. Stuart Adams led the override; the bill requires …'`.
  - In `codingReport.test.ts`, give the default `P` `record_kind: 'other-act'` and
    `actor_quote: 'J. Stuart Adams'`. The fixture text contains `Utah Senate President J. Stuart Adams`.
  - Keep every other existing assertion.
  - Tests that assert `person-not-in-snapshot` for a different person on the page stay valid: that
    `actor_quote` must then name the other person. Adjust the fixture `actor_quote` to text that
    is actually on that page and does not contain "Adams".

- [ ] **Step 2: Run and confirm that the new tests FAIL.**
- [ ] **Step 3: Implement** in `confirm.ts`:
  - Import `checkRecordGroup` and `instrumentKey` from `./recordBasis.js`, and widen `ConfirmFinding`
    with the five new values.
  - In `confirmRow`, split the passages: `records = restsOnPassages.filter((p) => p.v3_class === 'record')`,
    `statements = the rest`.
  - **Records.** Group them by `instrumentKey(p.instrument) ?? '∅'`. For each group:
    1. Call `checkRecordGroup({ passages: group, snapshotText: i.snapshotText, fullName: i.seat.full_name })`.
    2. Add each finding it returns.
    3. For the **date checks**, use only the group's `actorPassages`. If a group has none, use all of
       its passages, so it still fails closed. Apply today's record date logic to those passages:
       `record-not-this-office` for candidates, `dates-imprecise` / `record-before-term` for seated
       members, and `undated-evidence`.
    4. Do **not** run the per-passage `person-not-in-snapshot` proximity scan or the per-passage
       `provision-missing` check on record passages.
  - **Statements.** Keep today's per-passage logic: the proximity scan, `undated-evidence` and the
    cycle checks.
  - **Unchanged:** the identity check, `rests-on-pointer` and `revision-drift`, still over all passages.
- [ ] **Step 4: Run and confirm that it PASSES.** Run: `cd backend && npx vitest run scripts/lib/confirm.test.ts scripts/lib/recordBasis.test.ts scripts/lib/codingReport.test.ts scripts/lib/coderLabel.test.ts scripts/lib/disagreementDigest.test.ts scripts/lib/stancePublishPolicy.test.ts`.
  All must pass, and `stancePublishPolicy.test.ts` must pass unchanged.
- [ ] **Step 5: Commit.**

```bash
git add -- backend/scripts/lib/confirm.ts backend/scripts/lib/confirm.test.ts backend/scripts/lib/codingReport.test.ts
git commit -m "feat(confirm): record passages are judged as one basis per instrument (fixes D1)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" -- backend/scripts/lib/confirm.ts backend/scripts/lib/confirm.test.ts backend/scripts/lib/codingReport.test.ts
```

---

### Task 4: Season 1 leads + fresh/stale seed flag

**Files:**
- Create: `backend/scripts/lib/s1Leads.ts`, `backend/scripts/lib/s1Leads.test.ts`, `backend/scripts/build-s1-leads.ts`
- Modify: `backend/scripts/lib/codingReport.ts` (plus one test in `codingReport.test.ts`), `backend/scripts/code-stance-batch.ts`

**Interfaces:**
- Produces:
  - `interface S1Lead { topic_id: string; topic_key: string; season_number: number; value: number; pin_revision_id: string; reasoning: string | null; sources: string[]; seed: 'fresh' | 'stale' }`
  - `seedState(pinRevisionId: string, servedRevisionId: string): 'fresh' | 'stale'`
  - `leadsById(leads: S1Lead[]): Map<string, S1Lead>` (keyed by `topic_id`)
  - `buildCodingReport` accepts an optional `s1Leads?: S1Lead[]`
  - each `RowReport` gains `seed: 'fresh' | 'stale' | 'none'` (information only; it never changes
    `shadow` or `shadow_reasons`)

- [ ] **Step 1: Write the failing tests.**
  - `s1Leads.test.ts`:
    - `seedState('a', 'a')` returns `'fresh'`;
    - `seedState('a', 'b')` returns `'stale'`;
    - `leadsById` keys the leads by `topic_id`.
  - `codingReport.test.ts`, new case:
    - with `s1Leads: [{ topic_id: 't1', …, seed: 'stale' }]`, the report row for `t1` has
      `seed: 'stale'`, and `t2` has `seed: 'none'`;
    - `shadow` and `shadow_reasons` equal what the same call returns with no leads.
  - `coderPrompt.test.ts`, new case: `buildCodingReport`'s inputs never reach `buildCoderPrompt`. Build
    a prompt with the existing helpers and assert that it does not contain a marker string such as
    `'S1-LEAD-MARKER'`. In the same test, put that marker in a lead's `reasoning`, and show that no
    prompt-builder parameter accepts leads: the test is a type-level and behaviour guard, because
    `buildCoderPrompt` takes no leads argument.
- [ ] **Step 2: Run and confirm that they FAIL.**
- [ ] **Step 3: Implement `s1Leads.ts`.** The lib is pure: types, `seedState` and `leadsById`.
- [ ] **Step 4: Implement `build-s1-leads.ts`.** It is read-only:
  - Arguments: `--dir <batch> --politician <uuid>`.
  - It reads `topics.json`.
  - For each topic, it takes the person's **newest answer in a season whose status is not 'open' and
    not 'draft'**: join `inform.politician_answers` to `inform.seasons` with
    `s.status NOT IN ('open','draft')`, `ORDER BY s.number DESC LIMIT 1`, with `value <> 0`.
  - It adds that season's `politician_context` row, by the same `season_id`, for `reasoning` and
    `sources`.
  - It computes `seed = seedState(answer.topic_revision_id, topic.served_revision_id)`.
  - It writes `<dir>/s1-leads.json` as `{ politician_id, leads: S1Lead[] }` and prints
    `N leads (F fresh / S stale)`.
  - It carries the marker `-- @season-scope: all-seasons — collector lead: the newest closed-season answer, read to be re-checked, never displayed` inside its SQL literal, for `check:answer-seasons`.
  - The header comment states that the file is for the collector only, and must never be passed to a
    coder.
- [ ] **Step 5: Wire the flag.**
  - `code-stance-batch.ts`: if `<dir>/s1-leads.json` exists, read `.leads` and pass it as `s1Leads`.
  - `codingReport.ts`: set each row's `seed` from `leadsById(i.s1Leads ?? [])`, or `'none'` when the
    topic has no lead. Add `seed` to `RowReport` and to the `CodingReport` row type.
- [ ] **Step 6: Run the tests.** Run: `npx vitest run scripts/lib/s1Leads.test.ts scripts/lib/codingReport.test.ts scripts/lib/coderPrompt.test.ts`.
  Then typecheck the two scripts:

  ```bash
  npx tsc --noEmit --strict --module nodenext --moduleResolution nodenext --target es2022 --skipLibCheck scripts/build-s1-leads.ts scripts/code-stance-batch.ts
  ```

  Then run `npm run -s check:answer-seasons` from `backend/`. It must pass.
- [ ] **Step 7: Commit** (explicit pathspec for all six files, and the trailer).

---

### Task 5: SKILL shadow procedure

**Files:** Modify `.claude/skills/research-stances/SKILL.md`, the "## SHADOW CODING (P1, spec 2026-09-25)" section.

- [ ] **Step 1: Edit the section** as follows:
  - **Step 1 (Collect).** Add two sub-bullets:
    - "Before searching, run `npx tsx scripts/build-s1-leads.ts --dir <batch> --politician <uuid>`
      and check each lead's cited sources first. Old citations are often wrong (bill number, chamber,
      a dead bill). **Never pass `s1-leads.json` to a coder.**"
    - "Search with the topic annex's **Synonyms** as well as the plain topic words, before recording
      that nothing was found."
  - **Step 4 (Dispatch).** Replace the Agent-tool text with the headless dispatch, run from an **empty
    scratch directory**, one line per slot, and say that it keeps the input byte-exact and uses plan
    quota:

    ```bash
    CLAUDE_CONFIG_DIR=~/.claude-ev claude -p --model <opus|sonnet> --tools Write --allowedTools Write --permission-mode acceptEdits --add-dir <batch>/labels --output-format text < <batch>/coder-inputs/coder-N.md
    ```

  - **Step 5 note.** Add: "Record passages now need `record_kind`, `actor_quote` (and `tally_quote`
    for a vote). CONFIRM judges a vote page and its bill text together, as one basis."
- [ ] **Step 2: Commit** (explicit pathspec, with the trailer).

---

### Task 6: Re-code the two shadow batches under 0.3 and compare (operator-visible)

**Files:**
- Modify the batch dirs `backend/data/stance-research/2026-09-25-shadow-{yoder,durazo}/`
  (new `coder-inputs/`, `labels/`, `coding-report.json`, `disagreement-digest.json`, `s1-leads.json`).
- Keep the 0.2 outputs as `labels-0.2/` and `coding-report-0.2.json`.
- Modify `docs/superpowers/specs/2026-09-25-codebook-p1-findings.md`.

- [ ] **Step 1: Keep the 0.2 results.** For each batch, move `labels/` to `labels-0.2/` and
  `coding-report.json` to `coding-report-0.2.json`.
- [ ] **Step 2: Run `build-s1-leads.ts`** for each person (read-only).
- [ ] **Step 3: Rebuild the inputs.** Run `build-coder-inputs.ts` for each person with the same
  `--politician` value.
- [ ] **Step 4: Dispatch the coders.** Use the headless dispatch (Task 5) for slots 1–3 per batch: Opus
  for slot 1, Sonnet for slots 2–3.
- [ ] **Step 5: Run the reports.** Run `code-stance-batch.ts --dir <batch> --season-id <open season id> --models "opus,sonnet,sonnet"` for each batch (no `--apply`).
- [ ] **Step 6: Add a "0.2 → 0.3" section to the findings.** It should show:
  - the table of chairs per coder;
  - the CONFIRM findings per unanimous row;
  - the seed flags;
  - whether Durazo / voting-rights now fails only on real grounds. The expected ground is `adjacent`
    (preemption), not D1;
  - any new validator errors caused by the 0.3 fields.
- [ ] **Step 7: Commit** the batch dirs and the findings (explicit pathspec, with the trailer).
