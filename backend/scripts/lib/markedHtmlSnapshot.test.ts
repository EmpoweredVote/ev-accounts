// backend/scripts/lib/markedHtmlSnapshot.test.ts
import { describe, it, expect } from 'vitest';
import { snapshotMarkedHtml } from './markedHtmlSnapshot.js';
import { NotHtmlError, RobotsDisallowedError, type RawHtmlPage } from '../../src/lib/verificationFetch.js';
import type { SourceEntry } from './sourcesManifest.js';

const entry: SourceEntry = {
  url: 'https://www.azleg.gov/legtext/57leg/2R/bills/HB2001H.htm', source_kind: 'public-record', politician_id: 'p1', office_id: 'o1',
  topic_keys: ['taxes'], instruments: ['HB 2001'], pointer_passages: [], candidate_quotes: [],
};
const archivedPage: RawHtmlPage = {
  html: '<p>The rate is <strike>five</strike> four percent.</p>',
  via: 'wayback',
  fetchedUrl: 'https://web.archive.org/web/20260101000000id_/' + entry.url,
};

describe('snapshotMarkedHtml', () => {
  it('reads an archived copy with deletion fences, exactly as a live one would be read', async () => {
    const { record, page } = await snapshotMarkedHtml(entry, 'b1', async () => archivedPage);
    expect(page?.via).toBe('wayback');
    expect(record).toMatchObject({ ok: true, fetched_by: 'code', amendment_markup: 'kept' });
    expect(record.snapshot_text).toContain('[deleted: five]');
  });

  it('marks the snapshot unknown when the page links a stylesheet the reader cannot see', async () => {
    const withCss: RawHtmlPage = { ...archivedPage, html: '<link rel="stylesheet" href="x.css">' + archivedPage.html };
    const { record } = await snapshotMarkedHtml(entry, 'b1', async () => withCss);
    expect(record.amendment_markup).toBe('unknown');
  });

  it('maps a robots refusal to robots_disallowed', async () => {
    const { record, page } = await snapshotMarkedHtml(entry, 'b1', async () => { throw new RobotsDisallowedError(entry.url); });
    expect(record).toMatchObject({ ok: false, failure: 'robots_disallowed', snapshot_text: null });
    expect(page).toBeNull();
  });

  it('maps a non-HTML page to not-html', async () => {
    const { record } = await snapshotMarkedHtml(entry, 'b1', async () => { throw new NotHtmlError(entry.url, 'application/pdf'); });
    expect(record.failure).toBe('not-html');
  });

  it('keeps the live failure message otherwise', async () => {
    const { record } = await snapshotMarkedHtml(entry, 'b1', async () => { throw new Error('HTTP 404 (no archived copy)'); });
    expect(record.failure).toBe('HTTP 404 (no archived copy)');
  });
});
