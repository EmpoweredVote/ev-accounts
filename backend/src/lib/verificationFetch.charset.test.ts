import { describe, it, expect } from 'vitest';
import { decodeHtmlBody } from './verificationFetch.js';

// azleg.gov sends `Content-Type: text/html` with no charset and marks its Word-HTML pages
// windows-1252 only in a <meta http-equiv> tag. Decoding them as UTF-8 turned every §, dash and curly
// quote into U+FFFD (1,769 of them in AZ SB 1828's chaptered text).
const bytes = (s: string, extra: number[] = []) => new Uint8Array([...Buffer.from(s, 'latin1'), ...extra]);
const resp = (body: Uint8Array, ctype: string) => new Response(body, { headers: { 'content-type': ctype } });

describe('decodeHtmlBody', () => {
  it('uses the meta charset when the header has none (windows-1252 en dash)', async () =>
    expect(await decodeHtmlBody(resp(bytes('<meta http-equiv=Content-Type content="text/html; charset=windows-1252"><p>15', [0x96, 0x37, 0x31, 0x31]), 'text/html')))
      .toContain('15–711'));
  it('the header charset wins over the meta tag', async () =>
    expect(await decodeHtmlBody(resp(new Uint8Array(Buffer.from('<meta charset="windows-1252"><p>café', 'utf8')), 'text/html; charset=utf-8'))).toContain('café'));
  it('defaults to UTF-8', async () =>
    expect(await decodeHtmlBody(resp(new Uint8Array(Buffer.from('<p>§ 15–711', 'utf8')), 'text/html'))).toContain('§ 15–711'));
  it('an unknown charset label falls back to UTF-8 instead of throwing', async () =>
    expect(await decodeHtmlBody(resp(new Uint8Array(Buffer.from('<meta charset="x-nonsense"><p>ok', 'utf8')), 'text/html'))).toContain('ok'));
});
