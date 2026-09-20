import { describe, it, expect, beforeEach, vi } from 'vitest';
const { mockQuery } = vi.hoisted(() => ({ mockQuery: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: mockQuery } }));
import {
  acceptEvidence, rejectEvidence, rehomeEvidence, listPendingEvidence, REJECT_REASONS,
} from './evidenceReviewService.js';

beforeEach(() => { mockQuery.mockReset(); mockQuery.mockResolvedValue({ rows: [] }); });

describe('evidenceReviewService', () => {
  it('acceptEvidence sets accepted + reviewer + timestamps', async () => {
    await acceptEvidence('e1', 'admin1');
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toMatch(/review_status\s*=\s*'accepted'/);
    expect(sql).toMatch(/reviewed_by/); expect(sql).toMatch(/reviewed_at\s*=\s*NOW\(\)/i);
    expect(params).toEqual(['e1', 'admin1']);
  });

  it('rejectEvidence stores reason + note and rejects', async () => {
    await rejectEvidence('e1', 'admin1', 'goal-only', 'no lever');
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toMatch(/review_status\s*=\s*'rejected'/);
    expect(params).toEqual(['e1', 'admin1', 'goal-only', 'no lever']);
  });

  it('rejectEvidence rejects an invalid reason before querying', async () => {
    await expect(rejectEvidence('e1', 'admin1', 'bogus')).rejects.toThrow(/reason/i);
    expect(mockQuery).not.toHaveBeenCalled();
  });

  it('rehomeEvidence updates topic_id + issue and stays pending', async () => {
    await rehomeEvidence('e1', { topicId: 't1', issue: 'housing' }, 'admin1');
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toMatch(/topic_id\s*=\s*\$2/); expect(sql).toMatch(/issue\s*=\s*\$3/);
    expect(sql).not.toMatch(/review_status\s*=\s*'accepted'/);
    expect(params).toEqual(['e1', 't1', 'housing', 'admin1']);
  });

  it('rehomeEvidence requires a non-empty issue', async () => {
    await expect(rehomeEvidence('e1', { topicId: null, issue: '' }, 'admin1')).rejects.toThrow(/issue/i);
  });

  it('listPendingEvidence filters by politician and optional issue/status', async () => {
    mockQuery.mockResolvedValueOnce({ rows: [{ id: 'e1' }] });
    const rows = await listPendingEvidence('p1', { issue: 'housing', machineStatus: 'flagged' });
    const [sql, params] = mockQuery.mock.calls[0];
    expect(sql).toMatch(/review_status\s*=\s*'pending'/);
    expect(params).toContain('p1'); expect(params).toContain('housing'); expect(params).toContain('flagged');
    expect(rows).toEqual([{ id: 'e1' }]);
  });

  it('exposes the reason enum', () => {
    expect(REJECT_REASONS).toContain('goal-only'); expect(REJECT_REASONS).not.toContain('wrong-tag');
  });
});
