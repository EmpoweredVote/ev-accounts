import { describe, it, expect } from 'vitest';
import { JOBS, JOB_NAMES } from './registry.js';

/**
 * The registry is the CLI contract for `node dist/jobs/run.js <name>` and the list a
 * platform schedule (Render cron / Supabase Cron) references by string. Pin the names so
 * a renamed export or a typo can't silently drop a job.
 */
describe('jobs/registry', () => {
  const EXPECTED = [
    'calibration-lapse',
    'district-staleness',
    'fec-burst',
    'la-county-netfile',
    'ocpf',
    'reap-stale-ingestion-runs',
    'trivia-election-detection',
    'trivia-expiration',
    'trivia-pipeline',
    'vq-consensus',
    'vq-rotation',
  ];

  it('exposes exactly the expected job names, sorted', () => {
    expect(JOB_NAMES).toEqual([...EXPECTED].sort());
  });

  it('maps every job name to a callable', () => {
    for (const name of JOB_NAMES) {
      expect(typeof JOBS[name]).toBe('function');
    }
  });

  it('omits the default-off discovery sweep and the long-poll SQS worker', () => {
    // Both are intentionally NOT run-to-completion jobs — see registry.ts.
    expect(JOB_NAMES).not.toContain('discovery-sweep');
    expect(JOB_NAMES).not.toContain('sqs-worker');
  });
});
