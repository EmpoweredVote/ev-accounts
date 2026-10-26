import { describe, it, expect } from 'vitest';
import { evaluate, formatProblemLine, scheduleIntervalMinutes, type PgCronRow } from './jobHealthRules.js';

const now = new Date('2026-10-26T13:00:00Z');
const ago = (minutes: number) => new Date(now.getTime() - minutes * 60_000);

const job = (over: Partial<PgCronRow>): PgCronRow => ({
  jobname: 'j',
  schedule: '0 2 * * *',
  active: true,
  last_start: ago(60),
  fails: 0,
  first_fail_at: null,
  newest_fail_at: null,
  newest_fail_message: null,
  ...over,
});

const base = { now, pgCron: [], proofs: [], http: [], stranded: [] };

describe('scheduleIntervalMinutes', () => {
  it.each([
    ['*/5 * * * *', 5],
    ['0 * * * *', 60],
    ['0 2 * * *', 1440],
    ['17 8 * * *', 1440],
    ['0 3 * * 0', 10080],
    ['0 4 1 * *', 44640],
    ['30 seconds', 1],
    ['* * * * *', 1],
    ['0 */6 * * *', 360],
  ])('%s -> %i', (s, m) => expect(scheduleIntervalMinutes(s)).toBe(m));

  it('returns null for shapes it does not know', () => {
    expect(scheduleIntervalMinutes('0 0 1 1 *')).toBeNull();
    expect(scheduleIntervalMinutes('@daily')).toBeNull();
  });
});

describe('evaluate', () => {
  it('is silent on a healthy day', () => {
    expect(
      evaluate({
        ...base,
        pgCron: [job({}), job({ schedule: '*/5 * * * *', last_start: ago(4) })],
        proofs: [{ job: 'ev-jobs-ocpf', newest: ago(20 * 1440), maxAgeMinutes: 40 * 1440 }],
      }),
    ).toEqual([]);
  });

  it('reports failures with count and newest message, timed from the first failure', () => {
    const [p] = evaluate({
      ...base,
      pgCron: [job({ jobname: 'refresh-donor-names-search', fails: 2, first_fail_at: ago(1500), newest_fail_at: ago(60), newest_fail_message: 'ERROR:  canceling statement\n due to statement timeout' })],
    });
    expect(p.job).toBe('refresh-donor-names-search');
    expect(p.what).toBe('2 failed runs in the last 24h — newest: ERROR: canceling statement due to statement timeout');
    expect(formatProblemLine(p, now)).toMatch(/— for 1d 1h$/);
  });

  it('flags a job whose newest run is older than three intervals — the case failures cannot see', () => {
    const problems = evaluate({ ...base, pgCron: [job({ last_start: ago(3 * 1440 + 1) }), job({ jobname: 'ok', last_start: ago(3 * 1440 - 1) })] });
    expect(problems.map((p) => p.job)).toEqual(['j']);
    expect(problems[0].what).toMatch(/^no run since/);
  });

  it('ignores staleness on a paused job but still reports its failures', () => {
    const problems = evaluate({ ...base, pgCron: [job({ active: false, last_start: ago(99_999), fails: 1, first_fail_at: ago(10) })] });
    expect(problems).toHaveLength(1);
    expect(problems[0].what).toMatch(/failed run/);
  });

  it('flags stale and missing Render proofs', () => {
    const problems = evaluate({
      ...base,
      proofs: [
        { job: 'ev-jobs-fec-burst', newest: ago(49 * 60), maxAgeMinutes: 48 * 60 },
        { job: 'ev-jobs-trivia-pipeline', newest: null, maxAgeMinutes: 48 * 60 },
      ],
    });
    expect(problems.map((p) => p.job)).toEqual(['ev-jobs-fec-burst', 'ev-jobs-trivia-pipeline']);
  });

  it('reports stranded runs and refused HTTP triggers', () => {
    const problems = evaluate({
      ...base,
      stranded: [{ adapter_name: 'fec', runs: 3, oldest_start: ago(2000) }],
      http: [{ status_code: 401, timed_out: false, error_msg: null, responses: 72, first_seen: ago(360) }],
    });
    expect(problems.map((p) => p.what)).toEqual([
      "3 runs stuck in 'running' for over 24h",
      '72 requests answered HTTP 401',
    ]);
  });

  it('the test override trips every job, including ones with an unparsed schedule', () => {
    const problems = evaluate({
      ...base,
      staleOverrideMinutes: 1,
      pgCron: [job({ last_start: ago(2) }), job({ jobname: 'odd', schedule: '@daily', last_start: ago(2) })],
      proofs: [{ job: 'ev-jobs-ocpf', newest: ago(2), maxAgeMinutes: 40 * 1440 }],
    });
    expect(problems.map((p) => p.job)).toEqual(['j', 'odd', 'ev-jobs-ocpf']);
  });
});
