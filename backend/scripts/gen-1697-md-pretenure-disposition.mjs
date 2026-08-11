#!/usr/bin/env node
/**
 * Dispose of the 29 PRE-TENURE Maryland rows (operator instruction 2026-08-11).
 *
 * Every one of these rows rests on an instrument that predates the member's service, so the claim AS
 * WRITTEN is impossible. The Guzzone standard decides what happens next: search for in-tenure evidence,
 * RE-SOURCE where the member's own record carries the chair, RETIRE where it does not.
 *
 * 🔑 ON-TOPIC BY VOCABULARY IS NOT ON-TOPIC BY RATIONALE. The automated in-tenure search returned a
 *    sponsorship for 21 of 29 rows, but reading them showed 12 were vocabulary collisions that cannot
 *    support the chair:
 *      "Nonpublic Schools - Corporal Punishment" and "Student Elopement - Notice"  for a VOUCHERS chair
 *      "Income Tax Credit - Venison Donation", "Theatrical Production Tax Credit"  for PROGRESSIVE TAXATION
 *      "Criminal Law - Fraud - Assisted Reproductive Treatment"                    for ABORTION ACCESS
 *      "Public and Nonpublic Schools - Bronchodilator Availability"                for EDUCATION FUNDING
 *    A narrow targeted credit does not pin a "tax the wealthy" chair, and fertility fraud is not abortion
 *    access. Those rows are treated as having no substitute.
 *
 * 🔴 Retirement is irreversible; the rollback JSON is written BEFORE the delete and holds the only copy of
 *    the reasoning, sources and value. Retire = DELETE from politician_answers AND politician_context.
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), NUM = flag('--num'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!IN || !NUM || !SQL_OUT || !ROLLBACK) { console.error('need --in --num --sql --rollback'); process.exit(2); }

const B = (slug, ys) => `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${ys}`;

/** Hand-adjudicated: the member's own in-tenure record genuinely carries this chair. */
const RESOURCE = {
  'Darrell Odom|Voting Rights and Electoral Integrity': {
    bills: [B('hb0350', '2026RS')],
    reasoning: 'Co-sponsored HB0350 (2026), the Voting Rights Act of 2026 for counties and municipal corporations; supports expanding voting protections and local ballot access.' },
  'Sean A. Stinnett|Voting Rights and Electoral Integrity': {
    bills: [B('hb0350', '2026RS'), B('hb0641', '2026RS')],
    reasoning: 'Sponsored HB0350 (2026), the Voting Rights Act of 2026 for counties and municipal corporations, and HB0641 (2026) establishing a curbside voting pilot program; supports expanding ballot access.' },
  'Kim Ross|Reproductive Rights and Abortion Access': {
    bills: [B('hb0930', '2025RS')],
    reasoning: 'Sponsored HB0930 (2025) establishing the Public Health Abortion Grant Program; supports public funding for abortion access.' },
  'Gabriel M. Moreno|Immigration and Treatment of Immigrants': {
    bills: [B('hb0444', '2026RS'), B('hb1341', '2026RS')],
    reasoning: 'Sponsored HB0444 (2026) prohibiting immigration enforcement agreements and HB1341 (2026) expanding sensitive locations and notification requirements for immigration enforcement; opposes state and local cooperation with federal immigration enforcement.' },
  'Gabriel M. Moreno|Climate Change and Environmental Protection': {
    bills: [B('hb0572', '2026RS')],
    reasoning: 'Sponsored HB0572 (2026), the Climate Crimes Accountability Act, creating Attorney General authority and a climate accountability fund; favors aggressive climate action.' },
  'Dawn Gile|Childcare Affordability & Access': {
    bills: [B('sb0350', '2023RS'), B('sb0280', '2023RS')],
    reasoning: 'Sponsored SB0350 (2023) altering the Child Care Scholarship Program and SB0280 (2023) on child care provider registration and licensing; backs expanded childcare access and subsidy programs.' },
  'Dawn Gile|Reproductive Rights and Abortion Access': {
    bills: [B('sb0447', '2025RS'), B('sb0563', '2026RS')],
    reasoning: 'Sponsored SB0447 (2025) on hospital procedures for emergency pregnancy-related medical conditions and SB0563 (2026) on confidentiality of medical records at crisis pregnancy clinics; supports reproductive healthcare access.' },
  'Kevin M. Harris|Childcare Affordability & Access': {
    bills: [B('sb0664', '2026RS'), B('sb0402', '2026RS')],
    reasoning: 'Sponsored SB0664 (2026) prioritising child care providers in the Child Care Scholarship Program and SB0402 (2026) on residential child care programs; backs childcare subsidy expansion.' },
  'Cheryl E. Pasteur|Public Safety Approach': {
    bills: [B('hb0155', '2026RS')],
    reasoning: 'Sponsored HB0155 (2026) prohibiting face coverings for law enforcement officers; favors police accountability and transparency over enforcement-first approaches.' },
};

