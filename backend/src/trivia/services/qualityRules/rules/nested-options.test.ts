import { describe, it, expect } from 'vitest';
import { checkNestedOptions } from './nested-options.js';
import type { QuestionInput } from '../types.js';

/**
 * Fixtures are real questions from the live bank.
 *
 * The false positives matter as much as the true ones here. The first version of this
 * rule also flagged overlapping ranges and read comparators mid-string, and every one of
 * those hits was wrong -- 18 blocking, ~8 of them bogus. Narrowing it to leading/trailing
 * comparators on single-number options took it to 9 blocking and 0 wrong. The "passes"
 * suites below are that narrowing, pinned.
 */
function q(over: Partial<QuestionInput>): QuestionInput {
  return {
    externalId: 'test-000',
    text: 'placeholder',
    options: ['a', 'b', 'c', 'd'],
    correctAnswer: 0,
    explanation: 'An explanation long enough to be realistic for the engine.',
    difficulty: 'medium',
    source: { name: 'Test', url: 'https://example.com' },
    ...over,
  };
}

describe('checkNestedOptions — the bug it was written for', () => {
  it('blocks queny-059, which shipped with three true answers', () => {
    const result = checkNestedOptions(
      q({
        externalId: 'queny-059',
        text: 'How many languages are spoken in Queens, New York?',
        options: ['More than 50', 'More than 80', 'More than 138', 'More than 200'],
        correctAnswer: 2,
        difficulty: 'easy',
      })
    );

    expect(result.passed).toBe(false);
    expect(result.violations).toHaveLength(1);
    expect(result.violations[0].rule).toBe('nested-options');
    expect(result.violations[0].severity).toBe('blocking');
    // "More than 50" and "More than 80" are both true when "More than 138" is.
    expect(result.violations[0].message).toContain('3 simultaneously true options');
    expect(result.violations[0].evidence).toContain('More than 50');
    expect(result.violations[0].evidence).toContain('More than 80');
    expect(result.violations[0].evidence).not.toContain('More than 200');
  });

  it('blocks upper bounds the same way (wdc-068 as it shipped)', () => {
    const result = checkNestedOptions(
      q({
        externalId: 'wdc-068',
        text: 'What is the maximum dollar amount for cases heard in the Small Claims and Conciliation Branch?',
        options: ['$5,000 and below', '$10,000 and below', '$15,000 and below', '$25,000 and below'],
        correctAnswer: 1,
      })
    );

    expect(result.passed).toBe(false);
    expect(result.violations[0].severity).toBe('blocking');
    expect(result.violations[0].message).toContain('upper-bound');
    // A $10,000 claim also satisfies "$15,000 and below" and "$25,000 and below".
    expect(result.violations[0].evidence).toContain('$15,000 and below');
    expect(result.violations[0].evidence).toContain('$25,000 and below');
    expect(result.violations[0].evidence).not.toContain('$5,000 and below');
  });

  it('reads a bare "+" suffix as a lower bound (wmnla-038 as it shipped)', () => {
    const result = checkNestedOptions(
      q({
        externalId: 'wmnla-038',
        options: ['10+', '25+', '50+', '100+'],
        correctAnswer: 2,
      })
    );

    expect(result.passed).toBe(false);
    expect(result.violations[0].severity).toBe('blocking');
    expect(result.violations[0].evidence).toContain('10+');
    expect(result.violations[0].evidence).toContain('25+');
  });

  it('applies magnitude words before comparing (tucaz-054 as it shipped)', () => {
    const result = checkNestedOptions(
      q({
        externalId: 'tucaz-054',
        options: [
          'Over $25 million',
          'Over $60 million',
          'Over $100 million',
          'Over $138 million',
        ],
        correctAnswer: 3,
      })
    );

    expect(result.passed).toBe(false);
    expect(result.violations[0].message).toContain('4 simultaneously true options');
  });

  it('does not confuse scales: "Over 2 billion" beats "Over 900 million"', () => {
    const result = checkNestedOptions(
      q({ options: ['Over 900 million', 'Over 2 billion'], correctAnswer: 1 })
    );

    expect(result.passed).toBe(false);
    expect(result.violations[0].evidence).toContain('Over 900 million');
  });
});

