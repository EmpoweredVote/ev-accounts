import { afterEach, describe, expect, it, vi } from 'vitest';
import { Pool } from 'pg';
import { SessionPoolerPool, isPoolerFullError } from './sessionPoolerPool.js';

// The exact message Supavisor sent on 2026-10-22 06:18:44 (Render logs, ev-accounts-api).
const poolerFull = () =>
  new Error('(EMAXCONNSESSION) max clients reached in session mode - max clients are limited to pool_size: 15');

function fakeClient() {
  return {
    query: vi.fn((_text: unknown, _values: unknown, cb: (err: unknown, res: unknown) => void) =>
      cb(undefined, { rows: [{ ok: 1 }] })
    ),
    once: vi.fn(),
    removeListener: vi.fn(),
    release: vi.fn(),
  };
}

function makePool(delays: number[] = [0, 0, 0]) {
  const pool = new SessionPoolerPool({ connectionString: 'postgres://unused' });
  pool.retryDelaysMs = delays;
  return pool;
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe('isPoolerFullError', () => {
  it('matches the Supavisor session-cap refusal only', () => {
    expect(isPoolerFullError(poolerFull())).toBe(true);
    expect(isPoolerFullError(new Error('timeout exceeded when trying to connect'))).toBe(false);
    expect(isPoolerFullError('EMAXCONNSESSION')).toBe(false);
  });
});

describe('SessionPoolerPool.connect', () => {
  it('pool.query waits out a full pooler instead of failing', async () => {
    const client = fakeClient();
    const base = vi
      .spyOn(Pool.prototype, 'connect')
      .mockRejectedValueOnce(poolerFull())
      .mockRejectedValueOnce(poolerFull())
      .mockResolvedValueOnce(client as never);
    vi.spyOn(console, 'warn').mockImplementation(() => {});

    const res = await makePool().query('SELECT 1');

    expect(res.rows).toEqual([{ ok: 1 }]);
    expect(base).toHaveBeenCalledTimes(3);
    expect(client.release).toHaveBeenCalledTimes(1);
  });

  it('gives up with the pooler error once the retries are spent', async () => {
    const base = vi.spyOn(Pool.prototype, 'connect').mockRejectedValue(poolerFull());
    vi.spyOn(console, 'warn').mockImplementation(() => {});

    await expect(makePool([0, 0]).connect()).rejects.toThrow('EMAXCONNSESSION');
    expect(base).toHaveBeenCalledTimes(3); // first try + 2 retries
  });

  it('does not retry any other connect error', async () => {
    const base = vi
      .spyOn(Pool.prototype, 'connect')
      .mockRejectedValue(new Error('password authentication failed'));

    await expect(makePool().connect()).rejects.toThrow('password authentication failed');
    expect(base).toHaveBeenCalledTimes(1);
  });

  it('keeps the callback form working', async () => {
    const client = fakeClient();
    vi.spyOn(Pool.prototype, 'connect').mockResolvedValueOnce(client as never);

    const got = await new Promise((resolve, reject) =>
      makePool().connect((err, c, done) => {
        if (err) return reject(err);
        done();
        resolve(c);
      })
    );

    expect(got).toBe(client);
    expect(client.release).toHaveBeenCalledTimes(1);
  });
});

describe('SessionPoolerPool.releaseIdleSessions', () => {
  it('closes every idle session and makes later releases close theirs', async () => {
    const pool = makePool();
    const clients = [fakeClient(), fakeClient()];
    let idle = clients.length;
    Object.defineProperty(pool, 'idleCount', { get: () => idle });
    vi.spyOn(Pool.prototype, 'connect').mockImplementation(async () => clients[clients.length - idle--] as never);

    await pool.releaseIdleSessions();

    for (const c of clients) expect(c.release).toHaveBeenCalledWith(true);
    // pg-pool removes a released client once its use count reaches maxUses.
    expect(pool.options.maxUses).toBe(1);
  });
});
