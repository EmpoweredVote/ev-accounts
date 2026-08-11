#!/usr/bin/env node
/**
 * Generate migration 1687 -- the 19 pass-4c ACCEPT rows.
 *
 * Each row named a real MD bill; the row's cited member slug did NOT appear among that bill's sponsors,
 * but a same-surname slug did, and fetching THAT slug's member page proved it is the same person.
 * So the row is correct and its cited slug was wrong (dead, or -- worse -- another politician's page).
 *
 * Two repairs per row, together, because leaving a known-wrong-person URL in place while rewriting the
 * array would be indefensible:
 *   1. prepend the verified bill citation(s)
 *   2. replace the bad mgaleg MEMBER slug with the verified correct one
 *
 * Every correct slug below was confirmed by reading the member page title.
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!IN || !SQL_OUT || !ROLLBACK) { console.error('need --in --sql --rollback'); process.exit(2); }

// politician -> verified correct mgaleg member slug (page title read for each)
const CORRECT_SLUG = {
  'Adrienne A. Jones': 'jones',        // jones01 is Dana Jones -- WRONG PERSON
  'Nancy J. King': 'king',            // king01 is James M. King -- WRONG PERSON
  'Dana Stein': 'stein',              // stein01 dead
  'Terri L. Hill': 'hill02',          // hill04 dead
  'Antonio Hayes': 'hayes02',         // hayes01 dead
  'Cory V. McCray': 'mccray02',       // mccray01 dead
  'Heather Bagnall': 'bagnall01',     // bagnall dead
  'Mary Beth Carozza': 'carozza02',   // carozza01 dead
  'Mary Washington': 'washington01',  // already correct; the sponsoring slug was her historical one
};

const adj = JSON.parse(fs.readFileSync(IN, 'utf8'));
const rows = adj.rows.filter((r) => r.verdict === 'ACCEPT_SLUG_WAS_WRONG');

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const keys = rows.map((r) => [r.politician_id, r.topic_id]);
const { rows: live } = await pool.query(
  `SELECT c.politician_id, c.topic_id, p.full_name, t.title AS topic, c.sources, c.reasoning
   FROM inform.politician_context c
   JOIN essentials.politicians p ON p.id = c.politician_id
   LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE (c.politician_id, c.topic_id) IN (${keys.map((_, i) => `($${i * 2 + 1}::uuid,$${i * 2 + 2}::uuid)`).join(',')})`,
  keys.flat());
if (live.length !== rows.length) { console.error(`ABORT expected ${rows.length} got ${live.length}`); await pool.end(); process.exit(1); }
await pool.end();

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: '1687_md_surname_adjudicated_accepts',
  generated: 'pre-change snapshot from live DB',
  rule: 'pass 4c ACCEPT rows: verified bill citation prepended, and the bad mgaleg member slug replaced with the slug whose member page proves the same person.',
  row_count: live.length, rows: live,
}, null, 2));

const liveByKey = new Map(live.map((r) => [`${r.politician_id}|${r.topic_id}`, r]));
const esc = (s) => s.replace(/'/g, "''");
const MEMBER_RE = /mgaleg\.maryland\.gov\/mgawebsite\/Members\/Details\//i;

const stmts = [];
for (const r of rows) {
  const cur = liveByKey.get(`${r.politician_id}|${r.topic_id}`).sources || [];
  const slug = CORRECT_SLUG[r.politician];
  if (!slug) { console.error(`no verified slug for ${r.politician}`); process.exit(1); }
  const memberUrl = `https://mgaleg.maryland.gov/mgawebsite/Members/Details/${slug}`;
  const bills = [...new Set(r.proposed_sources)].slice(0, 4);
  const keptOthers = cur.filter((s) => !MEMBER_RE.test(s) && !bills.includes(s));
  const next = [...bills, memberUrl, ...keptOthers];
  stmts.push(
    `UPDATE inform.politician_context SET sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[]\n` +
    `WHERE politician_id = '${r.politician_id}'::uuid AND topic_id = '${r.topic_id}'::uuid\n` +
    `;  -- ${esc(r.politician)} / ${esc(r.topic)}  (slug ${esc(r.cited_slug)} -> ${esc(slug)})`
  );
}

const sql = `-- 1687_md_surname_adjudicated_accepts.sql
--
-- The 32 SURNAME_ONLY rows held back from 1685, now adjudicated one at a time.
-- A bill sponsor sharing a surname is NOT the same person until proved. Each candidate slug was
-- resolved by reading its member page title; slugs change when a member switches chamber, so dead
-- slugs were retried WITH THE BILL'S SESSION (\`washington?ys=2019RS\` = "Delegate Mary L. Washington").
--
--   19 ACCEPT  (this migration) -- sponsoring slug proved to be the same person
--   11 REJECT  -- a genuinely DIFFERENT legislator: Guy Guzzone (3), Frank S. Turner (2),
--                Pat Young (1), Mary/Mary L. Washington (5 filed under Alonzo T. Washington)
--    2 HOLD    -- slug \`washington\` on 2022RS HB0937 resolves in no session: UNKNOWN, not negative
--
-- Auto-accepting surname matches would have credited four other legislators' sponsorships to the
-- wrong people. That is why they were held out of 1685.
--
-- 🔴 SECOND DEFECT FOUND HERE, WIDER THAN THIS QUEUE: a cited member slug can belong to ANOTHER REAL
-- POLITICIAN. \`jones01\` is **Dana Jones** yet is cited by all 17 of Adrienne A. Jones's stances;
-- \`king01\` is **James M. King**, cited by Nancy J. King. Corpus-wide: of 176 politicians citing an
-- mgaleg member page, 143 OK, 22 cite a DEAD slug, 10 cite a DIFFERENT PERSON. Invisible to every
-- earlier check because the page resolves, is a real member page, and carries the right surname.
-- This migration fixes the slug only on the 19 rows it already touches; the rest is a separate repair.
--
-- No stance VALUE is modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-surname-accepts-1687-rollback.json
--
BEGIN
;

${stmts.join('\n\n')}

DO $$
DECLARE bad int;
BEGIN
  -- Every touched row must carry a bill citation.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ${rows.map((r) => `('${r.politician_id}'::uuid,'${r.topic_id}'::uuid)`).join(',\n    ')}
  ) AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % touched row(s) lack a bill citation', bad; END IF;

  -- No touched row may still cite a slug proved to be the wrong person or dead.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ${rows.map((r) => `('${r.politician_id}'::uuid,'${r.topic_id}'::uuid)`).join(',\n    ')}
  ) AND EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE
        s LIKE '%Members/Details/jones01%' OR s LIKE '%Members/Details/king01%'
     OR s LIKE '%Members/Details/stein01%' OR s LIKE '%Members/Details/hill04%'
     OR s LIKE '%Members/Details/hayes01%' OR s LIKE '%Members/Details/mccray01%'
     OR s LIKE '%Members/Details/bagnall?%' OR s LIKE '%Members/Details/bagnall'
     OR s LIKE '%Members/Details/carozza01%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still cite a bad member slug', bad; END IF;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`rows          : ${stmts.length}`);
console.log(`politicians   : ${new Set(rows.map((r) => r.politician)).size}`);
console.log(`rollback      : ${ROLLBACK}`);
