import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery, mockConnect, mockClientQuery, mockRelease } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  mockConnect: vi.fn(),
  mockClientQuery: vi.fn(),
  mockRelease: vi.fn(),
}));
vi.mock('./db.js', () => ({ pool: { query: mockQuery, connect: mockConnect } }));

import { listReadrankPoliticians, listReadrankQuotes, selectReadrankQuote, clearReadrankSelection, updateReadrankQuote, deleteReadrankQuote } from './readrankQuotesService.js';

beforeEach(() => {
  mockQuery.mockReset();
  mockClientQuery.mockReset();
  mockRelease.mockReset();
  mockConnect.mockReset();
  mockConnect.mockResolvedValue({ query: mockClientQuery, release: mockRelease });
});

describe('listReadrankPoliticians', () => {
  it('maps rows and resolves the office title via current_office_holders (migration 1463)', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { id: 'p1', name: 'Alex Doe', office_title: 'Mayor', state: 'IN', quote_count: '4', selected_count: '2' },
    ] });
    const out = await listReadrankPoliticians();
    expect(out).toEqual([
      { id: 'p1', name: 'Alex Doe', officeTitle: 'Mayor', state: 'IN', quoteCount: 4, selectedCount: 2 },
    ]);

    const sql = String(mockQuery.mock.calls[0][0]);
    // 1463 dropped essentials.offices.politician_id — occupancy must resolve through the view.
    expect(sql).toContain('essentials.current_office_holders');
    expect(sql).toMatch(/coh\.politician_id\s*=\s*p\.id/);
    // The pre-1463 shape: an unqualified politician_id filter directly on essentials.offices.
    expect(sql).not.toMatch(/essentials\.offices\s+WHERE\s+politician_id/i);
  });
});

describe('listReadrankQuotes', () => {
  it('groups quotes by topic_key', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { id: 'q1', topic_key: 'healthcare', quote_text: 'a', deidentified_text: 'A', source_url: null, source_name: null, readrank_selected: true },
      { id: 'q2', topic_key: 'healthcare', quote_text: 'b', deidentified_text: 'B', source_url: null, source_name: null, readrank_selected: false },
      { id: 'q3', topic_key: 'housing', quote_text: 'c', deidentified_text: null, source_url: null, source_name: null, readrank_selected: false },
    ] });
    const out = await listReadrankQuotes('pol-1');
    expect(out.map((t) => t.topicKey)).toEqual(['healthcare', 'housing']);
    expect(out[0].quotes).toHaveLength(2);
    expect(out[0].quotes[0]).toMatchObject({ id: 'q1', readrankSelected: true });
  });
});

describe('listReadrankQuotes — grouped by question', () => {
  it('splits two questions in one topic into two groups', async () => {
    // The admin page renders one radio group per group returned here. Grouping by
    // topic gave a split topic ONE radio group, so the editor physically could not
    // select an answer to each question — the UI enforced the retired invariant.
    mockQuery.mockResolvedValueOnce({ rows: [
      { id: 'bass-film', topic_key: 'economic-development', question_id: 'q-film', question_text: 'Film and TV?', quote_text: 'a', deidentified_text: 'A', source_url: null, source_name: null, editor_note: null, readrank_selected: true },
      { id: 'bass-downtown', topic_key: 'economic-development', question_id: 'q-downtown', question_text: 'Downtown?', quote_text: 'b', deidentified_text: 'B', source_url: null, source_name: null, editor_note: null, readrank_selected: false },
    ] });

    const out = await listReadrankQuotes('bass');

    expect(out).toHaveLength(2);
    expect(out.map((g) => g.key).sort()).toEqual(['q-downtown', 'q-film']);
    expect(out.map((g) => g.topicKey)).toEqual(['economic-development', 'economic-development']);
    const film = out.find((g) => g.questionId === 'q-film')!;
    expect(film.questionText).toBe('Film and TV?');
    expect(film.quotes.map((q) => q.id)).toEqual(['bass-film']);
  });

  it('keeps compass-era quotes in one topic group', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [
      { id: 'q1', topic_key: 'healthcare', question_id: null, question_text: null, quote_text: 'a', deidentified_text: 'A', source_url: null, source_name: null, editor_note: null, readrank_selected: true },
      { id: 'q2', topic_key: 'healthcare', question_id: null, question_text: null, quote_text: 'b', deidentified_text: 'B', source_url: null, source_name: null, editor_note: null, readrank_selected: false },
      { id: 'q3', topic_key: 'housing', question_id: null, question_text: null, quote_text: 'c', deidentified_text: null, source_url: null, source_name: null, editor_note: null, readrank_selected: false },
    ] });

    const out = await listReadrankQuotes('pol-1');

    expect(out.map((g) => g.key)).toEqual(['topic:healthcare', 'topic:housing']);
    expect(out[0].quotes).toHaveLength(2);
    expect(out[0]).toMatchObject({ topicKey: 'healthcare', questionId: null, questionText: null });
  });
});

