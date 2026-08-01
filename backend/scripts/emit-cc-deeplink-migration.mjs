#!/usr/bin/env node
/**
 * Emit migration 1514 from the Candidate Connection deep-link proposal, plus its rollback record.
 *
 * Applies ONLY CC_VERIFIED -- rows whose claim was found inside the #Campaign_themes SECTION TEXT.
 * ELSEWHERE_ON_PAGE is deliberately excluded: the claim is on the page but outside the survey, so the
 * anchor would point the reader away from the evidence, which is worse than the bare URL.
 *
 * 🔴 THE ONLY EDIT PERMITTED IS APPENDING #Campaign_themes TO THE URL ALREADY ON THE ROW. Not a
 * different page, not a different host, not a different anchor. The generator re-derives the expected
 * string and refuses any proposal that is not exactly that, so a bug upstream cannot turn a
 * precision fix into a source swap.
 *
 * Usage (from backend/):
 *   node scripts/emit-cc-deeplink-migration.mjs
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import { Pool } from 'pg';

const IN = 'data/stance-retirement/2026-07-31-cc-deeplinks.json';
const SQL = 'migrations/1514_deeplink_candidate_connection_citations.sql';
const ROLLBACK = 'data/stance-retirement/2026-07-31-cc-deeplinks-rollback.json';
const ANCHOR = '#Campaign_themes';

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const proposal = JSON.parse(readFileSync(IN, 'utf8'));
const rows = proposal.rows.filter((r) => r.verdict === 'CC_VERIFIED');

const bad = rows.filter((r) => r.url !== `${r.cited}${ANCHOR}`);
if (bad.length) {
  console.error(`REFUSING: ${bad.length} proposal(s) are not "cited + ${ANCHOR}":`);
  for (const r of bad.slice(0, 5)) console.error(`  ${r.name}: ${r.cited} -> ${r.url}`);
  process.exit(1);
}
const offSite = rows.filter((r) => !/^https:\/\/ballotpedia\.org\//i.test(r.cited));
if (offSite.length) {
  console.error(`REFUSING: ${offSite.length} proposal(s) are not ballotpedia.org URLs`);
  process.exit(1);
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows: before } = await pool.query(
  `SELECT politician_id::text AS pid, topic_id::text AS tid, sources
     FROM inform.politician_context
    WHERE (politician_id::text, topic_id::text) IN (${rows.map((r) => `(${q(r.pid)},${q(r.tid)})`).join(',')})`,
);
await pool.end();
const beforeBy = new Map(before.map((b) => [`${b.pid}|${b.tid}`, b.sources]));
const missing = rows.filter((r) => !beforeBy.has(`${r.pid}|${r.tid}`));
if (missing.length) { console.error(`REFUSING: ${missing.length} target row(s) not in prod`); process.exit(1); }

writeFileSync(ROLLBACK, `${JSON.stringify({
  _comment: 'Rollback record for migration 1514. `before` is the exact sources array as it stood in '
    + 'prod immediately before the migration was generated; restoring it removes the anchors.',
  generated_from: IN,
  rows: rows.map((r) => ({
    pid: r.pid, tid: r.tid, name: r.name, topic: r.topic,
    before: beforeBy.get(`${r.pid}|${r.tid}`), after: r.url, evidence: r.evidence,
  })),
}, null, 2)}\n`);

const pages = new Set(rows.map((r) => r.cited)).size;
const t = proposal.generated.tally;

const sql = `-- 1514_deeplink_candidate_connection_citations.sql
--
-- Point ${rows.length} stance citations at the section of the Ballotpedia page that carries the claim,
-- by appending #Campaign_themes. ${pages} distinct pages. NOTHING IS DELETED, NO PAGE CHANGES, NO HOST
-- CHANGES -- the only edit is an anchor on the URL the row already cited.
--   Evidence:        ${IN}
--   Rollback record: ${ROLLBACK}
--
-- WHY AN ANCHOR AND NOT A RE-POINT. The original plan for this cohort was "point each row at the
-- primary source behind Ballotpedia". For these rows there is no such thing. A Candidate Connection
-- survey answer is written by the candidate and published nowhere else, so Ballotpedia IS the primary
-- source and there is nothing upstream to point at. What was actually wrong is precision: measured
-- 2026-07-31, only 5 of 557 rows in this cohort carried an anchor of any kind, so every one of them
-- cited a whole biography to support one sentence. On Charlotte Bergmann's page the passage sits
-- 13,195px down.
--
-- 🔴 THE ANCHOR WAS NOT APPENDED BECAUSE THE REASONING SAYS "CANDIDATE CONNECTION". That is a claim
-- about how the row was written, not about the page, and an anchor that does not resolve to the quoted
-- passage is WORSE than no anchor -- it reads as a dead citation. Each row was tested against the
-- SECTION TEXT specifically, extracted from the heading to the next heading of equal rank:
--   CC_VERIFIED        ${String(t.CC_VERIFIED ?? 0).padStart(3)}  claim found INSIDE Campaign_themes           -> anchored here
--   NOT_ON_PAGE        ${String(t.NOT_ON_PAGE ?? 0).padStart(3)}  claim nowhere in the article body            -> citation audit's problem
--   ELSEWHERE_ON_PAGE  ${String(t.ELSEWHERE_ON_PAGE ?? 0).padStart(3)}  on the page but OUTSIDE the survey section   -> NOT anchored; the
--                           anchor would point the reader away from the row's own evidence. These are the
--                           rows that genuinely might be re-pointable off-site.
--   UNKNOWN            ${String(t.UNKNOWN ?? 0).padStart(3)}  404s, listed below
--   NO_CC_SECTION      ${String(t.NO_CC_SECTION ?? 0).padStart(3)}  page has no Campaign_themes section at all
-- The section is a real subset, not the whole page: mean 47% of body text, and only 2 of ${rows.length} rows sit
-- on a page where it exceeds 90%.
--
-- 🔴 THE FIRST RUN REPORTED 215 UNKNOWN AND THAT WAS THE RATE LIMITER, NOT THE DATA. 214 of them were
-- HTTP 202 with an empty body across 76 pages -- Ballotpedia's silent limit, for which r.ok is TRUE.
-- Re-running at --delay 3500 turned 275 CC_VERIFIED into ${rows.length}. Had the 202s been scored as absence,
-- 168 correctly-sourced rows would have been recorded as unsupported. Never read a tally that contains
-- UNKNOWN; re-run it first.
--
-- 🔴 THE ANCHOR ID IS #Campaign_themes AND THIS WAS CHECKED, NOT ASSUMED. There is no
-- #Candidate_Connection section id despite that being the survey's name. Two proposed URLs were also
-- opened in a real browser to confirm the anchor resolves to a "Campaign themes" heading with the
-- quoted passage beneath it.
--
-- LEFT FOR A HUMAN -- 9 rows cite an ELECTION page rather than the candidate's own page, and those
-- pages 404 or have no survey section. A race page never supported a claim about one candidate:
--   ballotpedia.org/Los_Angeles_City_Council_elections,_2026        7 rows, Andrej Selivra    404
--   ballotpedia.org/Monica_Garcia_(LAUSD_Board_District_2)          1 row,  Monica Garcia     404
--   ballotpedia.org/Mississippi's_1st_Congressional_District_...    1 row,  Johnny Baucom     no section

BEGIN;

CREATE TEMP TABLE _deeplink_1514 (
  politician_id uuid,
  topic_id      uuid,
  old_url       text,
  new_url       text
) ON COMMIT DROP;

INSERT INTO _deeplink_1514 (politician_id, topic_id, old_url, new_url) VALUES
${rows.map((r, i) => `  (${q(r.pid)}, ${q(r.tid)}, ${q(r.cited)}, ${q(r.url)})${i === rows.length - 1 ? '' : ','}`).join('\n')}
;

-- Strip any existing anchor and trailing slash before comparing, so a stored ".../Name/" or
-- ".../Name#Something" is still matched by a proposal recorded as ".../Name".
UPDATE inform.politician_context pc
   SET sources = (
     SELECT array_agg(
              CASE WHEN btrim(regexp_replace(s, '#.*$', ''), '/') = r.old_url THEN r.new_url ELSE s END
              ORDER BY ord)
       FROM unnest(pc.sources) WITH ORDINALITY AS u(s, ord))
  FROM _deeplink_1514 r
 WHERE pc.politician_id = r.politician_id
   AND pc.topic_id = r.topic_id;

DO $$
DECLARE
  v_target  int;
  v_unfixed int;
  v_lost    int;
BEGIN
  SELECT count(*) INTO v_target FROM _deeplink_1514;
  IF v_target <> ${rows.length} THEN
    RAISE EXCEPTION 'expected ${rows.length} targeted rows, found %', v_target;
  END IF;

  -- Every targeted row must now carry the anchor. If one does not, old_url did not match what was
  -- stored and the row was silently left behind on a whole-biography citation.
  SELECT count(*) INTO v_unfixed
    FROM inform.politician_context pc
    JOIN _deeplink_1514 r ON r.politician_id = pc.politician_id AND r.topic_id = pc.topic_id
   WHERE NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s = r.new_url);
  IF v_unfixed <> 0 THEN
    RAISE EXCEPTION '% targeted rows did not receive the anchor -- old_url did not match', v_unfixed;
  END IF;

  -- This migration substitutes; it never drops.
  SELECT count(*) INTO v_lost
    FROM inform.politician_context pc
    JOIN _deeplink_1514 r ON r.politician_id = pc.politician_id AND r.topic_id = pc.topic_id
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF v_lost <> 0 THEN
    RAISE EXCEPTION '% targeted rows ended with an empty sources array', v_lost;
  END IF;
END $$;

COMMIT;
`;

writeFileSync(SQL, sql);
console.log(`wrote ${SQL} (${rows.length} rows across ${pages} pages)`);
console.log(`wrote ${ROLLBACK}`);
