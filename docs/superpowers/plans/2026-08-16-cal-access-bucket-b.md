# Cal-Access Bucket B Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan
> task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> ⚠ **This repo has a standing operator rule: NO SUBAGENTS.** Do not use
> superpowers:subagent-driven-development here. MCP tools are not bound inside subagents, and every
> SQL statement in this plan runs through the supabase MCP.

**Goal:** Remove misattributed Cal-Access committee links and their money from active politicians'
profiles, keeping every link that can be affirmatively tied to the right person.

**Architecture:** Two independent tracks. Track A hand-verifies the ~25 money-bearing links that need
evidence against the Cal-Access filer record (the primary source), covering 94.4% of $41.5M. Track B
applies a mechanical prove-it-right rule to the ~7,270 zero-dollar remainder. Each track ends in one
DML migration with content guards. Track A ships first and gates Track B.

**Tech Stack:** PostgreSQL (Supabase) via `mcp__supabase-local__execute_sql`; TypeScript one-off
scripts run with `npx tsx` from `backend/`; Playwright (already a `backend` dependency) for the
Cal-Access fetch; migrations applied with `npx tsx scripts/_apply-file.ts`.

**Spec:** `docs/superpowers/specs/2026-08-16-cal-access-bucket-b-design.md`

## Global Constraints

- **Posture: prove-it-right.** Keep only links affirmatively tied to the politician. Unprovable comes
  down. (Operator decision, 2026-08-16.)
- **Demote, never delete, a wrong link:** `research_status = 'not_applicable'` plus a WRONG PERSON
  note appended to `notes`. The notes are the only provenance of how the tangle arose.
- **`contribution_summary_agg` is a real TABLE, not a view.** Whenever contributions are deleted, its
  rows must be deleted too, or the UI keeps displaying money whose contributions are gone.
- **Never `count(*)` `transparent_motivations.contributions`.** It blows the statement timeout. Scope
  every assertion to affected ids.
- **Never `IN (SELECT ... FROM <temp table>)` against `contributions`.** A fresh temp table has no
  statistics and the planner seq-scans. Write ids INLINE; keep the temp table and assert the two agree.
- **Use `contribution_summary_agg` for all money questions.** Aggregates over `contributions` time out.
- **Verify on row counts after applying, never on the apply script's "OK".**
- **Re-check the migration number immediately before `git commit`:** `node
  backend/scripts/check-migration-numbers.mjs`. Never take a number from the local checkout.
- **Migration numbers in this plan (1790, 1791) are placeholders for the number the checker reports.**
  If it differs, rename the file and update the header comment, the note text, and the guard strings.
- Guards must assert content — per-branch counts, a phrase from the note, and that the KEEP set
  survived with its dollar total unchanged.
- Every count in this plan was measured 2026-08-16. **Task 1 re-measures; if the numbers moved, stop
  and report before continuing.**

---

### Task 1: Build the Track A worklist

**Files:**
- Create: `backend/scripts/cal-access-bucket-b/01-build-worklist.ts`
- Create (output): `backend/data/cal-access-bucket-b/worklist.json`

**Interfaces:**
- Consumes: nothing.
- Produces: `worklist.json` — an array of
  `{ source_id: string, filer_id: string, politician_id: string, politician_name: string,
     first_name: string, last_name: string, committee_name: string, dollars: number, rank: number,
     verdict: 'names-them' | 'needs-evidence' | 'no-committee-name' }`.
  Tasks 2 and 3 read this file.

- [ ] **Step 1: Write the script**

```ts
// backend/scripts/cal-access-bucket-b/01-build-worklist.ts
// Builds the Track A worklist: the top-N money-bearing cal_access links on active politicians whose
// last full_name token IS their stored surname (bucket B), classified by whether the committee name
// names the politician.
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

const TOP_N = Number(process.env.TOP_N ?? 50);
const OUT_DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');

const SQL = `
WITH b AS (
  SELECT ps.id AS source_id, ps.external_id AS filer_id, p.id AS politician_id,
         p.full_name AS politician_name,
         coalesce(p.first_name,'') AS first_name, coalesce(p.last_name,'') AS last_name,
         coalesce(substring(ps.notes from '"committee_name"\\s*:\\s*"([^"]{0,200})'),'') AS committee_name,
         round(coalesce(sum(g.total_amount),0)::numeric,2) AS dollars
    FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
    LEFT JOIN transparent_motivations.contribution_summary_agg g ON g.politician_source_id = ps.id
   WHERE ps.source_system = 'cal_access'
     AND p.is_active
     AND lower(regexp_replace(p.full_name,'^.*\\s','')) = lower(coalesce(p.last_name,''))
   GROUP BY ps.id, ps.external_id, p.id, p.full_name, p.first_name, p.last_name, ps.notes
)
SELECT *, row_number() OVER (ORDER BY dollars DESC) AS rank
  FROM b
 WHERE dollars > 0
 ORDER BY dollars DESC
 LIMIT $1;
