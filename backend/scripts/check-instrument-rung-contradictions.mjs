#!/usr/bin/env node
/**
 * Two rows cite ONE instrument, take the SAME side of it, and sit on DIFFERENT rungs of the SAME
 * ladder. At most one of them can be right, and nothing in the corpus ever looked.
 *
 * WHY THIS EXISTS. Sampling the repaired rows on 2026-10-21 (36 of 396, read by hand) found the
 * defect is not really a property of a row — it is a property of a MAPPING. One instrument seats
 * one rung across many members, so a wrong mapping is wrong for every member who cites it, and a
 * right one is right for all of them. 15 (instrument, topic) pairs were seating more than one rung
 * across 167 rows: the Fair Share Amendment at tax rungs 2, 3 AND 4; the ROE Act at abortion rungs
 * 1, 2 and 4. The full measurement is in
 * data/stance-research/2026-10-21-repaired-rest-sample/MEASUREMENT.md.
 *
 * ⚖ WHAT COUNTS AS A CONTRADICTION, AND WHAT DOES NOT.
 *   A split is LEGITIMATE when it separates sides: on the Texas heartbeat act, 8 members who voted
 *   against it sit at abortion rung 2 and 1 who voted for it sits at rung 5. That is the ladder
 *   working. So this check groups by (instrument, topic, DIRECTION) and only reports a group whose
 *   members went the SAME way and still landed on different rungs.
 *   ⚠ SPONSOR is a third direction, never folded into FOR. Sponsoring and voting are different
 *   claims — migration 1690's rule is that a sponsor list cannot settle a floor vote.
 *
 * 🔴🔴 WHAT THIS CANNOT DO, AND IT IS THE BIGGER HALF.
 *   It finds DISAGREEMENT, not ERROR. A mapping that is uniformly wrong produces no disagreement
 *   and this check is blind to it — exactly the shape recorded in `instrument_topic_detector`:
 *   a consensus detector cannot see a large uniform misfile. In the 2026-10-21 sample the
 *   Massachusetts police reform act seats public-safety rung 2 for all 11 members who voted for it,
 *   and that mapping is wrong (the act is officer accountability; the ladder asks about staffing
 *   and who answers non-violent calls). This check reports it as consistent, because it is.
 *   ⚠ So a clean run means "no two rows citing one instrument disagree", never "the mappings are
 *   right". Read it the way check-stance-sources is read.
 *
 * It also only sees rows it can key: a numeric bill needs a legislature host among the citations to
 * scope it, and a descriptive phrase ("rent stabilization", "the jail construction moratorium") is
 * not an instrument name at all. Coverage is printed on every run so the blind spot stays visible.
 *
 *   node scripts/check-instrument-rung-contradictions.mjs            # report
 *   node scripts/check-instrument-rung-contradictions.mjs --json     # machine-readable
 *   node scripts/check-instrument-rung-contradictions.mjs --min 3    # only groups of >= 3 rows
 *   node scripts/check-instrument-rung-contradictions.mjs --sole     # strictest: one-instrument rows only
 *   node scripts/check-instrument-rung-contradictions.mjs --selftest # fixtures, no database
 */
import fs from 'node:fs';
import pg from 'pg';
import { extractInstrumentKeys, directionFor } from './lib/instrument-keys.mjs';

const argv = process.argv.slice(2);
const has = (f) => argv.includes(f);
const opt = (f, d) => { const i = argv.indexOf(f); return i > -1 ? argv[i + 1] : d; };
const MIN = Number(opt('--min', 2));
const SOLE = has('--sole');

/* ── the grouping, pure so the self-test can drive it without a database ─────────────────── */

/**
 * rows: [{ politician_id, topic_id, topic, name, value, reasoning, sources }]
 * -> { groups, coverage }
 */
