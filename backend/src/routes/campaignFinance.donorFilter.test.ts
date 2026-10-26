import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

const { mockGetContributions } = vi.hoisted(() => ({ mockGetContributions: vi.fn() }));
vi.mock('../middleware/auth.js', () => ({ optionalAuth: (_req: unknown, _res: unknown, next: () => void) => next() }));
vi.mock('../lib/campaignFinanceSearchService.js', () => ({ searchPoliticians: vi.fn() }));
vi.mock('../lib/campaignFinanceService.js', () => ({
  getContributions: mockGetContributions,
  getSummary: vi.fn(),
  searchDonors: vi.fn(),
  getCouncilVotes: vi.fn(),
  validateConfidence: () => null,
}));

import campaignFinanceRouter from './campaignFinance.js';

const app = express();
app.use('/api/campaign-finance', campaignFinanceRouter);

const ID = '7e1e1044-a98b-4c69-910e-73de8e818c48';
const url = (qs: string) => `/api/campaign-finance/politician/${ID}/contributions?cycle=2026&${qs}`;

beforeEach(() => {
  mockGetContributions.mockReset();
  mockGetContributions.mockResolvedValue({
    response: { results: [], page_info: { has_next_page: false, end_cursor: '', total_count: 0 } },
    updatedAt: null,
  });
});

describe('GET /politician/:id/contributions ?donor=', () => {
  it('passes the donor name through exactly, untrimmed', async () => {
    const res = await request(app).get(url(`donor=${encodeURIComponent('A.B. DATA, LTD ')}`));
    expect(res.status).toBe(200);
    expect(mockGetContributions).toHaveBeenCalledWith(ID, expect.objectContaining({ donor: 'A.B. DATA, LTD ' }));
  });

  it('passes null when ?donor= is absent', async () => {
    await request(app).get(url('limit=20'));
    expect(mockGetContributions).toHaveBeenCalledWith(ID, expect.objectContaining({ donor: null }));
  });

  it.each([
    ['blank', 'donor=%20%20'],
    ['empty', 'donor='],
    ['repeated', 'donor=a&donor=b'],
    ['too long', `donor=${'x'.repeat(301)}`],
  ])('422 when donor is %s', async (_label, qs) => {
    const res = await request(app).get(url(qs));
    expect(res.status).toBe(422);
    expect(mockGetContributions).not.toHaveBeenCalled();
  });
});
