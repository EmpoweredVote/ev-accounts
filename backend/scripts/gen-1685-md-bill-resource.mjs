#!/usr/bin/env node
/**
 * Generate migration 1685 -- re-source Maryland stances to the specific bills they already name.
 *
 * Only SPONSOR_CONFIRMED rows: the legislator's OWN mgaleg slug appears in that bill's
 * "Sponsored by" list. Stance VALUES are never touched; this only adds citations.
 *
 * ⚠ Terminator discipline: a previous generator on this workstream put `;` after a trailing `--`
 * comment and silently produced an unterminated statement. Terminators go on their own line.
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!IN || !SQL_OUT || !ROLLBACK) { console.error('need --in --sql --rollback'); process.exit(2); }

const data = JSON.parse(fs.readFileSync(IN, 'utf8'));
const rows = data.rows.filter((r) => r.verdict === 'SPONSOR_CONFIRMED');

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// ---- rollback FIRST, straight from the DB (never from the worklist's copy) ----
const keys = rows.map((r) => [r.politician_id, r.topic_id]);
const { rows: live } = await pool.query(
  `SELECT c.politician_id, c.topic_id, p.full_name, t.title AS topic, c.sources, c.reasoning
   FROM inform.politician_context c
   JOIN essentials.politicians p ON p.id = c.politician_id
   LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE (c.politician_id, c.topic_id) IN (${keys.map((_, i) => `($${i * 2 + 1}::uuid,$${i * 2 + 2}::uuid)`).join(',')})`,
  keys.flat());

if (live.length !== rows.length) {
  console.error(`ABORT: expected ${rows.length} live rows, found ${live.length}. Refusing to generate.`);
  await pool.end(); process.exit(1);
}
const liveByKey = new Map(live.map((r) => [`${r.politician_id}|${r.topic_id}`, r]));

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: '1685_resource_md_stances_to_named_bills',
  generated: 'pre-change snapshot taken from the live DB',
  rule: 'Each row named a Maryland Act/bill in its voter-facing reasoning; the legislator\'s own mgaleg slug was found in that bill\'s "Sponsored by" list on mgaleg. The specific bill page is prepended to sources. Stance values untouched.',
  row_count: live.length,
  rows: live,
}, null, 2));

// ---- build new source arrays ----
const esc = (s) => s.replace(/'/g, "''");
const stmts = [];
let added = 0;
for (const r of rows) {
  const k = `${r.politician_id}|${r.topic_id}`;
  const cur = liveByKey.get(k).sources || [];
  const bills = r.evidence.filter((e) => e.matched_slug)
    .sort((a, b) => a.session.localeCompare(b.session))
    .map((e) => `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${e.slug}?ys=${e.session}`);
  const uniqBills = [...new Set(bills)].slice(0, 4);
  const next = [...uniqBills, ...cur.filter((s) => !uniqBills.includes(s))];
  if (next.length === cur.length && next.every((v, i) => v === cur[i])) continue;
  added += uniqBills.length;
  stmts.push(
    `UPDATE inform.politician_context SET sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[]\n` +
    `WHERE politician_id = '${r.politician_id}'::uuid AND topic_id = '${r.topic_id}'::uuid\n` +
    `;  -- ${esc(r.politician)} / ${esc(r.topic)}`
  );
}

const sql = `-- 1685_resource_md_stances_to_named_bills.sql
-- Maryland single-source queue, pass 4: re-source stances to the bills they already name.
--
-- WHY: every row below cited only a generic mgaleg MEMBER page, which carries ONE session and so
-- cannot support a per-topic position. Each row's reasoning names a specific Maryland Act; that Act
-- was resolved against a local corpus of 73,232 bills (2013RS-2026RS) built from the MGA session
-- indexes, and the legislator's OWN mgaleg slug was then found in that bill's "Sponsored by" list.
--
-- SCOPE: ${stmts.length} rows across ${new Set(rows.map((r) => r.politician)).size} legislators. Citations only -- NO stance value is modified.
-- NOT INCLUDED: 32 surname-only matches (Maryland has same-surname legislators; needs a human),
-- 157 rows with no sponsor link (may still be true via a floor vote -- UNVERIFIED, never false),
-- 569 rows naming no instrument at all.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-bill-resource-rollback.json
--
BEGIN
;

${stmts.join('\n\n')}

-- Guard: every touched row must now carry at least one Legislation/Details citation.
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing
  FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ${rows.map((r) => `('${r.politician_id}'::uuid,'${r.topic_id}'::uuid)`).join(',\n    ')}
  )
  AND NOT EXISTS (
    SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%'
  );
  IF missing > 0 THEN
    RAISE EXCEPTION 'guard failed: % row(s) lack a bill citation', missing;
  END IF;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`rows updated : ${stmts.length}`);
console.log(`bill cites   : ${added}`);
console.log(`legislators  : ${new Set(rows.map((r) => r.politician)).size}`);
console.log(`rollback     : ${ROLLBACK}`);
await pool.end();
