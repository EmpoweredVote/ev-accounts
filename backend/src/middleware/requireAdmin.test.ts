import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Request, Response, NextFunction } from 'express';

// supabaseAdmin's module process.exit()s without env vars, so the whole client is a stub and
// the three outcomes are fed in through `result`. `.maybeSingle()` is the one that matters:
// unlike `.single()`, zero rows is `{ data: null, error: null }`, so a non-null `error` really
// does mean the question could not be asked rather than that the answer was no.
let result: { data: unknown; error: { message: string } | null } = { data: null, error: null };
vi.mock('../lib/supabase.js', () => ({
  supabaseAdmin: {
    from: () => ({
      select: () => ({
        eq: () => ({
          maybeSingle: async () => result,
        }),
      }),
    }),
  },
}));

const { requireAdmin } = await import('./requireAdmin.js');

function run(): Promise<{ status: number | null; body: unknown; nexted: boolean }> {
  let status: number | null = null;
  let body: unknown = null;
  let nexted = false;
  const res = {
    status: (code: number) => {
      status = code;
      return res;
    },
    json: (b: unknown) => {
      body = b;
      return res;
    },
  } as unknown as Response;
  return requireAdmin({ userId: 'u1' } as unknown as Request, res, (() => {
    nexted = true;
  }) as NextFunction).then(() => ({ status, body, nexted }));
}

beforeEach(() => {
  result = { data: null, error: null };
});

describe('requireAdmin', () => {
  it('calls next for a user in admin_users', async () => {
    result = { data: { user_id: 'u1' }, error: null };
    const out = await run();
    expect(out.nexted).toBe(true);
    expect(out.status).toBeNull();
  });

  it('403s a user who is not in admin_users', async () => {
    result = { data: null, error: null };
    const out = await run();
    expect(out.nexted).toBe(false);
    expect(out.status).toBe(403);
    expect(out.body).toEqual({ error: 'Admin access required' });
  });

  it('503s — not 403s — when the lookup could not be made at all', async () => {
    // 🔴 "NOT AN ADMIN" AND "COULD NOT ASK" ARE TWO ANSWERS. postgrest-js RESOLVES on a
    // transport or query failure, putting the fetch error in `error` instead of throwing, so
    // `if (error || !data)` collapsed a Supabase outage into "Admin access required". It fails
    // closed, so it was never a hole — it was a misdiagnosis, and it told an admin mid-outage
    // to go and request a role they already hold.
    //
    // src/focused_communities/routes/claimCuration.ts is the caller for which the difference
    // changes the answer: its guard is "maven OR admin", so a 403 from this half is an
    // ordinary outcome and only a status that is NOT 403 means the question went unanswered.
    const err = vi.spyOn(console, 'error').mockImplementation(() => {});
    result = { data: null, error: { message: 'TypeError: fetch failed' } };

    const out = await run();

    expect(out.nexted).toBe(false);
    expect(out.status).toBe(503);
    expect(out.status).not.toBe(403);
    expect(out.body).toEqual({ error: 'Could not verify admin access' });
    // The real reason goes to the log and never into the body.
    expect(err).toHaveBeenCalled();
    expect(JSON.stringify(out.body)).not.toContain('fetch failed');
    err.mockRestore();
  });
});
