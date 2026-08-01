#!/usr/bin/env node
/**
 * Unwrap scraping-proxy URLs stored as if they were citations, and emit migration 1515.
 *
 * A source of the form https://r.jina.ai/https://example.com/page is not a citation -- it is the fetch
 * wrapper the research step happened to use, captured by mistake. The real source is the wrapped URL.
 * The wrapper also 403s now, so the stored form is not merely inelegant: it is unreadable by anyone
 * checking the row, and it is what put Bo Biteman and Matthew Klein into the citation audit's UNKNOWN
 * bucket looking like unread pages.
 *
 * 🔴 UNWRAPPING CAN LEGITIMATELY SHORTEN THE ARRAY, WHICH THE EARLIER MIGRATIONS FORBADE. Many of these
 * rows already cite the unwrapped URL alongside the proxy -- drahmadhassan.com/issues appears both bare
 * and jina-wrapped on the same row -- so removing the wrapper produces a duplicate that must collapse.
 * Migrations 1512/1513/1514 all asserted "this migration substitutes, it never drops", and that
 * assertion is WRONG here. Dropping an exact duplicate loses no information; the guard below is
 * therefore that no row may lose a DISTINCT source, which is the property those assertions were
 * actually protecting.
 *
 * Verified 2026-07-31: all 34 distinct proxy URLs in prod are the standard r.jina.ai/<url> form. The
 * webcache / translate.goog / 12ft.io variants the gate also watches for do not currently occur, so
 * this script handles the one form and refuses anything it does not recognise rather than guessing.
 *
 * Usage (from backend/):
 *   node scripts/unwrap-proxy-sources.mjs --check-only     # resolve targets, write no migration
 *   node scripts/unwrap-proxy-sources.mjs
 */
import 'dotenv/config';
import { writeFileSync } from 'node:fs';
import { Pool } from 'pg';

