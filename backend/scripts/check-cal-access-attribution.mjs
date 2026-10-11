#!/usr/bin/env node
/**
 * check-cal-access-attribution.mjs — no NEW published CAL-ACCESS attribution without a trail.
 *
 * 🔴 THE DEFECT THIS EXISTS FOR. A `politician_sources` row that is `research_status='confirmed'`
 * is ON A VOTER'S PAGE: `campaignFinanceService.ts` reads own fundraising through
 * `confirmed AND source_type='candidate_committee'`, and outside spending through
 * `confirmed AND source_type='ie_committee'`. Measured on prod 2026-10-10, of the 518 confirmed
 * CAL-ACCESS sources publishing 260,653 contributions and $357,410,183:
 *
 *     387 on  94 politicians  written by `confirm-cal-access.ts`, the surname matcher
 *     105 on  59 politicians  no provenance at all
 *      15 on   8 politicians  flagged `--ambiguous` BY THAT SCRIPT and confirmed anyway
 *      11 on   3 politicians  carry an adjudication marker (CC_0214/0216/0218/0219)
 *
 * `confirm-cal-access.ts` matched committees to politicians BY SURNAME and confirmed its own
 * guesses in one pass. It produced the seven surname buckets that CC_0213-CC_0220 spent a week
 * unpicking — a bucket held 43 committees from at least seven different Hurtados, and a live
 * Assemblymember published nothing while $3.78M of hers sat on a dead row.
 *
 * 🔑 WHY A RATCHET AND NOT A CORRECTNESS TEST. **A name-based guard was tried first and does not
 * work.** Flagging a confirmed source whose committee name carries a forename conflicting with the
 * politician's flags 135 of 510, and every one sampled is a FALSE POSITIVE: "FRIENDS OF TED" on
 * Ted Lieu, "HOLLY J." on Holly J. Mitchell, "RE ELECT FIONA" on Fiona Ma, "FRIENDS OF" on Jose
 * Solache. That is the false trail CC_0213 already recorded: most CAL-ACCESS committees are
 * `SURNAME FOR OFFICE YEAR` with no forename, absence convicts nobody, and a forename inside a
 * phrase is not a conflict. Only CAL-ACCESS's own CANDIDATE page settles an attribution, and that
 * is a network call behind Incapsula — not a CI check.
 *
 * So this guard makes NO claim about whether an existing attribution is right. It says only:
 *
 *     a NEW confirmed CAL-ACCESS attribution must say who adjudicated it.
 *
 * The 518 that exist are grandfathered by key in the baseline. Anything else that becomes
 * `confirmed` must carry `adjudicated_by`, `published_by` or `verified_by` in its notes. It is a
 * ratchet, not a freeze: the baseline SHRINKS as the audit
 * (`.planning/todos/2026-10-10-cal-access-published-source-audit.md`) clears rows, and the check
 * reports that shrinkage so nobody has to notice it by hand.
 *
 * 🔴 THE BASELINE IS KEYED ON THE ATTRIBUTION, NOT THE ROW. `(politician_id, source_system,
 * external_id)` — the same triple as the UNIQUE index `idx_politician_source_system_extid`.
 * A row id would be the wrong key: CC_0216 and CC_0218 moved sources BETWEEN politicians keeping
 * their ids, so a row-id baseline would silently grandfather a brand-new attribution.
 *
 * Usage:
 *   node backend/scripts/check-cal-access-attribution.mjs                 # check (exit 1 on a violation)
 *   node backend/scripts/check-cal-access-attribution.mjs --write-baseline
 *
 * Skips green with no DATABASE_URL, like the other live-DB checks, so forks pass.
 */

import 'dotenv/config';
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
export const BASELINE_PATH = path.join(HERE, '..', 'data', 'cal-access-attribution-baseline.json');

/** The source system this guard covers. Others have their own provenance stories. */
const GUARDED_SYSTEM = 'cal_access';

/**
 * A marker naming who adjudicated an attribution. Matched as a JSON KEY, deliberately:
 * notes are not always valid JSON — appended text like `{...} | UNVERIFIED … | DISPUTED …` breaks
 * a `::jsonb` cast — so the test is textual, and keying on `"name":` keeps the word "adjudicated"
 * in prose from passing.
 */
const MARKER = /"(?:adjudicated_by|published_by|verified_by)"\s*:/;

export const keyOf = (r) => `${r.politician_id}|${r.source_system}|${r.external_id}`;

export const hasAdjudicationMarker = (notes) =>
  typeof notes === 'string' && MARKER.test(notes);

/**
 * findViolations returns the confirmed CAL-ACCESS attributions that are neither grandfathered
 * nor adjudicated. A non-confirmed row publishes nothing and is never a violation.
 */
