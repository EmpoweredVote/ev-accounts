/**
 * `adminCreatePolitician` must not write incumbency.
 *
 * History: it used to default `politicians.is_incumbent` to TRUE (the CA_0188 shape — every row
 * created here was marked a sitting officeholder), then to `!is_candidate`. The column was
 * dropped in CA_0378: whether someone holds a seat is read from `essentials.office_terms`
 * (src/lib/incumbency.ts), so a stored copy cannot go stale on a handover date. An INSERT that
 * still named it would fail in production the moment the column is gone.
 */
import { vi, describe, it, expect, beforeEach } from 'vitest';

vi.mock('./env.js', () => ({ env: {} }));
vi.mock('./supabase.js', () => ({ supabaseAdmin: {}, adminRpc: vi.fn() }));
vi.mock('./empowerService.js', () => ({ executeDemotion: vi.fn() }));
vi.mock('./db.js', () => ({ pool: { query: vi.fn() } }));

import { pool } from './db.js';
import { adminCreatePolitician } from './adminService.js';

async function insertFor(data: Record<string, unknown>): Promise<[string, unknown[]]> {
  const query = vi.mocked(pool.query);
  query.mockReset();
  query.mockResolvedValue({ rows: [{ id: 'p1' }] } as never);
  await adminCreatePolitician(data as never);
  return query.mock.calls[0] as unknown as [string, unknown[]];
}

describe('adminCreatePolitician — no incumbency column', () => {
  beforeEach(() => vi.mocked(pool.query).mockReset());

  it('does not name is_incumbent in the INSERT', async () => {
    const [sql] = await insertFor({ first_name: 'A', last_name: 'B', is_candidate: false });
    expect(sql).not.toMatch(/is_incumbent/);
  });

  it('binds exactly one value per named column (positive control on the parse)', async () => {
    const [sql, params] = await insertFor({ first_name: 'A', last_name: 'B', is_candidate: true });
    const cols = sql.slice(sql.indexOf('(') + 1, sql.indexOf(')')).split(',').map((c) => c.trim());
    expect(cols).toContain('full_name');
    expect(params).toHaveLength(cols.length);
  });
});

import { adminUpdatePolitician } from './adminService.js';

describe('adminUpdatePolitician — only real columns reach the UPDATE', () => {
  beforeEach(() => vi.mocked(pool.query).mockReset());

  it('drops office_title and is_candidate (not politicians columns: they made the UPDATE 500)', async () => {
    const query = vi.mocked(pool.query);
    query.mockResolvedValue({ rows: [{ id: 'p1' }] } as never);
    await adminUpdatePolitician('p1', { full_name: 'A B', office_title: 'Mayor', is_candidate: true } as never);
    const [sql, params] = query.mock.calls[0] as unknown as [string, unknown[]];
    expect(sql).toContain('full_name = $1');
    expect(sql).not.toMatch(/office_title|is_candidate/);
    expect(params).toEqual(['A B', 'p1']);
  });

  it('refuses when only unknown fields were sent', async () => {
    await expect(adminUpdatePolitician('p1', { office_title: 'Mayor' } as never)).rejects.toThrow('No fields to update');
    expect(vi.mocked(pool.query)).not.toHaveBeenCalled();
  });
});
