/**
 * Where a review frame lives once it leaves this machine.
 *
 * The operator's review page runs in a browser against the admin app, so the full uncropped
 * frames plan 1 renders locally have to be reachable over HTTP before anyone can choose from
 * them. They are free-licensed photographs with a stored author and licence, so the bucket is
 * public and the page needs no signed URL.
 *
 * 🔴 SEND BOTH `apikey` AND `Authorization`. A lone Bearer is refused as HTTP 400 carrying a
 * body that says 403 "Invalid Compact JWS" — which reads like a missing object and sends you
 * looking in the wrong place entirely.
 *
 * 🔴 BUILD THE PUBLIC URL FROM THE PATH, NEVER FROM THE HOST. Supabase storage answers on two
 * hostnames, `<ref>.storage.supabase.co` and `<ref>.supabase.co`. A host-based rule once
 * classified 1,279 of our own mirrored headshots as hotlinked.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 */
import fs from 'node:fs';

export const BUCKET = 'county_banner_frames';

export interface FrameDeps {
  fetchImpl?: typeof fetch;
  readFile?: (p: string) => Buffer;
}

function config(): { base: string; key: string } {
  const base = (process.env.SUPABASE_URL ?? '').replace(/\/$/, '');
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY ?? process.env.SUPABASE_SERVICE_KEY ?? '';
  if (!base) throw new Error('SUPABASE_URL is not set');
  // Never print the value, only the fact that it is missing.
  if (!key) throw new Error('SUPABASE_SERVICE_ROLE_KEY is not set');
  return { base, key };
}

function authHeaders(key: string): Record<string, string> {
  return { apikey: key, Authorization: `Bearer ${key}` };
}

/**
 * Create the bucket if it is not already there.
 *
 * An "already exists" answer is the normal case on every run after the first, so it is a
 * success and not an error — treating it as a failure would make the second import of every
 * state look broken.
 */
export async function ensureBucket(deps: FrameDeps = {}): Promise<void> {
  const { base, key } = config();
  const doFetch = deps.fetchImpl ?? fetch;
  const res = await doFetch(`${base}/storage/v1/bucket`, {
    method: 'POST',
    headers: { ...authHeaders(key), 'Content-Type': 'application/json' },
    body: JSON.stringify({ id: BUCKET, name: BUCKET, public: true }),
  });
  if (res.ok) return;
  if (res.status === 409) return;
  const body = await res.text();
  // A duplicate can also arrive as 400 with a body naming it, depending on the storage version.
  if (/already exists|Duplicate/i.test(body)) return;
  throw new Error(`ensureBucket ${BUCKET}: HTTP ${res.status} ${body.slice(0, 200)}`);
}

/** Upload one review frame and return the URL the review page will load it from. */
export async function uploadFrame(localPath: string, key: string, deps: FrameDeps = {}): Promise<string> {
  const { base, key: apiKey } = config();
  const doFetch = deps.fetchImpl ?? fetch;
  const read = deps.readFile ?? ((p: string) => fs.readFileSync(p));
  const body = read(localPath);
  const res = await doFetch(`${base}/storage/v1/object/${BUCKET}/${key}`, {
    method: 'POST',
    headers: {
      ...authHeaders(apiKey),
      'Content-Type': 'image/jpeg',
      // So a re-import replaces the frame rather than 409ing the whole state.
      'x-upsert': 'true',
    },
    body: body as unknown as BodyInit,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`uploadFrame ${key}: HTTP ${res.status} ${text.slice(0, 200)}`);
  }
  return `${base}/storage/v1/object/public/${BUCKET}/${key}`;
}
