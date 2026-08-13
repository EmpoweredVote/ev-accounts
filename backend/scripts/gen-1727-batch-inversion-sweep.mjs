#!/usr/bin/env node
/**
 * Generate migration 1727 — the WHOLE-POLITICIAN sweep of the migration-1714 bad batch.
 *
 * 🔴 1714 was TOPIC-scoped, so per-politician completeness was never established. Reading every
 * anti-pole row of all 24 politicians it touched finds the intensity-rating defect still live in
 * topics 1714's scan scored UNCALIBRATED (Voting Rights, Reproductive Rights, Immigration, Fossil
 * Fuel) and in topics it never reached at all (Taxation, Public Safety, Economic Development,
 * Police Accountability, Transportation, Rent Regulation, Local Immigration Enforcement...).
 *
 * 🔑 POLARITY IS READ FROM `compass_stances`, NEVER ASSUMED. Four topics here have their PRO end at
 * the HIGH chair and are therefore NOT swept:
 *   · Artificial Intelligence Oversight — chair 1 is "allow AI companies to develop freely",
 *     chair 5 is "strict approval requirements and ban AI systems that could cause serious harm".
 *   · Residential Zoning — chair 4-5 is the upzoning/YIMBY end.
 *   · Growth and Development Pace — chair 4-5 is streamlined permitting.
 *   · Affordable Housing chair 4 — "cut regulations so private developers can build more housing".
 *
 * 🔑 TARGET = THE LEAST EXTREME PRO-SIDE OPTION THE REASONING ACTUALLY SUPPORTS (the 1714 rule).
 *
 * Reads nothing. Writes the migration and its rollback record.
 *   node scripts/gen-1727-batch-inversion-sweep.mjs
 */
import fs from 'node:fs';

const MIG = 'backend/migrations/1727_batch_inversion_whole_politician.sql';
const ROLLBACK = 'backend/data/stance-retirement/2026-08-12-batch-inversion-1727-rollback.json';

const PID = {
  'Alonzo T. Washington': '8c8b0896-dfd0-4d3c-8492-e594d93b78ca',
  'Arthur Ellis': '4754dede-4a3b-4280-a8b1-7497530107f7',
  'Ben Bartlett': 'eaab41f8-71c8-47db-bd0b-62da46b5607b',
  'Benjamin F. Kramer': '7a2d1548-3268-4767-97a8-bb8b142d5a33',
  'Brent Blackaby': '424eb63b-9976-4059-8049-365c09719cc6',
  'C. Anthony Muse': '47823046-7dea-4a4f-a11b-0c5890539891',
  'Cheryl C. Kagan': 'e35d5990-55c7-42e2-94bc-27cb1c49b5f1',
  'Igor Tregub': '9f9a35a9-0226-45f0-9fd8-ef46163f7245',
  'Jeff Waldstreicher': 'da75c207-bb23-477e-b3c0-7c462394b570',
  'Jim Rosapepe': '9c400214-f007-4a8d-92fe-5f5d23b3838e',
  'Joanne C. Benson': '4a7dc8a6-2138-4472-8197-8b878034f029',
  'Kevin M. Harris': '8c6327bf-2eb4-4788-91f7-c5518ab5a3f1',
  'Nick Charles': 'cf190bac-9369-4175-bd4b-8ba776697d9c',
  'Rashi Kesarwani': 'd2013613-769f-4374-809e-a018dbc1e683',
  'Ron Watson': '9aef8bfb-8e0c-4f00-9898-c738abe4970c',
  'Sara Love': 'c5d2cd24-170a-4f87-8fde-84216fe62806',
  'Sean Elo-Rivera': 'dc3d8a98-07ce-4797-bc84-957a72fd854f',
  'Shaneka Henson': '05c9b5b9-cb2b-4387-ab6b-350b69553fac',
  'Terry Taplin': 'bcdb549a-48bf-400f-9d23-c93e2e71007c',
  'Todd Gloria': 'a975b943-f3e0-492a-bd26-9f5993a5c094',
  'Vivian Moreno': '0b16443e-fec4-4f33-abbc-eb1331e3b42d',
  'William C. Smith, Jr.': 'b05ff6cb-1ea9-4904-8ecd-5d9aba5c61fc',
};

