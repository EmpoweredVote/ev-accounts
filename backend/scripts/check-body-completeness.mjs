#!/usr/bin/env node
/**
 * Fail if a body's stated size disagrees with the offices we hold for it, or if a district
 * holds no office at all.
 *
 * WHY THIS EXISTS. Three defects in three days, none of which any existing guard could see:
 *
 *   CC_0427  Bangor ME published a `Mayor` that its charter does not create — the council
 *            picks a chair. 8 At-Large + Mayor = 9 = its own official_count, every seat held
 *            by a different person, so every count in the repo agreed with every other one.
 *   CC_0428  South Portland ME held 8 council offices against a charter that says 7. Its
 *            official_count was also 8 — copied from the rows it was meant to check — so the
 *            size CONFIRMED the defect instead of catching it. The number that separates this
 *            case from Bangor's is count(DISTINCT politician_id): 7 people in 8 seats, because
 *            the mayor row and District 5 are the same woman. Nothing computes that.
 *   CC_0429  Lewiston ME's school committee is NINE by charter and we hold EIGHT. The ninth is
 *            a city councillor the council appoints. Nothing was short of anything a gate read,
 *            so the missing seat was invisible until somebody read the charter.
 *
 * And one gap that is bigger than all three and that no gate in this repo can express:
 *
 *   R9k      Maine has no county government at all. All 16 counties are districts with
 *            polygons and ZERO offices. `DEAD_GEOGRAPHY` requires offices > 0, so a district
 *            with none is not a finding; `offices_missing_terms` starts FROM offices, so no
 *            office means no row; the drift baseline therefore cannot move. An office with no
 *            race is invisible rather than incomplete (CLAUDE.md) — a DISTRICT WITH NO OFFICE
 *            is invisible the same way, one level up.
 *
 * WHAT IS CHECKED
 *
 *   CHAMBER_SIZE_MISMATCH   chambers.official_count states a size and our office rows disagree.
 *                           Keyed state|direction, because the two directions need OPPOSITE
 *                           fixes: `too_many` is South Portland (delete, or the rows are
 *                           duplicates), `too_few` is Lewiston (research and seat).  [baselined]
 *   DISTRICT_WITHOUT_OFFICE district carries no office at all — nothing a resident can reach,
 *                           and nothing any occupancy metric counts.      [baselined]
 *
 * 🔴 `official_count = 0` IS "NOBODY SET THIS", NOT "THIS BODY HAS NO MEMBERS". 296 chambers
 * carry it, including Indiana township boards holding three offices each; 652 more are NULL.
 * Read as a size, the zero turns all 296 into `too_many` and the gate reports 307 findings
 * where 19 are real — which is a gate people switch off. Both are excluded from the predicate
 * and reported as a COVERAGE number instead, because "948 of 1,462 chambers state no size" is
 * the honest limit of what this check can see, and hiding it would overstate the green.
 *
 * ⚠ THE STATE KEY IS NOT NORMALISED, ON PURPOSE. Two Massachusetts districts carry `25` — the
 * FIPS code — where every other row carries USPS, so they bucket as `25|LOCAL` and `25|SCHOOL`.
 * Mapping 25 → ma here would launder exactly the kind of defect this gate exists to surface.
 * Federal chambers have no state and bucket as `us`.
 *
 * ⚠ WHY THIS IS BASELINED AND NOT ZERO. 19 chamber mismatches and 3,207 office-less districts
 * exist today. Failing red on day one would only train people to ignore this — the same
 * reasoning check-address-reachability.mjs records. The baseline is per bucket, so the gate
 * fires on GROWTH in a known bucket or on ANY NEW bucket. That is what makes an unseeded state
 * sit still (Maine's 16 counties stay in me|COUNTY) while a wave that creates an unseated
 * office fires immediately.
 *
 * 🔴 A MASTER-ONLY GATE CANNOT VET THE MERGE THAT TRIPS IT (CLAUDE.md). This runs after the
 * merge, so it fails on the NEXT PR and names an innocent author. A migration that creates
 * offices or districts should carry the delta check in its own post-verify:
 * see backend/migrations/_templates/body_completeness_delta.sql.
 *
 * Needs a live DB, so this does NOT run on every PR. It rides the `address-search reachability`
 * job in .github/workflows/ci.yml — master pushes and the nightly schedule — and skips itself
 * (exit 0) when DATABASE_URL is absent, as forks have no secrets.
 *
 * Usage:
 *   node scripts/check-body-completeness.mjs
 *   node scripts/check-body-completeness.mjs --verbose           # list every offending row
 *   node scripts/check-body-completeness.mjs --selftest          # plant a tamper, watch it go red
 *   node scripts/check-body-completeness.mjs --update-baseline
 */