`;

function verdictFor(row: any): string {
  const cmt = String(row.committee_name || '').toLowerCase();
  if (cmt === '') return 'no-committee-name';
  const given = String(row.first_name || '').trim().split(/\s+/)[0].toLowerCase();
  if (given && new RegExp('\\m' + given.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\M').test(cmt)) {
    return 'names-them';
  }
  return 'needs-evidence';
}

async function main() {
  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL is not set'); process.exit(1); }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows } = await pool.query(SQL, [TOP_N]);
  await pool.end();

  const out = rows.map(r => ({
    source_id: r.source_id, filer_id: r.filer_id, politician_id: r.politician_id,
    politician_name: r.politician_name, first_name: r.first_name, last_name: r.last_name,
    committee_name: r.committee_name, dollars: Number(r.dollars), rank: Number(r.rank),
    verdict: verdictFor(r),
  }));

  fs.mkdirSync(OUT_DIR, { recursive: true });
  fs.writeFileSync(path.join(OUT_DIR, 'worklist.json'), JSON.stringify(out, null, 2));

  const tally: Record<string, { n: number; dollars: number }> = {};
  for (const r of out) {
    tally[r.verdict] ??= { n: 0, dollars: 0 };
    tally[r.verdict].n++; tally[r.verdict].dollars += r.dollars;
  }
  console.log(`wrote ${out.length} rows to ${path.join(OUT_DIR, 'worklist.json')}`);
  for (const [k, v] of Object.entries(tally)) console.log(`  ${k}: ${v.n} links, $${v.dollars.toFixed(2)}`);
  console.log(`  TOTAL: $${out.reduce((a, r) => a + r.dollars, 0).toFixed(2)}`);
}
main();
```

- [ ] **Step 2: Run it**

```bash
cd "C:/EV-Accounts/backend" && npx tsx scripts/cal-access-bucket-b/01-build-worklist.ts
```

Expected, matching the 2026-08-16 audit:
```
  names-them: 25 links, $12910204.29
  needs-evidence: 22 links, $15114125.88
  no-committee-name: 3 links, $11110485.57
  TOTAL: $39134815.74
```

- [ ] **Step 3: Check the numbers against the spec**

If `names-them + needs-evidence + no-committee-name` is not 50, or TOTAL is not within a few dollars
of $39,134,815.74, **STOP and report**. Something moved since the audit and the plan's assumptions
need re-checking before any purge.

- [ ] **Step 4: Commit**

```bash
cd "C:/EV-Accounts" && git add backend/scripts/cal-access-bucket-b/01-build-worklist.ts backend/data/cal-access-bucket-b/worklist.json && git commit -m "chore(cal-access): build Track A worklist — top 50 money links by verdict"
```

---

### Task 2: Fetch the official committee name for every link needing evidence

**Files:**
- Create: `backend/scripts/cal-access-bucket-b/02-fetch-filers.ts`
- Create (output): `backend/data/cal-access-bucket-b/filer-records.json`

**Interfaces:**
- Consumes: `worklist.json` from Task 1.
- Produces: `filer-records.json` — `{ [filer_id: string]: { official_name: string, fetched_at: string,
  status: 'ok' | 'not-found' | 'error', error?: string } }`. Task 3 reads this file.

🔴 **Incapsula blocks a cold request.** `curl` returns a 212-byte stub and a direct Playwright hit on
the detail URL returns an empty body. You MUST load `https://cal-access.sos.ca.gov/` first in the same
browser context to clear the challenge, then navigate to each detail page. Verified on filer 1414018.

- [ ] **Step 1: Write the script**

```ts
// backend/scripts/cal-access-bucket-b/02-fetch-filers.ts
// Fetches the OFFICIAL registered committee name for each filer needing evidence.
// The Cal-Access filer record is the primary source -- the field confirm-cal-access.ts should have
// used instead of guessing from a name token.
import * as fs from 'fs';
import * as path from 'path';
import { chromium } from 'playwright';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');
const HOME = 'https://cal-access.sos.ca.gov/';
const DETAIL = (id: string) => `https://cal-access.sos.ca.gov/Campaign/Committees/Detail.aspx?id=${id}`;

