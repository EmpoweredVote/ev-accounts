#!/usr/bin/env node
/**
 * check-entity-types — a live tripwire on the one contract this repo holds in
 * a constant and Treasury Tracker holds in a migration.
 *
 * 🔴 WHAT DRIFTS. `KNOWN_ENTITY_TYPES` (src/lib/entityTypes.ts) is the
 * whitelist `?entity_type=` validates against. Its authority is TT's
 * `municipalities_entity_type_check`, which lives in ANOTHER REPO's migration
 * and reaches prod BY HAND. Nothing in either repo's build can see both, so
 * the two can fall out of step with every test in both repos green.
 *
 * 🔴 WHY IT MATTERS, MEASURED. TT sends `CITY_TIER_TYPES` as ONE comma-
 * separated value, so a single unrecognised member 422s the WHOLE query and a
 * county's children panel renders EMPTY — indistinguishable from a coverage
 * gap. That is the PA-borough failure mode (TT PR #150: 949 boroughs and 253
 * villages invisible, 37.2% of PA county children hidden) reproduced across
 * the repo boundary. `borough` reached the constraint a whole release before
 * the lists that consume it.
 *
 * 🔴 WHY A LIVE CHECK, AND WHY NIGHTLY. Same reasoning as check-rls-coverage
 * and check-spatial-ref-baseline: the constraint changes when someone APPLIES
 * a TT migration, which happens on the CALENDAR, not on our commits — a push
 * here applies nothing. Reading the catalog is also the only faithful source;
 * parsing TT's migration text would report what was written, not what is in
 * force. The half that IS ours — the literal in entityTypes.ts — is pinned
 * on every push by check-entity-types.test.ts.
 *
 * 🔴 POSITIVE CONTROL (the project's rule for any detector that can report
 * "nothing found"). Both readers can fail by finding NOTHING — a renamed
 * constraint, a reshaped declaration — and two empty sets compare EQUAL. So an
 * empty read is an ERROR (exit 2), never a pass, and the constraint this finds
 * must actually be about `entity_type` before it is believed.
 *
 * Exit 0 = the two agree (or skipped). Exit 1 = they have drifted. Exit 2 = the
 * check could not read one of them and is therefore watching nothing.
 *
 * Usage:
 *   node scripts/check-entity-types.mjs
 */
import 'dotenv/config';
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Pool } from 'pg';

const HERE = path.dirname(fileURLToPath(import.meta.url));

/** The constraint that is the authority, and where the API's copy of it lives. */
const SCHEMA = 'treasury';
const TABLE = 'municipalities';
const CONSTRAINT = 'municipalities_entity_type_check';
const SOURCE_FILE = path.join(HERE, '..', 'src', 'lib', 'entityTypes.ts');

/**
 * The values inside `pg_get_constraintdef`'s rendering of the CHECK.
 *
 * ⚠ Postgres does not store what the migration wrote. `entity_type IN (...)`
 * on a varchar column comes back as
 * `CHECK (((entity_type)::text = ANY ((ARRAY['city'::character varying, ...])::text[])))`,
 * so this reads the quoted literals out of whatever form the catalog returns
 * rather than matching on `IN`. The casts (`::character varying`, `::text`)
 * carry no quotes, so they cannot be mistaken for values.
 */
export function parseConstraintValues(def) {
  if (!/\bentity_type\b/.test(def)) {
    throw new Error(
      `the constraint found is not about entity_type — refusing to compare the API ` +
      `against some other column's domain. Definition: ${def}`,
    );
  }
  const values = [...def.matchAll(/'([^']*)'/g)].map((m) => m[1]).filter((v) => v !== '');
  if (values.length === 0) {
    throw new Error(`no values could be read from ${CONSTRAINT}. Definition: ${def}`);
  }
  return values;
}

/**
 * The members of the `KNOWN_ENTITY_TYPES = new Set([...])` literal in `src`.
 *
 * ⚠⚠ COMMENTS ARE STRIPPED FIRST. An apostrophe in prose — Pennsylvania's, the
 * county's — opens a "string" to a naive sweep, which then returns a list of
 * roughly the right LENGTH made of comment fragments. A count check still
 * passes on that; only a value-level assertion catches it. (TT hit exactly this
 * while writing cityTierTypes.test.mjs.) The declaration this guards has three
 * such apostrophes in the block comment directly above it.
 */
