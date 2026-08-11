#!/usr/bin/env node
/**
 * Generate the migration re-sourcing the roll-call-verified Maryland rows.
 *
 * These are the NO_SPONSOR_LINK rows: their claim is "supported"/"backed"/"voted", which a SPONSOR LIST
 * CANNOT SETTLE. Maryland publishes every floor vote as a PDF, so each row now carries the bill page AND
 * the specific vote sheet on which the member's own name appears -- primary evidence of the vote itself.
 *
 * Included:
 *  - CONSISTENT rows: the polarity the claim attaches to the instrument matches the recorded vote.
 *  - 2 DIRECTION_UNCLEAR rows read by hand (Augustine, Beidle): both say "opposes vouchers" AND "supports
 *    the Blueprint", voted YEA on the Blueprint -- consistent; the detector could not separate the two
 *    objects in one sentence.
 *  - 2 Valderrama rows the roll-call pass had VOIDED because a bare "HB0444" resolved to 2018 "Estates and
 *    Trusts". 2026 HB0444 really is "Public Safety - Immigration Enforcement Agreements - Prohibition" and
 *    she IS a sponsor, so they are cited to that bill (sponsorship, not a vote).
 *
 * Excluded: Crosby (a genuine contradiction -- claim says he supported the Climate Solutions Now Act, he
 * voted NAY) and everything unresolved.
 */
import fs from 'node:fs';
import pg from 'pg';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const IN = flag('--in'), NUM = flag('--num'), SQL_OUT = flag('--sql'), ROLLBACK = flag('--rollback');
if (!IN || !NUM || !SQL_OUT || !ROLLBACK) { console.error('need --in --num --sql --rollback'); process.exit(2); }

const dir = JSON.parse(fs.readFileSync(IN, 'utf8'));
const HAND_READ_CONSISTENT = new Set(['Malcolm Augustine|School Vouchers & Public Education Funding',
                                     'Pamela Beidle|School Vouchers & Public Education Funding']);
const take = dir.rows.filter((r) => r.verdict === 'CONSISTENT' || HAND_READ_CONSISTENT.has(`${r.politician}|${r.topic}`));

const billUrl = (bill) => {
  const [session, number] = bill.split(/\s+/);
  return `https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/${number.toLowerCase()}?ys=${session}`;
};

const plan = take.map((r) => ({
  politician: r.politician, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
  add: [billUrl(r.bill), r.vote_pdf],
  note: `${r.vote} on ${r.bill} (${r.bill_title ?? ''}) — ${r.action ?? ''}`,
}));

// Valderrama: sponsorship of the correct 2026 bill, verified this session.
const VALDERRAMA = '768ac1cf-a599-4ddb-943c-c985fafb2607';
for (const t of ['Deportation Priorities', 'Immigration and Treatment of Immigrants']) {
  plan.push({
    politician: 'Kriselda Valderrama', politician_id: VALDERRAMA, topic: t, topic_id: null,
    add: ['https://mgaleg.maryland.gov/mgawebsite/Legislation/Details/hb0444?ys=2026RS'],
    note: 'sponsor of 2026 HB0444 "Public Safety - Immigration Enforcement Agreements - Prohibition" (the bare number had resolved to 2018 "Estates and Trusts")',
  });
}

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// Resolve topic_ids by title for the hand-added rows, and pull live sources for everything.
const { rows: live } = await pool.query(`
  SELECT c.politician_id, c.topic_id, p.full_name, t.title AS topic, c.sources
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  WHERE c.politician_id = ANY($1::uuid[])`, [[...new Set(plan.map((p) => p.politician_id))]]);
await pool.end();

