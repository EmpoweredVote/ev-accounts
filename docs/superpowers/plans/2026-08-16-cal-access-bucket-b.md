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

### ✅ Tasks 1–4 COMPLETE (2026-08-16) — Track A shipped

Migration **1790**, commit `ce0a4299`, CI green on every job.
**18 links purged / $12,683,421.80 · 32 kept / $26,451,393.94.** cal_access displayed money on active
politicians went **$41,474,744.97 → $28,791,323.17**, exactly the purge total.

**Deviations from the plan as written, all deliberate and already in the committed code:**

1. 🔴 **The Playwright fetch in Task 2 does not work and fails SILENTLY.** Cal-Access sits behind
   Incapsula: curl gets a 212-byte stub, headless Chromium gets 0 chars even on the home page, headed
   Chromium gets the home page but empty detail pages, and adding a custom UA made it worse. Every
   detail page returns an **empty body with a 200**, so the scripted run reported `not-found` for all
   25 rather than erroring. **What works:** same-origin `fetch()` from inside the long-lived MCP
   browser, which already holds the Incapsula cookie — all 25 names in ONE `browser_evaluate` call.
   `02-fetch-filers.ts` now emits that snippet and documents the whole failure ladder.
2. 🔑 **A second proof route was added: the office the politician holds.** The first run purged
   Newsom's $10.68M, because the rule accepted only surname+given-name and "NEWSOM FOR CALIFORNIA
   GOVERNOR 2022" contains no "Gavin". Cal-Access routinely omits an incumbent's given name from
   their own committee. The office is an affirmative tie of the same kind; it rescued 5 links /
   $13.0M (Newsom·Governor, Irwin·Gipson·Lackey·Assembly, Solis·Supervisor).
3. 🔑 **Disproof OUTRANKS corroboration.** Rob Bonta once held an Assembly seat, so an office match
   alone would rescue "BONTA FOR ASSEMBLY 2024; MIA". A conflicting trailing given name vetoes the
   office route. Implemented as an explicit ordering in `03-classify-track-a.ts`.
4. **Tony Strickland is an operator ruling keyed by filer id** (`OPERATOR_KEEPS`), not a rule: he
   holds a Senate seat so no office match reaches a Controller committee, but the operator confirmed
   it is the same man and his real 2010 statewide run, so the donations merge.
5. ⚠ `officeKeywords()` does not recognise **"Board of Trustees"**. Harmless in Track A (the one
   affected row, Dolores Santiago, was purged correctly anyway) but its recorded *basis* wrongly says
   "no office recorded". **Fix before any further use of the office route.**

**Gate result — 17 of 18 purges were affirmatively disproved**, not guesses: 11 name a different
person outright, 2 do not share a surname at all, 3 share a surname but the office contradicts. Only
Kyle Langford ($113,004.50) was a bare unprovable. Prove-it-right cost almost nothing — *because the
office route existed*.

---

## 🔴 TRACK B WAS RE-SCOPED AT THE GATE (operator decision, 2026-08-16). READ THIS BEFORE TASK 5.

The original Tasks 5–7 said: apply a mechanical name rule to ~7,270 links, keep or demote. **That is
superseded.** Measuring the remainder at the gate broke two assumptions the plan rested on:

- **The remainder is NOT zero-dollar.** Splitting the still-`confirmed` bucket-B links three ways:

  | group | links | dollars |
  |---|---|---|
  | A — surname leads + own given name | 784 | **$13,710,488** |
  | B — names a different person | 2,766 | $652,846 |
  | C — unknown, no given name to test | 3,716 | **$14,262,907** |

  A "mechanical rule" would therefore have moved ~$14.9M on inference, and "demote everything" would
  have taken $28.63M — effectively all of cal_access — off display indefinitely.
- 🔴 **A name-based rule marks Track A's own verified keeps as unknown.** Newsom, Irwin, Gipson,
  Lackey and Solis all fail the given-name test and land in group C. **Any Track B rule MUST exclude
  links Track A already adjudicated**, or it silently undoes evidence work.

**The decision: verify the money, demote the rest.**
Only **336** money-bearing bucket-B links remain `confirmed`, and **32 of those are Track A's keeps**,
so **304 are genuinely unresearched**. At 25 per `browser_evaluate` call that is ~12 calls. Doing them
takes evidence coverage of cal_access money from 94.4% to **100%** — no dollar anywhere resting on a
guess — and leaves only genuinely evidence-free rows to be marked unknown.

🔑 **Three statuses, mapped to what is actually known** — the binary keep/purge was the error:
- `confirmed` — an official filer record ties it to this politician.
- `not_applicable` — a filer record or committee name names a **different** person. Affirmative disproof.
- `needs_research` — we do not know. **True without inference, and it disarms the link**: both
  `campaignFinanceService` (display) and `campaignFinanceScheduler` (ingestion) gate on
  `research_status = 'confirmed'`, and nothing reads `needs_research`.