describe('checkNestedOptions — advisory when only one option is true today', () => {
  it('flags a nested set as advisory when the correct option is the weakest bound', () => {
    const result = checkNestedOptions(
      q({
        options: ['More than 50', 'More than 80', 'More than 138', 'More than 200'],
        correctAnswer: 0,
      })
    );

    expect(result.passed).toBe(false);
    expect(result.violations).toHaveLength(1);
    expect(result.violations[0].rule).toBe('nested-option-scale');
    expect(result.violations[0].severity).toBe('advisory');
  });

  it('is advisory, not blocking, for the weakest upper bound', () => {
    // For upper bounds the WEAKEST option is the largest threshold: a value that is
    // "$25,000 and below" but above $10,000 makes only that one option true.
    const result = checkNestedOptions(
      q({
        options: ['$5,000 and below', '$10,000 and below', '$25,000 and below'],
        correctAnswer: 2,
      })
    );

    expect(result.violations[0].rule).toBe('nested-option-scale');
    expect(result.violations[0].severity).toBe('advisory');
  });

  it('blocks the smallest upper bound, which is the strongest claim', () => {
    const result = checkNestedOptions(
      q({
        options: ['$5,000 and below', '$10,000 and below', '$25,000 and below'],
        correctAnswer: 0,
      })
    );

    expect(result.violations[0].rule).toBe('nested-options');
    expect(result.violations[0].severity).toBe('blocking');
  });
});

describe('checkNestedOptions — ranges are NOT flagged, deliberately', () => {
  /**
   * Range options are normally competing EXACT claims, not buckets a value falls into.
   * Only one span is the real one, and overlap does not make a second option true.
   * Every range hit on the first run of this rule was a false positive.
   */
  it('passes overlapping date spans (Milwaukee sewer socialists)', () => {
    const result = checkNestedOptions(
      q({
        text: 'During roughly what period did Milwaukee elect sewer socialist mayors?',
        options: [
          'About 1892 to 1960',
          'About 1870 to 1900',
          'About 1910 to 1940',
          'About 1945 to 1975',
        ],
        correctAnswer: 0,
      })
    );

    expect(result.passed).toBe(true);
    expect(result.violations).toHaveLength(0);
  });

  it('passes a pair of years ("1974 and 1990")', () => {
    const result = checkNestedOptions(
      q({ options: ['1974 and 1990', '1968 and 1982', '1980 and 1996'], correctAnswer: 0 })
    );

    expect(result.passed).toBe(true);
  });

  it('passes district pairs ("Districts 1 and 2")', () => {
    const result = checkNestedOptions(
      q({ options: ['Districts 1 and 2', 'Districts 3 and 4'], correctAnswer: 0 })
    );

    expect(result.passed).toBe(true);
  });

  it('passes a hyphenated measure number ("Measure 26-228")', () => {
    const result = checkNestedOptions(
      q({ options: ['Measure 26-228', 'Measure 26-230', 'Measure 26-199'], correctAnswer: 0 })
    );

    expect(result.passed).toBe(true);
  });

  it('passes the Paris Agreement target, which carries two numbers and a comparator', () => {
    const result = checkNestedOptions(
      q({
        text: 'What temperature goal does the Paris Agreement set?',
        options: [
          'Well below 2C, pursuing efforts to limit it to 1.5C',
          'Exactly 2C with no further target',
          'Below 3C by 2100',
        ],
        correctAnswer: 0,
      })
    );

    expect(result.passed).toBe(true);
  });
});

describe('checkNestedOptions — comparators must lead or trail, not sit mid-string', () => {
  it('passes ica-013: "14 feet below sea level" is a measurement, not a bound', () => {
    const result = checkNestedOptions(
      q({
        externalId: 'ica-013',
        text: 'What is the lowest elevation in the city?',
        options: [
          '14 feet below sea level',
          '8 feet below sea level',
          '22 feet below sea level',
          '3 feet below sea level',
        ],
        correctAnswer: 0,
      })
    );

    expect(result.passed).toBe(true);
    expect(result.violations).toHaveLength(0);
  });

  it('still reads a leading comparator after a hedge ("About more than 500")', () => {
    const result = checkNestedOptions(
      q({ options: ['Roughly more than 500', 'Roughly more than 900'], correctAnswer: 1 })
    );

    expect(result.passed).toBe(false);
    expect(result.violations[0].severity).toBe('blocking');
  });

  it('requires a trailing comparator to actually end the option', () => {
    // "or more" mid-string is part of a phrase, not a threshold on the whole option.
    const result = checkNestedOptions(
      q({
        options: [
          '500 or more residents were displaced downtown',
          '900 or more residents were displaced downtown',
        ],
        correctAnswer: 1,
      })
    );

    expect(result.passed).toBe(true);
  });
});

