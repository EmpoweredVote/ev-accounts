// 03-classify-track-a.ts
// Classifies the Track A worklist against the OFFICIAL Cal-Access filer records and emits the
// migration. Also exports namesThem() so Track B uses the identical identity test -- the two tracks
// must not drift.
//
// Plan: docs/superpowers/plans/2026-08-16-cal-access-bucket-b.md (Task 3)
// Run from backend/:  MIGRATION_NUMBER=1790 npx tsx scripts/cal-access-bucket-b/03-classify-track-a.ts
import 'dotenv/config';
import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

const DIR = path.join(process.cwd(), 'data', 'cal-access-bucket-b');

// ── Operator rulings, applied by filer id ────────────────────────────────────────────────────────
// Recorded explicitly rather than encoded as a fuzzy rule, because each is a judgement about one
// person that no general predicate should be stretched to cover.
export const OPERATOR_KEEPS: Record<string, string> = {
  // Tony Strickland holds a State Senate seat, so an office match cannot rescue a Controller
  // committee. Operator ruling 2026-08-16: it is the same Tony Strickland, who really did run for
  // Controller statewide in 2010, and his donations should be merged onto him.
  '1325751': 'operator ruling 2026-08-16: same Tony Strickland; his real 2010 statewide Controller run',
  // Task 6. Same man, same reasoning as above: he really did hold a State Senate seat. The rule could
  // not reach it because essentials has NO office_terms row for him at all, so both the office and
  // OFFICEHOLDER routes are structurally unable to fire -- a gap in our data, not evidence against him.
  // ⚠ Deliberately NOT extended to filer 1285101 "STRICKLAND FOR JUDGE, COMMITTEE TO ELECT": he has
  // never been a judge, so that is very probably a different Strickland and it stays purged. The
  // ruling is per committee, not per person.
  '1294413': 'operator ruling 2026-08-16: same Tony Strickland; his real State Senate service, which no office record of ours can corroborate',
};

// ── Office corroboration: the SECOND proof route ─────────────────────────────────────────────────
// Cal-Access routinely omits an incumbent's given name from their own committee ("NEWSOM FOR
// CALIFORNIA GOVERNOR 2022"), so a given-name-only test purges verified-correct money. The office
// the politician actually holds is an affirmative tie of the same kind.
export function officeKeywords(offices: { title: string | null; chamber: string | null }[]): string[] {
  const kws = new Set<string>();
  for (const o of offices) {
    const s = `${o.title ?? ''} ${o.chamber ?? ''}`.toLowerCase();
    if (/lieutenant governor/.test(s)) kws.add('lieutenant governor');
    else if (/\bgovernor\b/.test(s)) kws.add('governor');
    if (/assembly/.test(s)) kws.add('assembly');
    if (/\bsenate\b|\bsenator\b/.test(s)) kws.add('senate');
    if (/supervisor/.test(s)) kws.add('supervisor');
    if (/\bmayor\b/.test(s)) kws.add('mayor');
    // 'council' as well as 'city council': Cal-Access routinely registers the seat as plain
    // "OHLSEN FOR COUNCIL 2026" / "RICKS-ODDIE FOR COUNCIL 2022", which 'city council' cannot match.
    // Those read as no-corroboration and were purged, though both are sitting council members.
    if (/city council|councilmember|council member|councilwoman|councilman/.test(s)) { kws.add('city council'); kws.add('council'); }
    if (/attorney general/.test(s)) kws.add('attorney general');
    if (/controller/.test(s)) kws.add('controller');
    if (/treasurer/.test(s)) kws.add('treasurer');
    if (/sheriff/.test(s)) kws.add('sheriff');
    // 'school' as well: the same seat is registered as "...CORONADO UNIFIED SCHOOL DISTRICT 2022",
    // which neither 'school board' nor 'board of education' matches.
    if (/board of education|school/.test(s)) { kws.add('school board'); kws.add('board of education'); kws.add('school'); }
    if (/water/.test(s)) kws.add('water');
    if (/judge|court/.test(s)) kws.add('judge');
    // ── Added 2026-08-16, Task 6 step 1 ────────────────────────────────────────────────────────
    // Audited against the DISTINCT (offices.title, chambers.name) actually held by the 304 links'
    // politicians. Seven pairs produced no keyword at all, and an unrecognised office is silently
    // indistinguishable from "no corroboration" -- which under prove-it-right means a PURGE. The
    // largest gap by far was Board of Trustees (19 politicians).
    if (/board of trustees|\btrustee\b/.test(s)) {
      kws.add('trustee');            // committees read "FOR CUSD TRUSTEE AREA 7"
      kws.add('school board');       // ...and, for the same seat, "FOR SCHOOL BOARD"
      kws.add('board of education');
    }
    if (/district attorney/.test(s)) kws.add('district attorney');
    if (/\bassessor\b/.test(s)) kws.add('assessor');
    if (/\bauditor\b/.test(s)) kws.add('auditor');
    if (/public utilities/.test(s)) kws.add('public utilities');
    if (/house of representatives|\bcongress/.test(s)) kws.add('congress');
  }
  return [...kws];
}

