#!/usr/bin/env node
/**
 * TIER A of the row-level national generic-sourcing audit: rows sourced ONLY by a legislature
 * MEMBER/PROFILE page, which structurally holds no per-topic position.
 *
 * Verified per state rather than assumed:
 *   MD mgaleg  /mgawebsite/Members/Details/     -- proven across passes 1-6
 *   MA         /Legislators/Profile/<id>        -- fetched: ZERO occurrences of supports/opposes/
 *                                                 believes/issues; committees + contact + bill list.
 *                                                 Its lone "climate" hit is a COMMITTEE NAME.
 *   TX         /Members/MemberInfo.aspx
 *   ME         /house|senate/memberprofiles/
 *   AZ         /house/house-member/ , /senate/senate-member/
 *
 * 🔴 Reads only. Emits a worklist telling you which rows are MECHANICALLY workable (they name an
 * instrument) and which are a human reading queue (they name nothing).
 *
 *   node scripts/tier-a-generic-member-pages.mjs --out <out.json>
 */
import fs from 'node:fs';
import pg from 'pg';
import { extractInstruments, statedYears, claimVerb } from './lib/md-instruments.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const OUT = flag('--out');
if (!OUT) { console.error('need --out'); process.exit(2); }

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();
const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });

// A row qualifies only if EVERY source is a generic person-page. Wayback URLs are unwrapped first.
// ⚠ Ballotpedia/Wikipedia count as generic ONLY here as companions -- Tier A is keyed on the
// presence of a legislature MEMBER page, which is the part proven to hold no positions.
const { rows } = await pool.query(`
  WITH src AS (
    SELECT c.politician_id, c.topic_id, u,
           COALESCE(substring(u FROM 'web\\.archive\\.org/web/[0-9]+(?:id_)?/(https?://.*)$'), u) AS nu
    FROM inform.politician_context c, unnest(c.sources) u
  ), cls AS (
    SELECT politician_id, topic_id, nu,
      CASE WHEN nu ILIKE '%en.wikipedia.org/wiki/%'
        OR (nu ILIKE '%ballotpedia.org/%' AND nu NOT ILIKE '%candidate_connection%')
        OR nu ILIKE '%/mgawebsite/members/details/%'
        OR nu ILIKE '%capitol.texas.gov/members/memberinfo%'
        OR nu ILIKE '%malegislature.gov/legislators/profile%'
        OR nu ILIKE '%legislature.maine.gov/house/memberprofiles%'
        OR nu ILIKE '%legislature.maine.gov/senate/memberprofiles%'
        OR nu ILIKE '%azleg.gov/house/house-member%'
        OR nu ILIKE '%azleg.gov/senate/senate-member%'
        OR nu ILIKE '%ballotready.org/people/%'
        OR nu ILIKE '%congress.gov/member/%'
        OR nu ILIKE '%govtrack.us/congress/members/%'
      THEN 1 ELSE 0 END AS is_generic,
      CASE
        WHEN nu ILIKE '%/mgawebsite/members/details/%' THEN 'MD'
        WHEN nu ILIKE '%malegislature.gov/legislators/profile%' THEN 'MA'
        WHEN nu ILIKE '%capitol.texas.gov/members/memberinfo%' THEN 'TX'
        WHEN nu ILIKE '%legislature.maine.gov/%memberprofiles%' THEN 'ME'
        WHEN nu ILIKE '%azleg.gov/%-member%' THEN 'AZ'
        ELSE NULL END AS state
    FROM src
  ), agg AS (
    SELECT politician_id, topic_id, count(*) n_src, sum(is_generic) n_generic,
           max(state) AS state
    FROM cls GROUP BY 1,2
  )
  SELECT p.full_name, a.politician_id, a.topic_id, t.title AS topic, a.state,
         ans.value, c.reasoning, c.sources
  FROM agg a
  JOIN inform.politician_context c ON c.politician_id=a.politician_id AND c.topic_id=a.topic_id
  JOIN essentials.politicians p ON p.id=a.politician_id
  LEFT JOIN inform.compass_topics t ON t.id=a.topic_id
  LEFT JOIN inform.politician_answers ans ON ans.politician_id=a.politician_id AND ans.topic_id=a.topic_id
  WHERE a.n_generic = a.n_src AND a.state IS NOT NULL
  ORDER BY a.state, p.full_name, t.title`);
await pool.end();

const work = rows.map((r) => {
  const text = r.reasoning || '';
  const instruments = extractInstruments(text);
  return {
    state: r.state, politician: r.full_name, politician_id: r.politician_id,
    topic: r.topic, topic_id: r.topic_id, value: r.value,
    sources: r.sources, reasoning: text,
    instruments, has_instrument: instruments.length > 0,
    stated_years: statedYears(text),
    claim_test: instruments.length ? claimVerb(text, instruments[0]) : null,
  };
});

const byState = {};
for (const w of work) {
  const s = (byState[w.state] ||= { rows: 0, pols: new Set(), with_instrument: 0, naming_nothing: 0, tests: {} });
  s.rows++; s.pols.add(w.politician_id);
  if (w.has_instrument) { s.with_instrument++; s.tests[w.claim_test] = (s.tests[w.claim_test] || 0) + 1; }
  else s.naming_nothing++;
}
const tally = Object.fromEntries(Object.entries(byState).map(([k, v]) =>
  [k, { rows: v.rows, politicians: v.pols.size, with_instrument: v.with_instrument, naming_nothing: v.naming_nothing, tests: v.tests }]));

fs.writeFileSync(OUT, JSON.stringify({
  pass: 'Tier A - legislature member-page-only rows, national',
  caveat: 'A member/profile page holds no per-topic position -- verified per state. Rows naming an '
        + 'instrument are mechanically workable; rows naming nothing are a HUMAN reading queue. '
        + 'Nothing here is a delete list.',
  tally, rows: work,
}, null, 1));
console.log(JSON.stringify(tally, null, 2));
console.log('total rows:', work.length);