const TID = {
  'Abortion': 'af2fdfd6-02c4-49df-b09c-cf8536f4773f',
  'Bail & Pretrial': '1fab5edf-6151-4da0-9704-a7f2113ba54c',
  'Campaign Finance': '92730f69-ae57-401c-8ad1-2d07834a895d',
  'City Sanitation': '7687de4f-4d0b-462a-b803-bdfb23b16b42',
  'Climate Change': 'f1e44d66-5d27-4b51-b54f-b7ace86f6a3c',
  'Criminal Justice': '9db07b16-1076-4b7d-ad89-ebe7b51f4336',
  'Criminalization of Homelessness': '4938766b-b45a-46e3-93bd-b8b30651271a',
  'Deportation': '44905f3b-e105-4f6c-afc7-5d223813dbac',
  'Economic Development': 'eb3d1247-0de1-4b7f-baec-7259861efd53',
  'Environment vs. Development': '1935979c-b290-42e4-baa5-8cb0138b4ffa',
  'Fossil Fuels': 'a22215c3-6693-4bc2-b248-01aebba14570',
  'Affordable Housing': '669cac97-66a6-4087-b036-936fbe62efb3',
  'Homelessness Response': '6fbf39ae-6b19-4182-b4c2-6a8d25c86c0f',
  'Immigration': '4e2c69ce-591e-4197-9cd5-7aceff79d390',
  'Jail Capacity': 'c267e137-0ff9-4e7d-9d13-e3cea1756cd0',
  'Local Immigration Enforcement': 'b9ccee94-ad96-4f10-b655-889d8e5abe92',
  'Medicare / Medicaid': 'cab61e8a-64fe-4bbd-bc08-fe9914d0091b',
  'Police Accountability': '7bad33eb-e93e-4d94-8822-97212d49bde5',
  'Prosecution': 'abb99d95-cbb1-4617-8f8b-f220ef6028ca',
  'Public Safety': 'e9ebefcd-c496-45e8-b816-a79f8442ba85',
  'Redistricting': '48cc9585-ec22-4f53-8d42-6839828dd36f',
  'Rent Regulation': 'c308e8e8-caac-44f5-ab04-dbfecf40bbe2',
  'Same-Sex Marriage': 'c5ab4eab-702f-49b8-9277-8ea53f3835c6',
  'Taxes': 'f7e5678d-dadd-4556-a2fc-446e24642ceb',
  'Trans Athletes': 'd1618b9c-0b9e-45af-b986-bb33d270b8e4',
  'Transportation': 'ba59337e-30e2-4aba-a39a-426b3366eb27',
  'Ukraine Support': '24e9212c-b011-422a-865c-093e35050901',
  'Voting Rights': 'd1792200-1d3b-4955-a0b7-0e6980d7a7b2',
};

