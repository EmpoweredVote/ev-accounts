/**
 * otrTranscript — resolve an On the Record meeting URL to its transcript text, for the stance
 * verifier.
 *
 * `https://ontherecord.empowered.vote/meetings/<uuid>` is a JavaScript SPA: the HTML the verifier
 * fetches holds no transcript, so every snippet cited to it came back `snippet_not_found` and the
 * chair fell below threshold. The transcript is public at
 * `<api>/api/meetings/<uuid>/transcript?page=N` (the API extract-otr.mjs reads). This module turns
 * the meeting URL into that text.
 *
 * Each turn is rendered `Speaker Name: text`, consecutive segments by one speaker merged, so the
 * verifier's name-proximity test ("the politician's name within 500 chars of the match") is
 * satisfied by the speaker label of the turn the quote sits in — the same property a news article
 * gives it. Pass `speaker` to keep only one person's turns.
 */
import type { PageFetcher } from './researchVerifier.js';

export const OTR_API_BASE = 'https://accounts-api.empowered.vote';
const OTR_URL_RE = /^https?:\/\/ontherecord\.empowered\.vote\/meetings\/([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})\/?(?:[?#].*)?$/i;
/** Hard stop on pagination so a misbehaving API cannot loop the verifier. */
const MAX_PAGES = 200;

export interface OtrSegment {
  speakerName?: string | null;
  /** Carries the politician's UUID in this payload (see extract-otr.mjs), empty when unlinked. */
  politicianSlug?: string | null;
  text?: string | null;
  startTime?: number | null;
}
interface TranscriptPage { segments?: OtrSegment[]; totalCount?: number }
export type JsonFetcher = (url: string) => Promise<unknown>;

/** The meeting id in an ontherecord meeting URL, or null for any other URL. */
export function otrMeetingId(url: string): string | null {
  const m = OTR_URL_RE.exec(url.trim());
  return m ? m[1].toLowerCase() : null;
}

/** Merge consecutive same-speaker segments into `Speaker: text` turns. */
export function segmentsToText(segments: OtrSegment[], speaker?: { name?: string; politicianId?: string }): string {
  const norm = (s: string) => s.toLowerCase().replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
  const keep = (t: { name: string; politicianId: string }): boolean => {
    if (!speaker) return true;
    if (speaker.politicianId && t.politicianId === speaker.politicianId) return true;
    return Boolean(speaker.name && norm(t.name) === norm(speaker.name));
  };
  // Merge over the WHOLE sequence first and filter after: filtering first would join two of one
  // person's turns across a turn that was removed, fabricating a passage nobody said.
  const turns: { key: string; name: string; politicianId: string; text: string }[] = [];
  for (const s of segments) {
    const text = (s.text ?? '').trim();
    if (!text) continue;
    const name = (s.speakerName ?? 'Unknown').trim() || 'Unknown';
    const key = s.politicianSlug || name;
    const last = turns[turns.length - 1];
    if (last && last.key === key) last.text += ' ' + text;
    else turns.push({ key, name, politicianId: s.politicianSlug ?? '', text });
  }
  return turns.filter(keep).map((t) => `${t.name}: ${t.text}`).join('\n');
}

/** Fetch every page of one meeting's transcript and render it. Throws on any API failure. */
export async function fetchOtrTranscriptText(
  meetingId: string,
  opts: { fetchJson: JsonFetcher; apiBase?: string; speaker?: { name?: string; politicianId?: string } },
): Promise<string> {
  const base = opts.apiBase ?? OTR_API_BASE;
  const segments: OtrSegment[] = [];
  let total = Infinity;
  for (let page = 1; page <= MAX_PAGES && segments.length < total; page++) {
    const body = (await opts.fetchJson(`${base}/api/meetings/${meetingId}/transcript?page=${page}`)) as TranscriptPage;
    const got = body?.segments ?? [];
    if (typeof body?.totalCount === 'number') total = body.totalCount;
    else if (!got.length) break;
    if (!got.length) break;
    segments.push(...got);
  }
  if (!segments.length) throw new Error(`OTR transcript for ${meetingId} is empty`);
  const text = segmentsToText(segments, opts.speaker);
  if (!text) throw new Error(`OTR transcript for ${meetingId} has no turns for the requested speaker`);
  return text;
}

/**
 * Wrap a PageFetcher so ontherecord meeting URLs resolve to transcript text. Every other URL goes
 * to `base` unchanged. Results are cached per URL like createPageFetcher's, failures included.
 */
export function withOtrTranscripts(
  base: PageFetcher,
  opts: { fetchJson?: JsonFetcher; apiBase?: string } = {},
): PageFetcher {
  const fetchJson: JsonFetcher = opts.fetchJson ?? (async (url) => {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`GET ${url} -> ${res.status}`);
    return res.json();
  });
  const cache = new Map<string, ReturnType<PageFetcher>>();
  return (url) => {
    const id = otrMeetingId(url);
    if (!id) return base(url);
    let hit = cache.get(url);
    if (!hit) {
      hit = fetchOtrTranscriptText(id, { fetchJson, apiBase: opts.apiBase })
        .then((text) => ({ ok: true as const, text }))
        .catch((err: any) => ({ ok: false as const, reason: err?.message ?? String(err) }));
      cache.set(url, hit);
    }
    return hit;
  };
}