describe('selectReadrankQuote', () => {
  it('rejects selecting a quote with no de-identified text', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ politician_id: 'pol-1', topic_key: 'healthcare', deidentified_text: null }] });
    await expect(selectReadrankQuote('q3')).rejects.toThrow(/de-identified/i);
    expect(mockConnect).not.toHaveBeenCalled();
  });

  it('throws when the quote id does not exist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await expect(selectReadrankQuote('nope')).rejects.toThrow(/not found/i);
    expect(mockConnect).not.toHaveBeenCalled();
  });

  it('clears siblings then selects the target in a transaction on one client', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ politician_id: 'pol-1', topic_key: 'Healthcare', deidentified_text: 'A' }] });
    mockClientQuery.mockResolvedValue({});
    await selectReadrankQuote('q1');
    const sql = mockClientQuery.mock.calls.map((c) => String(c[0]));
    expect(sql[0]).toBe('BEGIN');
    expect(sql[sql.length - 1]).toBe('COMMIT');
    const falseIdx = sql.findIndex((s) => /readrank_selected\s*=\s*false/i.test(s));
    const trueIdx = sql.findIndex((s) => /readrank_selected\s*=\s*true/i.test(s));
    expect(falseIdx).toBeGreaterThan(-1);
    expect(trueIdx).toBeGreaterThan(falseIdx);
    expect(mockRelease).toHaveBeenCalledTimes(1);
  });

  it('rolls back and releases the client when an update fails', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ politician_id: 'pol-1', topic_key: 'healthcare', deidentified_text: 'A' }] });
    mockClientQuery
      .mockResolvedValueOnce({})                 // BEGIN
      .mockResolvedValueOnce({})                 // clear siblings
      .mockRejectedValueOnce(new Error('boom')); // set target fails
    await expect(selectReadrankQuote('q1')).rejects.toThrow('boom');
    const sql = mockClientQuery.mock.calls.map((c) => String(c[0]));
    expect(sql).toContain('ROLLBACK');
    expect(mockRelease).toHaveBeenCalledTimes(1);
  });
});

// ---------------------------------------------------------------------------
// Selecting is scoped to the QUESTION, not the topic.
//
// The topic-wide clear was the live trap: with two econ-dev questions in the LA
// Mayor race, selecting Raman's downtown quote ALSO unselected Raman's film quote.
// Film then held only Bass and downtown only Raman — the partial unique index was
// satisfied, nothing errored, and the game paired Bass's film answer against
// Raman's downtown answer under one question heading.
// ---------------------------------------------------------------------------

describe('selectReadrankQuote — scoped to the question', () => {
  it('clears only the same question, leaving a sibling question in the topic selected', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{
      politician_id: 'raman', topic_key: 'economic-development',
      question_id: 'q-downtown', deidentified_text: 'Invest in transit first.',
    }] });
    mockClientQuery.mockResolvedValue({});

    await selectReadrankQuote('raman-downtown');

    const clear = mockClientQuery.mock.calls.find((c) => /readrank_selected\s*=\s*false/i.test(String(c[0])))!;
    expect(String(clear[0])).toMatch(/question_id\s*=\s*\$2/i);
    // A topic_key predicate here would sweep up the film selection.
    expect(String(clear[0])).not.toMatch(/topic_key/i);
    expect(clear[1]).toEqual(['raman', 'q-downtown']);
  });

  it('falls back to the topic for a compass-era quote with no question_id', async () => {
    // question_id IS NULL predates 1377. Those quotes group by topic, so the
    // "one selected per card" rule for them is still one per (candidate, topic) —
    // and must not clear the topic's question-bearing selections.
    mockQuery.mockResolvedValueOnce({ rows: [{
      politician_id: 'pol-1', topic_key: 'Healthcare',
      question_id: null, deidentified_text: 'A',
    }] });
    mockClientQuery.mockResolvedValue({});

    await selectReadrankQuote('q1');

    const clear = mockClientQuery.mock.calls.find((c) => /readrank_selected\s*=\s*false/i.test(String(c[0])))!;
    expect(String(clear[0])).toMatch(/lower\(topic_key\)\s*=\s*lower\(\$2\)/i);
    expect(String(clear[0])).toMatch(/question_id\s+IS\s+NULL/i);
    expect(clear[1]).toEqual(['pol-1', 'Healthcare']);
  });
});