// [politician, topic, from, to]
const D = [
  // ── MARYLAND — the 1714 batch, read whole ────────────────────────────────────────────────
  ['Alonzo T. Washington', 'Abortion', 5, 2], ['Alonzo T. Washington', 'Police Accountability', 5, 2],
  ['Alonzo T. Washington', 'Voting Rights', 5, 2], ['Alonzo T. Washington', 'Criminal Justice', 4, 2],
  ['Alonzo T. Washington', 'Economic Development', 4, 3], ['Alonzo T. Washington', 'Environment vs. Development', 4, 3],
  ['Alonzo T. Washington', 'Public Safety', 4, 3], ['Alonzo T. Washington', 'Taxes', 4, 2],

  ['Arthur Ellis', 'Environment vs. Development', 5, 2], ['Arthur Ellis', 'Voting Rights', 5, 2],
  ['Arthur Ellis', 'Economic Development', 4, 3], ['Arthur Ellis', 'Public Safety', 4, 3],
  ['Arthur Ellis', 'Taxes', 4, 2],

  ['Benjamin F. Kramer', 'Abortion', 5, 2], ['Benjamin F. Kramer', 'Medicare / Medicaid', 5, 2],
  ['Benjamin F. Kramer', 'Voting Rights', 5, 2], ['Benjamin F. Kramer', 'Economic Development', 4, 3],
  ['Benjamin F. Kramer', 'Environment vs. Development', 4, 3], ['Benjamin F. Kramer', 'Public Safety', 4, 3],
  ['Benjamin F. Kramer', 'Taxes', 4, 2],

  ['C. Anthony Muse', 'Voting Rights', 5, 2], ['C. Anthony Muse', 'Economic Development', 4, 3],
  ['C. Anthony Muse', 'Public Safety', 4, 3], ['C. Anthony Muse', 'Taxes', 4, 2],

  ['Cheryl C. Kagan', 'Abortion', 5, 2], ['Cheryl C. Kagan', 'Campaign Finance', 5, 2],
  ['Cheryl C. Kagan', 'Climate Change', 5, 3], ['Cheryl C. Kagan', 'Voting Rights', 5, 2],
  ['Cheryl C. Kagan', 'Economic Development', 4, 3], ['Cheryl C. Kagan', 'Immigration', 4, 2],
  ['Cheryl C. Kagan', 'Public Safety', 4, 3], ['Cheryl C. Kagan', 'Taxes', 4, 2],

  ['Jeff Waldstreicher', 'Abortion', 5, 2], ['Jeff Waldstreicher', 'Immigration', 5, 2],
  ['Jeff Waldstreicher', 'Same-Sex Marriage', 5, 1], ['Jeff Waldstreicher', 'Taxes', 5, 2],
  ['Jeff Waldstreicher', 'Trans Athletes', 5, 2], ['Jeff Waldstreicher', 'Voting Rights', 5, 2],
  ['Jeff Waldstreicher', 'Bail & Pretrial', 4, 2], ['Jeff Waldstreicher', 'Campaign Finance', 4, 2],
  ['Jeff Waldstreicher', 'Criminal Justice', 4, 2], ['Jeff Waldstreicher', 'Economic Development', 4, 3],
  ['Jeff Waldstreicher', 'Police Accountability', 4, 2], ['Jeff Waldstreicher', 'Public Safety', 4, 3],

  ['Jim Rosapepe', 'Abortion', 5, 2], ['Jim Rosapepe', 'Ukraine Support', 5, 2],
  ['Jim Rosapepe', 'Voting Rights', 5, 2], ['Jim Rosapepe', 'Public Safety', 4, 3],
  ['Jim Rosapepe', 'Taxes', 4, 2],

  ['Joanne C. Benson', 'Abortion', 5, 2], ['Joanne C. Benson', 'Voting Rights', 5, 2],
  ['Joanne C. Benson', 'Economic Development', 4, 3], ['Joanne C. Benson', 'Police Accountability', 4, 2],
  ['Joanne C. Benson', 'Public Safety', 4, 3], ['Joanne C. Benson', 'Taxes', 4, 2],

  ['Kevin M. Harris', 'Voting Rights', 5, 2], ['Kevin M. Harris', 'Economic Development', 4, 3],
  ['Kevin M. Harris', 'Environment vs. Development', 4, 3], ['Kevin M. Harris', 'Immigration', 4, 2],

  ['Nick Charles', 'Voting Rights', 5, 2], ['Nick Charles', 'Economic Development', 4, 3],
  ['Nick Charles', 'Police Accountability', 4, 2], ['Nick Charles', 'Public Safety', 4, 3],
  ['Nick Charles', 'Taxes', 4, 2],

  ['Ron Watson', 'Voting Rights', 5, 2], ['Ron Watson', 'Economic Development', 4, 3],
  ['Ron Watson', 'Public Safety', 4, 3], ['Ron Watson', 'Taxes', 4, 2],

  ['Sara Love', 'Abortion', 5, 2], ['Sara Love', 'Climate Change', 5, 3],
  ['Sara Love', 'Environment vs. Development', 5, 2], ['Sara Love', 'Medicare / Medicaid', 5, 2],
  ['Sara Love', 'Voting Rights', 5, 2], ['Sara Love', 'Economic Development', 4, 3],
  ['Sara Love', 'Immigration', 4, 2], ['Sara Love', 'Public Safety', 4, 3],
  ['Sara Love', 'Redistricting', 4, 2], ['Sara Love', 'Taxes', 4, 2],
  ['Sara Love', 'Trans Athletes', 4, 2],

  ['Shaneka Henson', 'Environment vs. Development', 5, 2], ['Shaneka Henson', 'Voting Rights', 5, 2],
  ['Shaneka Henson', 'Economic Development', 4, 3], ['Shaneka Henson', 'Police Accountability', 4, 2],
  ['Shaneka Henson', 'Public Safety', 4, 3], ['Shaneka Henson', 'Taxes', 4, 2],

  ['William C. Smith, Jr.', 'Abortion', 5, 2], ['William C. Smith, Jr.', 'Voting Rights', 5, 2],
  ['William C. Smith, Jr.', 'Bail & Pretrial', 4, 2], ['William C. Smith, Jr.', 'Criminal Justice', 4, 2],
  ['William C. Smith, Jr.', 'Economic Development', 4, 3], ['William C. Smith, Jr.', 'Immigration', 4, 2],
  ['William C. Smith, Jr.', 'Police Accountability', 4, 2], ['William C. Smith, Jr.', 'Prosecution', 4, 3],
  ['William C. Smith, Jr.', 'Public Safety', 4, 3], ['William C. Smith, Jr.', 'Redistricting', 4, 2],
  ['William C. Smith, Jr.', 'Taxes', 4, 2], ['William C. Smith, Jr.', 'Trans Athletes', 4, 2],

  // ── CALIFORNIA — richly sourced rows, so the reading is per-row and many are LEFT alone ───
  ['Ben Bartlett', 'Climate Change', 5, 2], ['Ben Bartlett', 'Environment vs. Development', 5, 2],
  ['Ben Bartlett', 'Homelessness Response', 5, 2], ['Ben Bartlett', 'Affordable Housing', 5, 2],
  ['Ben Bartlett', 'Jail Capacity', 5, 2], ['Ben Bartlett', 'Local Immigration Enforcement', 5, 2],
  ['Ben Bartlett', 'Public Safety', 5, 2], ['Ben Bartlett', 'Rent Regulation', 5, 2],
  ['Ben Bartlett', 'Criminalization of Homelessness', 4, 2], ['Ben Bartlett', 'Transportation', 4, 2],

  ['Brent Blackaby', 'Deportation', 5, 2], ['Brent Blackaby', 'Local Immigration Enforcement', 5, 2],
  ['Brent Blackaby', 'Transportation', 5, 2], ['Brent Blackaby', 'Environment vs. Development', 4, 3],
  ['Brent Blackaby', 'Rent Regulation', 4, 2],

  ['Igor Tregub', 'Environment vs. Development', 5, 2], ['Igor Tregub', 'Fossil Fuels', 5, 2],
  ['Igor Tregub', 'Local Immigration Enforcement', 5, 2], ['Igor Tregub', 'Rent Regulation', 5, 2],
  ['Igor Tregub', 'Transportation', 5, 2], ['Igor Tregub', 'Criminalization of Homelessness', 4, 3],
  ['Igor Tregub', 'Homelessness Response', 4, 2], ['Igor Tregub', 'Affordable Housing', 4, 3],
  ['Igor Tregub', 'Public Safety', 4, 3],

  ['Rashi Kesarwani', 'Local Immigration Enforcement', 5, 1], ['Rashi Kesarwani', 'Transportation', 5, 2],
  ['Rashi Kesarwani', 'City Sanitation', 4, 2], ['Rashi Kesarwani', 'Climate Change', 4, 3],
  ['Rashi Kesarwani', 'Rent Regulation', 4, 2],

  ['Sean Elo-Rivera', 'Affordable Housing', 4, 2], ['Sean Elo-Rivera', 'Taxes', 4, 2],

  ['Terry Taplin', 'Climate Change', 5, 3], ['Terry Taplin', 'Homelessness Response', 5, 2],
  ['Terry Taplin', 'Local Immigration Enforcement', 5, 2], ['Terry Taplin', 'Rent Regulation', 5, 2],
  ['Terry Taplin', 'Transportation', 5, 2], ['Terry Taplin', 'Criminalization of Homelessness', 4, 3],
  ['Terry Taplin', 'Public Safety', 4, 2],

  ['Vivian Moreno', 'Affordable Housing', 4, 3],

  ['Todd Gloria', 'Climate Change', 5, 3], ['Todd Gloria', 'Environment vs. Development', 5, 3],
  ['Todd Gloria', 'Trans Athletes', 5, 2], ['Todd Gloria', 'Immigration', 4, 2],
  ['Todd Gloria', 'Medicare / Medicaid', 4, 2], ['Todd Gloria', 'Transportation', 4, 2],
];

