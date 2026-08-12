#!/usr/bin/env node
/**
 * Generate the migration re-sourcing the Massachusetts "Affordable Homes Act" rows to the bill and
 * the Senate roll call that names each member.
 *
 * Evidence: 193rd General Court H.4977, "An Act relative to the Affordable Homes Act" (Chapter 150 of
 * the Acts of 2024), Senate Roll Call #249, "Question on passing the bill to be enacted" -- an
 * ENACTMENT vote, so the passage-only rule is satisfied. Parse self-checked: YEAS 37/37, NAYS 2/2.
 *
 * ⚠ HONEST WEIGHT: 37-2 in a 40-seat Senate is NEAR-UNANIMOUS, and by the rule applied to Mary
 * Lehman's 130-1 RELIEF Act vote, a near-unanimous vote cannot establish a DISTINCTIVE position.
 * It is used here for the narrower and correct purpose: every one of these rows CLAIMS the member
 * supported the 2024 Affordable Homes Act, and the roll call VERIFIES THAT CLAIM. The citation
 * evidences the sentence, not the chair value.
 *
 * ⚠ Reasoning is left UNCHANGED. Several rows carry softer secondary claims (MBTA Communities
 * compliance, "championed funding") that this citation does not support -- but unlike the pass-6d
 * voucher clause, those were never searched for, and NOT SEARCHED is not NOT FOUND. They are flagged
 * in the record rather than deleted.
 *
 *   node scripts/gen-ma-affordable-homes.mjs --num <n> --sql <out.sql> --rollback <out.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const NUM = flag('--num'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!NUM || !SQL_OUT || !ROLLBACK) { console.error('need --num --sql --rollback'); process.exit(2); }

const BILL = 'https://malegislature.gov/Bills/193/H4977';
const VOTE = 'https://malegislature.gov/RollCall/193/SenateRollCall249.pdf';
const TOPIC = '669cac97-66a6-4087-b036-936fbe62efb3';  // Affordable Housing
const PIDS = [
  ['Brendan P. Crighton', '99457307-afa4-4045-aebf-06ee8b39d28f'],
  ['Bruce E. Tarr', 'b1bd9a21-a37e-49f4-907b-9fba480a1ca2'],
  ['Jason M. Lewis', 'a40f234e-1790-4b52-8670-090b6379eb03'],
  ['Joan B. Lovely', '6d8717ca-45f9-42cf-bd28-6786a50d254f'],
  ['John F. Keenan', '5cd1c798-31dc-4e53-b578-7e2d81378478'],
  ['Julian A. Cyr', 'bd451748-111f-461d-9752-95e7c243769e'],
  ['Liz Miranda', '2f7d598c-c3d7-48ba-ac9c-fb059e032bfe'],
  ['Lydia M. Edwards', '11d73e67-bcd9-419a-8b0d-a26447eb0c0b'],
  ['Mark C. Montigny', '6f66ea3f-d5a3-4a51-96be-58aa0097bfc0'],
  ['Michael D. Brady', '67ea7814-b7aa-42de-aba8-2230c181d15a'],
  ['Michael J. Rodrigues', 'f865995d-ad3a-4d2d-827f-ed8a1a67af18'],
  ['Nick Collins', '2c53dc2c-38ae-4f39-873d-9ea1841b1c4c'],
  ['Patricia D. Jehlen', 'd40a0eda-36fc-4032-8382-20c76a36d6a6'],
  ["Patrick M. O'Connor", 'e1f72270-5809-4d0e-969c-48d1ab34fbdc'],
  ['Paul R. Feeney', 'c435ab14-5d64-46e4-a59f-bba18ed483c9'],
  ['Sal N. DiDomenico', 'c7e94dda-1862-40fe-bda5-5fa2fe68f536'],
  ['William N. Brownsberger', '8a63eab9-1b32-48c6-ab4e-ba96c12ec5e7'],
];

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const { rows: live } = await pool.query(
  `SELECT c.politician_id, c.topic_id, p.full_name, c.sources, c.reasoning
   FROM inform.politician_context c JOIN essentials.politicians p ON p.id=c.politician_id
   WHERE c.topic_id = $1::uuid AND c.politician_id = ANY($2::uuid[])`,
  [TOPIC, PIDS.map((x) => x[1])]);
await pool.end();

if (live.length !== PIDS.length) {
  console.error(`ABORT: expected ${PIDS.length} live rows, found ${live.length}`); process.exit(1);
}
const byId = new Map(live.map((r) => [r.politician_id, r]));

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: `${NUM}_resource_ma_affordable_homes_act`,
  generated: 'pre-change snapshot read from the live DB',
  evidence: {
    bill: '193rd General Court H.4977 "An Act relative to the Affordable Homes Act" (Chapter 150, Acts of 2024)',
    vote: 'Senate Roll Call #249 — Question on passing the bill to be enacted. YEAS 37 / NAYS 2, parse self-checked against both declared counts.',
    identity: 'MA roll calls print "Surname, First M.", so each match is on surname AND first name. No surname-only match was accepted.',
  },
  caveats: {
    near_unanimous: '37-2 in a 40-seat Senate. By the rule applied to Mary Lehman\'s 130-1 vote, this cannot establish a DISTINCTIVE position — it is used only to verify the claim each row already makes, that the member supported the Act.',
    secondary_claims: 'Several rows also assert MBTA Communities compliance or funding advocacy, which this citation does not support. Unlike the pass-6d voucher clause those were never searched for, and NOT SEARCHED is not NOT FOUND, so reasoning is left unchanged.',
  },
  not_applied: {
    'Ronald Mariano': 'Speaker of the House — not on a Senate roll call.',
    'William J. Driscoll': 'Representative — not on a Senate roll call.',
    'Dylan A. Fernandes': 'Was a Representative in the 193rd; elected to the Senate afterwards.',
    'Karen E. Spilka': 'Senate President. 37+2=39 of 40 seats, so the presiding officer is the one missing — UNKNOWN, never guessed (same rule as the MD Speaker/President case).',
  },
  row_count: live.length,
  rows: live,
}, null, 2));

const esc = (s) => s.replace(/'/g, "''");
const stmts = PIDS.map(([name, pid]) => {
  const cur = byId.get(pid).sources || [];
  const next = [BILL, VOTE, ...cur.filter((s) => s !== BILL && s !== VOTE)];
  return `UPDATE inform.politician_context SET sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[]\n`
    + `WHERE politician_id = '${pid}'::uuid AND topic_id = '${TOPIC}'::uuid\n`
    + `;  -- ${esc(name)} — YEA`;
});

const sql = `-- ${NUM}_resource_ma_affordable_homes_act.sql
-- Massachusetts Tier A -- re-source the "Affordable Homes Act" rows to the bill and the roll call.
--
-- EVIDENCE: 193rd General Court **H.4977**, "An Act relative to the Affordable Homes Act"
-- (Chapter 150 of the Acts of 2024). **Senate Roll Call #249**, "Question on passing the bill to be
-- enacted" -- an ENACTMENT vote, so the passage-only rule holds. Parse self-checked against the
-- sheet's own declared totals: YEAS 37/37, NAYS 2/2.
--
-- 🔑 MA IDENTITY IS SAFER THAN MD: the sheet prints "Surname, First M.", not a bare surname, so every
-- match here is on surname AND first name. No surname-only match was accepted.
--
-- ⚠ NEAR-UNANIMOUS: 37-2 in a 40-seat Senate. By the same rule that rejected Mary Lehman's 130-1
-- RELIEF Act vote, this cannot establish a DISTINCTIVE position. It is used for the narrower and
-- correct purpose: every row here CLAIMS the member supported the 2024 Affordable Homes Act, and the
-- roll call VERIFIES THAT CLAIM. The citation evidences the sentence, not the chair value.
--
-- ⚠ REASONING LEFT UNCHANGED. Some rows carry softer secondary claims (MBTA Communities compliance,
-- "championed funding") this citation does not support -- but unlike the pass-6d voucher clause,
-- those were never searched for, and NOT SEARCHED IS NOT NOT FOUND. Flagged in the record, not deleted.
--
-- NOT APPLIED (4 of the 21 rows citing this Act): Ronald Mariano and William J. Driscoll are House
-- members; Dylan A. Fernandes was a Representative in the 193rd; **Karen E. Spilka is Senate
-- President** and 37+2=39 of 40 seats, so the presiding officer is the one missing -- UNKNOWN, never
-- guessed, exactly as with the MD Speaker.
--
-- Rollback: backend/data/stance-retirement/${new Date().toISOString().slice(0, 10)}-ma-affordable-homes-rollback.json
--
BEGIN
;

CREATE TEMP TABLE ma_aha_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before
;

${stmts.join('\n\n')}

-- Guard 1 (scoped to the touched rows): each must now cite both the bill and the roll call.
DO $$
DECLARE bad int;
BEGIN
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE c.topic_id = '${TOPIC}'::uuid
    AND c.politician_id IN (${PIDS.map(([, p]) => `'${p}'::uuid`).join(', ')})
    AND (NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s = '${BILL}')
      OR NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s = '${VOTE}'));
  IF bad > 0 THEN
    RAISE EXCEPTION 'guard 1 failed: % row(s) lack the bill or the roll call', bad;
  END IF;
END
$$;

-- Guard 2: citations only -- nothing created or deleted, measured against the in-transaction snapshot.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM ma_aha_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF ctx_after <> snap.ctx_before THEN
    RAISE EXCEPTION 'guard 2 failed: context rows moved % -> %', snap.ctx_before, ctx_after;
  END IF;
  IF ans_after <> snap.ans_before THEN
    RAISE EXCEPTION 'guard 2 failed: answer rows moved % -> %', snap.ans_before, ans_after;
  END IF;
  IF orphans > 0 THEN
    RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans;
  END IF;
  RAISE NOTICE 'ma-aha ok: context=% (unchanged) answers=% (unchanged) orphans=%', ctx_after, ans_after, orphans;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`rows: ${stmts.length}\nrollback: ${ROLLBACK}`);
