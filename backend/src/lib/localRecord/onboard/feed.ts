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
    items.push({
      feedId: Number(raw.id),
      type,
      number,
      itemNumber: `${prefix} ${number}`,
      title: String(raw.title ?? ''),
      synopsis: raw.synopsis == null ? null : String(raw.synopsis),
      status,
      final,
      pageUrl: `${base}/council/legislation/${encodeURIComponent(type)}/${raw.year}/${number}`,
    });
  }
  return items;
}

export function listMinutesFiles(
  json: unknown,
): { meetingId: number; meetingDate: string; fileId: number; url: string; updated: string }[] {
  const out: { meetingId: number; meetingDate: string; fileId: number; url: string; updated: string }[] = [];
  if (!isObj(json)) return out;
  for (const [meetingDate, times] of Object.entries(json)) {
    if (!isObj(times)) continue;
    for (const meetings of Object.values(times)) {
      if (!Array.isArray(meetings)) continue;
      for (const meeting of meetings) {
        if (!isObj(meeting)) continue;
        const title = String(meeting.title ?? '');
        if (!title.includes('Common Council') || !title.includes('Session')) continue;
        const minutes = isObj(meeting.files) ? meeting.files.Minutes : undefined;
        if (!Array.isArray(minutes)) continue;
        for (const f of minutes) {
          if (!isObj(f) || f.type !== 'Minutes') continue;
          out.push({
            meetingId: Number(meeting.id),
            meetingDate,
            fileId: Number(f.id),
            url: String(f.url),
            updated: String(f.updated),
          });
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