export function findContradictions(rows, min = 2, sole = false) {
  const buckets = new Map();
  let keyed = 0;
  for (const r of rows) {
    const keys = extractInstrumentKeys(r.reasoning || '', r.sources || []);
    if (keys.length) keyed++;
    // ⚖ `sole` compares only rows whose reasoning rests on ONE instrument. Measured on 8 sampled
    // groups, 3 of the weakest flags were rows that shared an instrument but carried DIFFERENT
    // additional ones — Pressley backing the BREATHE Act as well as the George Floyd Act sits a
    // rung above a colleague who cited only the latter, and BOTH may be right. A rung reflects the
    // SUM of a row's evidence, so two rows are only strictly comparable when the sum is the same.
    if (sole && keys.length !== 1) continue;
    for (const { key, at } of keys) {
      const dir = directionFor(r.reasoning || '', at);
      if (!dir) continue;                       // an ambiguous side cannot create a contradiction
      // 🔑 GROUP BY THE LADDER REVISION, NOT THE TOPIC. A rung NUMBER only means something inside
      // one revision: Season 1 rung 1 on same-sex-marriage IS Season 2 rung 2, because that ladder
      // gained a rung at the top. Comparing bare numbers across revisions invents a disagreement
      // out of a renumbering — the same mistake migration 1903 made on 13 rows.
      const id = `${key}\u0000${r.topic_revision_id}\u0000${dir}`;
      const b = buckets.get(id) || { key, topic: r.topic, dir, rows: [] };
      b.rows.push(r);
      buckets.set(id, b);
    }
  }
  const groups = [];
  for (const b of buckets.values()) {
    const byRung = new Map();
    for (const r of b.rows) {
      const v = Number(r.value);
      byRung.set(v, (byRung.get(v) || []).concat(r));
    }
    if (byRung.size < 2 || b.rows.length < min) continue;
    groups.push({
      instrument: b.key, topic: b.topic, direction: b.dir, n: b.rows.length,
      rungs: [...byRung.entries()].sort((a, c) => a[0] - c[0])
        .map(([rung, rs]) => ({ rung, n: rs.length, names: rs.map((r) => r.name) })),
    });
  }
  groups.sort((a, b) => b.n - a.n || a.instrument.localeCompare(b.instrument));
  return { groups, coverage: { total: rows.length, keyed } };
}

/* ── self-test: fixtures with known answers, no database ─────────────────────────────────── */

function selftest() {
  const TX = ['https://capitol.texas.gov/BillLookup/History.aspx?LegSess=87R&Bill=SB8'];
  const MA = ['https://malegislature.gov/Bills/191/H5179'];
  // One revision per topic, since grouping is keyed on the REVISION: two topics are two ladders.
  const row = (name, topic, value, reasoning, sources) =>
    ({ politician_id: name, topic_id: topic, topic_revision_id: `rev:${topic}`, topic,
       name, value, reasoning, sources });
  const cases = [
    {
      what: 'flags two members who voted the same way and sit on different rungs',
      rows: [
        row('A', 'abortion', 1, 'voted Yea on H.5179, the ROE Act', MA),
        row('B', 'abortion', 2, 'voted Yea on H.5179, the ROE Act', MA),
      ],
      expect: 1,
    },
    {
      what: 'does NOT flag a split that separates yes from no — the ladder working',
      rows: [
        row('A', 'abortion', 2, 'voted against SB 8, the heartbeat act', TX),
        row('B', 'abortion', 5, 'voted for SB 8, the heartbeat act', TX),
      ],
      expect: 0,
    },
    {
      what: 'does NOT fold a sponsor in with a yes-voter — different claims',
      rows: [
        row('A', 'abortion', 1, 'is a cosponsor of H.5179', MA),
        row('B', 'abortion', 2, 'voted Yea on H.5179', MA),
      ],
      expect: 0,
    },
    {
      what: 'does NOT collide one bill number across two legislatures',
      rows: [
        row('A', 'taxes', 2, 'voted for SB 13', ['https://capitol.texas.gov/x']),
        row('B', 'taxes', 4, 'voted for SB 13', ['https://malegislature.gov/x']),
      ],
      expect: 0,
    },
    {
      what: 'does NOT compare across ladders — same bill, two topics is not a contradiction',
      rows: [
        row('A', 'climate-change', 4, 'voted for SB 13', TX),
        row('B', 'fossil-fuels', 5, 'voted for SB 13', TX),
      ],
      expect: 0,
    },
    {
      what: 'is silent when a mapping is uniformly applied — the documented blind spot',
      rows: [
        row('A', 'public-safety-approach', 2, 'voted Yea on S.2963', MA),
        row('B', 'public-safety-approach', 2, 'voted Yea on S.2963', MA),
        row('C', 'public-safety-approach', 2, 'voted Yea on S.2963', MA),
      ],
      expect: 0,
    },
    {
      // A votes FOR HB 100 and AGAINST SB 200 in one row. Only SB 200 is shared with B, and both
      // went AGAINST it, so the one group reported must be SB 200 — never HB 100, whose direction
      // must not have been smeared across the full stop.
      what: 'scores each instrument on its own clause, so only the shared one groups',
      rows: [
        row('A', 'climate-change', 4, 'voted for HB 100. He voted against SB 200.', TX),
        row('B', 'climate-change', 5, 'voted against SB 200.', TX),
      ],
      expect: 1,
      expectInstrument: 'TX:SB0200',
    },
  ];
  let bad = 0;
  for (const c of cases) {
    const { groups } = findContradictions(c.rows, 2);
    let ok = groups.length === c.expect;
    if (ok && c.expectInstrument) ok = groups[0]?.instrument === c.expectInstrument;
    if (!ok) bad++;
    const detail = c.expectInstrument ? `, want ${c.expect} on ${c.expectInstrument}` : `, want ${c.expect}`;
    console.log(`  ${ok ? 'ok  ' : 'FAIL'} ${c.what}  (groups: ${groups.length}`
      + `${groups[0] ? ' on ' + groups[0].instrument : ''}${detail})`);
  }
  console.log(bad ? `\n${bad} self-test case(s) failed` : '\nself-test OK');
  process.exit(bad ? 1 : 0);
}