import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

/** The two checks, named so the baseline file and the failure output agree. */
export const CHECKS = ['CHAMBER_SIZE_MISMATCH', 'DISTRICT_WITHOUT_OFFICE'];

/**
 * Does this chamber's stated size disagree with the offices we hold?
 *
 * Returns 'too_many' (we hold offices the body does not have), 'too_few' (the body has seats
 * we do not hold), or null for agreement AND for every chamber that states no size.
 *
 * 🔴 NULL and 0 both mean "unset". See the header: the zero is a sentinel, not a count.
 */
export function classifyChamber({ official_count: stated, offices }) {
  if (stated === null || stated === undefined) return null;
  const size = Number(stated);
  if (!Number.isFinite(size) || size <= 0) return null;
  const held = Number(offices);
  if (held === size) return null;
  return held > size ? 'too_many' : 'too_few';
}

/** The state key a bucket is filed under. Not normalised beyond case — see the header. */
function stateKey(state) {
  const trimmed = (state ?? '').trim().toLowerCase();
  return trimmed === '' ? 'us' : trimmed;
}

/**
 * Group offending rows into the buckets the baseline is keyed on.
 *
 * `kind` is 'chamber' (keyed state|direction) or 'district' (keyed state|district_type).
 * Chamber rows that do not offend are skipped here rather than by the caller, so the
 * classification lives in exactly one place.
 */
