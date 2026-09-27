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
import type { AmendmentText } from './recordBasis.js';
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
  /**
   * Amendment-markup spec §3: 'none' for a `final` source (no markup to lose); 'kept' when the
   * snapshot's text carries a `[deleted: …]` fence or the pdf-snapshot.ts strike-detection trailer;
   * 'unknown' otherwise (a `marked`/`unmarked` source whose snapshot shows no evidence deletions
   * were kept — CONFIRM, task 3, fails closed on this). An older snapshots.json with no such field
   * reads as 'unknown' when JSON-parsed as SnapshotRecord.
   */
  amendment_markup: 'kept' | 'none' | 'unknown';
}

/**
 * The fixed lead of the trailer pdf-snapshot.ts appends (the rest of the line names the run's date,
 * source url, and — for a saved file — that it came from one; see pdf-snapshot.ts). Exported so
 * snapshot-sources.ts's human-saved branch can recognise a pdf-snapshot.ts output file and read it
 * unstripped (spec §3/§9 — the file is already plain text, and htmlToText's tag-stripping would treat
 * a stray `<`/`>` in the bill text, or in the trailer itself, as a tag to remove).
 */
export const PDF_TRAILER_PREFIX = '[extracted by pdf-snapshot.ts with strike detection';

/**
 * Does `text`, once trailing whitespace is trimmed, END with a genuine pdf-snapshot.ts trailer?
 * Finds the LAST occurrence of the trailer's fixed prefix and requires everything from there to the
 * end of the (trimmed) text to be that one trailer — its own single closing `]`, and no other `]`
 * anywhere in between. A bare `.includes` would let a `[deleted: …]` fence that happened to quote
 * this exact phrase from a bill's own text (or any text still following it) be mistaken for the real
 * trailer, which is always the last thing pdf-snapshot.ts writes.
 */
function hasPdfSnapshotTrailer(text: string): boolean {
  const trimmed = text.trimEnd();
  const idx = trimmed.lastIndexOf(PDF_TRAILER_PREFIX);
  if (idx === -1) return false;
  const tail = trimmed.slice(idx);
  return tail.endsWith(']') && !tail.slice(0, -1).includes(']');
}

/**
 * amendment-markup spec §3: does this snapshot text show that deleted words were kept legible?
 * A `final` source prints no amended text at all, so there is nothing to keep — always 'none'.
 * Otherwise 'kept' when a `[deleted: …]` fence (htmlToMarkedText) or the pdf-snapshot.ts trailer
 * (pdfMarkedText) is present; 'unknown' when neither is — fail closed rather than assume nothing
 * was deleted.
 *
 * This function reads TEXT ONLY. Whether the HTML→text conversion itself could not fully resolve
 * every line-through rule (an unresolvable `<style>` selector, or an external stylesheet never read)
 * is NOT decidable from the text alone — an excerpt-only snapshot can cut off any marker a converter
 * might have appended — so that case is a separate, explicit `markupUnresolved` flag on
 * {@link buildSnapshot}, not something this function searches for.
 */
export function amendmentMarkup(text: string, amendmentText: AmendmentText): 'kept' | 'none' | 'unknown' {
  if (amendmentText === 'final') return 'none';
  if (text.includes('[deleted: ') || hasPdfSnapshotTrailer(text)) return 'kept';
  return 'unknown';
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
  /** How this source prints amended text (sourceProfiles.ts `rules.amendment_text`). Default 'final'. */
  amendmentText?: AmendmentText;
  /**
   * True when the converter that produced `fetchedText` (htmlMarkedTextWithStats, currently) could
   * not fully resolve every line-through rule on the page — an unresolvable `<style>` selector, or an
   * external/`@import`ed stylesheet this reader never read at all. Forces `amendment_markup` to
   * `'unknown'` regardless of what the (possibly excerpted) text otherwise shows: some deletions
   * being caught is not evidence every one was, and an excerpt can cut off any in-text signal of this
   * anyway — so it must travel as an explicit flag, never something searched for in the text.
   */
  markupUnresolved?: boolean;
}): SnapshotRecord {
  const { entry, fetchedText, failure, fetchedBy, batchId, amendmentText = 'final', markupUnresolved = false } = args;
  const excerptOnly = isExcerptOnly(entry.source_kind);
  const markup = (text: string | null): 'kept' | 'none' | 'unknown' => {
    if (amendmentText === 'final') return 'none';
    if (markupUnresolved) return 'unknown';
    if (text === null) return 'unknown';
    return amendmentMarkup(text, amendmentText);
  };
  const make = (ok: boolean, fail: string | null, sha: string | null, text: string | null): SnapshotRecord => ({
    snapshot_id: snapshotIdFor({ batchId, url: entry.url, pageSha256: sha, snapshotText: text }),
    url: entry.url, source_kind: entry.source_kind, fetched_by: fetchedBy, excerpt_only: excerptOnly,
    ok, failure: fail, page_sha256: sha, snapshot_text: text,
    amendment_markup: markup(text),
  });
  if (fetchedText === null) return make(false, failure ?? 'fetch-failed', null, null);
  const sha = createHash('sha256').update(fetchedText).digest('hex');
  // A JavaScript-only site (iga.in.gov) answers a plain fetch with an app shell and HTTP 200. That is
  // not the page: fail closed rather than hand the coders "You need to enable JavaScript".
  if (collapse(fetchedText).length < 400 && /enable javascript/i.test(fetchedText)) return make(false, 'js-shell', sha, null);
  const text = excerptOnly
    ? excerptWindows(fetchedText, [...entry.pointer_passages, ...entry.candidate_quotes])
    : collapse(fetchedText);
  if (!text) return make(false, 'anchor-not-found', sha, null);
  return make(true, null, sha, text);
}