describe('clearReadrankSelection', () => {
  it('clears every selected quote in the candidate+topic group (case-insensitive topic)', async () => {
    mockQuery.mockResolvedValueOnce({ rowCount: 1 });
    await expect(clearReadrankSelection('pol-1', 'Healthcare')).resolves.toBeUndefined();
    const call = mockQuery.mock.calls[0];
    const sql = String(call[0]);
    expect(sql).toMatch(/UPDATE\s+essentials\.quotes/i);
    expect(sql).toMatch(/readrank_selected\s*=\s*false/i);
    expect(sql).toMatch(/lower\(topic_key\)\s*=\s*lower\(\$2\)/i);
    expect(call[1]).toEqual(['pol-1', 'Healthcare']);
  });

  it('is idempotent — resolves even when nothing was selected', async () => {
    mockQuery.mockResolvedValueOnce({ rowCount: 0 });
    await expect(clearReadrankSelection('pol-1', 'housing')).resolves.toBeUndefined();
  });

  it('clears just one question when given a question id', async () => {
    // Turning ONE question off in a split topic must not take its sibling with it.
    mockQuery.mockResolvedValueOnce({ rowCount: 1 });
    await clearReadrankSelection('raman', 'economic-development', 'q-downtown');
    const call = mockQuery.mock.calls[0];
    expect(String(call[0])).toMatch(/question_id\s*=\s*\$2/i);
    expect(String(call[0])).not.toMatch(/topic_key/i);
    expect(call[1]).toEqual(['raman', 'q-downtown']);
  });
});

describe('updateReadrankQuote', () => {
  const validFields = { quoteText: 'new verbatim', deidentifiedText: 'new deid', sourceUrl: 'https://x', sourceName: 'X', editorNote: 'note' };

  it('throws when the quote id does not exist', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [] });
    await expect(updateReadrankQuote('nope', validFields)).rejects.toThrow(/not found/i);
    expect(mockQuery).toHaveBeenCalledTimes(1); // no UPDATE issued
  });

  it('rejects clearing de-identified text on a selected quote', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ readrank_selected: true }] });
    await expect(
      updateReadrankQuote('q1', { ...validFields, deidentifiedText: null }),
    ).rejects.toThrow(/de-identified/i);
    expect(mockQuery).toHaveBeenCalledTimes(1); // guard fires before UPDATE
  });

  it('rejects whitespace-only de-identified text on a selected quote', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ readrank_selected: true }] });
    await expect(
      updateReadrankQuote('q1', { ...validFields, deidentifiedText: '   ' }),
    ).rejects.toThrow(/de-identified/i);
    expect(mockQuery).toHaveBeenCalledTimes(1);
  });

  it('updates only the four content columns, never id/topic/selected fields', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ readrank_selected: false }] }) // existence + selected lookup
      .mockResolvedValueOnce({ rowCount: 1 });                          // UPDATE
    await updateReadrankQuote('q1', validFields);
    const updateCall = mockQuery.mock.calls[1];
    const sql = String(updateCall[0]);
    expect(sql).toMatch(/UPDATE\s+essentials\.quotes/i);
    expect(sql).toMatch(/quote_text\s*=/i);
    expect(sql).toMatch(/deidentified_text\s*=/i);
    expect(sql).toMatch(/source_url\s*=/i);
    expect(sql).toMatch(/source_name\s*=/i);
    expect(sql).toMatch(/editor_note\s*=/i);
    expect(sql).not.toMatch(/politician_id\s*=/i);
    expect(sql).not.toMatch(/topic_key\s*=/i);
    expect(sql).not.toMatch(/readrank_selected\s*=/i);
    expect(updateCall[1]).toEqual(['q1', 'new verbatim', 'new deid', 'https://x', 'X', 'note']);
  });

  it('allows null de-identified text when the quote is not selected', async () => {
    mockQuery
      .mockResolvedValueOnce({ rows: [{ readrank_selected: false }] })
      .mockResolvedValueOnce({ rowCount: 1 });
    await expect(
      updateReadrankQuote('q1', { ...validFields, deidentifiedText: null }),
    ).resolves.toBeUndefined();
    expect(mockQuery.mock.calls[1][1]).toEqual(['q1', 'new verbatim', null, 'https://x', 'X', 'note']);
  });
});

describe('deleteReadrankQuote', () => {
  it('throws when nothing was deleted', async () => {
    mockQuery.mockResolvedValueOnce({ rowCount: 0 });
    await expect(deleteReadrankQuote('nope')).rejects.toThrow(/not found/i);
  });

  it('deletes the row by id', async () => {
    mockQuery.mockResolvedValueOnce({ rowCount: 1 });
    await expect(deleteReadrankQuote('q1')).resolves.toBeUndefined();
    const call = mockQuery.mock.calls[0];
    expect(String(call[0])).toMatch(/DELETE\s+FROM\s+essentials\.quotes/i);
    expect(call[1]).toEqual(['q1']);
  });
});
