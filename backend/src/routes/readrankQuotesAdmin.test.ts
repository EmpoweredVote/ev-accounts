import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// readrankQuotesAdmin.ts pulls in adminService.js (supabase.js + db.js) and requireAdmin.js
// at module scope. None are exercised here, but importing the router pulls them in
// transitively; without these mocks supabase.js's env validation process.exit(1)s in test.
// Mirrors the admin.test.ts convention.
vi.mock('../lib/db.js', () => ({ pool: { query: vi.fn() } }));
vi.mock('../lib/supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));

vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => { req.userId = 'admin-1'; next(); },
}));
vi.mock('../middleware/requireAdmin.js', () => ({
  requireAdmin: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

const { mockUpdate, mockDelete, mockClear, mockLogAdminAction } = vi.hoisted(() => ({
  mockUpdate: vi.fn(),
  mockDelete: vi.fn(),
  mockClear: vi.fn(),
  mockLogAdminAction: vi.fn(),
}));
vi.mock('../lib/readrankQuotesService.js', () => ({
  listReadrankPoliticians: vi.fn(),
  listReadrankQuotes: vi.fn(),
  selectReadrankQuote: vi.fn(),
  clearReadrankSelection: mockClear,
  updateReadrankQuote: mockUpdate,
  deleteReadrankQuote: mockDelete,
}));
vi.mock('../lib/adminService.js', () => ({ logAdminAction: mockLogAdminAction }));

import readrankRouter from './readrankQuotesAdmin.js';

const app = express();
app.use(express.json());
app.use('/api/admin/readrank-quotes', readrankRouter);

// Version nibble 4 and variant nibble 8 are required: zod 4's .uuid() enforces the
// RFC 4122 version+variant fields, which zod 3's did not. The all-1s / all-2s
// fixtures parsed under zod 3 and 422 under zod 4. No stored id is affected —
// every uuid in the database already conforms (checked 2026-08-27, 173,971 rows).
const UUID = '11111111-1111-4111-8111-111111111111';
const QUESTION_UUID = '22222222-2222-4222-8222-222222222222';

beforeEach(() => {
  mockUpdate.mockReset();
  mockDelete.mockReset();
  mockClear.mockReset();
  mockLogAdminAction.mockReset();
  mockLogAdminAction.mockResolvedValue(undefined);
});

describe('PUT /api/admin/readrank-quotes/deselect', () => {
  it('422 when politician_id is not a uuid', async () => {
    const res = await request(app).put('/api/admin/readrank-quotes/deselect').send({ politician_id: 'nope', topic_key: 'housing' });
    expect(res.status).toBe(422);
    expect(mockClear).not.toHaveBeenCalled();
  });

  it('422 when topic_key is empty', async () => {
    const res = await request(app).put('/api/admin/readrank-quotes/deselect').send({ politician_id: UUID, topic_key: '' });
    expect(res.status).toBe(422);
    expect(mockClear).not.toHaveBeenCalled();
  });

  it('200 clears the selection and audit-logs politician_id + topic_key', async () => {
    mockClear.mockResolvedValue(undefined);
    const res = await request(app).put('/api/admin/readrank-quotes/deselect').send({ politician_id: UUID, topic_key: 'housing' });
    expect(res.status).toBe(200);
    expect(mockClear).toHaveBeenCalledWith(UUID, 'housing', null); // no question_id -> whole topic
    expect(mockLogAdminAction).toHaveBeenCalledWith(
      'admin-1', 'readrank_quote.deselect', null, expect.objectContaining({ politician_id: UUID, topic_key: 'housing' }),
    );
  });

  it('500 when the service throws', async () => {
    mockClear.mockRejectedValue(new Error('boom'));
    const res = await request(app).put('/api/admin/readrank-quotes/deselect').send({ politician_id: UUID, topic_key: 'housing' });
    expect(res.status).toBe(500);
  });

  it('200 forwards an optional question_id so one question can be cleared alone', async () => {
    // Without this the admin can only clear a whole topic, which is too coarse for
    // a topic hosting several questions (migration 1377).
    mockClear.mockResolvedValue(undefined);
    const res = await request(app).put('/api/admin/readrank-quotes/deselect')
      .send({ politician_id: UUID, topic_key: 'economic-development', question_id: QUESTION_UUID });
    expect(res.status).toBe(200);
    expect(mockClear).toHaveBeenCalledWith(UUID, 'economic-development', QUESTION_UUID);
    expect(mockLogAdminAction).toHaveBeenCalledWith(
      'admin-1', 'readrank_quote.deselect', null,
      expect.objectContaining({ politician_id: UUID, topic_key: 'economic-development', question_id: QUESTION_UUID }),
    );
  });

  it('422 when question_id is present but not a uuid', async () => {
    const res = await request(app).put('/api/admin/readrank-quotes/deselect')
      .send({ politician_id: UUID, topic_key: 'housing', question_id: 'nope' });
    expect(res.status).toBe(422);
    expect(mockClear).not.toHaveBeenCalled();
  });
});

describe('PATCH /api/admin/readrank-quotes', () => {
  const body = { quote_id: UUID, quote_text: 'v', deidentified_text: 'd', source_url: 'https://x', source_name: 'X', editor_note: 'note' };

  it('422 when quote_id is not a uuid', async () => {
    const res = await request(app).patch('/api/admin/readrank-quotes').send({ ...body, quote_id: 'nope' });
    expect(res.status).toBe(422);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('422 when quote_text is empty', async () => {
    const res = await request(app).patch('/api/admin/readrank-quotes').send({ ...body, quote_text: '' });
    expect(res.status).toBe(422);
    expect(mockUpdate).not.toHaveBeenCalled();
  });

  it('200 updates and audit-logs with quote_id + changed fields', async () => {
    mockUpdate.mockResolvedValue(undefined);
    const res = await request(app).patch('/api/admin/readrank-quotes').send(body);
    expect(res.status).toBe(200);
    expect(mockUpdate).toHaveBeenCalledWith(UUID, {
      quoteText: 'v', deidentifiedText: 'd', sourceUrl: 'https://x', sourceName: 'X', editorNote: 'note',
    });
    expect(mockLogAdminAction).toHaveBeenCalledWith(
      'admin-1', 'readrank_quote.update', null, expect.objectContaining({ quote_id: UUID }),
    );
  });

  it('accepts null for the nullable fields', async () => {
    mockUpdate.mockResolvedValue(undefined);
    const res = await request(app)
      .patch('/api/admin/readrank-quotes')
      .send({ quote_id: UUID, quote_text: 'v', deidentified_text: null, source_url: null, source_name: null, editor_note: null });
    expect(res.status).toBe(200);
    expect(mockUpdate).toHaveBeenCalledWith(UUID, {
      quoteText: 'v', deidentifiedText: null, sourceUrl: null, sourceName: null, editorNote: null,
    });
  });

  it('404 when the service reports the quote is not found', async () => {
    mockUpdate.mockRejectedValue(new Error('Quote not found'));
    const res = await request(app).patch('/api/admin/readrank-quotes').send(body);
    expect(res.status).toBe(404);
  });

  it('422 when the service rejects clearing de-identified text', async () => {
    mockUpdate.mockRejectedValue(new Error('Cannot remove de-identified text from a selected quote'));
    const res = await request(app).patch('/api/admin/readrank-quotes').send(body);
    expect(res.status).toBe(422);
  });
});

describe('DELETE /api/admin/readrank-quotes/:quoteId', () => {
  it('422 when the id param is not a uuid', async () => {
    const res = await request(app).delete('/api/admin/readrank-quotes/nope');
    expect(res.status).toBe(422);
    expect(mockDelete).not.toHaveBeenCalled();
  });

  it('200 deletes and audit-logs with the quote_id', async () => {
    mockDelete.mockResolvedValue(undefined);
    const res = await request(app).delete(`/api/admin/readrank-quotes/${UUID}`);
    expect(res.status).toBe(200);
    expect(mockDelete).toHaveBeenCalledWith(UUID);
    expect(mockLogAdminAction).toHaveBeenCalledWith(
      'admin-1', 'readrank_quote.delete', null, expect.objectContaining({ quote_id: UUID }),
    );
  });

  it('404 when the service reports the quote is not found', async () => {
    mockDelete.mockRejectedValue(new Error('Quote not found'));
    const res = await request(app).delete(`/api/admin/readrank-quotes/${UUID}`);
    expect(res.status).toBe(404);
  });
});
