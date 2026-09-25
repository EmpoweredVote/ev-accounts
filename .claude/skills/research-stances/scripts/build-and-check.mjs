#!/usr/bin/env node
/**
 * build-and-check.mjs — pre-push QA for a research CSV.
 *
 * Builds the audit-quotes context bundle (topics -> quotes with stance
 * {question_text, value, chairs}, editor_note, de-id) from a research CSV, and runs
 * the deterministic mechanical checks BEFORE anything is inserted, so the orchestrator
 * can fix problems in the CSV instead of in the DB. Mirrors the mechanical pass of the
 * audit-quotes skill (note-missing, note-too-long, note-section-ref, deid-missing,
 * trailing-ellipsis, partisan-tell, invalid-source, unquotable-source, scorecard-source,
 * pointer-only-source, stance-label). There is deliberately no campaign-site URL check:
 * provenance is judged by directness of answer, not medium, so the audit-quotes judgment
 * pass owns it (source-not-an-answer).
 *
 *   cd ev-accounts/backend && node ../.claude/skills/research-stances/scripts/build-and-check.mjs \
 *      --csv data/stance-research/2026-07-12-ca-gov-becerra-otr.csv
 *   # writes <csv>.bundle.json and prints findings. --out overrides the bundle path.
 *
 * Reads DATABASE_URL from ev-accounts/backend/.env; resolves pg + csv-parse from
 * backend/node_modules (so it runs no matter the cwd). Those two requires are LAZY
 * (loaded inside main()) so that importing this module and calling the pure
 * checkQuoteRow(row) needs no node_modules at all — that's what the Node parity test
 * (tests/fixture-parity.test.mjs) relies on.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));            // .../research-stances/scripts
const evRoot = resolve(here, '..', '..', '..', '..');           // .../ev-accounts
const backend = join(evRoot, 'backend');

function parseArgs(argv) {
  const a = {};
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--csv') a.csv = argv[++i];
    else if (argv[i] === '--out') a.out = argv[++i];
  }
  return a;
}

function databaseUrl() {
  if (process.env.DATABASE_URL) return process.env.DATABASE_URL;
  const env = readFileSync(join(backend, '.env'), 'utf8');
  const m = env.match(/^\s*DATABASE_URL\s*=\s*"?([^"\n]+)"?/m);
  if (!m) throw new Error('DATABASE_URL not found in env or backend/.env');
  return m[1];
}

// ---- the served-revision resolver (ADR 0006 §3) ----
// A VERBATIM MIRROR of seasonService.servedRevisionLateral (backend/src/lib/seasonService.ts). This
// file cannot import backend TypeScript, so the text is copied; backend/src/lib/servedRevision.test.ts
// builds both with the same arguments and fails if they differ. Change both together.
export function servedRevisionLateral(pinExpr, alias = 'eff') {
  return `LATERAL (
    SELECT e.id, e.title, e.short_title, e.question_text, e.version, e.revision
      FROM inform.compass_topic_revisions pin
      JOIN inform.compass_topic_revisions e
        ON e.topic_id = pin.topic_id
       AND e.version  = pin.version
       AND e.status IN ('published', 'superseded')
     WHERE pin.id = ${pinExpr}
     ORDER BY e.revision DESC
     LIMIT 1
  ) ${alias}`;
}

// ---- mechanical checks (ported from audit-quotes scripts/checks.py) ----
const DEM = /\b(Democrat|Democrats|Democratic)\b/;
const REP = /\b(Republican|Republicans|GOP)\b/;
const PARTISAN = /\b(Democrat|Democrats|Democratic|Republican|Republicans|GOP|MAGA)\b/;
const PARTY_PHRASE = /\b(?:my|our) party\b/i;
const SENTENCE_END = /[.!?](\s|$)/g;
// Secondary aggregators / encyclopedias — NOT valid sources (checks.py: AGGREGATOR_SOURCE).
const AGGREGATOR_SOURCE = /ontheissues\.org|wikipedia\.org/i;
// Quiz / questionnaire comparison sites — categorically unquotable (checks.py: QUIZ_SOURCE).
const QUIZ_SOURCE = /isidewith\.com/i;
// Legislative scorecards — votes/ratings, never utterances (checks.py: SCORECARD_SOURCE).
const SCORECARD_SOURCE = /\/(?:[a-z]+-)?scorecards?\//i;
// VOTE411 answers are the candidate's words, but LWV terms bar reproducing them without
// written permission — a pointer, never a cited source (checks.py: POINTER_ONLY_SOURCE).
const POINTER_ONLY_SOURCE = /vote411\.org|thevoterguide\.org/i;
// A quote this short states a topic, not a position (checks.py: STANCE_LABEL_MAX_WORDS).
const WORD = /[A-Za-z0-9][A-Za-z0-9'’-]*/g;
const STANCE_LABEL_MAX_WORDS = 4;