export function findViolations(rows, baseline) {
  return rows.filter(
    (r) =>
      r.source_system === GUARDED_SYSTEM &&
      r.research_status === 'confirmed' &&
      !baseline.has(keyOf(r)) &&
      !hasAdjudicationMarker(r.notes)
  );
}

/** Baseline keys that no longer name a confirmed attribution — the ratchet turning. */
export function findCleared(rows, baseline) {
  const live = new Set(
    rows
      .filter((r) => r.source_system === GUARDED_SYSTEM && r.research_status === 'confirmed')
      .map(keyOf)
  );
  return [...baseline].filter((k) => !live.has(k));
}

export function loadBaseline(file = BASELINE_PATH) {
  try {
    const parsed = JSON.parse(readFileSync(file, 'utf8'));
    return new Set(parsed.keys ?? []);
  } catch (e) {
    if (e.code === 'ENOENT') return new Set();
    throw e;
  }
}

const SQL = `
  SELECT s.id, s.essentials_politician_id AS politician_id, p.full_name AS politician_name,
         s.source_system, s.external_id, s.research_status, s.source_type, s.notes
    FROM transparent_motivations.politician_sources s
    JOIN essentials.politicians p ON p.id = s.essentials_politician_id
   WHERE s.source_system = $1 AND s.research_status = 'confirmed'`;

async function main() {
  const writing = process.argv.includes('--write-baseline');

  const url = process.env.DATABASE_URL?.trim();
  if (!url) {
    console.log(
      'cal-access attribution: DATABASE_URL is not set — skipping.\n' +
        '  This is a live-DB check; a fork has no credentials and is not expected to run it.'
    );
    return 0;
  }

  const { default: pg } = await import('pg');
  const pool = new pg.Pool({ connectionString: url, ssl: { rejectUnauthorized: false } });
  let rows;
  try {
    rows = (await pool.query(SQL, [GUARDED_SYSTEM])).rows;
  } finally {
    await pool.end();
  }

  if (writing) {
    const keys = rows.map(keyOf).sort();
    writeFileSync(
      BASELINE_PATH,
      `${JSON.stringify(
        {
          note:
            'Grandfathered CAL-ACCESS attributions, keyed (politician_id|source_system|external_id). ' +
            'These are NOT vouched for — most were written by confirm-cal-access.ts, the surname ' +
            'matcher. The guard only requires that anything NEW says who adjudicated it. Shrink this ' +
            'list as the audit clears rows; never grow it by hand.',
          generated_at: new Date().toISOString().slice(0, 10),
          count: keys.length,
          keys,
        },
        null,
        2
      )}\n`
    );
    console.log(`cal-access attribution: wrote ${keys.length} grandfathered keys to ${BASELINE_PATH}`);
    return 0;
  }

  const baseline = loadBaseline();
  const violations = findViolations(rows, baseline);
  const cleared = findCleared(rows, baseline);

  if (cleared.length > 0) {
    console.log(
      `cal-access attribution: ${cleared.length} grandfathered attribution(s) are no longer ` +
        'confirmed — the ratchet turned. Re-run with --write-baseline to bank it.'
    );
  }

  if (violations.length === 0) {
    console.log(
      `cal-access attribution OK — ${rows.length} confirmed source(s), ` +
        `${baseline.size} grandfathered, 0 unexplained.`
    );
    return 0;
  }

  console.error(
    `\n🔴 ${violations.length} CAL-ACCESS source(s) are CONFIRMED — and so publishing on a ` +
      'politician page — with neither a baseline entry nor a note saying who adjudicated them.\n'
  );
  for (const v of violations) {
    const committee = /"committee_name"\s*:\s*"([^"]*)"/.exec(v.notes ?? '')?.[1] ?? '(no committee name)';
    console.error(`  ${v.politician_name}  <-  ${committee}`);
    console.error(`      filer ${v.external_id} · ${v.source_type} · source ${v.id}`);
  }
  console.error(
    '\nConfirming a CAL-ACCESS committee onto a politician is a claim that the committee is theirs.\n' +
      "Settle it against CAL-ACCESS's own CANDIDATE page — /Campaign/Candidates/list.aspx?view=name\n" +
      '&letter=<X> lists a candidate, and their page lists the committees they control, by filer id.\n' +
      'The committee page never names the candidate; reasoning from it is what built the buckets.\n' +
      'Then record the finding in the row\'s notes as "adjudicated_by" / "adjudication".\n' +
      'Method and traps: .planning/todos/2026-10-10-cal-access-published-source-audit.md\n'
  );
  return 1;
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  main()
    .then((code) => process.exit(code))
    .catch((err) => {
      console.error('cal-access attribution: FAILED TO RUN:', err?.message ?? err);
      process.exit(1);
    });
}
