// backend/scripts/lib/snapshotSources.ts
/**
 * snapshotSources — turns a fetched page into what the coders see (spec §1.2, §5.4).
 * news / pointer → excerpt windows around the collector's anchors only (quotation size, not copy
 * size); public-record / own-site / transcript → the full whitespace-collapsed text.
 * page_sha256 hashes the whole fetched page text so a later re-fetch can be compared.
 * Anchors are located with the verifier's normalisation, but the excerpt keeps the page's own case.
 */
import { createHash } from 'node:crypto';
import { normalizeText } from '../../src/lib/researchVerifier.js';
import { isExcerptOnly, type SourceEntry, type SourceKind } from './sourcesManifest.js';

export const EXCERPT_CONTEXT_WORDS = 150;

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

export function excerptWindows(text: string, anchors: string[], ctx = EXCERPT_CONTEXT_WORDS): string | null {
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
  return merged
    .map(([a, b]) => `${a > 0 ? '… ' : ''}${orig.slice(a, b).join(' ')}${b < orig.length ? ' …' : ''}`)
    .join(' ')
    .replace(/ … … /g, ' … ');
}

export function buildSnapshot(args: {
  entry: SourceEntry;
  fetchedText: string | null;
  failure: string | null;
  fetchedBy: 'code' | 'human';
  newId: () => string;
}): SnapshotRecord {
  const { entry, fetchedText, failure, fetchedBy, newId } = args;
  const excerptOnly = isExcerptOnly(entry.source_kind);
  const base = { snapshot_id: newId(), url: entry.url, source_kind: entry.source_kind, fetched_by: fetchedBy, excerpt_only: excerptOnly };
  if (fetchedText === null) return { ...base, ok: false, failure: failure ?? 'fetch-failed', page_sha256: null, snapshot_text: null };
  const sha = createHash('sha256').update(fetchedText).digest('hex');
  const text = excerptOnly
    ? excerptWindows(fetchedText, [...entry.pointer_passages, ...entry.candidate_quotes])
    : collapse(fetchedText);
  if (!text) return { ...base, ok: false, failure: 'anchor-not-found', page_sha256: sha, snapshot_text: null };
  return { ...base, ok: true, failure: null, page_sha256: sha, snapshot_text: text };
}