/**
 * Pure, deterministic mechanical checks over one row. No DB, no I/O — mirrors
 * audit-quotes/scripts/checks.py's QUOTE_CHECKS. Accepts either the DB-shaped row
 * (topic_key/candidate/id) or the CSV-bundle row (same field names), and the shared
 * fixture row shape (docs/quote-curation/fixtures/mechanical-checks.json).
 */
export function checkQuoteRow(r) {
  const out = [];
  const base = { topic_key: r.topic_key, race_id: r.race_id, candidate: r.candidate, quote_id: r.id };
  const note = (r.editor_note || '').trim();
  if (!note) out.push({ ...base, check_id: 'note-missing', severity: 'high',
    what: 'editor_note is empty (essentials.quotes requires one; the audit hard-fails without it).' });
  else if (/§/.test(note) || /\btier-?\d\b/i.test(note)) out.push({ ...base, check_id: 'note-section-ref', severity: 'medium',
    what: 'editor_note cites internal section numbers / jargon; rewrite human-readable.' });
  else if ((note.match(SENTENCE_END) || []).length > 3) out.push({ ...base, check_id: 'note-too-long', severity: 'low',
    what: 'editor_note is longer than 3 sentences.' });
  if (!(r.deidentified_text || '').trim()) out.push({ ...base, check_id: 'deid-missing', severity: 'high',
    what: 'deidentified_text is blank; row is not admin-selectable and has no blind card.' });
  const qt = (r.quote_text || '').replace(/\s+$/, '');
  if (qt.endsWith('…') || qt.endsWith('...')) out.push({ ...base, check_id: 'trailing-ellipsis', severity: 'low',
    what: 'quote_text ends with a trailing ellipsis (strip it).' });
  const blind = r.deidentified_text || '';
  if (!(DEM.test(blind) && REP.test(blind))) {           // symmetric mention of both parties reveals no side
    const m = blind.match(PARTISAN) || blind.match(PARTY_PHRASE);
    if (m) out.push({ ...base, check_id: 'partisan-tell', severity: 'high',
      what: `blind text contains a partisan/side tell: '${m[0]}'.` });
  }
  const url = r.source_url || '';
  if (AGGREGATOR_SOURCE.test(url)) out.push({ ...base, check_id: 'invalid-source', severity: 'high',
    what: `source is a secondary aggregator, not an original: ${url}` });
  if (QUIZ_SOURCE.test(url)) out.push({ ...base, check_id: 'unquotable-source', severity: 'high',
    what: `source is a quiz/questionnaire site (no quotable row): ${url}` });
  if (SCORECARD_SOURCE.test(url)) out.push({ ...base, check_id: 'scorecard-source', severity: 'high',
    what: `source is a legislative scorecard (votes/ratings, not utterances): ${url}` });
  if (POINTER_ONLY_SOURCE.test(url)) out.push({ ...base, check_id: 'pointer-only-source', severity: 'high',
    what: `source is VOTE411 / thevoterguide.org: ${url}. LWV terms bar reproducing this without written permission, so it cannot be a cited source.` });
  const words = ((r.quote_text || '').match(WORD) || []).length;
  if (words > 0 && words <= STANCE_LABEL_MAX_WORDS) out.push({ ...base, check_id: 'stance-label', severity: 'medium',
    what: `quote is ${words} word(s) — a stance label, not a rankable statement.` });
  return out;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args.csv) { console.error('Usage: build-and-check.mjs --csv <path> [--out <bundle.json>]'); process.exit(2); }

  // Lazy requires: only main() (the DB/CSV-bundle path) needs pg + csv-parse, so
  // importing this module for checkQuoteRow alone needs no node_modules.
  const { createRequire } = await import('node:module');
  const require = createRequire(join(backend, 'package.json'));
  const { Client } = require('pg');
  const { parse } = require('csv-parse/sync');

  const csvPath = resolve(args.csv);
  const rows = parse(readFileSync(csvPath, 'utf8'), { columns: true, skip_empty_lines: true });

  const client = new Client({ connectionString: databaseUrl(), ssl: { rejectUnauthorized: false } });
  await client.connect();

  const bundle = { source_csv: csvPath, topics: {} };
  const quotes = [];
  const stanceCache = new Map();

  for (const r of rows) {
    if (!(r.quote_text || '').trim()) continue;            // only rows with a quote become bundle quotes
    const tk = (r.topic_key || '').toLowerCase();
    const name = r.full_name;
    // resolve politician_id (by full_name or alternate_names) — fetch up to 2 rows so an
    // ambiguous name (two namesakes sharing a full_name/alternate_name) is caught instead of
    // silently picked via LIMIT 1.
    const pidRows = (await client.query(
      `SELECT id::text FROM essentials.politicians
       WHERE lower(full_name)=lower($1)
          OR EXISTS (SELECT 1 FROM unnest(alternate_names) a WHERE lower(a)=lower($1)) LIMIT 2`, [name])).rows;
    if (pidRows.length > 1) console.error(`WARN: "${name}" matches more than one politician — no stance attached`);
    const pid = pidRows.length === 1 ? pidRows[0].id : null;
    const key = pid + '|' + tk;
    let stance = stanceCache.get(key);
    if (stance === undefined) {
      stance = null;
      if (pid) {
        // 🔴 THE "NEWEST SEASON ANSWERED" PICK MUST BE ORDERED AND LIMITED. It used to be a
        // SCALAR subquery: with one season it returns one row, and with two it returns two and
        // Postgres raises 21000, "more than one row returned by a subquery used as an
        // expression". Loud, but only once a second season exists — so it looked fine right up
        // until it wasn't. It's now a LATERAL join (so it can carry topic_revision_id alongside
        // value), but the same ORDER BY + LIMIT 1 still does the picking, for the same reason.
        //
        // The question here is "what does this person say on this topic", which follows the
        // PERSON, not the calendar: take the newest season in which they actually answered,
        // whichever that is. Someone not researched this season still has a stance, and asking
        // the open season for it would blank a compass that has real content. Mirrors
        // seasonService.newestAnswerLateral.
        //
        // Chair text and question text come from the SERVED revision of the answer's OWN pin
        // (inform.compass_topic_revisions / inform.compass_stance_revisions; ADR 0006) — never the frozen inform.compass_stances, and never
        // gated on is_live (CLAUDE.md "Officeholder..." — same rule, different table: read the
        // dated/versioned row, not a column that claims to be "current"). With no answer at all,
        // fall back to the OPEN season's pinned revision (inform.season_questions joined to
        // inform.seasons where status='open') for question + chairs, value null — but never fall
        // back for an answer that DOES exist, even when that answer's own revision can't be
        // found. Mixing an answer from one season with chair text pinned to another is the
        // defect this replaces.
        const s = (await client.query(
          `SELECT tr.question_text,
             -- @zero-scope: excludes-blanks — a 0 names no chair; the quote judge must not read it as a position.
             CASE WHEN ans.value = 0 THEN NULL ELSE ans.value END AS value,
             (SELECT json_agg(json_build_object('v', sr.value, 'text', sr.text) ORDER BY sr.value)
                FROM inform.compass_stance_revisions sr
               WHERE sr.topic_revision_id = tr.id) AS chairs
            FROM inform.compass_topics t
            LEFT JOIN LATERAL (
              -- Mirrors SEASON_IS_PUBLISHED (backend/src/lib/seasonService.ts, s.status <> 'draft'):
              -- a pre-staged draft-season answer is not a position anyone can see yet, so it must not
              -- count as "answered" here — the quote judge would otherwise score a quote against a
              -- stance nobody outside the review queue has read.
              SELECT a.value, a.topic_revision_id, true AS answered
                FROM inform.politician_answers a
                JOIN inform.seasons ssn ON ssn.id = a.season_id AND ssn.status <> 'draft'
               WHERE a.topic_id = t.id AND a.politician_id = $1::uuid
               ORDER BY ssn.number DESC
               LIMIT 1
            ) ans ON true
            LEFT JOIN LATERAL (
              SELECT sq.topic_revision_id
                FROM inform.season_questions sq
                JOIN inform.seasons se ON se.id = sq.season_id AND se.status = 'open'
               WHERE sq.topic_id = t.id
               LIMIT 1
            ) open_pin ON true
            -- C1 (final review 2026-09-24): the SERVED revision of that pin — the latest
            -- published/superseded revision of its version (ADR 0006), which is the text voters
            -- read, not the pin's own (superseded) rungs. Verbatim mirror of
            -- seasonService.servedRevisionLateral (backend/src/lib/seasonService.ts; this file is
            -- outside backend's rootDir); servedRevision.test.ts fails if the two drift.
            LEFT JOIN ${servedRevisionLateral('CASE WHEN ans.answered THEN ans.topic_revision_id ELSE open_pin.topic_revision_id END', 'tr')} ON true
           WHERE t.topic_key = $2`, [pid, tk])).rows[0];
        // No chairs is better than wrong chairs: an answer whose own revision can't be found,
        // or a topic with no ladder at all (no answer AND no open-season pin), yields stance =
        // null rather than mismatched or missing-but-silent chair text.
        if (s && s.chairs) stance = s;
        else console.error(`WARN: "${name}" / ${tk}: no compass ladder revision found for this answer — stance left blank`);
      }
      stanceCache.set(key, stance);
    }
    const q = {
      id: `CSV-${name}-${tk}`.replace(/\s+/g, '_'),
      topic_key: tk, candidate: name, politician_id: pid,
      quote_text: r.quote_text,
      deidentified_text: (r.quote_deidentified || '').trim() || null,
      editor_note: (r.editor_note || '').trim() || null,
      source_url: r.source_url_1 || r.source_url_2 || r.source_url_3 || null,
      stance,
    };
    quotes.push(q);
    const t = bundle.topics[tk] || (bundle.topics[tk] = { topic_key: tk, quotes: [] });
    t.quotes.push(q);
  }
  await client.end();

  const findings = quotes.flatMap(checkQuoteRow);
  const outPath = args.out ? resolve(args.out) : csvPath.replace(/\.csv$/, '') + '.bundle.json';
  writeFileSync(outPath, JSON.stringify(bundle, null, 2));

  const bySev = { high: 0, medium: 0, low: 0 };
  for (const f of findings) bySev[f.severity] = (bySev[f.severity] || 0) + 1;
  console.log(`Bundle: ${quotes.length} quote(s) across ${Object.keys(bundle.topics).length} topic(s) -> ${outPath}`);
  console.log(`MECHANICAL FINDINGS: ${findings.length} (high=${bySev.high} medium=${bySev.medium} low=${bySev.low})`);
  for (const f of findings) console.log(`  ${f.check_id.padEnd(18)} ${f.severity.padEnd(6)} ${f.candidate} / ${f.topic_key}: ${f.what}`);
  const missingPid = quotes.filter(q => !q.politician_id).map(q => q.candidate);
  if (missingPid.length) console.log(`\nWARNING: no politician_id for: ${[...new Set(missingPid)].join(', ')} (won't resolve on push)`);
  // non-zero exit if any high-severity finding, so the pipeline can gate on it
  process.exit(bySev.high > 0 ? 1 : 0);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(e => { console.error('FATAL:', e.message); process.exit(2); });
}
