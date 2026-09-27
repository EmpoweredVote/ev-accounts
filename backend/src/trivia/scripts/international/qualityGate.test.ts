import { describe, it, expect, afterEach } from 'vitest';
import type { Violation } from '../../services/qualityRules/types.js';
import {
  QUALITY_RULES_ENFORCE_ENV,
  qualityRulesEnforced,
  emptyQualityRuleStats,
  decideRuleGate,
  recordGate,
  recordRuleError,
  mergeQualityRuleStats,
  MAX_SAMPLES,
} from './qualityGate.js';

/**
 * WHY THIS EXISTS
 * ---------------
 * `wnews-0134` asked what year a past event happened and offered 2026 as an
 * option. The rule that catches it existed; nothing in the nightly pipeline
 * ever called it. This is the judgement half of the fix, kept free of the
 * database for the same reason `skipReasonFor()` was — a decision you cannot
 * test without a Postgres connection is a decision nobody tests.
 *
 * The distinction this file exists to protect is `blocked` vs `suppressed`.
 * With enforcement off, a question with blocking violations is still WRITTEN;
 * counting it as blocked would report a clean night that never happened, and
 * would hide the one number the flagged rollout is for — what enforcement
 * would cost if it were switched on tonight.
 */

const blocking = (rule: string): Violation => ({
  rule,
  severity: 'blocking',
  message: `${rule} violated`,
});

const advisory = (rule: string): Violation => ({
  rule,
  severity: 'advisory',
  message: `${rule} noted`,
});

describe('qualityRulesEnforced', () => {
  const original = process.env[QUALITY_RULES_ENFORCE_ENV];

  afterEach(() => {
    if (original === undefined) delete process.env[QUALITY_RULES_ENFORCE_ENV];
    else process.env[QUALITY_RULES_ENFORCE_ENV] = original;
  });

  it('is off when the variable is unset', () => {
    delete process.env[QUALITY_RULES_ENFORCE_ENV];
    expect(qualityRulesEnforced()).toBe(false);
  });

  it('is on only for the exact string "true"', () => {
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: 'true' })).toBe(true);
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: '1' })).toBe(false);
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: 'yes' })).toBe(false);
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: 'TRUE' })).toBe(false);
  });

  it('reads the environment on every call, not once at import', () => {
    // Review Focus 4. A module-level `const ENFORCE = process.env...` would
    // pass every other test in this file and still be wrong: the flag could
    // not be flipped without a redeploy, and this test would assert against a
    // value captured before it was set.
    delete process.env[QUALITY_RULES_ENFORCE_ENV];
    expect(qualityRulesEnforced()).toBe(false);
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'true';
    expect(qualityRulesEnforced()).toBe(true);
  });
});

describe('decideRuleGate', () => {
  it('writes a clean question', () => {
    const d = decideRuleGate([], false);
    expect(d.write).toBe(true);
    expect(d.blocking).toEqual([]);
    expect(d.advisory).toEqual([]);
  });

  it('writes a question with advisory violations only, under either setting', () => {
    expect(decideRuleGate([advisory('partisan-framing')], false).write).toBe(true);
    expect(decideRuleGate([advisory('partisan-framing')], true).write).toBe(true);
  });

  it('writes a blocking-violation question when enforcement is off', () => {
    const d = decideRuleGate([blocking('anachronistic-year-option')], false);
    expect(d.write).toBe(true);
    expect(d.blocking).toHaveLength(1);
  });

  it('refuses a blocking-violation question when enforcement is on', () => {
    const d = decideRuleGate([blocking('anachronistic-year-option')], true);
    expect(d.write).toBe(false);
  });

  it('partitions mixed violations by severity', () => {
    const d = decideRuleGate(
      [blocking('ambiguous-answers'), advisory('partisan-framing'), blocking('pure-lookup')],
      true,
    );
    expect(d.blocking.map(v => v.rule)).toEqual(['ambiguous-answers', 'pure-lookup']);
    expect(d.advisory.map(v => v.rule)).toEqual(['partisan-framing']);
  });
});

