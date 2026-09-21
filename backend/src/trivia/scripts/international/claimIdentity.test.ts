import { describe, it, expect } from 'vitest';
import {
  MIN_ENTITY_OVERLAP,
  MIN_USABLE_ENTITIES,
  entityOverlap,
  hasUsableEntities,
  isSameFact,
  normalizeEntities,
} from './claimIdentity.js';

describe('entityOverlap', () => {
  it('scores identical sets as 1', () => {
    expect(entityOverlap(['houthi', 'mokha'], ['houthi', 'mokha'])).toBe(1);
  });

  it('scores disjoint sets as 0', () => {
    expect(entityOverlap(['uganda', 'invictus games'], ['russia', 'tumen river'])).toBe(0);
  });

  it('scores an empty left side as 0', () => {
    expect(entityOverlap([], ['norway', 'oslo'])).toBe(0);
  });

  it('scores an empty right side as 0', () => {
    expect(entityOverlap(['norway', 'oslo'], [])).toBe(0);
  });

  it('scores two empty sides as 0, not a vacuous 1', () => {
    expect(entityOverlap([], [])).toBe(0);
  });

  it('ignores case differences', () => {
    expect(entityOverlap(['King Harald', 'NORWAY'], ['king harald', 'norway'])).toBe(1);
  });

  it('ignores leading, trailing and repeated internal whitespace', () => {
    expect(entityOverlap(['  king   harald ', 'norway'], ['king harald', ' norway'])).toBe(1);
  });

  it('ignores blank entries rather than counting them toward set size', () => {
    expect(entityOverlap(['norway', '', '   '], ['norway'])).toBe(1);
  });

  it('counts a repeated entity once, so the denominator is the true set size', () => {
    // ['norway','Norway'] is one entity. Against ['norway'] that is 1/1, not 1/2.
    expect(entityOverlap(['norway', 'Norway'], ['norway'])).toBe(1);
  });

  it('is symmetric', () => {
    const a = ['houthi', 'mokha', 'yemen'];
    const b = ['houthi', 'red sea'];
    expect(entityOverlap(a, b)).toBe(entityOverlap(b, a));
  });

  it('computes Jaccard, not simple intersection size', () => {
    // 2 shared, union of 4.
    expect(entityOverlap(['a', 'b', 'c'], ['a', 'b', 'd'])).toBeCloseTo(0.5, 5);
  });
});

describe('hasUsableEntities', () => {
  it('requires at least two distinct entities', () => {
    expect(MIN_USABLE_ENTITIES).toBe(2);
    expect(hasUsableEntities([])).toBe(false);
    expect(hasUsableEntities(['norway'])).toBe(false);
    expect(hasUsableEntities(['norway', 'oslo'])).toBe(true);
  });

  it('does not count a repeated entity twice', () => {
    expect(hasUsableEntities(['norway', 'Norway '])).toBe(false);
  });

  it('does not count blanks', () => {
    expect(hasUsableEntities(['norway', '  '])).toBe(false);
  });
});

describe('normalizeEntities', () => {
  it('lowercases, trims, collapses internal whitespace and de-duplicates', () => {
    expect(normalizeEntities(['  King   Harald ', 'king harald', 'NORWAY', ''])).toEqual([
      'king harald',
      'norway',
    ]);
  });

  // These four strings came out of the extractor's own extractEntities()
  // verbatim, run over paraphrases of the Mokha story. Without this cleanup
  // every one of them is a shared entity scored as unshared.
  it('strips the trailing sentence punctuation compromise actually emits', () => {
    expect(normalizeEntities(['red sea coast.'])).toEqual(['red sea coast']);
    expect(normalizeEntities(['bab al-mandab.'])).toEqual(['bab al-mandab']);
  });

  it("strips a possessive 's so \"yemen's\" collides with \"yemen\"", () => {
    expect(normalizeEntities(["yemen's", 'Yemen'])).toEqual(['yemen']);
  });

  it('closes up abbreviation dots rather than splitting them into words', () => {
    expect(normalizeEntities(['U.S.'])).toEqual(['us']);
  });

  it('keeps hyphens, which are part of the entity', () => {
    expect(normalizeEntities(['Bab al-Mandab'])).toEqual(['bab al-mandab']);
  });

  it('folds accents', () => {
    expect(normalizeEntities(['Zelensky', 'Zelenský'])).toEqual(['zelensky']);
  });

  it('turns other punctuation into a word break, not a join', () => {
    expect(normalizeEntities(['Wednesday, Yemeni military'])).toEqual(['wednesday yemeni military']);
  });

  it('drops an entity that normalises away entirely', () => {
    expect(normalizeEntities(['...', '—', 'norway'])).toEqual(['norway']);
  });
});