export function parseSourceValues(src) {
  const code = src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '');
  const m = /KNOWN_ENTITY_TYPES[^=]*=\s*new Set\(\s*\[([\s\S]*?)\]/.exec(code);
  if (!m) {
    throw new Error(
      `KNOWN_ENTITY_TYPES is not a \`new Set([...])\` literal any more, so this check ` +
      `cannot read it. Reshaping that declaration means teaching this reader the new ` +
      `shape — a gate that cannot find its subject must go red, not green.`,
    );
  }
  const values = [...m[1].matchAll(/['"]([^'"]*)['"]/g)].map((v) => v[1]).filter((v) => v !== '');
  if (values.length === 0) {
    throw new Error('KNOWN_ENTITY_TYPES parsed to an empty set, which cannot be right.');
  }
  return values;
}

/**
 * The verdict. The two directions are NOT symmetric and are reported apart:
 * one blanks a panel in production, the other turns a typo into "no results".
 */
export function compare(constraintValues, sourceValues) {
  const inConstraint = new Set(constraintValues);
  const inSource = new Set(sourceValues);
  const rejectedByApi = [...inConstraint].filter((v) => !inSource.has(v)).sort();
  const unknownToDb = [...inSource].filter((v) => !inConstraint.has(v)).sort();

  if (rejectedByApi.length === 0 && unknownToDb.length === 0) {
    return {
      code: 0,
      message:
        `${CONSTRAINT} and KNOWN_ENTITY_TYPES hold the same ${inConstraint.size} types: ` +
        `${[...inConstraint].sort().join(', ')}.`,
    };
  }

  const parts = ['FAIL: the API whitelist and the CHECK constraint have drifted.\n'];
  if (rejectedByApi.length > 0) {
    parts.push(
      `  ⚠⚠ ${CONSTRAINT} permits ${rejectedByApi.length} type(s) the API REJECTS: ` +
      `${rejectedByApi.join(', ')}.\n` +
      '     This is the direction that breaks production. TT sends CITY_TIER_TYPES as ONE\n' +
      '     CSV, so a single unknown member 422s the whole query and a county children\n' +
      "     panel renders EMPTY — which reads as a coverage gap, not as a bug. Add it to\n" +
      '     KNOWN_ENTITY_TYPES in src/lib/entityTypes.ts (and to its test expectation).\n',
    );
  }
  if (unknownToDb.length > 0) {
    parts.push(
      `  ⚠ KNOWN_ENTITY_TYPES accepts ${unknownToDb.length} type(s) no row may hold: ` +
      `${unknownToDb.join(', ')}.\n` +
      '     ?entity_type= then answers 200 with an empty list where it should 422, so a\n' +
      '     typo reads as "there are no such places". Either remove it here, or land the\n' +
      '     TT migration that adds it to the constraint — in that order, not this one.\n',
    );
  }
  return { code: 1, message: parts.join('\n') };
}

async function run() {
  if (!process.env.DATABASE_URL) {
    console.log('SKIP: DATABASE_URL not set — this check needs a live database.');
    return 0;
  }

  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  try {
    const { rows } = await pool.query(
      `SELECT pg_get_constraintdef(c.oid) AS def
         FROM pg_constraint c
         JOIN pg_class t ON t.oid = c.conrelid
         JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = $1 AND t.relname = $2 AND c.conname = $3`,
      [SCHEMA, TABLE, CONSTRAINT],
    );
    if (rows.length === 0) {
      throw new Error(
        `${SCHEMA}.${TABLE} has no constraint named ${CONSTRAINT}. Either it was renamed ` +
        `or dropped — in both cases this check is watching nothing, and the API's ` +
        `whitelist now has no authority behind it.`,
      );
    }

    const constraintValues = parseConstraintValues(rows[0].def);
    const sourceValues = parseSourceValues(readFileSync(SOURCE_FILE, 'utf8'));
    const verdict = compare(constraintValues, sourceValues);
    if (verdict.code === 0) console.log(verdict.message);
    else console.error(verdict.message);
    return verdict.code;
  } finally {
    await pool.end();
  }
}

const invokedDirectly =
  process.argv[1] !== undefined &&
  path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);

if (invokedDirectly) {
  run()
    .then((code) => process.exit(code))
    .catch((err) => {
      console.error('FAIL: check-entity-types errored:', err.message);
      process.exit(2);
    });
}
