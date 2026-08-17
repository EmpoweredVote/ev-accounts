// 06-classify-money.ts
// Classifies the 304 remaining money-bearing bucket-B links against their OFFICIAL Cal-Access filer
// records and emits the migration.
//
// Plan: docs/superpowers/plans/2026-08-16-cal-access-bucket-b.md (Task 6)
// Run from backend/:  MIGRATION_NUMBER=<n> npx tsx scripts/cal-access-bucket-b/06-classify-money.ts
//
// The identity helpers are IMPORTED from 03-classify-track-a.ts, never reimplemented -- two copies of
// an identity rule drift, and the whole defect being cleaned up here began as one predicate nobody
// could see a second opinion on.
//
// ⚠ ONE DELIBERATE DIFFERENCE FROM TRACK A: no auto-keep on `names-them`.
// Track A auto-kept rows whose committee name in OUR database already carried the given name, and
// never fetched them. Here every one of the 304 has an official record, so every row is judged on the
// official name. Our stored committee_name arrived through the same discredited ingest; when the
// authoritative field is in hand there is no reason to rule on the copy.
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';
import { namesThem, officeKeywords, conflictingGivenName, leadingDifferentSurname, OPERATOR_KEEPS, fold } from './03-classify-track-a';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');
const MIGRATION_NUMBER = process.env.MIGRATION_NUMBER ?? '1791';