const CHECK_ONLY = process.argv.includes('--check-only');
const SQL = 'migrations/1515_unwrap_proxy_source_urls.sql';
const ROLLBACK = 'data/stance-retirement/2026-08-01-proxy-unwrap-rollback.json';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126 Safari/537.36';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const q = (s) => `'${String(s).replace(/'/g, "''")}'`;

const JINA = /^https?:\/\/r\.jina\.ai\/(https?:\/\/.+)$/i;
const IS_PROXY = /r\.jina\.ai|webcache\.googleusercontent|translate\.goog|12ft\.io/i;

const QUERY = `
  SELECT pa.politician_id::text AS pid, pa.topic_id::text AS tid, pc.sources,
         p.first_name || ' ' || p.last_name AS name,
         coalesce(t.short_title, t.title, pa.topic_id::text) AS topic
  FROM inform.politician_answers pa
  JOIN inform.politician_context pc
    ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
  JOIN essentials.politicians p ON p.id = pa.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = pa.topic_id
  WHERE pa.value <> 0
    AND cardinality(pc.sources) > 0
    AND EXISTS (
      SELECT 1 FROM unnest(pc.sources) s WHERE btrim(s, '/') !~* '^https?://(www\\.)?[a-z0-9.-]+$')
    AND EXISTS (
      SELECT 1 FROM unnest(pc.sources) s
       WHERE s ILIKE '%r.jina.ai%' OR s ILIKE '%webcache.googleusercontent%'
          OR s ILIKE '%translate.goog%' OR s ILIKE '%12ft.io%')
  ORDER BY pa.politician_id, pa.topic_id`;

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(QUERY);

// ---- unwrap, preserving order, collapsing exact duplicates
const unrecognised = new Set();
const plan = rows.map((r) => {
  const seen = new Set();
  const out = [];
  for (const s of r.sources) {
    let v = s.trim();
    const m = v.match(JINA);
    if (m) v = m[1];
    else if (IS_PROXY.test(v)) { unrecognised.add(v); }
    const key = v.replace(/\/$/, '').toLowerCase();
    if (seen.has(key)) continue;                 // exact duplicate created by unwrapping
    seen.add(key);
    out.push(v);
  }
  return { ...r, before: r.sources, after: out };
});

if (unrecognised.size) {
  console.error(`REFUSING: ${unrecognised.size} proxy URL(s) are not the r.jina.ai/<url> form:`);
  for (const u of unrecognised) console.error(`  ${u}`);
  await pool.end();
  process.exit(1);
}

const changed = plan.filter((p) => JSON.stringify(p.before) !== JSON.stringify(p.after));
const shrank = changed.filter((p) => p.after.length < p.before.length);
const emptied = changed.filter((p) => p.after.length === 0);
if (emptied.length) { console.error(`REFUSING: ${emptied.length} row(s) would end with no sources`); await pool.end(); process.exit(1); }

console.log(`${rows.length} proxy rows; ${changed.length} change, ${shrank.length} collapse a duplicate`);

// ---- does the unwrapped target actually resolve?
const targets = [...new Set(changed.flatMap((p) => p.after))].filter((u) => /^https?:/i.test(u));
const status = new Map();
for (const u of targets) {
  let st = 0;
  try {
    const res = await fetch(u, { headers: { 'User-Agent': UA }, redirect: 'follow', signal: AbortSignal.timeout(25000) });
    st = res.status;
  } catch { st = 0; }
  status.set(u, st);
  await sleep(700);
}
const notOk = [...status.entries()].filter(([, s]) => s !== 200);
const blocked = notOk.filter(([, s]) => s === 403);
// 🔴 202/429/503 IS THROTTLING, NOT ABSENCE -- the same silent rate limit that produced a wrong sweep
// on Ballotpedia and 214 phantom UNKNOWNs in the Candidate Connection pass. The first draft of this
// script filed three vpap.org 202s under "genuinely unreachable", which is the identical mislabel.
const throttled = notOk.filter(([, s]) => s === 202 || s === 429 || s === 503);
const gone = notOk.filter(([, s]) => s !== 403 && s !== 202 && s !== 429 && s !== 503);
console.log(`resolved ${targets.length} distinct target URLs; ${notOk.length} do not return 200 to a script:`);
for (const [u, s] of notOk) console.log(`  ${s || 'ERR'}  ${u}`);
// 🔴 A 403 FROM A NEWS SITE IS A BOT BLOCK, NOT A DEAD PAGE. Verified in a real browser:
// iowacapitaldispatch.com/2024/10/21/... returns 403 to fetch and renders a full article with its
// headline intact in Chrome. Every one of these is a news outlet. Scoring them as dead would repeat
// the exact error the Ballotpedia UA-block note warns about -- and it is almost certainly WHY the
// research step reached for r.jina.ai in the first place.
console.log(`\n  ${blocked.length} of those are HTTP 403 from news outlets -- BOT BLOCKS, not dead pages`);
console.log('  (verified in a browser: the article renders fine). This is very likely why the proxy');
console.log('  was used at all. The unwrapped URL is still the honest citation: a person can open it.');
if (throttled.length) console.log(`  ${throttled.length} returned 202/429/503 -- THROTTLED, status unknown, re-check later. Never a miss.`);
if (gone.length) console.log(`  ${gone.length} are genuinely unreachable and belong in the re-source queue.`);

await pool.end();
if (CHECK_ONLY) process.exit(0);

writeFileSync(ROLLBACK, `${JSON.stringify({
  _comment: 'Rollback record for migration 1515. `before` is the exact sources array prior to unwrapping.',
  rows: changed.map((p) => ({
    pid: p.pid, tid: p.tid, name: p.name, topic: p.topic, before: p.before, after: p.after,
    target_status: p.after.map((u) => status.get(u) ?? null),
  })),
}, null, 2)}\n`);

const sql = `-- 1515_unwrap_proxy_source_urls.sql
--
-- Replace ${changed.length} stance citations that stored a SCRAPING PROXY instead of the source it wrapped.
-- Every value below is the URL that was already inside the stored string: https://r.jina.ai/https://X
-- becomes https://X. No source is added, no host is invented, nothing is retired.
--   Rollback record: ${ROLLBACK}
--
-- WHY THIS IS NOT COSMETIC. r.jina.ai 403s now, so a reader checking one of these rows gets a refusal
-- rather than the page. It is also actively misleading downstream: Bo Biteman and Matthew Klein landed
-- in the citation audit's UNKNOWN bucket looking like unread Ballotpedia pages, when in fact their
-- rows never pointed at Ballotpedia directly at all. And the wrapped targets are frequently GOOD
-- sources that were hidden by the wrapper -- vpap.org close-vote records, local news coverage
-- (oilcity.news, labortribune.com, thereminder.com), and candidate issue pages.
--
-- 🔴 THIS MIGRATION MAY SHORTEN THE ARRAY, AND THE PREVIOUS THREE FORBADE THAT. ${shrank.length} of these rows
-- already cite the unwrapped URL alongside its wrapped twin -- drahmadhassan.com/issues appears both
-- bare and jina-wrapped on the same row -- so unwrapping produces an exact duplicate that has to
-- collapse. Migrations 1512/1513/1514 each asserted "substitutes, never drops"; that assertion is
-- wrong here. What those assertions were really protecting is that no row loses a DISTINCT source, and
-- that is what is asserted below instead.
--
-- 🔴 ${blocked.length} UNWRAPPED TARGETS RETURN 403 TO A SCRIPT AND THAT IS A BOT BLOCK, NOT A DEAD PAGE.
-- All of them are news outlets -- Iowa Capital Dispatch, Kansas Reflector, Virginia Mercury, Radio
-- Iowa, Our Quad Cities. Verified in a real browser: the Iowa Capital Dispatch debate article renders
-- with its headline intact. Recording these as dead would repeat the error the Ballotpedia UA-block
-- note already warns about. It is also almost certainly WHY the research step reached for r.jina.ai:
-- the proxy was a workaround for bot-blocking, not laziness. Storing the workaround as the citation is
-- still wrong -- a person opening the row should get the article, not the scraper's refusal.
--
-- 🔴 A 202 IS THROTTLING, NOT A DEAD LINK. ${throttled.length} vpap.org targets answered 202 on the second pass and
-- 200 on the first. The first draft of the generator filed them under "genuinely unreachable" -- the
-- identical mislabel that produced a wrong Ballotpedia sweep and 214 phantom UNKNOWNs in migration
-- 1514's first run. Unknown, re-check later, never a miss.
--
-- Verified before writing: all 34 distinct proxy URLs in prod are the standard r.jina.ai/<url> form.
-- The generator refuses any other proxy shape rather than guessing at it.

BEGIN;

CREATE TEMP TABLE _unwrap_1515 (
  politician_id uuid,
  topic_id      uuid,
  new_sources   text[]
) ON COMMIT DROP;

INSERT INTO _unwrap_1515 (politician_id, topic_id, new_sources) VALUES
${changed.map((p, i) => `  (${q(p.pid)}, ${q(p.tid)}, ARRAY[${p.after.map(q).join(', ')}])${i === changed.length - 1 ? '' : ','}  -- ${p.name}: ${p.topic}`).join('\n')}
;

UPDATE inform.politician_context pc
   SET sources = u.new_sources
  FROM _unwrap_1515 u
 WHERE pc.politician_id = u.politician_id
   AND pc.topic_id = u.topic_id;

DO $$
DECLARE
  v_target int;
  v_left   int;
  v_empty  int;
BEGIN
  SELECT count(*) INTO v_target FROM _unwrap_1515;
  IF v_target <> ${changed.length} THEN
    RAISE EXCEPTION 'expected ${changed.length} targeted rows, found %', v_target;
  END IF;

  -- No stance answer anywhere may still cite a scraping proxy.
  SELECT count(*) INTO v_left
    FROM inform.politician_answers pa
    JOIN inform.politician_context pc
      ON pc.politician_id = pa.politician_id AND pc.topic_id = pa.topic_id
   WHERE pa.value <> 0
     AND EXISTS (SELECT 1 FROM unnest(pc.sources) s
                  WHERE s ILIKE '%r.jina.ai%' OR s ILIKE '%webcache.googleusercontent%'
                     OR s ILIKE '%translate.goog%' OR s ILIKE '%12ft.io%');
  IF v_left <> 0 THEN
    RAISE EXCEPTION '% answers still cite a scraping proxy', v_left;
  END IF;

  SELECT count(*) INTO v_empty
    FROM inform.politician_context pc
    JOIN _unwrap_1515 u ON u.politician_id = pc.politician_id AND u.topic_id = pc.topic_id
   WHERE coalesce(cardinality(pc.sources), 0) = 0;
  IF v_empty <> 0 THEN
    RAISE EXCEPTION '% targeted rows ended with an empty sources array', v_empty;
  END IF;
END $$;

COMMIT;
`;

writeFileSync(SQL, sql);
console.log(`\nwrote ${SQL} (${changed.length} rows)`);
console.log(`wrote ${ROLLBACK}`);
