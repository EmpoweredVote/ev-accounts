import { beforeEach, describe, expect, it, vi } from 'vitest';
import express from 'express';
import request from 'supertest';

const ITEM_ID = '33333333-3333-4333-8333-333333333333';

const { mockGetAgendaItemById } = vi.hoisted(() => ({
  mockGetAgendaItemById: vi.fn(),
}));

vi.mock('../lib/agendaItemsService.js', () => ({
  getAgendaItemById: mockGetAgendaItemById,
}));

vi.mock('../middleware/auth.js', () => ({
  optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
  requireAuth: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

import agendaItemsRouter from './agendaItems.js';

const app = express();
app.use(express.json());
app.use('/api/agenda-items', agendaItemsRouter);

beforeEach(() => {
  mockGetAgendaItemById.mockReset();
});

describe('GET /api/agenda-items/:id', () => {
  it('422s on non-UUID', async () => {
    const res = await request(app).get('/api/agenda-items/nope');
    expect(res.status).toBe(422);
    expect(res.body.code).toBe('INVALID_ID');
  });

  it('404s when missing', async () => {
    mockGetAgendaItemById.mockResolvedValueOnce(null);
    const res = await request(app).get(`/api/agenda-items/${ITEM_ID}`);
    expect(res.status).toBe(404);
    expect(res.body.code).toBe('NOT_FOUND');
  });

  it('returns the item detail', async () => {
    mockGetAgendaItemById.mockResolvedValueOnce({ id: ITEM_ID, itemNumber: '6A' });
    const res = await request(app).get(`/api/agenda-items/${ITEM_ID}`);
    expect(res.status).toBe(200);
    expect(res.body.itemNumber).toBe('6A');
  });

  it('500s with INTERNAL_ERROR on service failure', async () => {
    mockGetAgendaItemById.mockRejectedValueOnce(new Error('boom'));
    const res = await request(app).get(`/api/agenda-items/${ITEM_ID}`);
    expect(res.status).toBe(500);
    expect(res.body.code).toBe('INTERNAL_ERROR');
  });
});