async function main() {
  const worklist = JSON.parse(fs.readFileSync(path.join(DIR, 'worklist.json'), 'utf8'));
  const targets = worklist.filter((r: any) => r.verdict !== 'names-them');
  console.log(`fetching ${targets.length} filer records`);

  const browser = await chromium.launch();
  const page = await browser.newPage();

  // Clear the Incapsula challenge once. A cold hit on a detail URL returns an empty body.
  await page.goto(HOME, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2000);

  const out: Record<string, any> = {};
  for (const r of targets) {
    try {
      await page.goto(DETAIL(r.filer_id), { waitUntil: 'domcontentloaded' });
      await page.waitForTimeout(1200);
      const text = (await page.evaluate(() => document.body.innerText || '')).replace(/[ \t]+/g, ' ');
      // The official name appears after the "Campaign Finance:" heading and again in
      // "SUMMARY INFORMATION - <NAME> (ID# <filer>)". The latter is the more reliable anchor.
      const m = text.match(/SUMMARY INFORMATION\s*-\s*(.+?)\s*\(ID#/i);
      const official = m ? m[1].trim() : '';
      out[r.filer_id] = official
        ? { official_name: official, fetched_at: new Date().toISOString(), status: 'ok' }
        : { official_name: '', fetched_at: new Date().toISOString(), status: 'not-found' };
      console.log(`  ${r.filer_id}  ${out[r.filer_id].status.padEnd(9)}  ${official || '(none)'}`);
    } catch (e: any) {
      out[r.filer_id] = { official_name: '', fetched_at: new Date().toISOString(), status: 'error', error: String(e.message ?? e) };
      console.log(`  ${r.filer_id}  ERROR  ${e.message ?? e}`);
    }
    await page.waitForTimeout(800); // be polite to a government host
  }

  await browser.close();
  fs.writeFileSync(path.join(DIR, 'filer-records.json'), JSON.stringify(out, null, 2));
  const ok = Object.values(out).filter((v: any) => v.status === 'ok').length;
  console.log(`\n${ok} of ${targets.length} resolved`);
}
main();
```

- [ ] **Step 2: Run it**

```bash
cd "C:/EV-Accounts/backend" && npx tsx scripts/cal-access-bucket-b/02-fetch-filers.ts
```

Expected: ~25 lines, most `ok`. Filer `1414018` must resolve to `NEWSOM FOR CALIFORNIA GOVERNOR 2022`
— that is the known-good control. If it does not, the parse anchor is wrong; fix it before continuing.

- [ ] **Step 3: Handle failures**

If more than ~3 come back `error` or `not-found`, the WAF is likely throttling. Raise the
`waitForTimeout` after each page to 3000ms and re-run — the script overwrites the whole file, so
re-running is safe. If the site blocks sustained access entirely, **STOP and report**; the spec's
fallback is per-link judgment on committee name plus office and era, recorded as a weaker basis.

- [ ] **Step 4: Commit**

```bash
cd "C:/EV-Accounts" && git add backend/scripts/cal-access-bucket-b/02-fetch-filers.ts backend/data/cal-access-bucket-b/filer-records.json && git commit -m "chore(cal-access): fetch official filer names for Track A evidence"
```

---

### Task 3: Classify Track A and generate the migration

**Files:**
- Create: `backend/scripts/cal-access-bucket-b/03-classify-track-a.ts`
- Create (output): `backend/data/cal-access-bucket-b/track-a-decisions.json`
- Create (output): `backend/migrations/1790_cal_access_track_a.sql` ← **re-check the number**

**Interfaces:**
- Consumes: `worklist.json`, `filer-records.json`.
- Produces: `track-a-decisions.json` — each worklist row plus
  `{ decision: 'keep' | 'purge', basis: string, official_name: string }` — and the migration file.

**The decision rule.** For each link needing evidence, compare the *official* name to the politician:
- official name contains their `last_name` AND their `first_name` (or a diminutive) → **keep**
- official name contains a different person's name → **purge**
- official name unavailable, or names only the surname → **purge** (prove-it-right)
Every `names-them` row from Task 1 is an automatic **keep** and is not fetched.

- [ ] **Step 1: Write the classifier**

```ts
// backend/scripts/cal-access-bucket-b/03-classify-track-a.ts
import * as fs from 'fs';
import * as path from 'path';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');
const MIGRATION_NUMBER = process.env.MIGRATION_NUMBER ?? '1790';

const DIMINUTIVES: Record<string, string[]> = {
  robert: ['bob', 'rob', 'bobby'], james: ['jim', 'jimmy'], william: ['bill', 'will', 'billy'],
  richard: ['rick', 'dick', 'rich'], michael: ['mike'], joseph: ['joe'], thomas: ['tom'],
  charles: ['chuck', 'charlie'], daniel: ['dan', 'danny'], christopher: ['chris'],
  elizabeth: ['liz', 'beth', 'betty'], katherine: ['kate', 'kathy', 'katie'], kathryn: ['kate', 'kathy'],
  patricia: ['pat', 'patty'], jennifer: ['jen', 'jenny'], deborah: ['deb', 'debbie'],
  susan: ['sue'], margaret: ['peggy', 'maggie'], anthony: ['tony'], nicholas: ['nick'],
  benjamin: ['ben'], alexander: ['alex'], gregory: ['greg'], steven: ['steve'], stephen: ['steve'],
  edward: ['ed', 'eddie'], ronald: ['ron'], donald: ['don'], kenneth: ['ken'], jose: ['pepe'],
};

const esc = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const hasWord = (hay: string, needle: string) =>
  needle.length > 0 && new RegExp('\\b' + esc(needle) + '\\b', 'i').test(hay);

function namesThem(official: string, first: string, last: string): boolean {
  const o = official.toLowerCase();
  const given = first.trim().split(/\s+/)[0].toLowerCase();
  const surname = last.trim().toLowerCase();
  if (!hasWord(o, surname)) return false;
  if (hasWord(o, given)) return true;
  for (const d of DIMINUTIVES[given] ?? []) if (hasWord(o, d)) return true;
  return false;
}

const worklist = JSON.parse(fs.readFileSync(path.join(DIR, 'worklist.json'), 'utf8'));
const filers = JSON.parse(fs.readFileSync(path.join(DIR, 'filer-records.json'), 'utf8'));

const decisions = worklist.map((r: any) => {
  if (r.verdict === 'names-them') {
    return { ...r, decision: 'keep', basis: 'committee name in our DB already names them', official_name: r.committee_name };
  }
  const rec = filers[r.filer_id];
  const official = rec?.status === 'ok' ? rec.official_name : '';
  if (!official) {
    return { ...r, decision: 'purge', basis: `no official record retrievable (${rec?.status ?? 'missing'}); unprovable`, official_name: '' };
  }
  if (namesThem(official, r.first_name, r.last_name)) {
    return { ...r, decision: 'keep', basis: `official Cal-Access name "${official}" names them`, official_name: official };
  }
  return { ...r, decision: 'purge', basis: `official Cal-Access name "${official}" does not name them`, official_name: official };
});

fs.writeFileSync(path.join(DIR, 'track-a-decisions.json'), JSON.stringify(decisions, null, 2));

const purge = decisions.filter((d: any) => d.decision === 'purge');
const keep  = decisions.filter((d: any) => d.decision === 'keep');
const money = (rows: any[]) => rows.reduce((a, r) => a + r.dollars, 0);
const withMoney = purge.filter((d: any) => d.dollars > 0);

console.log(`keep  ${keep.length} links  $${money(keep).toFixed(2)}`);
console.log(`purge ${purge.length} links  $${money(purge).toFixed(2)}`);
console.log(`wrong-rate: ${(100 * purge.length / decisions.length).toFixed(1)}% of the top ${decisions.length}`);
for (const p of purge) console.log(`  PURGE  $${p.dollars.toFixed(2).padStart(12)}  ${p.politician_name}  <-  ${p.official_name || '(no official record)'}`);

// ── generate the migration ────────────────────────────────────────────────────
const lit = (ids: string[]) => ids.map(i => `'${i}'`).join(',\n   ');
const purgeIds = purge.map((d: any) => d.source_id);
const moneyIds = withMoney.map((d: any) => d.source_id);
const keepIds  = keep.map((d: any) => d.source_id);
const purgeDollars = money(purge).toFixed(2);
const keepDollars  = money(keep).toFixed(2);

const sql = `-- ${MIGRATION_NUMBER}_cal_access_track_a.sql
-- Cal-Access bucket B, Track A: the money. Verified against the OFFICIAL Cal-Access filer record.
--
-- Spec: docs/superpowers/specs/2026-08-16-cal-access-bucket-b-design.md
-- Decisions, with the official name and basis for every link: backend/data/cal-access-bucket-b/track-a-decisions.json
--
-- confirm-cal-access.ts linked committees on the LAST TOKEN of full_name and confirmed its own
-- guesses in the same pass (7,836 of 7,853 "confirmed"). Bucket A (migration 1789) cleared the links
-- where that token was not even the surname. This is the money half of what remained: the top
-- ${decisions.length} links by displayed dollars, which carry 94.4% of all cal_access money.
--
-- Each link needing evidence was resolved by fetching its Cal-Access filer record and reading the
-- OFFICIAL registered committee name -- the field the script should have used. Keep when that name
-- carries both the politician's surname and their given name (or a diminutive); purge otherwise,
-- including when no official record could be retrieved. That is the operator's prove-it-right posture.
--
-- KEEP  ${keep.length} links  $${keepDollars}
-- PURGE ${purge.length} links  $${purgeDollars}
BEGIN;

CREATE TEMP TABLE ta_purge (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO ta_purge (sid) VALUES
  ${purgeIds.map((i: string) => `('${i}')`).join(',\n  ')};

CREATE TEMP TABLE ta_keep (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO ta_keep (sid) VALUES
  ${keepIds.map((i: string) => `('${i}')`).join(',\n  ')};

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM ta_purge;
  IF n <> ${purge.length} THEN RAISE EXCEPTION 'pre-check: purge set is %, expected ${purge.length}', n; END IF;
  SELECT count(*) INTO n FROM ta_keep;
  IF n <> ${keep.length} THEN RAISE EXCEPTION 'pre-check: keep set is %, expected ${keep.length}', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ta_purge p ON p.sid = ps.id
   WHERE ps.source_system <> 'cal_access';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % purge target(s) are not cal_access links', n; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ta_purge p ON p.sid = g.politician_source_id;
  IF d <> ${purgeDollars} THEN RAISE EXCEPTION 'pre-check: purge set displays %, expected ${purgeDollars}', d; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ta_keep k ON k.sid = g.politician_source_id;
  IF d <> ${keepDollars} THEN RAISE EXCEPTION 'pre-check: keep set displays %, expected ${keepDollars}', d; END IF;
END $$;

-- Money, by INLINE literal ids. \`IN (SELECT ... FROM <temp>)\` seq-scans contributions and times out.
DELETE FROM transparent_motivations.contributions
 WHERE politician_source_id IN (
   ${lit(moneyIds)});

DELETE FROM transparent_motivations.contribution_summary_agg
 WHERE politician_source_id IN (
   ${lit(moneyIds)});

UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'not_applicable',
       notes = coalesce(ps.notes,'') || ' | WRONG PERSON (migration ${MIGRATION_NUMBER}, 2026-08-16):'
               || ' checked against the official Cal-Access filer record; that committee does not name'
               || ' this politician. See backend/data/cal-access-bucket-b/track-a-decisions.json.',
       updated_at = now()
  FROM ta_purge p
 WHERE ps.id = p.sid;

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM transparent_motivations.contribution_summary_agg g JOIN ta_purge p ON p.sid = g.politician_source_id;
  IF n <> 0 THEN RAISE EXCEPTION 'guard: % agg row(s) still on purged links', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.contributions c
   WHERE c.politician_source_id IN (
     ${lit(moneyIds)});
  IF n <> 0 THEN RAISE EXCEPTION 'guard: % contribution(s) still on purged links', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ta_purge p ON p.sid = ps.id
   WHERE ps.research_status = 'not_applicable' AND ps.notes LIKE '%WRONG PERSON (migration ${MIGRATION_NUMBER}%';
  IF n <> ${purge.length} THEN RAISE EXCEPTION 'guard: % of ${purge.length} purged links demoted with a note', n; END IF;

  -- The keeps are the point of doing evidence work. Assert they survived UNCHANGED -- a bug that
  -- widened the purge satisfies every check above.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ta_keep k ON k.sid = ps.id
   WHERE ps.research_status = 'confirmed';
  IF n <> ${keep.length} THEN RAISE EXCEPTION 'guard: % of ${keep.length} kept links still confirmed', n; END IF;
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ta_keep k ON k.sid = g.politician_source_id;
  IF d <> ${keepDollars} THEN RAISE EXCEPTION 'guard: kept money is now %, expected ${keepDollars} untouched', d; END IF;

  RAISE NOTICE 'cal_access Track A: ${purge.length} links purged ($${purgeDollars}), ${keep.length} kept ($${keepDollars})';
END $$;

COMMIT;
`;

fs.writeFileSync(path.join(process.cwd(), 'migrations', `${MIGRATION_NUMBER}_cal_access_track_a.sql`), sql);
console.log(`\nwrote migrations/${MIGRATION_NUMBER}_cal_access_track_a.sql`);
```

- [ ] **Step 2: Get the real migration number, then run**

```bash
cd "C:/EV-Accounts" && git fetch origin master --quiet && node backend/scripts/check-migration-numbers.mjs
cd "C:/EV-Accounts/backend" && MIGRATION_NUMBER=<the next free number> npx tsx scripts/cal-access-bucket-b/03-classify-track-a.ts
```

Expected: a keep/purge split, a wrong-rate percentage, and one PURGE line per link naming the official
committee. Read every PURGE line. Any that looks wrong means the rule or the fetch is wrong — fix it
before applying.

- [ ] **Step 3: Sanity-check the two controls**

- Newsom's filer `1414018` (`NEWSOM FOR CALIFORNIA GOVERNOR 2022`) must be a **keep**.
- If `BONTA FOR ASSEMBLY 2024; MIA` appears in the top 50, it must be a **purge**.
If either is wrong, stop and fix the classifier.

- [ ] **Step 4: Commit the script and the decisions (not yet applied)**

```bash
cd "C:/EV-Accounts" && git add backend/scripts/cal-access-bucket-b/03-classify-track-a.ts backend/data/cal-access-bucket-b/track-a-decisions.json && git commit -m "chore(cal-access): classify Track A against official filer records"
```

---

### Task 4: Apply Track A, verify, ship

**Files:**
- Modify: none (applies `backend/migrations/<N>_cal_access_track_a.sql`)

**Interfaces:**
- Consumes: the migration from Task 3.
- Produces: a purged database and a pushed commit.

- [ ] **Step 1: Apply**

```bash
cd "C:/EV-Accounts/backend" && npx tsx scripts/_apply-file.ts migrations/<N>_cal_access_track_a.sql
```

Expected: `Applied ... OK`. If it times out, a `contributions` scan slipped in — check that every
reference uses inline literals, not the temp table.

- [ ] **Step 2: Verify on row counts, not on "OK"**

Run via `mcp__supabase-local__execute_sql`:

```sql
SELECT count(DISTINCT ps.essentials_politician_id) AS politicians_showing_money,
       round(sum(a.total_amount)::numeric,2) AS dollars_displayed
FROM transparent_motivations.contribution_summary_agg a
JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
WHERE ps.source_system='cal_access' AND p.is_active;
```

Expected: `dollars_displayed` equals the pre-apply figure minus the migration's purge total, to the
cent. If it does not, stop and reconcile before committing.

- [ ] **Step 3: Re-check the migration number, commit, push**

```bash
cd "C:/EV-Accounts" && git fetch origin master --quiet && node backend/scripts/check-migration-numbers.mjs
git add backend/migrations/<N>_cal_access_track_a.sql && git commit -m "fix(cal-access): Track A — purge money links the official filer record disproves"
git push origin master
```

- [ ] **Step 4: Confirm CI is green on the commit you pushed**

```bash
cd "C:/EV-Accounts" && until [ "$(gh run list --limit 1 --json status -q '.[0].status')" = "completed" ]; do sleep 15; done
rid=$(gh run list --limit 1 --json databaseId -q '.[0].databaseId'); gh run list --limit 1 --json headSha,conclusion
gh run view "$rid" --json jobs -q '.jobs[] | "\(.name) :: \(.conclusion)"'
```

Check the headSha matches your commit and every job is `success` or `skipped`. An early failing step
masks later checks.

---

### Task 5: GATE — report the wrong-rate before touching Track B

**Files:** none.

**Interfaces:**
- Consumes: Task 3's wrong-rate and Task 4's verified totals.
- Produces: an operator decision to proceed with, or revise, Track B.

This gate is in the spec by design. Track B demotes roughly 3,700 links on a rule, not on evidence.
Track A is the only measurement of how often that rule would be wrong.

- [ ] **Step 1: Report to the operator**

State: how many of the top 50 were purged and for how much; the wrong-rate; and — the number that
matters — **how many purges were "no official record / surname only" rather than "names someone
else."** A high proportion of the former means prove-it-right is removing mostly-correct data, and
Track B would do that ~3,700 more times.

- [ ] **Step 2: Offer the coverage extension the spec allows**

The spec permits extending Track A from the top 50 to the top 100 (94.4% → 98% of dollars) if the
first pass shows a high wrong-rate. If it did, re-run Tasks 1–4 with `TOP_N=100`; `01-build-worklist.ts`
takes `TOP_N` from the environment, and Task 3 will simply re-decide the same links plus 50 more.
Skip the extension when the wrong-rate is low — the extra 50 links share only ~$1.6M.

- [ ] **Step 3: Wait for an explicit decision**

Do not start Task 6 without it. If the operator revises the posture, the spec and this plan both need
updating first.

---

### Task 6: Track B classifier — dry run

**Files:**
- Create: `backend/scripts/cal-access-bucket-b/04-classify-track-b.ts`
- Create (output): `backend/data/cal-access-bucket-b/track-b-decisions.json`

**Interfaces:**
- Consumes: the DB, plus `namesThem(official: string, first: string, last: string): boolean`
  **imported from `03-classify-track-a.ts` rather than copied**, so the two tracks cannot drift.
  `DIMINUTIVES` stays private to that module — `namesThem` already applies it.
- Produces: `track-b-decisions.json` — `{ source_id, politician_name, committee_name, decision, basis }`.

**Rule:** keep when the committee name carries the surname **in leading position** AND the given name
(or a diminutive). Otherwise purge. Leading position is what stops "Buena Park" and "Menlo Park"
counting as naming Traci Park.

- [ ] **Step 1: Export the helpers from Task 3's script**

In `03-classify-track-a.ts`, change `const DIMINUTIVES` to `export const DIMINUTIVES`, and
`function namesThem` to `export function namesThem`, and guard its top-level body so importing does
not re-run it:

```ts
// at the top of the executable section of 03-classify-track-a.ts
const isMain = process.argv[1]?.endsWith('03-classify-track-a.ts');
if (isMain) {
  // ... existing read/classify/write/generate code, indented into this block ...
}
```

- [ ] **Step 2: Write the Track B classifier**

```ts
// backend/scripts/cal-access-bucket-b/04-classify-track-b.ts
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { namesThem } from './03-classify-track-a';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');

const SQL = `
SELECT ps.id AS source_id, p.full_name AS politician_name,
       coalesce(p.first_name,'') AS first_name, coalesce(p.last_name,'') AS last_name,
       coalesce(substring(ps.notes from '"committee_name"\\s*:\\s*"([^"]{0,200})'),'') AS committee_name,
       coalesce((SELECT sum(g.total_amount) FROM transparent_motivations.contribution_summary_agg g
                  WHERE g.politician_source_id = ps.id), 0) AS dollars
  FROM transparent_motivations.politician_sources ps
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
 WHERE ps.source_system = 'cal_access'
   AND p.is_active
   AND ps.research_status = 'confirmed'
   AND lower(regexp_replace(p.full_name,'^.*\\s','')) = lower(coalesce(p.last_name,''));
`;

// Cal-Access writes the candidate's surname first: "SOLACHE FOR ASSEMBLY 2026; FRIENDS OF".
// Requiring it in the leading position stops "Buena Park" naming Traci Park.
function surnameLeads(committee: string, last: string): boolean {
  const head = committee.trim().toLowerCase().slice(0, last.trim().length + 2);
  return head.startsWith(last.trim().toLowerCase());
}

async function main() {
  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL is not set'); process.exit(1); }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows } = await pool.query(SQL);
  await pool.end();

  const decisions = rows.map(r => {
    const leads = surnameLeads(r.committee_name, r.last_name);
    const named = namesThem(r.committee_name, r.first_name, r.last_name);
    if (leads && named) return { ...r, decision: 'keep', basis: 'surname leads and given name present' };
    if (!leads)         return { ...r, decision: 'purge', basis: 'surname not in leading position' };
    return { ...r, decision: 'purge', basis: 'no given name in committee name (unprovable)' };
  });

  fs.mkdirSync(DIR, { recursive: true });
  fs.writeFileSync(path.join(DIR, 'track-b-decisions.json'), JSON.stringify(decisions, null, 2));

  const tally: Record<string, number> = {};
  let purgeMoney = 0;
  for (const d of decisions) {
    tally[`${d.decision}: ${d.basis}`] = (tally[`${d.decision}: ${d.basis}`] ?? 0) + 1;
    if (d.decision === 'purge') purgeMoney += Number(d.dollars);
  }
  console.log(`${decisions.length} links classified`);
  for (const [k, v] of Object.entries(tally)) console.log(`  ${v.toString().padStart(5)}  ${k}`);
  console.log(`money on purge set: $${purgeMoney.toFixed(2)}  <-- must be small; Track A took the big money`);
}
main();
```

- [ ] **Step 3: Run the dry run**

```bash
cd "C:/EV-Accounts/backend" && npx tsx scripts/cal-access-bucket-b/04-classify-track-b.ts
```

Expected: roughly 7,270 links classified, and **`money on purge set` should be small** — Track A
already removed the large sums. If it is large, Track A did not cover what it should have; stop.

- [ ] **Step 4: Spot-check 10 keeps and 10 purges by eye**

Read them out of `track-b-decisions.json`. A keep that names someone else, or a purge of a committee
that plainly names the politician, means the rule is wrong. Fix before generating a migration.

- [ ] **Step 5: Commit**

```bash
cd "C:/EV-Accounts" && git add backend/scripts/cal-access-bucket-b/04-classify-track-b.ts backend/data/cal-access-bucket-b/track-b-decisions.json && git commit -m "chore(cal-access): Track B classifier dry run"
```

---

### Task 7: Track B migration — generate, apply, ship

**Files:**
- Modify: `backend/scripts/cal-access-bucket-b/04-classify-track-b.ts` (add migration emission)
- Create: `backend/migrations/1791_cal_access_track_b.sql` ← **re-check the number**

**Interfaces:**
- Consumes: `track-b-decisions.json`.
- Produces: the applied migration.

- [ ] **Step 1: Emit the migration from the classifier**

Append to `main()` in `04-classify-track-b.ts`, before it returns:

```ts
  const MIGRATION_NUMBER = process.env.MIGRATION_NUMBER ?? '1791';
  const purge = decisions.filter(d => d.decision === 'purge');
  const keep  = decisions.filter(d => d.decision === 'keep');

  const sql = `-- ${MIGRATION_NUMBER}_cal_access_track_b.sql
-- Cal-Access bucket B, Track B: the ${decisions.length} zero-dollar links left after Track A.
--
-- Spec: docs/superpowers/specs/2026-08-16-cal-access-bucket-b-design.md
-- Decisions: backend/data/cal-access-bucket-b/track-b-decisions.json
--
-- Rule (the operator's prove-it-right posture, applied mechanically): keep a link only when the
-- committee name carries the politician's surname IN LEADING POSITION -- where Cal-Access puts it --
-- AND their given name or a known diminutive. Otherwise demote.
-- The leading-position test is what stops "Buena Park" and "Menlo Park" from naming Traci Park; the
-- diminutive list is what stops "BOB SMITH FOR COUNCIL" being demoted off a politician named Robert.
--
-- ⚠ This DELIBERATELY demotes correct-but-unprovable links such as "SOLACHE FOR ASSEMBLY 2026" --
-- surname, office, year, no given name anywhere. That is the posture working as intended, and the
-- same call the operator made on Socrata bucket C. No money rides on these rows, so the cost is a
-- missing source listing rather than a wrong figure.
--
-- KEEP ${keep.length} · PURGE ${purge.length}
BEGIN;

CREATE TEMP TABLE tb_purge (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO tb_purge (sid) VALUES
  ${purge.map(d => `('${d.source_id}')`).join(',\n  ')};

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM tb_purge;
  IF n <> ${purge.length} THEN RAISE EXCEPTION 'pre-check: purge set is %, expected ${purge.length}', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN tb_purge t ON t.sid = ps.id
   WHERE ps.source_system <> 'cal_access';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % target(s) are not cal_access links', n; END IF;

  -- Track A owns the money. If anything here still displays dollars, the two tracks disagree.
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN tb_purge t ON t.sid = g.politician_source_id;
  IF d > 1000 THEN RAISE EXCEPTION 'pre-check: purge set still displays %, which Track A should have handled', d; END IF;
END $$;

UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'not_applicable',
       notes = coalesce(ps.notes,'') || ' | WRONG PERSON (migration ${MIGRATION_NUMBER}, 2026-08-16):'
               || ' committee name does not carry this politician''''s surname in leading position and'
               || ' given name. Unprovable under the prove-it-right posture.',
       updated_at = now()
  FROM tb_purge t
 WHERE ps.id = t.sid;

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN tb_purge t ON t.sid = ps.id
   WHERE ps.research_status = 'not_applicable' AND ps.notes LIKE '%WRONG PERSON (migration ${MIGRATION_NUMBER}%';
  IF n <> ${purge.length} THEN RAISE EXCEPTION 'guard: % of ${purge.length} demoted with a note', n; END IF;

  -- Count ONLY bucket-B links. Bucket A's 14 correct keeps (migration 1789) are also still
  -- \`confirmed\` and are not this migration's business -- an unscoped count would be off by 14.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.source_system = 'cal_access' AND p.is_active AND ps.research_status = 'confirmed'
     AND lower(regexp_replace(p.full_name,'^.*\\s','')) = lower(coalesce(p.last_name,''));
  IF n <> ${keep.length} THEN RAISE EXCEPTION 'guard: % bucket-B links still confirmed, expected ${keep.length}', n; END IF;

  RAISE NOTICE 'cal_access Track B: ${purge.length} links demoted, ${keep.length} kept';
END $$;

COMMIT;
`;
  fs.writeFileSync(path.join(process.cwd(), 'migrations', `${MIGRATION_NUMBER}_cal_access_track_b.sql`), sql);
  console.log(`wrote migrations/${MIGRATION_NUMBER}_cal_access_track_b.sql`);
```

⚠ The `''''` in the note text is deliberate: it is a single quote inside a SQL string inside a JS
template literal. Read the generated `.sql` and confirm the note reads `politician's`, not
`politician''s`.

- [ ] **Step 2: Get the number and generate**

```bash
cd "C:/EV-Accounts" && git fetch origin master --quiet && node backend/scripts/check-migration-numbers.mjs
cd "C:/EV-Accounts/backend" && MIGRATION_NUMBER=<next free> npx tsx scripts/cal-access-bucket-b/04-classify-track-b.ts
```

- [ ] **Step 3: Apply**

```bash
cd "C:/EV-Accounts/backend" && npx tsx scripts/_apply-file.ts migrations/<N>_cal_access_track_b.sql
```

- [ ] **Step 4: Verify on row counts**

```sql
SELECT research_status, count(*) AS links
FROM transparent_motivations.politician_sources ps
JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
WHERE ps.source_system='cal_access' AND p.is_active
GROUP BY 1 ORDER BY 2 DESC;
```

Expected: `confirmed` equals the classifier's KEEP count exactly; the rest `not_applicable`.

Also re-run the money query from Task 4 Step 2 and confirm `dollars_displayed` is **unchanged** from
after Track A — Track B must not move money.

- [ ] **Step 5: Re-check the number, commit, push, confirm CI**

```bash
cd "C:/EV-Accounts" && git fetch origin master --quiet && node backend/scripts/check-migration-numbers.mjs
git add backend/migrations/<N>_cal_access_track_b.sql backend/scripts/cal-access-bucket-b/04-classify-track-b.ts && git commit -m "fix(cal-access): Track B — demote committee links that cannot be tied to the politician"
git push origin master
cd "C:/EV-Accounts" && until [ "$(gh run list --limit 1 --json status -q '.[0].status')" = "completed" ]; do sleep 15; done
rid=$(gh run list --limit 1 --json databaseId -q '.[0].databaseId'); gh run view "$rid" --json jobs -q '.jobs[] | "\(.name) :: \(.conclusion)"'
```

- [ ] **Step 6: Update the memory record**

Update `cal_access_lasttoken_mislinks`: mark bucket B done, record the final displayed-dollar figure
and the keep/purge counts, and note that the deferred bulk-registration ingest is now the only
remaining path to re-enabling cal_access.
