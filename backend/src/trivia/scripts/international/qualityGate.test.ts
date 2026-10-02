import { describe, it, expect, afterEach } from 'vitest';
import type { Violation } from '../../services/qualityRules/types.js';
import {
  QUALITY_RULES_ENFORCE_ENV,
  qualityRulesEnforced,
  qualityRulesEnforcement,
  enforcedRuleNames,
  enforcesRule,
  enforceOnly,
  ENFORCE_NONE,
  ENFORCE_ALL,
  emptyQualityRuleStats,
  decideRuleGate,
  recordGate,
  recordRuleError,
  mergeQualityRuleStats,
  recordWrittenUnaudited,
  shouldRecordClaim,
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

  it('still treats the exact string "true" as enforce-everything', () => {
    // Load-bearing: "true" is what the boolean version of this flag meant, and
    // production may already carry it. A deploy that quietly downgraded a
    // fully-enforcing pipeline would be the worst regression available here.
    const e = qualityRulesEnforcement({ [QUALITY_RULES_ENFORCE_ENV]: 'true' });
    expect(e.all).toBe(true);
    expect(enforcesRule(e, 'anything-at-all')).toBe(true);
    expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: 'true' })).toBe(true);
  });

  it('is off for the empty, absent and explicitly-negative values', () => {
    for (const v of ['', '   ', 'false', 'none']) {
      expect(qualityRulesEnforced({ [QUALITY_RULES_ENFORCE_ENV]: v })).toBe(false);
    }
  });

  it('treats any other value as a rule-name list, typos included', () => {
    // Deliberate: this module stays free of the rules registry, so it cannot
    // tell a typo from a rule it has not heard of. The safety net is that an
    // unknown name matches no violation and therefore blocks nothing, and that
    // enforcedRuleNames() puts whatever was parsed into the cron log and the
    // generation_jobs notes row, where a typo is visible rather than silent.
    const e = qualityRulesEnforcement({ [QUALITY_RULES_ENFORCE_ENV]: 'yes' });
    expect(enforcesRule(e, 'yes')).toBe(true);
    expect(enforcesRule(e, 'nested-options')).toBe(false);
    expect(enforcedRuleNames({ [QUALITY_RULES_ENFORCE_ENV]: 'yes' })).toEqual(['yes']);
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
    process.env[QUALITY_RULES_ENFORCE_ENV] = 'nested-options';
    expect(qualityRulesEnforcement().all).toBe(false);
    expect(enforcesRule(qualityRulesEnforcement(), 'nested-options')).toBe(true);
  });
});

describe('per-rule enforcement', () => {
  it('parses a single rule name', () => {
    const e = qualityRulesEnforcement({ [QUALITY_RULES_ENFORCE_ENV]: 'nested-options' });
    expect(e.all).toBe(false);
    expect(enforcesRule(e, 'nested-options')).toBe(true);
    expect(enforcesRule(e, 'pure-lookup')).toBe(false);
  });

  it('parses a comma-separated list and tolerates whitespace', () => {
    const e = qualityRulesEnforcement({
      [QUALITY_RULES_ENFORCE_ENV]: ' nested-options , anachronistic-year-option ',
    });
    expect(enforcesRule(e, 'nested-options')).toBe(true);
    expect(enforcesRule(e, 'anachronistic-year-option')).toBe(true);
    expect(enforcesRule(e, 'pure-lookup')).toBe(false);
  });

  it('reports the enforcing rules for the notes row, sorted', () => {
    expect(enforcedRuleNames({ [QUALITY_RULES_ENFORCE_ENV]: 'pure-lookup,nested-options' }))
      .toEqual(['nested-options', 'pure-lookup']);
    expect(enforcedRuleNames({ [QUALITY_RULES_ENFORCE_ENV]: 'true' })).toEqual(['*']);
    expect(enforcedRuleNames({ [QUALITY_RULES_ENFORCE_ENV]: '' })).toEqual([]);
  });

  /**
   * The point of the whole change. `pure-lookup` matched 15.3% of the live news
   * bank, so enforcing it and `nested-options` together was never an option --
   * one switch for rules with wildly different false-positive rates meant the
   * safe rule could not be turned on at all.
   */
  it('blocks on the enforced rule while suppressing an unenforced one', () => {
    const only = enforceOnly('nested-options');

    const nested = decideRuleGate([blocking('nested-options')], only);
    expect(nested.write).toBe(false);
    expect(nested.enforced.map(v => v.rule)).toEqual(['nested-options']);

    const lookup = decideRuleGate([blocking('pure-lookup')], only);
    expect(lookup.write).toBe(true);
    expect(lookup.blocking).toHaveLength(1);
    expect(lookup.enforced).toEqual([]);
  });

  it('blocks a question carrying both, and names the enforced rule in the sample', () => {
    const s = emptyQualityRuleStats();
    const d = decideRuleGate(
      [blocking('pure-lookup'), blocking('nested-options')],
      enforceOnly('nested-options'),
    );

    expect(d.write).toBe(false);
    recordGate(s, 'wnews-0200', d);

    expect(s.blocked).toBe(1);
    expect(s.suppressed).toBe(0);
    // Not `pure-lookup`, even though it is first in the violation list: the
    // sample should name the rule that actually refused the write.
    expect(s.samples).toEqual(['wnews-0200:nested-options']);
    expect(s.byRule).toEqual({ 'pure-lookup': 1, 'nested-options': 1 });
  });

  it('counts an unenforced blocking violation as suppressed, and writes it', () => {
    const s = emptyQualityRuleStats();
    const d = decideRuleGate([blocking('pure-lookup')], enforceOnly('nested-options'));

    recordGate(s, 'wnews-0201', d);

    expect(d.write).toBe(true);
    expect(s.blocked).toBe(0);
    expect(s.suppressed).toBe(1);
    expect(s.withBlocking).toBe(1);
  });

  it('keeps shouldRecordClaim honest under partial enforcement', () => {
    // A claim whose only question was suppressed WAS written, so the claim is
    // covered and must be fingerprinted. Only a real block may withhold it.
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([blocking('pure-lookup')], enforceOnly('nested-options')));
    expect(shouldRecordClaim(1, s)).toBe(true);

    const t = emptyQualityRuleStats();
    recordGate(t, 'b', decideRuleGate([blocking('nested-options')], enforceOnly('nested-options')));
    expect(shouldRecordClaim(0, t)).toBe(false);
  });
});