const pass6 = JSON.parse(fs.readFileSync(IN, 'utf8'));
const rows = pass6.rows;
const resourceRows = rows.filter((r) => RESOURCE[`${r.politician}|${r.topic}`]);
const retireRows = rows.filter((r) => !RESOURCE[`${r.politician}|${r.topic}`]);

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const pids = [...new Set(rows.map((r) => r.politician_id))];
const { rows: live } = await pool.query(`
  SELECT c.politician_id, c.topic_id, p.full_name, t.title AS topic, a.value, a.write_in_text,
         c.reasoning, c.sources
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  LEFT JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE c.politician_id = ANY($1::uuid[])`, [pids]);
const { rows: counts } = await pool.query(`
  SELECT politician_id, count(*) AS n FROM inform.politician_context
  WHERE politician_id = ANY($1::uuid[]) GROUP BY politician_id`, [pids]);
await pool.end();

const liveBy = new Map(live.map((r) => [`${r.politician_id}|${r.topic}`, r]));
const countBy = new Map(counts.map((r) => [r.politician_id, Number(r.n)]));

// nobody may be emptied
const retireCount = {};
for (const r of retireRows) retireCount[r.politician_id] = (retireCount[r.politician_id] ?? 0) + 1;
for (const [pid, n] of Object.entries(retireCount)) {
  const total = countBy.get(pid) ?? 0;
  if (total - n <= 0) { console.error(`ABORT: retiring ${n} of ${total} rows would empty ${pid}`); process.exit(1); }
}

const doomed = retireRows.map((r) => liveBy.get(`${r.politician_id}|${r.topic}`)).filter(Boolean);
if (doomed.length !== retireRows.length) { console.error('ABORT: some rows to retire were not found live'); process.exit(1); }

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: `${NUM}_dispose_md_pretenure_rows`,
  retired_on: '2026-08-11',
  authorised_by: 'operator instruction 2026-08-11 ("Then Pre-tenure 29")',
  rule: 'All 29 rows rest on an instrument predating the member\'s service, so the claim as written is impossible. 9 rows had genuinely on-chair in-tenure sponsorships and were RE-SOURCED with corrected reasoning; the other 20 had none (12 of them only vocabulary collisions, e.g. a venison tax credit for a progressive-taxation chair) and were RETIRED.',
  restore_note: 'Retirement DELETED the answer and the context row; restoring is an INSERT into inform.politician_answers and inform.politician_context from the values below.',
  resourced: resourceRows.map((r) => ({ politician: r.politician, topic: r.topic, ...RESOURCE[`${r.politician}|${r.topic}`] })),
  retired_count: doomed.length,
  retired_rows: doomed,
  vocabulary_only_note: rows.filter((r) => !RESOURCE[`${r.politician}|${r.topic}`] && r.in_tenure_sponsorships.length)
    .map((r) => ({ politician: r.politician, topic: r.topic, rejected_matches: r.in_tenure_sponsorships.map((f) => `${f.session} ${f.number} ${f.title}`) })),
}, null, 2));

