import { describe, it, expect } from 'vitest';
import { checkSourceDrift } from './source-drift.js';
import type { QuestionInput } from '../types.js';

/**
 * Fixtures are real questions from the live bank.
 *
 * The rule exists because of lou-018, which was CORRECT when written and was made
 * wrong by a statute nobody here was watching. Its original and its rewrite are both
 * pinned below: the pair is the contract. A rule that flags the topic would fire on
 * both and teach nothing. This one fires on the unqualified scope, so fixing the
 * scope clears the flag.
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

describe('checkSourceDrift — the question it was written for', () => {
  it('flags an election-mechanics claim whose scope is unqualified', () => {
    const result = checkSourceDrift(
      q({
        externalId: 'lou-018',
        text: 'In what years does Louisiana hold its statewide elections?',
        options: [
          'Odd years not coinciding with federal elections',
          'Even years alongside congressional elections',
          'Presidential election years',
          'Every two years starting 2020',
        ],
      })
    );
    expect(result.passed).toBe(false);
    expect(result.violations).toHaveLength(1);
    expect(result.violations[0].rule).toBe('source-drift-risk');
  });

  it('does not flag the same claim once its scope names the offices it covers', () => {
    const result = checkSourceDrift(
      q({
        externalId: 'lou-018-rewritten',
        text: 'In what years does Louisiana elect its governor and other state executive officials?',
        options: [
          'Odd years not coinciding with federal elections',
          'Even years alongside congressional elections',
          'Presidential election years',
          'Every two years starting 2020',
        ],
      })
    );
    expect(result.passed).toBe(true);
    expect(result.violations).toHaveLength(0);
  });

  it('does not flag a primary-system question that scopes itself to named offices', () => {
    const result = checkSourceDrift(
      q({
        externalId: 'lou-201',
        text: "In Louisiana's primary for a state office such as governor, what happens if one candidate wins more than 50% of the vote?",
      })
    );
    expect(result.passed).toBe(true);
  });
});

describe('checkSourceDrift — rankings and superlatives', () => {
  it('flags a superlative measured against a field someone else can change', () => {
    const result = checkSourceDrift(
      q({
        externalId: 'lou-054',
        text: 'The Port of South Louisiana is the largest U.S. port by what measure?',
      })
    );
    expect(result.passed).toBe(false);
    expect(result.violations[0].rule).toBe('source-drift-risk');
  });

  it('flags an explicit ordinal ranking', () => {
    const result = checkSourceDrift(
      q({
        externalId: 'lou-064',
        text: 'Which Louisiana port ranks 4th largest in the world by annual tonnage?',
      })
    );
    expect(result.passed).toBe(false);
  });

  it('does not flag a superlative with no comparison field', () => {
    const result = checkSourceDrift(
      q({ externalId: 'lou-101', text: 'In Louisiana, what is a bayou?' })
    );
    expect(result.passed).toBe(true);
  });
});

describe('checkSourceDrift — counts of governed units', () => {
  it('flags a count of seats, which a legislature can change', () => {
    const result = checkSourceDrift(
      q({
        externalId: 'lou-002',
        text: 'How many members serve in the Louisiana State Senate?',
        options: ['39', '40', '44', '50'],
      })
    );
    expect(result.passed).toBe(false);
  });

  it('does not flag a settled historical quantity', () => {
    const result = checkSourceDrift(
      q({
        externalId: 'lou-021',
        text: 'How much did the United States pay France for the Louisiana Purchase?',
        options: ['$15 million', '$20 million', '$7 million', '$32 million'],
      })
    );
    expect(result.passed).toBe(true);
  });
});

describe('checkSourceDrift — contract', () => {
  it('is advisory, never blocking: it finds candidates to read, not defects to archive', () => {
    const result = checkSourceDrift(
      q({ externalId: 'lou-018', text: 'In what years does Louisiana hold its statewide elections?' })
    );
    expect(result.violations[0].severity).toBe('advisory');
  });

  it('names the trigger that fired so a reader knows what to check', () => {
    const result = checkSourceDrift(
      q({ externalId: 'lou-018', text: 'In what years does Louisiana hold its statewide elections?' })
    );
    expect(result.violations[0].evidence).toMatch(/election-mechanics/);
  });

  it('passes an ordinary durable question', () => {
    const result = checkSourceDrift(
      q({
        externalId: 'lou-023',
        text: 'After whom was Louisiana named?',
        options: ['King Louis XIV of France', 'Louis XVI of France', 'Louis Armstrong', 'St. Louis'],
      })
    );
    expect(result.passed).toBe(true);
    expect(result.violations).toHaveLength(0);
  });
});

describe('registration in the rules engine', () => {
  it('auditQuestion surfaces source-drift-risk for lou-018, without blocking it', async () => {
    const { auditQuestion } = await import('../index.js');
    const result = await auditQuestion(
      q({
        externalId: 'lou-018',
        text: 'In what years does Louisiana hold its statewide elections?',
        options: [
          'Odd years not coinciding with federal elections',
          'Even years alongside congressional elections',
          'Presidential election years',
          'Every two years starting 2020',
        ],
      }),
      { skipUrlCheck: true }
    );
    expect(result.violations.map(v => v.rule)).toContain('source-drift-risk');
    const drift = result.violations.find(v => v.rule === 'source-drift-risk');
    expect(drift?.severity).toBe('advisory');
  });
});
