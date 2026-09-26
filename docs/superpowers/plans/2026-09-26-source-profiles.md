# Source Profiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** CONFIRM reads each official record page with the rules of its own source (one Markdown file per source, with a YAML header of code-defined rule kinds), and fails closed on a source with no profile.

**Architecture:** `recordBasis.ts` gains named rule kinds (`SourceRules`) that replace its built-in layout rules, with `GENERIC_RULES` equal to today's behaviour. A new `sourceProfiles.ts` loads `docs/sources/**/*.md`, validates each header strictly, and resolves a snapshot URL to a profile. `confirmRow` looks up each record passage's profile and adds `no-source-profile` when there is none. Four real profiles (CA + IN) ship with real saved pages as controls, run by a test.

**Tech Stack:** TypeScript ESM (`.js` import suffixes), vitest, `js-yaml` 5.4 (already a dependency: `import { load as yamlLoad } from 'js-yaml'`).

**Spec:** `docs/superpowers/specs/2026-09-26-source-profiles-design.md` (approved 2026-09-26).

## Global Constraints

- P1 stays SHADOW: do not import or change `backend/scripts/lib/stancePublishPolicy.ts`; `stancePublishPolicy.test.ts` must pass unchanged.
- No DB writes. Scripts are read-only. Never pass `--apply`.
- **The header chooses from rule kinds defined in code. It never holds a regex.**
- A header with an unknown key, an unknown rule kind, a missing field, or zero `pass` controls is a load **error** that names the file and the key.
- No profile → generic rules still run, and CONFIRM adds `no-source-profile` (fail closed).
- Coders never see profiles: `build-coder-inputs.ts` and `coderPrompt.ts` must not read `docs/sources`.
- `GENERIC_RULES` = `{ vote_block: 'aye-count', chamber: 'nearest-before', not_chamber_after: [], name_format: 'surname' }` and must reproduce today's findings exactly.
- Commits: explicit pathspec only (`git add <paths>` then `git commit -F <msgfile> -- <paths>`); end every message with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Tests from `backend/`: `npx vitest run <paths>`. `npx tsc -p .` does NOT cover `backend/scripts`; type-check scripts directly with:
  `npx tsc --noEmit --module esnext --moduleResolution bundler --target es2022 --strict --esModuleInterop --skipLibCheck --forceConsistentCasingInFileNames --resolveJsonModule <files>`

---

### Task 1: Rule kinds in `recordBasis.ts`

**Files:**
- Modify: `backend/scripts/lib/recordBasis.ts`
- Test: `backend/scripts/lib/recordBasis.test.ts` (add a `describe('source rules', …)` block)

**Interfaces:**
- Produces (exported from `recordBasis.ts`):
  ```ts
  export type VoteBlockRule = 'aye-count' | 'whole-page';
  export type ChamberRule = 'nearest-before' | 'word-before-floor' | 'page-header' | 'bill-origin' | 'none';
  export type NameFormat = 'surname' | 'surname-initial' | 'last-first' | 'full-name';
  export interface SourceRules { vote_block: VoteBlockRule; chamber: ChamberRule; not_chamber_after: string[]; name_format: NameFormat }
  export const GENERIC_RULES: SourceRules;
  export const VOTE_BLOCK_RULES: readonly VoteBlockRule[];
  export const CHAMBER_RULES: readonly ChamberRule[];
  export const NAME_FORMATS: readonly NameFormat[];
  /** Per actor passage: the rules of its source and the seat's chamber in that body. */
  export type PassageProfile = { rules: SourceRules; chamber: Chamber | null };
  ```