⚠ This matters because the zero-dollar links are **armed, not inert** — they show $0 because ingestion
has not reached them, not because they are harmless. The 4,859 contributions cleaned up in migrations
1789/1790 arrived through exactly such links.

---

### Task 5: Verify the remaining 304 money-bearing links

**Files:**
- Create: `backend/scripts/cal-access-bucket-b/05-build-money-worklist.ts`
- Create (output): `backend/data/cal-access-bucket-b/money-worklist.json`, `money-filer-records.json`

- [ ] **Step 1: Build the worklist of every still-`confirmed` money link Track A did not adjudicate**

Copy `01-build-worklist.ts` and change the selection to: bucket B, `research_status = 'confirmed'`,
has a `contribution_summary_agg` row, and `id NOT IN` the Track A decision set (read the 50
`source_id`s from `track-a-decisions.json` — do NOT filter on the migration-1790 note, which only the
18 purges carry). Expect **304**. If it is not 304, reconcile before fetching.

- [ ] **Step 2: Fetch official filer records, 25–30 per call**

Same method as Task 2 and it is the ONLY one that works: navigate the MCP browser to
`https://cal-access.sos.ca.gov/` once, then run the `02-fetch-filers.ts` snippet with each batch of
ids. Keep the 400ms in-loop pause — it is a government host.
🔑 **Control every batch:** re-include filer `1414018` and confirm it still returns
`NEWSOM FOR CALIFORNIA GOVERNOR 2022`. If a batch returns `__NOMATCH__` for everything, you are being
challenged again, not looking at empty records — reload the home page and retry that batch.

- [ ] **Step 3: Merge results into `money-filer-records.json`** in the same shape as
`filer-records.json`: `{ filer_id: { official_name, fetched_at, status } }`.

- [ ] **Step 4: Commit** the worklist, the records and the script.

---

### Task 6: Classify the 304 and write the migration

**Files:**
- Create: `backend/scripts/cal-access-bucket-b/06-classify-money.ts`
- Create: `backend/migrations/<N>_cal_access_money_verified.sql` ← re-check the number

- [ ] **Step 1: Fix `officeKeywords()` first.** Add "board of trustees" → `school board`, then audit
the mapping against the actual `offices.title` / `chambers.name` values held by the 304's politicians
(`SELECT DISTINCT title, chamber ...`). An unrecognised office silently becomes "no corroboration",
which under prove-it-right means a purge.

- [ ] **Step 2: Classify** by importing `namesThem`, `officeKeywords`, `conflictingGivenName` and
`OPERATOR_KEEPS` from `03-classify-track-a.ts` — do not reimplement. Same ordered rule:
operator ruling → no record → surname+given → surname absent → conflicting given name → office match
→ otherwise purge.

- [ ] **Step 3: Read every PURGE line before applying.** 304 is small enough to eyeball and this is
the last evidence-grade pass over cal_access money.

- [ ] **Step 4: Generate, apply, verify on row counts, commit, push, confirm CI** — exactly as Tasks
3–4. Money by INLINE literal ids; never `count(*)` on `contributions`; delete
`contribution_summary_agg` rows too. Guard that the keep set survived with its dollar total unchanged.

---

### Task 7: Demote the zero-dollar remainder to `needs_research`

**Files:**
- Create: `backend/scripts/cal-access-bucket-b/07-demote-remainder.ts`
- Create: `backend/migrations/<N>_cal_access_demote_unresearched.sql` ← re-check the number

- [ ] **Step 1: Select the remainder** — bucket B, still `confirmed`, **no** `contribution_summary_agg`
row, and not in the Track A or Task 6 decision sets. Roughly 6,930.

- [ ] **Step 2: Split two ways, not three.** Where the committee name names a demonstrably different
person (`conflictingGivenName` fires), set `not_applicable` with a WRONG PERSON note. Everything else
→ `needs_research` with a note saying it was produced by a discredited predicate and never verified.
⚠ Do **not** apply the office route here. It exists to prevent an irreversible deletion of money;
marking a link unknown destroys nothing, and using it here would put thousands more guesses into
`confirmed` on far softer evidence than Track A's.

- [ ] **Step 3: Guard that no money moves.** Assert the displayed cal_access total is **identical**
before and after — this migration must touch only rows with no agg row.

- [ ] **Step 4: Apply, verify, commit, push, CI.**

- [ ] **Step 5: Update memory** `cal_access_lasttoken_mislinks`: final displayed total, the
confirmed/not_applicable/needs_research counts, and that the deferred bulk-registration ingest is now
the only path to re-earning the `needs_research` links.