// Rows read at a pole and deliberately LEFT — recorded so the refusals are auditable.
const LEFT = [
  ['Jim Rosapepe', 'Economic Development', 5, 'he IS an economic-development champion; the row is not inverted'],
  ['Jim Rosapepe', 'AI Oversight', 4, 'AI Oversight polarity is reversed — chair 4 is the pro-regulation option'],
  ['C. Anthony Muse', 'Religious Freedom', 4, 'an ordained minister who champions faith-based protections — chair 4 is what the row says'],
  ['Sara Love', 'Residential Zoning', 4, 'zoning reform for more density IS the chair-4 upzoning option'],
  ['Ben Bartlett', 'AI Oversight', 5, 'chair 5 is strict AI regulation — correct'],
  ['Ben Bartlett', 'Residential Zoning', 4, 'ADU upzoning + transit village — correct'],
  ['Brent Blackaby', 'Climate Change', 4, 'a wildfire tax credit is adaptation, not a ladder position; no clear inversion'],
  ['Brent Blackaby', 'Affordable Housing', 4, 'voted for a 166-unit dense development — chair 4 is deregulate-to-build'],
  ['Brent Blackaby', 'Residential Zoning', 4, 'upheld a 10-story approval — correct'],
  ['Igor Tregub', 'Residential Zoning', 4, 'voted for the Middle Housing Ordinance — correct'],
  ['Rashi Kesarwani', 'Residential Zoning', 4, 'authored the middle housing ordinance — correct'],
  ['Sean Elo-Rivera', 'AI Oversight', 4, 'banned algorithmic rent-setting — chair 4 is ban high-risk AI uses'],
  ['Sean Elo-Rivera', 'Residential Zoning', 4, 'ADU incentives and pro-density — correct'],
  ['Terry Taplin', 'Residential Zoning', 4, 'Affordable Housing Overlay, +6 stories as-of-right — correct'],
  ['Vivian Moreno', 'Residential Zoning', 4, 'Land Use chair, BOMA award for development support — correct'],
  ['Todd Gloria', 'City Sanitation', 4, 'Clean SD genuinely pairs sanitation staffing WITH enforcement'],
  ['Todd Gloria', 'Growth and Development Pace', 4, 'reducing Land Development Code barriers IS chair 4'],
  ['Todd Gloria', 'Affordable Housing', 4, 'Housing Action Packages are supply-side zoning reform — correct'],
  ['Todd Gloria', 'Rent Regulation', 4, 'the row says he prioritises building over rent control — chair 4 is what he holds'],
  ['Todd Gloria', 'Residential Zoning', 4, 'AB-2372 density bonuses and parking caps — correct'],
];

