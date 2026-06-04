import { vi, describe, it, expect } from 'vitest';

// Mock DB and Supabase imports so env validation doesn't run during unit tests
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('./supabase.js', () => ({
  adminRpc: vi.fn(),
  supabaseAnon: { schema: vi.fn() },
  createUserClient: vi.fn(),
}));

import { groupCitationRows } from './compassService.js';

const base = {
  topic_key: 'healthcare',
  topic_title: 'Should the federal government provide universal healthcare?',
  topic_tension_name: 'Healthcare Policy',
  stance_value: 3 as number | null,
  stance_text: 'Supports a public option alongside private insurance' as string | null,
  reasoning: 'Voted for ACA expansion' as string | null,
  source_url: 'https://congress.gov/bill/123',
  snippet: 'voted yes on the expansion',
  verified_at: '2026-05-01T00:00:00Z',
  is_primary: true as boolean,
};

describe('groupCitationRows', () => {
  it('groups multiple citations for the same topic into one block', () => {
    const rows = [
      base,
      { ...base, source_url: 'https://govtrack.us/bill/456', snippet: 'supports expansion', is_primary: false, verified_at: '2026-04-01T00:00:00Z' },
    ];
    const blocks = groupCitationRows(rows);
    expect(blocks).toHaveLength(1);
    expect(blocks[0].citations).toHaveLength(2);
  });

  it('sets has_stance true when stance_value is non-null', () => {
    const blocks = groupCitationRows([base]);
    expect(blocks[0].has_stance).toBe(true);
    expect(blocks[0].stance_value).toBe(3);
    expect(blocks[0].stance_text).toBe('Supports a public option alongside private insurance');
  });

  it('sets has_stance false when stance_value is null', () => {
    const blocks = groupCitationRows([{ ...base, stance_value: null, stance_text: null }]);
    expect(blocks[0].has_stance).toBe(false);
    expect(blocks[0].stance_value).toBe(null);
  });

  it('extracts hostname from source_url', () => {
    const blocks = groupCitationRows([base]);
    expect(blocks[0].citations[0].domain).toBe('congress.gov');
  });

  it('falls back to raw url when domain extraction fails', () => {
    const blocks = groupCitationRows([{ ...base, source_url: 'not-a-valid-url' }]);
    expect(blocks[0].citations[0].domain).toBe('not-a-valid-url');
  });

  it('tracks last_verified_at as the max across all citations', () => {
    const rows = [
      { ...base, source_url: 'https://b.example', snippet: 'other', verified_at: '2026-05-15T00:00:00Z' },
      { ...base, verified_at: '2026-03-01T00:00:00Z' },
    ];
    const blocks = groupCitationRows(rows);
    expect(blocks[0].last_verified_at).toBe('2026-05-15T00:00:00Z');
  });

  it('produces one block per unique topic_key', () => {
    const rows = [
      base,
      { ...base, topic_key: 'climate', topic_title: 'Climate question?', topic_tension_name: 'Climate Policy', source_url: 'https://c.example', snippet: 'climate snippet' },
    ];
    const blocks = groupCitationRows(rows);
    expect(blocks).toHaveLength(2);
    expect(blocks.map(b => b.topic_key).sort()).toEqual(['climate', 'healthcare']);
  });

  it('returns empty array for empty input', () => {
    expect(groupCitationRows([])).toEqual([]);
  });
});
