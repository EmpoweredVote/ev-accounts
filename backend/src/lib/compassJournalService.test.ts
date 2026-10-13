import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import { listTopicJournal, listSeasonJournal } from './compassJournalService.js';

beforeEach(() => mockQuery.mockReset());

const row = (over = {}) => ({
  id: 'j1', topic_id: 't1', kind: 'changed', title: 'Why Childcare split',
  body: 'We saw 85 officials...', season_number: 2, season_name: 'Season 2',
  revision_id: 'r9', answers_id: 'j0', published_at: '2026-10-13T00:00:00Z',
  attribution: 'handle', display_name: 'riverkeeper', legal_name: 'Dana Reyes',
  is_empowered: false, ...over,
});

const sql = () => mockQuery.mock.calls[0][0] as string;

describe('listTopicJournal', () => {
  // 🔴 THE WORST FAILURE AVAILABLE HERE. A draft is the team thinking out loud.
  // Asserted on the QUERY, because a fixture that happens to contain no drafts
  // passes against a filter that was deleted.
  it('filters to published in SQL, not in the mapping', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    expect(sql()).toMatch(/status\s*=\s*'published'/);
  });

  it('returns newest first', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    expect(sql()).toMatch(/ORDER BY[\s\S]*published_at DESC/);
  });

  // Tier is a row's existence. A query reading a `tier` column would compile,
  // return undefined, and silently clamp every Empowered author to a handle.
  it('derives tier from an empowered_profiles row, never a column', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    const q = sql();
    expect(q).toContain('empower.empowered_profiles');
    expect(q).toMatch(/is_active/);
    expect(q).not.toMatch(/\btier\b/);
  });

  it('ships a resolved byline and never the raw identity fields', async () => {
    mockQuery.mockResolvedValue({ rows: [row()] });
    const [entry] = await listTopicJournal('t1');

    expect(entry.author).toEqual({ label: 'riverkeeper' });
    expect(JSON.stringify(entry)).not.toContain('Dana Reyes');
    expect(JSON.stringify(entry)).not.toContain('attribution');
  });

  it('clamps a Connected author who asked for their real name', async () => {
    mockQuery.mockResolvedValue({ rows: [row({ attribution: 'real', is_empowered: false })] });
    expect((await listTopicJournal('t1'))[0].author.label).toBe('riverkeeper');
  });

  it('honours an Empowered author who asked for their real name', async () => {
    mockQuery.mockResolvedValue({ rows: [row({ attribution: 'real', is_empowered: true })] });
    expect((await listTopicJournal('t1'))[0].author.label).toBe('Dana Reyes');
  });

  it('maps the season into a nested object', async () => {
    mockQuery.mockResolvedValue({ rows: [row()] });
    expect((await listTopicJournal('t1'))[0].season).toEqual({ number: 2, name: 'Season 2' });
  });

  it('passes the topic id as a parameter, never interpolated', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal("t1'; DROP TABLE x;--");
    expect(sql()).not.toContain('DROP TABLE');
    expect(mockQuery.mock.calls[0][1]).toEqual(["t1'; DROP TABLE x;--"]);
  });
});

describe('listSeasonJournal', () => {
  it('filters to published and to the season number given', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listSeasonJournal(3);
    expect(sql()).toMatch(/status\s*=\s*'published'/);
    expect(mockQuery.mock.calls[0][1]).toEqual([3]);
  });
});