export function bucketCounts(rows, kind) {
  const counts = {};
  for (const row of rows) {
    let key;
    if (kind === 'chamber') {
      const direction = classifyChamber(row);
      if (!direction) continue;
      key = `${stateKey(row.state)}|${direction}`;
    } else {
      key = `${stateKey(row.state)}|${row.district_type}`;
    }
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

/**
 * Which buckets are over their allowance.
 *
 * A bucket absent from the baseline has an allowance of 0, so ANY new bucket fires. That is
 * the half that catches a wave seeding a jurisdiction nobody has baselined. A bucket that has
 * SHRUNK is silent — the backlog being worked off is not a failure.
 */
export function compareToBaseline(found, baseline) {
  const over = [];
  for (const bucket of Object.keys(found).sort()) {
    const allowed = baseline[bucket] ?? 0;
    if (found[bucket] > allowed) {
      over.push({ bucket, found: found[bucket], allowed });
    }
  }
  return over;
}

/**
 * 🔴 AN EMPTY READ MUST NOT COMPARE EQUAL TO A CLEAN ONE.
 *
 * If the query returns nothing — a renamed column, a dropped view, a connection to the wrong
 * database — then "no violations" and "nothing was examined" are the same answer. A control
 * proves a verifier CAN fail; it does not prove the verifier read the RIGHT ROWS. The count it
 * actually examined is what separates those, so it is asserted rather than assumed.
 */
export function assertPopulationRead(count, noun) {
  if (!Number.isFinite(count) || count <= 0) {
    throw new Error(
      `BROKEN DETECTOR: examined 0 ${noun}. A gate that reads nothing reports clean, so this ` +
        'is a failure rather than a pass. Check the connection and the query.',
    );
  }
}

/* ------------------------------------------------------------------ the live half ---- */

const HERE = path.dirname(fileURLToPath(import.meta.url));
const BASELINE = path.join(HERE, '..', 'data', 'body-completeness-baseline.json');

const argv = process.argv.slice(2);
const VERBOSE = argv.includes('--verbose');
const UPDATE = argv.includes('--update-baseline');
const SELFTEST = argv.includes('--selftest');

/**
 * Every chamber, not just the offending ones. The coverage line needs the whole population,
 * and `assertPopulationRead` needs a number that a broken query cannot fake.
 *
 * `distinct_people` is reported rather than used. It is the number that separates Bangor from
 * South Portland — 9 offices/9 people wanted a retitle, 8 offices/7 people wanted a delete —
 * and an operator reading a `too_many` finding needs it to know which fix applies.
 */
const CHAMBER_SQL = `
  SELECT ch.id,
         ch.name,
         ch.official_count,
         COALESCE(NULLIF(trim(g.state), ''), '') AS state,
         g.name AS government,
         (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id) AS offices,
         (SELECT count(DISTINCT t.politician_id)
            FROM essentials.offices o
            JOIN essentials.office_terms t ON t.office_id = o.id
           WHERE o.chamber_id = ch.id AND t.politician_id IS NOT NULL) AS distinct_people
    FROM essentials.chambers ch
    LEFT JOIN essentials.governments g ON g.id = ch.government_id
`;

/** Districts carrying no office at all. `NOT EXISTS` rather than a LEFT JOIN count: same
 *  answer, and it cannot be accidentally weakened by a later join fanning rows out. */
const OFFICELESS_DISTRICT_SQL = `
  SELECT d.id, d.label, d.district_type, d.state, d.geo_id
    FROM essentials.districts d
   WHERE NOT EXISTS (SELECT 1 FROM essentials.offices o WHERE o.district_id = d.id)
   ORDER BY d.state, d.district_type, d.label
`;

const DISTRICT_POPULATION_SQL = 'SELECT count(*)::int AS n FROM essentials.districts';

function loadBaseline() {
  try {
    const raw = JSON.parse(readFileSync(BASELINE, 'utf8'));
    return raw.counts ?? {};
  } catch (err) {
    if (err.code === 'ENOENT') return {};
    throw err;
  }
}

/** How many chambers this check can see at all. Reported, never silently folded into green. */
function coverage(chambers) {
  const unset = chambers.filter(
    (c) => c.official_count === null || Number(c.official_count) === 0,
  ).length;
  return { unset, total: chambers.length, stated: chambers.length - unset };
}

function describeChamber(row) {
  const direction = classifyChamber(row);
  return (
    `    ${stateKey(row.state)}  ${row.government ?? '(no government)'} — ${row.name}: ` +
    `states ${row.official_count}, we hold ${row.offices} offices ` +
    `(${row.distinct_people} distinct people) [${direction}]`
  );
}

function describeDistrict(row) {
  return `    ${stateKey(row.state)}  ${row.district_type}  ${row.label} (geo_id ${row.geo_id ?? 'NULL'})`;
}

/** Run both checks against an open client. Returns the per-check buckets and the raw rows. */
async function detect(client) {
  const chambers = (await client.query(CHAMBER_SQL)).rows;
  assertPopulationRead(chambers.length, 'chambers');

  const officeless = (await client.query(OFFICELESS_DISTRICT_SQL)).rows;
  const districtTotal = (await client.query(DISTRICT_POPULATION_SQL)).rows[0].n;
  assertPopulationRead(districtTotal, 'districts');

  return {
    counts: {
      CHAMBER_SIZE_MISMATCH: bucketCounts(chambers, 'chamber'),
      DISTRICT_WITHOUT_OFFICE: bucketCounts(officeless, 'district'),
    },
    rows: {
      CHAMBER_SIZE_MISMATCH: chambers.filter((c) => classifyChamber(c) !== null),
      DISTRICT_WITHOUT_OFFICE: officeless,
    },
    coverage: coverage(chambers),
    districtTotal,
  };
}

/**
 * 🔴 THE POSITIVE CONTROL, AND IT IS WATCHED FAILING BEFORE IT IS TRUSTED.
 *
 * A uniform answer is a broken detector until a control passes (CLAUDE.md), and a control that
 * has only ever passed proves nothing. So each tamper is:
 *
 *   1. planted inside a transaction,
 *   2. ASSERTED PRESENT by re-reading the row — a tamper that did not apply is a control that
 *      proved nothing, and it looks exactly like a pass,
 *   3. fed to the SAME detector the gate uses, which must now report a bucket it did not
 *      report before,
 *   4. rolled back, and the rollback itself verified.
 *
 * One tamper per transaction, because a tamper that trips two checks at once tells you the
 * suite is alive but not which guard holds which claim.
 *
 * Each tamper deliberately creates a NEW bucket in a state that has none, so it tests the
 * "any new bucket fires" half rather than growth inside a bucket that is already red.
 */
async function selftest(pool) {
  const results = [];

  // ---- Tamper 1: a chamber that agrees is made to disagree. -----------------------------
  {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const before = await detect(client);
      const victim = (
        await client.query(`
          SELECT ch.id, ch.name, ch.official_count, lower(g.state) AS state,
                 (SELECT count(*)::int FROM essentials.offices o WHERE o.chamber_id = ch.id) AS offices
            FROM essentials.chambers ch JOIN essentials.governments g ON g.id = ch.government_id
           WHERE ch.official_count > 0
             AND ch.official_count = (SELECT count(*) FROM essentials.offices o WHERE o.chamber_id = ch.id)
             AND lower(g.state) = 'wi'
           ORDER BY ch.id LIMIT 1
        `)
      ).rows[0];
      if (!victim) throw new Error('SELFTEST: found no agreeing Wisconsin chamber to tamper with.');
      const bucket = 'wi|too_few';
      if (before.counts.CHAMBER_SIZE_MISMATCH[bucket]) {
        throw new Error(`SELFTEST: ${bucket} already exists, so this tamper would prove nothing.`);
      }

      await client.query('UPDATE essentials.chambers SET official_count = $2 WHERE id = $1', [
        victim.id,
        victim.offices + 1,
      ]);

      // (2) ASSERT THE TAMPER IS PRESENT. A failed UPDATE is silent.
      const planted = (
        await client.query('SELECT official_count FROM essentials.chambers WHERE id = $1', [victim.id])
      ).rows[0];
      if (Number(planted.official_count) !== victim.offices + 1) {
        throw new Error('SELFTEST: the tamper did not apply; this control proves nothing.');
      }

      const after = await detect(client);
      const fired = compareToBaseline(after.counts.CHAMBER_SIZE_MISMATCH, before.counts.CHAMBER_SIZE_MISMATCH);
      const hit = fired.find((f) => f.bucket === bucket);
      results.push({
        check: 'CHAMBER_SIZE_MISMATCH',
        tamper: `${victim.name} (wi) official_count ${victim.official_count} -> ${victim.offices + 1}`,
        red: Boolean(hit),
      });

      await client.query('ROLLBACK');
      const reverted = (
        await client.query('SELECT official_count FROM essentials.chambers WHERE id = $1', [victim.id])
      ).rows[0];
      if (Number(reverted.official_count) !== Number(victim.official_count)) {
        throw new Error('SELFTEST: ROLLBACK did not revert the tamper. Investigate before trusting this.');
      }
    } finally {
      client.release();
    }
  }

  // ---- Tamper 2: a district with no office is created. ----------------------------------
  {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const before = await detect(client);
      const bucket = 'zz|COUNTY';
      if (before.counts.DISTRICT_WITHOUT_OFFICE[bucket]) {
        throw new Error(`SELFTEST: ${bucket} already exists, so this tamper would prove nothing.`);
      }

      const planted = (
        await client.query(`
          INSERT INTO essentials.districts (label, district_type, state, geo_id)
          VALUES ('SELFTEST throwaway district', 'COUNTY', 'zz', 'selftest')
          RETURNING id
        `)
      ).rows[0];
      if (!planted?.id) throw new Error('SELFTEST: the district tamper did not apply.');

      const after = await detect(client);
      const fired = compareToBaseline(
        after.counts.DISTRICT_WITHOUT_OFFICE,
        before.counts.DISTRICT_WITHOUT_OFFICE,
      );
      const hit = fired.find((f) => f.bucket === bucket);
      results.push({
        check: 'DISTRICT_WITHOUT_OFFICE',
        tamper: 'inserted one office-less COUNTY district in state zz',
        red: Boolean(hit),
      });

      await client.query('ROLLBACK');
      const survivor = await client.query('SELECT 1 FROM essentials.districts WHERE id = $1', [planted.id]);
      if (survivor.rowCount !== 0) {
        throw new Error('SELFTEST: ROLLBACK did not remove the planted district. Investigate immediately.');
      }
    } finally {
      client.release();
    }
  }

  console.log('SELFTEST — each tamper planted, asserted present, then rolled back:\n');
  for (const r of results) {
    console.log(`  ${r.red ? 'RED (correct)  ' : 'GREEN (BROKEN) '} ${r.check}: ${r.tamper}`);
  }
  const blind = results.filter((r) => !r.red);
  if (blind.length > 0) {
    console.error(
      `\nFAIL: ${blind.length} check(s) stayed green against a planted fault. ` +
        'The gate is not watching what it claims to watch.',
    );
    return 1;
  }
  console.log('\nBoth checks went red against a planted fault and green again after rollback.');
  return 0;
}

