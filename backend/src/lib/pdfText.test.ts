import { describe, it, expect, vi } from 'vitest';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { extractPdfText, joinTextRuns, looksLikePdfBytes } from './pdfText.js';
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

describe('joinTextRuns', () => {
  const run = (str: string, x: number, width: number, y = 700, hasEOL = false) => ({ str, transform: [1, 0, 0, 1, x, y], width, hasEOL });

  it('joins a small-caps word printed as two touching runs (Nevada sponsor line, 2026-11-21)', () => {
    // "H" (large) then "ANSEN" (small) then "," then " " then "HARDY": the old join gave "H ANSEN , HARDY".
    const items = [run('H', 100, 8), run('ANSEN', 108, 30), run(',', 138, 2), run(' ', 140, 3), run('H', 143, 8), run('ARDY', 151, 22)];
    expect(joinTextRuns(items).replace(/\s+/g, ' ')).toBe('HANSEN, HARDY');
  });

  it('keeps a space between runs with a gap, on another line, or after an end of line', () => {
    expect(joinTextRuns([run('firearm', 100, 30), run('owner', 133, 25)])).toBe('firearm owner');
    expect(joinTextRuns([run('firearm', 100, 30), run('owner', 130, 25, 688)])).toBe('firearm owner');
    expect(joinTextRuns([run('firearm', 100, 30, 700, true), run('owner', 130, 25)])).toBe('firearm owner');
  });
});
