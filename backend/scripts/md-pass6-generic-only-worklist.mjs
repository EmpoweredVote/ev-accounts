#!/usr/bin/env node
/**
 * PASS 6 (Maryland) -- GENERIC-ONLY SOURCING, ROW-LEVEL COHORT.
 *
 * WHY THIS EXISTS: passes 1-5 worked a cohort defined POLITICIAN-level by
 *     distinct_srcs = 1 AND rows_ct >= 5 AND the_src ILIKE '%mgaleg%'
 * (see md-pass4-instrument-worklist.mjs). That test silently excludes every politician who has
 * ANY row with a specific citation, and everyone with fewer than 5 stances -- so as soon as passes
 * 4/5 added bill citations to SOME of a politician's rows, that politician fell OUT of the cohort
 * carrying their remaining defective rows with them. Measured 2026-08-11: 1,241 rows / 154
 * politicians are sourced ONLY by generic profile pages, of which 618 rows were NEVER audited.
 *
 * 🔑 THE FIX IS THE COHORT SHAPE, NOT THE THRESHOLD: test the ROW's own source set, never the
 * politician's aggregate. The defect is "a GENERIC PROFILE PAGE used to source a per-topic
 * position" -- a member landing page, a Ballotpedia bio, a Wikipedia article hold no per-topic
 * position at all. Source TYPE, never source COUNT.
 *
 * 🔴 THIS PROPOSES NOTHING AND WRITES NOTHING TO THE DB. It emits a worklist for a human.
 * 🔴 COVERAGE BOUND: corpus is 2013RS-2026RS; 2012 and earlier parse to ZERO rows, so a miss on a
 *    pre-2013 instrument is UNKNOWN, never absent. A row with no sponsor link and no roll call is
 *    UNVERIFIED, never false.
 *
 *   node scripts/md-pass6-generic-only-worklist.mjs --corpus <corpus.json> --prior <pass4.json> --out <out.json>
 */
import fs from 'node:fs';
import pg from 'pg';
import { extractInstruments, buildIndex, lookupAct, statedYears, claimVerb } from './lib/md-instruments.mjs';

const argv = process.argv.slice(2);
const flag = (n, d = null) => { const i = argv.indexOf(n); return i > -1 ? argv[i + 1] : d; };
const corpusPath = flag('--corpus');
const priorPath = flag('--prior');
const outPath = flag('--out');
if (!corpusPath || !outPath) { console.error('need --corpus and --out'); process.exit(2); }

const env = fs.readFileSync('C:/EV-Accounts/backend/.env', 'utf8');
const url = env.split(/\r?\n/).find((l) => /^DATABASE_URL=/.test(l)).replace(/^DATABASE_URL=/, '').trim();

const { bills } = JSON.parse(fs.readFileSync(corpusPath, 'utf8'));
const idx = buildIndex(bills);

// ⚠ Cohort membership is read from the RECORDED pass-4 worklist, never recomputed. Recomputing the
// distinct_srcs=1 test today would NOT reproduce the historical 92 -- passes 4/5 changed those very
// source sets. A detector's output drifts; the artifact of what it selected does not.
let prior = new Set();
if (priorPath) {
  const pw = JSON.parse(fs.readFileSync(priorPath, 'utf8'));
  const rows = Array.isArray(pw) ? pw : (pw.rows || []);
  prior = new Set(rows.map((r) => `${r.politician_id}|${r.topic_id}`));
  console.log(`prior pass-4 worklist: ${rows.length} rows`);
}

const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });
const { rows } = await pool.query(`
  SELECT p.full_name, c.politician_id, c.topic_id, t.title AS topic, a.value,
         c.reasoning, c.sources
  FROM inform.politician_context c
  JOIN essentials.politicians p ON p.id = c.politician_id
  LEFT JOIN inform.compass_topics t ON t.id = c.topic_id
  LEFT JOIN inform.politician_answers a ON a.politician_id = c.politician_id AND a.topic_id = c.topic_id
  WHERE array_to_string(c.sources, ' ') ILIKE '%mgaleg.maryland.gov%'
    AND array_to_string(c.sources, ' ') NOT ILIKE '%Legislation/Details%'
    AND array_to_string(c.sources, ' ') NOT ILIKE '%/votes/%'
    AND NOT EXISTS (
      SELECT 1 FROM unnest(c.sources) u
      WHERE u NOT ILIKE '%mgaleg.maryland.gov%'
        AND u NOT ILIKE '%ballotpedia.org%'
        AND u NOT ILIKE '%wikipedia.org%')
  ORDER BY p.full_name, t.title`);
