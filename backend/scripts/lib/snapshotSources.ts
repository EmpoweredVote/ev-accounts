// backend/scripts/lib/snapshotSources.ts
/**
 * snapshotSources — turns a fetched page into what the coders see (spec §1.2, §5.4).
 * news / pointer → excerpt windows around the collector's anchors only (quotation size, not copy
 * size); public-record / own-site / transcript → the full whitespace-collapsed text.
 * page_sha256 hashes the whole fetched page text so a later re-fetch can be compared.
 * Anchors are located with the verifier's normalisation, but the excerpt keeps the page's own case.
 */
import { createHash } from 'node:crypto';
import { resolve, sep } from 'node:path';
import { normalizeText } from '../../src/lib/researchVerifier.js';
import { isExcerptOnly, type SourceEntry, type SourceKind } from './sourcesManifest.js';

export const EXCERPT_CONTEXT_WORDS = 150;
/** Spec §1.2: a news / pointer excerpt is "a few hundred words maximum" in total, across all windows. */
export const MAX_EXCERPT_WORDS = 400;

export interface SnapshotRecord {
  snapshot_id: string;
  url: string;
  source_kind: SourceKind;
  fetched_by: 'code' | 'human';
  ok: boolean;
  failure: string | null;
  page_sha256: string | null;
  snapshot_text: string | null;
  excerpt_only: boolean;
}

const collapse = (s: string) => s.replace(/\s+/g, ' ').trim();

export function excerptWindows(text: string, anchors: string[], ctx = EXCERPT_CONTEXT_WORDS, maxWords = MAX_EXCERPT_WORDS): string | null {
  // A page token may carry punctuation around a word ("“we", "standard”", "today."): compare words
  // with edge punctuation stripped, and require EQUALITY so "the" never matches "there".
  const bare = (w: string) => normalizeText(w).replace(/^[^a-z0-9]+|[^a-z0-9]+$/g, '');
  const orig = collapse(text).split(' ');
  const norm = orig.map(bare);
  const spans: [number, number][] = [];
  for (const a of anchors) {
    const aw = collapse(a).split(' ').map(bare).filter(Boolean);
    if (!aw.length) continue;
    for (let i = 0; i + aw.length <= norm.length; i++) {
      let hit = true;
      for (let j = 0; j < aw.length; j++) {
        if (norm[i + j] !== aw[j]) { hit = false; break; }
      }
      if (hit) { spans.push([Math.max(0, i - ctx), Math.min(orig.length, i + aw.length + ctx)]); break; }
    }
  }
  if (!spans.length) return null;
  spans.sort((x, y) => x[0] - y[0]);
  const merged: [number, number][] = [];
  for (const s of spans) {
    const last = merged[merged.length - 1];
    if (last && s[0] <= last[1]) last[1] = Math.max(last[1], s[1]);
    else merged.push([s[0], s[1]]);
  }
  // Keep whole windows in page order until the word cap; the window that crosses it is cut to the
  // remaining budget (its cut end is marked with " …") and nothing after it is kept.
  const parts: string[] = [];
  let budget = maxWords;
  for (const [a, b] of merged) {
    if (budget <= 0) break;
    const end = Math.min(b, a + budget);
    parts.push(`${a > 0 ? '… ' : ''}${orig.slice(a, end).join(' ')}${end < orig.length ? ' …' : ''}`);
    budget -= end - a;
    if (end < b) break;
  }
  return parts.join(' ').replace(/ … … /g, ' … ');
}

/**
 * Deterministic snapshot id (final review item 5): a re-run over the same batch, URL, page and
 * excerpt yields the same id, so a coder's rests_on always names a row --apply stored; a changed
 * excerpt yields a new id. UUIDv5 layout over sha1 — node:crypto only, no dependency.
 */
export function snapshotIdFor(i: { batchId: string; url: string; pageSha256: string | null; snapshotText: string | null }): string {
  const textSha = i.snapshotText === null ? '' : createHash('sha256').update(i.snapshotText).digest('hex');
  const b = createHash('sha1').update(`${i.batchId}|${i.url}|${i.pageSha256 ?? ''}|${textSha}`).digest().subarray(0, 16);
  b[6] = (b[6] & 0x0f) | 0x50;
  b[8] = (b[8] & 0x3f) | 0x80;
  const h = b.toString('hex');
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
}

/** A human-saved page must sit inside the batch dir (final review item 12); null when it does not. */
export function resolveHumanSavedPath(batchDir: string, rel: string): string | null {
  const root = resolve(batchDir);
  const p = resolve(root, rel);
  return p.startsWith(root + sep) ? p : null;
}

export function buildSnapshot(args: {
  entry: SourceEntry;
  fetchedText: string | null;
  failure: string | null;
  fetchedBy: 'code' | 'human';
  batchId: string;
}): SnapshotRecord {
  const { entry, fetchedText, failure, fetchedBy, batchId } = args;
  const excerptOnly = isExcerptOnly(entry.source_kind);
  const make = (ok: boolean, fail: string | null, sha: string | null, text: string | null): SnapshotRecord => ({
    snapshot_id: snapshotIdFor({ batchId, url: entry.url, pageSha256: sha, snapshotText: text }),
    url: entry.url, source_kind: entry.source_kind, fetched_by: fetchedBy, excerpt_only: excerptOnly,
    ok, failure: fail, page_sha256: sha, snapshot_text: text,
  });
  if (fetchedText === null) return make(false, failure ?? 'fetch-failed', null, null);
  const sha = createHash('sha256').update(fetchedText).digest('hex');
  const text = excerptOnly
    ? excerptWindows(fetchedText, [...entry.pointer_passages, ...entry.candidate_quotes])
    : collapse(fetchedText);
  if (!text) return make(false, 'anchor-not-found', sha, null);
  return make(true, null, sha, text);
}