- `checkRecordGroup` input gains `profileOf?: (p: Passage) => PassageProfile | null`. When it is absent or returns null for a passage, that passage uses `GENERIC_RULES` and `i.chamber` (today's behaviour). All existing callers and tests keep working unchanged.

- [ ] **Step 1: Write the failing tests** (append to `recordBasis.test.ts`; reuse its `P` helper and imports; add `GENERIC_RULES, type SourceRules` to the import from `./recordBasis.js`)

```ts
describe('source rules', () => {
  const R = (over: Partial<SourceRules>): SourceRules => ({ ...GENERIC_RULES, ...over });
  const run = (page: string, over: Partial<Passage>, rules: SourceRules, chamber: 'upper' | 'lower' | null, fullName = 'Ana Wong') =>
    checkRecordGroup({ passages: [P({ snapshot_id: 'x', instrument: 'SB 9 (2024)', provision_quote: 'requires a thing', ...over })],
      snapshotText: new Map([['x', page]]), fullName, chamber: null, profileOf: () => ({ rules, chamber }) }).findings;

  const floorPage = 'SB 9 (2024). Location Senate Floor Ayes Count 30 Noes Count 9 Motion Assembly 3rd Reading Ayes Lee, Wong Noes Diaz. The bill requires a thing.';
  it('word-before-floor: the chamber is the word before "Floor", not the motion', () => {
    expect(run(floorPage, { actor_quote: 'Lee, Wong', tally_quote: 'Ayes Count 30 Noes Count 9' }, R({ chamber: 'word-before-floor' }), 'upper')).toEqual([]);
    expect(run(floorPage, { actor_quote: 'Lee, Wong', tally_quote: 'Ayes Count 30 Noes Count 9' }, R({ chamber: 'word-before-floor' }), 'lower')).toContain('chamber-not-evidenced');
  });
  it('page-header: the first chamber word on the page', () => {
    const page = 'Senate FIRST REGULAR SESSION SB 9 (2024) Yea 30 Nay 9 House members present Wong. The bill requires a thing.';
    expect(run(page, { actor_quote: 'present Wong', tally_quote: 'Yea 30 Nay 9' }, R({ chamber: 'page-header' }), 'upper')).toEqual([]);
  });
  it('bill-origin: SB is the Senate, AB/HB the lower chamber', () => {
    const page = 'SB 9 (2024), Wong. The bill requires a thing.';
    const author = { record_kind: 'author' as const, tally_quote: null, actor_quote: 'SB 9 (2024), Wong' };
    expect(run(page, author, R({ chamber: 'bill-origin' }), 'upper')).toEqual([]);
    expect(run(page, author, R({ chamber: 'bill-origin' }), 'lower')).toContain('chamber-not-evidenced');
  });
  it('none: the chamber test is skipped', () => {
    const page = 'SB 9 (2024). Council roll call Ayes 5 Noes 2 Ayes Lee, Wong. The bill requires a thing.';
    expect(run(page, { actor_quote: 'Lee, Wong', tally_quote: 'Ayes 5 Noes 2' }, R({ chamber: 'none' }), 'upper')).toEqual([]);
  });
  it('not_chamber_after: an extra word makes a chamber word a stage', () => {
    const page = 'SB 9 (2024). Senate Floor Ayes 30 Noes 9 Assembly Concurrence Ayes Lee, Wong. The bill requires a thing.';
    const over = { actor_quote: 'Lee, Wong', tally_quote: 'Ayes 30 Noes 9' };
    expect(run(page, over, R({}), 'upper')).toContain('chamber-not-evidenced');
    expect(run(page, over, R({ not_chamber_after: ['concurrence'] }), 'upper')).toEqual([]);
  });
  it('whole-page: two aye counts are one vote, so the surname counts across both', () => {
    const page = 'SB 9 (2024). Senate Ayes 30 Noes 9 Ayes Wong Ayes 29 Noes 9 Ayes Wong. The bill requires a thing.';
    const over = { actor_quote: 'Ayes Wong', tally_quote: 'Ayes 30 Noes 9' };
    expect(run(page, over, R({}), 'upper')).not.toContain('name-collision');
    expect(run(page, over, R({ vote_block: 'whole-page' }), 'upper')).toContain('name-collision');
  });
  it('full-name: the given name is always required', () => {
    const page = 'SB 9 (2024). Senate Ayes 5 Noes 2 Councilmember Wong aye. The bill requires a thing.';
    const over = { actor_quote: 'Councilmember Wong aye', tally_quote: 'Ayes 5 Noes 2' };
    expect(run(page, over, R({}), 'upper')).toEqual([]);
    expect(run(page, over, R({ name_format: 'full-name' }), 'upper')).toContain('name-collision');
  });
  it('profileOf returning null keeps the generic rules and i.chamber', () => {
    const f = checkRecordGroup({ passages: [P({ snapshot_id: 'x', instrument: 'SB 9 (2024)', actor_quote: 'Lee, Wong', tally_quote: 'Ayes Count 30 Noes Count 9', provision_quote: 'requires a thing' })],
      snapshotText: new Map([['x', floorPage]]), fullName: 'Ana Wong', chamber: 'upper', profileOf: () => null }).findings;
    // generic nearest-before reads "Assembly 3rd Reading" as a stage, then finds "Senate": passes
    expect(f).toEqual([]);
  });
});
```

- [ ] **Step 2: Run and confirm they FAIL**

Run: `npx vitest run scripts/lib/recordBasis.test.ts`
Expected: FAIL — `GENERIC_RULES` / `SourceRules` not exported, `profileOf` not accepted.

- [ ] **Step 3: Implement.** In `recordBasis.ts`:

  1. Add the types and constants after the `Chamber` type:

  ```ts
  export type VoteBlockRule = 'aye-count' | 'whole-page';
  export type ChamberRule = 'nearest-before' | 'word-before-floor' | 'page-header' | 'bill-origin' | 'none';
  export type NameFormat = 'surname' | 'surname-initial' | 'last-first' | 'full-name';
  export interface SourceRules { vote_block: VoteBlockRule; chamber: ChamberRule; not_chamber_after: string[]; name_format: NameFormat }
  export const VOTE_BLOCK_RULES: readonly VoteBlockRule[] = ['aye-count', 'whole-page'];
  export const CHAMBER_RULES: readonly ChamberRule[] = ['nearest-before', 'word-before-floor', 'page-header', 'bill-origin', 'none'];
  export const NAME_FORMATS: readonly NameFormat[] = ['surname', 'surname-initial', 'last-first', 'full-name'];
  /** Today's layout rules. A source with no profile is read with these (and CONFIRM flags it). */
  export const GENERIC_RULES: SourceRules = { vote_block: 'aye-count', chamber: 'nearest-before', not_chamber_after: [], name_format: 'surname' };
  export type PassageProfile = { rules: SourceRules; chamber: Chamber | null };
  ```

  2. Give `chamberAt` and `chamberBefore` an `extra: ReadonlySet<string>` parameter (words that, when they follow a chamber word, make it a stage/origin):

  ```ts
  function chamberAt(p: string[], k: number, extra: ReadonlySet<string>): Chamber | null {
    const c = CHAMBER_WORD[p[k]];
    if (!c) return null;
    if (p[k] === 'assembly' && p[k - 1] === 'general') return null;
    const next = p[k + 1];
    if (next !== undefined && (NOT_CHAMBER_NEXT.test(next) || extra.has(next))) return null;
    if (next !== undefined && ORDINAL.test(next) && p[k + 2] === 'reading') return null; // "Assembly 3rd Reading", not "Senate First Regular Session"
    return c;
  }
  function chamberBefore(p: string[], a: number, extra: ReadonlySet<string>): Chamber | null {
    for (let k = a - 1; k >= 0; k--) { const c = chamberAt(p, k, extra); if (c) return c; }
    return null;
  }
  /** The chamber of the vote/act that names the actor, read by the source's chamber rule. */
  function actorChamber(rule: ChamberRule, pt: string[], a: number, instrument: string | null | undefined, extra: ReadonlySet<string>): Chamber | null {
    switch (rule) {
      case 'nearest-before': return chamberBefore(pt, a, extra);
      case 'word-before-floor':
        for (let k = a - 1; k >= 0; k--) if (pt[k + 1] === 'floor') { const c = chamberAt(pt, k, extra); if (c) return c; }
        return null;
      case 'page-header':
        for (let k = 0; k < pt.length; k++) { const c = chamberAt(pt, k, extra); if (c) return c; }
        return null;
      case 'bill-origin': {
        const tok = billTokenOf(instrument);
        if (!tok) return null;
        if (tok.startsWith('s')) return 'upper';
        if (tok.startsWith('a') || tok.startsWith('h')) return 'lower';
        return null;
      }
      case 'none': return null;
    }
  }
  ```

  3. In `checkRecordGroup`, add the input field and resolve a profile per passage:

  ```ts
  export function checkRecordGroup(i: {
    passages: Passage[]; snapshotText: ReadonlyMap<string, string>; fullName: string;
    /** The seat's chamber (seatChamber(office_title)), used when a passage has no profile. */
    chamber?: Chamber | null;
    /** The source profile of a passage (sourceProfiles.ts). Absent/null → GENERIC_RULES + i.chamber. */
    profileOf?: (p: Passage) => PassageProfile | null;
  }):
  ```

  and near the top of the body:

  ```ts
  const prof = (p: Passage): PassageProfile => i.profileOf?.(p) ?? { rules: GENERIC_RULES, chamber: i.chamber ?? null };
  ```

  4. In `located`, use the passage's vote-block rule: `const bounds = prof(p).rules.vote_block === 'whole-page' ? [] : ayeBoundaries(pt);`

  5. Replace the chamber block with:

  ```ts
  // The vote that lists the actor must be the seat's chamber, read by the source's chamber rule.
  // Skipped when the seat has no chamber here or the source has none ('none'). Fails closed when no
  // occurrence shows it. The search starts at the surname, so a title inside the actor_quote counts
  // ("Authored by: Sen. Shelli Yoder").
  for (const l of located) {
    const { rules, chamber } = prof(l.p);
    if (!chamber || rules.chamber === 'none') continue;
    const extra = new Set(rules.not_chamber_after.map((w) => w.toLowerCase()));
    const inQuote = Math.max(0, words(l.p.actor_quote!).indexOf(last));
    if (!l.occ.some((a) => actorChamber(rules.chamber, l.pt, a + inQuote, l.p.instrument, extra) === chamber)) out.add('chamber-not-evidenced');
  }
  ```

  6. In the name-collision loop, a `full-name` source always needs the qualifier:

  ```ts
  const fullNameRequired = prof(p).rules.name_format === 'full-name';
  if (blockCount < 2 && !common && !fullNameRequired) continue;
  ```

  7. Update the file header comment: layout rules now come from the passage's source profile (`GENERIC_RULES` when there is none); list the five chamber rule kinds in one line each.

- [ ] **Step 4: Run the tests**

Run: `npx vitest run scripts/lib/recordBasis.test.ts scripts/lib/confirm.test.ts scripts/lib/codingReport.test.ts scripts/lib/coderLabel.test.ts scripts/lib/stancePublishPolicy.test.ts`
Expected: PASS, including every pre-existing test unchanged.
Then the direct tsc on `scripts/lib/recordBasis.ts scripts/lib/confirm.ts`: exit 0.

- [ ] **Step 5: Commit** `backend/scripts/lib/recordBasis.ts backend/scripts/lib/recordBasis.test.ts` — message `feat(confirm): named source rule kinds (vote block, chamber, name format); GENERIC_RULES = today's rules`.

---

### Task 2: `sourceProfiles.ts` — load, validate, resolve

**Files:**
- Create: `backend/scripts/lib/sourceProfiles.ts`, `backend/scripts/lib/sourceProfiles.test.ts`

**Interfaces:**
- Consumes (Task 1): `SourceRules`, `GENERIC_RULES`, `VOTE_BLOCK_RULES`, `CHAMBER_RULES`, `NAME_FORMATS`, `Chamber`, `seatChamber` from `./recordBasis.js`; `RECORD_KIND` from `./coderLabel.js` (check its exact export name there; it lists `vote | sponsor | author | other-act`).
- Produces:
  ```ts
  export type PageKind = 'vote' | 'author' | 'bill-text' | 'minutes';
  export interface ProfileControl {
    batch: string; snapshot: string; person: string; office_title: string; instrument: string;
    record_kind: 'vote' | 'sponsor' | 'author' | 'other-act'; actor_quote: string; tally_quote: string | null;
    expect: string;   // 'pass' or a RecordFinding the control must produce
  }
  export interface SourceProfile {
    profile: string; version: number; scope: string; body: string; url_prefixes: string[]; page_kind: PageKind;
    rules: SourceRules; seat_titles: Record<string, Chamber>; controls: ProfileControl[]; file: string;
  }
  export const SOURCES_DIR: string;   // absolute path of <repo>/docs/sources
  export function parseSourceProfile(md: string, file: string): SourceProfile;   // throws Error(`${file}: …`)
  export function loadSourceProfiles(dir?: string): SourceProfile[];            // throws on a duplicate id or prefix
  export function resolveProfile(profiles: readonly SourceProfile[], url: string): SourceProfile | null;
  export function profileSeatChamber(p: SourceProfile, officeTitle: string | null | undefined): Chamber | null;
  export const profileTag: (p: SourceProfile) => string;   // `${p.profile}@${p.version}`
  ```

- [ ] **Step 1: Write the failing tests** (`sourceProfiles.test.ts`)

```ts
import { describe, it, expect } from 'vitest';
import { mkdtempSync, mkdirSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { parseSourceProfile, loadSourceProfiles, resolveProfile, profileSeatChamber, profileTag } from './sourceProfiles.js';

const HEADER = `profile: ca-votes
version: 1
scope: state:CA
body: legislature
match:
  url_prefixes:
    - https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml
page_kind: vote
rules:
  vote_block: aye-count
  chamber: word-before-floor
  name_format: surname
seat_titles:
  Senator: upper
  Assembly Member: lower
controls:
  - batch: b
    snapshot: aa219c5b
    person: Maria Elena Durazo
    office_title: Senator
    instrument: SB 1174 (2023-2024)
    record_kind: vote
    actor_quote: "Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 30 Noes Count 8 NVR Count 2"
    expect: pass`;
const md = (h: string, body = '# CA votes\n\nProse.') => `---\n${h}\n---\n${body}\n`;

describe('parseSourceProfile', () => {
  it('parses a valid header; not_chamber_after defaults to []', () => {
    const p = parseSourceProfile(md(HEADER), 'f.md');
    expect(p.profile).toBe('ca-votes');
    expect(p.rules).toEqual({ vote_block: 'aye-count', chamber: 'word-before-floor', not_chamber_after: [], name_format: 'surname' });
    expect(p.url_prefixes).toEqual(['https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml']);
    expect(p.seat_titles).toEqual({ Senator: 'upper', 'Assembly Member': 'lower' });
    expect(profileTag(p)).toBe('ca-votes@1');
  });
  it.each([
    ['an unknown top-level key', HEADER + '\nextra: 1', /f\.md: unknown key "extra"/],
    ['an unknown rule kind', HEADER.replace('word-before-floor', 'regex-please'), /f\.md: rules\.chamber "regex-please"/],
    ['an unknown rules key', HEADER.replace('  name_format: surname', '  name_format: surname\n  pattern: "Senate.*"'), /f\.md: unknown key "rules\.pattern"/],
    ['a missing field', HEADER.replace('scope: state:CA\n', ''), /f\.md: missing "scope"/],
    ['no pass control', HEADER.replace('expect: pass', 'expect: name-collision'), /f\.md: needs at least one control with expect: pass/],
    ['a bad seat chamber', HEADER.replace('Senator: upper', 'Senator: middle'), /f\.md: seat_titles\.Senator "middle"/],
    ['a bad record_kind', HEADER.replace('record_kind: vote', 'record_kind: tweet'), /f\.md: controls\[0\]\.record_kind "tweet"/],
  ])('rejects %s', (_label, h, re) => expect(() => parseSourceProfile(md(h), 'f.md')).toThrow(re));
  it('rejects a file with no front matter', () => expect(() => parseSourceProfile('# no header', 'f.md')).toThrow(/f\.md: no front matter/));
});

describe('resolveProfile', () => {
  const a = parseSourceProfile(md(HEADER), 'a.md');
  const b = parseSourceProfile(md(HEADER.replace('profile: ca-votes', 'profile: ca-root').replace('https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml', 'https://leginfo.legislature.ca.gov/')), 'b.md');
  it('longest prefix wins', () => {
    expect(resolveProfile([b, a], 'https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml?bill_id=1')?.profile).toBe('ca-votes');
    expect(resolveProfile([b, a], 'https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml')?.profile).toBe('ca-root');
  });
  it('no match → null', () => expect(resolveProfile([a, b], 'https://iga.in.gov/x')).toBeNull());
});

describe('profileSeatChamber', () => {
  const p = parseSourceProfile(md(HEADER), 'a.md');
  it('reads seat_titles case-insensitively', () => expect(profileSeatChamber(p, 'assembly member')).toBe('lower'));
  it('falls back to seatChamber for a title the profile does not list', () => expect(profileSeatChamber(p, 'State Senator')).toBe('upper'));
});

describe('loadSourceProfiles', () => {
  const dirWith = (files: Record<string, string>) => {
    const d = mkdtempSync(join(tmpdir(), 'sp-'));
    for (const [rel, text] of Object.entries(files)) { mkdirSync(join(d, rel, '..'), { recursive: true }); writeFileSync(join(d, rel), text); }
    return d;
  };
  it('loads every .md under the dir except README.md', () => {
    const d = dirWith({ 'README.md': '# not a profile', 'states/CA/a.md': md(HEADER) });
    expect(loadSourceProfiles(d).map((p) => p.profile)).toEqual(['ca-votes']);
  });
  it('rejects a duplicate profile id', () => {
    const d = dirWith({ 'a.md': md(HEADER), 'b.md': md(HEADER) });
    expect(() => loadSourceProfiles(d)).toThrow(/duplicate profile "ca-votes"/);
  });
  it('rejects the same url prefix in two profiles', () => {
    const d = dirWith({ 'a.md': md(HEADER), 'b.md': md(HEADER.replace('profile: ca-votes', 'profile: other')) });
    expect(() => loadSourceProfiles(d)).toThrow(/url prefix .* in both/);
  });
});
```

- [ ] **Step 2: Run and confirm they FAIL**

Run: `npx vitest run scripts/lib/sourceProfiles.test.ts`
Expected: FAIL — module `./sourceProfiles.js` not found.

- [ ] **Step 3: Implement** `sourceProfiles.ts`:

```ts
/**
 * sourceProfiles — one Markdown file per official record source (docs/sources/**), with a YAML header
 * that CONFIRM reads (spec 2026-09-26-source-profiles-design.md). The header CHOOSES from rule kinds
 * defined in recordBasis.ts; it never holds a regex. Validation is strict: an unknown key, an unknown
 * rule kind, a missing field or no `pass` control stops the run, naming the file and the key.
 * COLLECTOR/CONFIRM ONLY — coders never see a profile (their input stays byte-exact).
 */
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { load as yamlLoad } from 'js-yaml';
import { CHAMBER_RULES, NAME_FORMATS, VOTE_BLOCK_RULES, seatChamber, type Chamber, type SourceRules } from './recordBasis.js';

export type PageKind = 'vote' | 'author' | 'bill-text' | 'minutes';
const PAGE_KINDS: readonly PageKind[] = ['vote', 'author', 'bill-text', 'minutes'];
const CONTROL_RECORD_KINDS = ['vote', 'sponsor', 'author', 'other-act'] as const;
export interface ProfileControl {
  batch: string; snapshot: string; person: string; office_title: string; instrument: string;
  record_kind: (typeof CONTROL_RECORD_KINDS)[number]; actor_quote: string; tally_quote: string | null; expect: string;
}
export interface SourceProfile {
  profile: string; version: number; scope: string; body: string; url_prefixes: string[]; page_kind: PageKind;
  rules: SourceRules; seat_titles: Record<string, Chamber>; controls: ProfileControl[]; file: string;
}

export const SOURCES_DIR = fileURLToPath(new URL('../../../docs/sources/', import.meta.url));
const TOP_KEYS = ['profile', 'version', 'scope', 'body', 'match', 'page_kind', 'rules', 'seat_titles', 'controls'];
const RULE_KEYS = ['vote_block', 'chamber', 'not_chamber_after', 'name_format'];
const CONTROL_KEYS = ['batch', 'snapshot', 'person', 'office_title', 'instrument', 'record_kind', 'actor_quote', 'tally_quote', 'expect'];

const isObj = (v: unknown): v is Record<string, unknown> => typeof v === 'object' && v !== null && !Array.isArray(v);
const str = (v: unknown): v is string => typeof v === 'string' && v.trim().length > 0;

export function parseSourceProfile(md: string, file: string): SourceProfile {
  const fail = (msg: string): never => { throw new Error(`${file}: ${msg}`); };
  const m = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?/.exec(md);
  if (!m) fail('no front matter (a profile starts with a --- YAML header ---)');
  const h = yamlLoad(m![1]);
  if (!isObj(h)) return fail('front matter is not a mapping');
  for (const k of Object.keys(h)) if (!TOP_KEYS.includes(k)) fail(`unknown key "${k}"`);
  for (const k of TOP_KEYS) if (h[k] === undefined) fail(`missing "${k}"`);
  if (!str(h.profile)) fail('profile must be a non-empty string');
  if (!Number.isInteger(h.version) || (h.version as number) < 1) fail('version must be an integer >= 1');
  if (!str(h.scope) || !/^(state|county|place):[A-Za-z0-9]+$/.test(h.scope as string)) fail(`scope "${String(h.scope)}" must be state:<USPS> | county:<fips> | place:<geoid>`);
  if (!str(h.body)) fail('body must be a non-empty string');
  if (!isObj(h.match)) return fail('match must be a mapping');
  for (const k of Object.keys(h.match)) if (k !== 'url_prefixes') fail(`unknown key "match.${k}"`);
  const prefixes = h.match.url_prefixes;
  if (!Array.isArray(prefixes) || prefixes.length === 0 || !prefixes.every((u) => str(u) && /^https?:\/\//.test(u as string))) fail('match.url_prefixes must be a non-empty list of http(s) URLs');
  if (!PAGE_KINDS.includes(h.page_kind as PageKind)) fail(`page_kind "${String(h.page_kind)}" is not one of ${PAGE_KINDS.join(' | ')}`);
  if (!isObj(h.rules)) return fail('rules must be a mapping');
  for (const k of Object.keys(h.rules)) if (!RULE_KEYS.includes(k)) fail(`unknown key "rules.${k}"`);
  const r = h.rules;
  if (!VOTE_BLOCK_RULES.includes(r.vote_block as never)) fail(`rules.vote_block "${String(r.vote_block)}" is not one of ${VOTE_BLOCK_RULES.join(' | ')}`);
  if (!CHAMBER_RULES.includes(r.chamber as never)) fail(`rules.chamber "${String(r.chamber)}" is not one of ${CHAMBER_RULES.join(' | ')}`);
  if (!NAME_FORMATS.includes(r.name_format as never)) fail(`rules.name_format "${String(r.name_format)}" is not one of ${NAME_FORMATS.join(' | ')}`);
  const extra = r.not_chamber_after ?? [];
  if (!Array.isArray(extra) || !extra.every((w) => str(w) && /^[a-z0-9]+$/i.test(w as string))) fail('rules.not_chamber_after must be a list of single words');
  if (!isObj(h.seat_titles)) return fail('seat_titles must be a mapping');
  for (const [t, c] of Object.entries(h.seat_titles)) if (c !== 'upper' && c !== 'lower') fail(`seat_titles.${t} "${String(c)}" must be upper | lower`);
  if (!Array.isArray(h.controls)) return fail('controls must be a list');
  h.controls.forEach((c, n) => {
    if (!isObj(c)) return fail(`controls[${n}] must be a mapping`);
    for (const k of Object.keys(c)) if (!CONTROL_KEYS.includes(k)) fail(`unknown key "controls[${n}].${k}"`);
    for (const k of CONTROL_KEYS) if (k !== 'tally_quote' && !str(c[k])) fail(`missing "controls[${n}].${k}"`);
    if (!CONTROL_RECORD_KINDS.includes(c.record_kind as never)) fail(`controls[${n}].record_kind "${String(c.record_kind)}" is not one of ${CONTROL_RECORD_KINDS.join(' | ')}`);
    if (c.tally_quote !== undefined && c.tally_quote !== null && !str(c.tally_quote)) fail(`controls[${n}].tally_quote must be a string or null`);
  });
  if (!(h.controls as Record<string, unknown>[]).some((c) => c.expect === 'pass')) fail('needs at least one control with expect: pass');
  return {
    profile: h.profile as string, version: h.version as number, scope: h.scope as string, body: h.body as string,
    url_prefixes: prefixes as string[], page_kind: h.page_kind as PageKind,
    rules: { vote_block: r.vote_block, chamber: r.chamber, not_chamber_after: extra as string[], name_format: r.name_format } as SourceRules,
    seat_titles: h.seat_titles as Record<string, Chamber>,
    controls: (h.controls as Record<string, unknown>[]).map((c) => ({ ...c, tally_quote: (c.tally_quote as string | undefined) ?? null }) as ProfileControl),
    file,
  };
}

const mdFiles = (dir: string): string[] => readdirSync(dir).flatMap((n) => {
  const p = join(dir, n);
  if (statSync(p).isDirectory()) return mdFiles(p);
  return n.endsWith('.md') && n !== 'README.md' ? [p] : [];
});

export function loadSourceProfiles(dir: string = SOURCES_DIR): SourceProfile[] {
  const profiles = mdFiles(dir).sort().map((f) => parseSourceProfile(readFileSync(f, 'utf8'), relative(dir, f)));
  const ids = new Map<string, string>(); const prefixes = new Map<string, string>();
  for (const p of profiles) {
    if (ids.has(p.profile)) throw new Error(`duplicate profile "${p.profile}" in ${ids.get(p.profile)} and ${p.file}`);
    ids.set(p.profile, p.file);
    for (const u of p.url_prefixes) {
      if (prefixes.has(u)) throw new Error(`url prefix ${u} in both ${prefixes.get(u)} and ${p.file}`);
      prefixes.set(u, p.file);
    }
  }
  return profiles;
}

export function resolveProfile(profiles: readonly SourceProfile[], url: string): SourceProfile | null {
  let best: SourceProfile | null = null; let len = -1;
  for (const p of profiles) for (const u of p.url_prefixes) if (url.startsWith(u) && u.length > len) { best = p; len = u.length; }
  return best;
}

export function profileSeatChamber(p: SourceProfile, officeTitle: string | null | undefined): Chamber | null {
  const t = (officeTitle ?? '').trim().toLowerCase();
  for (const [title, c] of Object.entries(p.seat_titles)) if (title.toLowerCase() === t) return c;
  return seatChamber(officeTitle);
}

export const profileTag = (p: SourceProfile): string => `${p.profile}@${p.version}`;
```

- [ ] **Step 4: Run the tests**

Run: `npx vitest run scripts/lib/sourceProfiles.test.ts` — Expected: PASS. Then the direct tsc on `scripts/lib/sourceProfiles.ts`: exit 0.

- [ ] **Step 5: Commit** `backend/scripts/lib/sourceProfiles.ts backend/scripts/lib/sourceProfiles.test.ts` — message `feat(confirm): sourceProfiles — strict loader and URL resolver for docs/sources profiles`.

---

### Task 3: Wire profiles into CONFIRM and the coding report

**Files:**
- Modify: `backend/scripts/lib/confirm.ts`, `backend/scripts/lib/codingReport.ts`, `backend/scripts/code-stance-batch.ts`
- Test: `backend/scripts/lib/confirm.test.ts`, `backend/scripts/lib/codingReport.test.ts`

**Interfaces:**
- Consumes (Task 2): `SourceProfile`, `resolveProfile`, `profileSeatChamber`, `profileTag`, `loadSourceProfiles` from `./sourceProfiles.js`. (Task 1): `PassageProfile`.
- Produces:
  - `ConfirmFinding` gains `'no-source-profile'`.
  - `confirmRow` input gains `snapshotUrl?: ReadonlyMap<string, string>` and `profiles?: readonly SourceProfile[]`. It returns `ConfirmFinding[]` as before. A second export `confirmRowDetailed(i) => { findings: ConfirmFinding[]; profiles: string[] }` returns the `profile@version` tags used; `confirmRow` = `confirmRowDetailed(i).findings`.
  - **Rule:** when `i.profiles` is given, every record passage resolves its profile by `i.snapshotUrl.get(p.snapshot_id)`; a passage with no URL or no match → `no-source-profile` (and that passage uses `GENERIC_RULES`). When `i.profiles` is absent (unit tests of other checks), no lookup happens and no `no-source-profile` is added.
  - `buildCodingReport` input gains `snapshotUrl?: ReadonlyMap<string, string>` and `profiles?: readonly SourceProfile[]`, passed through to `confirmRowDetailed`. `RowReport` gains `profiles: string[]` (tags used; `[]` when CONFIRM did not run). `CodingReport` gains `noProfileHosts: Record<string, number>` (count of rows with `no-source-profile`, keyed by the URL host of each unmatched record passage).
  - `code-stance-batch.ts` builds `snapshotUrl` from `snapshots.json` (`snapshot_id → url` for ok snapshots), calls `loadSourceProfiles()` once, passes both, and prints `no source profile: <host> ×N` lines when `noProfileHosts` is non-empty.

- [ ] **Step 1: Write the failing tests**

In `confirm.test.ts` (reuse its `P`, `seat`, `text` fixtures; the default passage is a record on snapshot `'s1'`), add:

```ts
import { parseSourceProfile } from './sourceProfiles.js';

describe('source profiles in CONFIRM', () => {
  const profile = parseSourceProfile(`---
profile: test-votes
version: 3
scope: state:UT
body: legislature
match:
  url_prefixes: [https://le.utah.gov/votes/]
page_kind: vote
rules: { vote_block: aye-count, chamber: nearest-before, name_format: surname }
seat_titles: { Senator: upper }
controls:
  - { batch: b, snapshot: s1, person: J. Stuart Adams, office_title: Senator, instrument: H.B. 11 (2022), record_kind: vote, actor_quote: x, tally_quote: null, expect: pass }
---
`, 'test.md');
  const base = { seat, snapshotText: text, sourceKind: kinds, rowServedRevisionId: 'r1', bundleServedRevisionId: 'r1' };
  it('a record passage whose URL matches no profile → no-source-profile', () => {
    const f = confirmRow({ ...base, restsOnPassages: [P({})], snapshotUrl: new Map([['s1', 'https://elsewhere.gov/x']]), profiles: [profile] });
    expect(f).toContain('no-source-profile');
  });
  it('a record passage with no URL at all → no-source-profile (fail closed)', () =>
    expect(confirmRow({ ...base, restsOnPassages: [P({})], snapshotUrl: new Map(), profiles: [profile] })).toContain('no-source-profile'));
  it('a matched profile adds nothing and is reported as profile@version', () => {
    const r = confirmRowDetailed({ ...base, restsOnPassages: [P({})], snapshotUrl: new Map([['s1', 'https://le.utah.gov/votes/hb11']]), profiles: [profile] });
    expect(r.findings).not.toContain('no-source-profile');
    expect(r.profiles).toEqual(['test-votes@3']);
    expect(r.findings).toEqual(confirmRow({ ...base, restsOnPassages: [P({})] }));
  });
  it('without profiles, no lookup and no no-source-profile (other checks unchanged)', () =>
    expect(confirmRow({ ...base, restsOnPassages: [P({})] })).not.toContain('no-source-profile'));
});
```

(`seat`, `text`, `kinds` and `P` are the fixtures `confirm.test.ts` already defines at its top; the default `P({})` is a clean record on `'s1'` whose `confirmRow` result is `[]`. Add `confirmRowDetailed` to its import from `./confirm.js`.)

In `codingReport.test.ts`, add one case using the existing unanimous-chair fixture (the D1 end-to-end pair test builds three identical coder files): pass `profiles: []` and a `snapshotUrl` mapping its snapshots to `https://nowhere.test/…`; expect the row's `confirm` to contain `'no-source-profile'`, `shadow` to be `'would-review'`, `profiles` to equal `[]`, and `report.noProfileHosts` to equal `{ 'nowhere.test': 1 }`. And the same call without `profiles` gives `row.profiles` equal `[]` and `noProfileHosts` equal `{}`.

- [ ] **Step 2: Run and confirm they FAIL**

Run: `npx vitest run scripts/lib/confirm.test.ts scripts/lib/codingReport.test.ts` — Expected: FAIL (`confirmRowDetailed` missing; unknown input fields).

- [ ] **Step 3: Implement**

`confirm.ts`:

```ts
import { resolveProfile, profileSeatChamber, profileTag, type SourceProfile } from './sourceProfiles.js';
import { checkRecordGroup, instrumentKey, seatChamber, type PassageProfile } from './recordBasis.js';
// ConfirmFinding: add | 'no-source-profile'

type ConfirmInput = {
  seat: SeatContext; restsOnPassages: Passage[]; snapshotText: ReadonlyMap<string, string>;
  sourceKind: ReadonlyMap<string, string>; rowServedRevisionId: string; bundleServedRevisionId: string;
  /** snapshot_id -> original URL (snapshots.json). Used only with `profiles`. */
  snapshotUrl?: ReadonlyMap<string, string>;
  /** Loaded source profiles. Given → every record passage must resolve one, else no-source-profile. */
  profiles?: readonly SourceProfile[];
};
export function confirmRow(i: ConfirmInput): ConfirmFinding[] { return confirmRowDetailed(i).findings; }
export function confirmRowDetailed(i: ConfirmInput): { findings: ConfirmFinding[]; profiles: string[] } {
  // ...existing body, unchanged except the record-group call below...
}
```

Inside the body, before the record groups:

```ts
const used = new Set<string>();
const profileOf = (p: Passage): PassageProfile | null => {
  if (!i.profiles) return null;
  const url = i.snapshotUrl?.get(p.snapshot_id);
  const prof = url ? resolveProfile(i.profiles, url) : null;
  if (!prof) { out.add('no-source-profile'); return null; }
  used.add(profileTag(prof));
  return { rules: prof.rules, chamber: profileSeatChamber(prof, i.seat.office_title) };
};
```

and pass `profileOf` to `checkRecordGroup({ …, chamber: seatChamber(i.seat.office_title), profileOf })`. `checkRecordGroup` calls `profileOf` for actor passages only; also call `profileOf(p)` once for **every** record passage in the group before `checkRecordGroup` (so a bill-text page with no profile is flagged too) — memoise per `snapshot_id` so each passage is resolved once. Return `{ findings: [...out], profiles: [...used].sort() }`.

`codingReport.ts`: add the two optional inputs; call `confirmRowDetailed({ …, snapshotUrl: i.snapshotUrl, profiles: i.profiles })`; set `row.profiles` from it (`[]` when CONFIRM did not run); build `noProfileHosts`: for each row whose `confirm` includes `'no-source-profile'`, for each record passage in its `restsOn` whose URL resolves no profile, count `new URL(url).host` (use `'(no url)'` when the URL is missing) — once per row per host.

`code-stance-batch.ts`: after `sourceKind`:

```ts
const snapshotUrl = new Map(snapshots.filter((s) => s.ok && s.snapshot_text).map((s) => [s.snapshot_id, s.url]));
const profiles = loadSourceProfiles();
```

pass `snapshotUrl, profiles` to `buildCodingReport`, and after the per-row print:

```ts
for (const [host, n] of Object.entries(report.noProfileHosts)) console.log(`no source profile: ${host} ×${n} — write docs/sources/… for it (spec 2026-09-26)`);
```

- [ ] **Step 4: Run the tests**

Run: `npx vitest run scripts/lib/confirm.test.ts scripts/lib/codingReport.test.ts scripts/lib/recordBasis.test.ts scripts/lib/sourceProfiles.test.ts scripts/lib/stancePublishPolicy.test.ts` — Expected: PASS. Direct tsc on `scripts/lib/confirm.ts scripts/lib/codingReport.ts scripts/code-stance-batch.ts`: exit 0.

- [ ] **Step 5: Commit** the five files — message `feat(confirm): resolve a source profile per record passage; no-source-profile fails closed; report profile@version and unmatched hosts`.

---

### Task 4: The first four profiles, their controls, and the collector step

**Files:**
- Create: `docs/sources/README.md`, `docs/sources/states/CA/leginfo-bill-votes.md`, `docs/sources/states/CA/leginfo-bill-text.md`, `docs/sources/states/IN/iga-roll-call.md`, `docs/sources/states/IN/iga-bill-details.md`
- Create: `backend/scripts/lib/sourceProfiles.real.test.ts`
- Modify: `.claude/skills/research-stances/SKILL.md` (SHADOW CODING step 1), `docs/superpowers/specs/2026-09-26-source-profiles-design.md` (add `bill-origin` to the rule-kind catalogue)

**Interfaces:**
- Consumes: everything above. Real snapshots in `backend/data/stance-research/2026-09-25-shadow-{durazo,yoder}/snapshots.json`.

- [ ] **Step 1: Write the failing test** `sourceProfiles.real.test.ts`:

```ts
/**
 * The real profiles in docs/sources: each loads, and each control runs on its real saved page with the
 * expected result. A profile with a failing control is a rule that does not match its own source.
 */
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { loadSourceProfiles, resolveProfile, profileSeatChamber } from './sourceProfiles.js';
import { checkRecordGroup, instrumentKey, seatChamber } from './recordBasis.js';
import type { Passage } from './coderLabel.js';

const batchDir = (b: string) => fileURLToPath(new URL(`../../data/stance-research/${b}/`, import.meta.url));
const snapshots = (b: string) => JSON.parse(readFileSync(`${batchDir(b)}snapshots.json`, 'utf8')) as { snapshot_id: string; url: string; ok: boolean; snapshot_text: string | null }[];
const profiles = loadSourceProfiles();
// Findings a control does not judge: they are about the content of a passage, not the page layout.
const CONTENT_FINDINGS = new Set(['provision-missing', 'near-unanimous-vote']);

describe('real source profiles', () => {
  it('there are at least the four first profiles', () =>
    expect(profiles.map((p) => p.profile).sort()).toEqual(expect.arrayContaining(['ca-leginfo-bill-text', 'ca-leginfo-bill-votes', 'in-iga-bill-details', 'in-iga-roll-call'])));
  for (const p of profiles) for (const [n, c] of p.controls.entries()) {
    it(`${p.file} control ${n}: ${c.snapshot} → ${c.expect}`, () => {
      const snap = snapshots(c.batch).find((s) => s.snapshot_id.startsWith(c.snapshot));
      expect(snap, `snapshot ${c.snapshot} in ${c.batch}`).toBeDefined();
      expect(resolveProfile(profiles, snap!.url)?.profile, 'the control page resolves to this profile').toBe(p.profile);
      const passage: Passage = { snapshot_id: snap!.snapshot_id, v1_attribution: 'own-act', v2_relevance: 'on-question', v3_class: 'record',
        v4_shape: 'chair-shaped', v5_time: 'in-term', instrument: c.instrument, record_kind: c.record_kind, actor_quote: c.actor_quote,
        tally_quote: c.tally_quote, provision_quote: null, date: null };
      const f = checkRecordGroup({ passages: [passage], snapshotText: new Map([[snap!.snapshot_id, snap!.snapshot_text ?? '']]), fullName: c.person,
        chamber: null, profileOf: () => ({ rules: p.rules, chamber: profileSeatChamber(p, c.office_title) }) }).findings.filter((x) => !CONTENT_FINDINGS.has(x));
      if (c.expect === 'pass') expect(f).toEqual([]); else expect(f).toContain(c.expect);
    });
  }
});

describe('the two shadow batches under their profiles', () => {
  for (const [b, name] of [['2026-09-25-shadow-yoder', 'Shelli Yoder'], ['2026-09-25-shadow-durazo', 'Maria Elena Durazo']] as const) {
    it(`${b}: every record group gives the same findings as the generic rules, and every record page has a profile`, () => {
      const snaps = snapshots(b).filter((s) => s.ok);
      const text = new Map(snaps.map((s) => [s.snapshot_id, s.snapshot_text ?? '']));
      const url = new Map(snaps.map((s) => [s.snapshot_id, s.url]));
      for (const slot of [1, 2, 3]) {
        const rows = JSON.parse(readFileSync(`${batchDir(b)}labels/coder-${slot}.json`, 'utf8')).rows as { passages?: Passage[] }[];
        for (const r of rows) {
          const groups = new Map<string, Passage[]>();
          for (const p of r.passages ?? []) if (p.v3_class === 'record') { const k = instrumentKey(p.instrument) ?? '∅'; groups.set(k, [...(groups.get(k) ?? []), p]); }
          for (const g of groups.values()) {
            for (const p of g) expect(resolveProfile(profiles, url.get(p.snapshot_id) ?? ''), `profile for ${url.get(p.snapshot_id)}`).not.toBeNull();
            const generic = checkRecordGroup({ passages: g, snapshotText: text, fullName: name, chamber: seatChamber('Senator') }).findings.sort();
            const profiled = checkRecordGroup({ passages: g, snapshotText: text, fullName: name, chamber: seatChamber('Senator'),
              profileOf: (p) => { const pr = resolveProfile(profiles, url.get(p.snapshot_id) ?? '')!; return { rules: pr.rules, chamber: profileSeatChamber(pr, 'Senator') }; } }).findings.sort();
            expect(profiled).toEqual(generic);
          }
        }
      }
    });
  }
});

describe('coders never see profiles', () => {
  it('build-coder-inputs.ts and coderPrompt.ts do not read docs/sources or sourceProfiles', () => {
    for (const f of ['../build-coder-inputs.ts', './coderPrompt.ts']) {
      const src = readFileSync(fileURLToPath(new URL(f, import.meta.url)), 'utf8');
      expect(src, f).not.toMatch(/docs\/sources|sourceProfiles/);
    }
  });
});
```


- [ ] **Step 2: Run and confirm it FAILS**

Run: `npx vitest run scripts/lib/sourceProfiles.real.test.ts` — Expected: FAIL (no profiles in `docs/sources`).

- [ ] **Step 3: Write the four profiles and the README.**

`docs/sources/states/CA/leginfo-bill-votes.md`:

```markdown
---
profile: ca-leginfo-bill-votes
version: 1
scope: state:CA
body: legislature
match:
  url_prefixes:
    - https://leginfo.legislature.ca.gov/faces/billVotesClient.xhtml
page_kind: vote
rules:
  vote_block: aye-count
  chamber: word-before-floor
  name_format: surname
seat_titles:
  Senator: upper
  State Senator: upper
  Assembly Member: lower
  Assemblymember: lower
controls:
  - batch: 2026-09-25-shadow-durazo
    snapshot: aa219c5b
    person: Maria Elena Durazo
    office_title: Senator
    instrument: SB 1174 (2023-2024)
    record_kind: vote
    actor_quote: "Cortese, Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 30 Noes Count 8 NVR Count 2"
    expect: pass
  - batch: 2026-09-25-shadow-durazo
    snapshot: 8666d0a3
    person: Maria Elena Durazo
    office_title: Senator
    instrument: AB 1955 (2023-2024)
    record_kind: vote
    actor_quote: "Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 29 Noes Count 8 NVR Count 3"
    expect: pass
  - batch: 2026-09-25-shadow-durazo
    snapshot: f3a91fb1
    person: Maria Elena Durazo
    office_title: Senator
    instrument: SB 57 (2025-2026)
    record_kind: vote
    actor_quote: "Cervantes, Cortese, Durazo, Grayson"
    tally_quote: "Ayes Count 29 Noes Count 8 NVR Count 3"
    expect: pass
  - batch: 2026-09-25-shadow-durazo
    snapshot: aa219c5b
    person: Maria Elena Durazo
    office_title: Assembly Member
    instrument: SB 1174 (2023-2024)
    record_kind: vote
    actor_quote: "Cortese, Dodd, Durazo, Eggman"
    tally_quote: "Ayes Count 30 Noes Count 8 NVR Count 2"
    expect: chamber-not-evidenced
---
# California Legislature — bill votes (leginfo)

**Page:** `billVotesClient.xhtml?bill_id=<session><bill>` — every recorded floor and committee vote on
one bill, newest first. Each vote starts `Date … Result … Location <Chamber> Floor | <Committee>`, then
`Ayes Count N Noes Count N NVR Count N`, the motion, and the Ayes / Noes / NVR name lists.

**Access:** robots-disallowed. Code does not fetch it. Save it from a real browser into
`<batch>/human-saved/` (`fetched_by = human`, `source_kind = public-record`).

**What it proves:** how a named member voted on one motion. It does **not** carry the bill text — pair it
with the bill-text page (`leginfo-bill-text`) in one record group (codebook V3, two-passage vote).

**Traps:**
- `Motion Assembly 3rd Reading` on a **Senate** floor vote names the bill's house of origin. The chamber
  is the word before `Floor` (rule `word-before-floor`).
- One page prints several votes (floor, concurrence, committee). Copy the `tally_quote` from the **same**
  vote as the `actor_quote`, or CONFIRM reports `tally-other-vote`.
- Members print by surname only; the same member appears once per vote.
- Committee votes (`Location` = a committee) are not floor votes; treat them as a separate vote.
```

`docs/sources/states/CA/leginfo-bill-text.md`:

```markdown
---
profile: ca-leginfo-bill-text
version: 1
scope: state:CA
body: legislature
match:
  url_prefixes:
    - https://leginfo.legislature.ca.gov/faces/billNavClient.xhtml
    - https://leginfo.legislature.ca.gov/faces/billTextClient.xhtml
page_kind: bill-text
rules:
  vote_block: whole-page
  chamber: bill-origin
  name_format: surname
seat_titles:
  Senator: upper
  State Senator: upper
  Assembly Member: lower
  Assemblymember: lower
controls:
  - batch: 2026-09-25-shadow-durazo
    snapshot: fb096408
    person: Maria Elena Durazo
    office_title: Senator
    instrument: SB 580 (2025-2026)
    record_kind: author
    actor_quote: "SB 580, Durazo."
    tally_quote: null
    expect: pass
---
# California Legislature — bill text (leginfo)

**Page:** `billNavClient.xhtml?bill_id=…` (bill text, with the Legislative Counsel's Digest).

**Access:** fetchable by code.

**What it proves:** the provision (quote it as `provision_quote`), and the **primary author**: the
Digest opens `SB 580, Durazo.` The primary author sits in the bill's house of origin, so the chamber
comes from the bill prefix (rule `bill-origin`: SB → Senate, AB → Assembly). Co-authors listed further
down may sit in either house — do not use them as an actor line.

**Traps:** the text shown is the latest amended version; cite the version in force at the vote you pair
it with.
```

`docs/sources/states/IN/iga-roll-call.md`:

```markdown
---
profile: in-iga-roll-call
version: 1
scope: state:IN
body: legislature
match:
  url_prefixes:
    - https://iga.in.gov/pdf-documents/
page_kind: vote
rules:
  vote_block: aye-count
  chamber: page-header
  name_format: surname-initial
seat_titles:
  Senator: upper
  State Senator: upper
  Representative: lower
  State Representative: lower
controls:
  - batch: 2026-09-25-shadow-yoder
    snapshot: 6024804d
    person: Shelli Yoder
    office_title: Senator
    instrument: HB 1041 (2025)
    record_kind: vote
    actor_quote: "N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder"
    tally_quote: "Yea 42 Student eligibility in interscholastic sports. Nay 6"
    expect: pass
  - batch: 2026-09-25-shadow-yoder
    snapshot: 6024804d
    person: Shelli Yoder
    office_title: State Representative
    instrument: HB 1041 (2025)
    record_kind: vote
    actor_quote: "N AY - 6 Ford J.D. Jackson Qaddoura Spencer Hunley Yoder"
    tally_quote: "Yea 42 Student eligibility in interscholastic sports. Nay 6"
    expect: chamber-not-evidenced
---
# Indiana General Assembly — roll call (PDF)

**Page:** `pdf-documents/<ga>/<year>/<house|senate>/bills/<BILL>/rollcalls/<BILL>.<n>_<H|S>.pdf` — one
roll call. The first line names the chamber (`Senate` / `House`), then the session, `GENERAL ASSEMBLY`,
the date, `Roll Call <n>`, the motion and `Yea N … Nay N`, then the YEA / NAY / EXCUSED / NOT VOTING lists.

**Access:** the PDF link opens from the bill page, which is JavaScript-only. Ask the operator before any
download (it shows a save dialog); read the saved file's text.

**What it proves:** how a named member voted on one roll call. Pair it with the bill page or bill text.

**Traps:**
- `GENERAL ASSEMBLY` is the whole legislature, not the House. The chamber is the page header (rule
  `page-header`). The `_S` / `_H` file suffix agrees with it.
- Shared surnames print with an initial after them (`Walker G`, `Walker K`) — rule `surname-initial`.
- The PDF text splits some words (`Y EA`, `N AY`); copy the words as the text shows them.
```

`docs/sources/states/IN/iga-bill-details.md`:

```markdown
---
profile: in-iga-bill-details
version: 1
scope: state:IN
body: legislature
match:
  url_prefixes:
    - https://iga.in.gov/legislative/
page_kind: author
rules:
  vote_block: whole-page
  chamber: nearest-before
  name_format: surname
seat_titles:
  Senator: upper
  State Senator: upper
  Representative: lower
  State Representative: lower
controls:
  - batch: 2026-09-25-shadow-yoder
    snapshot: d9257546
    person: Shelli Yoder
    office_title: Senator
    instrument: SB 208 (2024)
    record_kind: author
    actor_quote: "Authored by: Sen. Shelli Yoder"
    tally_quote: null
    expect: pass
---
# Indiana General Assembly — bill details (iga)

**Page:** `iga.in.gov/legislative/<year>/bills/<senate|house>/<n>/details` — title, digest, and the
author line `Authored by: Sen. Shelli Yoder, Sen. Vaneta Becker`, then co-authors and sponsors.

**Access:** JavaScript-only. Code cannot fetch it. Save it from a real browser into
`<batch>/human-saved/`.

**What it proves:** authorship (the author line) and the digest. It does not prove a vote — the roll
calls are separate PDFs (`in-iga-roll-call`).

**Traps:** the chamber is the title inside the author line (`Sen.` / `Rep.`), read back from the surname
(rule `nearest-before`). `Indiana General Assembly 2024 Session` is not a chamber.
```

Before writing these files: **verify every control's `actor_quote` and `tally_quote` are verbatim on its snapshot** (grep the `snapshot_text` in the batch's `snapshots.json`); if a quote differs, copy the page's exact words. Do not change a rule kind to make a control pass without saying why in the report.

`docs/sources/README.md`: a short page with
1. what a profile is and who reads which part (table from the spec's Approach);
2. how to add one: copy the template below, pick rule kinds from the catalogue, add at least one real saved page as an `expect: pass` control (and, where the page has a trap, one negative control), run `npx vitest run scripts/lib/sourceProfiles.real.test.ts` from `backend/`;
3. the rule-kind catalogue (the spec's table, plus `bill-origin`: "the chamber comes from the bill prefix — SB → upper, AB/HB → lower; for a primary author on a bill page");
4. the template header (copy of the CA votes header with placeholder values like `<profile-id>`);
5. the rule: bump `version` on any header change; the coding report records `profile@version`.

- [ ] **Step 4: Update the spec catalogue** — in `docs/superpowers/specs/2026-09-26-source-profiles-design.md`, add a `bill-origin` row under `chamber` ("the bill prefix: SB → upper, AB/HB → lower — the primary author on a bill page (CA Digest)"), and add `bill-origin` to the header comment line `# word-before-floor | nearest-before | page-header | none`.

- [ ] **Step 5: Update the SKILL** — in `.claude/skills/research-stances/SKILL.md`, SHADOW CODING step 1, add a sub-bullet:
  "Before collecting, read the source profiles for the jurisdiction in `docs/sources/` (access notes, which page proves what, traps). A record page from a source with no profile gets `no-source-profile` in CONFIRM: write the profile from `docs/sources/README.md`, with the saved page as an `expect: pass` control, in the same batch."

- [ ] **Step 6: Run the tests**

Run: `npx vitest run scripts/lib/sourceProfiles.real.test.ts scripts/lib/sourceProfiles.test.ts scripts/lib/recordBasis.test.ts scripts/lib/confirm.test.ts scripts/lib/codingReport.test.ts scripts/lib/coderPrompt.test.ts scripts/lib/stancePublishPolicy.test.ts` — Expected: PASS.
Then re-run both reports (read-only):
`ADMIN_INGEST_TOKEN=x npm run -s coding:report -- --dir data/stance-research/2026-09-25-shadow-<yoder|durazo> --season-id 86d893a1-c1a2-4bbf-b4e5-69ec43221194 --models "opus,sonnet,sonnet"`
Expected: no `no source profile:` line; `coding-report.json` differs from HEAD only by the new `profiles` / `noProfileHosts` fields (check with `git diff --stat` and read the diff).

- [ ] **Step 7: Commit** the five `docs/sources` files, `sourceProfiles.real.test.ts`, the SKILL, the spec, and the two re-run `coding-report.json` files — message `feat(sources): first four source profiles (CA leginfo votes + text, IN iga roll call + details) with real-page controls`.