const rows = D.map(([name, topic, from, to]) => {
  const pid = PID[name], tid = TID[topic];
  if (!pid) throw new Error(`no pid for ${name}`);
  if (!tid) throw new Error(`no tid for ${topic}`);
  return { name, topic, pid, tid, from, to };
});

const dupe = new Set();
for (const r of rows) {
  const k = `${r.pid}|${r.tid}`;
  if (dupe.has(k)) throw new Error(`duplicate target: ${r.name} / ${r.topic}`);
  dupe.add(k);
  if (r.to >= 4) throw new Error(`target is still at the anti pole: ${r.name} / ${r.topic}`);
}

const updates = rows.map((r) =>
  `-- ${r.name} / ${r.topic}: chair ${r.from} -> ${r.to}\n` +
  `UPDATE inform.politician_answers SET value = ${r.to}\n` +
  `WHERE politician_id = '${r.pid}'::uuid AND topic_id = '${r.tid}'::uuid AND value = ${r.from};`
).join('\n\n');

const want = rows.map((r) => `('${r.pid}'::uuid, '${r.tid}'::uuid, ${r.to}::numeric)`).join(',\n    ');

const header = fs.readFileSync('backend/scripts/1727_header.txt', 'utf8');

const sql = `${header}
BEGIN;

CREATE TEMP TABLE bi_snapshot ON COMMIT DROP AS
SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,
       (SELECT count(*) FROM inform.politician_answers) AS ans_before;

${updates}

-- Guard 1: every one of the ${rows.length} targeted rows exists and holds exactly its intended chair.
DO $$
DECLARE bad int; n int;
BEGIN
  SELECT count(*) FILTER (WHERE a.value <> w.want), count(*) INTO bad, n
  FROM (VALUES
    ${want}
  ) AS w(pid, tid, want)
  JOIN inform.politician_answers a ON a.politician_id=w.pid AND a.topic_id=w.tid;
  IF n <> ${rows.length} THEN RAISE EXCEPTION 'guard 1 failed: matched % rows, expected ${rows.length}', n; END IF;
  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) do not hold the intended chair', bad; END IF;
END $$;

-- Guard 2: no reasoning was touched, nothing created or deleted, no orphans.
DO $$
DECLARE ctx_after int; ans_after int; orphans int; snap record;
BEGIN
  SELECT * INTO snap FROM bi_snapshot;
  SELECT count(*) INTO ctx_after FROM inform.politician_context;
  SELECT count(*) INTO ans_after FROM inform.politician_answers;
  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;
  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;
  SELECT count(*) INTO orphans FROM inform.politician_answers a
  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c
                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);
  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;
END $$;

-- Guard 3: the 22 politicians retain exactly the anti-pole rows this pass READ AND KEPT — no more,
-- no fewer. A silent extra 4-5 row would mean the sweep missed something.
DO $$
DECLARE left_at_pole int;
BEGIN
  SELECT count(*) INTO left_at_pole FROM inform.politician_answers a
  WHERE a.value >= 4 AND a.politician_id IN (${[...new Set(rows.map((r) => `'${r.pid}'::uuid`))].join(', ')});
  IF left_at_pole <> ${LEFT.length} THEN
    RAISE EXCEPTION 'guard 3 failed: % anti-pole row(s) remain, expected exactly the ${LEFT.length} read and kept', left_at_pole;
  END IF;
  RAISE NOTICE 'batch inversion sweep ok: ${rows.length} chairs corrected, ${LEFT.length} read and kept';
END $$;

COMMIT;
`;

fs.writeFileSync(MIG, sql);
fs.writeFileSync(ROLLBACK, JSON.stringify({
  pass: 'whole-politician sweep of the migration-1714 bad batch',
  migration: '1727_batch_inversion_whole_politician.sql',
  note: 'Restores pre-1727 chairs. inform.politician_context is NOT touched by 1727.',
  n: rows.length,
  n_read_and_kept: LEFT.length,
  rows: rows.map((r) => ({
    politician_id: r.pid, name: r.name, topic_id: r.tid, topic: r.topic,
    chair_before: r.from, chair_after: r.to,
  })),
  read_and_kept: LEFT.map(([name, topic, chair, why]) => ({ name, topic, chair, why })),
}, null, 1));

const byPol = {};
for (const r of rows) byPol[r.name] = (byPol[r.name] || 0) + 1;
console.log(`${rows.length} corrections across ${Object.keys(byPol).length} politicians; ${LEFT.length} read and kept`);
for (const [n, c] of Object.entries(byPol).sort((a, b) => b[1] - a[1])) console.log(`  ${String(c).padStart(2)}  ${n}`);
console.log(`wrote ${MIG}`);
console.log(`wrote ${ROLLBACK}`);