describe('decideRuleGate', () => {
  it('writes a clean question', () => {
    const d = decideRuleGate([], ENFORCE_NONE);
    expect(d.write).toBe(true);
    expect(d.blocking).toEqual([]);
    expect(d.advisory).toEqual([]);
  });

  it('writes a question with advisory violations only, under either setting', () => {
    expect(decideRuleGate([advisory('partisan-framing')], ENFORCE_NONE).write).toBe(true);
    expect(decideRuleGate([advisory('partisan-framing')], ENFORCE_ALL).write).toBe(true);
  });

  it('writes a blocking-violation question when enforcement is off', () => {
    const d = decideRuleGate([blocking('anachronistic-year-option')], ENFORCE_NONE);
    expect(d.write).toBe(true);
    expect(d.blocking).toHaveLength(1);
  });

  it('refuses a blocking-violation question when enforcement is on', () => {
    const d = decideRuleGate([blocking('anachronistic-year-option')], ENFORCE_ALL);
    expect(d.write).toBe(false);
  });

  it('partitions mixed violations by severity', () => {
    const d = decideRuleGate(
      [blocking('ambiguous-answers'), advisory('partisan-framing'), blocking('pure-lookup')],
      ENFORCE_ALL,
    );
    expect(d.blocking.map(v => v.rule)).toEqual(['ambiguous-answers', 'pure-lookup']);
    expect(d.advisory.map(v => v.rule)).toEqual(['partisan-framing']);
  });
});