const liveBy = new Map(live.map((r) => [`${r.politician_id}|${r.topic}`, r]));
const esc = (s) => s.replace(/'/g, "''");
const stmts = [];
const missing = [];
for (const p of plan) {
  const r = liveBy.get(`${p.politician_id}|${p.topic}`);
  if (!r) { missing.push(`${p.politician} / ${p.topic}`); continue; }
  const cur = r.sources || [];
  const adds = p.add.filter(Boolean).filter((u) => !cur.includes(u));
  if (!adds.length) continue;
  const next = [...adds, ...cur];
  stmts.push(
    `UPDATE inform.politician_context SET sources = ARRAY[${next.map((s) => `'${esc(s)}'`).join(',')}]::text[]\n` +
    `WHERE politician_id = '${r.politician_id}'::uuid AND topic_id = '${r.topic_id}'::uuid\n` +
    `;  -- ${esc(p.politician)} / ${esc(p.topic)} — ${esc(p.note.slice(0, 110))}`
  );
}
if (missing.length) { console.error('ABORT, rows not found:\n  ' + missing.join('\n  ')); process.exit(1); }

fs.writeFileSync(ROLLBACK, JSON.stringify({
  migration: `${NUM}_resource_md_rollcall_verified`,
  generated: 'pre-change snapshot from live DB',
  rule: 'Rows whose claim is a VOTE, not a sponsorship. Each now cites the bill page and the specific floor-vote PDF on which the member\'s own name appears, with the claim\'s polarity matching the recorded vote.',
  plan, row_count: live.length, rows: live,
}, null, 2));

const sql = `-- ${NUM}_resource_md_rollcall_verified.sql
--
-- Maryland pass 5: ROLL-CALL evidence for rows a sponsor list could never settle.
--
-- These rows claim the member "supported" / "backed" / "voted for" something. Mig 1685 deliberately left
-- them alone because they are not sponsorship claims. Maryland publishes each floor vote as a PDF, so each
-- row below now cites the bill page AND the vote sheet carrying the member's own name.
--
-- METHOD, and the guards that make it trustworthy:
--   * TENURE FIRST. A member who was not serving is simply absent from the sheet, so absence would read as
--     "did not support" when it means "was not there". Only in-tenure bills were read.
--   * PASSAGE VOTES ONLY. Most recorded votes are floor amendments; a Nay on a hostile amendment is not
--     opposition to the bill. Only "Third Reading(s) Passed", "Concurs" and "Overridden" were read.
--   * CHAMBER RESOLVED PER SESSION. Surnames collide across chambers (Alonzo Washington in the House and
--     Mary Washington in the Senate, same session), so the member's chamber for that year is derived from
--     their service history and a bare surname is never matched across chambers.
--   * THE PDF's OWN TALLIES ARE THE PARSE CHECK. Each sheet declares "95 Yeas 42 Nays 4 Absent"; a parse
--     that does not reproduce every count exactly is discarded, not guessed at.
--   * IDENTITY. A bare surname counts only when no disambiguated form ("Jones, D." / "Jones, R.") of that
--     surname appears in the same vote; otherwise the member's initial must select exactly one.
--   * DIRECTION. The polarity is read from the clause GOVERNING the instrument and must agree with the
--     recorded vote.
--
-- SCOPE: ${stmts.length} rows. Citations only -- NO stance value modified.
--
-- NOT INCLUDED:
--   Brian M. Crosby / Climate Change -- a GENUINE CONTRADICTION: the stance says he "has supported the
--     Climate Solutions Now Act" and he voted NAY on 2022RS SB0528 (Third Reading Passed). Held for an
--     operator decision; this needs a reasoning correction or retirement, not a citation.
--   32 rows where no passage vote exists to read (the named bill died in committee -- SB0644/SB1000/
--     SB0915 have ZERO recorded votes), plus 1 ABSENT and 1 NOT_VOTING.
--   2 rows for the Speaker (Adrienne A. Jones): the presiding officer is listed as "Speaker", not by name,
--     so her own vote is not attributable by surname. UNKNOWN, never guessed.
--   29 PRE-TENURE rows: the named instrument predates the member's service entirely.
--
-- Rollback: backend/data/stance-retirement/2026-08-11-md-rollcall-${NUM}-rollback.json
--
BEGIN
;

${stmts.join('\n\n')}

DO $$
DECLARE bad int;
BEGIN
  -- every touched row must now cite a Legislation/Details page
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ${[...new Set(stmts.map((s) => s.match(/politician_id = '([^']+)'::uuid AND topic_id = '([^']+)'::uuid/)).filter(Boolean).map((m) => `('${m[1]}'::uuid,'${m[2]}'::uuid)`))].join(',\n    ')}
  ) AND NOT EXISTS (SELECT 1 FROM unnest(c.sources) s WHERE s LIKE '%Legislation/Details/%');
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) lack a bill citation', bad; END IF;

  -- no duplicates introduced, nobody emptied
  SELECT count(*) INTO bad FROM inform.politician_context c
  WHERE (c.politician_id, c.topic_id) IN (
    ${[...new Set(stmts.map((s) => s.match(/politician_id = '([^']+)'::uuid AND topic_id = '([^']+)'::uuid/)).filter(Boolean).map((m) => `('${m[1]}'::uuid,'${m[2]}'::uuid)`))].join(',\n    ')}
  ) AND (c.sources IS NULL OR cardinality(c.sources) = 0
         OR cardinality(c.sources) <> (SELECT count(DISTINCT s) FROM unnest(c.sources) s));
  IF bad > 0 THEN RAISE EXCEPTION 'guard failed: % row(s) empty or duplicated', bad; END IF;
END
$$;

COMMIT
;
`;
fs.writeFileSync(SQL_OUT, sql);
console.log(`rows: ${stmts.length}`);
console.log(`politicians: ${new Set(plan.map((p) => p.politician)).size}`);
console.log(`vote-pdf citations: ${plan.filter((p) => p.add.length === 2).length}`);