describe('entityOverlap — after normalisation', () => {
  it('scores the raw extractor output as a match once cleaned', () => {
    // "red sea coast." vs "Red Sea Coast" and "yemen's" vs "Yemen" were two
    // silent misses before normalizeEntity stripped punctuation.
    expect(entityOverlap(['red sea coast.', "yemen's"], ['Red Sea Coast', 'Yemen'])).toBe(1);
  });
});

// The three measured cases the rule was designed from, plus the unrelated
// pair that shows why the value alone is not enough.
describe('isSameFact — the measured cases', () => {
  it('Mokha, two runs 90 seconds apart: duplicate', () => {
    expect(
      isSameFact(
        { valueKey: '75', entities: ['houthi', 'mokha', 'bab al-mandab', 'yemen'] },
        { valueKey: '75', entities: ['houthi', 'mokha', 'bab al-mandab', 'red sea'] },
      ),
    ).toBe(true);
  });

  it("King Harald's age, 11 days apart with a grown cluster: duplicate", () => {
    expect(
      isSameFact(
        { valueKey: '89', entities: ['king harald', 'norway'] },
        { valueKey: '89', entities: ['king harald', 'norway', 'oslo'] },
      ),
    ).toBe(true);
  });

  it('Oct 7 deaths vs hostages, identical entities: NOT the same fact', () => {
    expect(
      isSameFact(
        { valueKey: '1200', entities: ['hamas', 'israel', 'gaza'] },
        { valueKey: '251', entities: ['hamas', 'israel', 'gaza'] },
      ),
    ).toBe(false);
  });

  it('Tumen River bridge vs Uganda Invictus Games, both "2026": NOT the same fact', () => {
    expect(
      isSameFact(
        { valueKey: '2026', entities: ['russia', 'north korea', 'tumen river'] },
        { valueKey: '2026', entities: ['uganda', 'invictus games', 'king charles'] },
      ),
    ).toBe(false);
  });
});

describe('isSameFact — mechanics', () => {
  it('requires the values to be equal, however well the entities match', () => {
    expect(
      isSameFact(
        { valueKey: '75', entities: ['houthi', 'mokha'] },
        { valueKey: '76', entities: ['houthi', 'mokha'] },
      ),
    ).toBe(false);
  });

  it('never matches on a blank value, even against another blank', () => {
    // Two extractions that normalised away are not evidence of one fact.
    expect(
      isSameFact(
        { valueKey: '', entities: ['houthi', 'mokha'] },
        { valueKey: '   ', entities: ['houthi', 'mokha'] },
      ),
    ).toBe(false);
  });

  it('returns false when the values match but the entities are empty', () => {
    expect(isSameFact({ valueKey: '75', entities: [] }, { valueKey: '75', entities: [] })).toBe(false);
  });

  it('honours an explicit threshold over the default', () => {
    const a = { valueKey: '75', entities: ['a', 'b', 'c'] };
    const b = { valueKey: '75', entities: ['a', 'b', 'd'] }; // Jaccard 0.5
    expect(isSameFact(a, b, 0.5)).toBe(true);
    expect(isSameFact(a, b, 0.51)).toBe(false);
  });

  it('treats the threshold as inclusive', () => {
    const a = { valueKey: '1', entities: ['a', 'b'] };
    const b = { valueKey: '1', entities: ['a', 'b'] };
    expect(isSameFact(a, b, 1)).toBe(true);
  });

  it('uses a default threshold that admits two-of-three but not two-of-six', () => {
    expect(MIN_ENTITY_OVERLAP).toBe(0.34);
    // Three-entity sets sharing two: 2/4 = 0.5 — the same story.
    expect(
      isSameFact(
        { valueKey: '1', entities: ['a', 'b', 'c'] },
        { valueKey: '1', entities: ['a', 'b', 'd'] },
      ),
    ).toBe(true);
    // Four-entity sets sharing two: 2/6 = 0.333 — too thin to assert.
    expect(
      isSameFact(
        { valueKey: '1', entities: ['a', 'b', 'c', 'd'] },
        { valueKey: '1', entities: ['a', 'b', 'e', 'f'] },
      ),
    ).toBe(false);
  });
});
