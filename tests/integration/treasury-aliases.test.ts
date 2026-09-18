import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import type { Express } from 'express';
// Static import — evaluated before the assignments below, so it sees the real
// DATABASE_URL rather than the placeholder this file installs for itself.
import { hasLiveDb } from '../helpers/liveDb.js';

// Set up test environment before any imports that read process.env.
process.env['NODE_ENV'] = 'test';
process.env['SUPABASE_URL'] = process.env['SUPABASE_URL'] || 'https://test.supabase.co';
process.env['SUPABASE_ANON_KEY'] = process.env['SUPABASE_ANON_KEY'] || 'test-anon-key';
process.env['SUPABASE_SERVICE_ROLE_KEY'] =
  process.env['SUPABASE_SERVICE_ROLE_KEY'] || 'test-service-role-key';
process.env['DATABASE_URL'] =
  process.env['DATABASE_URL'] || 'postgresql://postgres:password@localhost:5432/postgres';
process.env['ADMIN_INGEST_TOKEN'] = process.env['ADMIN_INGEST_TOKEN'] || 'test-ingest-token';

let app: Express;

beforeAll(async () => {
  const mod = await import('../../backend/src/index.js');
  app = mod.app;
});

// ---------------------------------------------------------------------------
// Contract test for GET /api/treasury/aliases
//
// Purpose: Treasury Tracker resolves a `?entity=<slug>` deep link whose slug was
// retired by a publisher rename against this payload. It decides WHICH ENTITY A
// READER LANDS ON, so the shape is a contract, not a convenience.
//
// ⚠⚠ IT EMITS SLUGS, from the same expression the coverage catalog uses. An
// earlier draft forbade them, reasoning that a second copy of TT's `toSlug`
// would drift silently — but this service already owns a slug expression, and
// /api/treasury/coverage already emits `slug` so that "no consumer ever
// reconstructs TT's toSlug and drifts". Withholding them would force every
// non-TT consumer to write their own.
// ---------------------------------------------------------------------------

const REQUIRED_ALIAS_KEYS = ['slug', 'label', 'canonicalSlug', 'canonicalLabel'] as const;

describe.skipIf(!hasLiveDb)('GET /api/treasury/aliases — contract', () => {
  it('returns 200 with an array', async () => {
    const res = await request(app).get('/api/treasury/aliases');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('every entry carries slug, label, canonicalSlug and canonicalLabel as strings', async () => {
    const res = await request(app).get('/api/treasury/aliases');
    expect(res.status).toBe(200);

    const aliases: unknown[] = res.body as unknown[];
    if (aliases.length === 0) return;

    for (const alias of aliases) {
      expect(typeof alias).toBe('object');
      expect(alias).not.toBeNull();
      for (const key of REQUIRED_ALIAS_KEYS) {
        expect(alias, `alias entry is missing required key: ${key}`).toHaveProperty(key);
        expect(
          typeof (alias as Record<string, unknown>)[key],
          `${key} must be a string — the consumer drops malformed rows`
        ).toBe('string');
      }
    }
  });

  it('emits slugs in the TT format, so a consumer never rebuilds toSlug', async () => {
    const res = await request(app).get('/api/treasury/aliases');
    const aliases: unknown[] = res.body as unknown[];
    if (aliases.length === 0) return;

    // `<name-hyphenated>-<state>`, lowercase throughout.
    for (const alias of aliases) {
      const a = alias as Record<string, string>;
      for (const key of ['slug', 'canonicalSlug']) {
        expect(a[key], `${key} must be lowercase with no whitespace`).toMatch(/^[a-z0-9.'-]+-[a-z]{2}$/);
      }
    }
  });

  it('never points an alias at the name it already is', async () => {
    const res = await request(app).get('/api/treasury/aliases');
    const aliases: unknown[] = res.body as unknown[];
    if (aliases.length === 0) return;

    for (const alias of aliases) {
      const a = alias as Record<string, string>;
      // A self-alias is inert rather than harmful — the consumer ignores it —
      // but it means a rename was recorded that never happened.
      expect(
        a['label']?.toLowerCase(),
        `self-alias on ${a['label']}: alias and canonical name are the same`
      ).not.toBe(a['canonicalLabel']?.toLowerCase());
    }
  });

  it('does not expose the same alias slug pointing at two different entities', async () => {
    const res = await request(app).get('/api/treasury/aliases');
    const aliases: unknown[] = res.body as unknown[];
    if (aliases.length === 0) return;

    // The consumer refuses to guess between two targets and shows not-found, so
    // an ambiguous pair silently disables the alias. Catch it here instead.
    const targets = new Map<string, Set<string>>();
    for (const alias of aliases) {
      const a = alias as Record<string, string>;
      const key = a['slug'] ?? '';
      if (!targets.has(key)) targets.set(key, new Set());
      targets.get(key)!.add(a['canonicalLabel']?.toLowerCase() ?? '');
    }
    for (const [key, canonicals] of targets) {
      expect(
        canonicals.size,
        `alias '${key}' names ${canonicals.size} different entities — the consumer will ` +
          `resolve it to not-found rather than pick one`
      ).toBe(1);
    }
  });
});
