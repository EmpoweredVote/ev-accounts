#!/usr/bin/env node
/**
 * WA 2026 primary CERTIFICATION PASS, step 2 of 2 — emit the migration from disposition.json.
 *
 * Run wa-cert-harvest.mjs first. Writes migrations/_wip_wa_2026_primary_certification_pass.sql
 * with an NNNN placeholder in its header comment: TAKE THE MIGRATION NUMBER LAST, then rename.
 *
 * The result_source citation is BUILT IN SQL from the same tally rows that drive the disposition,
 * so the citation and the decision cannot drift apart.
 *
 *   node scripts/wa-cert-emit-migration.mjs [feed-dir]
 */
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

/** Resolve a path relative to this script, Windows-drive-safe. */
const local = (rel) => fileURLToPath(new URL(rel, import.meta.url));

const SP = process.argv[2] || local('../.tmp-wa-cert');
const d = JSON.parse(fs.readFileSync(`${SP}/disposition.json`, 'utf8'));

const HELD = 'WA State Senate Legislative District 42'; // hand recount, RCW 29A.64.021
const NOPRIMARY = [
  'King County Council District 4',
  'King County Council District 6',
  'King County Director of Elections',
  'King County Prosecuting Attorney',
];

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;

// ── per-candidate tally rows (skip the held race)
const tally = [];
for (const disp of ['advanced', 'not_nominated']) {
  for (const r of d[disp]) {
    if (r.race === HELD) continue;
    tally.push({ race: r.race, name: r.name, feed_name: r.feed_name, votes: r.votes, disp });
  }
}
tally.sort((a, b) => a.race.localeCompare(b.race) || b.votes - a.votes);

// ── per-race contest metadata
const FEEDURL = {
  king: 'results.votewa.gov/results/public/api/elections/king-county-wa/20260804/data',
  kitsap: 'results.votewa.gov/results/public/api/elections/kitsap-county-wa/20260804/data',
  state: 'results.votewa.gov/results/public/api/elections/washington/20260804/data',
};
const CERTNOTE = {
  king: 'King County Canvassing Board certification 2026-08-18; verified line-by-line against King County Elections webresults-20260818-final.csv',
  kitsap: 'Kitsap County Canvassing Board certification 2026-08-18; verified line-by-line against the Kitsap County Auditor cumulative report (kitsap.gov/auditor/Documents/results.html, "Official Results", Run Date 08/18/2026, 321 of 321 precincts)',
  state: 'WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; spot-verified identical to the King County certified CSV on four King-only districts (LD 37 Senate, LD 43 Pos. 2, LD 46 Pos. 1, LD 47 Pos. 1)',
};

const contests = [];
for (const r of d.races) {
  if (r.status !== 'OK' || r.position_name === HELD) continue;
  const total = r.ranked_votes.reduce((a, b) => a + b, 0) + (r.writein_votes || 0);
  contests.push({ race: r.position_name, contest: r.contest, feed: r.feed, total, writein: r.writein_votes || 0 });
}
contests.sort((a, b) => a.race.localeCompare(b.race));

const nAdv = tally.filter((t) => t.disp === 'advanced').length;
const nNot = tally.filter((t) => t.disp === 'not_nominated').length;
const withdrawn = d.problems.filter((p) => p.why === 'OURS_NOT_IN_CERTIFIED_CANVASS');

const L = [];
const p = (s = '') => L.push(s);

