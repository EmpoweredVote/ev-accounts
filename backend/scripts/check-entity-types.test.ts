import { describe, it, expect } from 'vitest';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  parseConstraintValues,
  parseSourceValues,
  compare,
} from './check-entity-types.mjs';

/**
 * The guard's two halves are pure and tested here directly; the subprocess case
 * at the bottom covers the one behaviour that only exists end-to-end (skipping
 * green with no DATABASE_URL, as forks and manual runs hit it).
 *
 * ⚠⚠ WHAT MUST NEVER PASS SILENTLY. Both readers can fail by finding NOTHING —
 * a renamed constraint, a reshaped declaration — and "no values found" compares
 * equal to "no values found". That is a green check watching nothing, so each
 * reader THROWS on an empty read rather than returning [].
 */

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.join(HERE, 'check-entity-types.mjs');
const ENTITY_TYPES_TS = path.join(HERE, '..', 'src', 'lib', 'entityTypes.ts');

/** The fourteen, as of TT migration 20260903000000_pa_borough_entity_type.sql. */
const FOURTEEN = [
  'borough', 'city', 'conservancy', 'county', 'federal', 'library',
  'municipality', 'nonprofit', 'school_district', 'special_district', 'state',
  'town', 'township', 'village',
];

describe('reading the CHECK constraint', () => {
  it('reads the ANY(ARRAY[...]) form Postgres stores for a varchar column', () => {
    // This is what pg_get_constraintdef actually returns — Postgres rewrites
    // `IN (...)` and adds a cast per element. Parsing the migration's own
    // `IN (...)` text would not survive contact with the catalog.
    const def =
      "CHECK ((((entity_type)::text = ANY ((ARRAY['city'::character varying, " +
      "'county'::character varying, 'town'::character varying])::text[]))))";
    expect(parseConstraintValues(def)).toEqual(['city', 'county', 'town']);
  });

  it('reads the plain IN (...) form too', () => {
    const def = "CHECK ((entity_type IN ('city'::text, 'county'::text)))";
    expect(parseConstraintValues(def)).toEqual(['city', 'county']);
  });

  it('throws rather than reporting an empty set when it recognises no values', () => {
    expect(() => parseConstraintValues('CHECK ((entity_type IS NOT NULL))')).toThrow(/no values/i);
  });

  it('throws when handed a constraint that is not about entity_type', () => {
    // The positive control: if the query ever returns the wrong constraint, the
    // check must error, not compare the API against some other column's domain.
    const def = "CHECK (((basis)::text = ANY ((ARRAY['cash'::character varying])::text[])))";
    expect(() => parseConstraintValues(def)).toThrow(/entity_type/);
  });
});

describe('reading KNOWN_ENTITY_TYPES out of the TypeScript source', () => {
  it('extracts exactly the declared members', () => {
    const src = [
      "export const KNOWN_ENTITY_TYPES: ReadonlySet<string> = new Set([",
      "  'city', 'county',",
      "  'town',",
      "]);",
    ].join('\n');
    expect(parseSourceValues(src)).toEqual(['city', 'county', 'town']);
  });

  it('reads the live declaration, not a commented-out older one above it', () => {
    // ⚠⚠ THE COMMENT IS NOT THE CODE. A superseded declaration left in a
    // comment — and prose apostrophes: the county's, TT's — is how a reader of
    // SOURCE returns a list of the right SHAPE and the wrong CONTENT. It fails
    // green: the count is plausible, so only a value-level assertion sees it.
    // (TT hit the apostrophe half of this while writing cityTierTypes.test.mjs.)
    const src = [
      '/**',
      " * Was `new Set(['city'])` before the county's types landed — see TT's",
      ' * migration 20260903000000.',
      ' */',
      "// export const KNOWN_ENTITY_TYPES = new Set(['city']);",
      'export const KNOWN_ENTITY_TYPES: ReadonlySet<string> = new Set([',
      "  'city', 'county',",
      ']);',
    ].join('\n');
    expect(parseSourceValues(src)).toEqual(['city', 'county']);
  });

  it('throws when the declaration has been reshaped', () => {
    // A gate that cannot find its subject must go red, not green.
    const src = 'export const KNOWN_ENTITY_TYPES = buildSet(await loadTypes());';
    expect(() => parseSourceValues(src)).toThrow(/KNOWN_ENTITY_TYPES/);
  });

  it('throws when the declaration is absent entirely', () => {
    expect(() => parseSourceValues('export const nothing = 1;')).toThrow(/KNOWN_ENTITY_TYPES/);
  });

  it('reads the real entityTypes.ts as the fourteen types', () => {
    // Pins the live file, so a reshape or an edit is caught on push by this
    // test even though the DB half only runs nightly.
    const src = readFileSync(ENTITY_TYPES_TS, 'utf8');
    expect(parseSourceValues(src).sort()).toEqual(FOURTEEN);
  });
});

describe('comparing the two', () => {
  it('passes when they hold the same types in a different order', () => {
    const r = compare(['city', 'county'], ['county', 'city']);
    expect(r.code).toBe(0);
  });

  it('fails NAMING the type the constraint allows and the API would reject', () => {
    const r = compare(['city', 'parish'], ['city']);
    expect(r.code).toBe(1);
    expect(r.message).toMatch(/parish/);
    // The consequence has to be in the message: this direction is the one that
    // 422s a whole CSV and blanks a county's children panel.
    expect(r.message).toMatch(/422/);
  });

  it('fails NAMING the type the API accepts and no row may hold', () => {
    const r = compare(['city'], ['city', 'hamlet']);
    expect(r.code).toBe(1);
    expect(r.message).toMatch(/hamlet/);
  });

  it('reports both directions in one run', () => {
    const r = compare(['city', 'parish'], ['city', 'hamlet']);
    expect(r.code).toBe(1);
    expect(r.message).toMatch(/parish/);
    expect(r.message).toMatch(/hamlet/);
  });
});

describe('the script as CI runs it', () => {
  it('skips green when DATABASE_URL is absent', () => {
    // Run from an empty dir so `dotenv/config` cannot find a local .env and
    // hand the check a database this test never asked for.
    const dir = mkdtempSync(path.join(tmpdir(), 'entitytypes-'));
    try {
      const env = { ...process.env };
      delete env.DATABASE_URL;
      const r = spawnSync('node', [SCRIPT], { cwd: dir, encoding: 'utf8', env });
      expect(`${r.stdout}${r.stderr}`).toMatch(/SKIP/);
      expect(r.status).toBe(0);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
