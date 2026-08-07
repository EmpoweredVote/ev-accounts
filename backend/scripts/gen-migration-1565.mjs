#!/usr/bin/env node
/**
 * Generate migration 1565 (somervillejournal.com cluster) and its rollback record.
 *
 * Same construction as gen-migration-1564: everything traces to an artifact, the structural half is
 * re-derived in SQL as a cross-check, and nothing is hand-transcribed. See that script's header for why.
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIR = path.join(HERE, '..', 'data', 'stance-retirement');
const ws = JSON.parse(readFileSync(path.join(DIR, 'sj-workset.json'), 'utf8'));
const cl = JSON.parse(readFileSync(path.join(DIR, 'sj-classification.json'), 'utf8'));

const fabUrls = ws.fabricated_urls;
const retire = [...cl.rows.SOLE_SOURCED, ...cl.rows.NAV_ONLY];
const keep = [...cl.rows.HAS_COSOURCE, ...cl.rows.KEPT_UNVERIFIED];

const wsByKey = new Map(ws.rows.map((r) => [`${r.name}|${r.topic_id}`, r]));
const resolve = (r) => {
  const w = wsByKey.get(`${r.politician}|${r.topic_id}`);
  if (!w) throw new Error(`cannot resolve politician_id for ${r.politician} / ${r.topic_id}`);
  return { politician_id: w.politician_id, topic_id: r.topic_id, name: r.politician };
};
const retirePairs = retire.map(resolve);
const keepPairs = keep.map(resolve);

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows: full } = await pool.query(`
  SELECT pc.politician_id, pc.topic_id, pc.reasoning, pc.sources, pa.value, pa.write_in_text, p.full_name
    FROM inform.politician_context pc
    JOIN essentials.politicians p ON p.id = pc.politician_id
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pc.sources && $1::text[]`, [fabUrls]);

const retireSet = new Set(retirePairs.map((p) => `${p.politician_id}|${p.topic_id}`));
const rollback = full.filter((r) => retireSet.has(`${r.politician_id}|${r.topic_id}`));
if (rollback.length !== retirePairs.length) throw new Error(`rollback ${rollback.length} != retire ${retirePairs.length}`);

writeFileSync(path.join(DIR, '2026-08-06-migration-1565-rollback.json'),
  `${JSON.stringify({ migration: '1565_retire_somervillejournal_fabricated_citations',
                      note: 'Every retired row verbatim. Reinsert into inform.politician_context and inform.politician_answers to undo.',
                      fabricated_urls: fabUrls, retired_rows: rollback, stripped_rows: keepPairs }, null, 2)}\n`);

const pairRows = (ps) => ps.map((p) => `    ('${p.politician_id}','${p.topic_id}')`).join(',\n');
const cohort = new Set(retirePairs.map((p) => p.politician_id));

const sql = `-- 1565_retire_somervillejournal_fabricated_citations.sql
--
-- Retire ${retirePairs.length} Somerville stance rows citing somervillejournal.com. ⚠ NOT YET OPERATOR-APPROVED.
--
--   Rollback: data/stance-retirement/2026-08-06-migration-1565-rollback.json — all ${retirePairs.length} rows verbatim.
--   Evidence: sj-workset.json · sj-pages.json · sj-classification.json
--   Follows:  1564 (the main fabricated-source retirement)
--
-- ---------------------------------------------------------------------------------------------------
-- 🔴 THIS OVERTURNS THIS WORKSTREAM'S OWN STANDING ADVICE
-- ---------------------------------------------------------------------------------------------------
-- Every prior note said somervillejournal.com is "a genuine paper whose domain died — RE-POINT to
-- Wayback captures, do NOT retire", and it was excluded from 1564 on that basis. Asked to perform that
-- re-point, there is nothing to point to. Four independent checks:
--
--   ✅ POSITIVE CONTROL PASSES — the host is richly archived: 3,000 captures spanning 2001 -> 2025.
--   🔴 ZERO captures of the cited paths (sampled), and ZERO archived urls under /2020*, /2022*, /2024*.
--      The date-slug scheme NEVER existed on this domain.
--   🔴 The real article scheme was NUMERIC: somervillejournal.com/20418049.htm.
--   🔴 From 2021 the domain was a PDF SPAM FARM — 1,801 of 2,000 captures are
--      cgi-bin/content/view.php?data=...&filetype=pdf (car manuals, textbooks). Yet the citations are
--      dated 2019-2025, including years when the domain served nothing but spam.
--
-- The genuine Somerville Journal was a Wicked Local paper; real coverage lives at
-- wickedlocal.com/somerville*. Matching a row's claim to one of those articles is per-row research, not
-- a mechanical re-point — the 1564 lesson that a re-point is valid ONLY if the TARGET carries the CLAIM.
--
-- 🔑 HOW THE WRONG CALL WAS MADE, and it generalises: "the publication is real" was verified at BRAND
-- level and never at DOMAIN-ERA or PATH-SCHEME level. A masthead can be real while the domain has
-- changed hands, and a host can be richly archived while the cited URL FORM never existed on it.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY ALL ${retirePairs.length} ROWS, WHEN ONLY ${cl.split.SOLE_SOURCED} ARE SOLE-SOURCED
-- ---------------------------------------------------------------------------------------------------
-- All 18 surviving citations were fetched and read. NOT ONE is coverage:
--   * 10 x somervillema.gov/city-council/members/<name> -> HTTP 404. 🔴 And the scheme is itself
--     invented: the real councillor pages are somervillema.gov/content/councilor-<name> and
--     /departments/city-council/councilor-<name>. That is 10 more fabricated paths on a host which
--     already carried 5 confirmed fabrications (retired by 1564).
--     ⚠ Re-pointing to the REAL councillor pages was tested and rejected: they are 451-word contact
--     pages — zoning 0, housing 0, climate 0, rent 0. A bio page states no position.
--   * somervillema.gov/somervision (10 rows) and /departments/programs/climate-forward (9 rows) are
--     real CITY PROGRAM pages that name no individual — the attribute-prior class.
--   * 6 x malegislature.gov/Bills/192/H#### are STATE bills cited for CITY COUNCILLORS, who cannot
--     sponsor them, and none names the citing official.
-- So every row is either sole-sourced (${cl.split.SOLE_SOURCED}) or nav-only (${cl.split.NAV_ONLY}); none keeps a real co-source.
--
-- ---------------------------------------------------------------------------------------------------
-- BLAST RADIUS — NO CHIP FLIPS REQUIRED
-- ---------------------------------------------------------------------------------------------------
--   City of Somerville            44 of 52 answers -> 8 remain, chip stays true
--   Somerville Public Schools     11 of 18 answers -> 7 remain, chip stays true
--
-- ⚠ Those two do not sum to ${retirePairs.length}: several of these officials hold BOTH a council seat and a school
-- committee seat, so a row counts under both governments. And the per-row "government" label in
-- sj-classification.json is NOT reliable for this — it comes from a LEFT JOIN LATERAL ... LIMIT 1 that
-- picks an arbitrary office. It first suggested Somerville would keep 13; measuring properly against all
-- offices gives 8. 🔑 For a chip decision, count answers per government directly, never from a
-- one-office-per-politician label.
--   ${cohort.size} politicians touched; 10 drop to zero answers (Mbah, Ewen-Campen, Link, Strezo, Wheeler,
--   McLaughlin, Scott, Sait, Davis, Hardt). last_stances_researched_at nulled for those emptied,
--   computed at run time rather than hard-coded.

BEGIN;

CREATE TEMP TABLE sj_urls(url text PRIMARY KEY);
INSERT INTO sj_urls(url) VALUES
${fabUrls.map((u) => `    ('${u.replace(/'/g, "''")}')`).join(',\n')};

CREATE TEMP TABLE sj_retire(politician_id uuid, topic_id uuid);
INSERT INTO sj_retire(politician_id, topic_id) VALUES
${pairRows(retirePairs)};

DO $$
DECLARE
  v_n int; v_ans_before bigint; v_ctx_before bigint; v_nulled int; v_cohort uuid[]; v_orphans int;
BEGIN
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;

  SELECT count(*) INTO v_n FROM sj_urls;
  IF v_n <> ${fabUrls.length} THEN RAISE EXCEPTION '1565: expected ${fabUrls.length} urls, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM sj_retire;
  IF v_n <> ${retirePairs.length} THEN RAISE EXCEPTION '1565: expected ${retirePairs.length} retire rows, found %', v_n; END IF;

  -- Every row citing one of these urls must be in the retire list. This cluster has NO survivors worth
  -- keeping, so anything unaccounted for means the classification is stale and nothing should be deleted.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM sj_urls)
     AND (pc.politician_id, pc.topic_id) NOT IN (SELECT politician_id, topic_id FROM sj_retire);
  IF v_n <> 0 THEN RAISE EXCEPTION '1565: % affected rows are not in the retire list — classification is stale', v_n; END IF;

  -- Each targeted row must still exist and still cite one of these urls.
  SELECT count(*) INTO v_n FROM sj_retire r
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context pc
                      WHERE pc.politician_id = r.politician_id AND pc.topic_id = r.topic_id
                        AND pc.sources && (SELECT array_agg(url) FROM sj_urls));
  IF v_n <> 0 THEN RAISE EXCEPTION '1565: % retire rows no longer cite a somervillejournal url', v_n; END IF;

  -- Cross-check the structural half in SQL, as 1564 did.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM sj_urls)
     AND NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s NOT IN (SELECT url FROM sj_urls));
  IF v_n <> ${cl.split.SOLE_SOURCED} THEN
    RAISE EXCEPTION '1565: SQL says % sole-sourced, classification says ${cl.split.SOLE_SOURCED}', v_n; END IF;

  SELECT count(*) INTO v_orphans FROM sj_retire r
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = r.politician_id AND pa.topic_id = r.topic_id);
  RAISE NOTICE '1565: % of ${retirePairs.length} retire rows are orphan context', v_orphans;

  SELECT array_agg(DISTINCT politician_id) INTO v_cohort FROM sj_retire;

  DELETE FROM inform.politician_answers pa USING sj_retire r
   WHERE pa.politician_id = r.politician_id AND pa.topic_id = r.topic_id;
  DELETE FROM inform.politician_context pc USING sj_retire r
   WHERE pc.politician_id = r.politician_id AND pc.topic_id = r.topic_id;

  UPDATE essentials.politicians p
     SET last_stances_researched_at = NULL
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  GET DIAGNOSTICS v_nulled = ROW_COUNT;
  RAISE NOTICE '1565: nulled last_stances_researched_at for % emptied politicians', v_nulled;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s IN (SELECT url FROM sj_urls);
  IF v_n <> 0 THEN RAISE EXCEPTION '1565: % somervillejournal citations survived', v_n; END IF;

  IF v_ctx_before - (SELECT count(*) FROM inform.politician_context) <> ${retirePairs.length} THEN
    RAISE EXCEPTION '1565: context rows did not fall by exactly ${retirePairs.length}'; END IF;
  IF v_ans_before - (SELECT count(*) FROM inform.politician_answers) <> ${retirePairs.length} - v_orphans THEN
    RAISE EXCEPTION '1565: answers fell by the wrong amount'; END IF;

  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1565: % emptied politicians still carry a timestamp', v_n; END IF;

  RAISE NOTICE '1565: retired ${retirePairs.length} rows, % politicians emptied',
    (SELECT count(*) FROM unnest(v_cohort) c(id)
      WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = c.id));
END $$;

COMMIT;
`;

writeFileSync(path.join(HERE, '..', 'migrations', '1565_retire_somervillejournal_fabricated_citations.sql'), sql);
console.log(`urls: ${fabUrls.length} · retire: ${retirePairs.length} (sole ${cl.split.SOLE_SOURCED} + nav ${cl.split.NAV_ONLY}) · strip: ${keepPairs.length}`);
console.log(`politicians touched: ${cohort.size} · rollback rows: ${rollback.length}`);
console.log('\nwrote migrations/1565_retire_somervillejournal_fabricated_citations.sql');
await pool.end();
