import { vi, describe, it, expect, beforeEach } from 'vitest';

const { mockQuery, mockConnect, mockClientQuery, mockRelease } = vi.hoisted(() => ({
  mockQuery: vi.fn(),
  mockConnect: vi.fn(),
  mockClientQuery: vi.fn(),
  mockRelease: vi.fn(),
}));
vi.mock('./db.js', () => ({ pool: { query: mockQuery, connect: mockConnect } }));

import { listReadrankQuotes, selectReadrankQuote } from './readrankQuotesService.js';

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
