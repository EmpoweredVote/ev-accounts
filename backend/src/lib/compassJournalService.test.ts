import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import {
  listTopicJournal, listSeasonJournal,
  createEntry, resolveDefaultSeasonId,
} from './compassJournalService.js';

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

describe('resolveDefaultSeasonId', () => {
  it('prefers the open season over the draft one', async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 's-open' }] });
    expect(await resolveDefaultSeasonId()).toBe('s-open');
    expect(sql()).toMatch(/status IN \('open', 'draft'\)/);
  });

  // 🔴 There is no correct fallback. Stamping a CLOSED season backdates the
  // entry into a season it was not written for, and nothing downstream could
  // tell. Failing is the only honest option.
  it('THROWS rather than stamping a closed season', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await expect(resolveDefaultSeasonId()).rejects.toThrow(/NO_SEASON/);
  });
});

describe('createEntry — answers_id may not cross topics', () => {
  // Without this the two topics' threads splice together and a reader following
  // the link lands on a different question. A CHECK cannot express it: the rule
  // spans two rows.
  it('rejects answering an entry that belongs to another topic', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ topic_id: 't-OTHER' }] });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: null, answersId: 'j-elsewhere', attribution: 'handle',
    }, 'u1')).rejects.toThrow(/ANSWERS_WRONG_TOPIC/);
    // and it never reached the INSERT
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });

  it('rejects answering an entry that does not exist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: null, answersId: 'j-ghost', attribution: 'handle',
    }, 'u1')).rejects.toThrow(/ANSWERS_WRONG_TOPIC/);
  });

  it('inserts with the author id passed separately from the input', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'j-new' }] });
    const out = await createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: null, answersId: null, attribution: 'handle',
    }, 'u-admin');
    expect(out).toEqual({ id: 'j-new' });
    expect(mockQuery.mock.calls[0][1]).toContain('u-admin');
  });
});
