/**
 * sourcesManifest — the collector's (inline /research-stances session's) output contract:
 * <batch>/sources.json. It lists WHERE evidence is, never WHAT it proves (spec §1.1): a chair or
 * reasoning key here would let the collector's opinion reach the coders, so it is refused.
 */
export const SOURCE_KINDS = ['public-record', 'own-site', 'news', 'pointer', 'transcript'] as const;
export type SourceKind = typeof SOURCE_KINDS[number];
export const FORBIDDEN_OPINION_KEYS = ['value', 'chair', 'reasoning', 'stance', 'proposed_value'] as const;

export interface SourceEntry {
  url: string;
  source_kind: SourceKind;
  politician_id: string;
  office_id: string;
  topic_keys: string[];
  instruments: string[];
  /** Text the collector saw on the page, used as excerpt anchors. Verbatim. */
  pointer_passages: string[];
  candidate_quotes: string[];
  /** Page saved by a person in a real browser (spec §5.4), relative to the batch dir. */
  human_saved_path?: string;
}
export interface SourcesManifest { batch_id: string; sources: SourceEntry[] }

export const isExcerptOnly = (k: SourceKind): boolean => k === 'news' || k === 'pointer';

const strArr = (x: unknown): x is string[] => Array.isArray(x) && x.every((v) => typeof v === 'string');

export function parseSourcesManifest(raw: unknown): { ok: true; manifest: SourcesManifest } | { ok: false; errors: string[] } {
  const errors: string[] = [];
  if (typeof raw !== 'object' || raw === null || !Array.isArray((raw as { sources?: unknown }).sources)) {
    return { ok: false, errors: ['not an object with a sources array'] };
  }
  const m = raw as { batch_id?: unknown; sources: unknown[] };
  if (typeof m.batch_id !== 'string' || !m.batch_id) errors.push('batch_id missing');
  m.sources.forEach((s, i) => {
    const at = `sources[${i}]`;
    if (typeof s !== 'object' || s === null) { errors.push(`${at}: not an object`); return; }
    const e = s as Record<string, unknown>;
    for (const k of FORBIDDEN_OPINION_KEYS) if (k in e) errors.push(`${at}: collector-opinion key "${k}" is not allowed`);
    if (!(SOURCE_KINDS as readonly unknown[]).includes(e.source_kind)) errors.push(`${at}: source_kind ${String(e.source_kind)} not allowed`);
    if (typeof e.url !== 'string') errors.push(`${at}: url missing`);
    else {
      try { const u = new URL(e.url); if (u.pathname === '/' || u.pathname === '') errors.push(`${at}: url has no path`); }
      catch { errors.push(`${at}: url not parseable`); }
    }
    for (const k of ['politician_id', 'office_id'] as const) if (typeof e[k] !== 'string' || !e[k]) errors.push(`${at}: ${k} missing`);
    for (const k of ['topic_keys', 'instruments', 'pointer_passages', 'candidate_quotes'] as const) if (!strArr(e[k])) errors.push(`${at}: ${k} not a string array`);
    if (e.human_saved_path !== undefined && typeof e.human_saved_path !== 'string') errors.push(`${at}: human_saved_path not a string`);
    if ((e.source_kind === 'news' || e.source_kind === 'pointer')
      && strArr(e.pointer_passages) && strArr(e.candidate_quotes)
      && e.pointer_passages.length + e.candidate_quotes.length === 0) {
      errors.push(`${at}: ${String(e.source_kind)} source needs a pointer_passage or candidate_quote to excerpt around`);
    }
  });
  return errors.length ? { ok: false, errors } : { ok: true, manifest: raw as SourcesManifest };
}
