import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery, mockConnect, mockClientQuery, mockRelease } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  mockConnect: vi.fn(),
  mockClientQuery: vi.fn(),
  mockRelease: vi.fn(),
}));
vi.mock('./db.js', () => ({ pool: { query: mockQuery, connect: mockConnect } }));

import { listReadrankQuotes, selectReadrankQuote, clearReadrankSelection, updateReadrankQuote, deleteReadrankQuote } from './readrankQuotesService.js';

beforeEach(() => {
  mockQuery.mockReset();
  mockClientQuery.mockReset();
  mockRelease.mockReset();
  mockConnect.mockReset();
  mockConnect.mockResolvedValue({ query: mockClientQuery, release: mockRelease });
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