describe('recordGate', () => {
  it('counts a clean question as audited and nothing else', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'wnews-0001', decideRuleGate([], false), false);
    expect(s).toMatchObject({
      audited: 1, withBlocking: 0, withAdvisoryOnly: 0, blocked: 0, suppressed: 0,
    });
    expect(s.byRule).toEqual({});
  });

  it('counts a blocking violation as SUPPRESSED, not blocked, when enforcement is off', () => {
    const s = emptyQualityRuleStats();
    const d = decideRuleGate([blocking('anachronistic-year-option')], false);
    recordGate(s, 'wnews-0134', d, false);
    expect(s.withBlocking).toBe(1);
    expect(s.suppressed).toBe(1);
    expect(s.blocked).toBe(0);
  });

  it('counts a blocking violation as BLOCKED when enforcement is on', () => {
    const s = emptyQualityRuleStats();
    const d = decideRuleGate([blocking('anachronistic-year-option')], true);
    recordGate(s, 'wnews-0134', d, true);
    expect(s.blocked).toBe(1);
    expect(s.suppressed).toBe(0);
  });

  it('tallies every violated rule by name, blocking and advisory alike', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([blocking('pure-lookup'), advisory('partisan-framing')], false), false);
    recordGate(s, 'b', decideRuleGate([blocking('pure-lookup')], false), false);
    expect(s.byRule).toEqual({ 'pure-lookup': 2, 'partisan-framing': 1 });
  });

  it('counts advisory-only separately from blocking', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([advisory('partisan-framing')], false), false);
    expect(s.withAdvisoryOnly).toBe(1);
    expect(s.withBlocking).toBe(0);
  });

  it('samples the offending question ids, capped', () => {
    const s = emptyQualityRuleStats();
    for (let i = 0; i < MAX_SAMPLES + 5; i++) {
      recordGate(s, `wnews-${i}`, decideRuleGate([blocking('pure-lookup')], false), false);
    }
    expect(s.withBlocking).toBe(MAX_SAMPLES + 5);
    expect(s.samples).toHaveLength(MAX_SAMPLES);
    expect(s.samples[0]).toBe('wnews-0:pure-lookup');
  });

  it('does not sample clean questions', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'wnews-0001', decideRuleGate([], false), false);
    expect(s.samples).toEqual([]);
  });
});

describe('recordRuleError', () => {
  it('records a thrown rule without claiming the question was audited clean', () => {
    // Review Focus 3. A rule that throws must be contained here; propagating
    // it reaches run-pipeline's per-cluster catch and discards every
    // remaining question for the claim.
    const s = emptyQualityRuleStats();
    recordRuleError(s, 'wnews-0007', new Error('Cannot read properties of undefined'));
    expect(s.ruleErrors).toBe(1);
    expect(s.audited).toBe(0);
    expect(s.samples[0]).toContain('wnews-0007');
    expect(s.samples[0]).toContain('Cannot read properties of undefined');
  });

  it('survives a non-Error throw', () => {
    const s = emptyQualityRuleStats();
    recordRuleError(s, 'wnews-0008', 'string thrown');
    expect(s.ruleErrors).toBe(1);
    expect(s.samples[0]).toContain('string thrown');
  });
});

describe('mergeQualityRuleStats', () => {
  it('sums counters and unions rule tallies', () => {
    const a = emptyQualityRuleStats();
    recordGate(a, 'a', decideRuleGate([blocking('pure-lookup')], false), false);
    const b = emptyQualityRuleStats();
    recordGate(b, 'b', decideRuleGate([blocking('pure-lookup'), advisory('partisan-framing')], false), false);
    recordRuleError(b, 'c', new Error('boom'));

    mergeQualityRuleStats(a, b);

    expect(a.audited).toBe(2);
    expect(a.withBlocking).toBe(2);
    expect(a.suppressed).toBe(2);
    expect(a.ruleErrors).toBe(1);
    expect(a.byRule).toEqual({ 'pure-lookup': 2, 'partisan-framing': 1 });
  });

  it('caps samples when merging', () => {
    const a = emptyQualityRuleStats();
    const b = emptyQualityRuleStats();
    for (let i = 0; i < MAX_SAMPLES; i++) {
      recordGate(a, `a-${i}`, decideRuleGate([blocking('pure-lookup')], false), false);
      recordGate(b, `b-${i}`, decideRuleGate([blocking('pure-lookup')], false), false);
    }
    mergeQualityRuleStats(a, b);
    expect(a.samples).toHaveLength(MAX_SAMPLES);
  });

  it('leaves the source untouched', () => {
    const a = emptyQualityRuleStats();
    const b = emptyQualityRuleStats();
    recordGate(b, 'b', decideRuleGate([], false), false);
    mergeQualityRuleStats(a, b);
    expect(b.audited).toBe(1);
  });
});
