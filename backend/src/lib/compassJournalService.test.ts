import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));

import {
  listTopicJournal, listSeasonJournal, listJournalIndex,
  createEntry, resolveDefaultSeasonId, updateEntry, assertSeasonWritable,
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

describe('listJournalIndex', () => {
  const idxRow = (over = {}) => ({
    topic_id: 't1', entry_count: 3,
    latest_published_at: '2026-10-13T00:00:00Z', ...over,
  });

  it('filters to published in SQL, not in the mapping', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listJournalIndex();
    expect(sql()).toMatch(/status\s*=\s*'published'/);
  });

  // 🔴 THE WHOLE REASON THIS IS NOT ?season=N. An entry written in Season 2
  // about a change that shipped in Season 2 keeps its ⓘ when Season 3 opens;
  // scoping the index to a season would retire every older thread's affordance
  // at the rollover, which is a diary deleting itself.
  it('spans every season — it takes no season and filters on none', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listJournalIndex();
    expect(sql()).not.toMatch(/season/i);
    expect(mockQuery.mock.calls[0][1]).toBeUndefined();
  });

  it('groups by topic so one row per topic comes back', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listJournalIndex();
    expect(sql()).toMatch(/GROUP BY[\s\S]*topic_id/);
  });

  it('returns the count and the newest timestamp per topic', async () => {
    mockQuery.mockResolvedValue({ rows: [idxRow()] });
    expect(await listJournalIndex()).toEqual([
      { topicId: 't1', entryCount: 3, latestPublishedAt: '2026-10-13T00:00:00.000Z' },
    ]);
  });

  // Deferred finding #1 — pg hands back a Date and `lib/db.ts` sets no type
  // parsers, so the declared `string` is a lie for any in-process consumer.
  // Fixed here rather than inherited: the new field is coerced at the boundary.
  it('ships an ISO string even when pg hands back a Date', async () => {
    mockQuery.mockResolvedValue({
      rows: [idxRow({ latest_published_at: new Date('2026-10-13T00:00:00Z') })],
    });
    const [row] = await listJournalIndex();
    expect(row.latestPublishedAt).toBe('2026-10-13T00:00:00.000Z');
  });

  it('is an empty array when nothing is published, never null', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    expect(await listJournalIndex()).toEqual([]);
  });

  // A client that trusted a string count would render "NaN entries" and, worse,
  // `entryCount > 0` is the ⓘ gate: pg returns COUNT(*) as a string.
  it('normalises the count to a number', async () => {
    mockQuery.mockResolvedValue({ rows: [idxRow({ entry_count: '3' })] });
    expect((await listJournalIndex())[0].entryCount).toBe(3);
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

// ── Review fixes ────────────────────────────────────────────────────────────

/**
 * 🔴 C1. `connect.connected_profiles.legal_name` IS THE VAULTED IDENTITY NAME.
 * adminService.ts strips it even from an admin-only response — "vaulted
 * (id_vault), readable only via offline break-glass, never by the app or any
 * admin" — and says in the same breath that `empowered_profile.legal_name` is
 * the public one. This query published the vaulted column on an ANONYMOUS
 * endpoint: the precise de-anonymisation the attribution design exists to
 * prevent, introduced by the SQL feeding it.
 *
 * It had a second effect that hid the first: post-vault members have a NULL
 * Connect legal_name, so an Empowered author asking for `real` silently
 * rendered their handle and nobody would have noticed the source was wrong.
 */
describe('the byline never reads the vaulted Connect name', () => {
  it('takes legal_name from empowered_profiles, the published one', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    expect(sql()).toMatch(/ep\.legal_name/);
  });

  it('does not join connect.connected_profiles at all', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    expect(sql(), 'connected_profiles.legal_name is vaulted — ev-cto 0022')
      .not.toMatch(/connect\.connected_profiles/);
  });
});

/**
 * I4. Every other identity read in this codebase filters deleted_at
 * (profileService, candidateService, gemService). This one did not, so a
 * staffer who deleted their account kept their byline — and, if Empowered on
 * `real`, their legal name — on every published entry forever. is_active is
 * untouched by deletion, so the demotion clamp does not catch it.
 *
 * ⚠ The filters belong in the LEFT JOIN conditions, not in WHERE. In WHERE they
 * would drop the ENTRY; the entry stays published and only the identity goes.
 */
describe('a deleted account loses its byline, not its entries', () => {
  it('filters deleted_at on all three identity joins', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    const q = sql();
    expect(q).toMatch(/u\.deleted_at IS NULL/);
    expect(q).toMatch(/ep\.deleted_at IS NULL/);
  });

  it('keeps the deleted-account filters out of WHERE, so the entry survives', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await listTopicJournal('t1');
    const where = sql().split('WHERE')[1] ?? '';
    expect(where, 'a deleted author must cost the byline, never the entry')
      .not.toMatch(/deleted_at/);
  });
});