await pool.end();

const work = rows.map((r) => {
  const text = r.reasoning || '';
  const instruments = extractInstruments(text);
  const resolved = instruments.map((i) => {
    if (/^[SH]B\d{4}$/.test(i)) {
      // ⚠ A BARE BILL NUMBER IS AMBIGUOUS ACROSS SESSIONS (mig 1686): HB0810 is "Exploitation of
      // Vulnerable Adults" (2014) and "Economic Development Tax Credit" (2015). Never resolve one
      // without the year -- so every session hit is returned and the caller must gate on the year.
      const hits = [...new Map(idx.filter((b) => b.number.toUpperCase() === i).map((h) => [h.number + h.session, h])).values()];
      const sessions = [...new Set(hits.map((h) => h.session))];
      return {
        instrument: i, kind: 'bill_number',
        verdict: hits.length ? 'FOUND' : 'NOT_IN_CORPUS',
        ambiguous_sessions: sessions.length > 1 ? sessions : null,
        hits: hits.slice(0, 8),
      };
    }
    return { instrument: i, kind: 'act_name', ...lookupAct(i, idx) };
  });
  const years = statedYears(text);
  return {
    politician: r.full_name, politician_id: r.politician_id, topic: r.topic, topic_id: r.topic_id,
    value: r.value, sources: r.sources, reasoning: text,
    instruments: resolved,
    has_instrument: resolved.length > 0,
    // Consumed by md-pass4-verify-sponsorship.mjs, which is reused verbatim for this pass.
    // ⚠ FOUND_LOOSE counts as resolved here ONLY so the verifier gathers its evidence. It is NOT a
    // resolution: "CROWN Act" loosely matches Crownsville Treatment Center bonds, and MD's real
    // CROWN Act (2020RS SB0531/HB1444) has no "CROWN" in its title at all. The gate against acting
    // on a loose match is the human read, never this flag.
    all_resolved: resolved.length > 0 && resolved.every((x) => ['FOUND', 'FOUND_LOOSE', 'FOUND_CONJUNCTION'].includes(x.verdict)),
    stated_years: years,
    claim_test: resolved.length ? claimVerb(text, resolved[0].instrument) : null,
    // Needs a human before any citation is proposed: the corpus offers >1 session for the
    // instrument and the prose does not state a year to disambiguate.
    needs_year_decision: resolved.some((x) => x.ambiguous_sessions) && years.length === 0,
    previously_attempted: prior.has(`${r.politician_id}|${r.topic_id}`),
  };
});

// FOUND_CONJUNCTION resolved (as two separate instruments); FOUND_LOOSE is a candidate, not a
// resolution, but it IS matched -- an unresolved row is one the corpus could not place at all.
const RESOLVED = new Set(['FOUND', 'FOUND_LOOSE', 'FOUND_CONJUNCTION']);
const withInst = work.filter((w) => w.has_instrument);
const tally = {
  generic_only_rows: work.length,
  generic_only_politicians: new Set(work.map((w) => w.politician_id)).size,
  rows_naming_an_instrument: withInst.length,
  rows_naming_nothing: work.length - withInst.length,
  never_audited_rows: work.filter((w) => !w.previously_attempted).length,
  never_audited_with_instrument: withInst.filter((w) => !w.previously_attempted).length,
  by_test: withInst.reduce((a, w) => { a[w.claim_test] = (a[w.claim_test] || 0) + 1; return a; }, {}),
  rows_needing_year_decision: withInst.filter((w) => w.needs_year_decision).length,
  rows_with_unresolved_instrument: withInst.filter((w) => !w.instruments.every((x) => RESOLVED.has(x.verdict))).length,
  rows_relying_on_loose_match: withInst.filter((w) => w.instruments.some((x) => x.verdict === 'FOUND_LOOSE')).length,
  rows_naming_two_instruments: withInst.filter((w) => w.instruments.some((x) => x.verdict === 'FOUND_CONJUNCTION')).length,
};
fs.writeFileSync(outPath, JSON.stringify({
  pass: 'MD pass 6 - generic-only sourcing, row-level cohort',
  caveat: 'Corpus 2013RS-2026RS. A miss on a pre-2013 instrument is UNKNOWN, not absent. '
        + 'FOUND_LOOSE is a candidate for a human, never a resolution. Nothing here is a delete list.',
  tally, rows: work,
}, null, 1));
console.log(JSON.stringify(tally, null, 2));