p(`-- NNNN_wa_2026_primary_certification_pass.sql`);
p(`--`);
p(`-- THE CERTIFICATION CULL for every race on the WA 2026 Statewide General`);
p(`-- (election 51e7a875-bff9-4e96-adcf-41736454d25d). Migrations 1747 and 1750 seeded the`);
p(`-- 2026-08-04 top-two primary field from a PRE-CERTIFICATION results feed and wrote, in`);
p(`-- prose, "Pre-certification field; cull gates on the certified canvass" with`);
p(`-- provisional_until = 2026-08-24. This is that gate.`);
p(`--`);
p(`-- ============================================================================`);
p(`-- WHAT MAKES THE SOURCE CERTIFIED, AND HOW THAT WAS PROVEN RATHER THAN ASSUMED`);
p(`-- ============================================================================`);
p(`-- WA county canvassing boards certified the August primary on 2026-08-18; the Secretary of`);
p(`-- State's deadline to certify the state primary is 2026-08-21. All three results feeds now`);
p(`-- carry election.isOfficialResults = true:`);
p(`--`);
p(`--   statewide  ${FEEDURL.state}`);
p(`--              lastUpdated 2026-08-19T13:39:21Z   (10 congressional + 98 house + 24 senate)`);
p(`--   King       ${FEEDURL.king}`);
p(`--              lastUpdated 2026-08-18T21:36:40Z   (Assessor, Council 2/8, Seattle Council 5)`);
p(`--   Kitsap     ${FEEDURL.kitsap}`);
p(`--              lastUpdated 2026-08-18T00:01:49Z   (7 county offices)`);
p(`--`);
p(`-- 🔴 A FLAG IN A FEED IS THE FEED'S OWN CLAIM. Each was checked against the jurisdiction's`);
p(`-- own certified document before a single row was culled:`);
p(`--   King:   webresults-20260818-final.csv (cdn.kingcounty.gov/-/media/king-county/depts/`);
p(`--           elections/results/2026/08/) — Assessor, Council 2, Council 8 and Seattle 5 match`);
p(`--           candidate-for-candidate. Total Ballots Cast 534,500 matches the feed exactly.`);
p(`--   Kitsap: the Auditor's own cumulative report (kitsap.gov/auditor/Documents/results.html),`);
p(`--           header "Primary 8/4/2026 Official Results ... Run Date 08/18/2026 ... Precincts`);
p(`--           Reporting 321 of 321 = 100.00%" — all 7 county contests match to the vote.`);
p(`--   State:  four districts wholly inside King County (LD 37 Senate, LD 43 Pos. 2, LD 46`);
p(`--           Pos. 1, LD 47 Pos. 1) return numbers IDENTICAL to King's certified CSV, which is`);
p(`--           what an aggregate of certified county canvasses should do.`);
p(`--`);
p(`-- 🔴 A WEB SEARCH SUMMARY CONTRADICTED THE FEED ON THE KITSAP SHERIFF RACE and was wrong:`);
p(`-- it reported Myers 28,094 / Kuss 19,827 against the correct 48,117 / 34,768. The ratio was`);
p(`-- right and the magnitude was not, which is exactly what a garbled figure looks like. The`);
p(`-- Auditor's own report settled it. Raw jurisdiction documents only.`);
p(`--`);
p(`-- ============================================================================`);
p(`-- 🔴 THE ONE RACE THIS MIGRATION REFUSES TO CULL: LD 42 STATE SENATE`);
p(`-- ============================================================================`);
p(`-- Certified: Creydt (REP) 22,125 / Shepard (DEM) 13,125 / Collins (DEM) 13,121 / Bowman 1,248.`);
p(`-- SECOND AND THIRD ARE FOUR VOTES APART — 0.015% of their combined total. RCW 29A.64.021`);
p(`-- makes a HAND recount mandatory under 150 votes and 0.25%, and Whatcom County has scheduled`);
p(`-- it for 2026-08-25 08:00 at the Election Center, Whatcom County Courthouse. A certified cut`);
p(`-- line inside the mandatory-recount margin is not a settled field: culling Collins today`);
p(`-- would delete a candidate who may be on the November ballot.`);
p(`-- All four LD 42 rows therefore keep result = NULL and get provisional_until = 2026-09-04.`);
p(`-- Re-enter after the recount is certified: .planning/todos/2026-08-25-wa-ld42-senate-recount.md`);
p(`--`);
p(`-- The check that found it is a MARGIN test, not a tie test. An exact-tie guard would have`);
p(`-- passed this race green and shipped the cull.`);
p(`--`);
p(`-- ============================================================================`);
p(`-- WHY THE WRITE-IN LINE IS EXCLUDED BY NAME AND NOT BY ITS FLAG`);
p(`-- ============================================================================`);
p(`-- 🔴 ballotOptions.isWriteIn IS UNRELIABLE IN THIS FEED: 3 of 137 write-in lines statewide`);
p(`-- and 41 of 60 in the King feed carry isWriteIn = false. Trusting the flag puts a line called`);
p(`-- "Write-in" into the candidate ranking. It changed no disposition here only because every`);
p(`-- affected contest had a single real candidate, so the write-in took an unoccupied second`);
p(`-- slot — in a three-way contest it would have displaced a real advancer. Detection is by`);
p(`-- name; an actually-qualified write-in appears under the person's own name, never "Write-in".`);
p(`--`);
p(`-- ============================================================================`);
p(`-- DISPOSITION OF ALL 394 ROWS ON THIS ELECTION`);
p(`-- ============================================================================`);
p(`--   ${String(nAdv).padStart(3)}  result = 'advanced'      top two (or the sole candidate) in a certified contest`);
p(`--   ${String(nNot).padStart(3)}  result = 'not_nominated' ran and did not make the top two`);
p(`--     5  result = 'withdrew'      withdrew before the ballot; ABSENT from the certified canvass`);
p(`--     4  result stays NULL        LD 42 Senate — mandatory hand recount, see above`);
p(`--     4  result stays NULL        4 King County offices that HELD NO PRIMARY (sole filer)`);
p(`--`);
p(`-- essentials.is_live_candidate (migration 1582) is what makes this a cull: 'not_nominated'`);
p(`-- and candidate_status 'withdrawn' both drop out of every read path. Live field afterwards is`);
p(`-- ${nAdv} + 4 (LD 42) + 4 (unopposed King County) = ${nAdv + 8} of 394.`);
p(`--`);
p(`-- 🔴 THE 4 KING COUNTY OFFICES WITH NO PRIMARY DO NOT GET A RESULT. King County Council`);
p(`-- Districts 4 and 6, Director of Elections and Prosecuting Attorney drew a single filer each,`);
p(`-- and under WA law a nonpartisan race with no more than twice as many candidates as positions`);
p(`-- skips the primary entirely. There is no canvass line to cite, so there is no result to`);
p(`-- record — but their ABSENCE from a certified canvass does confirm the field, so`);
p(`-- provisional_until goes to NULL. Writing 'advanced' here would cite a contest that was`);
p(`-- never held.`);
p(`--`);
p(`-- 🔴 THE 5 WITHDRAWN ROWS ARE CONFIRMED BY ABSENCE, AND THAT IS A REAL FINDING. Joel Ard`);
p(`-- (LD 23 Pos. 1), Brett Johnson (LD 29 Pos. 1), Julia Payne (LD 6 Pos. 1), Emijah Smith`);
p(`-- (LD 37 Senate) and Douglas McKinley (LD 8 Senate) appear NOWHERE in the certified canvass`);
p(`-- of their race, which is what a pre-ballot withdrawal looks like. Note Julia Payne is a`);
p(`-- LIVE candidate in LD 6 Position 2 in the same certified canvass — she moved position, she`);
p(`-- did not leave the ballot, and only the Position 1 row is closed here.`);
p(`--`);
p(`-- MATCHING. 143 of 147 races mapped to a certified contest by parsed district/position`);
p(`-- number, never by fuzzy title. Candidate matching is 1:1 within the matched contest on an`);
p(`-- NFD-stripped normalised name; ONE row needed a fallback (last name + first initial, unique`);
p(`-- on both sides): "Suzan K. DelBene" -> "Suzan DelBene". Zero certified candidates were`);
p(`-- missing from our field in any race, and zero of our rows went unexplained.`);
p(`--`);
p(`-- Idempotent: every UPDATE is guarded on the value it is about to write.`);
p(``);
p(`BEGIN;`);
p(``);
p(`-- ── the certified tally, one row per candidate, from the feeds named above ──────────────────`);
p(`CREATE TEMP TABLE wa_cert_tally (`);
p(`  position_name text NOT NULL,`);
p(`  cand_name     text NOT NULL,`);
p(`  feed_name     text NOT NULL,`);
p(`  votes         integer NOT NULL,`);
p(`  disposition   text NOT NULL CHECK (disposition IN ('advanced','not_nominated'))`);
p(`) ON COMMIT DROP;`);
p(``);
p(`INSERT INTO wa_cert_tally (position_name, cand_name, feed_name, votes, disposition) VALUES`);
{
  const lines = tally.map(
    (t) => `  (${q(t.race)}, ${q(t.name)}, ${q(t.feed_name)}, ${t.votes}, ${q(t.disp)})`,
  );
  p(lines.join(',\n') + ';');
}
p(``);
p(`-- ── per-contest provenance, used to BUILD result_source from the same numbers ───────────────`);
p(`CREATE TEMP TABLE wa_cert_contest (`);
p(`  position_name text PRIMARY KEY,`);
p(`  contest_name  text NOT NULL,`);
p(`  feed_url      text NOT NULL,`);
p(`  cert_note     text NOT NULL,`);
p(`  total_votes   integer NOT NULL,   -- contest total INCLUDING the write-in line`);
p(`  writein_votes integer NOT NULL`);
p(`) ON COMMIT DROP;`);
p(``);
p(`INSERT INTO wa_cert_contest VALUES`);
{
  const lines = contests.map(
    (c) => `  (${q(c.race)}, ${q(c.contest)}, ${q(FEEDURL[c.feed])}, ${q(CERTNOTE[c.feed])}, ${c.total}, ${c.writein})`,
  );
  p(lines.join(',\n') + ';');
}
p(``);
p(`-- ── resolve to race_candidates rows, 1:1, and REFUSE to proceed on any ambiguity ────────────`);
p(`CREATE TEMP TABLE wa_cert_target AS`);
p(`SELECT rc.id AS rc_id, t.position_name, t.cand_name, t.votes, t.disposition,`);
p(`       'CERTIFIED canvass of the 2026-08-04 Washington top-two primary, "' || c.contest_name || '" ('`);
p(`         || c.feed_url || ', election.isOfficialResults = true; ' || c.cert_note || '; fetched 2026-08-20). '`);
p(`         || 'Advancing to the 2026-11-03 general: ' || adv.names || '. '`);
p(`         || 'Full certified tally: ' || tot.tally || '. '`);
p(`         || 'Contest total ' || to_char(c.total_votes, 'FM999,999,999') || ' votes'`);
p(`         || CASE WHEN c.writein_votes > 0 THEN ' (including ' || to_char(c.writein_votes, 'FM999,999,999') || ' write-in)' ELSE '' END`);
p(`         || '.' AS result_source`);
p(`  FROM wa_cert_tally t`);
p(`  JOIN wa_cert_contest c ON c.position_name = t.position_name`);
p(`  JOIN essentials.races r`);
p(`    ON r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
p(`   AND r.position_name = t.position_name`);
p(`  JOIN essentials.race_candidates rc`);
p(`    ON rc.race_id = r.id`);
p(`   AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key(t.cand_name)`);
p(`  CROSS JOIN LATERAL (`);
p(`    SELECT string_agg(t2.feed_name, ' and ' ORDER BY t2.votes DESC) AS names`);
p(`      FROM wa_cert_tally t2`);
p(`     WHERE t2.position_name = t.position_name AND t2.disposition = 'advanced'`);
p(`  ) adv`);
p(`  CROSS JOIN LATERAL (`);
p(`    SELECT string_agg(t3.feed_name || ' ' || to_char(t3.votes, 'FM999,999,999'), ' / ' ORDER BY t3.votes DESC) AS tally`);
p(`      FROM wa_cert_tally t3`);
p(`     WHERE t3.position_name = t.position_name`);
p(`  ) tot;`);
p(``);
p(`DO $$`);
p(`DECLARE n_tally int; n_target int; n_dupe int;`);
p(`BEGIN`);
p(`  SELECT count(*) INTO n_tally  FROM wa_cert_tally;`);
p(`  SELECT count(*) INTO n_target FROM wa_cert_target;`);
p(`  SELECT count(*) INTO n_dupe   FROM (SELECT rc_id FROM wa_cert_target GROUP BY rc_id HAVING count(*) > 1) x;`);
p(`  IF n_tally <> ${tally.length} THEN RAISE EXCEPTION 'tally is % rows, expected ${tally.length}', n_tally; END IF;`);
p(`  IF n_target <> ${tally.length} THEN RAISE EXCEPTION 'resolved % of ${tally.length} tally rows to race_candidates — a name did not match', n_target; END IF;`);
p(`  IF n_dupe > 0 THEN RAISE EXCEPTION '% race_candidates rows matched more than one tally row', n_dupe; END IF;`);
p(`END $$;`);
p(``);
p(`-- ── 1. the cull ────────────────────────────────────────────────────────────────────────────`);
p(`UPDATE essentials.race_candidates rc`);
p(`   SET result = t.disposition,`);
p(`       result_source = t.result_source,`);
p(`       result_recorded_at = now(),`);
p(`       last_verified_at = now(),`);
p(`       provisional_until = NULL,`);
p(`       updated_at = now()`);
p(`  FROM wa_cert_target t`);
p(` WHERE rc.id = t.rc_id`);
p(`   AND (rc.result IS DISTINCT FROM t.disposition`);
p(`        OR rc.result_source IS DISTINCT FROM t.result_source`);
p(`        OR rc.provisional_until IS NOT NULL);`);
p(``);
p(`-- ── 2. the 5 pre-ballot withdrawals, confirmed by ABSENCE from the certified canvass ────────`);
{
  const rows = [
    ['WA House of Representatives Legislative District 23 Position 1', 'Joel Ard', 'State Representative Pos. 1 - Legislative District 23'],
    ['WA House of Representatives Legislative District 29 Position 1', 'Brett Johnson', 'State Representative Pos. 1 - Legislative District 29'],
    ['WA House of Representatives Legislative District 6 Position 1', 'Julia Payne', 'State Representative Pos. 1 - Legislative District 6'],
    ['WA State Senate Legislative District 37', 'Emijah Smith', 'State Senator - Legislative District 37'],
    ['WA State Senate Legislative District 8', 'Douglas McKinley', 'State Senator - Legislative District 8'],
  ];
  p(`UPDATE essentials.race_candidates rc`);
  p(`   SET result = 'withdrew',`);
  p(`       result_source = 'Withdrew before the ballot was set. ABSENT from the certified canvass of the 2026-08-04 Washington top-two primary, "' || w.contest_name || '" (${FEEDURL.state}, election.isOfficialResults = true, WA Secretary of State aggregate of the certified county canvasses, feed lastUpdated 2026-08-19; fetched 2026-08-20), which lists every name that appeared on the primary ballot for this contest. candidate_status was already ''withdrawn'' from the WA SoS candidate filings; this records the certified confirmation.',`);
  p(`       result_recorded_at = now(),`);
  p(`       last_verified_at = now(),`);
  p(`       provisional_until = NULL,`);
  p(`       updated_at = now()`);
  p(`  FROM (VALUES`);
  p(rows.map(([race, name, contest]) => `        (${q(race)}, ${q(name)}, ${q(contest)})`).join(',\n'));
  p(`       ) AS w(position_name, cand_name, contest_name)`);
  p(`  JOIN essentials.races r`);
  p(`    ON r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
  p(`   AND r.position_name = w.position_name`);
  p(` WHERE rc.race_id = r.id`);
  p(`   AND essentials.candidate_name_key(rc.full_name) = essentials.candidate_name_key(w.cand_name)`);
  p(`   AND rc.candidate_status = 'withdrawn'`);
  p(`   AND (rc.result IS DISTINCT FROM 'withdrew' OR rc.provisional_until IS NOT NULL);`);
}
p(``);
p(`-- ── 3. the 4 King County offices that held no primary: field confirmed, no result to cite ───`);
p(`UPDATE essentials.race_candidates rc`);
p(`   SET provisional_until = NULL,`);
p(`       last_verified_at = now(),`);
p(`       updated_at = now()`);
p(`  FROM essentials.races r`);
p(` WHERE rc.race_id = r.id`);
p(`   AND r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
p(`   AND r.position_name IN (${NOPRIMARY.map(q).join(', ')})`);
p(`   AND rc.provisional_until IS NOT NULL;`);
p(``);
p(`-- ── 4. LD 42 Senate: HELD for the 2026-08-25 mandatory hand recount ─────────────────────────`);
p(`UPDATE essentials.race_candidates rc`);
p(`   SET provisional_until = DATE '2026-09-04',`);
p(`       last_verified_at = now(),`);
p(`       updated_at = now()`);
p(`  FROM essentials.races r`);
p(` WHERE rc.race_id = r.id`);
p(`   AND r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
p(`   AND r.position_name = ${q(HELD)}`);
p(`   AND rc.provisional_until IS DISTINCT FROM DATE '2026-09-04';`);
p(``);
p(`-- ── POST-VERIFY: every assertion below is a POSITIVE fact about the end state ───────────────`);
p(`DO $$`);
p(`DECLARE`);
p(`  n_adv int; n_not int; n_wd int; n_null int; n_live int;`);
p(`  n_ld42 int; n_ld42_prov int; n_noprim int; n_stale int; n_overfull int; n_nosrc int;`);
p(`BEGIN`);
p(`  SELECT count(*) FILTER (WHERE rc.result = 'advanced'),`);
p(`         count(*) FILTER (WHERE rc.result = 'not_nominated'),`);
p(`         count(*) FILTER (WHERE rc.result = 'withdrew'),`);
p(`         count(*) FILTER (WHERE rc.result IS NULL),`);
p(`         count(*) FILTER (WHERE essentials.is_live_candidate(rc.candidate_status, rc.result))`);
p(`    INTO n_adv, n_not, n_wd, n_null, n_live`);
p(`    FROM essentials.race_candidates rc`);
p(`    JOIN essentials.races r ON r.id = rc.race_id`);
p(`   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d';`);
p(``);
p(`  IF n_adv <> ${nAdv} THEN RAISE EXCEPTION 'advanced = %, expected ${nAdv}', n_adv; END IF;`);
p(`  IF n_not <> ${nNot} THEN RAISE EXCEPTION 'not_nominated = %, expected ${nNot}', n_not; END IF;`);
p(`  IF n_wd  <> 5   THEN RAISE EXCEPTION 'withdrew = %, expected 5', n_wd; END IF;`);
p(`  IF n_null <> 8  THEN RAISE EXCEPTION 'result IS NULL = %, expected 8 (4 LD42 + 4 unopposed King County)', n_null; END IF;`);
p(`  IF n_live <> ${nAdv + 8} THEN RAISE EXCEPTION 'live candidates = %, expected ${nAdv + 8}', n_live; END IF;`);
p(``);
p(`  -- LD 42 must still be a FOUR-WAY UNRESOLVED field held to 2026-09-04. Asserting the`);
p(`  -- positive fact, not "nothing was culled" — a count of 0 culls would pass vacuously.`);
p(`  SELECT count(*), count(*) FILTER (WHERE rc.provisional_until = DATE '2026-09-04' AND rc.result IS NULL)`);
p(`    INTO n_ld42, n_ld42_prov`);
p(`    FROM essentials.race_candidates rc`);
p(`    JOIN essentials.races r ON r.id = rc.race_id`);
p(`   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
p(`     AND r.position_name = ${q(HELD)};`);
p(`  IF n_ld42 <> 4 OR n_ld42_prov <> 4 THEN`);
p(`    RAISE EXCEPTION 'LD 42 Senate: % rows, % held unresolved to 2026-09-04 — expected 4 and 4', n_ld42, n_ld42_prov;`);
p(`  END IF;`);
p(``);
p(`  -- The 4 unopposed King County offices: one live candidate each, no result, no expiry.`);
p(`  SELECT count(*) INTO n_noprim`);
p(`    FROM essentials.race_candidates rc`);
p(`    JOIN essentials.races r ON r.id = rc.race_id`);
p(`   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
p(`     AND r.position_name IN (${NOPRIMARY.map(q).join(', ')})`);
p(`     AND rc.result IS NULL AND rc.provisional_until IS NULL`);
p(`     AND essentials.is_live_candidate(rc.candidate_status, rc.result);`);
p(`  IF n_noprim <> 4 THEN RAISE EXCEPTION 'unopposed King County offices: % live unexpiring rows, expected 4', n_noprim; END IF;`);
p(``);
p(`  -- No race may carry more than TWO live candidates: that is what a top-two general is.`);
p(`  SELECT count(*) INTO n_overfull FROM (`);
p(`    SELECT r.id`);
p(`      FROM essentials.races r`);
p(`      JOIN essentials.race_candidates rc ON rc.race_id = r.id`);
p(`     WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
p(`       AND r.position_name <> ${q(HELD)}`);
p(`       AND essentials.is_live_candidate(rc.candidate_status, rc.result)`);
p(`     GROUP BY r.id HAVING count(*) > 2`);
p(`  ) x;`);
p(`  IF n_overfull > 0 THEN RAISE EXCEPTION '% races still carry more than two live candidates', n_overfull; END IF;`);
p(``);
p(`  -- Nothing on this election may be left stale (provisional_until in the past, unverified).`);
p(`  SELECT count(*) INTO n_stale`);
p(`    FROM essentials.race_candidates rc`);
p(`    JOIN essentials.races r ON r.id = rc.race_id`);
p(`   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
p(`     AND rc.provisional_until IS NOT NULL`);
p(`     AND rc.provisional_until <= CURRENT_DATE`);
p(`     AND (rc.last_verified_at IS NULL OR rc.last_verified_at < rc.provisional_until);`);
p(`  IF n_stale > 0 THEN RAISE EXCEPTION '% rows left stale on this election', n_stale; END IF;`);
p(``);
p(`  -- result without a citation is what the CHECK forbids; prove it did not happen anyway.`);
p(`  SELECT count(*) INTO n_nosrc`);
p(`    FROM essentials.race_candidates rc`);
p(`    JOIN essentials.races r ON r.id = rc.race_id`);
p(`   WHERE r.election_id = '51e7a875-bff9-4e96-adcf-41736454d25d'`);
p(`     AND rc.result IS NOT NULL`);
p(`     AND (rc.result_source IS NULL OR rc.result_source NOT LIKE '%2026-08-04%');`);
p(`  IF n_nosrc > 0 THEN RAISE EXCEPTION '% result rows do not cite the 2026-08-04 canvass', n_nosrc; END IF;`);
p(``);
p(`  RAISE NOTICE 'WA 2026 certification pass OK: % advanced, % not_nominated, % withdrew, % held, % live of 394',`);
p(`    n_adv, n_not, n_wd, n_null, n_live;`);
p(`END $$;`);
p(``);
p(`COMMIT;`);
p(``);

const OUT = local('../migrations/_wip_wa_2026_primary_certification_pass.sql');
fs.writeFileSync(OUT, L.join('\n'));
console.log('wrote _wip_wa_2026_primary_certification_pass.sql');
console.log('tally rows:', tally.length, ' contests:', contests.length, ' advanced:', nAdv, ' not_nominated:', nNot);
console.log('withdrawn problems:', withdrawn.length);
