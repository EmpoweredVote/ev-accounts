#!/usr/bin/env node
/**
 * Generate the migration repairing the 5 politicians the URL-exact re-audit found still citing a DEAD
 * mgaleg member page. Same remedy as mig 1689; these were hidden from it by the old audit's cache bug.
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), NUM = flag('--num'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!IN || !NUM || !SQL_OUT || !ROLLBACK) { console.error('need --in --num --sql --rollback'); process.exit(2); }

const plan = JSON.parse(fs.readFileSync(IN, 'utf8')).rows.filter((r) => r.final === 'REPLACE');

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows: live } = await pool.query(`
  SELECT c.politician_id, c.topic_id, p.full_name, t.title AS topic, c.sources
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  WHERE p.full_name = ANY($1::text[])
  ORDER BY p.full_name, t.title`, [plan.map((p) => p.who)]);
await pool.end();

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: `${NUM}_repair_md_remaining_dead_member_slugs`,
  generated: 'pre-change snapshot from live DB',
  rule: 'Replace dead mgaleg member-page citations with a URL confirmed, in its stored form, to name the right politician. Found by re-running the member-slug audit with a URL-exact cache after the original run\'s cache bug was fixed.',
  plan, row_count: live.length, rows: live,
}, null, 2));

const byName = new Map(plan.map((p) => [p.who, p]));
const esc = (s) => s.replace(/'/g, "''");
const stmts = [];
let unchanged = 0;
for (const r of live) {
  const p = byName.get(r.full_name);
  const cur = r.sources || [];
  const isBad = (s) => {
    const needle = `members/details/${p.dead.toLowerCase()}`;
    const i = s.toLowerCase().indexOf(needle);
    if (i === -1) return false;
    const after = s.charAt(i + needle.length);
    return after === '' || after === '?' || after === '#';
  };
  const next = [];
  let changed = false;
  for (const s of cur) {
    if (isBad(s)) { changed = true; if (!next.includes(p.replacement.url)) next.push(p.replacement.url); }
    else if (!next.includes(s)) next.push(s);
  }
  if (!changed) { unchanged++; continue; }
  stmts.push(
    `UPDATE inform.politician_context SET sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[]\n` +
    `WHERE politician_id = '${r.politician_id}'::uuid AND topic_id = '${r.topic_id}'::uuid\n` +
    `;  -- ${esc(r.full_name)} / ${esc(r.topic ?? '?')}  (${esc(p.dead)} -> ${esc(p.replacement.slug)})`
  );
}

const sql = `-- ${NUM}_repair_md_remaining_dead_member_slugs.sql
--
-- 5 politicians whose stances still cited a DEAD mgaleg member page. Same defect and same remedy as
-- mig 1689 -- these were HIDDEN FROM IT by the bug in the original audit.
--
-- 🔴 WHY THEY WERE MISSED, and it is the lesson: the old audit fetched the bare slug and then
-- session-qualified variants but cached them all under the bare slug's filename. \`hayes01?ys=2019RS\`
-- names Antonio Hayes -- it is his page from when he was a Delegate -- so the audit recorded "OK" while
-- the STORED bare \`hayes01\` is NotFound. A slug changes when a member moves chamber and the old one
-- stops resolving without a session. Re-running with the cache keyed on the FULL URL exposed all five.
-- ⚠ 3 of them (Hayes, McCray, Carozza) had exactly ONE row repaired by mig 1687, which is why they
-- looked partly fixed; the rest of their rows kept the dead citation.
--
-- Every replacement was confirmed by fetching it IN THE FORM IT WILL BE STORED and reading the page
-- title. All five resolve BARE, each \`01\` -> \`02\`:
--   ${plan.map((p) => `${p.who}: ${p.dead} -> ${p.replacement.slug} ("${p.replacement.confirmed_as}")`).join('\n--   ')}
--
-- SCOPE: ${stmts.length} rows across ${plan.length} politicians. Citations only -- NO stance value modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-remaining-dead-slugs-${NUM}-rollback.json
--
BEGIN
;

${stmts.join('\n\n')}

DO $$
DECLARE bad int;
BEGIN
  -- Per politician (never corpus-wide: an 01 slug can be somebody else's correct page).
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE
    ${plan.map((p) => `(c.politician_id = '${live.find((r) => r.full_name === p.who).politician_id}'::uuid AND (s LIKE '%Members/Details/${p.dead}' OR s LIKE '%Members/Details/${p.dead}?%'))`).join('\n    OR ')}
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still cite their own dead slug', bad; END IF;

  -- Each politician must now carry their verified replacement somewhere.
  SELECT count(*) INTO bad FROM (VALUES
    ${plan.map((p) => `('${live.find((r) => r.full_name === p.who).politician_id}'::uuid, '${esc(p.replacement.url)}')`).join(',\n    ')}
  ) AS v(pid, newurl)
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c, unnest(c.sources) s WHERE c.politician_id = v.pid AND s = v.newurl
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % politician(s) lack their replacement citation', bad; END IF;

  -- No duplicates, nobody sourceless.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE c.politician_id = ANY(ARRAY[${plan.map((p) => `'${live.find((r) => r.full_name === p.who).politician_id}'::uuid`).join(',')}])
    AND (c.sources IS NULL OR cardinality(c.sources) = 0
         OR cardinality(c.sources) <> (SELECT count(DISTINCT s) FROM unnest(c.sources) s));
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) empty or duplicated', bad; END IF;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`politicians: ${plan.length}`);
console.log(`rows rewritten: ${stmts.length}   (untouched, slug absent: ${unchanged})`);