describe('recordGate', () => {
  it('counts a clean question as audited and nothing else', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'wnews-0001', decideRuleGate([], ENFORCE_NONE));
    expect(s).toMatchObject({
      audited: 1, withBlocking: 0, withAdvisoryOnly: 0, blocked: 0, suppressed: 0,
    });
    expect(s.byRule).toEqual({});
  });

  it('counts a blocking violation as SUPPRESSED, not blocked, when enforcement is off', () => {
    const s = emptyQualityRuleStats();
    const d = decideRuleGate([blocking('anachronistic-year-option')], ENFORCE_NONE);
    recordGate(s, 'wnews-0134', d);
    expect(s.withBlocking).toBe(1);
    expect(s.suppressed).toBe(1);
    expect(s.blocked).toBe(0);
  });

  it('counts a blocking violation as BLOCKED when enforcement is on', () => {
    const s = emptyQualityRuleStats();
    const d = decideRuleGate([blocking('anachronistic-year-option')], ENFORCE_ALL);
    recordGate(s, 'wnews-0134', d);
    expect(s.blocked).toBe(1);
    expect(s.suppressed).toBe(0);
  });

  it('tallies every violated rule by name, blocking and advisory alike', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([blocking('pure-lookup'), advisory('partisan-framing')], ENFORCE_NONE));
    recordGate(s, 'b', decideRuleGate([blocking('pure-lookup')], ENFORCE_NONE));
    expect(s.byRule).toEqual({ 'pure-lookup': 2, 'partisan-framing': 1 });
  });

  it('counts advisory-only separately from blocking', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([advisory('partisan-framing')], ENFORCE_NONE));
    expect(s.withAdvisoryOnly).toBe(1);
    expect(s.withBlocking).toBe(0);
  });

  it('samples the offending question ids, capped', () => {
    const s = emptyQualityRuleStats();
    for (let i = 0; i < MAX_SAMPLES + 5; i++) {
      recordGate(s, `wnews-${i}`, decideRuleGate([blocking('pure-lookup')], ENFORCE_NONE));
    }
    expect(s.withBlocking).toBe(MAX_SAMPLES + 5);
    expect(s.samples).toHaveLength(MAX_SAMPLES);
    expect(s.samples[0]).toBe('wnews-0:pure-lookup');
  });

  it('does not sample clean questions', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'wnews-0001', decideRuleGate([], ENFORCE_NONE));
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
    recordGate(a, 'a', decideRuleGate([blocking('pure-lookup')], ENFORCE_NONE));
    const b = emptyQualityRuleStats();
    recordGate(b, 'b', decideRuleGate([blocking('pure-lookup'), advisory('partisan-framing')], ENFORCE_NONE));
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
      recordGate(a, `a-${i}`, decideRuleGate([blocking('pure-lookup')], ENFORCE_NONE));
      recordGate(b, `b-${i}`, decideRuleGate([blocking('pure-lookup')], ENFORCE_NONE));
    }
    mergeQualityRuleStats(a, b);
    expect(a.samples).toHaveLength(MAX_SAMPLES);
  });

  it('leaves the source untouched', () => {
    const a = emptyQualityRuleStats();
    const b = emptyQualityRuleStats();
    recordGate(b, 'b', decideRuleGate([], ENFORCE_NONE));
    mergeQualityRuleStats(a, b);
    expect(b.audited).toBe(1);
  });
});

describe('shouldRecordClaim', () => {
  /**
   * run-pipeline records a claim fingerprint after writing, which suppresses the
   * story for CLAIM_WINDOW_DAYS = 14. The comment above that call promises:
   * "What is deliberately not remembered is a claim whose candidates were ALL
   * rejected by the gates, so a transient failure does not suppress the story
   * permanently."
   *
   * That held while `passing` was the last gate. It stopped holding the moment
   * the rules engine moved INSIDE writePassingQuestions, after that filter:
   * `written` can now be empty because the rules gate refused, and the claim
   * would be fingerprinted anyway. The news prompt generates one question for a
   * straightforward claim, so one blocking violation is enough to lose a story
   * for a fortnight with no link back to it.
   */
  it('records when questions were written', () => {
    const s = emptyQualityRuleStats();
    expect(shouldRecordClaim(2, s)).toBe(true);
  });

  it('records when nothing was written and the gate blocked nothing', () => {
    // The pre-existing benign case: every insert hit an external_id conflict,
    // which means the content is already present.
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([], ENFORCE_ALL));
    expect(shouldRecordClaim(0, s)).toBe(true);
  });

  it('does NOT record when the gate blocked every question', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([blocking('pure-lookup')], ENFORCE_ALL));
    expect(shouldRecordClaim(0, s)).toBe(false);
  });

  it('records when the gate blocked some but others were written', () => {
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([blocking('pure-lookup')], ENFORCE_ALL));
    recordGate(s, 'b', decideRuleGate([], ENFORCE_ALL));
    expect(shouldRecordClaim(1, s)).toBe(true);
  });

  it('is unaffected by suppressed violations, which were written', () => {
    // Enforcement OFF: the question WAS written, so the claim is covered.
    const s = emptyQualityRuleStats();
    recordGate(s, 'a', decideRuleGate([blocking('pure-lookup')], ENFORCE_NONE));
    expect(s.suppressed).toBe(1);
    expect(shouldRecordClaim(1, s)).toBe(true);
  });
});

describe('recordWrittenUnaudited', () => {
  it('counts a question written without a usable verdict', () => {
    // The catch around the audit falls through to the insert on purpose: a rule
    // that crashes is our defect, and refusing to write would turn a bug into
    // silent content loss. But that makes `written <= audited` false, so the
    // third outcome needs its own counter rather than an assumed invariant.
    const s = emptyQualityRuleStats();
    recordRuleError(s, 'wnews-0007', new Error('boom'));
    recordWrittenUnaudited(s);
    expect(s.audited).toBe(0);
    expect(s.ruleErrors).toBe(1);
    expect(s.writtenUnaudited).toBe(1);
  });

  it('merges like the other counters', () => {
    const a = emptyQualityRuleStats();
    const b = emptyQualityRuleStats();
    recordWrittenUnaudited(b);
    recordWrittenUnaudited(b);
    mergeQualityRuleStats(a, b);
    expect(a.writtenUnaudited).toBe(2);
  });
});