/**
 * A trailing personal name after ',' or ';' that is NOT this politician's.
 * 🔑 Disproof OUTRANKS office corroboration: Rob Bonta once held an Assembly seat, so "BONTA FOR
 * ASSEMBLY 2024; MIA" would be rescued by an office match. The "; MIA" must veto it.
 */
export function conflictingGivenName(official: string, first: string): string | null {
  const ORG = new Set(['committee', 'friends', 'the', 'a', 'citizens', 'of', 'inc', 'council', 'board',
    'mayor', 'supervisor', 'assembly', 'senate', 'sheriff', 'treasurer', 'governor', 'ii', 'iii', 'jr', 'sr',
    'reelect', 're-elect', 'elect', 'campaign', 'officeholder', 'director', 'trustee', 'clerk', 'auditor',
    'assessor', 'attorney', 'controller', 'city', 'county', 'district', 'account', 'special', 'for', 'and',
    // Stance and sponsorship verbs, added 2026-08-16 (Task 7). A committee's posture is not a person:
    // "...; BUILDING A STRONGER CALIFORNIA, SUPPORTING HEATHER" is Heather Hutt's OWN committee and
    // "BONTA FOR ASSEMBLY 2012, ... SUPPORT ROB" is Rob Bonta's, yet both read as naming someone else
    // because the verb sat where the given name was expected. Skipping these reaches the real name
    // behind them -- "OPPOSING CARL" still correctly disproves, now citing CARL rather than OPPOSING.
    'opposing', 'supporting', 'support', 'against', 'neighbors', 'judge', 'voters', 'residents',
    'leaders', 'coalition', 'alliance', 'team', 'group', 'fund', 'sponsored', 'funding', 'major']);

  // Pattern 1 (original): a bare given name trailing a comma or semicolon -- "...; MIA".
  // Pattern 2 (added 2026-08-16, Task 6): the same disproof written as a phrase -- "..., COMMITTEE TO
  // ELECT BERT", "..., FRIENDS OF DOUGLAS O.". 40+ of the 69 links this pass labelled `unprovable`
  // in fact name another person in exactly this shape; calling those "no evidence either way"
  // understated what the record actually says and skewed the disproof rate the operator gates on.
  // Deliberately narrow: it fires only on these fixed lead-ins followed by 1-3 name-like tokens, so
  // trailing fragments such as "SANTOS, SAN LEANDRANS FOR" stay honestly unprovable rather than
  // being asserted as disproof we do not have.
  const candidates: string[] = [];
  // The trailing segment after the last comma/semicolon, capped at TWO tokens so a real name plus an
  // initial or nickname is seen ("FRANK J.", "WILLIAM \"BILL\"", "CASTULO R.") while a longer
  // fragment that is not a person ("SANTOS, SAN LEANDRANS FOR") is left alone rather than asserted
  // as disproof we do not have.
  const seg = official.match(/[,;]\s*([^,;]+?)\s*$/);
  if (seg) {
    const toks = seg[1].trim().split(/\s+/);
    if (toks.length <= 2) for (const t of toks) if (/[A-Za-z]{2,}/.test(t)) candidates.push(t);
  }
  const m2 = official.match(/\b(?:COMMITTEE TO ELECT|FRIENDS TO ELECT|COMMITTEE TO SUPPORT|COMMITTEE FOR|NEIGHBORS FOR|SUPPORTERS OF|FRIENDS OF|TO SUPPORT|TO ELECT|ELECT)\s+((?:[A-Za-z'’.-]+|"[A-Za-z'’.-]+")(?:\s+(?:[A-Za-z'’.-]+|"[A-Za-z'’.-]+")){0,2})\s*$/i);
  if (m2) candidates.push(m2[1].trim().split(/\s+/)[0]);

  const given = givenName(first);
  for (const raw of candidates) {
    const tail = fold(raw.toLowerCase()).replace(/[.'’"]/g, '');
    if (!tail || ORG.has(tail) || TITLES.has(tail)) continue;
    if (tail === fold(given)) continue;
    if ((DIMINUTIVES[given] ?? []).some(d => tail === d)) continue;
    return raw;
  }
  return null;
}

// Without these, the rule falsely demotes correct links at scale: a politician stored as "Robert"
// whose committee reads "BOB SMITH FOR COUNCIL" would fail an exact given-name test.
export const DIMINUTIVES: Record<string, string[]> = {
  robert: ['bob', 'rob', 'bobby'], james: ['jim', 'jimmy'], william: ['bill', 'will', 'billy'],
  richard: ['rick', 'dick', 'rich'], michael: ['mike'], joseph: ['joe'], thomas: ['tom'],
  charles: ['chuck', 'charlie'], daniel: ['dan', 'danny'], christopher: ['chris'],
  elizabeth: ['liz', 'beth', 'betty'], katherine: ['kate', 'kathy', 'katie'], kathryn: ['kate', 'kathy'],
  patricia: ['pat', 'patty'], jennifer: ['jen', 'jenny'], deborah: ['deb', 'debbie'],
  susan: ['sue'], margaret: ['peggy', 'maggie'], anthony: ['tony'], nicholas: ['nick'],
  benjamin: ['ben'], alexander: ['alex'], gregory: ['greg'], steven: ['steve'], stephen: ['steve'],
  edward: ['ed', 'eddie'], ronald: ['ron'], donald: ['don'], kenneth: ['ken'],
};

const esc = (s: string) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/**
 * Strip diacritics before comparing names.
 * 🔴 Found 2026-08-16 in Task 6: "MUNOZ-GUEVARA FOR LYNWOOD CITY COUNCIL 2022; JUAN" was classified
 * `no-surname` for Juan Muñoz-Guevara and would have been purged with his $7,435 -- Cal-Access stores
 * committee names unaccented while `essentials.politicians.last_name` keeps the accent, so `\bmuñoz`
 * cannot match `MUNOZ`. The failure is silent and looks exactly like a genuinely different surname.
 */
export const fold = (s: string) => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '');

const hasWord = (hay: string, needle: string) =>
  needle.length > 0 && new RegExp('\\b' + esc(fold(needle)) + '\\b', 'i').test(fold(hay));

/**
 * Titles are not names -- on either side of the comparison.
 * 🔴 Found 2026-08-16 in Task 6: `essentials.politicians.first_name` for "Dr. Monica Sanchez" begins
 * with the title, so taking the first whitespace token yielded "dr." as her given name. Both of her
 * committees -- one of which literally ends "; DR. MONICA" -- were then read as naming a different
 * person and flipped from keep to purge. The given name must be the first token that is not a title.
 */
export const TITLES = new Set(['dr', 'mr', 'mrs', 'ms', 'miss', 'rev', 'hon', 'sgt', 'capt', 'prof', 'md', 'phd']);

export function givenName(first: string): string {
  const toks = fold(String(first ?? '').trim().toLowerCase()).replace(/[.'’]/g, ' ').split(/\s+/).filter(Boolean);
  for (const t of toks) if (!TITLES.has(t)) return t;
  return toks[0] ?? '';
}

/**
 * The committee leads with a DIFFERENT surname: "NAGRA FOR LATHROP CITY COUNCIL 2020".
 * Cal-Access committee names open with the candidate's surname followed by "FOR", so when that
 * opening token is not our politician, their surname is appearing incidentally -- as the CITY in the
 * Lathrop case, and as a given name elsewhere ("BRADY FOR PLACENTIA CITY COUNCIL, SCOTT P.").
 * Another disproof, so it must outrank the office route: without it "NAGRA FOR LATHROP CITY COUNCIL"
 * corroborates on 'city council' and Bruce Lathrop keeps money that is Nagra's.
 * Returns the conflicting leading surname, or null when the committee leads with our own.
 */
export function leadingDifferentSurname(official: string, last: string): string | null {
  const m = official.match(/^([A-Za-z'’-]+)\s+FOR\s+/i);
  if (!m) return null;                       // no "<SURNAME> FOR ..." opening; says nothing either way
  const lead = fold(m[1].toLowerCase()).replace(/[.'’]/g, '');
  const surname = fold(last.trim().toLowerCase());
  if (!lead || !surname) return null;
  if (lead === surname) return null;
  // A multi-word surname legitimately opens with its own first word ("DE LEON FOR ...").
  if (surname.split(/[\s-]/)[0] === lead) return null;
  return m[1];
}

/** True when `official` carries BOTH the surname and the given name (or a known diminutive). */
export function namesThem(official: string, first: string, last: string): boolean {
  const o = official.toLowerCase();
  const given = givenName(first);
  const surname = last.trim().toLowerCase();
  if (!hasWord(o, surname)) return false;
  if (hasWord(o, given)) return true;
  for (const d of DIMINUTIVES[given] ?? []) if (hasWord(o, d)) return true;
  return false;
}

async function main() {
  const MIGRATION_NUMBER = process.env.MIGRATION_NUMBER ?? '1790';
  const worklist = JSON.parse(fs.readFileSync(path.join(DIR, 'worklist.json'), 'utf8'));
  const filers = JSON.parse(fs.readFileSync(path.join(DIR, 'filer-records.json'), 'utf8'));

  // Offices held, for the second proof route.
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

  const decisions = worklist.map((r: any) => {
    const kws = officeKeywords(officesByPid[r.politician_id] ?? []);
    if (r.verdict === 'names-them') {
      return { ...r, decision: 'keep', basis: 'committee name in our DB already names them', official_name: r.committee_name, office_keywords: kws };
    }
    const rec = filers[r.filer_id];
    const official = rec?.status === 'ok' ? rec.official_name : '';
    const base = { ...r, official_name: official, office_keywords: kws };

    if (OPERATOR_KEEPS[r.filer_id]) {
      return { ...base, decision: 'keep', basis: OPERATOR_KEEPS[r.filer_id] };
    }
    if (!official) {
      return { ...base, decision: 'purge', basis: `no official record retrievable (${rec?.status ?? 'missing'}); unprovable` };
    }
    // Route 1 — the official name carries surname AND given name.
    if (namesThem(official, r.first_name, r.last_name)) {
      return { ...base, decision: 'keep', basis: `official name "${official}" carries their surname and given name` };
    }
    // Surname absent entirely: not their committee under any route.
    if (!new RegExp('\\b' + r.last_name.trim().toLowerCase().replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\b', 'i').test(official)) {
      return { ...base, decision: 'purge', basis: `official name "${official}" does not contain their surname` };
    }
    // Disproof outranks corroboration.
    const conflict = conflictingGivenName(official, r.first_name);
    if (conflict) {
      return { ...base, decision: 'purge', basis: `official name "${official}" names a different person ("${conflict}")` };
    }
    // Route 2 — the office they actually hold.
    const hit = kws.find(k => official.toLowerCase().includes(k));
    if (hit) {
      return { ...base, decision: 'keep', basis: `official name "${official}" matches the office they hold (${hit})` };
    }
    return { ...base, decision: 'purge', basis: `official name "${official}" gives no given name and no office match [holds: ${kws.join(', ') || 'no office recorded'}]` };
  });

  fs.writeFileSync(path.join(DIR, 'track-a-decisions.json'), JSON.stringify(decisions, null, 2));

  const purge = decisions.filter((d: any) => d.decision === 'purge');
  const keep = decisions.filter((d: any) => d.decision === 'keep');
  const money = (rows: any[]) => rows.reduce((a, r) => a + r.dollars, 0);
  const withMoney = purge.filter((d: any) => d.dollars > 0);

  console.log(`keep  ${keep.length} links  $${money(keep).toFixed(2)}`);
  console.log(`purge ${purge.length} links  $${money(purge).toFixed(2)}`);
  console.log(`wrong-rate: ${(100 * purge.length / decisions.length).toFixed(1)}% of the top ${decisions.length}\n`);
  for (const p of purge) {
    console.log(`  PURGE  $${p.dollars.toFixed(2).padStart(12)}  ${p.politician_name}  <-  ${p.official_name || '(no official record)'}`);
  }

  // ── generate the migration ──────────────────────────────────────────────────
  const lit = (ids: string[]) => ids.map(i => `'${i}'`).join(',\n   ');
  const purgeIds = purge.map((d: any) => d.source_id);
  const moneyIds = withMoney.map((d: any) => d.source_id);
  const keepIds = keep.map((d: any) => d.source_id);
  const purgeDollars = money(purge).toFixed(2);
  const keepDollars = money(keep).toFixed(2);

  const sql = `-- ${MIGRATION_NUMBER}_cal_access_track_a.sql
-- Cal-Access bucket B, Track A: the money. Verified against the OFFICIAL Cal-Access filer record.
--
-- Spec: docs/superpowers/specs/2026-08-16-cal-access-bucket-b-design.md
-- Decisions, with the official name and basis for every link:
--   backend/data/cal-access-bucket-b/track-a-decisions.json
--
-- confirm-cal-access.ts linked committees on the LAST TOKEN of full_name and confirmed its own
-- guesses in the same pass (7,836 of 7,853 "confirmed"). Migration 1789 cleared bucket A, where that
-- token was not even the surname. This is the money half of what remained: the top ${decisions.length} links by
-- displayed dollars, which carry 94.4% of all cal_access money on active politicians.
--
-- Each link needing evidence was resolved by fetching its Cal-Access filer record and reading the
-- OFFICIAL registered committee name -- the field the script should have used. Keep when that name
-- carries both the politician's surname and their given name (or a diminutive); purge otherwise,
-- including when no official record could be retrieved. That is the operator's prove-it-right posture.
--
-- ⚠ The filer records could NOT be fetched by a script: Cal-Access sits behind Incapsula, which
-- refuses a freshly launched Chromium and returns an EMPTY BODY with a 200 rather than an error.
-- See backend/scripts/cal-access-bucket-b/02-fetch-filers.ts for the full failure ladder.
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

  -- The keeps are the entire point of doing evidence work. Assert they survived UNCHANGED -- a bug
  -- that widened the purge satisfies every check above.
  SELECT count(*) INTO n FROM transparent_motivations.politician_sources ps JOIN ta_keep k ON k.sid = ps.id
   WHERE ps.research_status = 'confirmed';
  IF n <> ${keep.length} THEN RAISE EXCEPTION 'guard: % of ${keep.length} kept links still confirmed', n; END IF;
  SELECT round(coalesce(sum(g.total_amount),0)::numeric,2) INTO d
    FROM transparent_motivations.contribution_summary_agg g JOIN ta_keep k ON k.sid = g.politician_source_id;
  IF d <> ${keepDollars} THEN RAISE EXCEPTION 'guard: kept money is now %, expected ${keepDollars} untouched', d; END IF;

  RAISE NOTICE 'cal_access Track A: ${purge.length} links purged, ${keep.length} kept';
END $$;

COMMIT;
`;

  fs.writeFileSync(path.join(process.cwd(), 'migrations', `${MIGRATION_NUMBER}_cal_access_track_a.sql`), sql);
  console.log(`\nwrote migrations/${MIGRATION_NUMBER}_cal_access_track_a.sql`);
}

// Guarded so Track B can import namesThem() without re-running the generator.
if (process.argv[1]?.replace(/\\/g, '/').endsWith('03-classify-track-a.ts')) main();

export { };