/**
 * I2. The same reasoning that guards answers_id applies verbatim to
 * revision_id, and it was missing. Spec §7 marks the `changed` entry whose
 * revision_id matches a reader's outstanding flag as the cause of their
 * change — so a Childcare revision pasted onto an Abortion entry tells a
 * reader with a Childcare flag that an Abortion entry explains it.
 */
describe('createEntry — revision_id may not cross topics either', () => {
  it('rejects a revision belonging to another topic', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ topic_id: 't-OTHER' }] });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: 'r-elsewhere', answersId: null, attribution: 'handle',
    }, 'u1')).rejects.toThrow(/REVISION_WRONG_TOPIC/);
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });

  it('rejects a revision that does not exist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: 'r-ghost', answersId: null, attribution: 'handle',
    }, 'u1')).rejects.toThrow(/REVISION_WRONG_TOPIC/);
  });

  it('accepts a revision on the same topic', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ topic_id: 't1' }] })
      .mockResolvedValueOnce({ rows: [{ id: 'j-new' }] });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: 'r-ok', answersId: null, attribution: 'handle',
    }, 'u1')).resolves.toEqual({ id: 'j-new' });
  });
});

/**
 * 🔴 I3. "One hop" was documented and never enforced. The no-forum guard
 * asserts the SERVICE never traverses; it cannot stop the DATA becoming a
 * chain. A -> B -> C all succeeded, and FC adopts this table as-is and would
 * render it as a thread — the §1 decision lost without a reply column ever
 * being added, which is exactly the shape the guard was written to catch.
 */
describe('createEntry — answers_id is one hop, not a chain', () => {
  it('rejects answering an entry that already answers something', async () => {
    mockQuery.mockResolvedValueOnce({
      rows: [{ topic_id: 't1', answers_id: 'j-prior' }],
    });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: null, answersId: 'j-middle', attribution: 'handle',
    }, 'u1')).rejects.toThrow(/ANSWERS_IS_A_CHAIN/);
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });

  it('accepts answering an entry that answers nothing', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ topic_id: 't1', answers_id: null }] })
      .mockResolvedValueOnce({ rows: [{ id: 'j-new' }] });
    await expect(createEntry({
      topicId: 't1', seasonId: 's1', kind: 'changed', title: null, body: 'x',
      revisionId: null, answersId: 'j-root', attribution: 'handle',
    }, 'u1')).resolves.toEqual({ id: 'j-new' });
  });
});

/**
 * I5. `COALESCE($2, title)` cannot tell "clear this" from "leave this alone",
 * so PATCH {"title": null} answered 200 {ok:true} and changed nothing. The API
 * reported success for work it did not do, and a title could never be cleared.
 * The SET list is now built from the keys actually present.
 */
describe('updateEntry writes only the fields it was given', () => {
  it('clears a title when explicitly sent null, without COALESCE', async () => {
    mockQuery.mockResolvedValue({ rowCount: 1 });
    await updateEntry('j1', { title: null });
    const q = sql();
    expect(q).toMatch(/title\s*=\s*\$2/);
    expect(q, 'COALESCE makes null indistinguishable from absent').not.toMatch(/COALESCE/i);
    expect(mockQuery.mock.calls[0][1]).toEqual(['j1', null]);
  });

  it('leaves a field alone when the key is absent', async () => {
    mockQuery.mockResolvedValue({ rowCount: 1 });
    await updateEntry('j1', { body: 'new body' });
    const q = sql();
    expect(q).toMatch(/body\s*=\s*\$2/);
    expect(q).not.toMatch(/title\s*=/);
    expect(q).not.toMatch(/attribution\s*=/);
  });

  // An empty patch must not claim to have written anything, and must not bump
  // updated_at — but it still has to answer "does that entry exist?" honestly.
  it('issues no UPDATE at all for an empty patch', async () => {
    mockQuery.mockResolvedValue({ rows: [{ id: 'j1' }] });
    await updateEntry('j1', {});
    expect(sql()).not.toMatch(/UPDATE/i);
  });
});

/**
 * I7. resolveDefaultSeasonId refuses to stamp a closed season, but an EXPLICIT
 * seasonId bypassed it entirely — validated as a uuid and nothing more. Same
 * harm, different door.
 */
describe('assertSeasonWritable', () => {
  it('accepts an open or draft season', async () => {
    mockQuery.mockResolvedValue({ rows: [{ status: 'draft' }] });
    await expect(assertSeasonWritable('s-draft')).resolves.toBeUndefined();
  });

  it('REFUSES a closed season', async () => {
    mockQuery.mockResolvedValue({ rows: [{ status: 'closed' }] });
    await expect(assertSeasonWritable('s-closed')).rejects.toThrow(/SEASON_CLOSED/);
  });

  it('refuses a season that does not exist', async () => {
    mockQuery.mockResolvedValue({ rows: [] });
    await expect(assertSeasonWritable('s-ghost')).rejects.toThrow(/SEASON_CLOSED/);
  });
});
