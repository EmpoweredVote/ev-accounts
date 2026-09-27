// backend/scripts/lib/markedHtmlSnapshot.ts
/**
 * markedHtmlSnapshot — the code-fetched HTML branch of a `marked` source (amendment-markup spec §1/§3).
 * The page is fetched RAW through verificationFetch's raw-HTML ladder (robots gate → live → Wayback
 * `id_` capture), then read with htmlMarkedTextWithStats so struck words survive as `[deleted: …]`
 * fences. The text ladder cannot serve this path: every one of its tiers strips the HTML before it
 * returns, and the strike-through lives in the markup.
 *
 * Failures keep the snapshot codes snapshot-sources.ts has always written: `robots_disallowed`,
 * `not-html`, or the live failure (e.g. `HTTP 404 (no archived copy)`).
 */
import { fetchRawHtml, type RawHtmlPage } from '../../src/lib/verificationFetch.js';
import { htmlMarkedTextWithStats } from './htmlMarkedText.js';
import { buildSnapshot, type SnapshotRecord } from './snapshotSources.js';
import type { SourceEntry } from './sourcesManifest.js';

export interface MarkedHtmlSnapshot {
  record: SnapshotRecord;
  /** The page that was read, when one was — `via: 'wayback'` means an archived copy, not the live site. */
  page: RawHtmlPage | null;
}

export async function snapshotMarkedHtml(
  entry: SourceEntry,
  batchId: string,
  fetchRaw: (url: string) => Promise<RawHtmlPage> = (u) => fetchRawHtml(u),
): Promise<MarkedHtmlSnapshot> {
  const fail = (failure: string): MarkedHtmlSnapshot => ({
    record: buildSnapshot({ entry, fetchedText: null, failure, fetchedBy: 'code', batchId, amendmentText: 'marked' }),
    page: null,
  });
  let page: RawHtmlPage;
  try {
    page = await fetchRaw(entry.url);
  } catch (e) {
    const code = (e as { code?: unknown }).code;
    if (code === 'robots_disallowed') return fail('robots_disallowed');
    if (code === 'not_html') return fail('not-html');
    return fail((e as Error).message);
  }
  const { text, unresolved } = htmlMarkedTextWithStats(page.html);
  return {
    record: buildSnapshot({
      entry, fetchedText: text, failure: null, fetchedBy: 'code', batchId, amendmentText: 'marked', markupUnresolved: unresolved,
    }),
    page,
  };
}