const esc = (s) => s.replace(/'/g, "''");
const upd = [];
for (const r of resourceRows) {
  const live1 = liveBy.get(`${r.politician}|${r.topic}`) ?? liveBy.get(`${r.politician_id}|${r.topic}`);
  const plan = RESOURCE[`${r.politician}|${r.topic}`];
  const cur = live1.sources || [];
  const next = [...plan.bills, ...cur.filter((s) => !plan.bills.includes(s))];
  upd.push(
    `UPDATE inform.politician_context SET sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[], reasoning = '${esc(plan.reasoning)}'\n` +
    `WHERE politician_id = '${live1.politician_id}'::uuid AND topic_id = '${live1.topic_id}'::uuid\n` +
    `;  -- RE-SOURCED ${esc(r.politician)} / ${esc(r.topic)}`
  );
}
const pairs = doomed.map((d) => `('${d.politician_id}'::uuid,'${d.topic_id}'::uuid)`);

const sql = `-- ${NUM}_dispose_md_pretenure_rows.sql
--
-- The 29 PRE-TENURE Maryland rows. Operator instruction 2026-08-11.
--
-- Every row rests on an instrument that PREDATES the member's service, so the claim as written is
-- impossible, not merely unsourced. The Guzzone standard (migs 1690 vs 1692) decides the rest: search for
-- in-tenure evidence, re-source where the member's own record carries the chair, retire where it does not.
--
--   9 RE-SOURCED with corrected reasoning -- their own in-tenure bills carry the position
--  20 RETIRED -- no honest substitute
--
-- 🔑 ON-TOPIC BY VOCABULARY IS NOT ON-TOPIC BY RATIONALE, and this is where most of the work was. The
-- automated in-tenure search found a sponsorship for 21 of 29 rows; READING them showed 12 were vocabulary
-- collisions that cannot support the chair, so those rows count as having nothing:
--   "Nonpublic Schools - Corporal Punishment", "Student Elopement - Notice",
--   "Public and Nonpublic Schools - Bronchodilator Availability"    -> a SCHOOL VOUCHERS chair
--   "Income Tax Credit - Venison Donation", "Theatrical Production Tax Credit",
--   "Subtraction Modification for Classroom Supplies"               -> a PROGRESSIVE TAXATION chair
--   "Criminal Law - Fraud - Assisted Reproductive Treatment"        -> an ABORTION ACCESS chair
--   "Sales and Use Tax - Distribution of Cannabis Revenue"          -> a TAXATION chair
-- A narrow targeted credit does not pin "tax the wealthy", and fertility fraud is not abortion access.
--
-- 🔴 Retire = delete the ANSWER and the CONTEXT row; context alone leaves an orphan answer and trips
--    ANSWER_WITHOUT_CONTEXT (must be 0). NOBODY is emptied (asserted below).
-- Rollback -- the only surviving copy of the retired reasoning, sources and values, plus the list of
-- rejected vocabulary matches: backend/data/stance-retirement/2026-08-11-md-pretenure-${NUM}-rollback.json
--
BEGIN
;

CREATE TEMP TABLE _${NUM}_before ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_total,
       (SELECT count(*) FROM inform.politician_answers)  AS ans_total
;

-- ---------- 9 rows RE-SOURCED to the member's own in-tenure record ----------

${upd.join('\n\n')}

-- ---------- 20 rows RETIRED: claim impossible, no honest substitute ----------

DELETE FROM inform.politician_answers WHERE (politician_id, topic_id) IN (
  ${pairs.join(',\n  ')}
)
;

DELETE FROM inform.politician_context WHERE (politician_id, topic_id) IN (
  ${pairs.join(',\n  ')}
)
;

DO $$
DECLARE b record; bad int;
BEGIN
  SELECT * INTO b FROM _${NUM}_before;
  IF (SELECT count(*) FROM inform.politician_context) <> b.ctx_total - ${doomed.length} THEN
    RAISE EXCEPTION 'guard failed: context delta is not exactly -${doomed.length}'; END IF;
  IF (SELECT count(*) FROM inform.politician_answers) <> b.ans_total - ${doomed.length} THEN
    RAISE EXCEPTION 'guard failed: answers delta is not exactly -${doomed.length}'; END IF;

  SELECT count(*) INTO bad FROM inform.politician_context WHERE (politician_id, topic_id) IN (
    ${pairs.join(',\n    ')}
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % retired context row(s) survive', bad; END IF;

  -- no orphan answers anywhere
  SELECT count(*) INTO bad FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id = a.politician_id AND c.topic_id = a.topic_id);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % orphan answer(s) corpus-wide', bad; END IF;

  -- nobody emptied
  SELECT count(*) INTO bad FROM (VALUES ${[...new Set(rows.map((r) => `('${r.politician_id}'::uuid)`))].join(',')}) AS v(pid)
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c WHERE c.politician_id = v.pid);
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % politician(s) emptied', bad; END IF;

  -- every re-sourced row must carry a bill citation
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ${resourceRows.map((r) => { const l = liveBy.get(`${r.politician_id}|${r.topic}`); return `('${l.politician_id}'::uuid,'${l.topic_id}'::uuid)`; }).join(',\n    ')}
  ) AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % re-sourced row(s) lack a bill citation', bad; END IF;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`re-sourced: ${upd.length}`);
console.log(`retired   : ${doomed.length}`);
console.log('per politician retired:', JSON.stringify(Object.fromEntries(
  Object.entries(retireCount).map(([pid, n]) => [live.find((l) => l.politician_id === pid)?.full_name ?? pid, `${n} of ${countBy.get(pid)}`]))));
