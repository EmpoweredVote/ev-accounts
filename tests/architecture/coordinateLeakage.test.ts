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
import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Resolve from tests/architecture/ → project root → backend/src/routes/
const ROUTES_DIR = path.resolve(__dirname, '../../backend/src/routes');

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
  const routeFiles = fs
    .readdirSync(ROUTES_DIR)
    .filter((f) => f.endsWith('.ts'))
    .map((f) => path.join(ROUTES_DIR, f));

  it('should have route files to scan', () => {
    expect(routeFiles.length).toBeGreaterThan(0);
  });

  for (const filePath of routeFiles) {
    const fileName = path.basename(filePath);
    const content = fs.readFileSync(filePath, 'utf-8');

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
