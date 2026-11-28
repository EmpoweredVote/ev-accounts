// Readers for the City of Bloomington OnBoard JSON feeds (legislation and meetings).
import type { FeedItem, PrintedTally } from '../types.js';

/** Read only the counts from a printed vote such as '5 - 2 (Flaherty, Ruff) - 0 (Zulich absent)'. */
export function parseFeedTally(vote: string): PrintedTally | null {
  const bare = vote.replace(/\([^)]*\)/g, ' ');
  const m = /^\s*(\d+)\s*-\s*(\d+)(?:\s*-\s*(\d+))?\s*$/.exec(bare);
  if (!m) return null;
  return { yes: Number(m[1]), no: Number(m[2]), abstain: m[3] ? Number(m[3]) : 0 };
}

const PREFIX: Record<FeedItem['type'], string> = {
  Ordinance: 'Ord',
  Resolution: 'Res',
  'Appropriation Ordinance': 'App Ord',
};

const isObj = (v: unknown): v is Record<string, any> => typeof v === 'object' && v !== null && !Array.isArray(v);

export function parseLegislationFeed(json: unknown, base: string): FeedItem[] {
  if (!Array.isArray(json)) return [];
  const items: FeedItem[] = [];
  for (const raw of json) {
    if (!isObj(raw)) continue;
    const type = raw.type as FeedItem['type'];
    const prefix = PREFIX[type];
    if (!prefix) continue;
    const number = String(raw.number);
    const status = String(raw.status ?? '');
    const finalAction = Array.isArray(raw.actions)
      ? raw.actions.find((a: any) => isObj(a) && a.name === 'Final')
      : undefined;
    let final: FeedItem['final'] = null;
    if (finalAction) {
      let outcome: 'passed' | 'failed' | 'vetoed';
      if (status === 'Vetoed') outcome = 'vetoed';
      else if (finalAction.outcome === 'pass') outcome = 'passed';
      else if (finalAction.outcome === 'fail') outcome = 'failed';
      else
        throw new Error(
          `Unknown Final outcome "${String(finalAction.outcome)}" for legislation feed id ${raw.id}`,
        );
      final = {
        date: String(finalAction.date),
        outcome,
        tally: parseFeedTally(String(finalAction.vote ?? '')),
      };
    }
    const actionDates = Array.isArray(raw.actions)
      ? raw.actions
          .map((a: any) => (isObj(a) && typeof a.date === 'string' && a.date !== '' ? a.date : null))
          .filter((d: string | null): d is string => d !== null)
          .sort()
      : [];
    items.push({
      feedId: Number(raw.id),
      type,
      number,
      itemNumber: `${prefix} ${number}`,
      title: String(raw.title ?? ''),
      synopsis: raw.synopsis == null ? null : String(raw.synopsis),
      status,
      final,
      firstActionDate: actionDates[0] ?? null,
      pageUrl: `${base}/council/legislation/${encodeURIComponent(type)}/${raw.year}/${number}`,
    });
  }
  return items;
}

/** A council session's vote record: the clerk's Memorandum (posted within days) or the formal Minutes (months later). */
export type VoteDocumentKind = 'memorandum' | 'minutes';

export interface VoteDocument {
  meetingId: number;
  meetingDate: string;
  fileId: number;
  url: string;
  updated: string;
  kind: VoteDocumentKind;
  /** The file's name as posted ("2021.05.05.RS.Web_Memo.pdf"); it names the session or committee it covers. */
  fileName?: string;
  /** The meeting's title ("Common Council Regular Session and Special Session"). */
  meetingTitle?: string;
}

const DOCUMENT_TYPES: Record<string, VoteDocumentKind> = { Memorandum: 'memorandum', Minutes: 'minutes' };

/**
 * Memorandum and Minutes files of Common Council Session and Organizational meetings. The Memorandum confirms votes
 * first; the Minutes are read again when they appear, and they govern.
 */
export function listVoteDocuments(json: unknown): VoteDocument[] {
  const out: VoteDocument[] = [];
  if (!isObj(json)) return out;
  for (const [meetingDate, times] of Object.entries(json)) {
    if (!isObj(times)) continue;
    for (const meetings of Object.values(times)) {
      if (!Array.isArray(meetings)) continue;
      for (const meeting of meetings) {
        if (!isObj(meeting)) continue;
        const title = String(meeting.title ?? '');
        // Organizational Meetings (each January) hold roll calls too, such as the resolution adopting the year's rules.
        if (!title.includes('Common Council') || !(title.includes('Session') || title.includes('Organizational Meeting'))) continue;
        if (!isObj(meeting.files)) continue;
        for (const [type, kind] of Object.entries(DOCUMENT_TYPES)) {
          const files = meeting.files[type];
          if (!Array.isArray(files)) continue;
          for (const f of files) {
            if (!isObj(f) || f.type !== type) continue;
            out.push({
              meetingId: Number(meeting.id),
              meetingDate,
              fileId: Number(f.id),
              url: String(f.url),
              updated: String(f.updated),
              kind,
              fileName: String(f.filename ?? ''),
              meetingTitle: title,
            });
          }
        }
      }
    }
  }
  return out;
}

/** Fetch JSON with a generic browser-like User-Agent. No personal data in headers. */
export async function fetchJson(url: string): Promise<unknown> {
  const res = await fetch(url, {
    headers: {
      'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
      'Accept-Encoding': 'gzip',
      Accept: 'application/json',
    },
  });
  if (!res.ok) throw new Error(`GET ${url} failed: ${res.status}`);
  return res.json();
}
