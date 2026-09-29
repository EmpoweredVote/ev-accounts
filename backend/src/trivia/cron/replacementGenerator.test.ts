import { describe, it, expect, beforeAll } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

/**
 * WHY THIS EXISTS
 * ---------------
 * tryLoadLocaleConfig() decides whether the nightly replacement cron can even
 * SEE a collection's locale config. Controller Ruling 17 rekeyed its
 * config-detection guard from `'locale' in val && 'externalIdPrefix' in val`
 * to `'locale' in val && 'collectionSlug' in val`, because a new-scheme
 * config carries no externalIdPrefix key at all: the old guard silently
 * rejected it, tryLoadLocaleConfig returned null, and the cron just skipped
 * the collection with no error, no warning -- for exactly the collections
 * this whole change exists to support (every Knight collection carries
 * 15-30% expiring officeholder questions this cron replaces).
 *
 * tryLoadLocaleConfig, and the guard inside it, are module-private, and
 * Controller Ruling 18 says not to export either just to make this
 * testable -- unlike `skipReasonFor` in pipelineCron.test.ts (this same
 * directory), which WAS pulled out into its own exported function for
 * exactly this kind of reason. So this pins the guard the way
 * question-generator.test.ts pins `writePassingQuestions`: by reading the
 * real, current source and asserting on it, rather than reimplementing it
 * by hand (which would drift from the real guard silently) or executing the
 * unexported function directly (which is not reachable from here).
 *
 * The guard's own condition is a single boolean expression with no side
 * effects, so it is extracted verbatim from the source text and evaluated
 * -- via `new Function`, not `eval`, and only ever against literal test
 * objects defined in this file -- against both a legacy-shaped and a
 * new-scheme-shaped config object. This is stronger than a plain substring
 * check: it proves the CURRENT guard, as written, actually accepts both
 * shapes, and it fails exactly if the guard reverts to requiring
 * externalIdPrefix.
 */

const SRC = readFileSync(
  fileURLToPath(new URL('./replacementGenerator.ts', import.meta.url)),
  'utf-8',
);

// Anchored to the line immediately before it (`return val as LocaleConfig;`)
// so this can only ever match tryLoadLocaleConfig's own config-detection
// guard -- never an unrelated `if (...)` elsewhere in the file, and never a
// coincidental mention of `externalIdPrefix` in a comment or in mintFor().
const GUARD_RE = /if \((.+)\)\s*\{\n\s*return val as LocaleConfig;/;
const guardMatch = SRC.match(GUARD_RE);

describe('tryLoadLocaleConfig config-detection guard (Controller Ruling 17)', () => {
  it('the guard is present and extractable from the current source', () => {
    // Guards against the whole test suite going vacuously green if a
    // refactor changes the guard's shape enough that GUARD_RE stops
    // matching anything at all.
    expect(guardMatch).not.toBeNull();
  });

  let isLocaleConfigExport: (val: unknown) => boolean;

  beforeAll(() => {
    if (!guardMatch) {
      throw new Error(
        'tryLoadLocaleConfig config-detection guard not found in replacementGenerator.ts ' +
          '-- update GUARD_RE in replacementGenerator.test.ts to match the current source.',
      );
    }
    // eslint-disable-next-line no-new-func -- deliberately evaluating the
    // exact condition extracted from the real source above, not a
    // hand-copied duplicate of it.
    isLocaleConfigExport = new Function('val', `return Boolean(${guardMatch[1]});`) as (
      val: unknown,
    ) => boolean;
  });

  it('accepts a legacy-shaped config object (locale, collectionSlug, externalIdPrefix)', () => {
    const legacyConfig = {
      locale: 'bloomington-in',
      name: 'Bloomington, Indiana',
      externalIdPrefix: 'bli',
      collectionSlug: 'bloomington-in',
    };
    expect(isLocaleConfigExport(legacyConfig)).toBe(true);
  });

  it('accepts a new-scheme config object with NO externalIdPrefix key -- the case a regression to the old guard would break', () => {
    const newSchemeConfig = {
      locale: 'akron-oh',
      name: 'Akron, Ohio',
      collectionSlug: 'akron-oh',
      // no externalIdPrefix -- this is the point of the test.
    };
    expect(isLocaleConfigExport(newSchemeConfig)).toBe(true);
  });

  it('rejects an object with neither locale nor collectionSlug', () => {
    expect(isLocaleConfigExport({ officeholders: [] })).toBe(false);
  });

  it('rejects null and non-objects the way the real guard does (short-circuits on `val &&`)', () => {
    expect(isLocaleConfigExport(null)).toBe(false);
    expect(isLocaleConfigExport('a string export')).toBe(false);
  });
});
