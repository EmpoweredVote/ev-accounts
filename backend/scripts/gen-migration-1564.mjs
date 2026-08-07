#!/usr/bin/env node
/**
 * Generate migration 1564 and its rollback record from the classification artifacts.
 *
 * WHY GENERATED, NOT HAND-WRITTEN. The migration embeds 119 fabricated URLs and ~388 (politician, topic)
 * keys. Hand-transcribing those is how a row gets retired that nobody decided to retire. Everything here
 * traces to an artifact: the URLs to the sweep, the retire/keep split to navonly-classification.json.
 *
 * WHAT IS EMBEDDED VS COMPUTED, which matters for reviewability:
 *   · the fabricated URL list is embedded — the database cannot know it.
 *   · the NAV_ONLY verdicts are embedded — they came from READING 108 pages, and no SQL can re-derive
 *     "does this page state a position attributable to this person".
 *   · the SOLE_SOURCED half IS re-derived in SQL as a cross-check, because it is purely structural
 *     (no citation survives removal). If the SQL count disagrees with the read classification the
 *     migration aborts — that is the guard against a stale artifact.
 *
 * Writes: migrations/1564_retire_fabricated_source_stances.sql
 *         data/stance-retirement/2026-08-06-migration-1564-rollback.json
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const DIR = path.join(HERE, '..', 'data', 'stance-retirement');
const ws = JSON.parse(readFileSync(path.join(DIR, 'navonly-workset.json'), 'utf8'));
const cl = JSON.parse(readFileSync(path.join(DIR, 'navonly-classification.json'), 'utf8'));

const fabricated = [...new Set(ws.rows.flatMap((r) => []))]; // placeholder, filled below
// Rebuild the fabricated set exactly as the workset did.
import { readdirSync } from 'node:fs';
const WITHDRAWN = new Set(['https://lynch.house.gov/issues/technology']);
const fabSet = new Set();
for (const f of readdirSync(DIR).filter((x) => /^fabricated-article-sweep-.*\.json$/.test(x))) {
  for (const r of JSON.parse(readFileSync(path.join(DIR, f), 'utf8')).findings ?? []) {
    if (r.verdict === 'FABRICATED' && !WITHDRAWN.has(r.url)) fabSet.add(r.url);
  }
}
const fabUrls = [...fabSet].sort();

const retire = [...cl.rows.SOLE_SOURCED, ...cl.rows.NAV_ONLY];
const keep = [...cl.rows.HAS_COSOURCE, ...cl.rows.KEPT_UNVERIFIED];

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

// Rollback record: every retired row verbatim, so each can be reinserted.
const { rows: full } = await pool.query(`
  SELECT pc.politician_id, pc.topic_id, pc.reasoning, pc.sources,
         pa.value, pa.write_in_text, p.full_name, p.last_stances_researched_at
    FROM inform.politician_context pc
    JOIN essentials.politicians p ON p.id = pc.politician_id
    LEFT JOIN inform.politician_answers pa
      ON pa.politician_id = pc.politician_id AND pa.topic_id = pc.topic_id
   WHERE pc.sources && $1::text[]`, [fabUrls]);

const key = (r) => `${r.politician_id}|${r.topic_id}`;
const retireKeys = new Set(retire.map((r) => `${r.politician || ''}`)); // names only in cl; match on pairs below
// cl rows carry politician name + topic_id, not politician_id — re-associate via the workset.
const wsByKey = new Map(ws.rows.map((r) => [`${r.name}|${r.topic_id}`, r]));
const retirePairs = retire.map((r) => {
  const w = wsByKey.get(`${r.politician}|${r.topic_id}`);
  if (!w) throw new Error(`cannot resolve politician_id for ${r.politician} / ${r.topic_id}`);
  return { politician_id: w.politician_id, topic_id: r.topic_id, name: r.politician, government: r.government };
});
const keepPairs = keep.map((r) => {
  const w = wsByKey.get(`${r.politician}|${r.topic_id}`);
  if (!w) throw new Error(`cannot resolve politician_id for ${r.politician} / ${r.topic_id}`);
  return { politician_id: w.politician_id, topic_id: r.topic_id, name: r.politician };
});

const retireSet = new Set(retirePairs.map((p) => `${p.politician_id}|${p.topic_id}`));
const rollback = full.filter((r) => retireSet.has(key(r)));
if (rollback.length !== retirePairs.length) {
  throw new Error(`rollback rows ${rollback.length} != retire pairs ${retirePairs.length}`);
}

writeFileSync(path.join(DIR, '2026-08-06-migration-1564-rollback.json'),
  `${JSON.stringify({ migration: '1564_retire_fabricated_source_stances',
                      note: 'Every retired row verbatim. Reinsert into inform.politician_context and inform.politician_answers to undo.',
                      fabricated_urls: fabUrls, retired_rows: rollback,
                      stripped_rows: keepPairs }, null, 2)}\n`);

const sqlArray = (xs) => xs.map((x) => `    ${x.replace(/'/g, "''").replace(/^/, "'")}'`).join(',\n');
const pairRows = (ps) => ps.map((p) => `    ('${p.politician_id}','${p.topic_id}')`).join(',\n');

const emptied = new Map();
for (const p of retirePairs) emptied.set(p.politician_id, (emptied.get(p.politician_id) ?? 0) + 1);

const sql = `-- 1564_retire_fabricated_source_stances.sql
--
-- Retire ${retirePairs.length} stance rows whose evidence does not exist, and strip the fabricated
-- citations from a further ${keepPairs.length} rows that keep a real source. ⚠ NOT YET OPERATOR-APPROVED.
--
--   Findings:  data/stance-retirement/2026-08-06-fabricated-sweep-COMPLETE.md
--   Rollback:  data/stance-retirement/2026-08-06-migration-1564-rollback.json — every retired row
--              verbatim (politician, topic, value, reasoning, sources) so each can be reinserted.
--   Evidence:  fabricated-article-sweep-*.json (per-URL verdicts) · navonly-classification.json
--              (per-survivor read verdicts) · 2026-08-06-control-rederivation.json
--
-- ---------------------------------------------------------------------------------------------------
-- WHAT IS BEING REMOVED
-- ---------------------------------------------------------------------------------------------------
-- ${fabUrls.length} distinct cited URLs that were never published. Each one: HTTP 404 on a LIVE host,
-- zero Wayback captures of the exact path, and >= 5 archived sibling PAGES in the same section or month.
-- The sweep covered 13,705 of 13,705 eligible cited URLs (100%).
--
-- The sibling control counts real pages, not archived URLs: crawler asset paths, section indexes and
-- inline-JS artifacts were excluded and all 59 controls re-derived. That downgraded one finding
-- (audacy.com) out of this set. lynch.house.gov/issues/technology is also excluded as UNPROVEN — its
-- whole /issues section is gone and its control is contaminated by soft-404s.
--
-- ---------------------------------------------------------------------------------------------------
-- WHY ${retirePairs.length} ROWS AND NOT ALL ${ws.affected_rows}
-- ---------------------------------------------------------------------------------------------------
--   * ${cl.split.SOLE_SOURCED} rows are SOLE-SOURCED: removing the fabricated citations leaves no citation at all.
--   * ${cl.split.NAV_ONLY} rows keep only citations that are not coverage. Every surviving page was FETCHED AND
--     READ against the 2026-08-04 ruling ("does this page state a position attributable to this
--     person"). They fail in four ways:
--       - GONE: 36 of 108 survivors are 404 or dead domains. The three largest are the Carson,
--         Alhambra and Lynn agenda/minutes indexes — 62 rows rest on pages that no longer exist.
--       - INDEX pages: agendas, minutes, archives.
--       - SEARCH-RESULT URLs cited as sources (commonwealthbeacon.org/?s=…). A query is not a source.
--       - SUBSTANTIVE BUT NOT ABOUT THIS PERSON: actonmass.org bill pages and bare
--         malegislature.gov/Bills/<id> pages carry real prose and name no citing legislator.
--   * ${cl.split.HAS_COSOURCE} rows keep a real, readable co-source that names the politician -> citation STRIPPED, row KEPT.
--   * ${cl.split.KEPT_UNVERIFIED} rows keep a survivor that could not be read (bot-walled congress.gov / ontheissues) ->
--     KEPT. A server answered, so absence is not shown. We retire on demonstrated absence only.
--
-- 🔴 A STRUCTURAL RULE WAS NOT ENOUGH. Classifying survivors by path depth put NAV_ONLY at 42 and this
-- migration at 183 rows. Reading them put it at ${cl.split.NAV_ONLY} and ${retirePairs.length}. lynnma.gov/city-council/minutes
-- (19 rows) is depth-2 and is an index; wikipedia.org/wiki/Ed_Markey is depth-2 and is substantive.
--
-- ⚠ FOUR APPARENT RE-POINTS WERE WITHDRAWN AND ARE RETIRED HERE INSTEAD. Four citations are corrupted
-- slugs of real live pages (/issues/health-care -> /issues/health, /issues/criminal-justice ->
-- /criminal-injustice, and two Moulton slugs). Re-pointing them was tested and REJECTED: the target
-- pages do not carry the rows' claims (bail 0, "Justice Guarantee" 0, Gideon 0, Medicare 0, CHIPS 0,
-- deepfake 0, disinformation 0). Re-pointing would have manufactured support — the willametteweek rule.
--
-- ---------------------------------------------------------------------------------------------------
-- BLAST RADIUS — CHIPS MUST BE FLIPPED IN essentials/src/lib/coverage.js IN THE SAME BATCH
-- ---------------------------------------------------------------------------------------------------
--   City of Carson    34 of 34 answers  -> ZERO
--   City of Lynn MA   30 of 30          -> ZERO
--   City of Alhambra  19 of 19          -> ZERO   (invisible to the structural rule: all 19 rows on one 404 index)
--   City of Waltham   5 of 5            -> ZERO
--   Commonwealth of Massachusetts 161 of 2,675 · Somerville 30 of 85 · Medford 3 of 10 · others low.
-- ${emptied.size} politicians are touched; those emptied to zero answers have last_stances_researched_at nulled
-- (rule 1494/1507/1508), computed here rather than hard-coded.
--
-- ⚠ 4 of the ${retirePairs.length} retired rows are ORPHAN CONTEXT — reasoning with no answer behind it (Bryant Acosta 3,
-- David B. Walgren 1), part of the ~546-row orphan class that is still undiagnosed corpus-wide. So
-- context falls by ${retirePairs.length} while answers fall by ${retirePairs.length - 4}. Both are asserted separately below; the
-- orphan count is computed at run time, not hard-coded.

BEGIN;

CREATE TEMP TABLE fab_urls(url text PRIMARY KEY);
INSERT INTO fab_urls(url) VALUES
${fabUrls.map((u) => `    ('${u.replace(/'/g, "''")}')`).join(',\n')};

CREATE TEMP TABLE retire_rows(politician_id uuid, topic_id uuid);
INSERT INTO retire_rows(politician_id, topic_id) VALUES
${pairRows(retirePairs)};

CREATE TEMP TABLE strip_rows(politician_id uuid, topic_id uuid);
INSERT INTO strip_rows(politician_id, topic_id) VALUES
${pairRows(keepPairs)};

DO $$
DECLARE
  v_n int; v_ans_before bigint; v_ctx_before bigint; v_nulled int; v_cohort uuid[];
  v_orphans int;
BEGIN
  SELECT count(*) INTO v_ans_before FROM inform.politician_answers;
  SELECT count(*) INTO v_ctx_before FROM inform.politician_context;

  -- ---- guards on the pre-state ----
  SELECT count(*) INTO v_n FROM fab_urls;
  IF v_n <> ${fabUrls.length} THEN RAISE EXCEPTION '1564: expected ${fabUrls.length} fabricated urls, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM retire_rows;
  IF v_n <> ${retirePairs.length} THEN RAISE EXCEPTION '1564: expected ${retirePairs.length} retire rows, found %', v_n; END IF;

  SELECT count(*) INTO v_n FROM strip_rows;
  IF v_n <> ${keepPairs.length} THEN RAISE EXCEPTION '1564: expected ${keepPairs.length} strip rows, found %', v_n; END IF;

  -- Every targeted row must still exist and still cite a fabricated url. A row that has been edited
  -- since the classification is out of scope and must stop the migration, not be retired blind.
  SELECT count(*) INTO v_n FROM retire_rows r
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context pc
                      WHERE pc.politician_id = r.politician_id AND pc.topic_id = r.topic_id
                        AND pc.sources && (SELECT array_agg(url) FROM fab_urls));
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % retire rows no longer cite a fabricated url — re-review', v_n; END IF;

  SELECT count(*) INTO v_n FROM strip_rows s
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context pc
                      WHERE pc.politician_id = s.politician_id AND pc.topic_id = s.topic_id
                        AND pc.sources && (SELECT array_agg(url) FROM fab_urls));
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % strip rows no longer cite a fabricated url — re-review', v_n; END IF;

  -- The whole affected set must be exactly retire + strip: no row citing a fabricated url may be
  -- unaccounted for. This is what catches a stale classification artifact.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM fab_urls)
     AND (pc.politician_id, pc.topic_id) NOT IN (SELECT politician_id, topic_id FROM retire_rows)
     AND (pc.politician_id, pc.topic_id) NOT IN (SELECT politician_id, topic_id FROM strip_rows);
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % affected rows are in neither list — classification is stale', v_n; END IF;

  -- 🔴 CROSS-CHECK THE STRUCTURAL HALF IN SQL. Sole-sourced is derivable without reading anything:
  -- after removing the fabricated urls no citation survives. If SQL disagrees with the read
  -- classification, the artifact is stale and nothing should be deleted.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM fab_urls)
     AND NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s NOT IN (SELECT url FROM fab_urls));
  IF v_n <> ${cl.split.SOLE_SOURCED} THEN
    RAISE EXCEPTION '1564: SQL says % sole-sourced rows, classification says ${cl.split.SOLE_SOURCED}', v_n; END IF;

  -- Every sole-sourced row must be in the retire list (never merely stripped to an empty citation set).
  SELECT count(*) INTO v_n FROM inform.politician_context pc
   WHERE pc.sources && (SELECT array_agg(url) FROM fab_urls)
     AND NOT EXISTS (SELECT 1 FROM unnest(pc.sources) s WHERE s NOT IN (SELECT url FROM fab_urls))
     AND (pc.politician_id, pc.topic_id) NOT IN (SELECT politician_id, topic_id FROM retire_rows);
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % sole-sourced rows are not being retired', v_n; END IF;

  -- 🔴 ORPHAN CONTEXT ROWS ARE IN SCOPE AND THE ANSWER COUNT WILL NOT MATCH THE ROW COUNT BECAUSE OF
  -- THEM. Some rows are voter-facing reasoning with no answer behind it (the ~546-row orphan class,
  -- still undiagnosed corpus-wide). Deleting one removes a context row but no answer, so asserting
  -- "answers fell by exactly <rows>" fails — the first dry run of this migration failed on exactly that,
  -- which is the guard doing its job. Count them here and hold both totals to their true values rather
  -- than relaxing the check.
  SELECT count(*) INTO v_orphans
    FROM retire_rows r
   WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa
                      WHERE pa.politician_id = r.politician_id AND pa.topic_id = r.topic_id);
  RAISE NOTICE '1564: % of ${retirePairs.length} retire rows are orphan context (no answer behind them)', v_orphans;

  SELECT array_agg(DISTINCT politician_id) INTO v_cohort FROM retire_rows;

  -- ---- retire ----
  DELETE FROM inform.politician_answers pa USING retire_rows r
   WHERE pa.politician_id = r.politician_id AND pa.topic_id = r.topic_id;

  DELETE FROM inform.politician_context pc USING retire_rows r
   WHERE pc.politician_id = r.politician_id AND pc.topic_id = r.topic_id;

  -- ---- strip the fabricated citations from the rows that keep a real source ----
  UPDATE inform.politician_context pc
     SET sources = ARRAY(SELECT s FROM unnest(pc.sources) s WHERE s NOT IN (SELECT url FROM fab_urls))
    FROM strip_rows sr
   WHERE pc.politician_id = sr.politician_id AND pc.topic_id = sr.topic_id;

  -- ---- null the timestamp for politicians emptied to zero answers ----
  UPDATE essentials.politicians p
     SET last_stances_researched_at = NULL
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  GET DIAGNOSTICS v_nulled = ROW_COUNT;
  RAISE NOTICE '1564: nulled last_stances_researched_at for % emptied politicians', v_nulled;

  -- ---- post-verify ----
  SELECT count(*) INTO v_n FROM inform.politician_context pc, unnest(pc.sources) s
   WHERE s IN (SELECT url FROM fab_urls);
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % fabricated citations survived', v_n; END IF;

  -- Context falls by every retired row; answers fall by every retired row THAT HAD ONE.
  IF v_ctx_before - (SELECT count(*) FROM inform.politician_context) <> ${retirePairs.length} THEN
    RAISE EXCEPTION '1564: context rows did not fall by exactly ${retirePairs.length}'; END IF;
  IF v_ans_before - (SELECT count(*) FROM inform.politician_answers) <> ${retirePairs.length} - v_orphans THEN
    RAISE EXCEPTION '1564: answers fell by %, expected % (${retirePairs.length} rows less % orphans)',
      v_ans_before - (SELECT count(*) FROM inform.politician_answers), ${retirePairs.length} - v_orphans, v_orphans; END IF;

  -- 🔴 Stripping must never leave a row with no citation at all — that would be a silently
  -- unsourced voter-facing stance, which is worse than a retired one.
  SELECT count(*) INTO v_n FROM inform.politician_context pc
    JOIN strip_rows sr ON sr.politician_id = pc.politician_id AND sr.topic_id = pc.topic_id
   WHERE coalesce(array_length(pc.sources, 1), 0) = 0;
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % stripped rows were left with zero citations', v_n; END IF;

  -- No emptied politician may retain a research timestamp.
  SELECT count(*) INTO v_n FROM essentials.politicians p
   WHERE p.id = ANY(v_cohort)
     AND p.last_stances_researched_at IS NOT NULL
     AND NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = p.id);
  IF v_n <> 0 THEN RAISE EXCEPTION '1564: % emptied politicians still carry a timestamp', v_n; END IF;

  RAISE NOTICE '1564: retired ${retirePairs.length} rows, stripped citations from ${keepPairs.length} rows, % politicians emptied',
    (SELECT count(*) FROM unnest(v_cohort) c(id)
      WHERE NOT EXISTS (SELECT 1 FROM inform.politician_answers pa WHERE pa.politician_id = c.id));
END $$;

COMMIT;
`;

writeFileSync(path.join(HERE, '..', 'migrations', '1564_retire_fabricated_source_stances.sql'), sql);
console.log(`fabricated urls: ${fabUrls.length}`);
console.log(`retire rows:     ${retirePairs.length}  (sole ${cl.split.SOLE_SOURCED} + nav ${cl.split.NAV_ONLY})`);
console.log(`strip rows:      ${keepPairs.length}  (cosource ${cl.split.HAS_COSOURCE} + unverified ${cl.split.KEPT_UNVERIFIED})`);
console.log(`politicians touched by retirement: ${emptied.size}`);
console.log(`rollback rows captured: ${rollback.length}`);
console.log('\nwrote migrations/1564_retire_fabricated_source_stances.sql');
console.log('wrote data/stance-retirement/2026-08-06-migration-1564-rollback.json');
await pool.end();
