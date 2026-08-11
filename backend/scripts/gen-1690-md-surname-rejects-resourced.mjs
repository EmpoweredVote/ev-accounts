#!/usr/bin/env node
/**
 * Generate the migration for the pass-4c REJECT rows that turned out to be RIGHT.
 *
 * Pass 4b rejected these because the bill it matched was sponsored by a different same-surname member.
 * Reading them showed the rejection was the TOOL's fault: the reasoning states a YEAR ("HB0480 (2026)")
 * and the matcher had resolved bare numbers across all 14 sessions, landing on 2013-2015 bills.
 * Checked at the stated session, the politician IS a sponsor -- of a bill with a DIFFERENT number than
 * the prose gives. So the substance is true and both the citation AND the misstated number are repaired.
 *
 * ⚠ Reasoning is VOTER-FACING (`Citations.jsx` renders it under "Why this position?"), so a wrong bill
 *   number there is a live misstatement, not untidiness. Precedent for reasoning repair: migs 1524/1526.
 * ⚠ Guzzone's climate prose credited the Climate Solutions Now Act (2021/22) but she took office
 *   2023-01-11 -- PRE-TENURE. Her three real in-tenure climate sponsorships replace that claim.
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const NUM = flag('--num'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!NUM || !SQL_OUT || !ROLLBACK) { console.error('need --num --sql --rollback'); process.exit(2); }

const B = (slug, ys) => `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slug}?ys=${ys}`;

// Each entry verified this session by fetching the bill page and finding the politician's own slug in
// its "Sponsored by" list.
const PLAN = [
  { who: 'Caylin Young', topic: 'Voting Rights and Electoral Integrity',
    bills: [B('hb0350', '2026RS')],
    note: 'HB0350 (2026) "Voting Rights Act of 2026 - Counties and Municipal Corporations"; young05 IS a sponsor. The prose already named this title exactly; pass 4b had matched a 2017 bill of Pat Young.',
    reasoning: null },

  { who: 'Veronica Turner', topic: 'Affordable Housing',
    bills: [B('hb0573', '2026RS')],
    note: 'Prose said "HB0480 (2026)"; 2026 HB0480 is "Transportation Network Companies - Deactivation of Operators". The bill she describes -- "Fair Housing and Housing Discrimination - Regulations, Intent, and Discriminatory Effect" -- is 2026 HB0573, and turner01 IS a sponsor.',
    reasoning: 'Sponsored HB0573 (2026) — Fair Housing and Housing Discrimination - Regulations, Intent, and Discriminatory Effect; supports fair housing enforcement and anti-discrimination protections.' },

  { who: 'Veronica Turner', topic: 'Criminal Justice Approach',
    bills: [B('hb0626', '2026RS'), B('hb1309', '2026RS')],
    note: 'Both acts are real and she sponsors both, under different numbers than the prose gave: Exonerated 5 Act is 2026 HB0626 (not HB0574), and the racial-disparities commission is 2026 HB1309 (not HB0810).',
    reasoning: 'Sponsored the Exonerated 5 Act (HB0626, 2026) restricting admissibility of statements from custodial interrogation of minors; also sponsored HB1309 (2026) establishing a commission to review and assess racial disparities in the State criminal justice system; supports rehabilitation-focused reforms.' },

  { who: 'Pam Lanman Guzzone', topic: 'Climate Change and Environmental Protection',
    bills: [B('hb0347', '2023RS'), B('hb1279', '2024RS'), B('hb0340', '2025RS')],
    note: 'Prose credited the Climate Solutions Now Act (2021/2022) -- PRE-TENURE, she took office 2023-01-11 -- and pass 4b matched it to Guy Guzzone. Her own in-tenure climate sponsorships carry the same position honestly.',
    reasoning: 'Sponsored HB0347 (2023) authorizing Attorney General climate change actions, HB1279 (2024) on building performance standards and fossil fuel use, and HB0340 (2025) establishing a climate change restitution fund — consistently favors aggressive climate action.' },
];

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows: live } = await pool.query(`
  SELECT c.politician_id, c.topic_id, p.full_name, t.title AS topic, c.sources, c.reasoning
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  WHERE (p.full_name, t.title) IN (${PLAN.map((_, i) => `($${i * 2 + 1},$${i * 2 + 2})`).join(',')})`,
  PLAN.flatMap((p) => [p.who, p.topic]));
if (live.length !== PLAN.length) { console.error(`ABORT expected ${PLAN.length} rows, got ${live.length}`); await pool.end(); process.exit(1); }
await pool.end();

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: `${NUM}_resource_md_surname_rejects`,
  generated: 'pre-change snapshot from live DB',
  rule: 'pass-4c REJECT rows that reading showed were correct; the tool had resolved a bare bill number across all sessions. Citation added at the stated session and the misstated bill number corrected in voter-facing reasoning.',
  plan: PLAN, row_count: live.length, rows: live,
}, null, 2));

const key = (n, t) => `${n}|${t}`;
const liveBy = new Map(live.map((r) => [key(r.full_name, r.topic), r]));
const esc = (s) => s.replace(/'/g, "''");
const stmts = [];
for (const p of PLAN) {
  const r = liveBy.get(key(p.who, p.topic));
  const cur = r.sources || [];
  const next = [...p.bills, ...cur.filter((s) => !p.bills.includes(s))];
  const sets = [`sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[]`];
  if (p.reasoning) sets.push(`reasoning = '${esc(p.reasoning)}'`);
  stmts.push(
    `-- ${esc(p.who)} / ${esc(p.topic)}\n` +
    `-- ${esc(p.note)}\n` +
    `UPDATE inform.politician_context SET ${sets.join(', ')}\n` +
    `WHERE politician_id = '${r.politician_id}'::uuid AND topic_id = '${r.topic_id}'::uuid\n` +
    `;`
  );
}

const sql = `-- ${NUM}_resource_md_surname_rejects.sql
--
-- The 4 pass-4c REJECT rows that READING SHOWED WERE RIGHT. Pass 4b had rejected them because the bill
-- it matched was sponsored by a different same-surname legislator -- but that match was its own error:
-- the prose states a YEAR and the matcher resolved bare bill numbers across all 14 sessions.
--
-- 🔑 Checked at the session the prose actually states, each politician IS a sponsor -- of a bill with a
-- different NUMBER than the prose gave. So the substance was true and the number was wrong, which is the
-- opposite conclusion from "this row credits someone else's bill".
--
-- Reasoning is repaired alongside the citation because it is VOTER-FACING and carried the wrong number.
-- Precedent for reasoning repair: migs 1524, 1526.
--
-- NOT in this migration, and why:
--   7 rows UNVERIFIED, left untouched -- Alonzo T. Washington (6) and Mary Washington (1) say "supported"
--     / "backed" / "voted YES", never "sponsored". A sponsor list cannot settle a floor vote, and BOTH
--     were in office for every bill named (Washington: House 2012-12-19 to 2023-01-30, then Senate;
--     M. Washington: House 2011-2019, Senate since 2019). Their claims are UNVERIFIED, not false, and
--     roll calls are separate PDFs. ⚠ Adding the matched bill would credit MARY Washington's sponsorship
--     to ALONZO -- exactly the error 1685 held these rows back to avoid.
--   2 rows PRE-TENURE and unsupported -- Pam Lanman Guzzone / School Vouchers and / Taxation both rest
--     solely on the Blueprint for Maryland's Future (2019/2020). She took office 2023-01-11, so she
--     cannot have supported it. She sponsors NONE of the 23 in-tenure voucher/BOOST bills nor any of the
--     14 in-tenure progressive-tax bills. Held for an operator decision -- retirement is the one
--     irreversible step on this workstream.
--
-- No stance VALUE is modified.
-- Rollback: backend/data/stance-retirement/2026-08-11-md-surname-rejects-${NUM}-rollback.json
--
BEGIN
;

${stmts.join('\n\n')}

DO $$
DECLARE bad int;
BEGIN
  -- Each touched row must now cite its verified bill.
  SELECT count(*) INTO bad FROM (VALUES
    ${PLAN.map((p) => {
      const r = liveBy.get(key(p.who, p.topic));
      return `('${r.politician_id}'::uuid,'${r.topic_id}'::uuid,'${esc(p.bills[0])}')`;
    }).join(',\n    ')}
  ) AS v(pid, tid, billurl)
  WHERE NOT EXISTS (
    SELECT 1 FROM inform.politician_context c, unnest(c.sources) s
    WHERE c.politician_id = v.pid AND c.topic_id = v.tid AND s = v.billurl
  );
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) lack their verified bill citation', bad; END IF;

  -- No touched row may still state a bill number this migration proved wrong.
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ${PLAN.filter((p) => p.reasoning).map((p) => {
      const r = liveBy.get(key(p.who, p.topic));
      return `('${r.politician_id}'::uuid,'${r.topic_id}'::uuid)`;
    }).join(',\n    ')}
  ) AND (c.reasoning LIKE '%HB0480%' OR c.reasoning LIKE '%HB0574%' OR c.reasoning LIKE '%HB0810%'
      OR c.reasoning LIKE '%Climate Solutions Now%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) still state a disproved bill number', bad; END IF;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`rows: ${stmts.length}`);
console.log(`reasoning rewritten: ${PLAN.filter((p) => p.reasoning).length}`);
console.log(`rollback: ${ROLLBACK}`);
