import { describe, it, expect, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { extractPdfText, looksLikePdfBytes } from './pdfText.js';
import { fetchViaHttp } from './verificationFetch.js';

const pdf = new Uint8Array(readFileSync(join(__dirname, '__fixtures__', 'home-visiting.pdf')));

describe('extractPdfText', () => {
  it('positive control: a real PDF comes out as its text, never as bytes', async () => {
    expect(looksLikePdfBytes(pdf)).toBe(true); // the control really is a PDF
    const text = await extractPdfText(pdf);
    expect(text).toBe('Home visiting programs improve child outcomes.');
    expect(text.startsWith('%PDF')).toBe(false);
  });
});

describe('fetchViaHttp on a PDF (2026-10-07 goldentogether.com bug)', () => {
  const serve = (contentType: string, body: Uint8Array) =>
    vi.spyOn(globalThis, 'fetch').mockResolvedValue(new Response(body as BodyInit, { status: 200, headers: { 'content-type': contentType } }));

  it.each(['application/pdf', 'application/octet-stream', 'text/plain'])('extracts text when served as %s', async (ct) => {
    const spy = serve(ct, pdf);
    const text = await fetchViaHttp('https://example.org/wp-content/uploads/GT_Home-Visiting-3.pdf');
    spy.mockRestore();
    expect(text).toContain('Home visiting programs');
    expect(text.startsWith('%PDF')).toBe(false);
  });

  it('throws on a PDF that cannot be read, rather than returning its bytes', async () => {
    const spy = serve('application/pdf', new TextEncoder().encode('%PDF-1.4\nnot really a pdf'));
    await expect(fetchViaHttp('https://example.org/x.pdf')).rejects.toBeTruthy();
    spy.mockRestore();
  });
});
