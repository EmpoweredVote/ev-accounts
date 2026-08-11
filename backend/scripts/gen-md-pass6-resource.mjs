#!/usr/bin/env node
/**
 * Generate the Maryland PASS 6 migration -- re-source generic-only stances to the specific bills
 * (and floor-vote PDFs) they already name.
 *
 * Modelled on gen-1685-md-bill-resource.mjs. Citations only; NO stance value and NO reasoning is
 * modified, and nothing is deleted -- the corpus row count must come out unchanged.
 *
 * TWO EVIDENCE ROUTES, and a row qualifies on exactly one:
 *  A. SPONSOR  -- the legislator's OWN mgaleg slug is in the bill's "Sponsored by" list, AND the
 *     citation passed the fit audit (the bill title carries the act the reasoning names, at the year
 *     the reasoning states). Only APPLY-verdict citations are written.
 *     ⚠ SURPLUS_SESSION citations are deliberately DROPPED: the member sponsored the act in several
 *     sessions and the prose names one of them, so the others are noise, not evidence.
 *  B. ROLLCALL -- no sponsor link, but a PASSAGE roll-call PDF names the member and the vote
 *     direction is CONSISTENT with the claim. Requires bill_identity.ok from the direction pass.
 *
 * 🔴 EXCLUDED ON PURPOSE (each needs a human, none is a delete list):
 *    46 sponsor rows whose every citation is suspect (ACT_AMBIGUOUS_NO_YEAR 22, NUMBER_ONLY 15,
 *    ACT_YEAR_STALE 7, NO_FIT 2) · 70 UNRESOLVED roll calls · 15 VOID_WRONG_BILL · 1 CONTRADICTED
 *    (Anne Healey / abortion -- read the PDF first) · 21 PRE_TENURE verdicts that are CONTAMINATED
 *    by wrong-session bill resolution · 10 surname-only · 3 tenure-unknown · 937 rows naming nothing.
 *
 * ⚠ Terminator discipline: a previous generator on this workstream put `;` after a trailing `--`
 * comment and silently produced an unterminated statement. Terminators go on their own line.
 *
 *   node scripts/gen-md-pass6-resource.mjs --fit <fit.json> --sponsorship <sp.json> \
 *        --direction <dir.json> --num <migration_number> --sql <out.sql> --rollback <out.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const FIT = flag('--fit'), SPONS = flag('--sponsorship'), DIR = flag('--direction');
const NUM = flag('--num'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!FIT || !SPONS || !DIR || !NUM || !SQL_OUT || !ROLLBACK) {
  console.error('need --fit --sponsorship --direction --num --sql --rollback'); process.exit(2);
}

// Verdicts whose citation is safe to write. SURPLUS_SESSION is intentionally absent.
const APPLY = new Set(['TITLE_CARRIES_ACT_AND_YEAR', 'TITLE_CARRIES_ACT',
  'TITLE_CARRIES_ACT_ALL_SESSIONS', 'NUMBER_AND_YEAR']);

const fit = JSON.parse(fs.readFileSync(FIT, 'utf8'));
const sp = JSON.parse(fs.readFileSync(SPONS, 'utf8'));
const dir = JSON.parse(fs.readFileSync(DIR, 'utf8'));
const dirRows = dir.rows || dir;
const spRows = sp.rows || sp;

// ---- route A: sponsor-confirmed rows with at least one APPLY citation ----
const spMeta = new Map(spRows.map((r) => [`${r.politician_id}|${r.topic_id}`, r]));
const byRow = new Map();
for (const f of fit.findings) {
  if (!APPLY.has(f.verdict)) continue;
  const k = `${f.politician_id}|${f.topic_id}`;
  if (!byRow.has(k)) byRow.set(k, { politician: f.politician, topic: f.topic, urls: new Set(), why: new Set() });
  byRow.get(k).urls.add(f.url);
  byRow.get(k).why.add(`${f.attached} ${f.verdict}`);
}
const routeA = [...byRow.entries()].map(([k, v]) => {
  const [politician_id, topic_id] = k.split('|');
  return { politician_id, topic_id, politician: v.politician, topic: v.topic,
    urls: [...v.urls].sort().slice(0, 4), route: 'SPONSOR', why: [...v.why].join('; ') };
});

// ---- route B: roll-call CONSISTENT with a confirmed bill identity ----
const routeB = dirRows
  .filter((r) => r.verdict === 'CONSISTENT' && r.bill_identity?.ok && r.vote_pdf)
  .map((r) => {
    const [session, number] = r.bill.split(' ');
    return {
      politician_id: r.politician_id, topic_id: r.topic_id,
      politician: r.politician, topic: r.topic, route: 'ROLLCALL',
      urls: [`https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${number.toLowerCase()}?ys=${session}`, r.vote_pdf],
      why: `${r.vote} on ${r.bill} (${r.bill_identity.why})`,
    };
  });

const seen = new Set(routeA.map((r) => `${r.politician_id}|${r.topic_id}`));
const all = [...routeA, ...routeB.filter((r) => !seen.has(`${r.politician_id}|${r.topic_id}`))];
if (!all.length) { console.error('nothing to write'); process.exit(1); }

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// ---- rollback FIRST, straight from the DB (never from a worklist's copy) ----
const keys = all.map((r) => [r.politician_id, r.topic_id]);
const { rows: live } = await pool.query(
  `SELECT c.politician_id, c.topic_id, p.full_name, t.title AS topic, c.sources, c.reasoning
   FROM inform.politician_context c
   JOIN essentials.politicians p ON p.id = c.politician_id
   LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
   WHERE (c.politician_id, c.topic_id) IN (${keys.map((_, i) => `($${i * 2 + 1}::uuid,$${i * 2 + 2}::uuid)`).join(',')})`,
  keys.flat());

if (live.length !== all.length) {
  console.error(`ABORT: expected ${all.length} live rows, found ${live.length}. Refusing to generate.`);
  await pool.end(); process.exit(1);
}
const liveByKey = new Map(live.map((r) => [`${r.politician_id}|${r.topic_id}`, r]));

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: `${NUM}_resource_md_pass6_generic_only_stances`,
  generated: 'pre-change snapshot taken from the live DB',
  rule: 'Each row was sourced ONLY by generic profile pages (mgaleg member page / Ballotpedia bio / '
      + 'Wikipedia) and named a specific instrument in its voter-facing reasoning. Route SPONSOR: the '
      + "legislator's own mgaleg slug appears in that bill's Sponsored by list AND the bill title "
      + 'carries the named act at the stated year. Route ROLLCALL: a passage roll-call PDF names the '
      + 'member and the direction is consistent with the claim. Specific citations are PREPENDED; '
      + 'existing sources are kept. Stance values and reasoning untouched.',
  row_count: live.length,
  decisions: all.map((r) => ({ politician: r.politician, topic: r.topic, route: r.route, why: r.why, added: r.urls })),
  rows: live,
}, null, 2));

// ---- build new source arrays ----
const esc = (s) => s.replace(/'/g, "''");
const stmts = [];
let added = 0;
for (const r of all) {
  const cur = liveByKey.get(`${r.politician_id}|${r.topic_id}`).sources || [];
  const next = [...r.urls, ...cur.filter((s) => !r.urls.includes(s))];
  if (next.length === cur.length && next.every((v, i) => v === cur[i])) continue;
  added += r.urls.length;
  stmts.push(
    `UPDATE inform.politician_context SET sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[]\n`
    + `WHERE politician_id = '${r.politician_id}'::uuid AND topic_id = '${r.topic_id}'::uuid\n`
    + `;  -- [${r.route}] ${esc(r.politician)} / ${esc(r.topic)}`
  );
}

const pols = new Set(all.map((r) => r.politician)).size;
const sql = `-- ${NUM}_resource_md_pass6_generic_only_stances.sql
-- Maryland PASS 6 -- re-source GENERIC-ONLY stances to the instruments they already name.
--
-- WHY THIS COHORT EXISTS: passes 1-5 selected work POLITICIAN-level (distinct source sets = 1 AND
-- >= 5 rows). That test excludes anyone who has ANY row with a specific citation, so as passes 4/5
-- fixed some of a politician's rows, that politician dropped OUT of the queue carrying their
-- remaining defective rows with them. Re-measured ROW-level, the real defect population is 1,241
-- rows across 154 politicians, of which 618 rows had never been audited at all.
--
-- EVIDENCE. Each row's named instrument was resolved against a local corpus of 73,232 MD bills
-- (2013RS-2026RS) rebuilt from the MGA session indexes, then either:
--   SPONSOR  -- the legislator's OWN mgaleg slug appears in that bill's "Sponsored by" list AND the
--               bill title carries the named act at the year the reasoning states; or
--   ROLLCALL -- a PASSAGE floor-vote PDF names the member and the direction matches the claim.
--
-- SCOPE: ${stmts.length} rows across ${pols} legislators. CITATIONS ONLY -- no stance value, no
-- reasoning, no deletions. Corpus row count must be UNCHANGED by this migration.
--
-- DELIBERATELY NOT INCLUDED (each needs a human; none is a delete list):
--   46 rows whose every candidate citation is suspect (act ambiguous across sessions 22, bare bill
--      number resolving to another session 15, stated year stale 7, no title fit 2)
--   70 roll calls UNRESOLVED, 15 VOID_WRONG_BILL (vote real but on an unrelated bill)
--    1 CONTRADICTED  -- Anne Healey / abortion: prose says "voted for" the ACAA, parse says NAY on
--                       2022RS HB0937. Read the PDF and confirm surname identity before acting.
--   21 PRE_TENURE verdicts that are CONTAMINATED -- the tenure screen judged against wrong-session
--      bills (Mark Edelson screened on 2013RS bills though his instruments are 2024-2026).
--   10 surname-only matches, 3 tenure-unknown, and 937 rows naming no instrument at all.
--
-- Rollback: backend/data/stance-retirement/2026-08-11-md-pass6-resource-rollback.json
--
BEGIN
;

-- Snapshot BEFORE any write, inside the transaction. Guard 2 compares against this.
-- ⚠ Taking the "before" count in the same statement as the "after" count compares a value to
-- itself and passes unconditionally -- a guard that cannot fail is not a guard.
CREATE TEMP TABLE pass6_snapshot ON COMMIT DROP AS
SELECT
  (SELECT count(*) FROM inform.politician_context) AS ctx_before,
  (SELECT count(*) FROM inform.politician_answers) AS ans_before
;

${stmts.join('\n\n')}

-- Guard 1: every touched row must now carry a specific citation (a bill page or a vote sheet).
-- ⚠ Scoped to the rows this migration touches. A scoped guard CANNOT answer a corpus-wide question
-- (that is why mig 1691 had to exist) -- the corpus-wide check is run separately after applying.
DO $$
DECLARE missing int;
BEGIN
  SELECT count(*) INTO missing
  FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ${all.map((r) => `('${r.politician_id}'::uuid,'${r.topic_id}'::uuid)`).join(',\n    ')}
  )
  AND NOT EXISTS (
    SELECT 1 FROM unnest(c.sources) s
    WHERE s LIKE '%Legislation/Details/%' OR s LIKE '%/votes/%'
  );
  IF missing > 0 THEN
    RAISE EXCEPTION 'guard 1 failed: % row(s) lack a specific citation', missing;
  END IF;
END
$$;

-- Guard 2: this migration must not delete or create anything. Deltas are asserted against a
-- snapshot taken INSIDE the transaction, never against a hard-coded corpus total.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM pass6_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO orphans
  FROM inform.politician_answers a
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c
    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id
  );
  IF ctx_after <> snap.ctx_before THEN
    RAISE EXCEPTION 'guard 2 failed: context rows moved % -> %', snap.ctx_before, ctx_after;
  END IF;
  IF ans_after <> snap.ans_before THEN
    RAISE EXCEPTION 'guard 2 failed: answer rows moved % -> %', snap.ans_before, ans_after;
  END IF;
  IF orphans > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % answer(s) without context', orphans;
  END IF;
  RAISE NOTICE 'pass6 ok: context=% (unchanged) answers=% (unchanged) orphans=%',
    ctx_after, ans_after, orphans;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`rows updated  : ${stmts.length}`);
console.log(`  route SPONSOR : ${routeA.length}`);
console.log(`  route ROLLCALL: ${all.length - routeA.length}`);
console.log(`citations added: ${added}`);
console.log(`legislators    : ${pols}`);
console.log(`rollback       : ${ROLLBACK}`);
await pool.end();