describe('checkNestedOptions — sets that are genuinely exclusive', () => {
  it('passes plain competing values', () => {
    const result = checkNestedOptions(
      q({ options: ['$2,500', '$5,000', '$10,000', '$25,000'], correctAnswer: 2 })
    );

    expect(result.passed).toBe(true);
  });

  it('passes one lower bound paired with one upper bound', () => {
    const result = checkNestedOptions(
      q({
        options: ['Fewer than 10', '10 to 25', '25 to 40', 'More than 40'],
        correctAnswer: 3,
      })
    );

    expect(result.passed).toBe(true);
  });

  it('passes non-numeric options', () => {
    const result = checkNestedOptions(
      q({ options: ['The mayor', 'The city council', 'The county board'], correctAnswer: 1 })
    );

    expect(result.passed).toBe(true);
  });
});

describe('checkNestedOptions — guards', () => {
  it('passes an empty option list rather than throwing', () => {
    expect(checkNestedOptions(q({ options: [] })).passed).toBe(true);
  });

  it('defers an out-of-range correctAnswer to the rule that owns it', () => {
    const result = checkNestedOptions(
      q({ options: ['More than 50', 'More than 80'], correctAnswer: 7 })
    );

    expect(result.passed).toBe(true);
  });

  it('defers a negative correctAnswer too', () => {
    const result = checkNestedOptions(
      q({ options: ['More than 50', 'More than 80'], correctAnswer: -1 })
    );

    expect(result.passed).toBe(true);
  });
});

describe('checkNestedOptions — the live repairs stay repaired', () => {
  /**
   * The option sets the 2026-09-27 content pass wrote to replace every flagged one in the
   * live bank: eight that were blocking, then three that were advisory (all four options
   * an "Over N" bound, with the correct one the weakest). The ninth blocking question,
   * bxl-175, is not here because it was archived rather than repaired -- its cited source
   * never mentioned libraries and no source carried the number.
   *
   * If a later edit reintroduces same-direction bounds, these fail here first.
   */
  const repaired: Array<[string, string[], number]> = [
    ['bxl-153', ['Under $100,000', '$100,000 to $250,000', '$250,000 to $400,000', 'More than $400,000'], 3],
    ['climc-0053', ['Fewer than 1,000', '1,000 to 3,000', '3,000 to 5,000', 'More than 5,000'], 3],
    ['climc-0059', ['Fewer than 500 people', '500 to 1,000 people', '1,000 to 1,400 people', 'More than 1,400 people'], 3],
    ['por-143', ['Fewer than 9 decades', '9 or 10 decades', '11 or 12 decades', 'More than 12 decades'], 2],
    ['por-288', ['About 800 acres', 'About 2,500 acres', 'About 5,200 acres', 'About 12,000 acres'], 2],
    ['tucaz-054', ['Less than $25 million', '$25 million to $70 million', '$70 million to $135 million', 'More than $135 million'], 3],
    ['wdc-068', ['$2,500', '$5,000', '$10,000', '$25,000'], 2],
    ['wmnla-038', ['Fewer than 10', '10 to 25', '25 to 40', 'More than 40'], 3],
    // Were advisory, not blocking: nested but only the weakest bound was true.
    ['cam-025', ['Fewer than 20,000', '20,000 to 40,000', '40,000 to 60,000', 'More than 60,000'], 3],
    ['nysts-055', ['About 2 million acres', 'About 4 million acres', 'About 6 million acres', 'About 10 million acres'], 2],
    ['wdc-025', ['Fewer than 25', '25 to 50', '50 to 100', 'More than 100'], 3],
  ];

  it.each(repaired)('%s has exactly one true option', (externalId, options, correctAnswer) => {
    const result = checkNestedOptions(q({ externalId, options, correctAnswer }));

    expect(result.violations).toEqual([]);
    expect(result.passed).toBe(true);
  });
});