async function main() {
  if (!process.env.DATABASE_URL) {
    console.log('check:body-completeness: no DATABASE_URL, skipping (forks get no secrets).');
    return 0;
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  try {
    if (SELFTEST) return await selftest(pool);

    const client = await pool.connect();
    let found;
    try {
      found = await detect(client);
    } finally {
      client.release();
    }

    if (UPDATE) {
      const previous = (() => {
        try {
          return JSON.parse(readFileSync(BASELINE, 'utf8'));
        } catch {
          return {};
        }
      })();
      writeFileSync(
        BASELINE,
        `${JSON.stringify(
          {
            _comment: previous._comment ?? 'Baseline for check-body-completeness.mjs.',
            _updated: new Date().toISOString().slice(0, 10),
            counts: found.counts,
          },
          null,
          2,
        )}\n`,
      );
      console.log(`Wrote ${BASELINE}`);
      return 0;
    }

    const baseline = loadBaseline();
    const cov = found.coverage;
    console.log(
      `Chambers: ${cov.total} total, ${cov.stated} state a size, ${cov.unset} do not ` +
        `(NULL or the 0 sentinel) — this check is blind to those ${cov.unset}.`,
    );
    console.log(`Districts: ${found.districtTotal} total, ${found.rows.DISTRICT_WITHOUT_OFFICE.length} hold no office.\n`);

    let failed = false;
    for (const check of CHECKS) {
      const over = compareToBaseline(found.counts[check], baseline[check] ?? {});
      const total = Object.values(found.counts[check]).reduce((a, b) => a + b, 0);
      if (over.length === 0) {
        console.log(`  OK    ${check}: ${total} within baseline`);
      } else {
        failed = true;
        console.log(`  FAIL  ${check}: ${total} found, ${over.length} bucket(s) over allowance`);
        for (const o of over) {
          console.log(`          ${o.bucket}: found ${o.found}, allowed ${o.allowed}`);
        }
      }
      if (VERBOSE) {
        const describe = check === 'CHAMBER_SIZE_MISMATCH' ? describeChamber : describeDistrict;
        for (const row of found.rows[check]) console.log(describe(row));
      }
    }

    if (failed) {
      console.error(
        '\nFAIL: a body-completeness bucket grew, or a new one appeared.\n' +
          'A `too_many` chamber is South Portland\'s shape — compare offices against DISTINCT people\n' +
          'before deleting. A `too_few` is Lewiston\'s — the seat exists and we do not hold it.\n' +
          'A new DISTRICT_WITHOUT_OFFICE bucket means a district was created with nothing in it.\n' +
          'If the growth is correct and sourced, run --update-baseline and say why in the commit.',
      );
      return 1;
    }
    console.log('\nPASS');
    return 0;
  } finally {
    await pool.end();
  }
}

const invokedDirectly =
  process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (invokedDirectly) {
  main()
    .then((code) => process.exit(code))
    .catch((err) => {
      console.error(err);
      process.exit(1);
    });
}
