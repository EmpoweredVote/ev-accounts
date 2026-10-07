#!/usr/bin/env node
/**
 * Fail if the PUBLISHED coverage catalog claims compass coverage the database does not hold.
 *
 * WHY THIS EXISTS. `hasContext: true` in essentials `src/lib/coverage.js` renders a place's chip
 * purple and tells a voter "this place has compass stances — come and read why". Nothing on either
 * side of the repo boundary checked that the claim was true, and on 2026-10-06 it was not: EIGHT
 * Utah chips (Layton, Lehi, Ogden, Provo, Sandy, St. George, West Jordan, West Valley City) were
 * purple with ZERO compass rows — not stale rows, not retired rows, none ever, for any politician
 * ever linked to those governments through office_terms. essentials #190 flipped them grey.
 *
 * 🔴 THEY WERE NOT FOUND BY A DETECTOR. They were found by accident, while measuring the purple
 * cohort to decide where the bar sat for seven GREY chips. That is the whole argument for this
 * file: the defect is silent, it is voter-facing, and the only reason anyone saw it was that
 * somebody happened to look sideways. A guard is cheaper than the next accident.
 *
 * ⚠ IT GUARDS THE PUBLISHED CATALOG, NOT THE SOURCE FILE — on purpose. It reads
 * https://essentials.empowered.vote/coverage.json, which `prebuild` regenerates from coverage.js on
 * every essentials deploy, and which Treasury Tracker already consumes as a public contract. So a
 * green run means "what voters are being shown right now is backed by rows", which is the claim
 * worth making. The cost is a lag: greying a chip in essentials turns this green only once that
 * deploy lands. That lag is correct — until the deploy, the false chip is still on screen.
 *
 * WHAT IT CANNOT SEE: whether a row's reasoning is any GOOD, or whether its sources exist. Row
 * quality is check:stance-sources' job and the article-body sweep's job. This asks only the
 * structural question those cannot: does the city-level CLAIM match the row count?
 *
 * ── THE THREE TIERS, and why they are not all failures ────────────────────────────────────────
 *
 * FAIL · EMPTY_PURPLE — hasContext true, ZERO seated officials hold a row with reasoning.
 *   Zero tolerance, no baseline file. There is no reading of "this place has compass coverage"
 *   that survives having none, so a baseline here would only be somewhere to hide a false chip.
 *
 * FAIL · ONE_OFFICIAL_CITY — hasContext true on a CITY, exactly one covered official.
 *   Operator ruling 2026-10-06: one official out of three-to-seven seats is not city coverage,
 *   however good that one row is. essentials #191 greyed the eleven that existed (Anna, Fairview,
 *   Farmersville, Melissa, Parker TX; Dover, Norway, Raymond, Rochester, Union Grove, Yorkville
 *   WI), so the correct value is 0 and this is enforceable rather than advisory.
 *
 * REPORT · the rest. These print and do NOT fail, because each needs a judgement this script is
 *   not entitled to make:
 *     - ONE_OFFICIAL_COUNTY. Counties are not on the landing grid and the one instance is
 *       legitimate: Kitsap County WA's comment names two chair-holders, but one is a sheriff
 *       CANDIDATE rather than a seated official, so it reads as 1 only to a seated-officials
 *       measure like this one. Failing it would punish an accurate comment for our measurement
 *       choice.
 *     - UNDERCLAIMED. hasContext FALSE while three or more officials hold rows. This is the
 *       INVERSE defect and it is real — Newton MA sat grey through a full re-research pass and
 *       had to be flipped by hand in #190. But flipping a chip purple requires reading the rows,
 *       so the script surfaces the candidate and stops. Two today: Travis County TX (6 of 12) and
 *       Deschutes County OR (3 of 7) — the latter being, with some irony, the namesake of the
 *       "Deschutes rule" that the rest of coverage.js cites for not overclaiming.
 *     - UNRESOLVED_GEOID. A catalog geoid matching no government row. Two today, both VA
 *       independent cities carrying a second county-equivalent code beside a place code that does
 *       resolve — Alexandria ['5101000','51510'] and Falls Church ['5127200','51610']. Both cities
 *       are genuinely covered via the place code, so this is dead weight in a published contract
 *       rather than a false claim, and the VA dual-tier seed may have meant it.
 *
 * 🔑 THE THRESHOLD IS A COUNT OF OFFICIALS, NEVER A PERCENTAGE. Dover WI seats three; a 25% rule
 * would pass it on one row while failing a 12-seat council with two. The ruling was about the
 * count, so the check is about the count. Racine County WI (2 of 38) therefore passes, and that
 * is a deliberate consequence rather than an oversight.
 *
 * ⚠ "Covered" means a SEATED official, resolved through essentials.current_office_holders — never
 * a hand-rolled `term_end IS NULL`, which reads anyone with a dated future term as unseated (see
 * ADR 0002 and check:occupancy). It also means a row in inform.politician_context with non-empty
 * `reasoning`, joined on ALL THREE keys (politician_id, topic_id, season_id). It does NOT mean
 * politician_answers.write_in_text, which is empty on properly researched rows: reading that
 * column is what greyed Detroit for "no reasoning a reader can check" when all five of its rows
 * carried 417-621 characters of it.
 *
 * ⚠ A catalog entry may carry SEVERAL geoids (VA above, and the LA by-district cohort). Officials
 * are counted across the union of them and de-duplicated, because the chip is one claim.
 *
 * Exit codes: 0 clean (or skipped), 1 defects found, 2 catalog unreachable. The last is kept
 * distinct on purpose — a network failure must not read as a data defect in a nightly log, and it
 * must not read as a pass either.
 *
 * ⚠ Set via `process.exitCode` and a return, NEVER `process.exit()`. Calling process.exit() while
 * the fetch handle was still closing crashed libuv on Windows ("Assertion failed:
 * !(handle->flags & UV_HANDLE_CLOSING)") and the process left with 127 — so the one path that
 * most needed its distinct code was the one that lost it. Found by testing the failure paths,
 * which is the only way anyone finds this.
 *
 * Usage:
 *   node scripts/check-coverage-honesty.mjs              # gate
 *   node scripts/check-coverage-honesty.mjs --verbose    # every entry, with counts
 *   node scripts/check-coverage-honesty.mjs --file p.json  # a local catalog, for testing
 *   COVERAGE_JSON_URL=... node scripts/check-coverage-honesty.mjs
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import { Pool } from 'pg';

const VERBOSE = process.argv.includes('--verbose');
const fileArg = process.argv.indexOf('--file');
const LOCAL_FILE = fileArg !== -1 ? process.argv[fileArg + 1] : null;
const CATALOG_URL = process.env.COVERAGE_JSON_URL || 'https://essentials.empowered.vote/coverage.json';

// The ruling's threshold, as a named constant so a future change is one edit with a date on it.
const MIN_COVERED_OFFICIALS_CITY = 2; // operator ruling 2026-10-06
const UNDERCLAIM_REPORT_AT = 3; // grey chips with >= this many covered officials get reported

async function loadCatalog() {
  if (LOCAL_FILE) return { source: LOCAL_FILE, catalog: JSON.parse(readFileSync(LOCAL_FILE, 'utf8')) };
  const res = await fetch(CATALOG_URL, { headers: { accept: 'application/json' } });
  if (!res.ok) throw new Error(`${CATALOG_URL} returned HTTP ${res.status}`);
  // essentials is a single-page app, so a WRONG PATH does not 404 — it serves index.html with a
  // 200 and the failure only surfaces as a JSON parse error about an unexpected '<'. Say what
  // actually happened instead, or the next person debugs their database for an hour.
  const body = await res.text();
  if (body.trimStart().startsWith('<')) {
    throw new Error(`${CATALOG_URL} returned HTML, not JSON — the SPA fallback served index.html, so that path is wrong`);
  }
  return { source: CATALOG_URL, catalog: JSON.parse(body) };
}

(async () => {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    return;
  }

  let source, catalog;
  try {
    ({ source, catalog } = await loadCatalog());
  } catch (err) {
    // Exit 2, not 1: the catalog being unreachable says nothing about the data, and a reader
    // scanning a red nightly needs to know which of the two they are looking at.
    console.error('CATALOG UNREACHABLE — this is not a data defect.');
    console.error(`  ${err.message}`);
    console.error('  The check needs the published catalog to know what voters are being shown.');
    process.exitCode = 2;
    return;
  }

  const entries = [
    ...(catalog.cities ?? []).map((c) => ({ ...c, kind: 'city' })),
    ...(catalog.counties ?? []).map((c) => ({ ...c, kind: 'county' })),
  ];
  if (entries.length === 0) {
    console.error(`CATALOG EMPTY — ${source} parsed but listed no cities or counties.`);
    process.exitCode = 2;
    return;
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

  // One query for the whole catalog rather than 290 round trips. Counts are per GEOID; an entry
  // spanning several geoids is reduced below, de-duplicating politicians across them.
  const geoids = [...new Set(entries.flatMap((e) => e.geoids ?? []))];
  const { rows } = await pool.query(
    `
    WITH cat(geo_id) AS (SELECT unnest($1::text[])),
    seats AS (
      SELECT DISTINCT g.geo_id, coh.politician_id
      FROM cat
      JOIN essentials.governments g ON g.geo_id = cat.geo_id
      JOIN essentials.chambers ch   ON ch.government_id = g.id
      JOIN essentials.offices o     ON o.chamber_id = ch.id
      JOIN essentials.current_office_holders coh ON coh.office_id = o.id
    )
    SELECT s.geo_id,
           array_agg(DISTINCT s.politician_id) AS seated_ids,
           array_remove(array_agg(DISTINCT pa.politician_id)
             FILTER (WHERE pc.reasoning IS NOT NULL AND btrim(pc.reasoning) <> ''), NULL) AS covered_ids
    FROM seats s
    LEFT JOIN inform.politician_answers pa ON pa.politician_id = s.politician_id
    LEFT JOIN inform.politician_context pc
           ON pc.politician_id = pa.politician_id
          AND pc.topic_id      = pa.topic_id
          AND pc.season_id     = pa.season_id
    GROUP BY s.geo_id
    `,
    [geoids]
  );
  await pool.end();

  const byGeoid = new Map(rows.map((r) => [r.geo_id, r]));

  const failures = [];
  const reports = [];
  const table = [];

  for (const e of entries) {
    const ids = e.geoids ?? [];
    const unresolved = ids.filter((g) => !byGeoid.has(g));
    const seated = new Set();
    const covered = new Set();
    for (const g of ids) {
      const r = byGeoid.get(g);
      if (!r) continue;
      for (const id of r.seated_ids ?? []) seated.add(id);
      for (const id of r.covered_ids ?? []) covered.add(id);
    }
    const name = `${e.label}, ${e.state}`;
    table.push({ name, kind: e.kind, purple: e.hasContext, seated: seated.size, covered: covered.size });

    if (unresolved.length) {
      reports.push({
        code: 'UNRESOLVED_GEOID',
        name,
        detail: `${unresolved.join(', ')} matches no essentials.governments row`,
      });
    }

    if (e.hasContext) {
      if (covered.size === 0) {
        failures.push({
          code: 'EMPTY_PURPLE',
          name,
          detail: `purple with ZERO covered officials (${seated.size} seated)`,
        });
      } else if (covered.size < MIN_COVERED_OFFICIALS_CITY) {
        const entry = {
          code: e.kind === 'city' ? 'ONE_OFFICIAL_CITY' : 'ONE_OFFICIAL_COUNTY',
          name,
          detail: `purple on ${covered.size} covered official of ${seated.size} seated`,
        };
        (e.kind === 'city' ? failures : reports).push(entry);
      }
    } else if (covered.size >= UNDERCLAIM_REPORT_AT) {
      reports.push({
        code: 'UNDERCLAIMED',
        name,
        detail: `grey while ${covered.size} of ${seated.size} seated officials hold rows — worth a look`,
      });
    }
  }

  const purple = table.filter((t) => t.purple);
  console.log(`Catalog: ${source}`);
  console.log(
    `  ${table.length} entries (${purple.length} purple), ${geoids.length} geoids, ` +
      `generated ${catalog.generatedAt ?? 'unknown'}`
  );

  if (VERBOSE) {
    for (const t of [...table].sort((a, b) => a.covered - b.covered || a.name.localeCompare(b.name))) {
      console.log(
        `  ${t.purple ? 'purple' : 'grey  '} ${String(t.covered).padStart(3)}/${String(t.seated).padEnd(4)} ${t.name}`
      );
    }
  }

  if (reports.length) {
    console.log(`\nREPORT ONLY — ${reports.length} item(s), not failing the build:`);
    for (const r of reports) console.log(`  ${r.code.padEnd(18)} ${r.name} — ${r.detail}`);
  }

  if (failures.length) {
    console.error(`\nFAIL — ${failures.length} chip(s) claim coverage the database does not hold:`);
    for (const f of failures) console.error(`  ${f.code.padEnd(18)} ${f.name} — ${f.detail}`);
    console.error(
      '\nFix in essentials src/lib/coverage.js: set hasContext false with a dated comment saying what\n' +
        'was measured, or research the place. Do not edit this check to make it pass.\n' +
        'The chip only changes here once the essentials deploy regenerates /coverage.json.'
    );
    process.exit(1);
  }

  console.log('\nOK — every purple chip is backed by at least two covered officials.');
  process.exit(0);
})().catch((err) => {
  console.error('check-coverage-honesty failed:', err);
  process.exit(1);
});
