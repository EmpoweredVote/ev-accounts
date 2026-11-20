import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { BUCKET, ensureBucket, uploadFrame } from './frames.js';

interface Call { url: string; init: RequestInit }

function stubFetch(responses: Array<{ ok: boolean; status: number; body?: string }>) {
  const calls: Call[] = [];
  let i = 0;
  const impl = (async (url: unknown, init: unknown) => {
    calls.push({ url: String(url), init: (init ?? {}) as RequestInit });
    const r = responses[Math.min(i++, responses.length - 1)];
    return {
      ok: r.ok,
      status: r.status,
      text: async () => r.body ?? '',
    };
  }) as unknown as typeof fetch;
  return { impl, calls };
}

const readFile = () => Buffer.from('jpeg-bytes');

describe('frames', () => {
  beforeEach(() => {
    process.env.SUPABASE_URL = 'https://proj.supabase.co';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'test-key';
  });
  afterEach(() => {
    delete process.env.SUPABASE_URL;
    delete process.env.SUPABASE_SERVICE_ROLE_KEY;
  });

  it('sends both apikey and Authorization', async () => {
    // 🔴 A lone Bearer is refused as HTTP 400 with a body saying 403 "Invalid Compact JWS",
    // which reads like a missing object and sends you looking in the wrong place.
    const { impl, calls } = stubFetch([{ ok: true, status: 200 }]);
    await uploadFrame('/tmp/a.jpg', '10001-0.jpg', { fetchImpl: impl, readFile });
    const headers = calls[0].init.headers as Record<string, string>;
    expect(headers.apikey).toBe('test-key');
    expect(headers.Authorization).toBe('Bearer test-key');
  });

  it('sends x-upsert so a re-run replaces rather than 409s', async () => {
    const { impl, calls } = stubFetch([{ ok: true, status: 200 }]);
    await uploadFrame('/tmp/a.jpg', '10001-0.jpg', { fetchImpl: impl, readFile });
    const headers = calls[0].init.headers as Record<string, string>;
    expect(headers['x-upsert']).toBe('true');
  });

  it('returns the public URL built from the object path, not the host', async () => {
    // 🔴 Storage answers on TWO hostnames. A host-based rule once classified 1,279 of our own
    // mirrored images as hotlinked. The PATH is the stable part.
    const { impl } = stubFetch([{ ok: true, status: 200 }]);
    const url = await uploadFrame('/tmp/a.jpg', '10001-0.jpg', { fetchImpl: impl, readFile });
    expect(url).toContain(`/storage/v1/object/public/${BUCKET}/10001-0.jpg`);
    expect(url.endsWith('/storage/v1/object/public/county_banner_frames/10001-0.jpg')).toBe(true);
  });

  it('throws naming the key when the upload is not ok', async () => {
    const { impl } = stubFetch([{ ok: false, status: 500, body: 'boom' }]);
    await expect(uploadFrame('/tmp/a.jpg', '10001-3.jpg', { fetchImpl: impl, readFile }))
      .rejects.toThrow(/10001-3\.jpg/);
  });

  it('treats a 409 from ensureBucket as already-exists, not an error', async () => {
    const { impl } = stubFetch([{ ok: false, status: 409, body: 'Duplicate' }]);
    await expect(ensureBucket({ fetchImpl: impl, readFile })).resolves.toBeUndefined();
  });
});
