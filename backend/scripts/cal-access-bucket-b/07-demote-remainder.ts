// 07-demote-remainder.ts
// Demotes the zero-dollar bucket-B remainder: every still-`confirmed` cal_access link on an active
// politician that carries NO contribution_summary_agg row and that neither Track A nor Task 6 judged.
//
// Plan: docs/superpowers/plans/2026-08-16-cal-access-bucket-b.md (Task 7)
// Run from backend/:  MIGRATION_NUMBER=<n> npx tsx scripts/cal-access-bucket-b/07-demote-remainder.ts
//
// ── THE SPLIT IS TWO WAYS, NOT THREE ─────────────────────────────────────────────────────────────
//   · committee name names a demonstrably different person -> `not_applicable` + WRONG PERSON note
//   · everything else -> `needs_research`, with a note saying it was produced by a discredited
//     predicate and never verified
//
// 🔑 `needs_research` is TRUE WITHOUT INFERENCE AND IT DISARMS THE LINK: campaignFinanceService
// (display) and campaignFinanceScheduler (ingestion) both gate on research_status = 'confirmed', and
// nothing reads needs_research. So the honest status is also the safe one.
//
// ⚠ These links are ARMED, NOT INERT. $0 means ingestion has not reached them yet, not that they are
// harmless -- the 4,859 contributions cleaned up in migrations 1789/1790 arrived through exactly such
// links.
//
// ⚠ The office route is deliberately NOT used here. It exists to stop an irreversible deletion of
// money; marking a link unknown destroys nothing, and using it here would push thousands more guesses
// into `confirmed` on far softer evidence than Track A or Task 6 required.
//
// ⚠ Only conflictingGivenName() decides the not_applicable branch, not the wider disproof set Task 6
// used. These rows have NO fetched filer record -- the only name available is the committee_name our
// discredited ingest stored -- so the stronger "WRONG PERSON" claim is reserved for the one test that
// reads a different personal name straight out of that string.
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { conflictingGivenName } from './03-classify-track-a';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');
const MIGRATION_NUMBER = process.env.MIGRATION_NUMBER ?? '1792';

const SQL = `
SELECT ps.id AS source_id, ps.external_id AS filer_id, p.full_name AS politician_name,
       coalesce(p.first_name,'') AS first_name, coalesce(p.last_name,'') AS last_name,
       coalesce(substring(ps.notes from '"committee_name"\\s*:\\s*"([^"]{0,200})'),'') AS committee_name
  FROM transparent_motivations.politician_sources ps
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
 WHERE ps.source_system = 'cal_access'
   AND p.is_active
   AND ps.research_status = 'confirmed'
   AND lower(regexp_replace(p.full_name,'^.*\\s','')) = lower(coalesce(p.last_name,''))
   AND NOT EXISTS (SELECT 1 FROM transparent_motivations.contribution_summary_agg g
                    WHERE g.politician_source_id = ps.id)
   AND ps.id <> ALL($1::uuid[])
 ORDER BY ps.id;
`;

