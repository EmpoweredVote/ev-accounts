/**
 * Architecture test: coordinate leakage guard
 *
 * Static analysis scan of all route source files. Asserts that raw coordinate
 * column names (encrypted_lat, encrypted_lng) and lat/lng object keys never
 * appear in route files — preventing accidental leakage of coordinate data
 * into API responses or logs.
 *
 * This test runs as part of `npm test` in CI. Any violation fails the build
 * with a description of which file and pattern was matched.
 */

import { describe, it, expect } from 'vitest';
import * as path from 'path';
import { fileURLToPath } from 'url';
import { listSourceFiles, readCode } from '../helpers/sourceScan.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Resolve from tests/architecture/ → project root → backend/src/routes/
const ROUTES_DIR = path.resolve(__dirname, '../../backend/src/routes');

/**
 * Existence checks are the sanctioned way to expose "do we hold coordinates for
 * this user?" without exposing the coordinates: the column appears only inside a
 * NULL test whose projected value is a boolean. Used by connect.ts and
 * essentials.ts as `(encrypted_lat IS NOT NULL) AS has_coords`.
 *
 * Neutralising the idiom before scanning keeps the guard meaningful — a bare
 * `SELECT encrypted_lat` still fails.
 */
const SAFE_EXISTENCE_CHECK = /encrypted_(lat|lng)\s+IS\s+(NOT\s+)?NULL/gi;

/**
 * Forbidden patterns and their descriptions.
 *
 * Pattern notes:
 * - encrypted_lat / encrypted_lng: database column names that must never appear
 *   in a SELECT list or response object. Presence indicates raw encrypted bytes
 *   being returned to the client.
 * - \blat\s*: / \blng\s*: : object literal keys in a response shape. Matches
 *   `lat:` or `lng:` as property keys (with optional whitespace before colon).
 *   Negative lookahead excludes TypeScript type annotations (`lat: number`,
 *   `lng: string`, etc.) which are safe and common in route files.
 *   Does NOT match `p_lat:` (underscore before is a word char, breaks \b boundary).
 */
const FORBIDDEN_PATTERNS = [
  {
    pattern: /encrypted_lat/,
    description: 'encrypted_lat column reference',
  },
  {
    pattern: /encrypted_lng/,
    description: 'encrypted_lng column reference',
  },
  {
    // Matches `lat:` as an object value key but excludes TS type annotations.
    // Safe forms: `lat: number` / `lat: number,` / `lat: number)` / `lat: number;`
    // Leakage form: `{ lat: someValue }` — coordinate in a response object.
    // Does NOT match `p_lat:` (underscore before `lat` is a word char, \b does not match).
    pattern: /\blat\s*:(?!\s*(number|string|boolean|unknown|any|never|null|undefined)[,\s\);>])/,
    description: 'lat as object key (e.g. { lat: value }) — coordinate leakage in response shape',
  },
  {
    pattern: /\blng\s*:(?!\s*(number|string|boolean|unknown|any|never|null|undefined)[,\s\);>])/,
    description: 'lng as object key (e.g. { lng: value }) — coordinate leakage in response shape',
  },
];

describe('Architecture: coordinate leakage', () => {
  // Shipped route source only, comments stripped — test files carry request
  // fixtures like `.send({ lat, lng })` that are inputs, not leaked responses.
  const routeFiles = listSourceFiles(ROUTES_DIR, false);

  it('should have route files to scan', () => {
    expect(routeFiles.length).toBeGreaterThan(0);
  });

  for (const filePath of routeFiles) {
    const fileName = path.basename(filePath);
    const content = readCode(filePath).replace(SAFE_EXISTENCE_CHECK, 'has_coords_check');

    for (const { pattern, description } of FORBIDDEN_PATTERNS) {
      it(`${fileName}: must not contain "${description}"`, () => {
        const match = content.match(pattern);
        expect(
          match,
          `Violation in ${fileName}: found "${description}"\nPattern: ${pattern}\nMatch: ${match?.[0]?.slice(0, 100)}`,
        ).toBeNull();
      });
    }
  }
});
