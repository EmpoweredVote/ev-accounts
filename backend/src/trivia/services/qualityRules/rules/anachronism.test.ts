import { describe, it, expect, vi, afterEach } from 'vitest';
import { checkAnachronisticYear } from './anachronism.js';
import type { QuestionInput } from '../types.js';

/**
 * Fixtures are real questions from the live bank. The tense distinction IS the rule,
 * so the passing fixtures carry as much weight as the failing one.
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

afterEach(() => {
  vi.useRealTimers();
});

/** Pin "now" so the suite does not change behaviour on 1 January. */
function freezeYear(year: number) {
  vi.useFakeTimers();
  vi.setSystemTime(new Date(`${year}-06-15T00:00:00Z`));
}

describe('checkAnachronisticYear — the bug it was written for', () => {
  it('blocks a past-tense year question offering a year that has not happened', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        externalId: 'wnews-0134',
        text: 'In what year was South African deputy police commissioner Lt Gen Shadrack Sibiya charged with sexual offences and trafficking?',
        options: ['2024', '2025', '2026', '2027'],
        correctAnswer: 2,
      })
    );
    expect(result.passed).toBe(false);
    expect(result.violations).toHaveLength(1);
    expect(result.violations[0].rule).toBe('anachronistic-year-option');
    expect(result.violations[0].severity).toBe('blocking');
    expect(result.violations[0].evidence).toContain('2027');
  });
});

describe('checkAnachronisticYear — forward-looking questions are legitimate', () => {
  it('passes "what year will" (por-043)', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        externalId: 'por-043',
        text: "What year will Portland's District 3 and 4 councilors first face re-election?",
        options: ['2025', '2026', '2027', '2028'],
        correctAnswer: 1,
      })
    );
    expect(result.passed).toBe(true);
    expect(result.violations).toHaveLength(0);
  });

  it('passes "what year is X permitted to" (smo-019)', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        externalId: 'smo-019',
        text: 'What year is Santa Monica permitted to close its municipal airport?',
        options: ['2025', '2028', '2030', '2035'],
        correctAnswer: 1,
      })
    );
    expect(result.passed).toBe(true);
  });

  it('passes "by what year does X plan to" (ica-100)', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        externalId: 'ica-100',
        text: 'By what year does SunLine Transit Agency plan to convert its fleet to zero-emission buses?',
        options: ['2035', '2040', '2045', '2050'],
        correctAnswer: 0,
      })
    );
    expect(result.passed).toBe(true);
  });

  it('passes a report released in the past that projects into the future (climc-0051)', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        externalId: 'climc-0051',
        text: "Australia's seventh intergenerational report, released in September 2026, projects economic and social trends out to what year?",
        options: ['2056', '2061', '2066', '2071'],
        correctAnswer: 2,
      })
    );
    expect(result.passed).toBe(true);
  });
});

describe('checkAnachronisticYear — the cases that decide whether the rule is safe', () => {
  it('finds a future year embedded in a longer option string', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        text: 'In what year was the new city charter adopted?',
        options: ['March 2024', 'March 2025', 'March 2026', 'March 2027'],
        correctAnswer: 2,
      })
    );
    expect(result.passed).toBe(false);
    expect(result.violations[0].evidence).toContain('2027');
  });

  it('finds a future year in a school-year style range', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        text: 'In what year did the district adopt the new calendar?',
        options: ['2023-24', '2024-25', '2025-26', '2026-27'],
        correctAnswer: 2,
      })
    );
    expect(result.passed).toBe(false);
  });

  it('does not let a future marker excuse a genuine past-tense violation', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        text: 'What year was the closure deadline set, before it will take effect?',
        options: ['2024', '2025', '2026', '2027'],
        correctAnswer: 1,
      })
    );
    expect(result.passed).toBe(false);
  });

  it('ignores four-digit numbers that are not years', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        text: 'How many people were killed in the 7 October 2023 attacks?',
        options: ['1200', '2400', '3600', '4800'],
        correctAnswer: 0,
      })
    );
    expect(result.passed).toBe(true);
  });

  it('passes a past-tense question whose options are all in the past', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        text: 'In what year was the Cambridge Board of Election Commissioners established?',
        options: ['1921', '1938', '1945', '1952'],
        correctAnswer: 1,
      })
    );
    expect(result.passed).toBe(true);
  });

  it('is not a year question at all, so passes whatever the options say', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        text: 'Who appoints members of the Cambridge Board of Election Commissioners?',
        options: ['2027 Committee', 'The City Manager', 'The Governor', 'The Mayor'],
        correctAnswer: 1,
      })
    );
    expect(result.passed).toBe(true);
  });

  it('reads the current year from the clock, not a constant', () => {
    freezeYear(2030);
    const result = checkAnachronisticYear(
      q({
        text: 'In what year was the new charter adopted?',
        options: ['2027', '2028', '2029', '2031'],
        correctAnswer: 0,
      })
    );
    expect(result.passed).toBe(false);
    expect(result.violations[0].evidence).toContain('2031');
  });

  it('allows the current year itself', () => {
    freezeYear(2026);
    const result = checkAnachronisticYear(
      q({
        text: 'In what year did the council adopt the budget?',
        options: ['2023', '2024', '2025', '2026'],
        correctAnswer: 3,
      })
    );
    expect(result.passed).toBe(true);
  });
});

describe('registration in the rules engine', () => {
  it('auditQuestion reports a blocking violation for wnews-0134', async () => {
    freezeYear(2026);
    const { auditQuestion } = await import('../index.js');
    const result = await auditQuestion(
      q({
        externalId: 'wnews-0134',
        text: 'In what year was South African deputy police commissioner Lt Gen Shadrack Sibiya charged with sexual offences and trafficking?',
        options: ['2024', '2025', '2026', '2027'],
        correctAnswer: 2,
      }),
      { skipUrlCheck: true }
    );
    expect(result.hasBlockingViolations).toBe(true);
    expect(result.violations.map(v => v.rule)).toContain('anachronistic-year-option');
  });
});