async function main() {
  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL is not set'); process.exit(1); }

  const trackA = JSON.parse(fs.readFileSync(path.join(DIR, 'track-a-decisions.json'), 'utf8'));
  const money = JSON.parse(fs.readFileSync(path.join(DIR, 'money-decisions.json'), 'utf8'));
  const judged: string[] = [...trackA.map((d: any) => d.source_id), ...money.map((d: any) => d.source_id)];
  if (judged.length !== 354) {
    console.error(`ERROR: expected 354 already-judged links (50 + 304), found ${judged.length}.`);
    process.exit(1);
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows } = await pool.query(SQL, [judged]);
  await pool.end();

  const decisions = rows.map(r => {
    const conflict = r.committee_name ? conflictingGivenName(r.committee_name, r.first_name) : null;
    return conflict
      ? { ...r, branch: 'not_applicable', conflict }
      : { ...r, branch: 'needs_research', conflict: null };
  });

  fs.writeFileSync(path.join(DIR, 'remainder-decisions.json'), JSON.stringify(decisions, null, 2));

  const wrong = decisions.filter(d => d.branch === 'not_applicable');
  const unknown = decisions.filter(d => d.branch === 'needs_research');
  console.log(`remainder: ${decisions.length} links`);
  console.log(`  not_applicable (names a different person): ${wrong.length}`);
  console.log(`  needs_research (unknown):                  ${unknown.length}`);
  console.log('\nsample of the WRONG PERSON branch:');
  for (const w of wrong.slice(0, 12)) console.log(`  ${w.politician_name}  <-  ${w.committee_name}  ("${w.conflict}")`);

  const lit = (ids: string[]) => ids.map(i => `  ('${i}')`).join(',\n');

  const sql = `-- ${MIGRATION_NUMBER}_cal_access_demote_unresearched.sql
-- Cal-Access bucket B, Task 7: the zero-dollar remainder.
--
-- Spec: docs/superpowers/specs/2026-08-16-cal-access-bucket-b-design.md
-- Decisions: backend/data/cal-access-bucket-b/remainder-decisions.json
--
-- confirm-cal-access.ts linked committees on the LAST TOKEN of full_name and confirmed its own
-- guesses in the same pass, producing 7,836 "confirmed" links nothing ever checked. Migration 1789
-- cleared bucket A; 1790 and 1791 resolved every money-bearing link in bucket B against the official
-- Cal-Access filer record. What is left is ${decisions.length} links that carry no money and no evidence.
--
-- They are NOT inert. $0 means ingestion has not reached them, not that they are harmless -- the
-- 4,859 contributions cleaned up in 1789/1790 arrived through exactly such links. Both display
-- (campaignFinanceService) and ingestion (campaignFinanceScheduler) gate on
-- research_status = 'confirmed', and nothing reads 'needs_research', so demoting them disarms them.
--
-- Two branches, and neither asserts more than is known:
--   ${String(wrong.length).padStart(5)} -> not_applicable  the committee name names a different person outright
--   ${String(unknown.length).padStart(5)} -> needs_research  we do not know; true without inference
--
-- ⚠ The office route is NOT used here. It exists to prevent irreversible deletion of money; marking a
-- link unknown destroys nothing, and using it here would put thousands of guesses back into
-- 'confirmed' on softer evidence than any earlier pass accepted.
-- ⚠ No money may move: every target has no contribution_summary_agg row, asserted below both by
-- construction and by comparing the displayed cal_access total across the transaction.
BEGIN;

CREATE TEMP TABLE rem_wrong (sid uuid PRIMARY KEY) ON COMMIT DROP;
${wrong.length ? `INSERT INTO rem_wrong (sid) VALUES\n${lit(wrong.map(d => d.source_id))};` : '-- (empty)'}

CREATE TEMP TABLE rem_unknown (sid uuid PRIMARY KEY) ON COMMIT DROP;
${unknown.length ? `INSERT INTO rem_unknown (sid) VALUES\n${lit(unknown.map(d => d.source_id))};` : '-- (empty)'}

DO $$
DECLARE n int;
BEGIN
  SELECT count(*) INTO n FROM rem_wrong;
  IF n <> ${wrong.length} THEN RAISE EXCEPTION 'pre-check: wrong set is %, expected ${wrong.length}', n; END IF;
  SELECT count(*) INTO n FROM rem_unknown;
  IF n <> ${unknown.length} THEN RAISE EXCEPTION 'pre-check: unknown set is %, expected ${unknown.length}', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps
   WHERE ps.id IN (SELECT sid FROM rem_wrong UNION ALL SELECT sid FROM rem_unknown)
     AND (ps.source_system <> 'cal_access' OR ps.research_status <> 'confirmed');
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % target(s) are not confirmed cal_access links', n; END IF;

  -- The defining property of this migration: it touches only links with no money.
  SELECT count(*) INTO n FROM transparent_motivations.contribution_summary_agg g
   WHERE g.politician_source_id IN (SELECT sid FROM rem_wrong UNION ALL SELECT sid FROM rem_unknown);
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % target(s) carry an agg row; this pass must not move money', n; END IF;
END $$;

-- Snapshot the displayed total so the guard can prove it did not move. Deliberately NOT a
-- hard-coded figure: a literal would go stale and start failing correct migrations later.
CREATE TEMP TABLE rem_money_before AS
SELECT round(coalesce(sum(a.total_amount),0)::numeric,2) AS d
  FROM transparent_motivations.contribution_summary_agg a
  JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
  JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
 WHERE ps.source_system = 'cal_access' AND p.is_active;

UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'not_applicable',
       notes = coalesce(ps.notes,'') || ' | WRONG PERSON (migration ${MIGRATION_NUMBER}, 2026-08-16):'
               || ' this committee name gives a different personal name. Link created by'
               || ' confirm-cal-access.ts matching the last token of full_name.'
               || ' See backend/data/cal-access-bucket-b/remainder-decisions.json.',
       updated_at = now()
  FROM rem_wrong w
 WHERE ps.id = w.sid;

UPDATE transparent_motivations.politician_sources ps
   SET research_status = 'needs_research',
       notes = coalesce(ps.notes,'') || ' | UNVERIFIED (migration ${MIGRATION_NUMBER}, 2026-08-16):'
               || ' produced by confirm-cal-access.ts, which matched the last token of full_name and'
               || ' confirmed its own guesses in the same pass. Never independently verified and'
               || ' carries no contributions. Demoted to needs_research: not disproved, just unknown.',
       updated_at = now()
  FROM rem_unknown u
 WHERE ps.id = u.sid;

DO $$
DECLARE n int; d0 numeric; d1 numeric;
BEGIN
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN rem_wrong w ON w.sid = ps.id
   WHERE ps.research_status = 'not_applicable' AND ps.notes LIKE '%WRONG PERSON (migration ${MIGRATION_NUMBER}%';
  IF n <> ${wrong.length} THEN RAISE EXCEPTION 'guard: % of ${wrong.length} demoted to not_applicable with a note', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN rem_unknown u ON u.sid = ps.id
   WHERE ps.research_status = 'needs_research' AND ps.notes LIKE '%UNVERIFIED (migration ${MIGRATION_NUMBER}%';
  IF n <> ${unknown.length} THEN RAISE EXCEPTION 'guard: % of ${unknown.length} demoted to needs_research with a note', n; END IF;

  -- Nothing may still be 'confirmed' in either set.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps
   WHERE ps.id IN (SELECT sid FROM rem_wrong UNION ALL SELECT sid FROM rem_unknown)
     AND ps.research_status = 'confirmed';
  IF n <> 0 THEN RAISE EXCEPTION 'guard: % target(s) are still confirmed', n; END IF;

  -- NOT ONE DOLLAR MOVED.
  SELECT d INTO d0 FROM rem_money_before;
  SELECT round(coalesce(sum(a.total_amount),0)::numeric,2) INTO d1
    FROM transparent_motivations.contribution_summary_agg a
    JOIN transparent_motivations.politician_sources ps ON ps.id = a.politician_source_id
    JOIN essentials.politicians p ON p.id = ps.essentials_politician_id
   WHERE ps.source_system = 'cal_access' AND p.is_active;
  IF d0 <> d1 THEN RAISE EXCEPTION 'guard: displayed cal_access money moved from % to %', d0, d1; END IF;

  RAISE NOTICE 'cal_access Task 7: % wrong-person, % unknown, money unchanged at %', ${wrong.length}, ${unknown.length}, d1;
END $$;

DROP TABLE rem_money_before;

COMMIT;
`;

  fs.writeFileSync(path.join(process.cwd(), 'migrations', `${MIGRATION_NUMBER}_cal_access_demote_unresearched.sql`), sql);
  console.log(`\nwrote migrations/${MIGRATION_NUMBER}_cal_access_demote_unresearched.sql`);
}
main();
