import { describe, expect, it } from 'vitest';
import { statusOf, type StateCount } from './stage5Progress.js';

const c = (over: Partial<StateCount>): StateCount => ({ state: 'XX', sitting: 100, written: 0, outcomes: {}, pending: 0, ...over });

describe('statusOf', () => {
  it('reads a state from its own run list when one is on file', () => {
    expect(statusOf(c({ written: 60, scope: 60, scopeWritten: 60 }))).toBe('done');       // the run dropped 40 who lost or left
    expect(statusOf(c({ written: 99, scope: 100, scopeWritten: 99 }))).toBe('done');      // one person held
    expect(statusOf(c({ written: 80, scope: 100, scopeWritten: 80 }))).toBe('part');
    expect(statusOf(c({ written: 60, scope: 60, scopeWritten: 60, pending: 3 }))).toBe('to approve');
  });
  it('falls back to the roster, and tells an empty roster from an unstarted state', () => {
    expect(statusOf(c({ written: 70 }))).toBe('done');
    expect(statusOf(c({ written: 50 }))).toBe('part');
    expect(statusOf(c({}))).toBe('not started');
    expect(statusOf(c({ sitting: 5 }))).toBe('no roster');
    expect(statusOf(c({ sitting: 5, written: 4 }))).toBe('done');
  });
});
