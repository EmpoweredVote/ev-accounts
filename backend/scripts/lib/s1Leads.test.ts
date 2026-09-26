import { describe, it, expect } from 'vitest';
import { seedState, leadsById, type S1Lead } from './s1Leads.js';

const lead = (topic_id: string): S1Lead => ({
  topic_id, topic_key: `k-${topic_id}`, season_number: 1, value: 4, pin_revision_id: 'r1',
  reasoning: 'r', sources: ['https://x.gov'], seed: 'fresh',
});

describe('seedState', () => {
  it('is fresh when the pin and served revision agree', () => {
    expect(seedState('a', 'a')).toBe('fresh');
  });
  it('is stale when the pin and served revision differ', () => {
    expect(seedState('a', 'b')).toBe('stale');
  });
});

describe('leadsById', () => {
  it('keys the leads by topic_id', () => {
    const map = leadsById([lead('t1'), lead('t2')]);
    expect(map.get('t1')?.topic_id).toBe('t1');
    expect(map.get('t2')?.topic_id).toBe('t2');
    expect(map.size).toBe(2);
  });
});