if (has('--selftest')) selftest();

/* ── live run ────────────────────────────────────────────────────────────────────────────── */

const env = fs.readFileSync(new URL('../.env', import.meta.url), 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// 🔴 ONE ROW PER (PERSON, TOPIC) — THE SERVING ONE. The first live run compared people against
// THEMSELVES: a member with both a Season 1 and a Season 2 answer appeared twice, and because the
// same-sex-marriage ladder gained a rung at the top between seasons, the identical reasoning sat at
// rung 1 in S1 and rung 2 in S2. That alone manufactured a 195-row "contradiction" in which Angie
// Craig disagreed with Angie Craig. A season remap is not two people disagreeing.
const SEASON_2 = '86d893a1-c1a2-4bbf-b4e5-69ec43221194';
const { rows } = await pool.query(`
  WITH serving AS (
    SELECT DISTINCT ON (pa.politician_id, pa.topic_id)
           pa.politician_id, pa.topic_id, pa.season_id, pa.value, pa.topic_revision_id
      FROM inform.politician_answers pa
     ORDER BY pa.politician_id, pa.topic_id, (pa.season_id = $1::uuid) DESC
  )
  SELECT s.politician_id, s.topic_id, s.topic_revision_id, pc.reasoning, pc.sources,
         -- 🔴 THE KEY ONLY, NEVER THE FROZEN LABEL. The topic table also carries a frozen display
         -- label, and reading it is exactly what check-ladder-text-reads exists to stop: it is the
         -- wording as it WAS, not as the ladder now reads. A topic with no key falls back to its
         -- id, which is stable, rather than to that label.
         s.value, p.full_name AS name, COALESCE(t.topic_key, s.topic_id::text) AS topic
    FROM serving s
    JOIN inform.politician_context pc
      ON pc.politician_id = s.politician_id AND pc.topic_id = s.topic_id
     AND pc.season_id = s.season_id
    JOIN essentials.politicians p ON p.id = s.politician_id
    LEFT JOIN inform.compass_topics t ON t.id = s.topic_id
   WHERE s.value <> 0 AND p.is_active AND pc.reasoning IS NOT NULL`, [SEASON_2]);
await pool.end();

const { groups, coverage } = findContradictions(rows, MIN, SOLE);

if (has('--json')) {
  console.log(JSON.stringify({ coverage, groups }, null, 1));
  process.exit(0);
}

const affected = groups.reduce((a, g) => a + g.n, 0);
console.log(`instrument/rung contradictions — ${groups.length} group(s) covering ${affected} row(s)\n`);
console.log(`  voter-facing rows examined        ${String(coverage.total).padStart(6)}`);
console.log(`  rows yielding a comparable key    ${String(coverage.keyed).padStart(6)}`
  + `   (${(100 * coverage.keyed / coverage.total).toFixed(0)}% — the rest are not compared)`);
console.log(`  minimum group size reported       ${String(MIN).padStart(6)}\n`);

for (const g of groups) {
  const spread = g.rungs.map((r) => `rung ${r.rung}: ${r.n}`).join('  |  ');
  console.log(`${String(g.n).padStart(4)} rows  ${g.instrument}  /  ${g.topic}  /  ${g.direction}`);
  console.log(`           ${spread}`);
  for (const r of g.rungs) {
    const shown = r.names.slice(0, 4).join(', ');
    console.log(`             rung ${r.rung}: ${shown}${r.names.length > 4 ? ` … +${r.names.length - 4}` : ''}`);
  }
}
if (!groups.length) {
  console.log('OK — no two rows citing one instrument, on one ladder, from the same side, disagree.');
  console.log('⚠ That is NOT "the mappings are right": a uniformly wrong mapping produces no');
  console.log('  disagreement and is invisible here. See the header.');
}
process.exit(0);
