#!/usr/bin/env node
/**
 * Correct the chair on rows where it sits at the OPPOSITE pole from the row's own reasoning, and
 * re-source them where the Maryland sponsor index can carry the claim.
 *
 * 🔑 THE ROWS ARE HAND-CONFIRMED, NOT DETECTOR-SELECTED. The scan produced 194 candidates; every one
 * was read. Genuine conservatives sitting correctly at the anti pole were removed — Harold Rogers
 * ("voted YES on ending racial preferences", 28% NAACP), seven real same-sex-marriage opponents,
 * Shannon Grove, Will Ainsworth, Leslie Rutledge, Andy Harris. Two whole topics were dropped because
 * "support" attaches to opposite objects in them: School Vouchers ("supporter of public education
 * and opponent of voucher programs" IS chair 1) and AI Oversight ("promoting voluntary NIST
 * standards" IS chair 2).
 *
 * 🔑 THE TARGET CHAIR IS THE LEAST EXTREME PRO-SIDE OPTION THE REASONING ACTUALLY SUPPORTS. Generic
 * "supports civil rights legislation … racial equity … anti-discrimination" becomes chair 2
 * ("strengthen civil rights enforcement and address systemic discrimination"), NOT chair 1, which
 * demands reparations the row never claims. The mapping is stated per topic below so it is
 * reviewable, and a row whose wording is clearly stronger gets an explicit override.
 *
 * ⚠ A MECHANICAL 5→1 FLIP WOULD BE WRONG. The same batch got other topics right — Sara Love and Ron
 * Watson both sit correctly at chair 2 on Fossil Fuel Policy and School Vouchers, because there the
 * reasoning is phrased as opposition and a low number was picked. The batch is inconsistent.
 *
 *   node scripts/gen-chair-inversion-fix.mjs --out <migration.sql> --rollback <rollback.json>
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out'), ROLLBACK = flag('--rollback');
if (!OUT || !ROLLBACK) { console.error('need --out --rollback'); process.exit(2); }

const SCAN = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-chair-inversion-scan.json', 'utf8'));
const IDX = JSON.parse(fs.readFileSync('data/stance-retirement/2026-08-12-md-cr-sponsor-index.json', 'utf8'));
const slugOf = {}; for (const b of IDX.bills) slugOf[b.session + b.number] = b.slug;

// ── the mapping, stated so it can be argued with ────────────────────────────────────────────────
const TARGET = {
  // topic                                        default  why
  'Civil Rights and Social Justice':                  2, // "strengthen enforcement / address systemic discrimination" — 1 demands reparations
  'Same-Sex Marriage':                                1, // "require all states to recognize" — 2 adds an opt-out the rows never mention
  'Childcare Affordability & Access':                 2, // "significantly expanding subsidies and provider grants" — 1 is universal public childcare
  'Healthcare Access':                                2, // "affordable coverage through a mix of public programs and regulated private insurance"
  'Climate Change and Environmental Protection':      3, // "invest in clean energy while gradually reducing fossil fuels" — 2 demands phase-out by 2030
  'Affordable Housing':                               3, // "targeted help — subsidies, first-time buyer assistance, easier building"
  'Rent Regulation':                                  2, // "strengthen existing rent stabilization and extend coverage"
  'Ukraine - Russia Conflict':                        2, // "continue current levels" — 1 is "until complete victory"
  'Misinformation and the Role of Algorithms in Democracy': 2, // "mandate fact-checking and transparency"
};
// Rows whose wording is clearly stronger than the topic default.
const OVERRIDE = {
  'Igor Tregub|Climate Change and Environmental Protection': 2,      // chaired the Sierra Club SF Bay Chapter
  'Sean Elo-Rivera|Climate Change and Environmental Protection': 2,  // 100% renewable by 2030 Climate Action Plan
  'Jeff Waldstreicher|Climate Change and Environmental Protection': 2, // "consistently votes for aggressive climate action"
  'William C. Smith, Jr.|Climate Change and Environmental Protection': 2, // "supports aggressive climate action"
  'Rashi Kesarwani|Affordable Housing': 2,                           // secured a $4.9M encampment-resolution grant, builds at all income levels
  'Terry Taplin|Affordable Housing': 2,                              // "housing as a human right", Affordable Housing Overlay
  'Alonzo T. Washington|Affordable Housing': 2,                      // backed affordable housing funding + tenant protections
  'Jeff Waldstreicher|Affordable Housing': 2,                        // "leading advocate", sponsored housing legislation
  'Todd Gloria|Healthcare Access': 2,                                // authored AB-2119 and other access bills
  'William C. Smith, Jr.|Healthcare Access': 2,                      // "supports universal healthcare access"
};
// ⚠ Maryland rows whose reasoning names tenant protections belong at 2, not the housing default of 3.
const HOUSING_TENANT = /tenant protection|anti-displacement/i;

// ── hand-confirmed inversions, by "name|topic" ──────────────────────────────────────────────────
const CONFIRMED = new Set([
  // Civil Rights (19 of 20 read; Harold Rogers excluded as correctly anti)
  ...['Todd Gloria', 'Joanne C. Benson', 'Nick Charles', 'Arthur Ellis', 'Kevin M. Harris', 'Shaneka Henson',
    'William C. Smith, Jr.', 'Cheryl C. Kagan', 'Benjamin F. Kramer', 'Sara Love', 'Jim Rosapepe',
    'Jeff Waldstreicher', 'Alonzo T. Washington', 'Ron Watson', 'Terry Taplin', 'Ben Bartlett',
    'C. Anthony Muse', 'Rashi Kesarwani', 'Brent Blackaby'].map((n) => `${n}|Civil Rights and Social Justice`),
  // Same-Sex Marriage (8 of 15; Steube, Kelly, Miller, Fischbach, Graves, Griffin, Reeves are genuine opponents)
  ...['Todd Gloria', 'Arthur Ellis', 'Kevin M. Harris', 'William C. Smith, Jr.', 'Cheryl C. Kagan',
    'Benjamin F. Kramer', 'Sara Love', 'Ron Watson'].map((n) => `${n}|Same-Sex Marriage`),
  // Childcare (all 13)
  ...['Joanne C. Benson', 'Nick Charles', 'Kevin M. Harris', 'Shaneka Henson', 'William C. Smith, Jr.',
    'Cheryl C. Kagan', 'Sara Love', 'Jeff Waldstreicher', 'Alonzo T. Washington', 'Ron Watson',
    'Arthur Ellis', 'C. Anthony Muse', 'Jim Rosapepe'].map((n) => `${n}|Childcare Affordability & Access`),
  // Climate (15 of 23; Grove, Ainsworth, Hunsaker, Braun, Foster, Craddick correct; Whitburn & Jacob too vague)
  ...['Benjamin F. Kramer', 'Igor Tregub', 'Jeff Waldstreicher', 'Sean Elo-Rivera', 'Shaneka Henson',
    'Vivian Moreno', 'William C. Smith, Jr.', 'Alonzo T. Washington', 'Arthur Ellis', 'C. Anthony Muse',
    'Jim Rosapepe', 'Joanne C. Benson', 'Kevin M. Harris', 'Nick Charles', 'Ron Watson']
    .map((n) => `${n}|Climate Change and Environmental Protection`),
  // Healthcare (13 of 22; Rutledge, Kohlhaas, Pan, Cowan, Conforti, Wittrock, Vaz correct; Szeliga & Johnson vague)
  ...['Alonzo T. Washington', 'Arthur Ellis', 'C. Anthony Muse', 'Cheryl C. Kagan', 'Joanne C. Benson',
    'Kevin M. Harris', 'Nick Charles', 'Ron Watson', 'Sara Love', 'Shaneka Henson',
    'William C. Smith, Jr.', 'Jim Rosapepe', 'Todd Gloria'].map((n) => `${n}|Healthcare Access`),
  // Affordable Housing (16 of 22; Jones, Czaplewski, Long, Ishii correct; Cloutier & O'Keefe too vague)
  ...['Alonzo T. Washington', 'Jeff Waldstreicher', 'Rashi Kesarwani', 'Terry Taplin', 'Arthur Ellis',
    'Benjamin F. Kramer', 'C. Anthony Muse', 'Cheryl C. Kagan', 'Jim Rosapepe', 'Joanne C. Benson',
    'Kevin M. Harris', 'Nick Charles', 'Ron Watson', 'Sara Love', 'Shaneka Henson',
    'William C. Smith, Jr.'].map((n) => `${n}|Affordable Housing`),
  // Ukraine (2 of 3; Andy Harris voted Nay and is correct at 4)
  'Mark Warner|Ukraine - Russia Conflict', 'Tim Kaine|Ukraine - Russia Conflict',
  // Rent Regulation (2 of 2)
  'Sara Love|Rent Regulation', 'Jeff Waldstreicher|Rent Regulation',
  // Misinformation (1 of 4)
  'Cheryl C. Kagan|Misinformation and the Role of Algorithms in Democracy',
]);

// ── re-sourcing, only where the MD sponsor index can carry the claim ────────────────────────────
const RESOURCE_TOPICS = {
  'Civil Rights and Social Justice': [/hate crime|hate-bias|antihate|antidiscrimination/i,
    /human relations|civil right|fair housing|public accommodation/i,
    /discrimination in (employment|housing)|employment discrimination|housing discrimination/i,
    /reparation|lynching|definition of race/i],
  'Same-Sex Marriage': [/LGBTQ|sexual orientation|gender identity|conversion therapy|same-?sex/i],
};
const bySurname = {};
for (const tok of Object.keys(IDX.index)) {
  const sn = tok.split(' ').pop();
  (bySurname[sn] ||= []).push(tok);
}
const norm = (s) => s.toLowerCase().replace(/\./g, '').replace(/\s+/g, ' ').trim();
function mdBills(fullName, topic) {
  const tiers = RESOURCE_TOPICS[topic];
  if (!tiers) return [];
  const bare = fullName.replace(/,?\s+(Jr\.|Sr\.|II|III|IV)$/i, '').trim();
  const sn = norm(bare.split(/\s+/).pop());
  const initial = norm(bare.split(/\s+/)[0])[0];
  const toks = bySurname[sn] || [];
  if (!toks.length) return [];
  const initialled = toks.filter((t) => t !== sn);
  const distinct = new Set(initialled.map((t) => t.split(' ')[0][0]));
  let use = toks;
  if (initialled.length && distinct.size > 1) {
    use = initialled.filter((t) => t.split(' ')[0][0] === initial);
    if (!use.length) return [];                      // ambiguous surname — credit nobody
  } else if (initialled.length && distinct.size === 1 && [...distinct][0] !== initial && toks.includes(sn)) {
    return [];
  }
  const all = use.flatMap((t) => IDX.index[t]);
  const scored = all.map((b) => ({ ...b, s: tiers.findIndex((re) => re.test(b.title)) }))
    .filter((b) => b.s > -1)
    .sort((a, b) => a.s - b.s || b.session.localeCompare(a.session));
  return [...new Map(scored.map((b) => [b.session + b.number, b])).values()].slice(0, 3);
}

// ── build ───────────────────────────────────────────────────────────────────────────────────────
const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

const work = [], rollback = [];
const unseen = new Set(CONFIRMED);
for (const f of SCAN.flags) {
  const key = `${f.full_name}|${f.topic}`;
  if (!CONFIRMED.has(key)) continue;
  unseen.delete(key);
  let target = OVERRIDE[key] ?? TARGET[f.topic];
  if (f.topic === 'Affordable Housing' && HOUSING_TENANT.test(f.reasoning)) target = 2;
  if (target == null) throw new Error(`no target chair for ${key}`);
  if (target === Number(f.value)) throw new Error(`${key}: target equals stored chair ${target}`);

  const { rows: got } = await pool.query(
    `SELECT c.reasoning, c.sources, a.value, p.full_name, t.title FROM inform.politician_context c
     JOIN essentials.politicians p ON p.id=c.politician_id
     LEFT JOIN inform.compass_topics t ON t.id=c.topic_id
     LEFT JOIN inform.politician_answers a ON a.politician_id=c.politician_id AND a.topic_id=c.topic_id
     WHERE c.politician_id=$1::uuid AND c.topic_id=$2::uuid`, [f.politician_id, f.topic_id]);
  if (got.length !== 1) throw new Error(`expected 1 row for ${key}, got ${got.length}`);
  const r = got[0];
  if (r.full_name !== f.full_name || r.title !== f.topic) throw new Error(`identity mismatch for ${key}`);
  if (Number(r.value) !== Number(f.value)) throw new Error(`${key}: chair moved since the scan (${r.value} vs ${f.value})`);

  const bills = mdBills(f.full_name, f.topic);
  const sources = bills.length
    ? bills.map((b) => `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${slugOf[b.session + b.number]}?ys=${b.session}`)
    : null;
  const why = bills.length
    ? `${f.reasoning.replace(/\s+$/, '')} Co-sponsored in the Maryland General Assembly: ${bills.map((b) => `${b.number} (${b.session.slice(0, 4)}) "${b.title}"`).join('; ')}.`
    : null;
  work.push({ ...f, from: Number(f.value), to: target, sources, why, n_bills: bills.length });
  rollback.push({ politician_id: f.politician_id, topic_id: f.topic_id, name: f.full_name, topic: f.topic,
    old_value: r.value, old_reasoning: r.reasoning, old_sources: r.sources, new_value: target });
}
await pool.end();
if (unseen.size) throw new Error(`confirmed rows not found in the scan: ${[...unseen].join(' ; ')}`);
fs.writeFileSync(ROLLBACK, JSON.stringify({ pass: 'chair inversion fix', rows: rollback }, null, 1));

const byTopic = {};
for (const w of work) (byTopic[w.topic] ||= []).push(w);
console.log(`${work.length} row(s); re-sourced ${work.filter((w) => w.sources).length}`);
for (const [t, g] of Object.entries(byTopic)) console.log(`  ${String(g.length).padStart(3)}  ${t}  → chair ${[...new Set(g.map((x) => x.to))].join('/')}`);

const q = (s) => `'${String(s).replace(/'/g, "''")}'`;
const arr = (a) => `ARRAY[${a.map(q).join(',')}]::text[]`;
const L = [];
L.push(`-- ${OUT.split(/[\\/]/).pop()}`);
L.push(`-- CHAIR CORRECTION — rows whose stored chair is the OPPOSITE POLE from their own reasoning.`);
L.push(`--`);
L.push(`-- 🔴 A wrong chair is a wrong VOTER-FACING POSITION: the compass dot and the "Why this position?"`);
L.push(`-- text currently say opposite things about the same person. Alonzo Washington sits at chair 5,`);
L.push(`-- "eliminate affirmative action and all race-based government programs", on a row reading "As an`);
L.push(`-- African American senator in PG County, he prioritizes racial justice". Todd Gloria, the first`);
L.push(`-- openly gay mayor of San Diego, sits at chair 5 on Same-Sex Marriage — "make same-sex marriage`);
L.push(`-- illegal". Mark Warner and Tim Kaine sit at "end all aid to Ukraine immediately".`);
L.push(`--`);
L.push(`-- 🔑 ONE BAD BATCH, NOT SCATTERED NOISE. 15 politicians hold 79 inverted rows and for 14 of them`);
L.push(`-- 100% of their pro-worded rows sit at the anti pole; 14 are Maryland. Best reading: a research`);
L.push(`-- run wrote the chair as an INTENSITY rating — 5 meaning "strongly holds this view" — instead of`);
L.push(`-- selecting one of five discrete policy options.`);
L.push(`--`);
L.push(`-- ⚠ A MECHANICAL 5→1 FLIP WOULD BE WRONG, which is why each row was read. The same batch got`);
L.push(`-- other topics right: Sara Love and Ron Watson both sit correctly at chair 2 on Fossil Fuel Policy`);
L.push(`-- and School Vouchers, because there the reasoning is phrased as opposition and a low number was`);
L.push(`-- picked. The batch is inconsistent.`);
L.push(`--`);
L.push(`-- 🔑 TARGET = THE LEAST EXTREME PRO-SIDE OPTION THE REASONING ACTUALLY SUPPORTS:`);
for (const [t, v] of Object.entries(TARGET)) L.push(`--     ${t} → ${v}`);
L.push(`-- Rows with clearly stronger wording are overridden individually (Sierra Club chapter chair,`);
L.push(`-- "aggressive climate action", "universal healthcare access", "housing as a human right").`);
L.push(`--`);
L.push(`-- ⚠ HAND-CONFIRMED, NOT DETECTOR-SELECTED. The scan produced 194 candidates and every one was`);
L.push(`-- read. Genuine conservatives correctly at the anti pole were removed: Harold Rogers ("voted YES`);
L.push(`-- on ending racial preferences", 28% NAACP), seven real same-sex-marriage opponents, Shannon`);
L.push(`-- Grove, Will Ainsworth, Leslie Rutledge, Andy Harris. Two topics were dropped whole because`);
L.push(`-- "support" attaches to opposite objects in them — School Vouchers ("supporter of public`);
L.push(`-- education and opponent of voucher programs" IS chair 1) and AI Oversight.`);
L.push(`--`);
L.push(`-- ⚠ SOURCING: ${work.filter((w) => w.sources).length} rows are additionally re-sourced to bills the member co-sponsored,`);
L.push(`-- from the 882-bill Maryland index. The rest keep their existing citations — the chair is fixed`);
L.push(`-- but the sourcing is still owed, and that is recorded rather than glossed.`);
L.push(`--`);
L.push(`-- Rollback: ${ROLLBACK}`);
L.push(`BEGIN;`);
L.push(``);
L.push(`CREATE TEMP TABLE chairfix_snapshot ON COMMIT DROP AS`);
L.push(`SELECT (SELECT count(*) FROM inform.politician_context) AS ctx_before,`);
L.push(`       (SELECT count(*) FROM inform.politician_answers) AS ans_before;`);
L.push(``);
for (const w of work) {
  L.push(`-- ${w.full_name} / ${w.topic}: chair ${w.from} -> ${w.to}${w.sources ? `  (+${w.n_bills} bill citation${w.n_bills > 1 ? 's' : ''})` : ''}`);
  L.push(`UPDATE inform.politician_answers SET value = ${w.to}`);
  L.push(`WHERE politician_id = ${q(w.politician_id)}::uuid AND topic_id = ${q(w.topic_id)}::uuid AND value = ${w.from};`);
  if (w.sources) {
    L.push(`UPDATE inform.politician_context SET sources = ${arr(w.sources)}, reasoning = ${q(w.why)}`);
    L.push(`WHERE politician_id = ${q(w.politician_id)}::uuid AND topic_id = ${q(w.topic_id)}::uuid;`);
  }
  L.push(``);
}
const pairs = work.map((w) => `(${q(w.politician_id)}::uuid, ${q(w.topic_id)}::uuid, ${w.to}::numeric)`).join(', ');
L.push(`-- Guard 1: every targeted row now holds exactly its intended chair.`);
L.push(`DO $$`);
L.push(`DECLARE bad int;`);
L.push(`BEGIN`);
L.push(`  SELECT count(*) INTO bad FROM (VALUES ${pairs}) AS w(pid, tid, want)`);
L.push(`  JOIN inform.politician_answers a ON a.politician_id=w.pid AND a.topic_id=w.tid`);
L.push(`  WHERE a.value <> w.want;`);
L.push(`  IF bad > 0 THEN RAISE EXCEPTION 'guard 1 failed: % row(s) do not hold the intended chair', bad; END IF;`);
L.push(`END $$;`);
L.push(``);
L.push(`-- Guard 2: exactly ${work.length} rows touched, nothing created or deleted, no orphans.`);
L.push(`DO $$`);
L.push(`DECLARE n int; ctx_after int; ans_after int; orphans int; snap record;`);
L.push(`BEGIN`);
L.push(`  SELECT * INTO snap FROM chairfix_snapshot;`);
L.push(`  SELECT count(*) INTO n FROM (VALUES ${pairs}) AS w(pid, tid, want)`);
L.push(`  JOIN inform.politician_answers a ON a.politician_id=w.pid AND a.topic_id=w.tid;`);
L.push(`  IF n <> ${work.length} THEN RAISE EXCEPTION 'guard 2 failed: matched % rows, expected ${work.length}', n; END IF;`);
L.push(`  SELECT count(*) INTO ctx_after FROM inform.politician_context;`);
L.push(`  SELECT count(*) INTO ans_after FROM inform.politician_answers;`);
L.push(`  IF ctx_after <> snap.ctx_before THEN RAISE EXCEPTION 'guard 2 failed: context moved % -> %', snap.ctx_before, ctx_after; END IF;`);
L.push(`  IF ans_after <> snap.ans_before THEN RAISE EXCEPTION 'guard 2 failed: answers moved % -> %', snap.ans_before, ans_after; END IF;`);
L.push(`  SELECT count(*) INTO orphans FROM inform.politician_answers a`);
L.push(`  WHERE NOT EXISTS (SELECT 1 FROM inform.politician_context c`);
L.push(`                    WHERE c.politician_id=a.politician_id AND c.topic_id=a.topic_id);`);
L.push(`  IF orphans > 0 THEN RAISE EXCEPTION 'guard 2 failed: % orphan answer(s)', orphans; END IF;`);
L.push(`  RAISE NOTICE 'chair fix ok: % rows, context=% answers=% orphans=%', n, ctx_after, ans_after, orphans;`);
L.push(`END $$;`);
L.push(``);
L.push(`COMMIT;`);
fs.writeFileSync(OUT, L.join('\n') + '\n');
console.log(`wrote ${OUT}\nwrote ${ROLLBACK}`);
