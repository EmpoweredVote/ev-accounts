import { describe, expect, it, vi } from 'vitest';

vi.mock('../db.js', () => ({ pool: { query: vi.fn() } }));

import { zipFromDatasetStream } from './client.js';

/** A body that arrives in chunks of `size` bytes. */
async function* chunks(text: string, size: number): AsyncGenerator<Uint8Array> {
  const bytes = Buffer.from(text, 'latin1');
  for (let i = 0; i < bytes.length; i += size) yield new Uint8Array(bytes.subarray(i, i + size));
}

// Bytes chosen so the base64 contains "/" and "+" and needs "=" padding.
const ZIP = Buffer.from([0xff, 0xef, 0xbf, 0x50, 0x4b, 0x03, 0x04, 0xfb, 0xff, 0xfe, 0x3e, 0x3f, 0x7f]);
const b64 = ZIP.toString('base64');
const phpEscaped = b64.replace(/\//g, '\\/'); // PHP json_encode writes "\/"
const reply = (zip: string) =>
  `{"status":"OK","dataset":{"state_id":52,"session_id":2199,"session_name":"119th Congress","zip":"${zip}"}}`;

describe('zipFromDatasetStream', () => {
  it('has a test value that really contains a slash and padding', () => {
    expect(b64).toContain('/');
    expect(b64.endsWith('=')).toBe(true);
  });

  it.each([1, 2, 3, 5, 7, 64, 100000])('decodes the zip whatever the chunk size (%i bytes)', async (size) => {
    const out = await zipFromDatasetStream(chunks(reply(phpEscaped), size));
    expect(out.equals(ZIP)).toBe(true);
  });

  it('also accepts an answer with no escaped slashes', async () => {
    const out = await zipFromDatasetStream(chunks(reply(b64), 4));
    expect(out.equals(ZIP)).toBe(true);
  });

  it('reads past a large zip without error', async () => {
    const big = Buffer.alloc(300_000, 0xab);
    const out = await zipFromDatasetStream(chunks(reply(big.toString('base64')), 65_536));
    expect(out.length).toBe(big.length);
    expect(out.equals(big)).toBe(true);
  });

  it('turns an error reply into an error, without echoing the API key', async () => {
    const err = '{"status":"ERROR","alert":{"message":"Invalid API key key=SECRET123&x"}}';
    await expect(zipFromDatasetStream(chunks(err, 9))).rejects.toThrow(/had no zip/);
    await expect(zipFromDatasetStream(chunks(err, 9))).rejects.not.toThrow(/SECRET123/);
  });

  it('rejects an escape it does not understand', async () => {
    await expect(zipFromDatasetStream(chunks(reply('AAAA\\nBBBB'), 6))).rejects.toThrow(/unexpected escape/);
  });
});