async function main() {
  const worklist = JSON.parse(fs.readFileSync(path.join(DIR, 'money-worklist.json'), 'utf8'));
  const filers = JSON.parse(fs.readFileSync(path.join(DIR, 'money-filer-records.json'), 'utf8'));

  if (!process.env.DATABASE_URL) { console.error('ERROR: DATABASE_URL is not set'); process.exit(1); }
  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
  const { rows: officeRows } = await pool.query(
    `SELECT t.politician_id, o.title, c.name AS chamber
       FROM essentials.office_terms t
       JOIN essentials.offices o ON o.id = t.office_id
       LEFT JOIN essentials.chambers c ON c.id = o.chamber_id
      WHERE t.politician_id = ANY($1::uuid[])`,
    [worklist.map((r: any) => r.politician_id)]);
  await pool.end();

  const officesByPid: Record<string, { title: string | null; chamber: string | null }[]> = {};
  for (const o of officeRows) (officesByPid[o.politician_id] ??= []).push({ title: o.title, chamber: o.chamber });

  const esc = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

  const decisions = worklist.map((r: any) => {
    const kws = officeKeywords(officesByPid[r.politician_id] ?? []);
    const rec = filers[r.filer_id];
    const official = rec?.status === 'ok' ? rec.official_name : '';
    const historical: string[] = Array.isArray(rec?.historical) ? rec.historical : [];
    const officeholder: string = String(rec?.officeholder ?? '');
    const base = { ...r, official_name: official, historical, officeholder, office_keywords: kws };

    if (OPERATOR_KEEPS[r.filer_id]) {
      return { ...base, decision: 'keep', route: 'operator', basis: OPERATOR_KEEPS[r.filer_id] };
    }
    if (!official) {
      return { ...base, decision: 'purge', route: 'no-record', basis: `no official record retrievable (${rec?.status ?? 'missing'}); unprovable` };
    }
    // Route 1 -- the official name carries surname AND given name (or a diminutive).
    if (namesThem(official, r.first_name, r.last_name)) {
      return { ...base, decision: 'keep', route: 'name', basis: `official name "${official}" carries their surname and given name` };
    }
    // Surname absent from EVERY registered name for this filer: not their committee under any route.
    const surnameRe = new RegExp('\\b' + esc(fold(r.last_name.trim().toLowerCase())) + '\\b', 'i');
    if (![official, ...historical].some(n => surnameRe.test(fold(String(n).toLowerCase())))) {
      return { ...base, decision: 'purge', route: 'no-surname', basis: `official name "${official}" does not contain their surname` };
    }
    // Disproof OUTRANKS corroboration -- a conflicting trailing given name vetoes the office route.
    const conflict = conflictingGivenName(official, r.first_name);
    if (conflict) {
      return { ...base, decision: 'purge', route: 'other-person', basis: `official name "${official}" names a different person ("${conflict}")` };
    }
    // Disproof, continued: the committee leads with somebody else's surname.
    const lead = leadingDifferentSurname(official, r.last_name);
    if (lead) {
      return { ...base, decision: 'purge', route: 'other-surname-leads', basis: `official name "${official}" is "${lead}"'s committee; their surname appears only incidentally` };
    }
    // Route 1b -- a HISTORICAL registered name carries surname AND given name.
    // Cal-Access drops the given name when a committee is renamed, so the current name can be
    // anonymous while an earlier one is explicit: "IRWIN FOR LIEUTENANT GOVERNOR 2030" today,
    // "IRWIN FOR LT. GOVERNOR 2030; JACQUI" before. That is identity evidence, not inference.
    const histHit = historical.find(h => namesThem(String(h), r.first_name, r.last_name));
    if (histHit) {
      return { ...base, decision: 'keep', route: 'historical-name', basis: `historical committee name "${histHit}" carries their surname and given name` };
    }
    // Route 1c -- the filer's own OFFICEHOLDER line names the seat they hold.
    // Stronger than reading the office out of the committee's title: this field describes the
    // officeholder behind the committee, not the contest it was registered for.
    const ohHit = officeholder ? kws.find(k => officeholder.toLowerCase().includes(k)) : undefined;
    if (ohHit) {
      return { ...base, decision: 'keep', route: 'officeholder', basis: `filer's OFFICEHOLDER is "${officeholder}", the office they hold (${ohHit})` };
    }
    // Route 2 -- the office they actually hold.
    // ⚠ A surname of 1-2 characters cannot carry this route. "Francis De" (stored last_name "De")
    // word-matches every "DE HOFF"/"DE MAIO"/"DE LEON" committee, so 'city council' would corroborate
    // a stranger's council committee. Such a link needs an actual given-name match or nothing.
    const surnameTooShort = fold(r.last_name.trim()).replace(/[^A-Za-z]/g, '').length <= 2;
    const hit = surnameTooShort ? undefined : kws.find(k => official.toLowerCase().includes(k));
    if (hit) {
      return { ...base, decision: 'keep', route: 'office', basis: `official name "${official}" matches the office they hold (${hit})` };
    }
    if (surnameTooShort) {
      return { ...base, decision: 'purge', route: 'surname-too-short', basis: `surname "${r.last_name}" is too short to corroborate; office route withheld` };
    }
    return { ...base, decision: 'purge', route: 'unprovable', basis: `official name "${official}" gives no given name and no office match [holds: ${kws.join(', ') || 'no office recorded'}]` };
  });

  fs.writeFileSync(path.join(DIR, 'money-decisions.json'), JSON.stringify(decisions, null, 2));

  const purge = decisions.filter((d: any) => d.decision === 'purge');
  const keep = decisions.filter((d: any) => d.decision === 'keep');
  const money = (rows: any[]) => rows.reduce((a, r) => a + r.dollars, 0);
  // 🔴 NOT `dollars > 0`. Every link in this worklist has a contribution_summary_agg row by
  // construction, but one of them totals $0 -- and a $0 agg row is still a row. Filtering on dollars
  // left it undeleted while the purge set still claimed it, and the post-apply guard correctly
  // refused the whole migration with "1 agg row(s) still on purged links". The guard did its job;
  // the generator was wrong.
  const withMoney = purge;

  const byRoute: Record<string, { n: number; d: number }> = {};
  for (const d of decisions) { byRoute[d.route] ??= { n: 0, d: 0 }; byRoute[d.route].n++; byRoute[d.route].d += d.dollars; }

  console.log(`keep  ${keep.length} links  $${money(keep).toFixed(2)}`);
  console.log(`purge ${purge.length} links  $${money(purge).toFixed(2)}`);
  console.log(`wrong-rate: ${(100 * purge.length / decisions.length).toFixed(1)}% of ${decisions.length}\n`);
  console.log('by route:');
  for (const [k, v] of Object.entries(byRoute)) console.log(`  ${k.padEnd(13)} ${String(v.n).padStart(4)}  $${v.d.toFixed(2)}`);

  console.log(`\n── EVERY PURGE (${purge.length}) ──`);
  for (const p of purge) console.log(`  $${p.dollars.toFixed(2).padStart(11)}  ${p.route.padEnd(13)} ${p.politician_name}  <-  ${p.official_name || '(no official record)'}`);

  console.log(`\n── KEEPS ON THE OFFICE ROUTE (softer evidence, ${byRoute.office?.n ?? 0}) ──`);
  for (const k of keep.filter((d: any) => d.route === 'office')) console.log(`  $${k.dollars.toFixed(2).padStart(11)}  ${k.politician_name}  <-  ${k.official_name}`);

  // ── generate the migration ──────────────────────────────────────────────────
  const lit = (ids: string[]) => ids.map(i => `'${i}'`).join(',\n   ');
  const purgeIds = purge.map((d: any) => d.source_id);
  const moneyIds = withMoney.map((d: any) => d.source_id);
  const keepIds = keep.map((d: any) => d.source_id);
  const purgeDollars = money(purge).toFixed(2);
  const keepDollars = money(keep).toFixed(2);

  const sql = `-- ${MIGRATION_NUMBER}_cal_access_money_verified.sql
-- Cal-Access bucket B, Task 6: the last ${decisions.length} money-bearing links, each judged against the
-- OFFICIAL Cal-Access filer record. With this applied, EVERY dollar of cal_access money still on
-- display rests on a fetched filer record rather than on the last-token guess that created it.
--
-- Spec: docs/superpowers/specs/2026-08-16-cal-access-bucket-b-design.md
-- Decisions, with the official name and basis for every link:
--   backend/data/cal-access-bucket-b/money-decisions.json
--
-- These are the money links Track A did not reach: 336 bucket-B links carry a contribution_summary_agg
-- row, 32 of which Track A already adjudicated, leaving ${decisions.length}. All ${decisions.length} official records were
-- retrieved (0 not-found), so no link here is purged merely for being unretrievable.
--
-- Ordered rule, importing Track A's helpers so the two cannot drift. Disproof always outranks
-- corroboration:
--   operator ruling -> no record -> surname+given name -> surname absent from every registered name
--   -> conflicting given name -> committee leads with another surname -> historical name carries
--   surname+given -> filer's OFFICEHOLDER line matches the seat held -> surname too short to
--   corroborate -> office held appears in the committee name -> otherwise purge (prove-it-right).
--
-- ⚠ FOUR DEFECTS WERE FOUND BY READING ALL 304 DECISIONS, each of which silently destroyed or kept
-- real money. They are fixed in 03-classify-track-a.ts and documented there:
--   · diacritics were not folded, so "MUNOZ-GUEVARA ...; JUAN" read as a missing surname for Juan
--     Munoz-Guevara and would have been purged with his $7,435;
--   · officeKeywords() produced NO keyword for seven title/chamber pairs actually held by these
--     politicians (Board of Trustees alone covering 19), and an unrecognised office is
--     indistinguishable from "no corroboration", which under prove-it-right means a purge;
--   · a title stored in first_name ("Dr. Monica Sanchez") made the given name resolve to "dr.", so
--     a committee literally ending "; DR. MONICA" read as naming a different person;
--   · the office route accepted 1-2 character surnames, letting a politician stored as "Francis De"
--     corroborate on any "DE HOFF"/"DE MAIO" committee.
-- Re-running Track A's rule with every fix flips none of its 18 applied purges; migration 1790 stands.
--
-- 🔑 THE FILER PAGE HAS THREE FIELDS, NOT ONE. Reading only the SUMMARY INFORMATION name left 69
-- links "unprovable"; the OFFICEHOLDER line and HISTORICAL NAMES on the same page cut that to 24.
-- Jacqui Irwin's $60,380 and Mike Gipson's $20,650 were both about to be purged as unprovable and are
-- affirmatively hers and his: "IRWIN FOR LT. GOVERNOR 2030; JACQUI" and "OFFICEHOLDER: ASSEMBLY
-- DISTRICT 65". A "missing" given name was an artifact of reading one field.
--
-- KEEP  ${keep.length} links  $${keepDollars}
-- PURGE ${purge.length} links  $${purgeDollars}
BEGIN;

CREATE TEMP TABLE tb_purge (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO tb_purge (sid) VALUES
  ${purgeIds.map((i: string) => `('${i}')`).join(',\n  ')};

CREATE TEMP TABLE tb_keep (sid uuid PRIMARY KEY) ON COMMIT DROP;
INSERT INTO tb_keep (sid) VALUES
  ${keepIds.map((i: string) => `('${i}')`).join(',\n  ')};

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM tb_purge;
  IF n <> ${purge.length} THEN RAISE EXCEPTION 'pre-check: purge set is %, expected ${purge.length}', n; END IF;
  SELECT count(*) INTO n FROM tb_keep;
  IF n <> ${keep.length} THEN RAISE EXCEPTION 'pre-check: keep set is %, expected ${keep.length}', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN tb_purge p ON p.sid = ps.id
   WHERE ps.source_system <> 'cal_access';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % purge target(s) are not cal_access links', n; END IF;

  -- Every target must still be 'confirmed'. If one is not, the worklist is stale and the dollar
  -- assertions below are being read against a database that moved.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps
   WHERE ps.id IN (SELECT sid FROM tb_purge UNION ALL SELECT sid FROM tb_keep)
     AND ps.research_status <> 'confirmed';
  IF n <> 0 THEN RAISE EXCEPTION 'pre-check: % target(s) are no longer confirmed', n; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN tb_purge p ON p.sid = g.politician_source_id;
  IF d <> ${purgeDollars} THEN RAISE EXCEPTION 'pre-check: purge set displays %, expected ${purgeDollars}', d; END IF;

  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN tb_keep k ON k.sid = g.politician_source_id;
  IF d <> ${keepDollars} THEN RAISE EXCEPTION 'pre-check: keep set displays %, expected ${keepDollars}', d; END IF;
END $$;

-- Money, by INLINE literal ids. IN (SELECT ... FROM <temp table>) seq-scans contributions and times
-- out -- a fresh temp table has no statistics so the planner ignores the index. Killed the first
-- attempt at migration 1789.
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
               || ' this politician. See backend/data/cal-access-bucket-b/money-decisions.json.',
       updated_at = now()
  FROM tb_purge p
 WHERE ps.id = p.sid;

DO $$
DECLARE n int; d numeric;
BEGIN
  SELECT count(*) INTO n FROM transparent_motivations.contribution_summary_agg g JOIN tb_purge p ON p.sid = g.politician_source_id;
  IF n <> 0 THEN RAISE EXCEPTION 'guard: % agg row(s) still on purged links', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.contributions c
   WHERE c.politician_source_id IN (
     ${lit(moneyIds)});
  IF n <> 0 THEN RAISE EXCEPTION 'guard: % contribution(s) still on purged links', n; END IF;

  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN tb_purge p ON p.sid = ps.id
   WHERE ps.research_status = 'not_applicable' AND ps.notes LIKE '%WRONG PERSON (migration ${MIGRATION_NUMBER}%';
  IF n <> ${purge.length} THEN RAISE EXCEPTION 'guard: % of ${purge.length} purged links demoted with a note', n; END IF;

  -- The keeps are the entire point of doing evidence work. Assert they survived UNCHANGED -- a bug
  -- that widened the purge satisfies every check above.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN tb_keep k ON k.sid = ps.id
   WHERE ps.research_status = 'confirmed';
  IF n <> ${keep.length} THEN RAISE EXCEPTION 'guard: % of ${keep.length} kept links still confirmed', n; END IF;
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN tb_keep k ON k.sid = g.politician_source_id;
  IF d <> ${keepDollars} THEN RAISE EXCEPTION 'guard: kept money is now %, expected ${keepDollars} untouched', d; END IF;

  RAISE NOTICE 'cal_access Task 6: ${purge.length} links purged, ${keep.length} kept';
END $$;

COMMIT;
`;

  fs.writeFileSync(path.join(process.cwd(), 'migrations', `${MIGRATION_NUMBER}_cal_access_money_verified.sql`), sql);
  console.log(`\nwrote migrations/${MIGRATION_NUMBER}_cal_access_money_verified.sql`);
}
main();
