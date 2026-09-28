import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { auditBeforeInsert } from './auditBeforeInsert.js';
import type { QuestionInput } from '../qualityRules/types.js';
import { QUALITY_RULES_ENFORCE_ENV } from '../../scripts/international/qualityGate.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * ev-accounts #816 put the rules engine on the news pipeline's write path and
 * nothing else. These two generators inserted into trivia.questions with no rule
 * ever consulted. The gate they now share is the fix, and the distinction it has
 * to protect is the same one qualityGate.test.ts protects: a rule that is not
 * enforced must still run and still log, and must NOT refuse the write.
 *
 * The audit-throws case matters most. Refusing to write because our own rule
 * crashed turns an engine bug into silent content loss, which is worse than the
 * unaudited question it was trying to prevent.
 */

function q(over: Partial<QuestionInput> = {}): QuestionInput {
  return {
    externalId: 'ctq-race1-001',
    text: 'How many members sit on the county commission?',
    options: ['Three', 'Five', 'Seven', 'Nine'],
    correctAnswer: 1,
    explanation: 'An explanation long enough to be realistic for the engine to accept.',
    difficulty: 'medium',
    source: { name: 'County Clerk', url: 'https://example.gov/commission' },
    ...over,
  };
}

/** The defect the whole workstream exists for: every option true at once. */
function nested(): QuestionInput {
  return q({
    externalId: 'ctq-race1-002',
    text: 'How many people voted in the last county election?',
    options: ['More than 1,000', 'More than 5,000', 'More than 10,000', 'More than 20,000'],
    correctAnswer: 3,
  });
}

const original = process.env[QUALITY_RULES_ENFORCE_ENV];

beforeEach(() => {
  vi.spyOn(console, 'log').mockImplementation(() => {});
  vi.spyOn(console, 'warn').mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
  if (original === undefined) delete process.env[QUALITY_RULES_ENFORCE_ENV];
  else process.env[QUALITY_RULES_ENFORCE_ENV] = original;
});

describe('auditBeforeInsert', () => {
  it('writes a clean question', async () => {
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'nested-options';
    const r = await auditBeforeInsert(q());

    expect(r.write).toBe(true);
    expect(r.enforced).toEqual([]);
    expect(r.errored).toBe(false);
  });

  it('refuses a nested-options question when that rule is enforced', async () => {
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'nested-options';
    const r = await auditBeforeInsert(nested());

    expect(r.write).toBe(false);
    expect(r.enforced.map(v => v.rule)).toContain('nested-options');
    expect(r.errored).toBe(false);
  });

  it('writes the same question when nothing is enforced, but still reports it', async () => {
    // The flagged-rollout contract: the rule runs and the violation is visible,
    // it simply does not refuse the write.
    delete process.env[QUALITY_RULES_ENFORCE_ENV];
    const r = await auditBeforeInsert(nested());

    expect(r.write).toBe(true);
    expect(r.blocking.map(v => v.rule)).toContain('nested-options');
    expect(r.enforced).toEqual([]);
  });

  it('writes a question whose only blocking rule is NOT the enforced one', async () => {
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'some-other-rule';
    const r = await auditBeforeInsert(nested());

    expect(r.write).toBe(true);
    expect(r.blocking.map(v => v.rule)).toContain('nested-options');
    expect(r.enforced).toEqual([]);
  });

  it('refuses under the blanket "true" setting too', async () => {
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'true';
    const r = await auditBeforeInsert(nested());

    expect(r.write).toBe(false);
  });

  it('logs the blocking verdict rather than failing silently', async () => {
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'nested-options';
    await auditBeforeInsert(nested());

    const logged = (console.log as unknown as { mock: { calls: unknown[][] } }).mock.calls
      .map(c => String(c[0]))
      .join('\n');
    expect(logged).toContain('BLOCKED');
    expect(logged).toContain('ctq-race1-002');
  });
});

describe('auditBeforeInsert — when the engine itself breaks', () => {
  it('writes the question and flags it, rather than losing content', async () => {
    // Enforcement fully ON, so nothing but the catch can be keeping this alive.
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'true';

    // A null options array makes a rule throw for real -- verified against the
    // engine: "Cannot read properties of null (reading 'length')". No mocking of
    // the module graph, so this keeps testing the real failure path if the rules
    // change.
    const r = await auditBeforeInsert(q({ options: null as unknown as string[] }));

    expect(r.errored).toBe(true);
    expect(r.write).toBe(true);
    expect(r.blocking).toEqual([]);
    expect(r.enforced).toEqual([]);
  });

  it('says so on stderr instead of swallowing the crash', async () => {
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'true';
    await auditBeforeInsert(q({ options: null as unknown as string[] }));

    const warned = (console.warn as unknown as { mock: { calls: unknown[][] } }).mock.calls
      .map(c => String(c[0]))
      .join('\n');
    expect(warned).toContain('THREW');
    expect(warned).toContain('writing unaudited');
  });
});
